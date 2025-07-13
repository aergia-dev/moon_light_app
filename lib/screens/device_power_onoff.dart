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
  DateTime _selectedPowerOnTime = DateTime.now();
  DateTime _selectedPowerOffTime = DateTime.now();
  DateTime _selectedDelayPowerOffTime = DateTime.now();
  bool _isPowerScheduleOnOff = false;
  bool _isDelayPowerOff = false;

  LedStatus _ledStatus = LedStatus(
    isOn: false,
    brightness: 0,
    color: 0,
    powerOnHour: 0,
    powerOnMinute: 0,
    powerOffHour: 0,
    powerOffMinute: 0,
    powerOffDelayMin: 0,
  );

  final BleService _bleService = BleService.instance;

  @override
  void initState() {
    super.initState();
    _ledStatus = BleService().getLedStatus();

    _selectedPowerOnTime = DateTime(
      now.year,
      now.month,
      now.day,
      _ledStatus.powerOnHour,
      _ledStatus.powerOnMinute,
    );

    _selectedPowerOffTime = DateTime(
      now.year,
      now.month,
      now.day,
      _ledStatus.powerOffHour,
      _ledStatus.powerOffMinute,
    );

    _selectedDelayPowerOffTime = DateTime(
      now.year,
      now.month,
      now.day,
      0,
      _ledStatus.powerOffDelayMin,
    );

    _isPowerScheduleOnOff = _selectedPowerOnTime.hour > 0 ||
        _selectedPowerOnTime.minute > 0 ||
        _selectedPowerOffTime.hour > 0 ||
        _selectedPowerOffTime.minute > 0;

    _isDelayPowerOff = _selectedDelayPowerOffTime.hour > 0 ||
        _selectedDelayPowerOffTime.minute > 0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showTimePickerDialog(
      bool isPowerOn, void Function(DateTime selectedDateTime) updateCb) {
    DateTime currentTime =
        isPowerOn ? _selectedPowerOnTime : _selectedPowerOffTime;
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
                              updateCb(tempSelectedDate);
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
                  value: _isPowerScheduleOnOff,
                  onChanged: (value) {
                    setState(() {
                      _isPowerScheduleOnOff = value;
                    });
                  },
                  activeColor: Colors.white,
                ),
                Icon(Icons.dark_mode, size: 20),
              ],
            ),
            const SizedBox(height: 15),
            if (_isPowerScheduleOnOff) ...[
              // Power On 시간 설정
              _buildPowerOnTimeSetting(),
              _buildPowerOffTimeSetting(),
              const SizedBox(height: 20),
              // power on/off 저장 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _changePowerOnOffTime,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    disabledBackgroundColor: Colors.grey[700],
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
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
                  value: _isDelayPowerOff,
                  onChanged: (value) {
                    setState(() {
                      _isDelayPowerOff = value;
                    });
                  },
                  activeColor: Colors.white,
                ),
                Icon(Icons.dark_mode, size: 20),
              ],
            ),
            if (_isDelayPowerOff) ...[
              _buildDelayPowerOffTimeSetting(),
            ],
          ],
        ),
      ),
    );
  }

  void updatePowerOnCb(DateTime t) {
    print("save power on time: ${t.hour}:${t.minute}");
    _selectedPowerOnTime = t;
  }

  void updatePowerOffCb(DateTime t) {
    print("save power off time: ${t.hour}:${t.minute}");
    _selectedPowerOffTime = t;
  }

  void updateDelayPowerOffCb(DateTime t) {
    print("save power off time: ${t.hour}:${t.minute}");
    _selectedDelayPowerOffTime = t;
  }

  Widget _buildPowerOnTimeSetting() {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _showTimePickerDialog(true, updatePowerOnCb),
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
                      '${_selectedPowerOnTime.hour.toString().padLeft(2, '0')}:${_selectedPowerOnTime.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
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
          onTap: () => _showTimePickerDialog(false, updatePowerOffCb),
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
                      '${_selectedPowerOffTime.hour.toString().padLeft(2, '0')}:${_selectedPowerOffTime.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
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

  Widget _buildDelayPowerOffTimeSetting() {
    return Column(
      children: [
        // Power Off 시간 설정
        GestureDetector(
          onTap: () => _showTimePickerDialog(false, updateDelayPowerOffCb),
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
                      '${_selectedDelayPowerOffTime.hour.toString().padLeft(2, '0')}:${_selectedPowerOffTime.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
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
        const SizedBox(height: 20),
        // power on/off 저장 버튼
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _changeDelayPowerOffTime,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 104, 6, 161),
              disabledBackgroundColor: Colors.grey[700],
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              '전원 꺼짐 예약 저장',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  _changePowerOnOffTime() async {
    setState(() {
      _isChanging = true;
    });

    try {
      print("_changePowerOnOffTime");

      if (_selectedPowerOnTime.hour == _selectedPowerOffTime.hour &&
          _selectedPowerOnTime.minute == _selectedPowerOffTime.minute) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('on/off 시간이 같은 경우는 설정할 수 없습니다')),
        );
        return;
      }

      // Update the ledStatus with the new power on/off times
      // _ledStatus.powerOnHour = _selectedPowerOnTime.hour;
      // _ledStatus.powerOnMinute = _selectedPowerOnTime.minute;
      // _ledStatus.powerOffHour = _selectedPowerOffTime.hour;
      // _ledStatus.powerOffMinute = _selectedPowerOffTime.minute;

      // Send the updated status to the BLE service
      await _bleService.applySchedulePowerOnOffTime(_selectedPowerOnTime,
          _selectedPowerOffTime, _selectedDelayPowerOffTime);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('전원 스케줄이 저장되었습니다.')),
      );
    } catch (e) {
      // Handle any errors that occur during the update
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류 발생: $e')),
      );
    } finally {
      setState(() {
        _isChanging = false;
      });
    }
  }

  _changeDelayPowerOffTime() async {
    setState(() {
      _isChanging = true;
    });

    try {
      print("_changeDelayPowerOffTime");

      // Update the ledStatus with the new power on/off times
      // _ledStatus.powerOffDelayMin = _selectedDelayPowerOffTime.minute;

      // Send the updated status to the BLE service
      await _bleService.applySchedulePowerOnOffTime(_selectedPowerOnTime,
          _selectedPowerOffTime, _selectedDelayPowerOffTime);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('전원 스케줄이 저장되었습니다.')),
      );
    } catch (e) {
      // Handle any errors that occur during the update
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류 발생: $e')),
      );
    } finally {
      setState(() {
        _isChanging = false;
      });
    }
  }
}
