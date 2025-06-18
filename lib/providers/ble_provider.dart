import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/led_status.dart';
import '../models/protocol.dart';
import '../services/ble_service.dart';
import '../utils/preference_manager.dart';

class BleProvider extends ChangeNotifier {
  final BleService _bleService = BleService.instance;

  bool _lightConnected = false;
  bool _lightOnOff = false;
  Color _currentColor = Colors.white;
  Color _backupColor = Colors.white;
  bool _isConnecting = false;
  String _deviceName = "연결된 기기 없음";
  double _brightness = 70.0;
  String _connectionError = '';

  bool get lightConnected => _lightConnected;
  bool get lightOnOff => _lightOnOff;
  Color get currentColor => _currentColor;
  Color get backupColor => _backupColor;
  bool get isConnecting => _isConnecting;
  String get deviceName => _deviceName;
  double get brightness => _brightness;
  String get connectionError => _connectionError;

  // 연결 상태 스트림 getter 추가
  Stream<BluetoothConnectionState> get connectionStateStream =>
      _bleService.stateController.stream;

  set currentColor(Color color) {
    _currentColor = color;
    notifyListeners();
  }

  set brightness(double value) {
    _brightness = value;
    _bleService.applyBrightness(value);
    notifyListeners();
  }

  BleProvider() {
    _bleService.init();
    _initListeners();
    // 생성자에서 자동 연결 제거 (SplashScreen에서 호출하도록 변경)
  }

  void _initListeners() {
    _bleService.currentColorController.stream.listen((color) {
      _backupColor = color;
      _currentColor = color;
      notifyListeners();
    });

    _bleService.stateController.stream.listen((state) {
      _lightConnected = (state == BluetoothConnectionState.connected);

      // 연결 상태 변경시 로딩 상태도 업데이트
      if (state == BluetoothConnectionState.connected) {
        _isConnecting = false; // 연결 성공시 로딩 중단
      } else if (state == BluetoothConnectionState.disconnected) {
        _isConnecting = false; // 연결 해제시도 로딩 중단
        _lightOnOff = false;
        _deviceName = "연결된 기기 없음";
      }
      notifyListeners();
    });

    _bleService.lightOnOffController.stream.listen((status) {
      _lightOnOff = status;
      notifyListeners();
    });

    _bleService.ready.stream.listen((ready) async {
      if (ready) {
        await _bleService.readLedStatus();

        if (_bleService.device != null) {
          _deviceName = _bleService.device!.platformName;
          if (_deviceName.isEmpty) {
            _deviceName = _bleService.device!.remoteId.toString();
          }
          notifyListeners();
        }
      }
    });
  }

  Future<bool> connectDevice() async {
    _isConnecting = true;
    _connectionError = '';
    notifyListeners();

    try {
      final connected = await _bleService.connect();

      // 연결 결과에 관계없이 로딩 상태 해제
      _isConnecting = false;

      if (!connected) {
        _connectionError = '기기 연결 실패';
      }

      notifyListeners();
      return connected;
    } catch (e) {
      _isConnecting = false;
      _connectionError = '연결 오류: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> disconnectDevice() async {
    _isConnecting = true; // 연결 해제 중 표시
    notifyListeners();

    await _bleService.disconnect();

    // disconnect는 stateController를 통해 자동으로 _isConnecting이 false가 됨
  }

  void toggleLight() {
    _lightOnOff = !_lightOnOff;
    _bleService.toggleLed(_lightOnOff);
    notifyListeners();
  }

  Future<void> applyColor(Color color) async {
    await _bleService.applyColor(color);
    _backupColor = color;
    notifyListeners();
  }

  Future<bool> changeDeviceName(String newName) async {
    if (!_lightConnected) {
      _connectionError = '기기가 연결되지 않았습니다';
      notifyListeners();
      return false;
    }

    try {
      final success = await _bleService.changeDeviceName(newName);

      if (success) {
        _deviceName = newName;

        PreferenceManager().deaultDevName = newName;

        notifyListeners();
      } else {
        _connectionError = '기기 이름 변경 실패';
        notifyListeners();
      }

      return success;
    } catch (e) {
      _connectionError = '기기 이름 변경 오류: $e';
      notifyListeners();
      return false;
    }
  }
}
