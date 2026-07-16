/// Thrown when the server rejects a request with 401: the stored session
/// token is no longer valid and the caller should route back to login.
class UnauthorizedException implements Exception {}

/// Thrown when the server rejects a request with 403: the user is
/// authenticated but lacks the required role (e.g. a non-admin hitting an
/// admin-only endpoint).
class ForbiddenException implements Exception {}
