# Mockup Reference

A summary of every screen designed during the mockup phase. Use this as a reference when building UI in each phase. Each screen includes purpose, key elements, design decisions, and which build phase it belongs to.

---

## Design system foundation

### Colors
```
Background (page):       #f5ede0  (warm cream)
Surface (cards):         #fdf8f0  (warm white)
Surface secondary:       #f0e8d8  (deeper cream, for inset elements)
Primary text:            #2a1d14  (dark brown-black)
Secondary text:          #8a7a6a  (warm gray)
Tertiary text:           #c4b0a0  (light warm gray)
Brand primary:           #b88a5e  (warm brown)
Brand secondary:         #8a6a4a  (darker brown — for housing/utilities)
Warning / over-budget:   #d4824a  (warm coral)
Success / sage:          #5a7d3e  (muted sage green)
Dark CTA:                #2a1d14  (almost black, for primary buttons)
```

### Capybara mascot palette
```
Body brown:              #b88a5e
Head highlight:          #c49574
Belly hint:              #d4a878
Ear outer:               #a07854
Ear inner pink:          #e5b8a8
Eye black:               #2a1d14
Nose:                    #7a5840
Orange (signature):      #f29545
Leaf:                    #7ca85e
```

### Avatar colors (per person, consistent across app)
Assign each household member one color (use the `c-*` ramp system):
- Person 1: #c0d4b8 background / #3b6d11 text (green)
- Person 2: #e5b8a8 background / #993556 text (pink)
- Person 3: #d0c4d8 background / #534ab7 text (purple)
- Person 4: #e4c8c0 background / #993c1d text (coral)

### Typography
- System font (SF Pro) for UI
- Serif italic for warm headings ("The Mahmoud House," "Welcome to," screen titles in onboarding)
- Big numbers: 32-48px, weight 500, letter-spacing -0.5px

### Corners
- Cards: 16-18px radius
- Buttons: 100px (pill)
- Avatars: 50% (circle)
- Small chips: 100px (pill)

### Spacing rhythm
- Screen padding: 22px horizontal
- Card padding: 14-18px
- Card gap: 8-10px vertical, 12px grid gap
- Tab bar padding: 16px

---

## Phase mapping

| Phase | Screens to build |
|---|---|
| 1 | Onboarding (welcome, name, groups Y/N, AI consent), Members & Groups view, Settings shell |
| 2 | Home, Add Expense, Category Picker, Expenses tab, Settle Up |
| 3 | Budgets, Notifications settings |
| 4 | Receipt Scan (camera, review, assignment sheet) |
| 4.5 | Assistant tab (empty + conversation), AI consent re-visit |
| 5 | Reports tab, polish pass on all earlier screens |

---

## 1. Home screen

**Phase:** 2
**Purpose:** Default screen on app open. Glanceable household status.

**Elements (top to bottom):**
- Status bar (system)
- Header: small italic serif household name + bold "Good morning, [Name]" + avatar
- Hero card (brown background, cream text): "This month" total + comparative context + your balance + Settle up button
- 2-column budget pills (top 2 budgets with progress bars)
- "Recent" section title + "See all" link
- 3 expense cards: icon, title, who/when/split, amount + per-person share
- FAB: dark circle with + icon, bottom right
- Tab bar: 5 tabs (Home, Expenses, Reports, Assistant, Settings)

**Key decisions:**
- Greeting uses person's name; household name is smaller above
- Balance shown as "You're owed $X" or "You owe $X" — not raw number
- Over-budget categories show coral color, on-track show brown
- Capybara icon in tab bar shows face only (no orange at small size)
- FAB is THE primary action — always one tap away

---

## 2. Add Expense

**Phase:** 2
**Purpose:** Log a new expense manually. Most-used screen after Home.

**Elements:**
- Top bar: X close, "New expense" title, camera icon (switch to scan)
- Big centered amount entry ($ + number, 48px)
- Category card (icon, label, chevron)
- Description input
- Date card (defaults to "Today")
- Split section:
  - Pill selector: Equal / Percentages / By amount / By shares
  - Member rows showing each participant's share
  - "Customize" link for per-line-item splits (when receipt-based)
