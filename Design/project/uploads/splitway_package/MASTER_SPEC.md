# Splitway — Master Spec

**App name:** Splitway
**App Store positioning:** "Expenses & Bills — Splitway"

**Version:** 1.2 (post-mockup, with groups + refinements)
**Last updated:** May 2026
**Target ship:** Usable by household at move-in (~50 days). Household beta 50-120+ days. App Store submission when polished.

---

## 0. Build philosophy

This is a **"household beta first"** build, not an "App Store v1" build.

- Day 50 (move-in): All features exist and work for the happy path. Rough edges allowed.
- Day 50-120+: Household uses it daily. Polish based on real friction.
- Day 120+: App Store submission when it actually feels ready. No artificial deadline.

The household is the beta test.

---

## 1. Product summary

A native iOS app for tracking, splitting, and budgeting shared household expenses between multiple adults living together. Initial design target: 4 adults, 2 sub-households (you + wife, sister-in-law + her husband), built to support any group size and configuration.

**Differentiating bets:**
1. **Smart receipt + shared-items learning.** A real grocery receipt is *mostly shared, some personal*. The app learns which items are shared vs. whose, so scanning becomes near-zero friction over time.
2. **AI companion ("the assistant").** A capybara character with a Claude-backed chatbot. Ask natural-language questions about household spending — "did I pay Ahmad back?", "how much on groceries this month?" — get accurate answers from your real data.
3. **Groups.** First-class support for families/couples within a household, so bills split family-vs-family with one tap while keeping individual splitting available.
4. **Privacy-first.** Local CloudKit storage. AI queries opt-in with explicit consent. No tracking, no ads.

---

## 2. Users, groups, and roles

### Initial household
- 4 adults, 2 sub-households (married couples), all on iPhone with iCloud

### User identity
- Apple ID via CloudKit (no passwords, no email signup)
- Display name + optional emoji avatar

### Household model
- One household per user in v1
- CloudKit shared zones, joined via share link or 6-digit invite code
- Members can be archived (not deleted — preserves history)

### Groups (new in v1.2)
- A **Group** is a named subset of household members (e.g., "Mahmoud family", "Hassan family")
- Groups are **optional** — works fine without them for roommate households
- Groups have a name and optional color tag
- A user can belong to 0 or 1 group within a household
- New members start as individuals; can be invited to a group by any existing member

### Permissions
- No admin/member distinction in v1. Equal rights for all members.
- Trust model assumes household-level trust.

---

## 3. Architecture

### Stack
- **Language:** Swift 5.9+
- **UI:** SwiftUI (iOS 17+ minimum target)
- **Persistence:** Core Data via NSPersistentCloudKitContainer
- **OCR:** Apple Vision framework (on-device)
- **Charts:** Swift Charts (iOS 16+)
- **Notifications:** UserNotifications (local only)
- **AI/Chatbot:** Claude API (Anthropic) — Haiku for simple queries, Sonnet for complex
- **Image handling:** UIKit's UIImage + ImageIO for compression

### Sync model
- **Private DB (CloudKit):** user preferences, settings, chatbot conversation history
- **Shared DB (CloudKit):** household data (expenses, members, splits, budgets, receipts, groups)
- Sharing via CKShare

### Chatbot architecture
- Query → app collects relevant data slice → sent to Claude API with system prompt
- Response streams back, displayed next to mascot
- Conversation stored locally
- API key handling:
  - **Household beta:** bundled in TestFlight build
  - **Public App Store:** thin proxy service (Cloudflare Workers / Vercel Functions)

### Time zones, currency, localization
- UTC storage, local display
- USD only in v1, locale-aware NumberFormatter throughout
- English only

---

## 4. Data model

### `User`
- `id: UUID`
- `appleUserID: String`
- `displayName: String`
- `avatarEmoji: String?`
- `householdID: UUID`
- `groupID: UUID?` (optional)
- `isArchived: Bool`
- `archivedAt: Date?`
- `joinedAt: Date`
- `notificationPreferences: NotificationPrefs`
- `chatbotEnabled: Bool`

