import 'dart:async';

/// 根据单位进行转换
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

  ///```dart
  /// /// 订阅 发布者
  ///  subscription = OperationalGoodsUnit.subscriber.stream.listen(
  ///    (event) {
  ///      final widget = event.toString();
  ///      if (text != widget) {
  ///        setState(
  ///          () {
  ///            text = widget;
  ///          },
  ///        );
  ///      }
  ///    },
  ///  );
  ///
  ///  /// 记得取消订阅
  ///  subscription?.cancel();
  ///```
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
