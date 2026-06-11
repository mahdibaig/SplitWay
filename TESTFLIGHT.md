# Splitway → TestFlight checklist

Everything needed to get Splitway from this repo onto TestFlight, then to
the App Store. Items marked **[done]** are already handled in code/config.
Items marked **[you]** need you to do something in Xcode, the Apple
Developer portal, or App Store Connect (ASC) — Claude can't do those.

Bundle ID: `com.mahdibaig.splitway`
Current version: `1.0.0 (1)`

---

## 0. Already handled in the project [done]

- [x] App icon: 1024×1024, no alpha (App Store compliant)
- [x] Privacy manifest `PrivacyInfo.xcprivacy` (UserDefaults reason + data types)
- [x] `ITSAppUsesNonExemptEncryption = false` (auto-answers export compliance)
- [x] `aps-environment` driven per config (development for dev, production for the archive — CloudKit sync needs it)
- [x] `LSApplicationCategoryType = finance`
- [x] StoreKit config wired into the scheme for local testing
- [x] Camera usage string present; PhotosPicker/document picker need no string
- [x] Version set to 1.0.0

---

## 1. One-time account setup [you]

- [ ] Apple Developer Program membership active (business account — already verified)
- [ ] In **Xcode → Settings → Accounts**, your Apple ID is signed in and shows the team
- [ ] Find your **Team ID** (10 chars, e.g. `A1B2C3D4E5`) at developer.apple.com → Membership

### Add your Team ID to the build
Open `Splitway/Config/Secrets.xcconfig` (gitignored — your local copy) and add:
```
DEVELOPMENT_TEAM = A1B2C3D4E5
```
(use your real Team ID). Then `xcodegen generate`. This keeps the team ID
out of the public repo while letting the archive sign.

---

## 2. App Store Connect — create the app record [you]

1. appstoreconnect.apple.com → **Apps → +** → New App
2. Platform: iOS, Name: **Splitway**, Primary language: English (U.S.)
3. Bundle ID: select `com.mahdibaig.splitway` (register it at
   developer.apple.com → Identifiers first if it's not in the dropdown;
   enable **iCloud** and **Push Notifications** capabilities on the
   identifier — both are used by CloudKit sync)
4. SKU: anything unique, e.g. `splitway-001`

---

## 3. In-app purchases — REQUIRED for the paywall to work on TestFlight [you]

The local `Splitway.storekit` file is IGNORED on TestFlight. The onboarding
trial page and paywall read products from ASC. Create these four
auto-renewable subscriptions in **ASC → your app → Subscriptions**, all in
one subscription group named **Splitway Pro**:

| Product ID | Display name | Price | Duration | Intro offer | Family Sharable |
|---|---|---|---|---|---|
| `splitway_individual_monthly` | Individual Monthly | $4.99 | 1 month | 7-day free trial | No |
| `splitway_individual_yearly` | Individual Yearly | $44.99 | 1 year | 7-day free trial | No |
| `splitway_household_monthly` | Household Monthly | $12.99 | 1 month | 7-day free trial | Yes |
| `splitway_household_yearly` | Household Yearly | $109.99 | 1 year | 7-day free trial | Yes |

- Product IDs must match EXACTLY (they're in `ProductID` in
  `Splitway/Models/Domain/SubscriptionTier.swift`).
- For each: add a **localized display name + description**, a **price**,
  and an **Introductory Offer** = Free, 1 week.
- Mark BOTH **Household** products **Family Sharable**; leave both
  **Individual** products not sharable. This build relies on Apple Family
  Sharing to give the whole household Pro, so the flag is load-bearing.
- Set subscription **levels** so Household ranks above Individual (Household
  = higher service level) for correct upgrade/downgrade.
- Add a **subscription group display name** and at least one **review
  screenshot** per product (ASC requires it before review).

> **Duo is intentionally NOT in this build.** The code wires up
> `splitway_duo_monthly` / `splitway_duo_yearly` but holds them out of the
> paywall until CloudKit-based Pro sharing ships (a "2 people" plan can't be
> enforced through Apple Family Sharing, which allows up to 6). Do NOT create
> the Duo products in ASC yet. Lifetime is also intentionally not shipping.

> Until these exist and are in "Ready to Submit" / approved state, the
> "Start my free week" button on TestFlight will be disabled and prices
> fall back to placeholder text. IAPs are reviewed alongside your first
> build — submit them with the build.

---

## 4. Privacy [you]

