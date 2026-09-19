import 'dart:typed_data';

/// Encoder JPEG baseline 4:4:4, puro Dart: serve nei test e in [compute].
Uint8List encodeJpeg(
  Uint8List rgba, {
  required int width,
  required int height,
  int quality = 90,
}) {
  final q = quality.clamp(1, 100);
  final scale = q < 50 ? (5000 / q).round() : 200 - 2 * q;
  final yQuant = _scaleTable(_lumaQuant, scale);
  final cQuant = _scaleTable(_chromaQuant, scale);

  final ydu = Float64List(64);
  final cbdu = Float64List(64);
  final crdu = Float64List(64);
  final yq = _aanQuant(yQuant);
  final cq = _aanQuant(cQuant);
  final zz = List<int>.filled(64, 0);

  var prevY = 0;
  var prevCb = 0;
  var prevCr = 0;
  final bits = _BitWriter();

  final widthBlocks = (width + 7) >> 3;
  final heightBlocks = (height + 7) >> 3;

  for (var by = 0; by < heightBlocks; by++) {
    for (var bx = 0; bx < widthBlocks; bx++) {
      _sampleBlock(rgba, width, height, bx * 8, by * 8, ydu, cbdu, crdu);
      prevY = _encodeDu(bits, ydu, yq, zz, _dcLuma, _acLuma, prevY);
      prevCb = _encodeDu(bits, cbdu, cq, zz, _dcChroma, _acChroma, prevCb);
      prevCr = _encodeDu(bits, crdu, cq, zz, _dcChroma, _acChroma, prevCr);
    }
  }
  bits.flush();

  final out = BytesBuilder(copy: false);
  out.add(_soi);
  out.add(_app0);
  out.add(_dqtMarker(0, yQuant));
  out.add(_dqtMarker(1, cQuant));
  out.add(_sof0(width, height));
  out.add(_dht(_dcLumaBits, _dcLumaVal, 0x00));
  out.add(_dht(_acLumaBits, _acLumaVal, 0x10));
  out.add(_dht(_dcChromaBits, _dcChromaVal, 0x01));
  out.add(_dht(_acChromaBits, _acChromaVal, 0x11));
  out.add(_sos);
  out.add(bits.bytes);
  out.add(_eoi);
  return out.toBytes();
}

const _aasf = [
  1.0,
  1.387039845,
  1.306562965,
  1.175875602,
  1.0,
  0.785694958,
  0.541196100,
  0.275899379,
];

List<double> _aanQuant(List<int> quant) {
  return [
    for (var i = 0; i < 64; i++)
      1.0 / (quant[i] * _aasf[i >> 3] * _aasf[i & 7] * 8.0),
  ];
}

/// DCT AAN in-place (stesso algoritmo di jpeg-js / libjpeg jfdctflt).
void _fdctAan(Float64List data) {
  for (var i = 0; i < 8; i++) {
    final o = i * 8;
    final d0 = data[o];
    final d1 = data[o + 1];
    final d2 = data[o + 2];
    final d3 = data[o + 3];
    final d4 = data[o + 4];
    final d5 = data[o + 5];
    final d6 = data[o + 6];
    final d7 = data[o + 7];
    final tmp0 = d0 + d7;
    final tmp7 = d0 - d7;
    final tmp1 = d1 + d6;
    final tmp6 = d1 - d6;
    final tmp2 = d2 + d5;
    final tmp5 = d2 - d5;
    final tmp3 = d3 + d4;
    final tmp4 = d3 - d4;
    final tmp10 = tmp0 + tmp3;
    final tmp13 = tmp0 - tmp3;
    final tmp11 = tmp1 + tmp2;
    final tmp12 = tmp1 - tmp2;
    data[o] = tmp10 + tmp11;
    data[o + 4] = tmp10 - tmp11;
    final z1 = (tmp12 + tmp13) * 0.707106781;
    data[o + 2] = tmp13 + z1;
    data[o + 6] = tmp13 - z1;
    final tmp10b = tmp4 + tmp5;
    final tmp11b = tmp5 + tmp6;
    final tmp12b = tmp6 + tmp7;
    final z5 = (tmp10b - tmp12b) * 0.382683433;
    final z2 = 0.541196100 * tmp10b + z5;
    final z4 = 1.306562965 * tmp12b + z5;
    final z3 = tmp11b * 0.707106781;
    final z11 = tmp7 + z3;
    final z13 = tmp7 - z3;
    data[o + 5] = z13 + z2;
    data[o + 3] = z13 - z2;
    data[o + 1] = z11 + z4;
    data[o + 7] = z11 - z4;
  }
  for (var i = 0; i < 8; i++) {
    final d0 = data[i];
    final d1 = data[i + 8];
    final d2 = data[i + 16];
    final d3 = data[i + 24];
    final d4 = data[i + 32];
    final d5 = data[i + 40];
    final d6 = data[i + 48];
    final d7 = data[i + 56];
    final tmp0 = d0 + d7;
    final tmp7 = d0 - d7;
    final tmp1 = d1 + d6;
    final tmp6 = d1 - d6;
    final tmp2 = d2 + d5;
    final tmp5 = d2 - d5;
    final tmp3 = d3 + d4;
    final tmp4 = d3 - d4;
    final tmp10 = tmp0 + tmp3;
    final tmp13 = tmp0 - tmp3;
    final tmp11 = tmp1 + tmp2;
    final tmp12 = tmp1 - tmp2;
    data[i] = tmp10 + tmp11;
    data[i + 32] = tmp10 - tmp11;
    final z1 = (tmp12 + tmp13) * 0.707106781;
    data[i + 16] = tmp13 + z1;
    data[i + 48] = tmp13 - z1;
    final tmp10b = tmp4 + tmp5;
    final tmp11b = tmp5 + tmp6;
    final tmp12b = tmp6 + tmp7;
    final z5 = (tmp10b - tmp12b) * 0.382683433;
    final z2 = 0.541196100 * tmp10b + z5;
    final z4 = 1.306562965 * tmp12b + z5;
    final z3 = tmp11b * 0.707106781;
    final z11 = tmp7 + z3;
    final z13 = tmp7 - z3;
    data[i + 40] = z13 + z2;
    data[i + 24] = z13 - z2;
    data[i + 8] = z11 + z4;
    data[i + 56] = z11 - z4;
  }
}

