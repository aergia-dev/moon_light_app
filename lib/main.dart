import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_switch/flutter_switch.dart';
import "ble.dart";
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:lottie/lottie.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: TextTheme(
          bodyMedium: TextStyle(
              fontFamily: 'Roboto', fontSize: 16, color: Colors.black),
          bodySmall: TextStyle(
              fontFamily: 'Roboto', fontSize: 14, color: Colors.black54),
          titleMedium: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87),
        ),
      ),
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
          }),
    );
  }
}

Future<void> requestBtPermission() async {
  Map<Permission, PermissionStatus> statuses = await [
    Permission.bluetooth,
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.locationWhenInUse,
  ].request();

  if (statuses[Permission.bluetooth]?.isGranted == true &&
      statuses[Permission.bluetoothScan]?.isGranted == true &&
      statuses[Permission.bluetoothConnect]?.isGranted == true &&
      statuses[Permission.locationWhenInUse]?.isGranted == true) {
  } else {
    if (statuses[Permission.bluetooth]?.isPermanentlyDenied == true ||
        statuses[Permission.bluetoothScan]?.isPermanentlyDenied == true ||
        statuses[Permission.bluetoothConnect]?.isPermanentlyDenied == true ||
        statuses[Permission.locationWhenInUse]?.isPermanentlyDenied == true) {
      openAppSettings();
    }
  }
}

class BluetoothPermission extends StatelessWidget {
  const BluetoothPermission({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/bluetooth_animation.json',
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              ),
              const SizedBox(height: 20),
              const Text(
                "블루투스가 꺼져 있습니다.",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "블루투스를 켜야 연결할 수 있습니다.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () async {
                  await FlutterBluePlus.turnOn();
                },
                icon: const Icon(Icons.bluetooth),
                label: const Text("블루투스 켜기"),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
  bool isConnecting = false;

  @override
  void initState() {
    super.initState();
    Ble.instance.init();

    Ble.instance.currentColorController.stream.listen((color) {
      setState(() {
        backupColor = color;
        currentColor = color;
      });
    });

    Ble.instance.stateController.stream.listen((state) {
      setState(() {
        lightConnected = (state == BluetoothConnectionState.connected);
        if (!lightConnected) {
          lightOnOff = false;
        }
      });
    });

    Ble.instance.lightOnOffController.stream.listen((status) {
      setState(() => lightOnOff = status);
    });

    Ble.instance.ready.stream.listen((ready) async {
      if (ready) {
        await Ble.instance.readLedStatus();
      }
    });
  }

  void changeColor(Color color) {
    setState(() => currentColor = color);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.indigo.shade800, Colors.indigo.shade300],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        lightOnOff ? Icons.lightbulb : Icons.lightbulb_outline,
                        size: 120,
                        color: lightOnOff
                            ? currentColor
                            : currentColor.withOpacity(0.3),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "밝기",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16),
                                ),
                                FlutterSwitch(
                                  value: true,
                                  width: 45.0,
                                  height: 25.0,
                                  toggleSize: 18.0,
                                  borderRadius: 30.0,
                                  padding: 2.0,
                                  activeColor: Colors.blueAccent,
                                  onToggle: (val) {},
                                ),
                              ],
                            ),
                            Slider(
                              value: 0.7,
                              onChanged: (value) {},
                              activeColor: Colors.white,
                              inactiveColor: Colors.white24,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "색상",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16),
                                ),
                                FlutterSwitch(
                                  value: true,
                                  width: 45.0,
                                  height: 25.0,
                                  toggleSize: 18.0,
                                  borderRadius: 30.0,
                                  padding: 2.0,
                                  activeColor: Colors.blueAccent,
                                  onToggle: (val) {},
                                ),
                              ],
                            ),
                            Slider(
                              value: 0.5,
                              onChanged: (value) {},
                              activeColor: Colors.white,
                              inactiveColor: Colors.white24,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: isConnecting
                              ? CircularProgressIndicator(
                                  color: Colors.blueAccent,
                                )
                              : Icon(
                                  Icons.bluetooth,
                                  color: lightConnected
                                      ? const Color.fromARGB(255, 125, 195, 253)
                                      : Colors.white,
                                  size: 28,
                                ),
                          onPressed: () async {
                            if (lightConnected) {
                              await Ble.instance.disconnect();
                            } else {
                              setState(() {
                                isConnecting = true;
                              });
                              await Ble.instance.connect();
                              setState(() {
                                isConnecting = false;
                              });
                            }
                          },
                        ),
                        Text(
                          "Connect",
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            lightOnOff
                                ? Icons.lightbulb
                                : Icons.lightbulb_outline,
                            color: lightOnOff
                                ? const Color.fromARGB(255, 125, 195, 253)
                                : Colors.white,
                            size: 28,
                          ),
                          onPressed: () {
                            setState(() => lightOnOff = !lightOnOff);
                            Ble.instance.toggleLed(lightOnOff);
                          },
                        ),
                        Text(
                          "On/Off",
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.palette,
                            color: Colors.white,
                            size: 28,
                          ),
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
                                    child: Column(
                                      children: [
                                        SlidePicker(
                                          pickerColor: currentColor,
                                          onColorChanged: changeColor,
                                          enableAlpha: false,
                                          displayThumbColor: true,
                                          showIndicator: true,
                                          indicatorBorderRadius:
                                              const BorderRadius.vertical(
                                                  top: Radius.circular(25.0)),
                                        ),
                                        const SizedBox(height: 20),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: <Widget>[
                                            ElevatedButton(
                                              onPressed: () {
                                                Ble.instance
                                                    .applyColor(currentColor);
                                                backupColor = currentColor;
                                                Navigator.of(context).pop();
                                              },
                                              style: ElevatedButton.styleFrom(
                                                foregroundColor: Colors.white,
                                                backgroundColor: Colors.blue,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 30,
                                                        vertical: 15),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                              child: const Text("Apply"),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                setState(() {
                                                  currentColor = backupColor;
                                                });
                                                Navigator.of(context).pop();
                                              },
                                              style: ElevatedButton.styleFrom(
                                                foregroundColor: Colors.white,
                                                backgroundColor: Colors.blue,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 30,
                                                        vertical: 15),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                              child: const Text("revert"),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        Text(
                          "Color",
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.settings,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: () {
                            // 설정 popup?
                          },
                        ),
                        Text(
                          "Settings",
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
