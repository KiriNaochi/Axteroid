class UserManager {
  static UserManager? _instance;
  factory UserManager() => _instance ??= UserManager._();

  UserManager._();

  String? _firstName;
  String? _lastName;

  String? get fullName => '$_firstName $_lastName';

  void setUserDetails(String firstName, String lastName) {
    _firstName = firstName;
    _lastName = lastName;
  }
}