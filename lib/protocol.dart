class Protocol {
  static var map = {
    "RESET": [0x01, 0x01],
    "WRITE_STATUS": [0x01, 0x02],
    "READ_STATUS": [0x01, 0x03],
    "TEST_STATUS": [0x01, 0x04],
  };
}