void _sampleBlock(
  Uint8List rgba,
  int width,
  int height,
  int originX,
  int originY,
  Float64List ydu,
  Float64List cbdu,
  Float64List crdu,
) {
  final maxX = width - 1;
  final maxY = height - 1;
  for (var y = 0; y < 8; y++) {
    var py = originY + y;
    if (py > maxY) {
      py = maxY;
    }
    final row = py * width;
    for (var x = 0; x < 8; x++) {
      var px = originX + x;
      if (px > maxX) {
        px = maxX;
      }
      final i = (row + px) * 4;
      final r = rgba[i];
      final g = rgba[i + 1];
      final b = rgba[i + 2];
      final idx = y * 8 + x;
      ydu[idx] = (((19595 * r + 38470 * g + 7471 * b) >> 16) - 128).toDouble();
      cbdu[idx] = ((-11059 * r - 21709 * g + 32768 * b) >> 16).toDouble();
      crdu[idx] = ((32768 * r - 27439 * g - 5329 * b) >> 16).toDouble();
    }
  }
}

int _encodeDu(
  _BitWriter bits,
  Float64List du,
  List<double> fdtbl,
  List<int> zz,
  List<_Huff> dcTable,
  List<_Huff> acTable,
  int prevDc,
) {
  _fdctAan(du);
  for (var z = 0; z < 64; z++) {
    final src = _zigzag[z];
    final v = du[src] * fdtbl[src];
    final q = v < 0 ? (v - 0.5).toInt() : (v + 0.5).toInt();
    zz[z] = q.clamp(-1023, 1023);
  }
  final dc = zz[0] - prevDc;
  _writeCoeff(bits, dcTable, 0, dc);
  var lastNz = 63;
  while (lastNz > 0 && zz[lastNz] == 0) {
    lastNz--;
  }
  var zeroRun = 0;
  for (var i = 1; i <= lastNz; i++) {
    if (zz[i] == 0) {
      zeroRun++;
      if (zeroRun == 16) {
        bits.writeHuff(acTable[0xF0]);
        zeroRun = 0;
      }
    } else {
      _writeCoeff(bits, acTable, zeroRun, zz[i]);
      zeroRun = 0;
    }
  }
  if (lastNz < 63) {
    bits.writeHuff(acTable[0x00]);
  }
  return zz[0];
}

void _writeCoeff(_BitWriter bits, List<_Huff> table, int run, int value) {
  var mag = value < 0 ? -value : value;
  var cat = 0;
  while (mag > 0) {
    mag >>= 1;
    cat++;
  }
  bits.writeHuff(table[(run << 4) | cat]);
  if (cat > 0) {
    var bitsVal = value;
    if (value < 0) {
      bitsVal = value - 1;
    }
    bits.write(bitsVal, cat);
  }
}

