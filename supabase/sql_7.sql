-- ─────────────────────────────────────────────────────────────────────────────
-- FASE 3: E-commerce, Gestión de Clientes, Pedidos y Pagos a Plataforma
-- Tablas con UUIDs estrictos para aislamiento Multi-Tenant y portabilidad futura.
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. TABLA DE PRODUCTOS
create table public.products (
  id uuid default gen_random_uuid() primary key,
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  name text not null,
  description text,
  price numeric(10,2) not null check (price >= 0),
  image_url text,
  is_active boolean default true,
  created_at timestamp with time zone default timezone('utc'::text, now())
);

alter table public.products enable row level security;

-- Políticas para Productos
-- Públicos para lectura (catálogo web)
create policy "Products are viewable by everyone"
  on public.products for select using (true);

-- Solo el Manager (owner del tenant) o Worker pueden insertar/actualizar/eliminar
create policy "Managers can manage their products"
  on public.products for all using (
    exists (
      select 1 from public.tenants
      where tenants.id = products.tenant_id
      and tenants.owner_id = auth.uid()
    )
    or exists (
      select 1 from public.workers
      where workers.tenant_id = products.tenant_id
      and workers.profile_id = auth.uid()
    )
  );

-- 2. TABLA RELACIONAL CLIENTE-TENANT (Con UUID propio para migración)
create table public.tenant_clients (
  id uuid default gen_random_uuid() primary key,
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamp with time zone default timezone('utc'::text, now()),
  unique(tenant_id, profile_id) -- Un cliente no puede estar dos veces en el mismo tenant
);

alter table public.tenant_clients enable row level security;

-- Políticas para Clientes del Tenant
-- Managers pueden ver sus clientes
create policy "Managers view their clients"
  on public.tenant_clients for select using (
    exists (
      select 1 from public.tenants
      where tenants.id = tenant_clients.tenant_id
      and tenants.owner_id = auth.uid()
    )
  );
-- Clientes pueden ver su propia relación
create policy "Clients view their own relations"
  on public.tenant_clients for select using (profile_id = auth.uid());
-- Insert: Un cliente al registrarse o comprar se vincula automáticamente
create policy "Clients can link themselves"
  on public.tenant_clients for insert with check (profile_id = auth.uid());


-- 3. TABLA DE PEDIDOS (ORDERS)
create table public.orders (
  id uuid default gen_random_uuid() primary key,
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  client_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected', 'completed')),
  total_amount numeric(10,2) not null check (total_amount >= 0),
  created_at timestamp with time zone default timezone('utc'::text, now())
);

alter table public.orders enable row level security;

-- Políticas de Pedidos
-- Manager ve todos los pedidos de su tienda
create policy "Managers view tenant orders"
  on public.orders for select using (
    exists (
      select 1 from public.tenants
      where tenants.id = orders.tenant_id
      and tenants.owner_id = auth.uid()
    )
  );
-- Manager actualiza estado
create policy "Managers update tenant orders"
  on public.orders for update using (
    exists (
      select 1 from public.tenants
      where tenants.id = orders.tenant_id
      and tenants.owner_id = auth.uid()
    )
  );
-- Cliente ve sus propios pedidos
create policy "Clients view own orders"
  on public.orders for select using (client_id = auth.uid());
-- Cliente crea su pedido
create policy "Clients insert own orders"
  on public.orders for insert with check (client_id = auth.uid());


-- 4. DETALLE DE PEDIDOS (ORDER ITEMS)
create table public.order_items (
  id uuid default gen_random_uuid() primary key,
  order_id uuid not null references public.orders(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  quantity integer not null check (quantity > 0),
  unit_price numeric(10,2) not null check (unit_price >= 0)
);

alter table public.order_items enable row level security;

-- Políticas de Detalle de Pedidos
-- Mismas reglas de herencia implícita a través de "orders"
create policy "Users view items of visible orders"
  on public.order_items for select using (
    exists (
      select 1 from public.orders
      where orders.id = order_items.order_id
      and (
        orders.client_id = auth.uid() or
        exists (
          select 1 from public.tenants
          where tenants.id = orders.tenant_id
          and tenants.owner_id = auth.uid()
        )
      )
    )
  );
-- Cliente inserta items a su orden
create policy "Clients insert items"
  on public.order_items for insert with check (
    exists (
      select 1 from public.orders
      where orders.id = order_items.order_id
      and orders.client_id = auth.uid()
    )
  );


-- 5. PAGOS PLATAFORMA (FINANZAS ADMIN Y MRR)
create table public.platform_payments (
  id uuid default gen_random_uuid() primary key,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  concept text not null, -- ej: 'Suscripción Básica - Mes Mayo'
  amount numeric(10,2) not null check (amount >= 0),
  status text not null default 'pending' check (status in ('pending', 'paid', 'failed')),
  payment_date timestamp with time zone,
  created_at timestamp with time zone default timezone('utc'::text, now())
);

alter table public.platform_payments enable row level security;

-- Políticas de Pagos Plataforma
-- Admin ve todo
create policy "Admins view all payments"
  on public.platform_payments for select using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'admin'
    )
  );
-- Usuarios (Owners) ven sus propios pagos
create policy "Users view own payments"
  on public.platform_payments for select using (profile_id = auth.uid());
