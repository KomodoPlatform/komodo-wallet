import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

Uint8List createZipOfSingleFile({
  required String fileName,
  required String fileContent,
  String extension = 'txt',
}) {
  final fileNameWithExtension = '$fileName.$extension';

  final originalBytes = utf8.encode(fileContent);
  // use `raw: true` to exclude zlip header and trailer data that causes
  // zip decompression to fail
  final compressedBytes =
      Uint8List.fromList(ZLibCodec(raw: true).encode(originalBytes));
  final crc32 = _crc32(originalBytes);

  final ByteData localFileHeader = _createZipHeader(
    fileNameWithExtension,
    crc32,
    originalBytes,
    compressedBytes.length,
  );

  final ByteData centralDirectoryHeader = _createZipDirectoryHeader(
    fileNameWithExtension,
    crc32,
    originalBytes,
    compressedBytes.length,
  );

  final ByteData endOfCentralDirectory = _createEndOfCentralDirectory(
    centralDirectoryHeader,
    localFileHeader,
    compressedBytes,
  );

  final zipData = BytesBuilder()
    ..add(localFileHeader.buffer.asUint8List())
    ..add(compressedBytes)
    ..add(centralDirectoryHeader.buffer.asUint8List())
    ..add(endOfCentralDirectory.buffer.asUint8List());
  return zipData.takeBytes();
}

ByteData _createEndOfCentralDirectory(
  ByteData centralDirectoryHeader,
  ByteData localFileHeader,
  Uint8List bytes,
) {
  final endOfCentralDirectory = ByteData(22)
    // End of central directory signature
    ..setUint32(0, 0x06054b50, Endian.little)
    // Number of this disk
    ..setUint16(4, 0, Endian.little)
    // Disk with the start of the central directory
    ..setUint16(6, 0, Endian.little)
    // Total number of entries in the central directory on this disk
    ..setUint16(8, 1, Endian.little)
    // Total number of entries in the central directory
    ..setUint16(10, 1, Endian.little)
    // Size of the central directory
    ..setUint32(12, centralDirectoryHeader.lengthInBytes, Endian.little)
    // Offset of start of central directory
    ..setUint32(16, localFileHeader.lengthInBytes + bytes.length, Endian.little)
    // Comment length
    ..setUint16(20, 0, Endian.little);
  return endOfCentralDirectory;
}

ByteData _createZipDirectoryHeader(
  String fileName,
  int crc32,
  Uint8List originalBytes,
  int compressedSize,
) {
  final centralDirectoryHeader = ByteData(46 + fileName.length)
    ..setUint32(
      0,
      0x02014b50,
      Endian.little,
    ) // Central directory file header signature
    ..setUint16(4, 0, Endian.little) // Version made by
    ..setUint16(6, 20, Endian.little) // Version needed to extract
    ..setUint16(8, 0, Endian.little) // General purpose bit flag
    ..setUint16(10, 8, Endian.little) // Compression method (8: Deflate)
    ..setUint16(12, 0, Endian.little) // File last modification time
    ..setUint16(14, 0, Endian.little) // File last modification date
    ..setUint32(16, crc32, Endian.little) // CRC-32
    ..setUint32(20, compressedSize, Endian.little) // Compressed size
    ..setUint32(24, originalBytes.length, Endian.little) // Uncompressed size
    ..setUint16(28, fileName.length, Endian.little) // File name length
    ..setUint16(30, 0, Endian.little) // Extra field length
    ..setUint16(32, 0, Endian.little) // File comment length
    ..setUint16(34, 0, Endian.little) // Disk number start
    ..setUint16(36, 0, Endian.little) // Internal file attributes
    ..setUint32(38, 0, Endian.little) // External file attributes
    ..setUint32(42, 0, Endian.little) // Relative offset of local header
    ..buffer.asUint8List().setAll(46, utf8.encode(fileName)); // File name
  return centralDirectoryHeader;
}

ByteData _createZipHeader(
  String fileName,
  int crc32,
  Uint8List originalBytes,
  int compressedSize,
) {
  final localFileHeader = ByteData(30 + fileName.length)
    ..setUint32(0, 0x04034b50, Endian.little) // Local file header signature
    ..setUint16(4, 20, Endian.little) // Version needed to extract
    ..setUint16(6, 0, Endian.little) // General purpose bit flag
    ..setUint16(8, 8, Endian.little) // Compression method (8: Deflate)
    ..setUint16(10, 0, Endian.little) // File last modification time
    ..setUint16(12, 0, Endian.little) // File last modification date
    ..setUint32(14, crc32, Endian.little) // CRC-32
    ..setUint32(18, compressedSize, Endian.little) // Compressed size
    ..setUint32(22, originalBytes.length, Endian.little) // Uncompressed size
    ..setUint16(26, fileName.length, Endian.little) // File name length
    ..buffer.asUint8List().setAll(30, utf8.encode(fileName)); // File name
  return localFileHeader;
}

int _crc32(List<int> bytes) {
  // Simple implementation of CRC-32 checksum algorithm
  const polynomial = 0xEDB88320;
  var crc = 0xFFFFFFFF;
  for (final byte in bytes) {
    var currentByte = byte;
    for (int j = 0; j < 8; j++) {
      final isBitSet = (crc ^ currentByte) & 1;
      crc >>= 1;
      if (isBitSet != 0) {
        crc ^= polynomial;
      }
      currentByte >>= 1;
    }
  }
  return ~crc & 0xFFFFFFFF;
}
