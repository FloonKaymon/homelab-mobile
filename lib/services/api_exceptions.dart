/// Thrown when the server rejects a request with 401: the stored session
/// token is no longer valid and the caller should route back to login.
class UnauthorizedException implements Exception {}
