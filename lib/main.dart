import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';

import 'providers/ble_provider.dart';
import 'screens/bluetooth_permission_screen.dart';
import 'screens/splash_screen.dart';
import 'services/ble_service.dart';
import 'utils/preference_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefManager = PreferenceManager();
  await prefManager.init();

  BleService.instance.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BleProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
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
              return const SplashScreen();
            }
            return const BluetoothPermissionScreen();
          },
        ),
      ),
    );
  }
}
