// lib/utils/user_manager.dart
class UserManager {
  static final UserManager _instance = UserManager._internal();
  factory UserManager() => _instance;
  UserManager._internal();

  String username = 'anonymous';
  bool isLoggedIn = false;

  void setUser({required String name, required bool loggedIn}) {
    username = name;
    isLoggedIn = loggedIn;
  }
}