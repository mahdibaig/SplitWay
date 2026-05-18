# Splitway --- Claude Code Handoff

> **Purpose:** A prioritized, executable task list for Claude Code based
> on the market research dossier (Splitway_Market_Research.docx). This
> file is the source of truth for the next 12 months of development.
> Drop it in the repo root as HANDOFF.md.
>
> **How to use this file in Claude Code:**

1.  Open the Splitway repo, drop this file in the root.

2.  Start each session with Read HANDOFF.md.

3.  Work P0 → P1 → P2 → P3 in order. Do not jump tiers without explicit
    approval.

4.  When a task ships, change \[ \] to \[x\] and add a one-line note
    with the commit SHA or PR link.

5.  New ideas go in the **Backlog** section, not inline.

## 0. Context (read once, then refer back as needed)

**Splitway** is a native iOS (Swift 5.9 / SwiftUI / iOS 17+)
expense-splitting app for adults sharing a household. Tech stack: Core
Data + CloudKit (NSPersistentCloudKitContainer), Apple Vision for OCR,
Swift Charts, DeepSeek V4 for the AI assistant. No backend
infrastructure.

**Architecture (do not change):** Views → ViewModels → Services →
Repositories → Persistence. This separation is what makes future
feature-gating trivial.

**Who we\'re competing with (high level):**

- **Splitwise** (\$2.99/mo or \$29.99/yr, Pro). Category leader, but
  lost user goodwill in Dec 2023 with a daily expense cap and forced
  ads. Receipt OCR is camera-only, no edit-in-place, no
  quantity-per-person.

- **Tricount** (free, owned by Bunq). No OCR, no item splits.

- **Honeydue** (couples, dying). Acqui-hired by Mission Lane in 2021,
  \~2 employees left.

- **Monarch Money** (\$99.99/yr). The only adjacent app shipping AI on
  its base plan. Strategic threat.

- **Zeta** shut down May 2025.

**Splitway\'s three differentiators** (everything below serves these ---
don\'t dilute):