class _Huff {
  const _Huff(this.code, this.len);
  final int code;
  final int len;
}

class _BitWriter {
  final BytesBuilder _out = BytesBuilder(copy: false);
  int _acc = 0;
  int _n = 0;

  Uint8List get bytes => _out.toBytes();

  void writeHuff(_Huff h) => write(h.code, h.len);

  void write(int value, int len) {
    if (len <= 0) {
      return;
    }
    _acc = (_acc << len) | (value & ((1 << len) - 1));
    _n += len;
    while (_n >= 8) {
      _n -= 8;
      final b = (_acc >> _n) & 0xFF;
      _out.addByte(b);
      if (b == 0xFF) {
        _out.addByte(0x00);
      }
    }
    if (_n == 0) {
      _acc = 0;
    } else {
      _acc &= (1 << _n) - 1;
    }
  }

  void flush() {
    if (_n > 0) {
      write(0x7F, 8 - _n);
    }
  }
}

List<int> _scaleTable(List<int> base, int scale) {
  return [
    for (final v in base) ((v * scale + 50) ~/ 100).clamp(1, 255),
  ];
}

Uint8List _dqtMarker(int id, List<int> table) {
  return Uint8List.fromList([
    0xFF,
    0xDB,
    0x00,
    0x43,
    id,
    for (var i = 0; i < 64; i++) table[_zigzag[i]],
  ]);
}

Uint8List _sof0(int width, int height) {
  return Uint8List.fromList([
    0xFF, 0xC0, 0x00, 0x11, 0x08,
    (height >> 8) & 0xFF, height & 0xFF,
    (width >> 8) & 0xFF, width & 0xFF,
    0x03,
    0x01, 0x11, 0x00,
    0x02, 0x11, 0x01,
    0x03, 0x11, 0x01,
  ]);
}

Uint8List _dht(List<int> bits, List<int> values, int cls) {
  final len = 2 + 1 + 16 + values.length;
  return Uint8List.fromList([
    0xFF, 0xC4,
    (len >> 8) & 0xFF, len & 0xFF,
    cls,
    ...bits,
    ...values,
  ]);
}

List<_Huff> _buildHuff(List<int> bits, List<int> values) {
  final table = List<_Huff>.filled(256, const _Huff(0, 0));
  var code = 0;
  var k = 0;
  for (var i = 0; i < 16; i++) {
    for (var j = 0; j < bits[i]; j++) {
      table[values[k]] = _Huff(code, i + 1);
      code++;
      k++;
    }
    code <<= 1;
  }
  return table;
}

final _dcLuma = _buildHuff(_dcLumaBits, _dcLumaVal);
final _acLuma = _buildHuff(_acLumaBits, _acLumaVal);
final _dcChroma = _buildHuff(_dcChromaBits, _dcChromaVal);
final _acChroma = _buildHuff(_acChromaBits, _acChromaVal);

const _soi = [0xFF, 0xD8];
const _eoi = [0xFF, 0xD9];
const _app0 = [
  0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01, 0x01,
  0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00,
];
const _sos = [
  0xFF, 0xDA, 0x00, 0x0C, 0x03, 0x01, 0x00, 0x02, 0x11, 0x03, 0x11,
  0x00, 0x3F, 0x00,
];

const _zigzag = [
  0, 1, 8, 16, 9, 2, 3, 10,
  17, 24, 32, 25, 18, 11, 4, 5,
  12, 19, 26, 33, 40, 48, 41, 34,
  27, 20, 13, 6, 7, 14, 21, 28,
  35, 42, 49, 56, 57, 50, 43, 36,
  29, 22, 15, 23, 30, 37, 44, 51,
  58, 59, 52, 45, 38, 31, 39, 46,
  53, 60, 61, 54, 47, 55, 62, 63,
];

const _lumaQuant = [
  16, 11, 10, 16, 24, 40, 51, 61,
  12, 12, 14, 19, 26, 58, 60, 55,
  14, 13, 16, 24, 40, 57, 69, 56,
  14, 17, 22, 29, 51, 87, 80, 62,
  18, 22, 37, 56, 68, 109, 103, 77,
  24, 35, 55, 64, 81, 104, 113, 92,
  49, 64, 78, 87, 103, 121, 120, 101,
  72, 92, 95, 98, 112, 100, 103, 99,
];

