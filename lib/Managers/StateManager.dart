class StateManager {
  String? selectedOrganizationId;

  static final StateManager _instance = StateManager._internal();

  factory StateManager() {
    return _instance;
  }

  StateManager._internal();
}