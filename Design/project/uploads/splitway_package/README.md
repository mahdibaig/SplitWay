# Splitway — Design & Spec Package

This package contains everything needed to design and build **Splitway** — a native iOS app for splitting expenses and bills with the people you live with.

**App Store positioning:** "Expenses & Bills — Splitway"

---

## Quick start

**To see the visuals:** Open `mockups/index.html` in your browser.

**To understand the product:** Read `APP_SUMMARY.md`.

**To start building:** Read `MASTER_SPEC.md`, then `PHASE_1_FOUNDATION.md`.

---

## What's in this package

### Documents (read in this order)

| File | What it is | When to read |
|---|---|---|
| `APP_SUMMARY.md` | Top-level vision, features, architecture, design system | First — gives you the whole picture |
| `MASTER_SPEC.md` | Full product spec with data model, edge cases, behaviors | Before designing or coding |
| `MOCKUP_REFERENCE.md` | Per-screen design decisions and design system tokens | When refining designs or building UI |
| `PHASE_1_FOUNDATION.md` | Detailed Phase 1 build plan (CloudKit + onboarding) | When starting development |
| `PINTEREST_INSPIRATION_BRIEF.md` | Optional design reference gathering guide | If you want to expand visual inspiration |

### Mockups (17 standalone HTML files)

Open any of them in any browser. They show iPhone-sized screens with the full design system applied.

| # | File | Screen |
|---|---|---|
| 01 | `mockups/01_capybara_concepts.html` | Three mascot directions (B selected) |
| 02 | `mockups/02_home_screen.html` | Home — household summary |
| 03 | `mockups/03_add_expense.html` | Add Expense form |
| 04 | `mockups/04_category_picker.html` | Category Picker |
| 05 | `mockups/05_receipt_scan_camera.html` | Receipt Scan — Camera (dark mode) |
| 06 | `mockups/06_receipt_review.html` | Receipt Scan — Review items |
| 07 | `mockups/07_assignment_sheet.html` | Receipt Scan — Assignment bottom sheet |
| 08 | `mockups/08_assistant_empty.html` | Assistant — Empty state with capybara |
| 09 | `mockups/09_assistant_conversation.html` | Assistant — Active conversation |
| 10 | `mockups/10_expenses_tab.html` | Expenses tab with "Who owes who" |
| 11 | `mockups/11_settle_up.html` | Settle Up with debt simplification |
| 12 | `mockups/12_reports_tab.html` | Reports — charts & trends |
| 13 | `mockups/13_onboarding_welcome.html` | Onboarding — Welcome |
| 14 | `mockups/14_onboarding_name.html` | Onboarding — Name household |
| 15 | `mockups/15_onboarding_groups.html` | Onboarding — Set up groups |
| 16 | `mockups/16_onboarding_ai_consent.html` | Onboarding — AI assistant consent |
| 17 | `mockups/17_settings.html` | Settings |
| 18 | `mockups/18_budgets.html` | Budgets |

`mockups/index.html` is a gallery linking to all of them.

---

## How to use this package

### Handing off to Claude Design (or any designer)

1. Open `mockups/index.html` and walk through every screen
2. Read `APP_SUMMARY.md` for the product vision
3. Read `MOCKUP_REFERENCE.md` for the design system and per-screen rationale
4. Refine in Figma / Claude Design — these mockups are direction, not pixel-perfect spec
5. The capybara mascot needs proper illustration work — the SVG version in these mockups is a placeholder

**Key things to refine in design:**
- Final capybara character illustration (proper artwork, multiple poses)
- Final color palette tweaks (the warm cream/brown direction is locked)
- Typography pairing (which serif for headings, final weight choices)
- Empty states and success states with personality
- App icon design (capybara-based)
- Light AND dark mode (mockups are light only)

### Handing off to Claude Code (or any developer)

1. Open `MASTER_SPEC.md` and read it end to end
2. Read `MOCKUP_REFERENCE.md` to understand each screen
3. Open `mockups/index.html` so visuals are available alongside the spec
4. Start with `PHASE_1_FOUNDATION.md` — step-by-step Xcode setup, data model, services
5. Use mockups as visual targets during UI implementation (Phase 2+)

**First Claude Code prompt:**

> "I'm building an iOS app called Splitway — a native expense-splitting app for households. Read MASTER_SPEC.md, MOCKUP_REFERENCE.md, and PHASE_1_FOUNDATION.md from this repo. We're starting Phase 1 today. Begin by setting up the Xcode project structure as specified in Phase 1 section 1, then implement the Core Data model in section 2. Don't start on UI yet — get the foundation right first. Ask me before making any major decisions not covered in the spec."

---

## What's been decided vs. open

### Decided (locked in)
- **App name: Splitway**
- **App Store positioning: "Expenses & Bills — Splitway"**
- iOS native with SwiftUI
- CloudKit local-first architecture (no backend in v1)
- Capybara mascot, warm rounded style, with signature orange-on-head
- Groups system for couples/families
- 5 split types (Equal / Percentages / Amounts / Shares / Excluded)
- Three-option learning model for shared items
- Color palette (warm cream + brown + sage + coral)
- All 17 screens in design
- Claude API for chatbot (Haiku + Sonnet)
- Build philosophy: household beta first, App Store later
- Phase plan and timeline

### Open (decide during or after build)
- Capybara name (Cap? Bara? Cappy? Pip? Or no name?)
- Exact serif typography choice
- App icon design (Splitway capybara-based)
- Dark mode adaptations (build then refine)
- Final illustrated empty states
- Marketing copy / App Store description (for whenever submission happens)

---

## Timeline reference

- **Days 1-50:** Build to household-usable (Phases 1-4.5)
- **Days 50-120+:** Household beta period — real use, fix real bugs
- **Day 120+:** App Store submission when ready

---

When you have questions during build:
- Spec ambiguities → return to `MASTER_SPEC.md`
- UI questions → check `MOCKUP_REFERENCE.md` + the relevant mockup
- New features come up → add to v2 backlog, don't expand v1 scope

بالتوفيق على البناء والبيت الجديد إن شاء الله.
