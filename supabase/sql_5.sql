create table public.workers (
  id uuid default gen_random_uuid() primary key,
  tenant_id uuid references public.tenants(id) on delete cascade,
  profile_id uuid references public.profiles(id) on delete cascade,
  first_name text not null,
  last_name text not null,
  email text not null unique,
  created_at timestamp with time zone default timezone('utc'::text, now())
);

alter table public.workers enable row level security;

create policy "Managers manage own workers"
  on public.workers for all
  using (
    exists (
      select 1 from public.tenants
      where tenants.id = workers.tenant_id
      and tenants.owner_id = auth.uid()
    )
  );

alter table public.tenants
  add column if not exists business_type_id integer references public.business_types(id),
  add column if not exists link_url text,
  add column if not exists qr_url text,
  add column if not exists accepted_terms boolean default false,
  add column if not exists terms_accepted_at timestamp with time zone;