-- ─────────────────────────────────────────────────────────────────────────────
-- FASE 4: Suscripciones y Límites de Productos
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. Añadir columnas de suscripción a la tabla tenants
ALTER TABLE public.tenants
ADD COLUMN IF NOT EXISTS subscription_tier TEXT DEFAULT 'freemium' CHECK (subscription_tier IN ('freemium', 'low', 'mid', 'high')),
ADD COLUMN IF NOT EXISTS subscription_status TEXT DEFAULT 'active' CHECK (subscription_status IN ('active', 'past_due', 'canceled')),
ADD COLUMN IF NOT EXISTS stripe_customer_id TEXT;

-- 2. Función para comprobar el límite de productos antes de insertar
CREATE OR REPLACE FUNCTION public.check_product_limit()
RETURNS TRIGGER AS $$
DECLARE
  v_tier TEXT;
  v_current_count INTEGER;
  v_limit INTEGER;
BEGIN
  -- Obtener el tier actual del tenant
  SELECT subscription_tier INTO v_tier FROM public.tenants WHERE id = NEW.tenant_id;
  
  -- Si no existe o hay algún problema, permitimos asumiendo que RLS filtrará si es inválido
  IF v_tier IS NULL THEN
    RETURN NEW;
  END IF;

  -- Asignar el límite basado en el tier
  CASE v_tier
    WHEN 'freemium' THEN v_limit := 20;
    WHEN 'low' THEN v_limit := 100;
    WHEN 'mid' THEN v_limit := 500;
    WHEN 'high' THEN v_limit := 999999; -- Ilimitado
    ELSE v_limit := 20;
  END CASE;

  -- Contar cuántos productos tiene actualmente este tenant
  SELECT COUNT(id) INTO v_current_count FROM public.products WHERE tenant_id = NEW.tenant_id;

  -- Verificar si excede
  IF v_current_count >= v_limit THEN
    RAISE EXCEPTION 'Product limit reached for tier % (Limit: %)', v_tier, v_limit;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Crear el Trigger en la tabla products
DROP TRIGGER IF EXISTS trigger_check_product_limit ON public.products;
CREATE TRIGGER trigger_check_product_limit
BEFORE INSERT ON public.products
FOR EACH ROW EXECUTE FUNCTION public.check_product_limit();


-- 4. Función RPC para obtener el uso de productos de un tenant (para el Navbar en Flutter)
CREATE OR REPLACE FUNCTION public.get_tenant_product_usage(p_tenant_id UUID)
RETURNS JSON AS $$
DECLARE
  v_tier TEXT;
  v_current_count INTEGER;
  v_limit INTEGER;
BEGIN
  -- Verificar que el usuario tenga acceso a este tenant (Owner o Worker)
  IF NOT EXISTS (
    SELECT 1 FROM public.tenants WHERE id = p_tenant_id AND owner_id = auth.uid()
  ) AND NOT EXISTS (
    SELECT 1 FROM public.workers WHERE tenant_id = p_tenant_id AND profile_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  -- Obtener el tier
  SELECT subscription_tier INTO v_tier FROM public.tenants WHERE id = p_tenant_id;
  
  CASE v_tier
    WHEN 'freemium' THEN v_limit := 20;
    WHEN 'low' THEN v_limit := 100;
    WHEN 'mid' THEN v_limit := 500;
    WHEN 'high' THEN v_limit := 999999;
    ELSE v_limit := 20;
  END CASE;

  -- Obtener el conteo
  SELECT COUNT(id) INTO v_current_count FROM public.products WHERE tenant_id = p_tenant_id;

  RETURN json_build_object(
    'tier', v_tier,
    'used', v_current_count,
    'limit', v_limit
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
