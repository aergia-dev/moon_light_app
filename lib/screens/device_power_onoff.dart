import 'package:esp32_led_app/models/led_status.dart';
import 'package:flutter/material.dart';
import 'package:scroll_datetime_picker/scroll_datetime_picker.dart';

import 'package:esp32_led_app/services/ble_service.dart';
import 'package:intl/intl.dart';

class DevicePowerOnOffSchedule extends StatefulWidget {
  @override
  _DevicePowerOnOffSchedule createState() => _DevicePowerOnOffSchedule();
}

class _DevicePowerOnOffSchedule extends State<DevicePowerOnOffSchedule> {
  final TextEditingController _nameController = TextEditingController();
  bool _isChanging = false;
  final controllerOn = DateTimePickerController();
  final controllerOff = DateTimePickerController();
  final now = DateTime.now();
  DateTime selectedPowerOnTime = DateTime.now();
  DateTime selectedPowerOffTime = DateTime.now().add(Duration(hours: 12));
  DateTime selectedDelayPowerOffTime = DateTime.now();
  bool _isPowerScheduleOn = false;
  bool _isReservedPowerOff = false;

  @override
  void initState() {
    super.initState();
    //값을 어떻게 가져오나?
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // 시간 선택 팝업 표시
  void _showTimePickerDialog(
      bool isPowerOn, void Function(DateTime selectedDateTime) saveCb) {
    DateTime currentTime =
        isPowerOn ? selectedPowerOnTime : selectedPowerOffTime;
    DateTimePickerController currentController =
        isPowerOn ? controllerOn : controllerOff;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        DateTime tempSelectedDate = currentTime;
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            height: 400,
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white54),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isPowerOn ? Colors.green : Colors.red,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isPowerOn ? '전원 ON 시간 선택' : '전원 OFF 시간 선택',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                // 시간, 분 라벨
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  child: Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: Text(
                            '시간',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            '분',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 구분선
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  color: Colors.white24,
                ),
                // TimePicker
                Expanded(
                  child: ScrollDateTimePicker(
                    controller: currentController,
                    itemExtent: 54,
                    dateOption: DateTimePickerOption(
                      dateFormat: DateFormat('HH:mm'),
                      minDate: DateTime(now.year, now.month, now.day, 0, 0),
                      maxDate: DateTime(now.year, now.month, now.day, 23, 59),
                      initialDate: tempSelectedDate,
                    ),
                    onChange: (datetime) {
                      tempSelectedDate = datetime;
                    },
                    style: DateTimePickerStyle(
                      activeStyle: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      inactiveStyle: const TextStyle(
                        fontSize: 16,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ),
                // 버튼들
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white54),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            '취소',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              if (isPowerOn) {
                                saveCb(tempSelectedDate);
                              } else {
                                saveCb(tempSelectedDate);
                              }
                            });
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isPowerOn ? Colors.green : Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            '확인',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 기기 이름 변경 함수 추가
  void _changePowerOnOffTime() async {
    if (_nameController.text.isEmpty) {
      return;
    }

    setState(() {
      _isChanging = true;
    });

    // 여기에 실제 기기 이름 변경 로직 구현
    await Future.delayed(Duration(seconds: 2)); // 예시 지연

    setState(() {
      _isChanging = false;
    });

    // 성공 시 이전 화면으로 돌아가기
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          '전원 스케줄 설정',
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Power On/Off 시간 설정 섹션
                const Text(
                  '전원 스케줄 설정',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(Icons.light_mode, size: 20),
                Switch(
                  value: _isPowerScheduleOn,
                  onChanged: (value) {
                    setState(() {
                      _isPowerScheduleOn = value;
                    });
                  },
                  activeColor: Colors.white,
                ),
                Icon(Icons.dark_mode, size: 20),
              ],
            ),
            const SizedBox(height: 15),
            if (_isPowerScheduleOn) ...[
              // Power On 시간 설정
              _buildPowerOnTimeSetting(),
              _buildPowerOffTimeSetting(),
              const SizedBox(height: 20),
              // 저장 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isChanging ? null : _changePowerOnOffTime,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    disabledBackgroundColor: Colors.grey[700],
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isChanging
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        )
                      : const Text(
                          '스케줄 저장',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '전원 꺼짐 예약 설정',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(Icons.light_mode, size: 20),
                Switch(
                  value: _isReservedPowerOff,
                  onChanged: (value) {
                    setState(() {
                      _isReservedPowerOff = value;
                    });
                  },
                  activeColor: Colors.white,
                ),
                Icon(Icons.dark_mode, size: 20),
              ],
            ),
            if (_isReservedPowerOff)
              GestureDetector(
                onTap: () => _showTimePickerDialog(false),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color.fromARGB(255, 235, 48, 34)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(255, 66, 110, 147)
                            .withValues(
                                red: 0.1, green: 0.1, blue: 0.8, alpha: 0.7),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.power_off,
                                color: Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '전원 꺼짐 예약 시간',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${selectedPowerOffTime.hour.toString().padLeft(2, '0')}:${selectedPowerOffTime.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${selectedPowerOffTime.hour * 60 + selectedPowerOffTime.minute} 분 후에 꺼짐',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(
                              red: 0.1, green: 0.1, blue: 0.8, alpha: 0.7),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Icon(
                          Icons.access_time,
                          color: Colors.red,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildPowerOnTimeSetting() {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _showTimePickerDialog(
            true,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green),
              boxShadow: [
                BoxShadow(
                  color: Colors.green
                      .withValues(red: 0.1, green: 0.8, blue: 0.3, alpha: 0.7),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.power_settings_new,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Power ON',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${selectedPowerOnTime.hour.toString().padLeft(2, '0')}:${selectedPowerOnTime.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${selectedPowerOnTime.hour < 12 ? '오전' : '오후'} ${(selectedPowerOnTime.hour == 0 ? 12 : selectedPowerOnTime.hour > 12 ? selectedPowerOnTime.hour - 12 : selectedPowerOnTime.hour)}시 ${selectedPowerOnTime.minute.toString().padLeft(2, '0')}분',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(
                        red: 0.5, green: 0.8, blue: 0.3, alpha: 0.7),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Icons.access_time,
                    color: Colors.green,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildPowerOffTimeSetting() {
    return Column(
      children: [
        // Power Off 시간 설정
        GestureDetector(
          onTap: () => _showTimePickerDialog(false),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red),
              boxShadow: [
                BoxShadow(
                  color: Colors.red
                      .withValues(red: 0.5, green: 0.1, blue: 0.3, alpha: 0.7),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.power_off,
                          color: Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Power OFF',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${selectedPowerOffTime.hour.toString().padLeft(2, '0')}:${selectedPowerOffTime.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${selectedPowerOffTime.hour < 12 ? '오전' : '오후'} ${(selectedPowerOffTime.hour == 0 ? 12 : selectedPowerOffTime.hour > 12 ? selectedPowerOffTime.hour - 12 : selectedPowerOffTime.hour)}시 ${selectedPowerOffTime.minute.toString().padLeft(2, '0')}분',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(
                        red: 0.0, green: 0.0, blue: 0.3, alpha: 0.7),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Icons.access_time,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
