import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'protocol.dart';

import 'dart:typed_data';

class LedStatus {
  bool isOn;
  int brightness;
  int reserved;
  int color;
  LedStatus({
    this.isOn = false,
    this.brightness = 0,
    this.reserved = 0,
    this.color = 0,
  });

  factory LedStatus.fromBytes(List<int> bytes) {
    final buffer = Uint8List.fromList(bytes).buffer;
    final reader = ByteData.view(buffer);
    if (reader.lengthInBytes == 0) {
      return LedStatus(
        isOn: false,
        brightness: 0,
        reserved: 0,
        color: 0,
      );
    }
    return LedStatus(
      isOn: reader.getUint8(0) != 0,
      brightness: reader.getUint8(1),
      reserved: reader.getUint16(2),
      color: reader.getUint32(4),
    );
  }

  List<int> toBytes() {
    final buffer = Uint8List(8).buffer;
    final writer = ByteData.view(buffer);

    writer.setUint8(0, isOn ? 1 : 0);
    writer.setUint8(0, brightness);
    writer.setUint16(0, reserved);
    writer.setUint32(0, color);
    return buffer.asUint8List();
  }
}

class Ble {
  static final Ble _instance = Ble();

  static Ble get instance => _instance;

  // int current_color;
  // Color currentColor;

  StreamController currentColorController = StreamController<Color>();
  StreamController stateController =
      StreamController<BluetoothConnectionState>();

  StreamController lightOnOffController = StreamController<bool>();
  bool lightState = false;

  StreamController ready = StreamController<bool>();
  final String devName = "Sleep Light";
  BluetoothDevice? device;
  BluetoothCharacteristic? characteristic;

  final String serviceUUID = "fb349b5f-8000-0080-0010-0000d4c3b2a1";
  final String characteristicUUID = "fb349b5f-8000-0080-0010-0000d5c3b2a1";

  Future<void> connect() async {
    print("start scan");

    try {
      await FlutterBluePlus.stopScan();
      bool deviceFound = false;
      final subscription = FlutterBluePlus.scanResults.listen((results) async {
        for (ScanResult r in results) {
          if (r.device.platformName == devName && !deviceFound) {
            deviceFound = true;
            device = r.device;
            print("service name: $r.device.platformName ");
            await connectToDevice();
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
  }

  Future<void> connectToDevice() async {
    if (device == null) return;

    try {
      // 연결
      await device!.connect();
      print("bt connect");

      // 상태 변경 모니터링
      device!.connectionState.listen((state) {
        stateController.add(state);
      });

      // 서비스 검색
      List<BluetoothService> services = await device!.discoverServices();
      for (BluetoothService service in services) {
        if (service.uuid.toString() == serviceUUID) {
          for (BluetoothCharacteristic c in service.characteristics) {
            if (c.uuid.toString() == characteristicUUID) {
              characteristic = c;
              ready.add(true);
              break;
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
  }

  // 연결 해제 메소드
  Future<void> disconnect() async {
    if (device != null) {
      try {
        await device!.disconnect();
      } catch (e) {
        print('Error disconnecting: $e');
      }
    }
  }

  void init() async {
    print("init");

    FlutterBluePlus.scanResults.listen((results) async {
      // print("results: $results");
    });
  }

  void toggleLed(bool onOff) async {
    // device
    print("toogleLed: $onOff");

    LedStatus status = LedStatus(
      isOn: onOff,
      brightness: 0,
      reserved: 0,
      color: 0,
    );

    await characteristic
        ?.write((Protocol.map['TEST_STATUS'] ?? []) + status.toBytes());

    await readLedStatus();
  }

  Future<void> changeLedColor(Color c) async {
    //  print("change color: $r, $g, $b");
    await characteristic?.write([
      ...Protocol.map['TEST_STATUS'] ?? [],
      ...[c.red, c.green, c.blue]
    ]);
  }

  Future<void> readLedStatus() async {
    try {
      print("write read_status");
      await characteristic?.write(Protocol.map['READ_STATUS'] ?? []);
    } catch (e) {
      print("write error?: $e");
    }
    List<int>? read = await characteristic?.read();
    if (read != null) {
      LedStatus status = LedStatus.fromBytes(read);
      Color color = Color(status.color);

      print("status: $status.color");
      currentColorController.add(color);
      lightOnOffController.add(status.isOn);
      lightState = status.isOn;
    }

    return;
  }

  //save current color into flash.
  Future<void> applyColor(Color c) async {
    await characteristic?.write([
      ...Protocol.map['TEST_STATUS'] ?? [],
      ...[c.red, c.green, c.blue]
    ]);
  }

  Future<void> controllBrightness(int val) async {
    await characteristic?.write([...Protocol.map['TEST_STATUS'] ?? [], val]);
  }
}
