import 'dart:typed_data';

class LedStatus {
  bool isOn;
  int brightness;
  int color;
  int powerOnHour;
  int powerOnMinute;
  int powerOffHour;
  int powerOffMinute;
  int powerOffDelayMin;

  LedStatus({
    this.isOn = false,
    this.brightness = 0,
    this.color = 0,
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
      powerOnHour: reader.getUint32(9, Endian.little),
      powerOnMinute: reader.getUint32(10, Endian.little),
      powerOffHour: reader.getUint32(11, Endian.little),
      powerOffMinute: reader.getUint32(12, Endian.little),
      powerOffDelayMin: reader.getUint32(13, Endian.little),
    );
  }

  List<int> toBytes() {
    final buffer = Uint8List(12).buffer;
    final writer = ByteData.view(buffer);

    writer.setUint32(0, isOn ? 1 : 0, Endian.little);
    writer.setUint32(4, brightness, Endian.little);
    writer.setUint32(8, color, Endian.little);
    writer.setUint32(9, powerOnHour, Endian.little);
    writer.setUint32(10, powerOnMinute, Endian.little);
    writer.setUint32(11, powerOffHour, Endian.little);
    writer.setUint32(12, powerOffMinute, Endian.little);
    writer.setUint32(13, powerOffDelayMin, Endian.little);
    return buffer.asUint8List();
  }
}
