import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../providers/ble_provider.dart';
import '../widgets/moon_rendering_widget.dart';
import 'settings_screen.dart'; // 추가된 import

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _showConnectionError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bleProvider = Provider.of<BleProvider>(context, listen: false);
      if (!bleProvider.lightConnected &&
          bleProvider.connectionError.isNotEmpty) {
        setState(() {
          _showConnectionError = true;
        });

        // 3초 후 자동으로 오류 메시지 숨기기
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _showConnectionError = false;
            });
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BleProvider>(
      builder: (context, bleProvider, child) {
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
                          bleProvider.deviceName,
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "밝기",
                                          style: TextStyle(
                                              color: bleProvider.lightConnected
                                                  ? Colors.white
                                                  : Colors.white.withAlpha(127),
                                              fontSize: 16),
                                        ),
                                      ],
                                    ),
                                    SliderTheme(
                                      data: SliderThemeData(
                                        thumbColor: bleProvider.lightConnected
                                            ? Colors.white
                                            : Colors.grey.shade400,
                                        activeTrackColor:
                                            bleProvider.lightConnected
                                                ? Colors.white
                                                : Colors.grey.shade500,
                                        inactiveTrackColor:
                                            bleProvider.lightConnected
                                                ? Colors.white.withAlpha(127)
                                                : Colors.grey.shade700,
                                        overlayColor: bleProvider.lightConnected
                                            ? Colors.white.withAlpha(50)
                                            : Colors.transparent,
                                      ),
                                      child: Slider(
                                        value: bleProvider.brightness,
                                        min: 0,
                                        max: 100,
                                        onChanged: bleProvider.lightConnected
                                            ? (value) {
                                                bleProvider.brightness = value;
                                              }
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _buildBottomControls(context, bleProvider),
                    ],
                  ),
                ),
              ),
              // 연결 오류 메시지 표시
              if (_showConnectionError)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 60,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade700,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '기기 연결에 실패했습니다',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomControls(BuildContext context, BleProvider bleProvider) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: bleProvider.isConnecting
                    ? const CircularProgressIndicator(
                        color: Colors.blueAccent,
                      )
                    : Icon(
                        Icons.bluetooth,
                        color: bleProvider.lightConnected
                            ? const Color.fromARGB(255, 125, 195, 253)
                            : Colors.white,
                        size: 28,
                      ),
                onPressed: () async {
                  if (bleProvider.lightConnected) {
                    await bleProvider.disconnectDevice();
                  } else {
                    await bleProvider.connectDevice();
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
                  bleProvider.lightOnOff
                      ? Icons.lightbulb
                      : Icons.lightbulb_outline,
                  color: bleProvider.lightConnected
                      ? (bleProvider.lightOnOff
                          ? const Color.fromARGB(255, 125, 195, 253)
                          : Colors.white)
                      : Colors.white.withAlpha(127),
                  size: 28,
                ),
                onPressed: bleProvider.lightConnected
                    ? () {
                        bleProvider.toggleLight();
                      }
                    : null,
              ),
              Text(
                "On/Off",
                style: TextStyle(
                  color: bleProvider.lightConnected
                      ? Colors.white
                      : Colors.white.withAlpha(127),
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
                  color: bleProvider.lightConnected
                      ? Colors.white
                      : Colors.white.withAlpha(127),
                  size: 28,
                ),
                onPressed: bleProvider.lightConnected
                    ? () {
                        _showColorPicker(context, bleProvider);
                      }
                    : null,
              ),
              Text(
                "색상 변경",
                style: TextStyle(
                  color: bleProvider.lightConnected
                      ? Colors.white
                      : Colors.white.withAlpha(127),
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
                  // 설정 화면으로 이동
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
              const Text(
                "Settings",
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showColorPicker(BuildContext context, BleProvider bleProvider) {
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
                  pickerColor: bleProvider.currentColor,
                  onColorChanged: (color) {
                    bleProvider.currentColor = color;
                  },
                  enableAlpha: false,
                  displayThumbColor: true,
                  showIndicator: true,
                  indicatorBorderRadius: const BorderRadius.vertical(
                    top: Radius.circular(25.0),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    ElevatedButton(
                      onPressed: () {
                        bleProvider.applyColor(bleProvider.currentColor);
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.all(12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
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
}