- Paid by card
- Save button (dark, full-width, pill)

**Key decisions:**
- Amount is the hero (cash-app pattern)
- Camera icon at top-right for quick switch to receipt scanning
- Split pills show ALL split types, not hidden behind "Custom"
- "Paid by" separate from "Split among" (independent concepts)
- For households with groups, show groups as default split granularity; tap to expand to individuals

---

## 3. Category Picker

**Phase:** 2
**Purpose:** Choose a category when logging an expense.

**Elements:**
- Back arrow + "Choose category" title
- Search bar
- List of categories, each row:
  - Colored icon tile (one color per category)
  - Category name
  - Inline budget context for currently-selected: "$486 of $600 this month"
  - Checkmark on selected category, brown border highlight

**Key decisions:**
- Each category has its own color (palette derived from c-* ramps)
- Budget context inline — subtle nudge while selecting
- Fixed list of 10 categories (no custom in v1)

---

## 4. Receipt Scan — Camera

**Phase:** 4
**Purpose:** Capture a receipt photo for OCR.

**Elements:**
- Dark mode (camera UI)
- Top bar: X close, "Scan receipt", flash toggle
- Camera viewfinder with orange frame guides (corner brackets at 4 corners + thin orange border)
- Instruction: "Position receipt inside the frame" (overlay banner)
- Bottom controls: photo library / capture (white circle) / flip camera

**Key decisions:**
- Brand orange in the frame guides for visual continuity
- Corner brackets feel more inviting than a plain rectangle
- Capture button is large and centered (primary action)

---

## 5. Receipt Scan — Review

**Phase:** 4
**Purpose:** Confirm and assign OCR-extracted line items.

**Elements:**
- Back arrow + "Review items" title + edit icon
- Subtitle: merchant + date + total
- Recognition banner (sage-tinted): "I recognized N items from past receipts. Review M new items below."
- Line item rows:
  - Cleaned-up display name (not raw OCR)
  - Status indicator: sage check + "Shared 50/50" OR coral question + "New item · tap to assign"
  - Left border color matches status (sage = known, coral = new)
  - Price on the right
- "Continue to split" button (disabled until all new items assigned)

**Key decisions:**
- Recognition banner is critical — builds trust in the learning system
- Color-coded left borders for instant scan-ability
- Names normalized for display, raw OCR preserved for later

---

## 6. Receipt Scan — Assignment Sheet

**Phase:** 4
**Purpose:** Assign a new line item to a person or group.

**Elements (bottom sheet, modal over receipt review):**
- Drag handle
- "New item" label + item name + amount + "who's this for?"
- Options:
  - Shared between all (default selected if multiple individuals selected)
  - Just [Person 1]
  - Just [Person 2]
  - ... (one per household member)
- Multi-select supported; if 2+ match a known group, label "Mahmoud family" appears in summary
- **Remember dropdown:**
  - "Always shared like this" (auto-selected when "Shared" picked)
  - "Just this time" (auto-selected when individual picked)
  - "Always [name]'s" (only shown when single individual picked)
- Confirm button

**Key decisions:**
- Three-option remember system instead of single checkbox (avoids false-positive learning)
- Auto-detect group from individual selections (cleaner UX than separate "Just [Family]" options)
- Default remember value depends on user's selection (smart defaults)

---

## 7. Assistant — Empty State

**Phase:** 4.5
**Purpose:** First impression of the chatbot. Set expectations.

**Elements:**
- Large capybara character (hero, full color, orange + leaf)
- Serif italic "Hi, I'm your assistant"
- Subtitle: "Ask me anything about your household's spending"
- "Try asking" section with 4 suggested questions (tappable):
  - "How much did we spend on groceries this month?"
  - "Did I pay Ahmad back yet?"
  - "Are we over budget on anything?"
  - "Compare this month to last month"
- Bottom: pill-shaped input + dark send button
- Privacy line: "Powered by Claude · Your data stays private"

