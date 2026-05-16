create table public.profiles (
  id uuid references auth.users(id) on delete cascade primary key,
  email text not null,
  role text not null check (role in ('admin', 'advertiser', 'manager', 'worker', 'client')),
  created_at timestamp with time zone default timezone('utc'::text, now())
);

-- Seguridad: nadie puede ver perfiles ajenos
alter table public.profiles enable row level security;

create policy "Users can view own profile"
  on public.profiles for select
  using (auth.uid() = id);

create table public.tenants (
  id uuid default gen_random_uuid() primary key,
  owner_id uuid references public.profiles(id) on delete cascade,
  business_name text not null,
  slug text not null unique,  -- ej: "mi-restaurante" → mi-restaurante.quinindews.com
  is_active boolean default true,
  created_at timestamp with time zone default timezone('utc'::text, now())
);

alter table public.tenants enable row level security;

create policy "Managers can view own tenants"
  on public.tenants for select
  using (auth.uid() = owner_id);

create table public.admin_access (
  id uuid default gen_random_uuid() primary key,
  profile_id uuid references public.profiles(id) on delete cascade unique,
  secret_path text not null default 'd8t1-admin-panel',
  created_at timestamp with time zone default timezone('utc'::text, now())
);

alter table public.admin_access enable row level security;

-- Solo el admin puede ver su propio registro
create policy "Admin only"
  on public.admin_access for select
  using (auth.uid() = profile_id);