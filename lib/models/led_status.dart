import 'dart:typed_data';

class LedStatus {
  bool isOn;
  int brightness;
  int color;
  bool isTimeSynced;
  int powerOnHour;
  int powerOnMinute;
  int powerOffHour;
  int powerOffMinute;
  int powerOffDelayMin;

  static const int structureSize =
      19; // Size of the LedStatus structure in bytes

  LedStatus({
    this.isOn = false,
    this.brightness = 0,
    this.color = 0,
    this.isTimeSynced = false,
    this.powerOnHour = 0,
    this.powerOnMinute = 0,
    this.powerOffHour = 0,
    this.powerOffMinute = 0,
    this.powerOffDelayMin = 0,
  });

  factory LedStatus.fromBytes(List<int> bytes) {
    final dataBytes = bytes.sublist(1);
    final buffer = Uint8List.fromList(dataBytes).buffer;
    final reader = ByteData.view(buffer);
    if (reader.lengthInBytes == 0) {
      return LedStatus(
        isOn: false,
        brightness: 0,
        color: 0,
      );
    }
    return LedStatus(
      isOn: reader.getUint32(0, Endian.little) != 0,
      brightness: reader.getUint32(4, Endian.little),
      color: reader.getUint32(8, Endian.little),
      isTimeSynced: reader.getUint8(12) != 0,
      powerOnHour: reader.getUint8(13),
      powerOnMinute: reader.getUint8(14),
      powerOffHour: reader.getUint8(15),
      powerOffMinute: reader.getUint8(16),
      powerOffDelayMin: reader.getUint16(17, Endian.little),
    );
  }

  List<int> toBytes() {
    final buffer = Uint8List(structureSize).buffer;
    final writer = ByteData.view(buffer);

    writer.setUint32(0, isOn ? 1 : 0, Endian.little);
    writer.setUint32(4, brightness, Endian.little);
    writer.setUint32(8, color, Endian.little);
    writer.setUint8(12, isTimeSynced ? 1 : 0);
    writer.setUint8(13, powerOnHour);
    writer.setUint8(14, powerOnMinute);
    writer.setUint8(15, powerOffHour);
    writer.setUint8(16, powerOffMinute);
    writer.setUint16(17, powerOffDelayMin, Endian.little);
    return buffer.asUint8List();
  }
}
