# Budtrainer Product Style Guide (en-US)

Purpose: deliver an elegant, sophisticated, and accessible UI for a Canadian client. Keep content professional, concise, and empathetic.

## Principles

- Clarity over cleverness; keep copy short and actionable.
- Elegant minimalism: generous whitespace; remove non-essential visuals.
- Accessibility AA: contrast, focus outlines, keyboard navigation.
- Consistency: one typographic scale, one spacing system, predictable components.

## Voice & Tone

- Professional, calm, and respectful. Avoid slang/idioms.
- Use direct verbs: “Create RFQ”, “Review quote”, “Send invitation”.
- Errors: explain what happened and how to fix. Example: “We couldn’t process the file. Try again or contact support.”

## UI Guidelines

- Typography: Inter (or system), weights 400/500/600. Sizes (example): 14, 16, 20, 24, 32.
- Color: neutral grays + one restrained accent. Avoid heavy shadows; subtle elevation only.
- Spacing: 8px scale. Prefer multiples (8, 16, 24, 32…).
- Components: visible focus states; primary buttons high-contrast; clear field labels and inline help; tables with sticky headers for long lists.

## Content

- Title case for navigation and page titles. Sentence case for buttons.
- Keep sentences < 20 words. Prefer precise nouns and strong verbs.
- Currency always explicit where relevant (e.g., CAD 1,250.00).

## Emails (brief)

- From: “Budtrainer Notifications”. Short subject lines, one clear CTA.

## Implementation notes

- Next.js + Tailwind: define tokens for colors/spacing/typography; build a small library for Button, Input, Select, Table, Card, Modal.
