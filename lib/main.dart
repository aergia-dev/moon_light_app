// Copyright 2017, Paul DeMarco.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_switch/flutter_switch.dart';
import "ble.dart";
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      color: Colors.lightBlue,
      home: StreamBuilder<BluetoothAdapterState>(
          stream: FlutterBluePlus.adapterState,
          initialData: BluetoothAdapterState.unknown,
          builder: (c, snapshot) {
            final state = snapshot.data;
            if (state == BluetoothAdapterState.on) {
              return const MainPage();
            }

            return const BluetoothPermission();

            // adaterState: state ?? BluetoothAdapterState.unknown);
          }),
    );
  }
}

Future<void> requestBtPermission() async {
  var status = await Permission.bluetooth.request();
  if (status.isGranted) {
    // 권한이 허용됨
    print('bt permisstion allowed');
  } else if (status.isDenied) {
    // 권한이 거부됨
    print('bt permission not allowed');
  } else if (status.isPermanentlyDenied) {
    // 권한이 영구적으로 거부됨
    openAppSettings(); // 설정 화면으로 이동
  }
}

class BluetoothPermission extends StatelessWidget {
  const BluetoothPermission({super.key});

  @override
  Widget build(BuildContext context) {
    return const ElevatedButton(
        onPressed: requestBtPermission, child: Text("req permission"));
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainScreen createState() => _MainScreen();
}

class _MainScreen extends State<MainPage> {
  bool lightConnected = false;
  bool lightOnOff = false;
  Color currentColor = Colors.white;
  Color backupColor = Colors.white;
  // double _sliderVal = 50;

  @override
  void initState() {
    print("#### initState()");
    Ble.instance.init();
    super.initState();

    //after read current color of lamp.
    Ble.instance.currentColorController.stream.listen((color) {
      // await
      changeColor(color);
      backupColor = color;
    });

    // FlutterBluePlus.connectedDevices.listen((event) {
    //   print("flutter blue state : $event");
    // });

    Ble.instance.stateController.stream.listen((event) {
      if (event == BluetoothConnectionState.connected) {
        setState(() => lightConnected = true);
      } else {
        setState(() => lightConnected = false);
      }
    });

    Ble.instance.lightOnOffController.stream.listen((event) {
      setState(() => lightOnOff = event);
    });

    Ble.instance.ready.stream.listen((event) async {
      if (event == true) {
        await Ble.instance.readLedStatus();
      }
    });
  }

  void changeColor(Color color) {
    setState(() => currentColor = color);
    // print("current color: $color");
    // colorController.add(color);
    Ble.instance.changeLedColor(color);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text("Sleep Light", style: Theme.of(context).textTheme.titleMedium),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    "connect",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  // textAlign: TextAlign.center,
                  // textScaler: TextScaler.linear(0.2)),
                  const SizedBox(height: 10.0),
                  FlutterSwitch(
                    value: lightConnected,
                    width: 50.0,
                    height: 30.0,
                    toggleSize: 20,
                    borderRadius: 30.0,
                    padding: 2.0,
                    onToggle: (tryConnect) async {
                      bool isComplete = false;
                      if (tryConnect) {
                        isComplete = await Ble.instance.connect();
                        // if (!isComplete) {
                        //   showDialog(
                        //     //todo: change it
                        //     context: context,
                        //     builder: (BuildContext context) {
                        //       return AlertDialog(
                        //         title: Text('알림'),
                        //         content: Text('연결에 실패했습니다.'),
                        //         actions: [
                        //           TextButton(
                        //             child: Text('확인'),
                        //             onPressed: () {
                        //               Navigator.of(context).pop();
                        //             },
                        //           ),
                        //         ],
                        //       );
                        //     },
                        //   );
                        // }
                      } else {
                        isComplete = await Ble.instance.disconnect();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    "Toggle Light",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  // textAlign: TextAlign.center,
                  // textScaler: TextScaler.linear(0.1)),
                  const SizedBox(height: 10.0),
                  FlutterSwitch(
                    value: lightOnOff,
                    width: 50.0,
                    height: 30.0,
                    toggleSize: 20,
                    borderRadius: 30.0,
                    padding: 2.0,
                    onToggle: (val) {
                      setState(() => lightOnOff = val);
                      Ble.instance.toggleLed(val);
                    },
                  ),
                ],
              ),
              // StreamBuilder<Color>(
              //   stream: colorController.stream,
              //   initialData: Colors.white,
              //   builder: (c, snapshot) =>
              Row(
                children: <Widget>[
                  Text(
                    "",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  // textAlign: TextAlign.center,
                  // textScaler: TextScaler.linear(0.1)),
                  const SizedBox(width: 30.0),
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            titlePadding: const EdgeInsets.all(0.0),
                            contentPadding: const EdgeInsets.all(0.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25.0),
                            ),
                            content: SingleChildScrollView(
                              child: SlidePicker(
                                pickerColor: currentColor,
                                onColorChanged: changeColor,
                                // paletteType: PaletteType.rgb,
                                enableAlpha: false,
                                displayThumbColor: true,
                                // showLabel: false,
                                showIndicator: true,
                                indicatorBorderRadius:
                                    const BorderRadius.vertical(
                                  top: Radius.circular(25.0),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: currentColor,
                    ),
                    child: const Text('Choose'),
                    // textColor: useWhiteForeground(currentColor)
                    //     ? const Color(0xffffffff)
                    //     : const Color(0xff000000),
                  ),
                  const SizedBox(width: 5.0),
                  ElevatedButton(
                    onPressed: () {
                      Ble.instance.applyColor(currentColor);
                      backupColor = currentColor;
                    },
                    child: const Text("apply"),
                  ),
                  const SizedBox(width: 5.0),
                  ElevatedButton(
                    onPressed: () {
                      currentColor = backupColor;
                      changeColor(currentColor);
                    },
                    child: const Text("revert"),
                  )
                ],
              ),
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //   children: <Widget>[
              //     Text("Control Brightness",
              //         textAlign: TextAlign.center, textScaleFactor: 1.0),
              //     SizedBox(height: 10.0),
              //     Slider(
              //         value:_sliderVal,
              //         min: 0,
              //         max:100,
              //         divisions: 100,
              //         label: _sliderVal.round().toString(),
              //         onChanged: (double val) {
              //           setState(() {
              //             _sliderVal = val;
              //           });
              //           Ble.instance.controllBrightness(val.toInt());
              //         })
              //   ],
              // ),

              // )
            ],
          ),
        ),
      ),
    );
  }
}
