class TokenManager {
  static TokenManager? _instance;
  factory TokenManager() => _instance ??= TokenManager._();

  TokenManager._();

  String? _refreshToken;
  String? _accessToken;

  String? get refreshToken => _refreshToken;
  String? get accessToken => _accessToken;

  void setTokens(String refresh, String access) {
    _refreshToken = refresh;
    _accessToken = access;
  }

  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
  }}