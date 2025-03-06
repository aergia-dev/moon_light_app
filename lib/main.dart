import 'package:esp32_led_app/moon_rendering_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import "ble.dart";
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:lottie/lottie.dart';
import 'preference_manager.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final prefManger = PreferenceManager();
  prefManger.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: const TextTheme(
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
        },
      ),
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
  MainScreen createState() => MainScreen();
}

class MainScreen extends State<MainPage> {
  bool lightConnected = false;
  bool lightOnOff = false;
  Color currentColor = Colors.white;
  Color backupColor = Colors.white;
  bool isConnecting = false;
  String deviceName = "No Device";
  double brightness = 70.0;

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
          deviceName = "No Device";
        }
      });
    });

    Ble.instance.lightOnOffController.stream.listen((status) {
      setState(() => lightOnOff = status);
    });

    Ble.instance.ready.stream.listen((ready) async {
      if (ready) {
        await Ble.instance.readLedStatus();

        // Update device name when connected
        if (Ble.instance.device != null) {
          setState(() {
            deviceName = Ble.instance.device!.platformName;
            if (deviceName.isEmpty) {
              deviceName = Ble.instance.device!.remoteId.toString();
            }
          });
        }
      }
    });

    Ble.instance.connect();
  }

  Color adjustBrightness(Color color, double targetBrightness) {
    int r = color.r as int;
    int g = color.g as int;
    int b = color.b as int;

    double luminance = 0.299 * r + 0.587 * g + 0.114 * b;

    double targetLuminance = targetBrightness * 255 / 100;

    double brightnessRatio = targetLuminance / luminance;

    int newR = (r * brightnessRatio).round();
    int newG = (g * brightnessRatio).round();
    int newB = (b * brightnessRatio).round();

    newR = newR.clamp(0, 255);
    newG = newG.clamp(0, 255);
    newB = newB.clamp(0, 255);

    return Color.fromARGB(255, newR, newG, newB);
  }

  void changeColor(Color color) {
    setState(() => currentColor = color);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/background.gif',
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: SafeArea(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    alignment: Alignment.center,
                    child: Text(
                      deviceName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 400,
                            height: 400,
                            child: Moon3D(),
                          ),
                          const SizedBox(height: 20),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "밝기",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 16),
                                    ),
                                  ],
                                ),
                                Slider(
                                  value: brightness,
                                  min: 0,
                                  max: 100,
                                  onChanged: (value) {
                                    setState(() {
                                      brightness = value;
                                      currentColor = adjustBrightness(
                                          backupColor, brightness);
                                    });
                                    Ble.instance.applyColor(currentColor);
                                  },
                                  activeColor: Colors.white,
                                  inactiveColor: Colors.white,
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
                                  ? const CircularProgressIndicator(
                                      color: Colors.blueAccent,
                                    )
                                  : Icon(
                                      Icons.bluetooth,
                                      color: lightConnected
                                          ? const Color.fromARGB(
                                              255, 125, 195, 253)
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
                                color: lightConnected
                                    ? (lightOnOff
                                        ? const Color.fromARGB(
                                            255, 125, 195, 253)
                                        : Colors.white)
                                    : Colors.white.withValues(alpha: 127),
                                size: 28,
                              ),
                              onPressed: lightConnected
                                  ? () {
                                      setState(() => lightOnOff = !lightOnOff);
                                      Ble.instance.toggleLed(lightOnOff);
                                    }
                                  : null,
                            ),
                            Text(
                              "On/Off",
                              style: TextStyle(
                                color: lightConnected
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 127),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.palette,
                                color: lightConnected
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 127),
                                size: 28,
                              ),
                              onPressed: lightConnected
                                  ? () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            titlePadding:
                                                const EdgeInsets.all(0.0),
                                            contentPadding:
                                                const EdgeInsets.all(0.0),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(25.0),
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
                                                        const BorderRadius
                                                            .vertical(
                                                            top:
                                                                Radius.circular(
                                                                    25.0)),
                                                  ),
                                                  const SizedBox(height: 20),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceEvenly,
                                                    children: <Widget>[
                                                      ElevatedButton(
                                                        onPressed: () {
                                                          Ble.instance
                                                              .applyColor(
                                                                  currentColor);
                                                          backupColor =
                                                              currentColor;
                                                          Navigator.of(context)
                                                              .pop();
                                                        },
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          foregroundColor:
                                                              Colors.white,
                                                          backgroundColor:
                                                              Colors.blueAccent,
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(12),
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        25),
                                                          ),
                                                        ),
                                                        child: const Text('적용'),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    }
                                  : null,
                            ),
                            Text(
                              "색상 변경",
                              style: TextStyle(
                                color: lightConnected
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 127),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.settings,
                                color: Colors.white,
                                size: 28,
                              ),
                              onPressed: () {
                                // 설정 popup?
                              },
                            ),
                            const Text(
                              "Settings",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12),
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
        ],
      ),
    );
  }
}
