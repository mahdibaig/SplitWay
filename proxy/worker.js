// Splitway assistant proxy. Cloudflare Worker.
//
// Routes:
//   POST /v1/chat/completions   -> DeepSeek (chat + receipt cleanup)
//   POST /v1/vision/receipt     -> OpenAI GPT-4o mini (receipt vision OCR)
//
// Both routes require the X-App-Auth shared-secret header. Both are
// optionally rate-limited per IP per day via KV, with separate caps so
// expensive vision calls can't burn down the chat budget.
//
// Required Worker secrets (set via `wrangler secret put`):
//   APP_SHARED_SECRET   - long random string; matches what's compiled into the app
//   DEEPSEEK_API_KEY    - your DeepSeek key (for chat + cleanup)
//   OPENAI_API_KEY      - your OpenAI key (for receipt vision); optional —
//                         /v1/vision/receipt returns 503 if missing.
//
// Optional bindings / env:
//   RATE_LIMIT_KV          - Workers KV namespace for per-IP counts
//   DAILY_LIMIT            - chat: requests per IP per day (default 200)
//   VISION_DAILY_LIMIT     - vision: scans per IP per day (default 30)

const DEEPSEEK_URL = 'https://api.deepseek.com/chat/completions';
const OPENAI_URL   = 'https://api.openai.com/v1/chat/completions';
const VISION_MODEL = 'gpt-4o-mini';

// Abuse caps. The shared secret ships in the IPA and is extractable, so the
// only thing standing between a leaked secret and a runaway provider bill is
// (a) the per-IP daily rate limit and (b) these hard ceilings on what a
// single request can cost. Keep them generous enough for real use but tight
// enough that one abusive request can't be expensive.
const MAX_BODY_BYTES   = 12 * 1024 * 1024; // 12 MB hard request cap
const MAX_IMAGE_B64    = 12 * 1024 * 1024; // ~9 MB raw image after base64
const MAX_CHAT_CHARS   = 200 * 1000;       // total chars across chat messages
const MAX_CHAT_TOKENS  = 2048;             // clamp client-supplied max_tokens
// DeepSeek models we allow the chat endpoint to request. Anything else is
// coerced to deepseek-chat so a leaked secret can't invoke a pricier model.
const ALLOWED_CHAT_MODELS = ['deepseek-chat', 'deepseek-reasoner'];
const ALLOWED_IMAGE_MIME = ['image/jpeg', 'image/png', 'image/heic', 'image/webp'];

export default {
  async fetch(request, env, ctx) {
    if (request.method === 'OPTIONS') {
      return cors(new Response(null, { status: 204 }));
    }
    if (request.method !== 'POST') {
      return cors(json({ error: 'method_not_allowed' }, 405));
    }

    // Reject oversized requests before reading the body (cost/DoS guard).
    const declaredLen = parseInt(request.headers.get('Content-Length') ?? '0', 10);
    if (declaredLen > MAX_BODY_BYTES) {
      return cors(json({ error: 'payload_too_large', limit: MAX_BODY_BYTES }, 413));
    }

    // Auth: shared secret. Constant-time compare to avoid timing leaks.
    const auth = request.headers.get('X-App-Auth') ?? '';
    const secret = env.APP_SHARED_SECRET ?? '';
    if (!secret || !timingSafeEqual(auth, secret)) {
      return cors(json({ error: 'unauthorized' }, 401));
    }

    const url = new URL(request.url);
    if (url.pathname === '/v1/chat/completions') {
      return handleChat(request, env, ctx);
    }
    if (url.pathname === '/v1/vision/receipt') {
      return handleVisionReceipt(request, env, ctx);
    }
    return cors(json({ error: 'not_found' }, 404));
  },
};

// MARK: - Chat completions (DeepSeek)

