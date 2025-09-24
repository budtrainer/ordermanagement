# Contributing to Budtrainer

Thank you for contributing. Use English (en-US) with a professional tone. Never commit real secrets.

## Workflow

- Branch from `main`. Keep PRs small and focused.
- Branch names: `feat/<kebab>`, `fix/<kebab>`, `chore/<kebab>`.
- Conventional Commits: `feat:`, `fix:`, `docs:`, `refactor:`, `chore:`, `ci:`.

## Local Development

- Requirements: Node 20, pnpm 9
- Install deps: `pnpm install`
- Environment files:
  - Copy `/.env.example` → `/.env`
  - Copy `/apps/api/.env.example` → `/apps/api/.env.local`
  - Copy `/apps/web/.env.example` → `/apps/web/.env.local`
- Run:
  - API: `pnpm --filter @budtrainer/api run dev`
  - Web: `pnpm --filter @budtrainer/web run dev`

## Quality Gates

- Type check: `pnpm -w run type-check`
- Lint: `pnpm -w run lint`

## Pull Request Checklist

- [ ] Description explains What / Why / How and a rollback plan
- [ ] `pnpm -w run type-check` passes
- [ ] `pnpm -w run lint` passes
- [ ] No secrets in code or logs
- [ ] Screenshots/video for UI changes
- [ ] Copy follows `docs/STYLE_GUIDE_EN_US.md`

## Security & Privacy

- Do not log secrets or PII. Mask sensitive data in logs.
- Rotate keys on suspicion of exposure.

## Links

- Style Guide: `docs/STYLE_GUIDE_EN_US.md`
- Environments & Secrets: `docs/ENV_AND_SECRETS.md`
