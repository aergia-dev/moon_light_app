import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';

import '../providers/ble_provider.dart';
import 'bluetooth_permission_screen.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _connectionFailed = false;
  late Timer _connectionTimer;

  @override
  void initState() {
    super.initState();

    // UI가 구축될 수 있도록 짧은 지연 후 연결 시도 시작
    Future.delayed(const Duration(milliseconds: 100), () {
      _attemptConnection();
    });

    // 연결 시도 타임아웃 설정
    _connectionTimer = Timer(const Duration(seconds: 8), () {
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

    try {
      final connected = await bleProvider.connectDevice();

      // 타이머가 아직 활성화되어 있고 위젯이 여전히 마운트된 경우
      if (_connectionTimer.isActive && mounted) {
        _connectionTimer.cancel();

        if (connected) {
          _navigateToMainScreen();
        } else {
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
    } catch (e) {
      print('연결 시도 중 오류 발생: $e');
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
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainScreen()),
    );
  }

  @override
  void dispose() {
    _connectionTimer.cancel();
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
              const CircularProgressIndicator(
                color: Colors.white,
              ),
          ],
        ),
      ),
    );
  }
}
