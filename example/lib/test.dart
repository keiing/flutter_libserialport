import 'dart:async';
import 'dart:convert';

// import 'package:flutter_libserialport_example/main.dart';

class OperationalGoodsUnit {
  final List<int> fristTargetData = [
    1,
    2,
  ];

  final List<int> lastTargetData = [
    3,
    4,
    // 0,
  ];

  static double weight = 0.00;

  static final StreamController<double> subscriber =
      StreamController<double>.broadcast();

  /// 发布消息
  static void publish(
    double weight,
  ) {
    /// 数据发生变化
    subscriber.sink.add(
      weight,
    );
  }

  /// 关闭发布者
  static void close() {
    subscriber.close();
  }

  final List<int> data = [];

  List<int> extractedData = [];

  bool isFind() {
    if (data.length > fristTargetData.length + lastTargetData.length) {
      return true;
    }
    return false;
  }

  /// 获取到传输内容
  bool findData() {
    int startIndex = -1;
    int lastIndex = -1;

    /// 获取起始坐标
    for (int i = 0; i < data.length - fristTargetData.length + 1; i++) {
      if (data[i] == fristTargetData[0] && data[i + 1] == fristTargetData[1]) {
        startIndex = i;
        break;
      }
    }
    if (startIndex != -1) {
      /// 获取结束坐标
      for (int i = startIndex;
          i < data.length - lastTargetData.length + 1;
          i++) {
        if (data[i] == lastTargetData[0] && data[i + 1] == lastTargetData[1]) {
          lastIndex = i;
          break;
        }
      }
    }

    if (startIndex != -1 && lastIndex != -1) {
      extractedData = data.sublist(
        startIndex + 2,
        lastIndex,
      );
      return true;
    }
    return false;
  }

  /// 添加数据
  add(List<int> list) {
    data.addAll(
      list,
    );
    find();
  }

  /// 主动进行查询一次
  find() {
    if (isFind()) {
      /// 为true
      if (findData()) {
        /// 清空数据
        clear();
        publish(getWeight());
      }
    }
  }

  /// 清空数据
  clear() {
    data.clear();
  }

  String? getValue() {
    if (extractedData.isNotEmpty) {
      final text = String.fromCharCodes(
        extractedData,
      );
      RegExp regExp = RegExp(r'(\d+\.\d+)');
      RegExpMatch? match = regExp.firstMatch(text);
      if (match != null) {
        String extractedData = match.group(0).toString();
        return extractedData;
      }
      return null;
    }
    return null;
  }

  /// 返回重量
  ///
  /// 使用方法
  ///```dart
  ///
  /// reader!.stream.listen(
  ///    (list) {
  ///      operationalGoodsUnit.add(
  ///        list.toList(),
  ///      );
  ///      final widget = operationalGoodsUnit.getWeight().toString();
  ///      if (text != widget) {
  ///        setState(
  ///          () {
  ///            text = widget;
  ///          },
  ///        );
  ///      }
  ///      ;
  ///    },
  ///  );
  ///```
  double getWeight() {
    try {
      final value = getValue();
      return weight = double.parse(
        value.toString(),
      );
    } catch (err) {
      weight = 0.00;
    }
    return weight;
  }
}

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
