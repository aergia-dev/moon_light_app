import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';

import '../providers/ble_provider.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _connectionFailed = false;
  late Timer _connectionTimer;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;

  @override
  void initState() {
    super.initState();

    // UI가 구축될 수 있도록 짧은 지연 후 연결 시도 시작
    Future.delayed(const Duration(milliseconds: 100), () {
      _attemptConnection();
    });

    // 연결 시도 타임아웃을 더 길게 설정 (15초)
    _connectionTimer = Timer(const Duration(seconds: 15), () {
      if (mounted) {
        setState(() {
          _connectionFailed = true;
        });

        // 실패 메시지를 잠시 보여준 후 메인 화면으로 이동
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _navigateToMainScreen();
          }
        });
      }
    });
  }

  void _attemptConnection() async {
    final bleProvider = Provider.of<BleProvider>(context, listen: false);

    // 연결 상태 변화를 실시간으로 감지
    _connectionSubscription = bleProvider.connectionStateStream.listen((state) {
      if (state == BluetoothConnectionState.connected) {
        // 연결 성공!
        if (_connectionTimer.isActive && mounted) {
          _connectionTimer.cancel();
          _navigateToMainScreen();
        }
      }
    });

    try {
      // 연결 시도 (결과를 기다리지 않고 상태 변화만 감지)
      bleProvider.connectDevice();
    } catch (e) {
      if (mounted) {
        setState(() {
          _connectionFailed = true;
        });

        // 실패 메시지를 잠시 보여준 후 메인 화면으로 이동
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _navigateToMainScreen();
          }
        });
      }
    }
  }

  void _navigateToMainScreen() {
    _connectionSubscription?.cancel();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainScreen()),
    );
  }

  @override
  void dispose() {
    _connectionTimer.cancel();
    _connectionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/splash.png',
              width: 200,
              height: 200,
            ),
            const SizedBox(height: 30),
            if (_connectionFailed)
              const Text(
                '기기 연결 실패',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              )
            else
              Column(
                children: [
                  const CircularProgressIndicator(
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '기기 연결 중...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
