# Splitway assistant proxy

Cloudflare Worker that sits between the Splitway iOS app and two upstream
providers:

- **DeepSeek** — chat assistant + receipt line-item name cleanup
- **OpenAI GPT-4o mini** — vision OCR for receipt scanning (line items +
  categories in one call)

Reason it exists: API keys never ship in the iOS binary, we can rotate
them in seconds without an App Update, and we get per-IP rate limiting
cheaply. The OpenAI vision path is rate-limited tighter than chat
(default 30 scans/IP/day) because each call costs real money
(~$0.001-0.003).

## What gets deployed where

```
iPhone (Splitway app)
        │  POST /v1/chat/completions
        │  Headers: X-App-Auth: <shared secret>
        ▼
api.splitway.app  →  Cloudflare Worker  ─Authorization: Bearer DEEPSEEK_KEY→  api.deepseek.com
```

The worker is one file, ~120 lines. It:
1. Rejects non-POST and unknown paths.
2. Verifies the `X-App-Auth` shared-secret header (constant-time compare).
3. Optionally enforces a daily per-IP cap via Workers KV.
4. Forwards the body to DeepSeek with our key injected server-side.
5. Returns DeepSeek's response unchanged.

## One-time deploy (≈ 10 minutes)

You'll need a Cloudflare account (free tier is plenty for a household beta;
100k requests/day, way more than needed).

```sh
# 1. Install wrangler
npm i -g wrangler

# 2. Authenticate
wrangler login

# 3. From this proxy/ directory, set the two secrets
wrangler secret put DEEPSEEK_API_KEY
#    paste your DeepSeek key when prompted

wrangler secret put APP_SHARED_SECRET
#    paste a long random string. Generate one with:
#      openssl rand -hex 32
#    Save this. You'll paste it into Xcode too.

# 3a. (Optional but recommended) OpenAI key for receipt vision scanning.
#     The /v1/vision/receipt endpoint forwards to GPT-4o mini which does
#     OCR + line-item extraction + categorization in one call. If this
#     key isn't set, the app falls back to local Apple Vision OCR.
wrangler secret put OPENAI_API_KEY
#    paste your OpenAI key (starts with "sk-..." from platform.openai.com).

# 4. STRONGLY RECOMMENDED: per-IP rate limit. This is your main defense
#    against a leaked shared secret running up the provider bill. Without
#    it there is NO daily cap. Create a KV namespace:
wrangler kv namespace create RATE_LIMIT_KV
#    Copy the printed `id`. Edit wrangler.toml: uncomment the
#    [[kv_namespaces]] block and paste the id.

# 5. Deploy
wrangler deploy
```

### Built-in abuse protections

Even without KV, the worker enforces hard per-request ceilings so one
request can't be expensive: 12 MB max body, 12 MB max image, 200k-char
max chat prompt, completions clamped to 2048 tokens, and the chat model
is coerced to an allowlist (deepseek-chat / deepseek-reasoner) so a
leaked secret can't invoke a pricier model. The per-IP daily limit (KV)
adds the volume cap on top — set it up.

Wrangler prints the deployed URL, something like:
`https://splitway-assistant.<your-account>.workers.dev`

Test it from your machine:
```sh
curl -i https://splitway-assistant.<your-account>.workers.dev/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "X-App-Auth: <the shared secret you set>" \
  -d '{"model":"deepseek-chat","messages":[{"role":"user","content":"Say hello"}]}'
```

Expect a 200 with a DeepSeek-format JSON response.

### Optional: custom domain `api.splitway.app`

In the Cloudflare dashboard for the `splitway.app` zone:
1. Add a CNAME or worker route for `api` → the worker.
2. In `wrangler.toml`, uncomment the `[[routes]]` block.
3. `wrangler deploy` again.

## Configure the iOS app

The two values live in `Splitway/Config/Secrets.xcconfig`, which is
**gitignored**. Don't paste secrets into `project.yml`; that file is
committed and the repo is public.

1. Copy the template:
   ```sh
   cp Splitway/Config/Secrets.xcconfig.example \
      Splitway/Config/Secrets.xcconfig
   ```
2. Open `Splitway/Config/Secrets.xcconfig` and fill in:
   - `SPLITWAY_ASSISTANT_BASE_URL` — your workers.dev URL (the `$()` between
     `https:` and `//` is a required xcconfig escape; don't remove it)
   - `SPLITWAY_ASSISTANT_SHARED_SECRET` — the random string from
     `wrangler secret put APP_SHARED_SECRET`
3. Regenerate the Xcode project: `xcodegen generate`
4. Build and run. The "AI assistant" toggle in Settings just works; the
   user never enters an API key.

`project.yml` references those via `$(SPLITWAY_ASSISTANT_…)` in the
Info.plist properties, and the target's `configFiles` pulls them from
`Secrets.xcconfig` at build time.

If those values are blank or missing, the assistant gracefully falls back
to "not configured" with a Settings link, the same way it used to when the
user hadn't pasted a key.

## Rotate the DeepSeek key

If the key leaks:
```sh
wrangler secret put DEEPSEEK_API_KEY
#    paste the new key
```
That's it. No app update needed.

## Rotate the shared secret

If you suspect abuse from a leaked shared secret (someone reverse-engineered
the IPA and is hammering your worker):
1. `wrangler secret put APP_SHARED_SECRET` (paste a fresh random string)
2. Update `SplitwayAssistantSharedSecret` in the app's Info.plist
3. Ship an app update via TestFlight / App Store
4. Old binaries stop working against the proxy immediately

Day-to-day this isn't necessary; the per-IP rate limit and key rotation
cover ~99% of abuse.

## Limits and upgrade path

- **Cloudflare Workers free tier:** 100,000 requests/day, 10ms CPU per request.
  Way more than a household beta needs.
- **Workers KV free tier:** 100k reads + 1k writes/day. The rate limiter
  uses one read + one write per request, so the KV write limit is the
  binding constraint at scale. If you exceed ~1k requests/day, either
  upgrade to the paid plan ($5/mo) or switch the limiter to Durable Objects.
- **DeepSeek cost:** is on your account, not Cloudflare's. Monitor at
  platform.deepseek.com. With the curated chip set in the assistant and one
  cleanup call per scan, expected cost per active user is small (cents/month
  range), but watch the dashboard during beta.
