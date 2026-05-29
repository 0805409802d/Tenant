-- ─────────────────────────────────────────────────────────────────────────────
-- FASE 5: Categorías de Productos y Datos Extendidos de Pedidos
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. TABLA DE CATEGORÍAS
create table if not exists public.categories (
  id uuid default gen_random_uuid() primary key,
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  name text not null,
  is_active boolean default true,
  created_at timestamp with time zone default timezone('utc'::text, now())
);

alter table public.categories enable row level security;

-- Políticas para Categorías
-- Públicas para lectura (catálogo web)
create policy "Categories are viewable by everyone"
  on public.categories for select using (true);

-- Solo el Manager o Worker pueden gestionar las categorías
create policy "Managers and Workers can manage their categories"
  on public.categories for all using (
    exists (
      select 1 from public.tenants
      where tenants.id = categories.tenant_id
      and tenants.owner_id = auth.uid()
    )
    or exists (
      select 1 from public.workers
      where workers.tenant_id = categories.tenant_id
      and workers.profile_id = auth.uid()
    )
  );

-- 2. EXTENSIÓN DE PRODUCTOS
-- Añadir la relación con categorías
alter table public.products
  add column if not exists category_id uuid references public.categories(id) on delete set null;

-- 3. EXTENSIÓN DE PEDIDOS (ORDERS)
-- Añadir campos necesarios para pedidos a domicilio o para llevar
alter table public.orders
  add column if not exists order_type text check (order_type in ('delivery', 'pickup')),
  add column if not exists delivery_address text,
  add column if not exists contact_phone text,
  add column if not exists notes text;
