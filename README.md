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

## Next steps

- F1.0-B: add linting, formatting, commit hooks, and dev guides.
- F1.0-C/D: bootstrap Next.js (web) and Fastify (api) baselines.

# ordermanagement