**Key decisions:**
- Capybara is the hero — biggest version of the character anywhere in the app
- Suggested questions teach the user what's possible AND act as shortcuts
- No name on the assistant in copy until name is locked in
- Privacy reminder visible every time

---

## 8. Assistant — Conversation

**Phase:** 4.5
**Purpose:** Active chat with the assistant.

**Elements:**
- Top bar: small capybara avatar + "Assistant" name + "Ready" status (sage dot) + dots menu
- Chat messages:
  - User: dark brown bubble, right-aligned, top-right corner sharp
  - Assistant: cream/white bubble, left-aligned, top-left corner sharp
  - Tiny capybara avatar next to each assistant message
- Response content can include:
  - Prose with key numbers bolded
  - Structured data (rows of name + value)
- Input bar at bottom (same as empty state)

**Key decisions:**
- Capybara appears at 3 sizes: hero (empty), header (small), per-message (tiny)
- Personality through visuals, NOT through forced cuteness in copy
- Numbers in responses use bold weight, not color
- Structured data when it's clearer than prose (e.g., who-paid-what breakdowns)

---

## 9. Expenses Tab

**Phase:** 2
**Purpose:** Full expense history + balances.

**Elements:**
- Top: "Expenses" title + filter icon
- "Who owes who" card:
  - Avatar pairs with arrows showing direction
  - Sage = money toward you, coral = money away from you
  - "Settle up" link
- Filter pills (horizontal scroll): Month, Category, Person
- Date-grouped expense list:
  - Section labels: "Today", "Yesterday", "Nov 8", etc.
  - Each row: category icon, title, who/items/split, amount + your impact (sage +X / coral -X / gray "excluded")
- FAB + tab bar

**Key decisions:**
- "Who owes who" card answers the most-asked question first
- Per-expense impact (your share) visible at a glance
- Date grouping makes scrolling natural
- "Excluded" status (gray) for personal items that don't affect your balance

---

## 10. Settle Up

**Phase:** 2
**Purpose:** Resolve outstanding balances with minimum transactions.

**Elements:**
- Top: back arrow + "Settle up"
- "The simplest way" card with subtitle: "Just N payments to settle everyone up"
- Per-payment cards:
  - Avatar → arrow → avatar
  - "[Person] pays you" + amount
  - Two buttons side by side: "Mark paid" (dark CTA) + "Open Zelle" (outline)
- "How this works" explainer card at bottom (sage tint): explains why simplified numbers differ from raw debts
- "Show all transactions instead" link (escape hatch)

**Key decisions:**
- Debt simplification is THE feature here — saves multiple transactions
- Explainer card is non-negotiable — without it, users distrust the math
- Mark paid + Open Zelle as parallel actions (Zelle can fail without blocking)

---

## 11. Reports Tab

**Phase:** 5
**Purpose:** Spending trends, categories, top expenses for any month.

**Elements:**
- "Reports" title
- Month picker (chevrons + tap-to-change)
- Hero total card (brown background): household spent + vs last month
- "By category" card:
  - Pie chart (donut with total in center)
  - Legend with top 5 categories + amounts
  - "View all" link
- "6-month trend" card:
  - Bar chart, current month highlighted
  - Below: monthly average + % change
- "Top expenses this month" card: 3 biggest line items with date + split type

**Key decisions:**
- Month picker prominent — looking at past months is a primary use case
- Donut chart + legend (not pie + slices) for cleaner appearance
- Trend bars in cream/brown (not multicolor) — period-over-period is one dimension

---

## 12. Onboarding — Welcome

**Phase:** 1
**Purpose:** First impression. Establish tone.

**Elements:**
- Large capybara hero
- Serif italic "Welcome to"
- Bold serif title "Splitway"
- Subtitle: "Track and split expenses with the people you live with — peacefully."
- "Get started" button
- Privacy policy reference below

**Key decisions:**
- Capybara establishes the visual identity from screen 1
- Serif typography signals warmth, not coldness
- One CTA, no options to confuse

---

## 13. Onboarding — Name Household

**Phase:** 1
**Purpose:** Personalize the household.

