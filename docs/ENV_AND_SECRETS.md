# Environments and Secrets — Budtrainer

This document describes how to configure local env files and provider secrets (GitHub, Vercel, Supabase) for a single production environment setup.

## Local env files (development only)

Never commit real secrets. Use the example files and copy them locally:

- Copy `/.env.example` → `/.env` and fill placeholders as needed.
- Copy `/apps/api/.env.example` → `/apps/api/.env.local` and fill:
  - `SUPABASE_URL`
  - `SUPABASE_SERVICE_ROLE`
  - `LOG_LEVEL=info`
  - `CIN7_API_BASE=https://api.cin7.com/api/v1`
  - `CIN7_API_KEY`
- Copy `/apps/web/.env.example` → `/apps/web/.env.local` and fill:
  - `NEXT_PUBLIC_SUPABASE_URL`
  - `NEXT_PUBLIC_SUPABASE_ANON_KEY`
  - Optional: `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY`

Note: Your repo currently allows tracking `.env*`. Treat this with care. Prefer not to commit files containing real secrets.

## GitHub Actions — repository secrets

Required to run the deploy workflows:

- `SUPABASE_ACCESS_TOKEN` — Personal access token from Supabase (Account → Access Tokens)
- (Optional) `SUPABASE_DB_PASSWORD` — Database password to allow `supabase db push`
- `VERCEL_TOKEN`, `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID` — Vercel credentials for the web deploy

Add in: GitHub → Repo → Settings → Secrets and variables → Actions → New repository secret

## Vercel — project environment

Project must point to `apps/web` (Root Directory).

Set Production environment variables in Project Settings → Environment Variables:

- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- Optional: `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY`

The GitHub workflow `.github/workflows/deploy-web.yml` will pull these with `vercel pull` before deploying.

## Supabase — project setup (already done)

- Storage buckets `templates` and `rfqs` created via migration.
- Edge Functions stubs deployed.
- Optional: you may set project-level secrets for Edge Functions using the CLI if needed later:

```sh
supabase secrets set KEY=VALUE
```

## Security notes

- Do not publish real secrets in Git history or public PRs.
- If a secret is accidentally committed, rotate it in the provider (Supabase/Vercel/GitHub) immediately.
- Use the single production environment with manual deploys to keep control and reduce complexity.