### `Household`
- `id: UUID`
- `name: String`
- `inviteCode: String`
- `inviteCodeExpiresAt: Date?`
- `createdAt: Date`
- `createdByUserID: UUID`
- `currency: String`
- `receiptRetentionMonths: Int` (default 12; options: 6, 12, -1=forever, 0=never)
- `groupsEnabled: Bool` (set during onboarding; user-changeable)

### `Group` (new in v1.2)
- `id: UUID`
- `householdID: UUID`
- `name: String`
- `colorTag: String?` (hex color, optional)
- `emoji: String?` (optional)
- `memberUserIDs: [UUID]`
- `createdAt: Date`
- `createdByUserID: UUID`

### `Expense`
- `id: UUID`
- `householdID: UUID`
- `loggedByUserID: UUID`
- `amount: Decimal`
- `currency: String`
- `category: Category`
- `description: String`
- `merchant: String?`
- `date: Date`
- `createdAt: Date`
- `updatedAt: Date`
- `editHistory: [EditRecord]`
- `splitRule: SplitRule`
- `lineItems: [LineItem]?`
- `receiptImageID: UUID?`
- `isRecurringInstance: Bool`
- `recurringTemplateID: UUID?`
- `isSettled: Bool`
- `notes: String?`

### `LineItem`
- `id: UUID`
- `expenseID: UUID`
- `itemName: String` (raw OCR)
- `displayName: String` (cleaned up — "WHL MLK GAL" → "Whole milk gallon")
- `normalizedItemName: String` (for matching)
- `amount: Decimal`
- `quantity: Int`
- `splitRule: SplitRule`
- `category: Category?`
- `assignedToUserIDs: [UUID]?` (multiple — auto-detects group if 2+ form a known group)

### `SplitRule` (embedded value type)
- `type: SplitType` enum:
  - `.equal` — split evenly among participants
  - `.percentages` — each participant has a %
  - `.amounts` — each participant has an exact amount
  - `.shares` — each participant has integer shares
  - `.excluded` — specific users excluded (personal expense)
- `participantIDs: [UUID]` (can reference Users OR Groups)
- `participantValues: [UUID: Decimal]` (% / amount / shares, depending on type)
- `paidBy: [UUID: Decimal]` (who paid up-front, how much)

### `SharedItemRule` (the learning list)
- `id: UUID`
- `householdID: UUID`
- `normalizedItemName: String`
- `category: Category?`
- `ruleType: RuleType` enum:
  - `.alwaysShared` — split per default rule (typically equal between groups)
  - `.alwaysPerson(UUID)` — always assigned to a specific person
- `confidence: Int` (count of confirmations)
- `lastUsedAt: Date`
- `createdAt: Date`

### `Budget`
- `id: UUID`
- `householdID: UUID`
- `category: Category`
- `monthlyLimit: Decimal`
- `currency: String`
- `alertThresholds: [Double]` (default `[0.80, 1.00]`)
- `createdAt: Date`
- `updatedAt: Date`

### `RecurringExpenseTemplate`
- `id: UUID`
- `householdID: UUID`
- `description: String`
- `category: Category`
- `amount: Decimal?` (nil if variable)
- `isVariableAmount: Bool`
- `splitRule: SplitRule`
- `dayOfMonth: Int`
- `nextOccurrence: Date`
- `isActive: Bool`
- `createdBy: UUID`

### `Settlement`
- `id: UUID`
- `householdID: UUID`
- `fromUserID: UUID`
- `toUserID: UUID`
- `amount: Decimal`
- `currency: String`
- `method: String?`
- `note: String?`
- `settledAt: Date`
- `createdBy: UUID`

### `ReceiptImage`
- `id: UUID`
- `expenseID: UUID`
- `householdID: UUID`
- `imageData: Data`
- `originalSize: Int`
- `compressedSize: Int`
- `capturedAt: Date`
- `expiresAt: Date?`
- `ocrText: String?`

### `ChatMessage`
- `id: UUID`
- `userID: UUID`
- `role: ChatRole` (`.user`, `.assistant`)
- `content: String`
- `dataContext: String?`
- `createdAt: Date`
- `tokenCount: Int?`

### `NotificationPrefs` (embedded in User)
- `budgetAlerts: Bool`
- `newExpenseFromOthers: Bool`
- `balanceReminderFrequency: Frequency` (.never, .weekly, .monthly)
- `recurringReminders: Bool`
- `monthlySummary: Bool`

