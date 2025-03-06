import 'package:shared_preferences/shared_preferences.dart';

class PreferenceManager {
  static final PreferenceManager _instance = PreferenceManager._();
  factory PreferenceManager() => _instance;
  PreferenceManager._();

  static late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    initDefaultValues();
  }

  final String deaultDevName = "sleep_light";
  final String lastestDevNameKey = "lastestDevName";

  Future<void> saveLastConnectedDeviceName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(lastestDevNameKey, name);
  }

  Future<String?> getLastConnectedDeviceName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(lastestDevNameKey);
  }

  Future<void> initDefaultValues() async {
    final prefs = await SharedPreferences.getInstance();
    final bool keyExists = prefs.containsKey(lastestDevNameKey);

    if (!keyExists) await prefs.setString(lastestDevNameKey, deaultDevName);
  }
}
