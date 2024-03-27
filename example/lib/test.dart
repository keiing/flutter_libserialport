import 'dart:async';
import 'dart:convert';

import 'operational_unit.dart';

// import 'package:flutter_libserialport_example/main.dart';

void main() {
  final data = [
    1,
    2,
    85,
    32,
    48,
    50,
    46,
    53,
    49,
    52,
    107,
    103,
    101,
    3,
    4,
    0,
    1,
    2,
    85,
    32,
    3,
    4,
    0
  ];

  print(String.fromCharCodes(data));

  RegExp regExp = RegExp(r'(-?\d+\.\d+)');
  RegExpMatch? match = regExp.firstMatch("U 0.12324kge");
  if (match != null) {
    String extractedData = match.group(0).toString();
    print(extractedData);
  }

  RegExpMatch? match2 = regExp.firstMatch("U -0.12324kge");
  if (match2 != null) {
    String extractedData = match2.group(0).toString();
    print(extractedData);
  }

  return;
  OperationalGoodsUnit operationalGoodsUnit = OperationalGoodsUnit();

  operationalGoodsUnit.add(
    [
      1,
      2,
      85,
      32,
      48,
      50,
      46,
      53,
    ],
  );

  operationalGoodsUnit.add(
    [
      49,
      52,
      107,
      103,
      101,
      3,
      4,
      0,
      1,
      2,
      85,
      32,
      3,
      4,
      0,
    ],
  );

  /// 是否可以查询
  final double weight = operationalGoodsUnit.getWeight();
  print(weight);
  // print(operationalGoodsUnit.findData());

  return;
  String hexString = "343538"; // 16进制数据
  List<int> bytes = List.generate(
    hexString.length ~/ 2,
    (i) => int.parse(
      hexString.substring(i * 2, i * 2 + 2),
      radix: 16,
    ),
  );
  String chineseString = utf8.decode(bytes);
  print(chineseString);

  /// 3, 4, 16 意味结束
  // final list = [48, 48, 107, 103, 97, 3, 4, 16];
  // print(
  //   // 00kga
  //   String.fromCharCodes(
  //     Uint8List.fromList(
  //       list,
  //     ).sublist(
  //       0,
  //       list.length - 3,
  //     ),
  //   ),
  // );

  // print(
  //   // 00kga
  //   convert.latin1.decode(
  //     Uint8List.fromList(
  //       [48, 48, 107, 103, 97, 3, 4, 16],
  //     ).buffer.asUint8List(
  //           5,
  //           3,
  //         ),
  //   ),
  // ); // "123"

  // print(
  //   convert.ascii.decode(
  //     Uint8List.fromList(
  //       [48, 48, 107, 103, 97, 3, 4, 16],
  //     ),
  //   ),
  // );
}
