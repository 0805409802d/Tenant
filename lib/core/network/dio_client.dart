// ─────────────────────────────────────────────────────────────────────────────
// CLIENTE DE RED — No requerido para el MVP
// ─────────────────────────────────────────────────────────────────────────────
//
// El MVP usa supabase_flutter directamente para todas las operaciones de datos.
// El SDK de Supabase maneja autenticación, base de datos, storage y realtime
// sin necesidad de un cliente HTTP adicional.
//
// Este archivo existe como placeholder de arquitectura para cuando el proyecto
// requiera llamar a APIs externas propias (ej: microservicio de QR, pasarela
// de pagos, generador de PDFs) o si se migra a un backend propio.
//
// TODO Fase futura: Implementar si se necesita:
//   - Dio con interceptors para JWT + tenant header
//   - Manejo de rate limiting y reintentos
//   - Logging de requests en desarrollo
//
// Referencia: https://pub.dev/packages/dio
// ─────────────────────────────────────────────────────────────────────────────
