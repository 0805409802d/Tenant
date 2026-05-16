-- ─────────────────────────────────────────────────────────────────────────────
-- FIX: Permitir inserción en perfiles y tenants durante el registro
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. Políticas para profiles
create policy "Users can insert own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id);

-- 2. Políticas para tenants
create policy "Managers can insert own tenant"
  on public.tenants for insert
  with check (auth.uid() = owner_id);

create policy "Managers can update own tenant"
  on public.tenants for update
  using (auth.uid() = owner_id);
