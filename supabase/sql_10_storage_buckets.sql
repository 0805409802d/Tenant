-- ─────────────────────────────────────────────────────────────────────────────
-- MIGRACIÓN: Creación de buckets de Storage para avatars y logos
-- Ejecutar en Supabase SQL Editor (una sola vez, es idempotente)
-- ─────────────────────────────────────────────────────────────────────────────

-- Crear bucket de avatars si no existe
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do update set public = true;

-- Crear bucket de logos si no existe
insert into storage.buckets (id, name, public)
values ('logos', 'logos', true)
on conflict (id) do update set public = true;

-- Políticas de seguridad para avatars (público para lectura, usuarios autenticados para escritura)
create policy "Avatars are publicly accessible" on storage.objects for select
  using ( bucket_id = 'avatars' );

create policy "Users can upload their own avatars" on storage.objects for insert
  with check ( bucket_id = 'avatars' and auth.role() = 'authenticated' );

create policy "Users can update their own avatars" on storage.objects for update
  using ( bucket_id = 'avatars' and auth.role() = 'authenticated' );

-- Políticas de seguridad para logos (público para lectura, usuarios autenticados para escritura)
create policy "Logos are publicly accessible" on storage.objects for select
  using ( bucket_id = 'logos' );

create policy "Users can upload their own logos" on storage.objects for insert
  with check ( bucket_id = 'logos' and auth.role() = 'authenticated' );

create policy "Users can update their own logos" on storage.objects for update
  using ( bucket_id = 'logos' and auth.role() = 'authenticated' );

-- Crear bucket de productos si no existe
insert into storage.buckets (id, name, public)
values ('products', 'products', true)
on conflict (id) do update set public = true;

-- Políticas de seguridad para productos
create policy "Products are publicly accessible" on storage.objects for select
  using ( bucket_id = 'products' );

create policy "Users can upload their own product images" on storage.objects for insert
  with check ( bucket_id = 'products' and auth.role() = 'authenticated' );

create policy "Users can update their own product images" on storage.objects for update
  using ( bucket_id = 'products' and auth.role() = 'authenticated' );
