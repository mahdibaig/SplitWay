# Splitway, legal pages

Source of truth for Splitway's Privacy Policy and Terms of Service. The markdown here is the canonical version. The HTML at `splitway.app/privacy` and `splitway.app/terms` is derived from it.

## Files

- `privacy.md`: Privacy Policy. Covers what data Splitway handles, on-device vs iCloud vs DeepSeek, retention, your controls.
- `terms.md`: Terms of Service. License, AI assistant disclaimer, in-app purchases, limitation of liability, governing law.

## Before launching

Both documents have a few placeholders to fill in before they go live:

- `support@splitway.app`: confirm the address exists and routes to an inbox you check.
- Registered business address (privacy.md Contact section): add if/when a registered business is set up.
- Governing law jurisdiction (terms.md): currently set to Texas. Change if the founder relocates or registers a business elsewhere.
- "Last updated" date: refresh whenever the content changes.

## When to update

- Any new data flow that touches an external service: update `privacy.md`.
- New paid features, pricing changes, or new third-party integrations: update both.
- AI provider change (from DeepSeek to something else, or addition of a proxy): update `privacy.md`.

When the content changes materially, also publish an in-app announcement per the project guidelines in HANDOFF.md.

## Style rules (same as the rest of the project)

- Plain language. No legal jargon when a normal word works.
- No em dashes, no en dashes. Use commas, periods, or "to" for ranges.
- No markdown emphasis (no asterisks for bold or italic) inside body text.
- One blank line between paragraphs.
- Use full URLs (splitway.app/privacy), not relative links.

## Deploying to splitway.app

Convert markdown to HTML with the project's preferred build (pandoc, Astro, or a simple static-site generator). A minimal wrap is fine: header, container with max-width 720px, body font matching the app's serif accent for headings and system sans for body.
