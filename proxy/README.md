# Splitway assistant proxy

Cloudflare Worker that sits between the Splitway iOS app and DeepSeek's
chat-completions endpoint. Reason it exists: the DeepSeek API key never ships
in the iOS binary, we can rotate it in seconds without an App Update, and we
get per-IP rate limiting cheaply.

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

# 4. (Recommended) per-IP rate limit. Create a KV namespace:
wrangler kv namespace create RATE_LIMIT_KV
#    Copy the printed `id`. Edit wrangler.toml: uncomment the
#    [[kv_namespaces]] block and paste the id.

# 5. Deploy
wrangler deploy
```

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

In Xcode, target Splitway → Info plist, set (or edit `project.yml` if you
regenerate via xcodegen):

| Key | Value |
|---|---|
| `SplitwayAssistantBaseURL` | `https://api.splitway.app` (or the workers.dev URL) |
| `SplitwayAssistantSharedSecret` | the long random string from `wrangler secret put APP_SHARED_SECRET` |

Build and run. The "AI assistant" toggle in Settings now just works for Pro
users; the user never enters an API key.

If those Info.plist keys are blank or missing, the assistant gracefully
falls back to "not configured" with a Settings link, the same way it used
to when the user hadn't pasted a key.

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
