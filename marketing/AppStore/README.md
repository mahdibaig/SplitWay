# Splitway, App Store marketing

Everything needed for an App Store submission lives here. The files are markdown for editing convenience, but most of them paste directly into App Store Connect.

## Files

- `description.md`: Name, subtitle, promotional text, and the full long description. Drop into App Store Connect's App Information tab.
- `keywords.txt`: 100-character keyword string for ASO.
- `whats-new.md`: Per-version release notes. The 1.0 entry is ready.
- `screenshots-plan.md`: Which 8 screens to capture, what to show, and two caption sets to A/B test.
- `privacy-nutrition.md`: Answers for the Privacy Nutrition Label questionnaire.
- `support-faq.md`: Content for `splitway.app/support`, required by Apple.

## Before submitting

1. Confirm pricing matches what's in `description.md` (currently $24.99 / $39.99 / $89).
2. Confirm `support@splitway.app` exists and routes to an inbox you check.
3. Confirm `splitway.app/privacy`, `splitway.app/terms`, and `splitway.app/support` are live (content sources: `marketing/legal/` and this folder).
4. Capture the 8 screenshots per device class (see `screenshots-plan.md`).
5. Get the App Icon designed (default Xcode icon still in `Splitway/Resources/Assets.xcassets/AppIcon.appiconset/`). Spec from HANDOFF.md: 1024x1024, capybara, cream and brown palette, no transparency, no rounded corners.
6. Sanity-check the Privacy Nutrition answers in `privacy-nutrition.md` against any new data flows added since 2026-05-16.

## When to update

- New features that change the differentiator pitch: refresh `description.md`.
- Pricing change: refresh `description.md`, `whats-new.md`, and the FAQ.
- New AI feature, new external service, or proxy goes live: refresh `privacy-nutrition.md` and `support-faq.md`.
- Major UI refresh: re-capture screenshots and rewrite captions.

## Style rules (same as the rest of the project)

- Plain language. No legalese, no marketing fluff.
- No em dashes, no en dashes. Use commas, periods, or "to" for ranges.
- Avoid superlatives. "The best", "amazing", "revolutionary" all read as AI slop and Apple App Review pushes back on them.
- Use the founder's voice. Splitway is an indie app, not a startup pitch deck.
- When you mention features, link them to outcomes. "Smart receipt scanning" is a feature; "stop tagging milk every Tuesday" is the outcome that gets a download.
