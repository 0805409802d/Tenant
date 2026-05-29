-- ─────────────────────────────────────────────────────────────────────────────
-- FASE 7: Mejoras Generales Backend (Stock, Proveedores, WhatsApp, Crédito y Rentabilidad)
-- ─────────────────────────────────────────────────────────────────────────────

-- ==========================================
-- MEJORA 1: GESTIÓN DE STOCK Y ALERTAS
-- ==========================================

-- 1.1. Extensión de la tabla de productos existente
ALTER TABLE public.products
  ADD COLUMN IF NOT EXISTS stock_quantity integer DEFAULT 0 CHECK (stock_quantity >= 0),
  ADD COLUMN IF NOT EXISTS min_stock_alert integer DEFAULT 5 CHECK (min_stock_alert >= 0),
  ADD COLUMN IF NOT EXISTS track_inventory boolean DEFAULT true,
  ADD COLUMN IF NOT EXISTS cost_price numeric(10,2) DEFAULT 0.00 CHECK (cost_price >= 0);

-- 1.2. Tabla de historial de movimientos de inventario (Auditoría)
CREATE TABLE IF NOT EXISTS public.inventory_transactions (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  quantity_changed integer NOT NULL, -- Positivo (+) entradas, Negativo (-) salidas
  transaction_type text NOT NULL CHECK (transaction_type IN ('sale', 'purchase', 'adjustment', 'return')),
  reference_id uuid, -- ID opcional del pedido o compra
  notes text,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  created_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL
);

ALTER TABLE public.inventory_transactions ENABLE ROW LEVEL SECURITY;

-- 1.3. Políticas para el Historial de Inventario (Tabla inventory_transactions)

-- Trabajadores: Pueden ver el historial de transacciones
CREATE POLICY "Workers can view inventory transactions"
  ON public.inventory_transactions FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.workers
      WHERE workers.tenant_id = inventory_transactions.tenant_id
      AND workers.profile_id = auth.uid()
    )
  );

-- Trabajadores: Pueden registrar ajustes manuales
CREATE POLICY "Workers can insert inventory transactions"
  ON public.inventory_transactions FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.workers
      WHERE workers.tenant_id = inventory_transactions.tenant_id
      AND workers.profile_id = auth.uid()
    )
  );

-- Management (Dueño): Control y auditoría completa de todas las transacciones de inventario
CREATE POLICY "Managers have full access to inventory transactions"
  ON public.inventory_transactions FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.tenants
      WHERE tenants.id = inventory_transactions.tenant_id
      AND tenants.owner_id = auth.uid()
    )
  );

-- 1.4. Automatización en Base de Datos (Disminución Automática de Stock)
CREATE OR REPLACE FUNCTION public.handle_order_stock_deduction()
RETURNS TRIGGER AS $$
DECLARE
  item RECORD;
BEGIN
  -- Solo deducir cuando el pedido es aprobado (de 'pending' a 'approved')
  IF NEW.status = 'approved' AND OLD.status = 'pending' THEN
    FOR item IN 
      SELECT product_id, quantity 
      FROM public.order_items 
      WHERE order_id = NEW.id
    LOOP
      -- Validar si el producto lleva control de inventario y descontar
      UPDATE public.products
      SET stock_quantity = stock_quantity - item.quantity
      WHERE id = item.product_id AND track_inventory = true;

      -- Registrar auditoría si el producto tiene track_inventory activo
      INSERT INTO public.inventory_transactions (
        tenant_id, product_id, quantity_changed, transaction_type, reference_id, notes, created_by
      )
      VALUES (
        NEW.tenant_id, item.product_id, -item.quantity, 'sale', NEW.id, 
        'Descuento automático por aprobación de orden N° ' || NEW.id, NEW.client_id
      );
    END LOOP;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_order_approved_deduct_stock ON public.orders;
CREATE TRIGGER on_order_approved_deduct_stock
  AFTER UPDATE OF status ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_order_stock_deduction();


-- ==========================================
-- MEJORA 2: MÓDULO DE PROVEEDORES E HISTORIAL DE COSTOS
-- ==========================================

-- 2.1. Tabla de Proveedores
CREATE TABLE IF NOT EXISTS public.suppliers (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  name text NOT NULL,
  contact_name text,
  phone text,
  email text,
  address text,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now())
);

-- 2.2. Tabla de Compras/Reabastecimiento
CREATE TABLE IF NOT EXISTS public.supplier_purchases (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  supplier_id uuid REFERENCES public.suppliers(id) ON DELETE SET NULL,
  purchase_date timestamp with time zone DEFAULT timezone('utc'::text, now()),
  total_amount numeric(10,2) NOT NULL DEFAULT 0.00 CHECK (total_amount >= 0),
  status text NOT NULL DEFAULT 'completed' CHECK (status IN ('pending', 'completed', 'cancelled')),
  notes text,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  registered_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL
);

