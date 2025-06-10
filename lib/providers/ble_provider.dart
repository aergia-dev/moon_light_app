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
      if (!_lightConnected) {
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
    await _bleService.disconnect();
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
}
