-- F1.0-E — Supabase bootstrap: Storage buckets & minimal policies
-- This migration creates the private buckets `templates` and `rfqs` and
-- sets minimal RLS policies that allow access for authenticated users only.
-- Suppliers will access files via signed URLs generated server-side.

-- Create buckets (id must be unique). Use ON CONFLICT to be idempotent.
insert into storage.buckets (id, name, public)
values ('templates', 'templates', false)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('rfqs', 'rfqs', false)
on conflict (id) do nothing;

-- RLS is enabled on storage.objects by default in Supabase
-- Skipping alter table statement to avoid ownership issues

-- ==========================
-- Policies for bucket: templates
-- ==========================
-- Read (authenticated)
drop policy if exists "templates_select_auth" on storage.objects;
create policy "templates_select_auth"
  on storage.objects for select
  using (
    bucket_id = 'templates'
    and auth.uid() is not null
  );

-- Insert (authenticated)
drop policy if exists "templates_insert_auth" on storage.objects;
create policy "templates_insert_auth"
  on storage.objects for insert
  with check (
    bucket_id = 'templates'
    and auth.uid() is not null
  );

-- Update (authenticated)
drop policy if exists "templates_update_auth" on storage.objects;
create policy "templates_update_auth"
  on storage.objects for update
  using (
    bucket_id = 'templates'
    and auth.uid() is not null
  )
  with check (
    bucket_id = 'templates'
    and auth.uid() is not null
  );

-- Delete (authenticated)
drop policy if exists "templates_delete_auth" on storage.objects;
create policy "templates_delete_auth"
  on storage.objects for delete
  using (
    bucket_id = 'templates'
    and auth.uid() is not null
  );

-- ==========================
-- Policies for bucket: rfqs
-- ==========================
-- Read (authenticated)
drop policy if exists "rfqs_select_auth" on storage.objects;
create policy "rfqs_select_auth"
  on storage.objects for select
  using (
    bucket_id = 'rfqs'
    and auth.uid() is not null
  );

-- Insert (authenticated)
drop policy if exists "rfqs_insert_auth" on storage.objects;
create policy "rfqs_insert_auth"
  on storage.objects for insert
  with check (
    bucket_id = 'rfqs'
    and auth.uid() is not null
  );

-- Update (authenticated)
drop policy if exists "rfqs_update_auth" on storage.objects;
create policy "rfqs_update_auth"
  on storage.objects for update
  using (
    bucket_id = 'rfqs'
    and auth.uid() is not null
  )
  with check (
    bucket_id = 'rfqs'
    and auth.uid() is not null
  );

-- Delete (authenticated)
drop policy if exists "rfqs_delete_auth" on storage.objects;
create policy "rfqs_delete_auth"
  on storage.objects for delete
  using (
    bucket_id = 'rfqs'
    and auth.uid() is not null
  );
