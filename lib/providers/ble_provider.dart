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
  String _deviceName = "No Device";
  double _brightness = 70.0;

  bool get lightConnected => _lightConnected;
  bool get lightOnOff => _lightOnOff;
  Color get currentColor => _currentColor;
  Color get backupColor => _backupColor;
  bool get isConnecting => _isConnecting;
  String get deviceName => _deviceName;
  double get brightness => _brightness;

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
    _bleService.connect();
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
        _deviceName = "No Device";
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

  Future<void> connectDevice() async {
    _isConnecting = true;
    notifyListeners();

    await _bleService.connect();

    _isConnecting = false;
    notifyListeners();
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
