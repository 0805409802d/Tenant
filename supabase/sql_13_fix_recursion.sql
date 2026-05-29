-- ─────────────────────────────────────────────────────────────────────────────
-- MIGRACIÓN: Arreglo del error de "infinite recursion" en profiles
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. Eliminamos la política defectuosa que causa el bucle infinito
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;

-- 2. Creamos una función segura que revisa si el usuario es admin sin disparar RLS
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean AS $$
DECLARE
  is_admin boolean;
BEGIN
  SELECT (role = 'admin') INTO is_admin
  FROM public.profiles
  WHERE id = auth.uid();
  RETURN COALESCE(is_admin, false);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Volvemos a crear la política usando la función segura
CREATE POLICY "Admins can view all profiles"
  ON public.profiles FOR SELECT
  USING (public.is_admin());