- [ ] **Privacy policy URL** (required for external TestFlight + App Store).
      A draft is in `PRIVACY.md` — review it, then host it somewhere public
      (GitHub Pages, a Notion public page, your own domain) and paste the
      URL into ASC → App Privacy and ASC → App Information.
- [ ] **App Privacy questionnaire** (ASC → App Privacy). Based on how
      Splitway actually works, declare:
  - **Financial Info → Other Financial Info**: collected, used for App
    Functionality, **not** linked to identity, **not** used for tracking.
  - **User Content → Photos or Videos** (receipt images): same — App
    Functionality, not linked, not tracking.
  - Everything else: Not Collected. No tracking. No third-party ads.
  - Note in your own records: receipt images + spending summaries are sent
    to OpenAI (scanning) and DeepSeek (assistant) via your Cloudflare
    proxy. These are processing sub-processors; no identity is sent.

---

## 5. Archive & upload [you]

**Xcode (simplest):**
1. Plug in / select **Any iOS Device (arm64)** as the run destination
   (not a simulator).
2. `xcodegen generate` (if you changed anything).
3. **Product → Archive**. Wait for it to build.
4. Organizer opens → select the archive → **Distribute App → App Store
   Connect → Upload**. Accept the automatic signing prompts.
5. Wait ~5–15 min for the build to finish "Processing" in ASC.

**If Archive is greyed out:** destination is a simulator — switch to a
device / "Any iOS Device".

**Build number:** every upload needs a higher `CFBundleVersion`. For the
next upload bump `CURRENT_PROJECT_VERSION` in `project.yml` (1 → 2 → 3 …)
and regenerate. (Marketing version `1.0.0` can stay the same across builds.)

---

## 6. TestFlight [you]

- [ ] ASC → your app → **TestFlight** tab → wait for the build to leave
      "Processing".
- [ ] Answer the **export compliance** prompt (the `ITSAppUsesNonExemptEncryption=false`
      flag should auto-answer it → "No").
- [ ] **Internal testing** (you + up to 100 of your own team, no review
      needed): create a group, add your Apple ID, install via the
      TestFlight app on your phone. Fastest path to test the real build.
- [ ] **External testing** (friends/family, up to 10,000): requires a
      one-time **Beta App Review** (usually < 24h). You'll need: the
      privacy policy URL, a beta description, and a test account / notes.
      In the notes, mention: "AI receipt scanning and the assistant send
      data to a backend proxy; no login required."

---

## 7. Keep the backend alive [you]

The app's AI features depend on your Cloudflare Worker and its keys:
- [ ] Worker `splitway-assistant` is deployed (`wrangler deploy`)
- [ ] Secrets set: `OPENAI_API_KEY`, `DEEPSEEK_API_KEY`, `APP_SHARED_SECRET`
- [ ] OpenAI account has a payment method + a sensible monthly **usage cap**
      (Billing → Limits). $10–20/mo is plenty for a beta.
- [ ] The shared secret in `Secrets.xcconfig` matches the worker's
      `APP_SHARED_SECRET`.
- [ ] Vision scan rate limit is 30/IP/day (tune `VISION_DAILY_LIMIT` if needed).

> Note: the shared secret is compiled into the IPA and is extractable by a
> determined tester. That's the accepted trade-off — the per-IP rate limit
> and one-command key rotation cap any abuse. Rotate after the beta if you
> ever go fully public.

---

## 8. Before App Store submission (later, not needed for TestFlight)

- [ ] Screenshots for 6.7" and 6.5" iPhones (ASC requires them)
- [ ] App description, keywords, support URL, marketing URL
- [ ] Age rating questionnaire
- [ ] Decide final pricing (we'll review together)
- [ ] Submit build + IAPs together for App Review

---

## Quick gotcha reference

- **Paywall empty / trial button disabled on TestFlight** → IAP products
  not created in ASC yet, or still pending review (Section 3).
- **"No account for team" / signing error on Archive** → `DEVELOPMENT_TEAM`
  not set in `Secrets.xcconfig` (Section 1).
- **CloudKit doesn't sync on the TestFlight build** → confirm the App ID
  has iCloud + Push capabilities and the container
  `iCloud.com.mahdibaig.splitway` exists in the CloudKit dashboard, and
  that you've deployed the schema to the **Production** CloudKit
  environment (CloudKit Console → Deploy Schema Changes).
- **Build stuck "Processing" > 1h** → usually a missing export-compliance
  answer; check the TestFlight tab for a prompt.