### `EditRecord` (embedded in Expense)
- `editedAt: Date`
- `editedByUserID: UUID`
- `fieldChanged: String`
- `oldValue: String`
- `newValue: String`

---

## 5. Categories (fixed list, v1)

```swift
enum Category: String, CaseIterable, Codable {
    case rent
    case utilities
    case groceries
    case diningOut
    case transportation
    case entertainment
    case householdSupplies
    case personalCare
    case healthcare
    case other
}
```

Each has SF Symbol icon and default color.

---

## 6. Splitting logic

### Split types (v1.2 — surfaced in UI, not hidden behind "custom")

The Add Expense screen exposes:

- **Equal** (default) — split evenly among participants
- **Percentages** — each participant gets %, must sum to 100
- **By amount** — each participant gets exact $, must sum to total
- **By shares** — each gets integer shares, total split proportionally
- **Excluded** — specific users not part of split

### Group vs individual splitting

**Bill-level splits (Add Expense screen):**
- If household has groups enabled, **groups are the default granularity**
- Splittable units shown as groups (e.g., "Mahmoud family", "Hassan family")
- User can tap a group to expand into individuals and split differently within it
- If household doesn't use groups, individuals are the granularity

**Item-level splits (receipt assignment sheet):**
- Always shows **individuals** (cleaner UX)
- App auto-detects when 2+ selected individuals form a known group, labels accordingly
- Example: select Hamza + Sarah → app shows "Mahmoud family" in expense summary

### Per-line-item override

Receipt scans allow per-item splits. Item-level splits override expense-level split.

### "Paid by" is separate from "split among"

Whoever paid up-front gets credit. Splits determine who owes whom. These are independent.

### Default rule for new households
- With groups enabled (2 groups): Equal between groups
- With groups disabled OR uneven group counts: Equal among all members

---

## 7. Shared items learning list

### Receipt scan flow

1. OCR produces line items via Apple Vision
2. Normalize names (lowercase, expand abbreviations, strip prices)
3. Fuzzy match (Levenshtein ≤ 2 or 85% similarity) against `SharedItemRule` table for this household
4. Three outcomes per item:
   - **High-confidence rule match (`.alwaysShared`, confidence ≥ 3):** apply silently, show undo
   - **High-confidence rule match (`.alwaysPerson`, confidence ≥ 3):** apply silently, show undo
   - **Low-confidence or no match:** prompt user via assignment sheet

### Assignment sheet (v1.2 refined)

Bottom sheet shows:
- Item name, amount, "who's this for?"
- **Selection options (individuals only):**
  - Shared between all (default selected if multiple selected)
  - Just [Person 1]
  - Just [Person 2]
  - etc. (one per household member)
- User can multi-select; if 2+ selected match a known group, app labels it "[Group name]"
- **Remember dropdown** (replaces single checkbox):
  - `Always shared like this` — auto-selected when user picks "Shared"
  - `Just this time` — auto-selected when user picks an individual (default for personal items)
  - `Always [name]'s` — only shown when single individual selected
- Confirm button

### Why this matters

