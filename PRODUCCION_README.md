# 🚀 Guía de Producción — Sistema Multi-Tenant

Este archivo documenta todos los pasos **manuales** que debes ejecutar en Supabase para dejar el sistema completamente funcional en producción.

---

## PASO 1 — Instalar Supabase CLI

Si no lo tienes instalado:

```bash
npm install -g supabase
```

Inicia sesión en tu cuenta de Supabase:

```bash
supabase login
```

---

## PASO 2 — Vincular tu proyecto Supabase

En la raíz del proyecto, ejecuta:

```bash
supabase link --project-ref TU_PROJECT_REF
```

> 🔍 Encuentra tu `PROJECT_REF` en: **Supabase Dashboard → Settings → General → Reference ID**

---

## PASO 3 — Desplegar las Edge Functions

Las Edge Functions son necesarias para crear y eliminar trabajadores sin que la sesión del manager se vea afectada.

```bash
supabase functions deploy create-worker --no-verify-jwt
supabase functions deploy delete-worker --no-verify-jwt
```

> ⚠️ El flag `--no-verify-jwt` permite que las functions verifiquen el JWT manualmente (ya lo hacen internamente).

### Verificar que están desplegadas

En el Dashboard de Supabase → **Edge Functions** debes ver:
- `create-worker` ✅
- `delete-worker` ✅

---

## PASO 4 — Crear el RPC `get_security_questions_by_email`

Este procedimiento es utilizado por el sistema de recuperación de cuenta. Ejecútalo en el **SQL Editor** de Supabase:

```sql
-- Función para obtener preguntas de seguridad por email (para recuperación de cuenta)
CREATE OR REPLACE FUNCTION get_security_questions_by_email(user_email TEXT)
RETURNS TABLE (
  question_1 TEXT,
  question_2 TEXT,
  question_3 TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT
    sq.question_1,
    sq.question_2,
    sq.question_3
  FROM security_questions sq
  INNER JOIN profiles p ON p.id = sq.profile_id
  WHERE LOWER(p.email) = LOWER(user_email)
  LIMIT 1;
END;
$$;
```

---

## PASO 5 — Verificar políticas RLS de `tenant_clients`

Ejecuta esto en el SQL Editor para asegurarte de que los clientes pueden vincularse a la tienda al registrarse:

```sql
-- Permitir a clientes insertarse en tenant_clients
CREATE POLICY IF NOT EXISTS "Clients can link themselves"
  ON public.tenant_clients FOR INSERT
  WITH CHECK (profile_id = auth.uid());

-- Permitir a managers leer los clientes de su tienda
CREATE POLICY IF NOT EXISTS "Managers can view their clients"
  ON public.tenant_clients FOR SELECT
  USING (
    tenant_id IN (
      SELECT id FROM tenants WHERE owner_id = auth.uid()
    )
    OR
    -- Workers también pueden ver los clientes de su tienda
    tenant_id IN (
      SELECT tenant_id FROM workers WHERE profile_id = auth.uid()
    )
  );
```

---

## PASO 6 — Verificar política RLS de `orders`

Para que los workers puedan ver y actualizar pedidos:

```sql
-- Workers pueden ver pedidos de su tienda
CREATE POLICY IF NOT EXISTS "Workers can view tenant orders"
  ON public.orders FOR SELECT
  USING (
    tenant_id IN (
      SELECT tenant_id FROM workers WHERE profile_id = auth.uid()
    )
  );

-- Workers pueden actualizar estado de pedidos
CREATE POLICY IF NOT EXISTS "Workers can update order status"
  ON public.orders FOR UPDATE
  USING (
    tenant_id IN (
      SELECT tenant_id FROM workers WHERE profile_id = auth.uid()
    )
  );
```

---

## PASO 7 — Verificar política RLS de `products` para workers

```sql
-- Workers pueden gestionar productos de su tienda
CREATE POLICY IF NOT EXISTS "Workers can manage products"
  ON public.products FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM workers WHERE profile_id = auth.uid()
    )
  )
  WITH CHECK (
    tenant_id IN (
      SELECT tenant_id FROM workers WHERE profile_id = auth.uid()
    )
  );
```

---

## PASO 8 — Configurar `.env` para producción

Tu archivo `.env` en la raíz del proyecto Flutter debe tener:

```env
SUPABASE_URL=https://TU_PROJECT_REF.supabase.co
SUPABASE_ANON_KEY=tu_anon_key_aqui
```

> 🔑 Encuentra estas claves en: **Supabase Dashboard → Settings → API**

---

## PASO 9 — Configurar dominio web (para Flutter Web)

Para que el sistema multi-tenant por subdominio funcione (`negocio.quinindews.com`), configura tu proveedor de DNS con un wildcard:

```
*.quinindews.com → IP del servidor Flutter Web
```

Si usas **Firebase Hosting** o **Vercel** para el frontend Flutter Web:
1. Agrega el dominio `*.quinindews.com` como dominio personalizado
2. Configura el wildcard DNS según las instrucciones del proveedor

---

## PASO 10 — Build de producción Flutter Web

```bash
flutter pub get
flutter build web --release
```

El output estará en `build/web/`. Sube esa carpeta a tu hosting.

---

## ✅ Checklist de verificación final

Antes de lanzar, verifica que:

- [ ] Las tablas `profiles`, `tenants`, `workers`, `products`, `orders`, `order_items`, `tenant_clients`, `security_questions` existen en Supabase
- [ ] Las Edge Functions `create-worker` y `delete-worker` están desplegadas
- [ ] El RPC `get_security_questions_by_email` está creado
- [ ] Las políticas RLS de `tenant_clients`, `orders` y `products` incluyen workers
- [ ] El archivo `.env` tiene las claves correctas de producción
- [ ] El storage tiene los buckets: `avatars`, `logos`, `products` (todos públicos)
- [ ] El DNS wildcard está configurado para `*.quinindews.com`

---

## 🔑 Flujo de acceso por tipo de usuario

| Tipo | Cómo accede | URL de acceso |
|------|-------------|---------------|
| **Manager** | Correo registrado (ej: `dueño@gmail.com`) | `quinindews.com/login` |
| **Worker** | Correo `nombre@mitienda.com` + contraseña creada por el manager | `quinindews.com/login` |
| **Cliente** | Correo personal, se registra en la tienda | `mitienda.quinindews.com` |

---

## 📂 Estructura de Edge Functions

```
supabase/
  functions/
    create-worker/
      index.ts    ← Crea trabajador (Admin API, no afecta sesión del manager)
    delete-worker/
      index.ts    ← Elimina trabajador de workers, profiles y auth.users
```