async function handleChat(request, env, ctx) {
  if (!env.DEEPSEEK_API_KEY) {
    return cors(json({ error: 'misconfigured' }, 500));
  }

  const rl = await checkRateLimit(env, ctx, request, 'rl', env.DAILY_LIMIT ?? '200');
  if (rl) return cors(rl);

  // Parse + sanitize rather than blindly forwarding. A holder of the shared
  // secret shouldn't be able to request an expensive model, an unbounded
  // completion, or a giant prompt on our DeepSeek account.
  let parsed;
  try {
    parsed = await request.json();
  } catch (e) {
    return cors(json({ error: 'bad_request', detail: 'body must be JSON' }, 400));
  }
  if (!parsed || !Array.isArray(parsed.messages) || parsed.messages.length === 0) {
    return cors(json({ error: 'bad_request', detail: 'messages[] required' }, 400));
  }

  // Total prompt size guard.
  let totalChars = 0;
  for (const m of parsed.messages) {
    if (typeof m?.content === 'string') totalChars += m.content.length;
  }
  if (totalChars > MAX_CHAT_CHARS) {
    return cors(json({ error: 'prompt_too_large', limit: MAX_CHAT_CHARS }, 413));
  }

  // Force a known-cheap model + clamp completion length.
  const safeBody = {
    model: ALLOWED_CHAT_MODELS.includes(parsed.model) ? parsed.model : 'deepseek-chat',
    messages: parsed.messages,
    temperature: typeof parsed.temperature === 'number' ? parsed.temperature : 0.3,
    max_tokens: Math.min(
      typeof parsed.max_tokens === 'number' ? parsed.max_tokens : MAX_CHAT_TOKENS,
      MAX_CHAT_TOKENS
    ),
  };

  let upstream;
  try {
    upstream = await fetch(DEEPSEEK_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${env.DEEPSEEK_API_KEY}`,
      },
      body: JSON.stringify(safeBody),
    });
  } catch (e) {
    return cors(json({ error: 'upstream_unreachable' }, 502));
  }

  const respBody = await upstream.text();
  return cors(new Response(respBody, {
    status: upstream.status,
    headers: {
      'Content-Type': upstream.headers.get('Content-Type') ?? 'application/json',
    },
  }));
}

// MARK: - Vision receipt scan (OpenAI GPT-4o mini)

// Expected input body:  {"image_base64": "<jpeg base64>", "mime_type": "image/jpeg"}
// Expected output:      {"merchant": ..., "date": "YYYY-MM-DD", "total": <num>,
//                        "items": [{"name": ..., "amount": <num>, "category": "..."}]}

const CATEGORIES = [
  'rent', 'utilities', 'groceries', 'diningOut', 'transportation',
  'entertainment', 'householdSupplies', 'personalCare', 'healthcare', 'other'
];

const GROCERY_STORES = [
  'costco', 'walmart', 'target', 'safeway', 'trader joe', 'whole foods',
  'kroger', 'h-e-b', 'heb', 'publix', 'aldi', "sam's club", 'sams club',
  'wegmans', 'meijer', 'food lion', 'giant', 'stop & shop', 'shoprite'
];

function visionSystemPrompt() {
  return `You read a photo of a retail receipt and return STRICT JSON with this schema:
{
  "merchant": string (short store name, e.g. "Costco"),
  "date": "YYYY-MM-DD" or null,
  "subtotal": number (the SUBTOTAL line as printed, before tax; null if not printed),
  "savings": number (total discounts / instant savings as a POSITIVE number; 0 if none),
  "tax": number (the total TAX as printed; 0 if none),
  "total": number (the final TOTAL actually paid),
  "items": [
    { "name": string (1-4 words, plain English), "amount": number, "category": one of ${CATEGORIES.join('|')} }
  ]
}

Rules:
- Capture EVERY line item on the receipt. Do not skip items. Do not invent items.
- Item amounts are the line price (after multiplying quantity if printed that way).
- Read subtotal, tax, savings, and total EXACTLY as printed on the receipt —
  do not compute them yourself. If the receipt prints a TAX line, "tax" must
  match it. Discounts / instant savings / coupons go in "savings" as a
  positive number. Normally total = subtotal - savings + tax.
- Use clean readable names: "WHL MLK GAL" -> "Whole milk gallon", "KS PAPER TWLS" -> "Kirkland paper towels".
- Each item gets ONE category. Pick the most specific match. Do not default everything to "groceries".

Category guide:
- groceries: edible food/drink for home (milk, eggs, produce, meat, bread, snacks, soda, bottled water, coffee beans, condiments, sauces, frozen meals, prepared/deli/bakery items bought at a grocery or warehouse store like rotisserie chicken, street tacos, take-and-bake meals).
- diningOut: RESTAURANT, cafe, bar, or coffee-shop receipts only. Not items taken home from a grocery store.
- transportation: gasoline, parking, tolls, transit fares, ride share, car wash, motor oil.
- householdSupplies: paper towels, toilet paper, dish soap, laundry detergent, cleaning products, trash bags, foil, batteries, light bulbs, kitchen tools, small appliances, electronics, hardware, pet supplies.
- personalCare: shampoo, toothpaste, makeup, razors, deodorant.
- healthcare: OTC medicine, vitamins, prescriptions, bandages.
- entertainment: movie tickets, streaming, books, games, toys, hobby supplies.
- utilities, rent: bills only — almost never on a retail receipt.
- other: only if nothing fits.

GROCERY-STORE CONTEXT: if the merchant is Costco, Walmart, Target, Safeway, Trader Joe's, Whole Foods, Kroger, H-E-B, Publix, Aldi, Sam's Club, Wegmans, Meijer, Food Lion, Giant, Stop & Shop, ShopRite — prepared foods sold there (rotisserie, deli, take-and-bake, hot bar, sushi, bakery, frozen meals, meatballs, lasagna, pesto, sauces) are ALL "groceries", NOT "diningOut". DiningOut is reserved for actual restaurant/cafe/bar receipts.

Return ONLY the JSON object. No prose, no markdown, no code fences.`;
}

async function handleVisionReceipt(request, env, ctx) {
  if (!env.OPENAI_API_KEY) {
    return cors(json({
      error: 'vision_not_configured',
      detail: 'OPENAI_API_KEY is not set on the worker.'
    }, 503));
  }

  const rl = await checkRateLimit(env, ctx, request, 'vsn', env.VISION_DAILY_LIMIT ?? '30');
  if (rl) return cors(rl);

  let payload;
  try {
    payload = await request.json();
  } catch (e) {
    return cors(json({ error: 'bad_request', detail: 'body must be JSON' }, 400));
  }
  const imageBase64 = payload?.image_base64;
  const mimeType = payload?.mime_type || 'image/jpeg';
  if (typeof imageBase64 !== 'string' || imageBase64.length < 100) {
    return cors(json({ error: 'bad_request', detail: 'image_base64 missing or too small' }, 400));
  }
  if (imageBase64.length > MAX_IMAGE_B64) {
    return cors(json({ error: 'payload_too_large', limit: MAX_IMAGE_B64 }, 413));
  }
  if (!ALLOWED_IMAGE_MIME.includes(mimeType)) {
    return cors(json({ error: 'bad_request', detail: 'unsupported mime_type' }, 400));
  }

  const openaiBody = {
    model: VISION_MODEL,
    response_format: { type: 'json_object' },
    max_tokens: 2000,
    temperature: 0,
    messages: [
      { role: 'system', content: visionSystemPrompt() },
      {
        role: 'user',
        content: [
          { type: 'text', text: 'Extract every line item from this receipt as JSON per the schema.' },
          {
            type: 'image_url',
            image_url: {
              url: `data:${mimeType};base64,${imageBase64}`,
              detail: 'high'  // small text on receipts needs high-detail vision
            }
          }
        ]
      }
    ]
  };

  let upstream;
  try {
    upstream = await fetch(OPENAI_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${env.OPENAI_API_KEY}`,
      },
      body: JSON.stringify(openaiBody),
    });
  } catch (e) {
    return cors(json({ error: 'upstream_unreachable' }, 502));
  }

  if (!upstream.ok) {
    // Don't echo the upstream error body to the client (it can contain
    // provider org/account metadata). Log-free: just surface the status.
    return cors(json({ error: 'upstream_error', status: upstream.status }, 502));
  }

  // Pull the assistant's JSON string out of the OpenAI envelope and pass
  // just the parsed object back to the iOS client, so the app doesn't
  // need to know OpenAI's response shape.
  let openaiResp;
  try {
    openaiResp = await upstream.json();
  } catch (e) {
    return cors(json({ error: 'malformed_upstream', detail: String(e) }, 502));
  }
  const content = openaiResp?.choices?.[0]?.message?.content;
  if (typeof content !== 'string') {
    return cors(json({ error: 'malformed_upstream', detail: 'no content' }, 502));
  }
  let parsed;
  try {
    parsed = JSON.parse(content);
  } catch (e) {
    return cors(json({ error: 'malformed_json', detail: content.slice(0, 500) }, 502));
  }

  return cors(json(parsed, 200));
}

