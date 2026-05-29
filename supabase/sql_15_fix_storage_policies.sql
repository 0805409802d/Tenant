-- ─────────────────────────────────────────────────────────────────────────────
-- FASE 6: Corrección de Seguridad en Storage (Buckets)
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. Eliminar las políticas inseguras anteriores para Logos
drop policy if exists "Users can upload their own logos" on storage.objects;
drop policy if exists "Users can update their own logos" on storage.objects;

-- 2. Eliminar las políticas inseguras anteriores para Productos
drop policy if exists "Users can upload their own product images" on storage.objects;
drop policy if exists "Users can update their own product images" on storage.objects;

-- 3. Crear función de seguridad para verificar rol (Optimización de rendimiento)
create or replace function public.is_manager_or_worker()
returns boolean as $$
declare
  user_role text;
begin
  select role into user_role from public.profiles where id = auth.uid();
  return user_role in ('manager', 'worker');
end;
$$ language plpgsql security definer;

-- 4. Nuevas políticas seguras para LOGOS
create policy "Managers and Workers can upload logos" on storage.objects for insert
  with check ( bucket_id = 'logos' and auth.role() = 'authenticated' and public.is_manager_or_worker() );

create policy "Managers and Workers can update logos" on storage.objects for update
  using ( bucket_id = 'logos' and auth.role() = 'authenticated' and public.is_manager_or_worker() );

-- 5. Nuevas políticas seguras para PRODUCTOS
create policy "Managers and Workers can upload product images" on storage.objects for insert
  with check ( bucket_id = 'products' and auth.role() = 'authenticated' and public.is_manager_or_worker() );

create policy "Managers and Workers can update product images" on storage.objects for update
  using ( bucket_id = 'products' and auth.role() = 'authenticated' and public.is_manager_or_worker() );
