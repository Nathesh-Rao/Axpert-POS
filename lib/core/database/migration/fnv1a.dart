import 'dart:convert';

/// 32-bit FNV-1a over the UTF-8 bytes of [text], as 8 lowercase hex digits.
///
/// Written so every intermediate value stays below 2^53 (web safe). It is a
/// copy-verification checksum, not a security hash.
String fnv1a32Hex(String text) {
  const mask = 0xFFFFFFFF;
  var hash = 0x811C9DC5;
  for (final byte in utf8.encode(text)) {
    hash ^= byte;
    // hash * 0x01000193 mod 2^32, split so no product exceeds 2^53.
    hash = ((hash * 0x193) + ((hash & 0xFF) << 24)) & mask;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}