The old "Remember this for future receipts" checkbox was a bug. If Sarah buys a Snickers today, you don't want every future Snickers auto-assigned to Sarah — anyone might buy one. The three-option system distinguishes:
- **Shared items** (milk, eggs, rice) → "always shared" makes sense
- **Personal items that rotate** (snacks, face wash) → "just this time" makes sense
- **Specific persistent items** (someone's medication brand) → "always [person]'s" makes sense

### Category-level fallback rules

User can set: "All groceries default to shared between groups."
Item-level rules override category-level rules.

### v2

CoreML model replaces fuzzy match, trained on accumulated decisions.

---

## 8. Budgets

- Per-category monthly limits (household-level, not per-person)
- Alerts at 80% and 100% (fires once per threshold per month)
- Visual progress bars; over-budget categories highlighted with coral
- Resets on the 1st of each month
- Excluded/personal expenses don't count toward shared budgets

### v1 budget screens
- Settings → Budgets → list with progress bars
- Add/edit budget: category picker + monthly amount + notification toggle
- Hero summary card at top showing total spent vs total budgeted

---

## 9. Settlement

- Balance = (amounts paid) − (their share) + (settlements sent) − (settlements received)
- **Debt simplification:** greedy creditor-debtor matching to minimize transactions
- **Settle Up screen** shows simplified payments needed, with explanation:
  - "Ahmad pays you $71.80 (instead of full $84, because you owe Sarah $12)"
- Action buttons per payment: "Mark paid" (primary) + "Open Zelle" (deep link, best-effort)
- Partial settlements supported
- "Show all transactions instead" escape hatch for users who don't trust simplification

---

## 10. Notifications (local only)

| Notification | Default | Toggle | Trigger |
|---|---|---|---|
| Budget 80% reached | On | Yes | Real-time |
| Budget 100% exceeded | On | Yes | Real-time |
| New expense from other member | On | Yes (the noisy one) | CloudKit change |
| Balance reminder | Weekly | Yes (none/weekly/monthly) | Scheduled |
| Recurring expense due | On | Yes | Day of, morning |
| Monthly summary | On | Yes | 1st of month, morning |

All via `UNUserNotificationCenter`. No server needed.

---

## 11. Receipts

### Capture
- Custom camera UI with orange frame guides (matching brand)
- OCR via Apple Vision (`VNRecognizeTextRequest`, `.accurate`)
- Custom parser identifies: merchant, date, line items, totals
- Store-specific tuning for Texas: H-E-B, Costco, Walmart, Target first

### Review screen
- Banner: "I recognized N items from past receipts. Review M new items below."
- Each item row has a **left-border status color**:
  - **Sage green:** recognized, auto-assigned, no action needed
  - **Coral:** new item, needs user assignment
- Names cleaned up for display ("WHL MLK GAL" → "Whole milk gallon")
- Tap any item to override (even auto-assigned ones)

### Storage
- Compressed JPEG, max 1MB, 1200px max dimension
- CloudKit shared DB
- Auto-delete per household setting (6/12/forever/never)

### Confidence handling
- Low parsing confidence → fall back to manual entry, photo still saved
- Editable after OCR via "edit" icon at top of review screen

---

## 12. Recurring expenses

- **Fixed amount:** auto-logs on day-of-month, notification confirms
- **Variable amount:** notification prompts for amount, opens pre-filled form
- Templates managed in Settings → Recurring expenses
- Idempotency: `(templateID, month, year)` uniqueness
- Pausable without deletion

---

## 13. Reports & analytics

### v1 (Reports tab)
- **Month picker** at top (chevrons + tap to jump)
- **Hero total** with vs-last-month comparison
- **Pie chart** of spending by category, with legend
- **6-month trend bars** (current month highlighted)
- **Monthly average + % change** below trend
- **Top expenses** for the month (3 biggest)

Built with Swift Charts (no third-party libs).

### v2 (deferred)
- CSV/PDF export
- Per-person analytics
- Year-over-year
- Custom date ranges
- Per-group breakdown

---

## 14. AI Companion ("the assistant")

### Purpose

Persistent chat tab. Natural-language questions about household spending, backed by Claude API.

### Example queries (must handle well)

- "How much did we spend on groceries this month?"
- "Did I pay Ahmad back yet?"
- "What's our biggest spending category this year?"
- "Are we over budget on anything?"
- "Show me all expenses over $100 last month"
- "Compare this month's spending to last month"
- "Who paid the rent last month?"
- "What did Sarah spend on personal care this year?"
- "How much do I owe right now?"
- "Are we trending up on dining out?"

### Does NOT do
- Add or edit expenses (use form)
- General financial advice (not a financial advisor)
- Discuss anything outside household's expense data

### Mascot character: the capybara

- **Direction:** Warm rounded, minimal geometric (Direction B from design sketches)
- **Color:** Natural warm brown body, soft pink inner ears
- **Signature:** Small orange on top of head with a leaf — instantly recognizable
- **States:** Idle (subtle breathing), Thinking (subtle pulse), Responding (text streams in next to it)
- **Implementation:** Static SVG/PNG with SwiftUI animation. NOT video files. NOT AI-generated animations.
- **Placement:**
  - Primary: Assistant tab (large, hero)
  - Secondary: chat header avatar (small), each response avatar (tiny)
  - Tab bar icon (face only, no orange at small size)
  - Welcome screen of onboarding
  - NOT on: home, add expense, settings, reports, expenses
- **Name:** TBD (pending decision)

### Query flow

1. User types question
2. App parses intent, gathers relevant data slice (date range, categories, etc.)
3. Constructs prompt: system prompt + data slice + question
4. Sends to Claude API (Haiku for simple, Sonnet for complex)
5. Response streams back, displayed next to mascot

### Privacy & consent

- **Onboarding consent screen:** explicit explanation, opt-in by default
- **Disable anytime** in Settings → AI assistant
- **Per-query indicator:** "Sent to Anthropic" while query in flight
- **No PII in queries:** display names allowed; no Apple IDs, no UUIDs, no email

### Persona

Friendly, brief, factual. Not bubbly. Not corporate. Concise — numbers first, then context. Personality comes from the visual character, NOT from forced cuteness in language. Honest declines for out-of-scope queries.

### Limits

- No image input
- No multi-turn agentic actions
- Conversation history: last 50 messages, older auto-pruned

---

## 15. Design direction

### Vibe
- **Warm and friendly with Apple-native restraint**
- Soft cream backgrounds (`#f5ede0`), warm white cards (`#fdf8f0`)
- Brown accents (`#b88a5e`), coral for warnings (`#d4824a`), sage for positive (`#5a7d3e`)
- Big numbers with comparative context ("$854 this month, $147 less than October")
- Serif/italic headlines for warmth, sans-serif for UI

### Visual language
- Continuous rounded corners
- SF Pro for system text, serif italic accents for warmth
- SF Symbols (Tabler-equivalent) for utility icons
- Colored avatar circles (one color per person, consistent across screens)
- Light + dark mode both first-class
- Capybara mascot for emotional moments (Assistant tab, welcome screen)

### Rich animations
- Numbers count up on appearance
- Pie slices animate in
- Chart lines draw themselves
- Haptic feedback on log expense, settle, budget hit
- Smooth transitions, not gratuitous

### Avoiding "AI slop"
- No generic iOS blue everywhere
- Custom illustrated empty states (not stock)
- Real data shapes in mockups
- Specific micro-interactions
- The capybara has a job (chat avatar), not decoration

---

## 16. Screens designed

All mockups completed before code starts:

1. **Home** — household summary, balance, budgets, recent expenses, FAB, tab bar
2. **Add Expense** — amount-first, category picker, smart split section, paid-by
3. **Category Picker** — colored tiles, budget context inline, search
4. **Receipt Scan — Camera** — dark mode, orange frame guides, capture button
5. **Receipt Scan — Review** — banner, line items with status borders, normalized names
6. **Receipt Scan — Assignment Sheet** — bottom sheet, three-option remember system
7. **Assistant — Empty State** — large capybara, suggested questions, input
8. **Assistant — Conversation** — chat bubbles with small capybara avatars
9. **Expenses Tab** — "Who owes who" card, filter pills, expense list with impact
10. **Settle Up** — simplified payments with explanation, Zelle + Mark paid actions
11. **Reports Tab** — month picker, hero total, pie chart, 6-month trend, top expenses
12. **Onboarding — Welcome** — large capybara, serif welcome
13. **Onboarding — Name Household** — input + quick-pick chips
14. **Onboarding — Groups Setup** — yes/no decision with explainer
15. **Onboarding — AI Consent** — privacy & toggle-anytime cards
16. **Settings** — grouped sections, inline status values
17. **Budgets** — hero summary, per-category cards with progress, add-budget CTA

---

## 17. Onboarding flow

1. Welcome screen (capybara hero, "Get started")
2. Apple ID sign-in (silent via CloudKit)
3. Display name + emoji
4. Create or join household
   - Create: name household, set up groups (Y/N), invite members (link + code)
   - Join: enter code OR tap shared link
5. (If creator chose groups) Drag members into groups during invite, or assign later
6. Notification permission (iOS-native)
7. AI assistant consent (privacy explained, opt-in by default)
8. Quick tour (3 swipeable hints: log expenses, scan receipts, ask the assistant)
9. Home screen

Total time for first user: ~90 seconds. For joiners: ~30 seconds.

---

## 18. Edge cases & policies

| Case | Behavior |
|---|---|
| Editing own expense | Allowed; logs to editHistory |
| Editing others' expenses | Not allowed |
| Deleting expenses | Logger only; soft-delete with 30-day recovery |
| Disputed expenses | Informal; logger edits |
| Member leaves household | Archive; balances must settle first |
| Member leaves group | Set `groupID = nil`; historical splits preserved |
| Member joins a group | Invited by existing member; user accepts/declines |
| Refunds | Edit original expense |
| Partial settlements | Supported via multiple Settlement records |
| Tax-only items | Proportional per line item |
| Low OCR confidence | Manual entry fallback, photo saved |
| Conflicting edits | CloudKit last-writer-wins, updatedAt shown |
| Offline logging | Queued in Core Data |
| Chatbot data unavailable | "I don't have data on that" |
| Chatbot API failure | Friendly error, retry button |
| Out-of-scope chatbot query | "I can only help with your household's expenses" |
| User picks individuals matching a group | Auto-label as group name in summary |
| Groups disabled mid-use | Existing group-based splits remain; new ones use individuals |

---

## 19. App Store submission

### Approach
- Build, use privately with household (days 50-120+)
- Polish based on real friction
- Submit when ready (no marketing)

### Pre-submit checklist
- App icon (capybara-themed, designed properly)
- Screenshots (5-8 from real household data)
- App description (~200 words)
- Privacy policy (emphasizes local data + explicit AI consent)
- Apple Developer account ($99/year)
- TestFlight beta with household
- **Proxy service for Claude API key** (replace bundled key)
- AI usage disclosure if Apple requires
- CloudKit schema deployed to production

### Listing
- **App name:** Splitway
- **Subtitle:** "Expenses & Bills" (this is the App Store subtitle field, displayed under the name)
- **Full display:** "Expenses & Bills — Splitway" in marketing contexts
- Primary category: Finance
- Secondary category: Lifestyle
- Keywords: shared expenses, household, roommates, split bills, family budget, receipt scanner, AI assistant, splitwise alternative

---

## 20. Build phases

| Phase | Scope | Days |
|---|---|---|
| 1. Foundation | Project setup, CloudKit, household create/join, groups | 6-9 |
| 2. Core expenses | Add expense, splits (all 5 types), balances, settlement | 8-11 |
| 3. Budgets + notifications | Budget CRUD, alerts, recurring | 5-7 |
| 4. Receipts | Camera, OCR, parsing, assignment sheet, learning rules | 10-14 |
| 4.5. AI Assistant | Mascot illustrations, chat tab, Claude integration, query layer | 8-12 |
| 5. Reports + polish | Charts, history, settings UI, mockup-driven polish | 5-7 |
| 6. App Store prep | Icon, screenshots, proxy service, submit | 5-7 (post-move-in) |

**Total to move-in (Phases 1-4.5):** ~37-53 days at household-beta polish level.

### Parallel work (during phases 1-3)
- Capybara character design (final version, not SVG placeholder)
- Apple Developer account enrollment
- Mockup-driven refinements

---

## 21. Risks

- **Receipt OCR quality:** Apple Vision good not perfect. Manual entry fallback always available.
- **CloudKit sharing complexity:** Gotchas common. Validate end-to-end in Phase 1.
- **Chatbot quality:** A bad chatbot is worse than no chatbot. Heavy prompt engineering, narrow scope, honest declines.
- **Timeline:** 50 days tight at household-beta polish. Happy-path-first, ruthless prioritization.
- **API key security:** Bundled key fine for household, proxy service needed before App Store.
- **Group complexity:** New entity adds branching in UI. Mitigation: thorough onboarding decision (Y/N), default to "no groups" for solo testing.

---

## 22. v2 backlog

- CoreML model replacing fuzzy match
- Multi-currency
- CSV/PDF export
- Per-person analytics
- Custom categories
- Multi-household per user
- Home screen widget
- Apple Watch app
- Apple Pay settlement
- Year-over-year reports
- Roles & permissions
- Tags
- Cross-conversation chat search
- Chatbot voice input
- Chatbot proactive insights
- Per-group reports breakdown
- Group color theming throughout app

---

*End of master spec v1.2.*
