# Splitway — App Summary

**App name:** Splitway
**App Store positioning:** "Expenses & Bills — Splitway"
**Status:** Design finalized, ready for development
**Target platform:** iOS native (Swift / SwiftUI)
**Target users:** 4 adults moving into a shared home, with v1 designed for any group up to ~8 people

---

## In one paragraph

A native iOS app for tracking, splitting, and budgeting shared household expenses between adults living together. Built for a real household (two married couples sharing a house) with first-class support for groups, smart receipt scanning that learns over time, and a friendly AI companion (a capybara character) that answers questions about spending in plain English. Local-first via CloudKit. Designed warm and Apple-native, not fintech-bro. Differentiates from Splitwise/Honeydue through smart receipts, the assistant, and group-based splits.

---

## Why it exists

Existing apps fall short:
- **Splitwise** treats every receipt as one line item. Real grocery receipts are *mostly shared, some personal* (snacks, face wash). Manual line-item splitting is tedious.
- **Honeydue / others** target couples, not multi-family households.
- **No competitor has a meaningful AI layer.** Asking "did I pay Ahmad back?" should be a one-line question, not a manual scroll through transactions.
- Many competitors feel dated (Splitwise) or cold (most fintech). Warmth matters for an app you use with family.

The original need: a 4-adult, 2-family household moving in together needs to split rent, utilities, groceries, and other expenses fairly without anyone feeling like they're keeping score.

---

## Core differentiators