-- 2.3. Detalle de los Productos Comprados
CREATE TABLE IF NOT EXISTS public.purchase_items (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  purchase_id uuid NOT NULL REFERENCES public.supplier_purchases(id) ON DELETE CASCADE,
  product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  quantity integer NOT NULL CHECK (quantity > 0),
  cost_price numeric(10,2) NOT NULL CHECK (cost_price >= 0)
);

ALTER TABLE public.suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.supplier_purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.purchase_items ENABLE ROW LEVEL SECURITY;

-- 2.4. Políticas de Proveedores

CREATE POLICY "Workers can view suppliers"
  ON public.suppliers FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.workers WHERE workers.tenant_id = suppliers.tenant_id AND workers.profile_id = auth.uid())
  );

CREATE POLICY "Workers can insert suppliers"
  ON public.suppliers FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.workers WHERE workers.tenant_id = suppliers.tenant_id AND workers.profile_id = auth.uid())
  );

CREATE POLICY "Managers have full access to suppliers"
  ON public.suppliers FOR ALL USING (
    EXISTS (SELECT 1 FROM public.tenants WHERE tenants.id = suppliers.tenant_id AND tenants.owner_id = auth.uid())
  );

-- 2.5. Políticas de Compras y Detalles

CREATE POLICY "Workers can view purchases"
  ON public.supplier_purchases FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.workers WHERE workers.tenant_id = supplier_purchases.tenant_id AND workers.profile_id = auth.uid())
  );

CREATE POLICY "Workers can insert purchases"
  ON public.supplier_purchases FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.workers WHERE workers.tenant_id = supplier_purchases.tenant_id AND workers.profile_id = auth.uid())
  );

CREATE POLICY "Workers can view purchase items"
  ON public.purchase_items FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.supplier_purchases
      JOIN public.workers ON workers.tenant_id = supplier_purchases.tenant_id
      WHERE supplier_purchases.id = purchase_items.purchase_id
      AND workers.profile_id = auth.uid()
    )
  );

CREATE POLICY "Workers can insert purchase items"
  ON public.purchase_items FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.supplier_purchases
      JOIN public.workers ON workers.tenant_id = supplier_purchases.tenant_id
      WHERE supplier_purchases.id = purchase_items.purchase_id
      AND workers.profile_id = auth.uid()
    )
  );

CREATE POLICY "Managers have full access to purchases"
  ON public.supplier_purchases FOR ALL USING (
    EXISTS (SELECT 1 FROM public.tenants WHERE tenants.id = supplier_purchases.tenant_id AND tenants.owner_id = auth.uid())
  );

CREATE POLICY "Managers have full access to purchase items"
  ON public.purchase_items FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.supplier_purchases
      JOIN public.tenants ON tenants.id = supplier_purchases.tenant_id
      WHERE supplier_purchases.id = purchase_items.purchase_id
      AND tenants.owner_id = auth.uid()
    )
  );


-- ==========================================
-- MEJORA 3: CATÁLOGO WEB DE WHATSAPP
-- ==========================================

-- 3.1. Extensión de la tabla de configuraciones de tenants
ALTER TABLE public.tenants
  ADD COLUMN IF NOT EXISTS whatsapp_number text,
  ADD COLUMN IF NOT EXISTS whatsapp_enabled boolean DEFAULT true,
  ADD COLUMN IF NOT EXISTS currency_symbol text DEFAULT '$',
  ADD COLUMN IF NOT EXISTS catalog_cover_url text,
  ADD COLUMN IF NOT EXISTS shipping_cost numeric(10,2) DEFAULT 0.00 CHECK (shipping_cost >= 0),
  ADD COLUMN IF NOT EXISTS manual_payment_instructions text;


-- ==========================================
-- MEJORA 4: LIBRO DE CRÉDITO A CLIENTES
-- ==========================================

-- 4.1. Campos adicionales en la relación cliente-tenant
ALTER TABLE public.tenant_clients
  ADD COLUMN IF NOT EXISTS credit_limit numeric(10,2) DEFAULT 0.00 CHECK (credit_limit >= 0),
  ADD COLUMN IF NOT EXISTS current_debt numeric(10,2) DEFAULT 0.00 CHECK (current_debt >= 0),
  ADD COLUMN IF NOT EXISTS is_credit_approved boolean DEFAULT false;

-- 4.2. Permitir a los dueños (managers) actualizar el crédito de sus clientes
-- (La política de SELECT ya existe en FASE 3)
CREATE POLICY "Managers can update their clients"
  ON public.tenant_clients FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.tenants
      WHERE tenants.id = tenant_clients.tenant_id
      AND tenants.owner_id = auth.uid()
    )
  );

