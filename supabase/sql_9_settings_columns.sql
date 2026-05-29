-- ─────────────────────────────────────────────────────────────────────────────
-- MIGRACIÓN: Columnas de personalización para tenants y profiles
-- Ejecutar en Supabase SQL Editor (una sola vez, es idempotente)
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. Columnas en TENANTS
alter table public.tenants
  add column if not exists primary_color text default '#1E6BFF',
  add column if not exists logo_url      text,
  add column if not exists link_url      text,
  add column if not exists business_type_id integer references public.business_types(id),
  add column if not exists accepted_terms boolean default false,
  add column if not exists terms_accepted_at timestamp with time zone,
  add column if not exists phone         text,
  add column if not exists country       text,
  add column if not exists city          text,
  add column if not exists address       text;

-- 2. Columnas en PROFILES
alter table public.profiles
  add column if not exists owner_name    text,
  add column if not exists business_name text,
  add column if not exists phone         text,
  add column if not exists country       text,
  add column if not exists city          text,
  add column if not exists address       text,
  add column if not exists avatar_url    text,
  add column if not exists first_name    text,
  add column if not exists last_name     text;

-- 3. Rellenar link_url con el valor por defecto para tenants existentes
update public.tenants
  set link_url = 'https://' || slug || '.quinindews.com'
  where link_url is null;

-- 4. Política para que admins lean todos los perfiles (para gestión)
do $$ 
begin
  if not exists (select 1 from pg_policies where policyname = 'Admins can view all profiles' and tablename = 'profiles') then
    create policy "Admins can view all profiles"
      on public.profiles for select
      using (
        exists (
          select 1 from public.profiles p
          where p.id = auth.uid() and p.role = 'admin'
        )
      );
  end if;
end $$;