1. **Smart receipt + shared-items learning.** Scan a receipt → app extracts line items via Apple Vision → recognized items auto-assigned based on past decisions, new items prompt for assignment. Over time, ~80% of grocery items auto-categorize. Three-option "remember" system (Always shared / Just this time / Always [person]'s) handles the nuance that personal items rotate but household items don't.

2. **The capybara assistant.** A friendly capybara character with a Claude-backed chatbot lives in the app. Natural-language queries: "How much on groceries this month?", "Did I pay Ahmad back?", "Are we over budget on anything?", "Compare this month to last month." Real answers based on real household data.

3. **Groups (couples/families).** First-class entity. Bills split family-vs-family by default with one tap. Tap a group to expand into individuals. Auto-detects "Mahmoud family" when both Hamza and Sarah are tagged on a line item.

4. **Privacy-first architecture.** All data stays on user devices via Apple's CloudKit. No backend, no analytics, no ads. Chatbot is the only cloud-dependent feature, with explicit opt-in and clear data-flow disclosure.

5. **Designed warmth.** Soft cream backgrounds, brown accents, friendly serif accents, calm motion. Not Robinhood. Not Splitwise. Closer to Apple Wallet meets Spenzy.

---

## Target user

**Primary:** Adults sharing a residence with at least one other adult — couples, families sharing with another family, multi-generational households, mature roommates. Specifically NOT solo users (it's a household app, requires 2+).

**Initial validation set:** The owner's own household — 4 adults, 2 couples — for the first 1-3 months. Real use surfaces real friction.

**Excluded from v1:** Children with their own expenses, business expense tracking, solo personal finance, banking integration.

---

## Architecture summary

| Layer | Choice | Why |
|---|---|---|
| Language | Swift 5.9+ | Native iOS performance + App Store ecosystem |
| UI | SwiftUI | Modern, declarative, Apple-native |
| Min OS | iOS 17+ | Swift Charts, modern SwiftUI primitives, CloudKit improvements |
| Persistence | Core Data + CloudKit (NSPersistentCloudKitContainer) | Free sync, offline-first, Apple-managed |
| Sharing | CKShare | Native multi-user, no backend needed |
| OCR | Apple Vision | Free, on-device, private |
| Charts | Swift Charts | Built-in, polished, no 3rd party |
| Notifications | UserNotifications (local) | No server needed |
| AI | Claude API (Haiku + Sonnet) | Smart, brand-aligned, opt-in only |
| Backend | None (initially) | Privacy-first, no infrastructure to maintain |

**API key handling:** Bundled in TestFlight during household beta. Replaced with thin proxy service (Cloudflare Workers / Vercel) before App Store launch.

---

## Data model (high-level)

**Core entities:**
- `User` — Apple ID identity + display name + emoji + optional `groupID`
- `Household` — name, invite code, groups-enabled flag
- `Group` — name, color, member list (optional concept; off for roommate setups)
- `Expense` — amount, category, split rule, paid-by, optional line items, optional receipt
- `LineItem` — item name (normalized), amount, per-item split rule
- `SplitRule` — type (equal/percent/amount/shares/excluded) + participants (Users or Groups)
- `SharedItemRule` — learned rule for an item ("always shared" / "always [person]'s")
- `Budget` — per-category monthly limit + alert thresholds
- `RecurringExpenseTemplate` — auto-logs fixed bills, prompts for variable bills
- `Settlement` — record of a payment between members
- `ReceiptImage` — compressed JPEG with retention policy
- `ChatMessage` — AI assistant conversation history (local only)

**Time/currency:** UTC storage, locale-aware display. USD only in v1, locale-aware formatters throughout (multi-currency = v2 config change, not rewrite).

---

## Feature list — v1 (household beta)

### Foundation
- Apple ID identity, no passwords
- Create household, invite via share link OR 6-digit code
- Optional Groups (couples/families) with onboarding decision step
- Members can be archived (not deleted)
- All members have equal rights

### Expense logging
- Manual entry: amount, category (fixed list of 10), description, date, split, paid-by
- 5 split types: Equal, Percentages, By amount, By shares, Excluded
- Split by Group OR individuals (drillable)
- Recurring expenses: fixed-amount auto-logs, variable prompts for amount
- Edit own expenses with full audit trail; soft-delete with 30-day recovery
- Refunds = edit original

### Receipt scanning
- Custom camera with brand-orange frame guides
- Apple Vision OCR with custom parser
- Store-aware parsing (H-E-B, Costco, Walmart, Target prioritized for Texas)
- Recognition banner: "I recognized N items, review M new items"
- Status-coded line items (green = known, orange = new)
- Cleaned-up display names ("WHL MLK GAL" → "Whole milk gallon")
- Bottom-sheet assignment with three-option "remember" system
- Receipt photo compressed + stored with retention policy (6mo / 12mo / forever / never)

### Balances & settlement
- Real-time balance calculation across CloudKit sync
- "Who owes who" card on Expenses tab
- Debt simplification (Splitwise-style) with transparent explanation
- Mark paid + optional Zelle deep link
- Partial settlements supported
- Settlement history view

### Budgets
- Per-category monthly limits (household-level)
- Alerts at 80% and 100%
- Hero summary card + per-category cards with progress bars
- Over-budget highlighted in coral

### Reports
- Monthly view with chevron navigation
- Hero total with vs-last-month comparison
- Category pie chart with legend
- 6-month trend bars
- Top expenses for the month

### AI Assistant (capybara)
- Persistent Assistant tab
- Capybara mascot (warm rounded direction, signature orange on head)
- Empty state with suggested questions
- Claude API queries (Haiku for simple, Sonnet for complex)
- Real natural-language answers about household data
- Conversation history (last 50 messages, local-only)
- Opt-in during onboarding, disable anytime in settings
- Honest declines for out-of-scope queries

### Notifications (all local, no server)
- Budget 80% and 100% alerts
- New expense by others (toggleable — most likely to be noisy)
- Balance reminders (none/weekly/monthly)
- Recurring expense due
- Monthly summary

### Settings
- Profile (display name, emoji)
- Household management (name, members, groups, invite, recurring)
- Money (budgets, settlement history)
- Preferences (notifications, AI assistant, receipt storage, appearance)
- About (privacy policy, version)

---

## Out of scope for v1 (in v2 backlog)

- CoreML model replacing fuzzy match for shared-items learning
- Multi-currency
- CSV/PDF export
- Per-person analytics
- Custom categories
- Multi-household per user
- Home screen widget
- Apple Watch app
- Apple Pay settlement integration
- Year-over-year reports
- Roles & permissions (admin/member distinction)
- Tags (additional to categories)
- Cross-conversation chat search
- Chatbot voice input
- Chatbot proactive insights
- Arabic localization (originally considered, deprioritized for v1/v2)
- Bank import / Plaid integration (intentionally never — local-first)
- Ads (intentionally never)

---

## Design system

### Colors
```
Background (page):       #f5ede0  warm cream
Surface (cards):         #fdf8f0  warm white
Surface secondary:       #f0e8d8  deeper cream
Primary text:            #2a1d14  dark brown-black
Secondary text:          #8a7a6a  warm gray
Tertiary text:           #c4b0a0  light warm gray
Brand primary:           #b88a5e  warm brown
Brand secondary:         #8a6a4a  darker brown
Warning (over-budget):   #d4824a  warm coral
Success (sage):          #5a7d3e  muted sage green
Dark CTA:                #2a1d14  almost black
```

### Capybara palette
```
Body:                    #b88a5e
Head highlight:          #c49574
Belly:                   #d4a878
Ear outer:               #a07854
Ear inner pink:          #e5b8a8
Eye:                     #2a1d14
Nose:                    #7a5840
Orange (signature):      #f29545
Leaf:                    #7ca85e
```

### Per-person avatar colors
- Person 1: bg #c0d4b8, text #3b6d11 (sage)
- Person 2: bg #e5b8a8, text #993556 (pink)
- Person 3: bg #d0c4d8, text #534ab7 (purple)
- Person 4: bg #e4c8c0, text #993c1d (coral)

### Typography
- System font (SF Pro) for UI
- Serif italic (Georgia or similar serif) for warm headings
- Big numbers: 32-48px, weight 500, letter-spacing -0.5px

### Geometry
- Card corners: 16-18px continuous
- Button corners: 100px (pill)
- Avatar: 50% (circle)
- Icon tiles: 10-12px corners

### Spacing
- Screen horizontal padding: 22px
- Card padding: 14-18px
- Vertical gap between cards: 8-10px
- Tab bar padding: 16px from edges

### Motion
- Numbers count up on first appearance
- Pie slices animate in
- Chart lines draw themselves
- Haptic feedback on: log expense, settle, budget hit
- No gratuitous transitions

### What we're avoiding (the "AI slop" check)
- Generic iOS blue everywhere
- Stock illustrations
- Lorem ipsum data
- Identical card spacing everywhere
- No personality in empty states
- Generic SF Symbols where custom icons would shine
- Capybara as decoration (it has a JOB — chat avatar — not vibes)

---

## The capybara mascot

**Style:** Warm rounded (Direction B from concept sketches). Minimal geometric body, soft dimensional shading, friendly proportions. NOT cartoon, NOT chibi, NOT photorealistic.

**Signature detail:** Small orange on top of head with a green leaf. Instantly recognizable. Could become the app icon's central element.

**States:**
- Idle: subtle breathing animation
- Thinking: subtle pulse during query
- Responding: text streams in beside it

**Implementation:** Static SVG/PNG with SwiftUI animation. NEVER video files. NEVER AI-generated animation clips. The character should be designed properly (commissioned ~$200-500 on Fiverr/Dribbble, or refined via Midjourney/DALL-E with consistent style prompts).

**Placement rules:**
- Primary (large): Assistant tab empty state, onboarding welcome
- Secondary (small): chat header avatar, per-message tiny avatar
- Tab bar icon: face only, no orange at small size
- NEVER on: home, add expense, settings, reports, expenses screens

**Personality:** Calm, helpful, observant. Through visuals only. The chatbot copy is brief and factual — no "*sniffs the calculator*" forced cuteness.

**Name:** TBD. Candidates discussed: Cap, Bara, Cappy, Pip. Or no name — "the assistant" can become endearing through use.

---

## Onboarding flow (8 steps)

1. **Welcome** — capybara hero, "Get started"
2. **Apple ID sign-in** — silent via CloudKit, no UI
3. **Display name + emoji** — quick personalization
4. **Create or join household** — two big buttons
5a. **(Create path)** Name household → groups Y/N → optional group creation → invite link + code
5b. **(Join path)** Enter code OR tap shared link → confirm
6. **Notification permission** — iOS-native dialog
7. **AI assistant consent** — privacy explained, opt-in default, skip available
8. **Quick tour** — 3 swipeable hints (log, scan, ask)

Total: ~90 seconds for creator, ~30 seconds for joiners.

---

## Build plan

| Phase | Scope | Days |
|---|---|---|
| 1. Foundation | Project setup, CloudKit, household + groups create/join | 6-9 |
| 2. Core expenses | Add expense, all 5 split types, balances, settlement | 8-11 |
| 3. Budgets + notifications | Budget CRUD, alerts, recurring expenses | 5-7 |
| 4. Receipts | Camera, OCR, parsing, assignment sheet, learning rules | 10-14 |
| 4.5. AI Assistant | Capybara assets, chat UI, Claude integration, query layer | 8-12 |
| 5. Reports + polish | Charts, history, mockup-driven polish | 5-7 |
| 6. App Store prep | Icon, screenshots, API proxy, submit | 5-7 (post-move-in) |

**Total to household-beta-ready (Phases 1-4.5):** ~37-53 days

**Parallel work:** capybara design, Apple Developer enrollment, additional Pinterest inspiration

---

## Build philosophy

This is a **household beta first** build, not an App Store v1 build. Bar is "household can actually use it on move-in day," not "publicly polished." Bugs and rough edges allowed in v1. The household IS the beta test. App Store submission comes weeks or months after move-in, when real use has surfaced and fixed real issues.

---

## Risks & mitigations

| Risk | Mitigation |
|---|---|
| Receipt OCR quality variable | Manual entry always available as fallback |
| CloudKit sharing has bugs | Validate end-to-end in Phase 1 before building on top |
| Bad chatbot worse than no chatbot | Heavy prompt engineering, narrow scope, honest declines |
| Timeline tight | Happy-path-first; edge cases deferred to post-move-in beta period |
| API key security | Bundled OK for household; proxy service before App Store |
| Group complexity | Onboarding Y/N gates it; default to "no groups" path is fully supported |

---

## Tone, voice, and personality

**App copy is brief, warm, and direct.** Never bubbly. Never corporate.

Good examples:
- "Track and split expenses with the people you live with — peacefully."
- "Position receipt inside the frame"
- "I recognized 5 items from past receipts. Review 2 new items below."
- "Just 2 payments to settle everyone up."
- "Ahmad owes you $84, but you owe Sarah $12. So Ahmad pays you $71.80."
- "Your data stays private. Only the question and related expenses are sent to Anthropic."
- "Turn off anytime."

Bad examples (avoid):
- "Welcome to the future of household finance!"
- "🎉 Yay! You just logged your first expense!"
- "Oops, something went wrong 😅"
- "Pro tip: track every penny!"
- Mascot dialogue ("*Cap waddles over and says hello!*")

---

## Document index

When sharing for design/development, the full package includes:

- `MASTER_SPEC.md` — exhaustive product specification (technical + functional)
- `PHASE_1_FOUNDATION.md` — detailed Phase 1 plan (CloudKit + groups + onboarding shell)
- `MOCKUP_REFERENCE.md` — every screen's purpose, elements, decisions, build phase
- `APP_SUMMARY.md` — this document
- `mockups/index.html` — gallery linking to all 17 visual mockups
- `mockups/*.html` — individual standalone HTML mockup files
- `PINTEREST_INSPIRATION_BRIEF.md` — optional design reference gathering guide

---

## What to do with this package

**For Claude Design (or any designer):**
- Open `mockups/index.html` for the visual overview
- Reference `APP_SUMMARY.md` (this doc) for vision
- Reference `MOCKUP_REFERENCE.md` for design system + per-screen decisions
- Use mockups as direction, not pixel-perfect spec — refine in Figma/Claude Design

**For Claude Code (or any developer):**
- Read `MASTER_SPEC.md` first
- Then `MOCKUP_REFERENCE.md`
- Start with `PHASE_1_FOUNDATION.md`
- Use mockups as visual targets during UI implementation

---

*End of app summary.*
