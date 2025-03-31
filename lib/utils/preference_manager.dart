import 'package:shared_preferences/shared_preferences.dart';

class PreferenceManager {
  static final PreferenceManager _instance = PreferenceManager._internal();
  late SharedPreferences _prefs;
  bool _initialized = false;

  // 싱글톤 구현
  factory PreferenceManager() {
    return _instance;
  }

  PreferenceManager._internal();

  Future<void> init() async {
    if (!_initialized) {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
    }
  }

  // 기본 장치 이름 - 원래 코드와 호환성 유지를 위해 변수명 유지
  String get deaultDevName {
    return _prefs.getString('default_device_name') ?? 'LEDMoon';
  }

  set deaultDevName(String name) {
    _prefs.setString('default_device_name', name);
  }

  // 기기 UUID 저장 - 이름이 없는 경우를 위해
  String get deviceUUID {
    return _prefs.getString('device_uuid') ?? '';
  }

  set deviceUUID(String uuid) {
    _prefs.setString('device_uuid', uuid);
  }

  // 마지막으로 저장된 색상
  int get lastColor {
    return _prefs.getInt('last_color') ?? 0xFFFFFFFF;
  }

  set lastColor(int color) {
    _prefs.setInt('last_color', color);
  }

  // 마지막으로 저장된 밝기
  double get lastBrightness {
    return _prefs.getDouble('last_brightness') ?? 70.0;
  }

  set lastBrightness(double brightness) {
    _prefs.setDouble('last_brightness', brightness);
  }

  // 마지막 전원 상태
  bool get lastPowerState {
    return _prefs.getBool('last_power') ?? false;
  }

  set lastPowerState(bool state) {
    _prefs.setBool('last_power', state);
  }
}