// MARK: - Rate limit helper (shared between chat + vision)

/// Returns a Response if the request should be blocked, or null to allow.
async function checkRateLimit(env, ctx, request, prefix, limitStr) {
  if (!env.RATE_LIMIT_KV) return null;
  const ip = request.headers.get('CF-Connecting-IP') ?? 'unknown';
  const day = new Date().toISOString().slice(0, 10);
  const key = `${prefix}:${ip}:${day}`;
  const limit = parseInt(limitStr, 10);
  const current = parseInt((await env.RATE_LIMIT_KV.get(key)) ?? '0', 10);
  if (current >= limit) {
    return json({ error: 'rate_limited', limit, day, scope: prefix }, 429);
  }
  ctx.waitUntil(env.RATE_LIMIT_KV.put(
    key, String(current + 1),
    { expirationTtl: 60 * 60 * 26 }
  ));
  return null;
}

// MARK: - HTTP helpers

function json(obj, status = 200) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

function cors(response) {
  const headers = new Headers(response.headers);
  headers.set('Access-Control-Allow-Origin', '*');
  headers.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  headers.set('Access-Control-Allow-Headers', 'Content-Type, X-App-Auth');
  return new Response(response.body, { status: response.status, headers });
}

function timingSafeEqual(a, b) {
  if (a.length !== b.length) return false;
  let mismatch = 0;
  for (let i = 0; i < a.length; i++) {
    mismatch |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return mismatch === 0;
}
