// Splitway assistant proxy. Cloudflare Worker.
//
// Forwards POSTs from the Splitway iOS app to DeepSeek, injecting our master
// API key server-side. The app authenticates with a shared secret in the
// X-App-Auth header, and an optional KV-backed per-IP daily counter caps abuse.
//
// Required Worker secrets (set via `wrangler secret put`):
//   DEEPSEEK_API_KEY    - your DeepSeek key, never ships in the iOS binary
//   APP_SHARED_SECRET   - long random string; matches what's compiled into the app
//
// Optional bindings:
//   RATE_LIMIT_KV       - Workers KV namespace for per-IP counts
//   DAILY_LIMIT         - env var, requests per IP per day (default 200)

const DEEPSEEK_URL = 'https://api.deepseek.com/chat/completions';

export default {
  async fetch(request, env, ctx) {
    if (request.method === 'OPTIONS') {
      return cors(new Response(null, { status: 204 }));
    }
    if (request.method !== 'POST') {
      return cors(json({ error: 'method_not_allowed' }, 405));
    }

    const url = new URL(request.url);
    if (url.pathname !== '/v1/chat/completions') {
      return cors(json({ error: 'not_found' }, 404));
    }

    // Auth: shared secret. Constant-time compare to avoid timing leaks.
    const auth = request.headers.get('X-App-Auth') ?? '';
    const secret = env.APP_SHARED_SECRET ?? '';
    if (!secret || !timingSafeEqual(auth, secret)) {
      return cors(json({ error: 'unauthorized' }, 401));
    }

    if (!env.DEEPSEEK_API_KEY) {
      return cors(json({ error: 'misconfigured' }, 500));
    }

    // Per-IP daily rate limit (best-effort; relies on KV when bound).
    if (env.RATE_LIMIT_KV) {
      const ip = request.headers.get('CF-Connecting-IP') ?? 'unknown';
      const day = new Date().toISOString().slice(0, 10);
      const key = `rl:${ip}:${day}`;
      const limit = parseInt(env.DAILY_LIMIT ?? '200', 10);
      const current = parseInt((await env.RATE_LIMIT_KV.get(key)) ?? '0', 10);
      if (current >= limit) {
        return cors(json({ error: 'rate_limited', limit, day }, 429));
      }
      // Fire-and-forget the counter increment so we don't block the request.
      ctx.waitUntil(env.RATE_LIMIT_KV.put(
        key, String(current + 1),
        { expirationTtl: 60 * 60 * 26 } // expire ~26h after the day starts
      ));
    }

    // Forward the body as-is; only the auth header is replaced with ours.
    const body = await request.text();
    let upstream;
    try {
      upstream = await fetch(DEEPSEEK_URL, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${env.DEEPSEEK_API_KEY}`,
        },
        body,
      });
    } catch (e) {
      return cors(json({ error: 'upstream_unreachable', detail: String(e) }, 502));
    }

    const respBody = await upstream.text();
    return cors(new Response(respBody, {
      status: upstream.status,
      headers: {
        'Content-Type': upstream.headers.get('Content-Type') ?? 'application/json',
      },
    }));
  },
};

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
