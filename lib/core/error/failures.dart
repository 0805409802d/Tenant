// ─────────────────────────────────────────────────────────────────────────────
// MANEJO DE ERRORES — Fase 3+
// ─────────────────────────────────────────────────────────────────────────────
//
// Este archivo contendrá el modelo de errores tipados del dominio cuando
// el proyecto evolucione a una arquitectura Clean con Result<T, Failure>.
//
// Por ahora, los errores se manejan con el wrapper AuthResult (success/error)
// definido en core/services/auth_service.dart, que es suficiente para el MVP.
//
// TODO Fase 3: Implementar cuando se agreguen repositorios y casos de uso:
//
// sealed class Failure {
//   final String message;
//   const Failure(this.message);
// }
//
// class AuthFailure     extends Failure { const AuthFailure(super.message); }
// class NetworkFailure  extends Failure { const NetworkFailure(super.message); }
// class ServerFailure   extends Failure { const ServerFailure(super.message); }
// class NotFoundFailure extends Failure { const NotFoundFailure(super.message); }
// class PermissionFailure extends Failure { const PermissionFailure(super.message); }
// ─────────────────────────────────────────────────────────────────────────────
