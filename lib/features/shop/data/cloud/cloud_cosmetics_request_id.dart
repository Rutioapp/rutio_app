import 'dart:math';

class CloudCosmeticsRequestId {
  CloudCosmeticsRequestId._();

  static final Random _random = Random.secure();

  static String generateV4() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    return '${_hex(bytes.sublist(0, 4))}-'
        '${_hex(bytes.sublist(4, 6))}-'
        '${_hex(bytes.sublist(6, 8))}-'
        '${_hex(bytes.sublist(8, 10))}-'
        '${_hex(bytes.sublist(10, 16))}';
  }

  static String _hex(List<int> bytes) {
    final buffer = StringBuffer();
    for (final byte in bytes) {
      buffer.write(byte.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }
}