const _chromaQuant = [
  17, 18, 24, 47, 99, 99, 99, 99,
  18, 21, 26, 66, 99, 99, 99, 99,
  24, 26, 56, 99, 99, 99, 99, 99,
  47, 66, 99, 99, 99, 99, 99, 99,
  99, 99, 99, 99, 99, 99, 99, 99,
  99, 99, 99, 99, 99, 99, 99, 99,
  99, 99, 99, 99, 99, 99, 99, 99,
  99, 99, 99, 99, 99, 99, 99, 99,
];

const _dcLumaBits = [
  0, 1, 5, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0,
];
const _dcLumaVal = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
const _dcChromaBits = [
  0, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0,
];
const _dcChromaVal = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
const _acLumaBits = [
  0, 2, 1, 3, 3, 2, 4, 3, 5, 5, 4, 4, 0, 0, 1, 0x7d,
];
const _acLumaVal = [
  0x01, 0x02, 0x03, 0x00, 0x04, 0x11, 0x05, 0x12, 0x21, 0x31, 0x41, 0x06,
  0x13, 0x51, 0x61, 0x07, 0x22, 0x71, 0x14, 0x32, 0x81, 0x91, 0xa1, 0x08,
  0x23, 0x42, 0xb1, 0xc1, 0x15, 0x52, 0xd1, 0xf0, 0x24, 0x33, 0x62, 0x72,
  0x82, 0x09, 0x0a, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x25, 0x26, 0x27, 0x28,
  0x29, 0x2a, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3a, 0x43, 0x44, 0x45,
  0x46, 0x47, 0x48, 0x49, 0x4a, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59,
  0x5a, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6a, 0x73, 0x74, 0x75,
  0x76, 0x77, 0x78, 0x79, 0x7a, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89,
  0x8a, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98, 0x99, 0x9a, 0xa2, 0xa3,
  0xa4, 0xa5, 0xa6, 0xa7, 0xa8, 0xa9, 0xaa, 0xb2, 0xb3, 0xb4, 0xb5, 0xb6,
  0xb7, 0xb8, 0xb9, 0xba, 0xc2, 0xc3, 0xc4, 0xc5, 0xc6, 0xc7, 0xc8, 0xc9,
  0xca, 0xd2, 0xd3, 0xd4, 0xd5, 0xd6, 0xd7, 0xd8, 0xd9, 0xda, 0xe1, 0xe2,
  0xe3, 0xe4, 0xe5, 0xe6, 0xe7, 0xe8, 0xe9, 0xea, 0xf1, 0xf2, 0xf3, 0xf4,
  0xf5, 0xf6, 0xf7, 0xf8, 0xf9, 0xfa,
];
const _acChromaBits = [
  0, 2, 1, 2, 4, 4, 3, 4, 7, 5, 4, 4, 0, 1, 2, 0x77,
];
const _acChromaVal = [
  0x00, 0x01, 0x02, 0x03, 0x11, 0x04, 0x05, 0x21, 0x31, 0x06, 0x12, 0x41,
  0x51, 0x07, 0x61, 0x71, 0x13, 0x22, 0x32, 0x81, 0x08, 0x14, 0x42, 0x91,
  0xa1, 0xb1, 0xc1, 0x09, 0x23, 0x33, 0x52, 0xf0, 0x15, 0x62, 0x72, 0xd1,
  0x0a, 0x16, 0x24, 0x34, 0xe1, 0x25, 0xf1, 0x17, 0x18, 0x19, 0x1a, 0x26,
  0x27, 0x28, 0x29, 0x2a, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3a, 0x43, 0x44,
  0x45, 0x46, 0x47, 0x48, 0x49, 0x4a, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58,
  0x59, 0x5a, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6a, 0x73, 0x74,
  0x75, 0x76, 0x77, 0x78, 0x79, 0x7a, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87,
  0x88, 0x89, 0x8a, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98, 0x99, 0x9a,
  0xa2, 0xa3, 0xa4, 0xa5, 0xa6, 0xa7, 0xa8, 0xa9, 0xaa, 0xb2, 0xb3, 0xb4,
  0xb5, 0xb6, 0xb7, 0xb8, 0xb9, 0xba, 0xc2, 0xc3, 0xc4, 0xc5, 0xc6, 0xc7,
  0xc8, 0xc9, 0xca, 0xd2, 0xd3, 0xd4, 0xd5, 0xd6, 0xd7, 0xd8, 0xd9, 0xda,
  0xe2, 0xe3, 0xe4, 0xe5, 0xe6, 0xe7, 0xe8, 0xe9, 0xea, 0xf2, 0xf3, 0xf4,
  0xf5, 0xf6, 0xf7, 0xf8, 0xf9, 0xfa,
];
