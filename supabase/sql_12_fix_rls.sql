-- ─────────────────────────────────────────────────────────────────────────────
-- FIX: Políticas RLS para Empleados (Workers) y Clientes
-- ─────────────────────────────────────────────────────────────────────────────

DO $$ 
BEGIN

  -- 1. Tenants son públicos para lectura (necesario para que los clientes vean la tienda por slug y los workers entren)
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Tenants are viewable by everyone' AND tablename = 'tenants') THEN
    CREATE POLICY "Tenants are viewable by everyone" ON public.tenants FOR SELECT USING (true);
  END IF;

  -- 2. Workers pueden ver pedidos de su tienda
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Workers can view tenant orders' AND tablename = 'orders') THEN
    CREATE POLICY "Workers can view tenant orders" ON public.orders FOR SELECT
    USING (tenant_id IN (SELECT tenant_id FROM public.workers WHERE profile_id = auth.uid()));
  END IF;

  -- 3. Workers pueden actualizar pedidos de su tienda
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Workers can update tenant orders' AND tablename = 'orders') THEN
    CREATE POLICY "Workers can update tenant orders" ON public.orders FOR UPDATE
    USING (tenant_id IN (SELECT tenant_id FROM public.workers WHERE profile_id = auth.uid()));
  END IF;

  -- 4. Workers pueden ver los clientes de su tienda
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Workers can view tenant clients' AND tablename = 'tenant_clients') THEN
    CREATE POLICY "Workers can view tenant clients" ON public.tenant_clients FOR SELECT
    USING (tenant_id IN (SELECT tenant_id FROM public.workers WHERE profile_id = auth.uid()));
  END IF;

  -- 5. Workers pueden ver los items de los pedidos
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Workers can view order items' AND tablename = 'order_items') THEN
    CREATE POLICY "Workers can view order items" ON public.order_items FOR SELECT
    USING (
      order_id IN (
        SELECT id FROM public.orders WHERE tenant_id IN (
          SELECT tenant_id FROM public.workers WHERE profile_id = auth.uid()
        )
      )
    );
  END IF;

END $$;