**Elements:**
- Progress bar (1 of 3)
- "Step 1 of 3" label
- Serif title: "Name your household"
- Subtitle: "This is what you'll see when you open the app. You can change it later."
- Pre-filled input card (with brown border)
- "Or pick a quick name" pill chips: "Our House", "Home", "The Smiths", "Family"
- Continue button

**Key decisions:**
- Quick-pick chips reduce decision friction
- "You can change it later" copy reduces commitment anxiety
- Progress bar shows journey is short

---

## 14. Onboarding — Groups Setup

**Phase:** 1
**Purpose:** Decide if household uses groups.

**Elements:**
- Progress bar (2 of 3)
- "Step 2 of 3" label
- Serif title: "Set up groups"
- Subtitle: "Do people in your household form groups, like couples or families?"
- Two big option cards:
  - **Yes, set up groups** (selected by default, brown border) — explainer: "Bills can be split between groups (50/50, percentage, etc.)"
  - **No, just individuals** — explainer: "Everyone splits expenses on their own (great for roommates)"
- Info banner: "You can change this anytime in Settings"
- Continue button

**Key decisions:**
- Two-option binary, not a complex form
- Explainer copy tells user what each choice means
- Reassurance that it's changeable later

---

## 15. Onboarding — AI Consent

**Phase:** 4.5 (UI), but framework set up in Phase 1
**Purpose:** Explicit opt-in for AI features.

**Elements:**
- Progress bar (3 of 3)
- Sparkles icon in cream circle
- Serif title: "Enable the assistant?"
- Subtitle: "Ask questions about your spending in plain English."
- Two cards:
  - "Your data stays private" (sage check icon) — explainer about what's sent to Anthropic
  - "Turn off anytime" (toggle icon) — explainer about Settings option
- "Enable assistant" button (primary)
- "Skip for now" button (secondary, no border)

**Key decisions:**
- No dark patterns — Skip is genuinely available
- Privacy + control are the two cards (the two most important reassurances)
- "For now" implies they can enable later — reduces FOMO

---

## 16. Settings

**Phase:** 1 (shell) → Phase 5 (polish)
**Purpose:** Manage account, household, preferences.

**Sections (each is a grouped card with chevron rows):**
- **Profile card** at top: avatar + name + group + join date + edit icon
- **Household:** household name, members & groups (count), invite member, recurring expenses (count)
- **Money:** budgets (count), settlement history
- **Preferences:** notifications, AI assistant (status: On/Off), receipt storage (12 months), appearance (Light/Dark/Auto)
- **About:** privacy policy, version

**Key decisions:**
- Inline status values ("On", "12 months", "5 active") so user sees state without tapping
- Grouped sections with uppercase labels (iOS-standard)
- No "Sign out" — CloudKit handles auth; "Leave household" is in Members & groups instead

---

## 17. Budgets

**Phase:** 3
**Purpose:** Manage monthly category budgets.

**Elements:**
- Back arrow + "Budgets" + plus icon
- Hero summary card (brown background): November budget total + progress bar + amount left
- Per-category cards:
  - Icon tile + category name + "$spent / $budget"
  - Progress bar in category color
  - "$X left" or "$X over" copy below
  - Coral left border + coral numbers if over budget
- "Add a budget" dashed-border CTA at bottom

**Key decisions:**
- Hero summary first (most-asked question is "how am I doing overall?")
- Color-coded status (sage = on track, brown = approaching, coral = over)
- Dashed-border add CTA fits naturally in the list (not a floating button)

---

## Mockup viewing notes

These mockups were created as HTML/SVG approximations in chat. They are NOT pixel-perfect Figma files. They communicate:
- Layout and hierarchy
- Color decisions
- Component patterns
- Information density
- Interaction affordances

For final UI, Claude Code should:
1. Follow the design system colors and spacing
2. Use proper SwiftUI components (not HTML-equivalents)
3. Use SF Symbols (not Tabler icons — those were placeholders)
4. Implement proper iOS interaction patterns (haptics, transitions)
5. Test in light AND dark mode (mockups are light-only; dark mode adaptations needed)

---

*End of mockup reference.*
