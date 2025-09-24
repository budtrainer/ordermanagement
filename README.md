# Budtrainer Monorepo

Order Management & Supplier Portal (CIN7-only, Supabase)

- Language & tone: English (en-US), professional (Canadian client)
- Tech stack: Next.js 14, TypeScript, Tailwind, React Query, Zod; Fastify; Supabase (Auth, Postgres, Storage, Edge Functions)

## Structure

```
/
├── apps/
│   ├── web/                 # Next.js frontend (F1.0-C)
│   └── api/                 # Fastify backend (F1.0-D)
├── packages/
│   ├── domain/              # Domain entities and value objects
│   ├── shared/              # Shared types and utilities
│   └── cache/               # Cache contract/utilities
├── supabase/
│   ├── functions/           # Edge functions (stubs in F1.0-F)
│   ├── migrations/          # Database migrations (F1.1+)
│   └── seed/                # Seed data
└── infrastructure/
    ├── docker/              # Docker configs (future)
    └── scripts/             # Deployment scripts (CI/CD)
```

## Workspaces

- Managed by pnpm. See `pnpm-workspace.yaml`.

## Node version

- Node 20 (see `.nvmrc`).

## Quickstart

1. Install dependencies

```bash
pnpm install
```

2. Environment setup (do not commit real secrets)

- Copy `/.env.example` → `/.env`
- Copy `/apps/api/.env.example` → `/apps/api/.env.local`
- Copy `/apps/web/.env.example` → `/apps/web/.env.local`

3. Run apps

```bash
# API
pnpm --filter @budtrainer/api run dev

# Web
pnpm --filter @budtrainer/web run dev
```

## Docs

- Style Guide (UI tone & elegance): `docs/STYLE_GUIDE_EN_US.md`
- Contributing: `CONTRIBUTING.md`
- Environments & Secrets: `docs/ENV_AND_SECRETS.md`

# ordermanagement
