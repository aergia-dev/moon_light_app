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

  var _ledStatus = LedStatus(
      isOn: false,
      brightness: 0,
      color: 0,
      powerOnHour: 0,
      powerOnMinute: 0,
      powerOffHour: 0,
      powerOffMinute: 0,
      powerOffDelayMin: 0);

  bool lightState = false;

  StreamController<Color> currentColorController =
      StreamController<Color>.broadcast();
  StreamController<BluetoothConnectionState> stateController =
      StreamController<BluetoothConnectionState>.broadcast();
  StreamController<bool> lightOnOffController =
      StreamController<bool>.broadcast();
  StreamController<bool> ready = StreamController<bool>.broadcast();

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
    print("스캔 시작");
    bool isConnected = false;
    final devName = PreferenceManager().deaultDevName;

    try {
      // 이전 스캔 중지
      await FlutterBluePlus.stopScan();

      // 잠시 대기
      await Future.delayed(const Duration(milliseconds: 500));

      bool deviceFound = false;
      List<ScanResult> allResults = [];

      // 스캔 결과 구독
      final subscription = FlutterBluePlus.scanResults.listen((results) async {
        print("스캔된 기기 수: ${results.length}");
        allResults = results;

        for (ScanResult r in results) {
          String deviceName = r.device.platformName.isNotEmpty
              ? r.device.platformName
              : "Unknown";

          print(
              "발견된 기기: $deviceName, ID: ${r.device.remoteId}, RSSI: ${r.rssi}");

          // 기기 이름이 일치하는지 확인
          if ((r.device.platformName == devName) && !deviceFound) {
            deviceFound = true;
            device = r.device;
            print("연결할 기기 찾음: ${r.device.platformName}");

            // 스캔 중지
            await FlutterBluePlus.stopScan();

            // 기기에 연결 시도
            isConnected = await connectToDevice();
            break;
          }
        }
      });

      // 더 강력한 스캔 옵션으로 시작
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        androidUsesFineLocation: true,
      );

      // 스캔 완료를 기다림
      await Future.delayed(const Duration(seconds: 10));

      if (!deviceFound) {
        print("=== 스캔 완료 후 결과 ===");
        print("총 발견된 기기 수: ${allResults.length}");
        for (ScanResult r in allResults) {
          String deviceName = r.device.platformName.isNotEmpty
              ? r.device.platformName
              : "Unknown";
          print("기기: $deviceName (${r.device.remoteId})");
        }
        print("찾는 기기 이름: '$devName'");
        print("기기를 찾을 수 없음");
        subscription.cancel();
      }
    } catch (e) {
      print('스캔 중 오류 발생: $e');
    }

    return isConnected;
  }

  Future<bool> connectToDevice() async {
    if (device == null) return false;

    try {
      print("기기에 연결 시도 중...");
      await device!.connect(timeout: const Duration(seconds: 8));
      print("블루투스 연결 성공");

      // 연결 상태 모니터링
      device!.connectionState.listen((state) {
        print("연결 상태 변경: $state");
        stateController.add(state);

        if (state == BluetoothConnectionState.disconnected) {
          characteristic = null;
        }
      });

      // 서비스 및 특성 탐색
      print("서비스 탐색 중...");
      List<BluetoothService> services = await device!.discoverServices();
      print("발견된 서비스 수: ${services.length}");

      for (BluetoothService service in services) {
        print("서비스 UUID: ${service.uuid}");

        if (service.uuid.toString() == serviceUUID) {
          for (BluetoothCharacteristic c in service.characteristics) {
            print("특성 UUID: ${c.uuid}");

            if (c.uuid.toString() == characteristicUUID) {
              characteristic = c;
              ready.add(true);
              return true;
            }
          }
          print("일치하는 특성(characteristic)을 찾을 수 없음 - serviceUUID를 확인하세요");
        }
      }
      print("일치하는 서비스를 찾을 수 없음 - serviceUUID를 확인하세요");
    } catch (e) {
      print('기기 연결 중 오류 발생: $e');
    }

    return false;
  }

  Future<bool> disconnect() async {
    if (device != null) {
      try {
        await device!.disconnect();
      } catch (e) {
        print('연결 해제 중 오류 발생: $e');
        return false;
      }
      return true;
    } else {
      print("이미 연결 해제됨");
      return true;
    }
  }

  void init() async {
    print("초기화");

    FlutterBluePlus.scanResults.listen((results) async {
      // 스캔 결과 로깅이 많으므로 주석 처리함
      // print("results: $results");
    });
  }

  void toggleLed(bool onOff) async {
    print("토글LED: $onOff");

    LedStatus status = getLedStatus();
    status.isOn = onOff;

    try {
      await characteristic?.write(
          (Protocol.map['WRITE_STATUS'] ?? []) + getLedStatus().toBytes());
    } catch (e) {
      print("LED 토글 중 오류: $e");
    }
  }

  Future<void> syncTime() async {
    try {
      print("시간 동기화 시작");
      DateTime now = DateTime.now();
      int timestamp = (now.millisecondsSinceEpoch / 1000).round();
      await characteristic?.write(
          (Protocol.map['SYNC_TIME'] ?? []) + [timestamp],
          withoutResponse: false);

      print("시간 동기화 완료");
    } catch (e) {
      print("시간 동기화 중 오류: $e");
    }
  }

  Future<void> readLedStatus() async {
    try {
      print("쓰기 후 LED 상태 읽기");
      await characteristic?.write(Protocol.map['READ_STATUS'] ?? []);
    } catch (e) {
      print("쓰기 오류?: $e");
    }

    try {
      List<int>? read = await characteristic?.read();
      if (read != null) {
        LedStatus status = LedStatus.fromBytes(read);
        Color color = Color(status.color);

        print("상태 - 색상: ${status.color}");
        print("상태 - 켜짐: ${status.isOn}");

        currentColorController.add(color);
        lightOnOffController.add(status.isOn);
        lightState = status.isOn;
        updateLedStatus(status);
      }
    } catch (e) {
      print("LED 상태 읽기 중 오류: $e");
    }

    return;
  }

  Future<void> changeLedColor(Color c) async {
    try {
      LedStatus status = getLedStatus();
      status.color = c.value;
      await characteristic
          ?.write((Protocol.map['TEST_STATUS'] ?? []) + status.toBytes());
    } catch (e) {
      print("LED 색상 변경 중 오류: $e");
    }
  }

  Future<void> applyColor(Color c) async {
    try {
      LedStatus status = getLedStatus();
      status.color = c.value;
      await characteristic
          ?.write((Protocol.map['WRITE_STATUS'] ?? []) + status.toBytes());
    } catch (e) {
      print("색상 적용 중 오류: $e");
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
      print("밝기 적용 중 오류: $e");
    }
  }

  Future<bool> changeDeviceName(String newName) async {
    if (characteristic == null) {
      print("기기가 연결되지 않음");
      return false;
    }
    if (newName.length > 14) {
      print("기기 이름이 너무 깁니다 (최대 14글자)");
      return false;
    }

    try {
      List<int> nameData = _createDeviceNameData(newName);

      List<int> command = (Protocol.map['WRITE_DEV_NAME'] ?? []) + nameData;

      print("기기 이름 변경 요청: '$newName'");

      await characteristic!.write(command);

      print("기기 이름 변경 완료");
      return true;
    } catch (e) {
      print("기기 이름 변경 중 오류: $e");
      return false;
    }
  }

  List<int> _createDeviceNameData(String name) {
    List<int> nameBytes = name.codeUnits;
    List<int> data = List.filled(15, 0);

    int maxLength = nameBytes.length > 14 ? 14 : nameBytes.length;
    for (int i = 0; i < maxLength; i++) {
      data[i] = nameBytes[i];
    }

    return data;
  }

  Future<void> applySchedulePowerOnOffTime(
      DateTime powerOnTime, DateTime powerOffTime) async {
    try {
      LedStatus status = getLedStatus();
      status.powerOnHour = powerOnTime.hour;
      status.powerOnMinute = powerOnTime.minute;
      status.powerOffHour = powerOffTime.hour;
      status.powerOffMinute = powerOffTime.minute;

      await characteristic?.write(
          (Protocol.map['WRITE_STATUS'] ?? []) + status.toBytes(),
          withoutResponse: true);
    } catch (e) {
      print("밝기 적용 중 오류: $e");
    }
  }

  Future<void> applyDelayPowerOffTime(DateTime DelaypowerOffTime) async {
    try {
      LedStatus status = getLedStatus();
      status.powerOffDelayMin =
          DelaypowerOffTime.hour * 60 + DelaypowerOffTime.minute;

      await characteristic?.write(
          (Protocol.map['WRITE_STATUS'] ?? []) + status.toBytes(),
          withoutResponse: true);
    } catch (e) {
      print("밝기 적용 중 오류: $e");
    }
  }

  void dispose() {
    currentColorController.close();
    stateController.close();
    lightOnOffController.close();
    ready.close();
  }
}