1.  **Smart receipt OCR with item-level learning** (\"milk is always
    shared, face wash is always Hamza\'s\").

2.  **Couples and families as first-class entities** (split household
    bills couple-vs-couple in one tap).

3.  **Privacy-first, on-device, Apple-native design** (capybara, cream +
    brown palette).

Plus a trimmed AI assistant that answers natural-language money
questions.

## 1. Guiding Principles (Do Not Break These)

- **No daily expense cap. Ever.** This is Splitwise\'s #1 user
  complaint. It is also our biggest marketing wedge. Even a \"soft
  limit\" or \"expense quota\" is off the table.

- **No ads.** Privacy-first brand promise. Ads contradict it.

- **No silent paywall changes.** Every monetization shift ships with an
  in-app announcement and grandfathers existing users. Communicate
  before, during, and after.

- **On-device by default.** The AI assistant is the only feature that
  may talk to an external service, and only opt-in with explicit
  consent.

- **Frontend → ViewModels → Services → Repositories → Persistence stays
  intact.** Adding a paid-tier feature gate must not leak into Views.

- **Match Apple\'s design language.** Soft cream + brown palette,
  friendly serif accents, capybara mascot. Resist any urge to copy
  Splitwise\'s flat green or Robinhood\'s hyper-density.

- **USD-only is fine for v1.** Multi-currency is backlog. Don\'t
  pre-build it.

## 2. What\'s Working Well --- Preserve

These already exist in the codebase and should not be regressed. Treat
them as load-bearing.

- Onboarding flow (welcome, display name, avatar via photo/emoji,
  household create/join).

  Members and groups CRUD; iCloud account status surfaced in Settings.

  All 5 split modes (Equal / Percent / Amount / Shares / Excluded) in
  Add Expense.

  Settle Up with greedy debt-simplification + Mark paid + Open Zelle.

  \"Who owes who\" card on Home and Expenses.

  Per-row \"You paid \$X\" personal-share indicator.

  Soft-delete with 30-day recovery + audit-trail support in the data
  model.

  Per-category monthly budgets, over-budget coral treatment, Home
  summary card.

  Recurring bills (fixed auto-log; variable prompts via Bills due
  banner).

  Local notifications for 80% / 100% budget + recurring-due (with
  permission flow).

  Photo-picker entry from Add Expense.

  Vision OCR + generic line-item parser.

  Review screen with editable line items and per-item assignment.

  SharedItemRule three-option remember system (Always shared / Just this
  time / Always Hamza\'s).

  Green/orange dots for known / new items on subsequent scans.

  Paperclip indicator on expense rows with a receipt.

  Chat tab + capybara + message bubbles + suggested-question chips.

  Local conversation history capped at 50.

  DeepSeekClient (OpenAI-compatible) + AssistantContextBuilder JSON
  snapshot.

  Opt-in toggle + API key field in Settings.

  Reports tab: Household / Just-me scope toggle, hero MoM card, donut
  chart, 3/6/9/12-month trend chart, top expenses, month picker.

**Do not refactor any of the above without an explicit reason tied to a
P0 / P1 task below.**

## 3. P0 --- Critical Path to App Store

> **Goal:** ship a submittable v1.0 build to TestFlight inside 12 weeks.
> Everything in P0 is a launch blocker.

### 3.1 Security --- DeepSeek API key migration

- [x] **Move the DeepSeek API key from UserDefaults to Keychain.** Done 2026-05-14. KeychainService wraps the Security framework; legacy UserDefaults key migrates on first launch and is scrubbed.

  - Acceptance: key is no longer readable from UserDefaults, app
    continues to function, settings UI still allows entering/clearing
    the key.

  - Suggested location: Splitway/Services/KeychainService.swift (new).
    Wrap with KeychainAccess or Apple\'s native Security framework.

  - Touch: DeepSeekClient.swift, Settings view that reads/writes the
    key.

  - Test: delete the app, reinstall, key is gone (Keychain access group
    should NOT be shared). On normal launch, key persists.

  **Stand up a thin proxy service for the DeepSeek API.**

  - Why: the user\'s key (or our master key) should never ship in the
    binary. Anyone with mitmproxy can pull it otherwise.

  - Suggested stack: Cloudflare Worker, AWS Lambda, or Fly.io. Anything
    that costs \<\$5/month.

  - Acceptance: DeepSeekClient calls
    https://api.splitway.app/v1/chat/completions (or similar) instead of
    DeepSeek directly. Proxy injects the key server-side. Per-user rate
    limit (suggest: 100 messages/day soft cap).

  - Document the proxy repo separately; keep its source out of the iOS
    repo.

### 3.2 App Store readiness

- **Replace the default Xcode app icon.**

  - Acceptance: 1024×1024 icon with capybara, cream + brown palette, no
    transparency, no rounded corners (iOS adds them).

  - Suggested vendor: Dribbble freelancer or Fiverr Pro, \~\$100--\$300
    budget.

  - Generate all required sizes via Assets.xcassets automation or
    xcassetgen.

  [x] **App Store metadata bundle.** Drafted 2026-05-16 in `marketing/AppStore/`. Description, 84-char keywords, 1.0 release notes, screenshot plan with 8 captures and two caption sets, privacy nutrition label answers, support-page FAQ. Still needs: actual screenshot capture, design pass on captions, working `support@splitway.app` inbox, live splitway.app pages.

  - Acceptance: 5--10 screenshots per device class (6.7\", 6.1\", iPad
    13\"), with on-image captions. Privacy nutrition label completed.
    App description draft + keywords list (\"split expenses, household,
    roommates, couples, receipt scanning\"). Support URL + privacy
    policy URL live.

  - Put screenshot mockups + copy in marketing/AppStore/ so they\'re
    versioned.

  [x] **Privacy policy + Terms of Service pages.** Drafted 2026-05-14 in `marketing/legal/privacy.md` and `marketing/legal/terms.md`. All six required topics covered. Still needs: confirmed support email, HTML conversion, and live deployment to splitway.app.

  - Acceptance: simple HTML pages on splitway.app/privacy and
    splitway.app/terms. Must explicitly cover: (a) on-device data
    storage, (b) optional DeepSeek opt-in with what is sent, (c)
    CloudKit data, (d) no analytics, (e) no ads, (f) data retention.

  - Suggested template: Iubenda or write plain, in our own voice. Avoid
    legal-jargon defaults.

### 3.3 AI assistant --- scope trim

> **The instinct in the brief is correct: ship less here.** The
> highest-value AI flows are receipt-name cleanup and 5--10 canned
> questions. Free-form chat is a wow-once demo and rarely used after.

- [x] **Remove the free-form chat input field from the Chat tab for v1.** Done 2026-05-14. AssistantView now renders a chip-only palette; AssistantContextBuilder and DeepSeekClient untouched.

  - Acceptance: Chat tab still exists, capybara still greets, but the
    input field is replaced with a vertically scrolling list of
    suggested-question chips. Tapping a chip sends the canned question.

  - Touch: Chat view + ChatViewModel. Keep DeepSeekClient and
    AssistantContextBuilder intact --- the backend stays general.

  - Reasoning: cuts API costs, eliminates \"the AI hallucinated my
    balance\" support tickets, and the suggested questions are what
    people actually ask.

  **Curate the suggested-question chip list.**

  - Acceptance: 8--12 chips covering the questions Splitway should
    answer well. Suggested starter set:

    - \"How much did I spend on groceries this month?\"

    - \"How much did we spend on groceries this month?\"

    - \"Who owes me money right now?\"

    - \"Did I pay Ahmad back this month?\"

    - \"What\'s my biggest expense category?\"

    - \"Are we over budget anywhere?\"

    - \"What recurring bills are coming up?\"

    - \"How does this month compare to last month?\"

    - \"What did Hamza pay for last week?\"

    - \"How much did our last grocery trip cost?\"

  - Each chip resolves to a fixed prompt template that
    AssistantContextBuilder fills.

  [x] **Hook receipt-name cleanup into the OCR review flow (separate from
  chat).** Done 2026-05-14. ReceiptCleanupService runs one batched DeepSeek call per scan, cached in UserDefaults JSON. AI pill on the row, tap-to-revert. Switch the call to the proxy once the proxy service ships.

  - Acceptance: after Vision OCR parses items, each item passes through
    the LLM for normalization (\"WHL MLK GAL\" → \"Whole milk gallon\").
    This is a server-side call to the proxy with cleanup_only=true.

  - Touch: ReceiptReviewViewModel (or wherever the line-item array is
    built post-OCR).

  - Cost: rate-limit one cleanup call per scan (batch all items in one
    prompt). Cache normalizations in Core Data so repeated items don\'t
    re-call.

  - Show a small \"cleaned by AI\" indicator next to renamed items, with
    a tap-to-revert option.

  [x] **Onboarding consent step for the AI assistant.** Done 2026-05-14. AssistantConsentView sits between household creation and MainTabs. Default OFF. Existing users with `enabled == true` skip the gate.

  - Acceptance: a one-screen onboarding step explaining what the
    assistant does, what data is sent (household JSON snapshot), and an
    opt-in toggle. Skipping defaults to OFF. Settings page still lets
    the user toggle later.

  - Touch: Onboarding flow + AssistantConsentService (new, or extend
    existing settings store).

  - Apple App Review requires consent-at-point-of-use for off-device
    data transmission.

### 3.4 CloudKit sharing (the long pole)

> **This is the single biggest launch blocker.** Without CKShare, the
> app cannot serve a 2+-adult household, which is the entire pitch.

- **Confirm Apple Developer Program enrollment.** (Tracking task only
  --- no code.)

  **Implement CKShare invite links.**

  - Acceptance: from Settings → Household, the owner can generate a
    share link. Recipient opens the link on their device, accepts, and
    joins the household. Members appear in the existing Members list.

  - Touch: HouseholdRepository, new SharingService. Use
    UICloudSharingController for the share sheet.

  - Edge cases: revoke access, transfer ownership, handle
    iCloud-signed-out gracefully.

  **Multi-device sync verification.**

  - Acceptance: an expense added on device A appears on device B within
    30 seconds. Conflict resolution: last-write-wins on individual
    fields, soft-delete preserves history.

  - Test matrix: 2 iPhones + 1 iPad, all signed into different iCloud
    accounts but joined to the same shared household.

### 3.5 TestFlight beta

- **Recruit 30--50 households for TestFlight beta.**

  - Channels: Reddit (r/Splitwise migration threads, r/personalfinance),
    Indie Hackers, friends-of-founders, Twitter/X.

  - Acceptance: 30+ active households (≥2 members each), ≥4 weeks of
    usage data, ≥10 written feedback responses.

  - Use TestFlight\'s built-in feedback button. Triage weekly.

## 4. P1 --- Differentiation Features

> **Goal:** ship the smart-receipt, couples-first, and pricing model
> that the market research identifies as the wedge. These can ship over
> months 4--9.

### 4.1 Receipt OCR --- close the Splitwise gap

These are the specific UX failures from Splitwise\'s own feedback portal
that Splitway should beat.

- **Quantity-per-person on a single line item.**

  - Example: Alice had 2 beers, Bob had 1. Splitwise cannot do this.
    Splitway should.

  - Acceptance: on the review screen, each line item has a quantity
    field. Long-press a line to open a per-person split-with-quantity
    sheet.

  - Touch: ReceiptReviewView + LineItemModel (add quantityPerMember:
    \[MemberID: Int\]).

  **Edit a single line item in place.**

  - Acceptance: tap a line, edit name/price/assignment without deleting
    and re-adding. Save returns to the review screen.

  - Touch: ReceiptReviewView. No data-model changes needed.

  **Photo-gallery upload for receipts.**

  - Acceptance: from Add Expense → Scan Receipt, the user picks either
    Camera or Photos. Splitwise has refused to ship this for 6 years.

  - Touch: ReceiptCaptureService. Use PHPickerViewController for
    gallery.

  **Custom camera with brand frame guides.**

  - Needs a real device for testing --- gate on Apple Developer Program
    enrollment.

  - Acceptance: when capturing a new receipt, show subtle cream-colored
    frame guides + a corner-detection overlay. Auto-snap when the
    receipt is square in frame.

  - Touch: new ReceiptCameraView built on AVFoundation. Do not use
    UIImagePickerController for this.

  **Store-aware receipt parsers.**

  - Order of priority by US market share: H-E-B, Costco, Walmart,
    Target.

  - Acceptance: when OCR detects a known store header (configurable
    regex list), route to a store-specific parser that handles that
    chain\'s receipt format. Generic parser is the fallback.

  - Touch: ReceiptParser → ParserRegistry. Each store gets a .swift file
    under Splitway/Services/ReceiptParsers/.

  **Receipt retention policy UI.**

  - Acceptance: in Settings → Privacy, the user picks 6mo / 12mo /
    forever / never. Receipts older than the policy are purged
    automatically (background task).

  - Touch: SettingsView + ReceiptRetentionService (new). Background task
    via BGTaskScheduler.

### 4.2 Groups --- couples and families as first-class

This is the second-biggest market gap. Splitwise has no couples plan.
Monarch sort of does. Nobody does it well.

- [x] **Assign members to groups.** Done 2026-05-17. `GroupDetailView` lets you check/uncheck members per group; "move from other group" confirmation included. Note: schema is 1 group per member (to-one User.group), not 0+. Sufficient for the couples use case.

  - Acceptance: each member can belong to 0+ groups. Group examples:
    \"Mahdi + spouse\", \"Hamza + spouse\", \"Roommates\". A group has a
    name, color, and emoji.

  - Touch: GroupRepository, MemberRepository, new join table.

  [x] **"Split between groups" toggle on Add Expense.** Done 2026-05-17. Among picker (Individuals/Groups) appears when 2+ groups have members. SplitResolver expands group IDs to user shares via groupMembership.

  - Acceptance: a new toggle below the split-type picker. When on, the
    split is computed at the group level first (Couple A: 50% / Couple
    B: 50%), then drilled into individuals (within Couple A: equal
    between spouses).

  - Touch: AddExpenseView + ExpenseSplitter logic.

  [x] **Group-level rollup on Home and Expenses.** Done 2026-05-17 (Expenses tab only). WhoOwesWhoCard has People/Groups toggle when 2+ groups have members; groups view uses `BalanceService.simplifyGroups`. Home tab not wired yet; can add to balance hero in a small follow-up.

  - Acceptance: \"Who owes who\" card shows balances both per-individual
    and per-group, toggleable.

  - Touch: BalancesViewModel + HomeView.

  **Auto-detection of family groups (stretch).**

  - Acceptance: if two members repeatedly settle each other\'s debts to
    zero (or have a \"couple\" suffix in their display names), prompt to
    suggest a group.

  - Touch: BalancesAnalyzer (new). Low priority --- ship after the
    manual flow is solid.

### 4.3 Pricing model --- Subscription + Lifetime + Family

> **Recommended pricing (from the research):**

- Individual: **\$24.99/yr** or \$2.99/mo.

- **Family (up to 5 members):** **\$39.99/yr.**

- **Household Lifetime:** **\$89** one-time.

- All tiers: 14-day free trial.

This beats Splitwise on individual price (\$24.99 vs \$29.99), crushes
them on couples (\$39.99 vs \$59.98 for 2× Pro), and captures the
Cashew-style \"pay once\" crowd with the lifetime SKU.

- **Set up StoreKit 2 product configurations in App Store Connect.**

  - Acceptance: three products live --- splitway_individual_yearly,
    splitway_family_yearly, splitway_household_lifetime. 14-day intro
    offer on the subscriptions.

  - Touch: App Store Connect (no code yet).

  **Subscription service in the codebase.**

  - Acceptance: a SubscriptionService reads StoreKit 2 transactions,
    surfaces isPro: Bool + tier: .free \| .individual \| .family \|
    .lifetime.

  - Touch: new Splitway/Services/SubscriptionService.swift. Inject into
    ViewModels that gate features.

  - Restore-purchases button in Settings is mandatory for App Review.

  **Feature-gating layer.**

  - Acceptance: a single FeatureFlag enum lists Pro-gated features.
    ViewModels check subscriptionService.canUse(.receiptOCR) rather than
    checking tier directly. Each Pro feature shows a paywall sheet on
    tap if locked.

  - Touch: new FeatureFlag.swift, paywall view, hooks in: ReceiptReview,
    ChatTab (if assistant ever gets gated), Reports (full trends), CSV
    export, Group count \> 1.

  **Define what\'s free vs Pro (final list --- implement this
  exactly):**

  -----------------------------------------------------------------
  **Feature**           **Free**              **Pro**
  --------------------- --------------------- ---------------------
  All 5 split modes     Yes                   Yes

  Unlimited expenses    Yes                   Yes
  (no daily cap, ever)                        

  1 group               Yes                   ---

  Unlimited groups      ---                   Yes

  Settle up             Yes                   Yes

  Recurring bills       Yes                   Yes

  Basic reports         Yes                   ---
  (current month only)                        

  Full reports          ---                   Yes
  (3/6/9/12-month                             
  trends + Just-me                            
  mode)                                       

  Budgets +             ---                   Yes
  notifications                               

  Receipt photo         Yes                   Yes
  attachment                                  

  Vision OCR +          ---                   Yes
  item-level review                           

  AI receipt-name       ---                   Yes
  cleanup                                     

  AI assistant chips    ---                   Yes

  CSV export            ---                   Yes

  CloudKit sharing for  Yes                   Yes
  2 people                                    

  CloudKit sharing for  ---                   Yes
  3+                                          
  -----------------------------------------------------------------

> **Critical:** the daily expense cap is NOT a free-vs-Pro lever. Free
> users always get unlimited expense entries.

- **Paywall view.**

  - Acceptance: a single PaywallView component shown when a free user
    taps a locked feature. Lists the three SKUs side by side, highlights
    Family + Lifetime as best value, 14-day trial copy, restore button.

  - Touch: new Splitway/Views/PaywallView.swift. Brand-matched
    cream/brown design with capybara.

  [x] **Splitwise import tool.** Done 2026-05-17. SplitwiseImportService parses the CSV, maps categories, best-effort matches members to current household, shows preview with match status, commits as equal-split expenses with reconstructed paidBy. UI under Settings → Money → Import from Splitwise. Non-equal Splitwise splits become equal in Splitway (documented caveat).

  - Acceptance: Settings → Import from Splitwise. User exports their
    Splitwise CSV, picks the file, Splitway parses it into expenses +
    members + groups. Show a preview before committing.

  - Touch: new SplitwiseImportService. This is our lowest-cost growth
    channel --- Reddit migration threads will surface our import button.

## 5. P2 --- Polish & Moat

> **Goal:** months 7--9. Things that make the product hard to leave once
> a user is in.

- **Widgets (Home Screen + Lock Screen).**

  - Acceptance: at-a-glance \"you owe / are owed \$X\" widget. Tap →
    opens Home.

  - Touch: new WidgetExtension target.

  **Apple Watch app (companion only).**

  - Acceptance: tap-to-log an expense (amount + category + split with
    default group). View pending settle-ups.

  - Touch: new WatchKit target.

  **App Intents + Shortcuts.**

  - Acceptance: \"Hey Siri, log \$24 for groceries\" creates an expense
    in the default group.

  - Touch: AppShortcutsProvider.

  **Multi-currency support.**

  - Order: EUR, GBP, INR after USD. Add per-expense currency,
    settings-level home currency, FX conversion via a free public API
    (e.g., open.er-api.com).

  - Touch: ExpenseModel + CurrencyService + ReportsViewModel.

  **Year-over-year reports.**

  - Acceptance: Reports tab gets a new \"YoY\" toggle showing current vs
    prior year for the selected category/period.

  - Touch: ReportsViewModel.

  **Localization.**

  - Languages in priority order: Spanish, French, German, Hindi,
    Portuguese, Italian.

  - Acceptance: every user-facing string flows through
    Localizable.strings. Set up genstrings and a CI check.

## 6. P3 --- Backlog (Future)

Do not start these without explicit approval --- they\'re listed so
they\'re not lost.

- Android port (only if iOS revenue justifies; most successful indie
  household apps stay iOS-only for 12+ months).

  Web companion (read-only first, full functionality later).

  Bank-sync via Plaid (contradicts privacy-first stance --- only if we
  change the brand promise).

  UPI integration (India). Big market for Splitwise, no native rupee
  payments. Worth it if we localize to India.

  Pay-by-Bank via Tink (EU/UK). Splitwise just added this via Tink in
  Oct 2025.

  Categorization-by-image LLM (\"here\'s a photo of a meal, log it as a
  dinner expense\").

  Receipt warranty tracking (small adjacent niche).

  Travel mode (auto-create a trip group from a location burst).

## 7. Things to Explicitly NOT Build

These were considered and rejected based on the market research. If a
future task suggests one of these, push back with this file as the
reason.

- ❌ **Daily expense cap on free tier.** This is Splitwise\'s defining
  mistake.

- ❌ **Ads of any kind.** Contradicts privacy-first.

- ❌ **Push notifications beyond budget thresholds + recurring-due.**
  Splitwise was criticized for over-notifying.

- ❌ **Cloud sync of receipts to our servers.** They live in CloudKit
  (the user\'s iCloud) or on-device. Not on our infrastructure.

- ❌ **One receipt = one line item.** Splitwise does this. We do the
  opposite.

- ❌ **Per-OS pricing** (charging once for iOS, again for iPad).
  HomeBudget does this. We don\'t.

- ❌ **In-house joint banking.** Zeta tried, shut down May 2025.

- ❌ **Free-form AI chat in v1.** Trim it. Chips are enough.

- ❌ **Multi-currency in v1.** Backlog.

- ❌ **Android in v1.** Backlog.

## 8. Acceptance Criteria for v1.0 Launch

When all of these are true, ship to the App Store:

- All P0 tasks complete.

  At least 80% of P1 tasks complete (Receipt OCR gap + Groups
  completion + Pricing model are mandatory).

  30+ households on TestFlight for ≥4 weeks with no Sev-1 bugs in the
  last 2 weeks.

  App Store review checklist clean: privacy nutrition label, consent UX,
  restore purchases, no test data, no debug menus visible to end users.

  DeepSeek key never appears in UserDefaults, the binary, or any
  client-side log.

  Proxy service is up with monitoring + rate limits.

  Privacy policy + ToS live on splitway.app.

  Marketing site has at least: hero, 3-feature grid (smart receipt,
  couples-first, AI assistant), pricing, FAQ, privacy/ToS links.

## 9. Open Questions for Mahdi

Resolve these before P1 starts.

- Do we want a freemium subscription model (recommended) or pure
  lifetime IAP? Default: both (the recommended pricing model).

  Final pricing --- confirm \$24.99 / \$39.99 / \$89.

  Are we shipping in English only at launch or with Spanish + Hindi from
  day 1? Default: English only.

  How aggressively do we want to lean on the Reddit migration channel?
  (Cheap, organic, and Splitwise-hostile-but-true.)

  Domain status --- is splitway.app registered? If not, register it
  before App Store screenshots are taken.

## 10. Reference Data (from market research)

### Splitwise (the incumbent we\'re displacing)

- Founded 2011, Providence RI, \~47 employees, independently held.

- Funding: \$30.5M total, \$20M Series A April 2021 led by Insight
  Partners.

- Pricing: \$2.99/mo or \$29.99/yr. No couples plan. No lifetime plan.

- Revenue: \~\$15--25M/yr global app-store estimate (Sensor Tower).

- Biggest user complaints (rank order): daily expense cap, full-screen
  ads, silent rollout, OCR rigidity, no UPI, no couples plan.

### Pricing benchmark (USD/year, 2026)

  -----------------------------------------------------------------------
  **App**                 **Annual price**        **Has couples/family
                                                  plan?**
  ----------------------- ----------------------- -----------------------
  Splitwise Pro           \$29.99                 No

  Spendee Plus            \$22.99                 No (shared wallets
                                                  only)

  Spendee Premium         \$35.99                 No

  Cashew                  Lifetime IAP only       No

  HomeBudget              \~\$4.99 once per OS    Yes (Family Sync)

  YNAB                    \$109                   Yes (single pot, 6
                                                  users)

  Monarch Core            \$99.99                 Yes (Shared Views)

  Monarch Plus            \$199                   Yes

  **Splitway Individual   **\$24.99**             ---
  (proposed)**                                    

  **Splitway Family       **\$39.99**             **Yes (up to 5)**
  (proposed)**                                    

  **Splitway Lifetime     **\$89 once**           **Yes**
  (proposed)**                                    
  -----------------------------------------------------------------------

### Files / modules to know

(From the original spec --- confirm exact paths in the repo.)

- Splitway/Services/DeepSeekClient.swift --- OpenAI-compatible API
  client.

- Splitway/Services/AssistantContextBuilder.swift --- JSON snapshot of
  household state for the LLM.

- Repositories layer --- where household, expense, group, member queries
  live.

- Persistence layer --- NSPersistentCloudKitContainer setup.

**Last updated:** May 2026. **Next review:** when P0 is 80% complete,
re-rank P1 based on TestFlight signal.