-- 4.3. Tabla del Libro diario de Crédito
CREATE TABLE IF NOT EXISTS public.client_credit_ledger (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  client_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  amount numeric(10,2) NOT NULL, -- Positivo (+) para cargos/compras, Negativo (-) para abonos
  transaction_type text NOT NULL CHECK (transaction_type IN ('charge', 'payment', 'adjustment')),
  reference_order_id uuid REFERENCES public.orders(id) ON DELETE SET NULL,
  notes text,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  created_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL
);

ALTER TABLE public.client_credit_ledger ENABLE ROW LEVEL SECURITY;

-- 4.4. Políticas para Libro de Crédito
CREATE POLICY "Clients can view their own credit ledger"
  ON public.client_credit_ledger FOR SELECT USING (client_id = auth.uid());

CREATE POLICY "Workers can view credit entries"
  ON public.client_credit_ledger FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.workers WHERE workers.tenant_id = client_credit_ledger.tenant_id AND workers.profile_id = auth.uid())
  );

CREATE POLICY "Workers can insert credit entries"
  ON public.client_credit_ledger FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.workers WHERE workers.tenant_id = client_credit_ledger.tenant_id AND workers.profile_id = auth.uid())
  );

CREATE POLICY "Managers have full access to credit ledger"
  ON public.client_credit_ledger FOR ALL USING (
    EXISTS (SELECT 1 FROM public.tenants WHERE tenants.id = client_credit_ledger.tenant_id AND tenants.owner_id = auth.uid())
  );

-- 4.5. Trigger de Automatización Contable
CREATE OR REPLACE FUNCTION public.update_tenant_client_debt()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.tenant_clients
  SET current_debt = current_debt + NEW.amount
  WHERE tenant_id = NEW.tenant_id AND profile_id = NEW.client_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_credit_ledger_change ON public.client_credit_ledger;
CREATE TRIGGER on_credit_ledger_change
  AFTER INSERT ON public.client_credit_ledger
  FOR EACH ROW
  EXECUTE FUNCTION public.update_tenant_client_debt();


-- ==========================================
-- MEJORA 5: PANEL DE RENTABILIDAD
-- ==========================================

-- 5.1. Extensión de la tabla de detalles de pedido
ALTER TABLE public.order_items
  ADD COLUMN IF NOT EXISTS unit_cost_price numeric(10,2) DEFAULT 0.00 CHECK (unit_cost_price >= 0);

-- 5.2. Trigger automático para sellar el costo en el momento de la venta
CREATE OR REPLACE FUNCTION public.stamp_product_cost_on_sale()
RETURNS TRIGGER AS $$
DECLARE
  current_cost numeric(10,2);
BEGIN
  SELECT cost_price INTO current_cost
  FROM public.products
  WHERE id = NEW.product_id;

  NEW.unit_cost_price := COALESCE(current_cost, 0.00);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_order_item_create_stamp_cost ON public.order_items;
CREATE TRIGGER on_order_item_create_stamp_cost
  BEFORE INSERT ON public.order_items
  FOR EACH ROW
  EXECUTE FUNCTION public.stamp_product_cost_on_sale();

-- 5.3. Función RPC para cálculo del Reporte Financiero
CREATE OR REPLACE FUNCTION public.get_tenant_profitability_report(
  p_tenant_id uuid,
  p_start_date timestamp with time zone,
  p_end_date timestamp with time zone
)
RETURNS TABLE (
  total_revenue numeric,
  total_cost numeric,
  net_profit numeric,
  profit_margin_percentage numeric
) AS $$
BEGIN
  -- Validar que el usuario que ejecuta la consulta sea el OWNER (Management) del Tenant
  IF NOT EXISTS (
    SELECT 1 FROM public.tenants 
    WHERE id = p_tenant_id AND owner_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Acceso Denegado: Solo el dueño de la tienda puede consultar reportes financieros.';
  END IF;

  RETURN QUERY
  SELECT 
    COALESCE(SUM(o.total_amount), 0.00) as total_revenue,
    COALESCE(SUM(oi.quantity * oi.unit_cost_price), 0.00) as total_cost,
    COALESCE(SUM(o.total_amount) - SUM(oi.quantity * oi.unit_cost_price), 0.00) as net_profit,
    CASE 
      WHEN SUM(o.total_amount) > 0 THEN 
        ROUND(((SUM(o.total_amount) - SUM(oi.quantity * oi.unit_cost_price)) / SUM(o.total_amount) * 100), 2)
      ELSE 0.00
    END as profit_margin_percentage
  FROM public.orders o
  JOIN public.order_items oi ON oi.order_id = o.id
  WHERE o.tenant_id = p_tenant_id
    AND o.status = 'approved'
    AND o.created_at BETWEEN p_start_date AND p_end_date;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
