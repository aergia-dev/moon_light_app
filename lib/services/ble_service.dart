// ignore_for_file: avoid_print

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/led_status.dart';
import '../models/protocol.dart';
import '../utils/preference_manager.dart';

class BleService {
  static final BleService _instance = BleService._internal();
  static BleService get instance => _instance;

  factory BleService() {
    return _instance;
  }

  BleService._internal();

  var _ledStatus = LedStatus(isOn: false, brightness: 0, color: 0);
  bool lightState = false;

  StreamController currentColorController = StreamController<Color>();
  StreamController stateController =
      StreamController<BluetoothConnectionState>();
  StreamController lightOnOffController = StreamController<bool>();
  StreamController ready = StreamController<bool>();

  BluetoothDevice? device;
  BluetoothCharacteristic? characteristic;

  final String serviceUUID = "fb349b5f-8000-0080-0010-0000d4c3b2a1";
  final String characteristicUUID = "fb349b5f-8000-0080-0010-0000d5c3b2a1";

  void updateLedStatus(LedStatus src) {
    _ledStatus = src;
  }

  LedStatus getLedStatus() {
    return _ledStatus;
  }

  Future<bool> connect() async {
    print("start scan");
    bool isConnected = false;
    final devName = PreferenceManager().deaultDevName;

    try {
      await FlutterBluePlus.stopScan();
      bool deviceFound = false;

      final subscription = FlutterBluePlus.scanResults.listen((results) async {
        for (ScanResult r in results) {
          print("Found device: ${r.device.platformName}");
          if (r.device.platformName == devName && !deviceFound) {
            deviceFound = true;
            device = r.device;
            print("service name: ${r.device.platformName}");
            isConnected = await connectToDevice();
            break;
          }
        }
      });

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
      await Future.delayed(const Duration(seconds: 4));
      if (!deviceFound) {
        print("device not found");
        subscription.cancel();
      }
    } catch (e) {
      print('Error during scanning: $e');
    }

    return isConnected;
  }

  Future<bool> connectToDevice() async {
    if (device == null) return false;

    try {
      await device!.connect();
      print("bt connect");

      device!.connectionState.listen((state) {
        stateController.add(state);

        if (state == BluetoothConnectionState.disconnected) {
          characteristic = null;
        }
      });

      List<BluetoothService> services = await device!.discoverServices();
      for (BluetoothService service in services) {
        if (service.uuid.toString() == serviceUUID) {
          for (BluetoothCharacteristic c in service.characteristics) {
            if (c.uuid.toString() == characteristicUUID) {
              characteristic = c;
              ready.add(true);
              return true;
            } else {
              print("couldn't find a characteristic - check service uuid");
            }
          }
        } else {
          print("couldn't find a service - check service uuid");
        }
      }
    } catch (e) {
      print('Error connecting to device: $e');
    }

    return false;
  }

  Future<bool> disconnect() async {
    if (device != null) {
      try {
        await device!.disconnect();
      } catch (e) {
        print('Error disconnecting: $e');
        return false;
      }
      return true;
    } else {
      print("already disconnected");
      return true;
    }
  }

  void init() async {
    print("init");

    FlutterBluePlus.scanResults.listen((results) async {
      // print("results: $results");
    });
  }

  void toggleLed(bool onOff) async {
    print("toogleLed: $onOff");

    LedStatus status = getLedStatus();
    status.isOn = onOff;

    try {
      await characteristic?.write(
          (Protocol.map['WRITE_STATUS'] ?? []) + getLedStatus().toBytes());
    } catch (e) {
      print("Error toggling LED: $e");
    }
  }

  Future<void> readLedStatus() async {
    try {
      print("read_status after write cmd");
      await characteristic?.write(Protocol.map['READ_STATUS'] ?? []);
    } catch (e) {
      print("write error?: $e");
    }

    try {
      List<int>? read = await characteristic?.read();
      if (read != null) {
        LedStatus status = LedStatus.fromBytes(read);
        Color color = Color(status.color);

        print("status - color : ${status.color}");
        print("status - isOn : ${status.isOn}");

        currentColorController.add(color);
        lightOnOffController.add(status.isOn);
        lightState = status.isOn;
        updateLedStatus(status);
      }
    } catch (e) {
      print("Error reading LED status: $e");
    }

    return;
  }

  Future<void> changeLedColor(Color c) async {
    try {
      LedStatus status = getLedStatus();
      status.color = c.toARGB32();
      await characteristic
          ?.write((Protocol.map['TEST_STATUS'] ?? []) + status.toBytes());
    } catch (e) {
      print("Error changing LED color: $e");
    }
  }

  Future<void> applyColor(Color c) async {
    try {
      LedStatus status = getLedStatus();
      status.color = c.toARGB32();
      await characteristic
          ?.write((Protocol.map['WRITE_STATUS'] ?? []) + status.toBytes());
    } catch (e) {
      print("Error applying color: $e");
    }
  }

  static int prevBrightness = 0;
  Future<void> applyBrightness(double val) async {
    try {
      int intVal = val.round();
      final int margin = 5;

      if (((prevBrightness - intVal).abs() < margin &&
              intVal >= 10 &&
              intVal <= 90) ||
          prevBrightness == intVal) {
        return;
      }

      prevBrightness = intVal;
      LedStatus status = getLedStatus();
      status.brightness = intVal;

      await characteristic?.write(
          (Protocol.map['WRITE_STATUS'] ?? []) + status.toBytes(),
          withoutResponse: true);
    } catch (e) {
      print("Error applying brightness: $e");
    }
  }

  void dispose() {
    currentColorController.close();
    stateController.close();
    lightOnOffController.close();
    ready.close();
  }
}
