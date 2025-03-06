// ignore_for_file: avoid_print

import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'models/protocol.dart';
import 'dart:typed_data';
import 'preference_manager.dart';

class LedStatus {
  bool isOn;
  int brightness;
  int color;

  LedStatus({
    this.isOn = false,
    this.brightness = 0,
    this.color = 0,
  });

  factory LedStatus.fromBytes(List<int> bytes) {
    final dataBytes = bytes.sublist(1);
    final buffer = Uint8List.fromList(dataBytes).buffer;
    final reader = ByteData.view(buffer);
    if (reader.lengthInBytes == 0) {
      return LedStatus(
        isOn: false,
        brightness: 0,
        color: 0,
      );
    }
    return LedStatus(
      isOn: reader.getUint32(0, Endian.little) != 0,
      brightness: reader.getUint32(4, Endian.little),
      color: reader.getUint32(8, Endian.little),
    );
  }

  List<int> toBytes() {
    final buffer = Uint8List(12).buffer;
    final writer = ByteData.view(buffer);

    writer.setUint32(0, isOn ? 1 : 0, Endian.little);
    writer.setUint32(4, brightness, Endian.little);
    writer.setUint32(8, color, Endian.little);
    return buffer.asUint8List();
  }
}

class Ble {
  static final Ble _instance = Ble();

  static Ble get instance => _instance;
  var _ledStatus = LedStatus(isOn: false, brightness: 0, color: 0);

  // int current_color;
  // Color currentColor;

  StreamController currentColorController = StreamController<Color>();
  StreamController stateController =
      StreamController<BluetoothConnectionState>();

  StreamController lightOnOffController = StreamController<bool>();
  bool lightState = false;

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
          if (r.device.platformName == devName && !deviceFound) {
            deviceFound = true;
            device = r.device;
            print("service name: $r.device.platformName ");
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

      // 오류 처리
    } catch (e) {
      print('Error during scanning: $e');
    }

    return isConnected;
  }

  Future<bool> connectToDevice() async {
    if (device == null) return false;

    try {
      // 연결
      await device!.connect();
      print("bt connect");

      // 상태 변경 모니터링
      device!.connectionState.listen((state) {
        stateController.add(state);

        if (state == BluetoothConnectionState.disconnected) {
          characteristic = null;
        }
      });

      // 서비스 검색
      List<BluetoothService> services = await device!.discoverServices();
      for (BluetoothService service in services) {
        if (service.uuid.toString() == serviceUUID) {
          for (BluetoothCharacteristic c in service.characteristics) {
            if (c.uuid.toString() == characteristicUUID) {
              characteristic = c;
              // await characteristic?.setNotifyValue(true);
              //characteristic?.lastValueStream.listen(_handleNotification);
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

  // 연결 해제 메소드
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

  // void _handleNotification(List<int> value) {
  //   print("_handleNotification: $value");
  // }

  void toggleLed(bool onOff) async {
    print("toogleLed: $onOff");

    LedStatus status = getLedStatus();
    status.isOn = onOff;

    await characteristic?.write(
        (Protocol.map['WRITE_STATUS'] ?? []) + getLedStatus().toBytes());

    // await readLedStatus();
  }

  Future<void> readLedStatus() async {
    try {
      print("read_status after write cmd");
      await characteristic?.write(Protocol.map['READ_STATUS'] ?? []);
    } catch (e) {
      print("write error?: $e");
    }
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

    return;
  }

  Future<void> changeLedColor(Color c) async {
    LedStatus status = getLedStatus();
    status.color = c.toARGB32();
    await characteristic
        ?.write((Protocol.map['TEST_STATUS'] ?? []) + status.toBytes());
  }

  //save current color into flash.
  Future<void> applyColor(Color c) async {
    LedStatus status = getLedStatus();
    status.color = c.toARGB32();
    await characteristic
        ?.write((Protocol.map['WRITE_STATUS'] ?? []) + status.toBytes());
  }

  static int prevBrightness = 0;
  Future<void> applyBrightness(double val) async {
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
  }
}
