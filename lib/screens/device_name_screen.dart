import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/ble_provider.dart';

class DeviceNameScreen extends StatefulWidget {
  const DeviceNameScreen({super.key});

  @override
  State<DeviceNameScreen> createState() => _DeviceNameScreenState();
}

class _DeviceNameScreenState extends State<DeviceNameScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isChanging = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          '기기 이름 변경',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '새로운 기기 이름을 입력하세요',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              maxLength: 14,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '기기 이름 (최대 14글자)',
                hintStyle: const TextStyle(color: Colors.white54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white54),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white54),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.blueAccent),
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isChanging ? null : _changeDeviceName,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isChanging
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        '이름 변경',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _changeDeviceName() async {
    String newName = _nameController.text.trim();

    if (newName.isEmpty) {
      _showSnackBar('기기 이름을 입력해주세요');
      return;
    }

    setState(() {
      _isChanging = true;
    });

    final bleProvider = Provider.of<BleProvider>(context, listen: false);
    bool success = await bleProvider.changeDeviceName(newName);

    setState(() {
      _isChanging = false;
    });

    if (success) {
      _showSnackBar('기기 이름이 변경되었습니다');
      Navigator.of(context).pop();
    } else {
      _showSnackBar('기기 이름 변경에 실패했습니다');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.grey[800],
      ),
    );
  }
}
