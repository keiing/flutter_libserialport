import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';

void main() => runApp(ExampleApp());

class ExampleApp extends StatefulWidget {
  @override
  _ExampleAppState createState() => _ExampleAppState();
}

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

extension IntToString on int {
  String toHex() => '0x${toRadixString(16)}';
  String toPadded([int width = 3]) => toString().padLeft(width, '0');
  String toTransport() {
    switch (this) {
      case SerialPortTransport.usb:
        return 'USB';
      case SerialPortTransport.bluetooth:
        return 'Bluetooth';
      case SerialPortTransport.native:
        return 'Native';
      default:
        return 'Unknown';
    }
  }
}

class _ExampleAppState extends State<ExampleApp> {
  var availablePorts = [];
  SerialPortReader? reader;
  String text = "";
  String text2 = "";

  OperationalGoodsUnit operationalGoodsUnit = OperationalGoodsUnit();

  StreamSubscription<double>? subscription;
  late SerialPort port;

  int readTime = 0;
  int sendTimeout = 0;

  @override
  void initState() {
    super.initState();
    initPorts();

    /// 订阅 发布者
    subscription = OperationalGoodsUnit.subscriber.stream.listen(
      (event) {
        final widget = event.toString();
        if (text != widget) {
          setState(
            () {
              text = widget;
            },
          );
        }
      },
    );
  }

  int hexToInt(String hex) {
    return int.parse(hex, radix: 16);
  }

  /// 发送数据
  void senData(String sendData) async {
    if (sendData.isEmpty) {
      return;
    }
    int lastSendTimeout = DateTime.now().millisecondsSinceEpoch - sendTimeout;
    print(lastSendTimeout);
    if (lastSendTimeout > 10) {
      List<int> dataList = [];
      int len = sendData.length ~/ 2;
      for (int i = 0; i < len; i++) {
        String data = sendData.trim().substring(2 * i, 2 * (i + 1));
        int d = hexToInt(data);
        dataList.add(d);
      }
      print('发送数据$sendData');
      print('发送数据${dataList.toString()}');
      var bytes = Uint8List.fromList(dataList);
      port.write(bytes);
      sendTimeout = DateTime.now().millisecondsSinceEpoch;
    }
  }

  void _readData() async {
    // 读数据
    final reader = SerialPortReader(
      port,
      timeout: 10,
    );
    List<String> list = [];
    if (!port.openReadWrite()) {
      print(SerialPort.lastError);
      return;
    }
    StringBuffer buffer = StringBuffer();
    int timeout = DateTime.now().millisecondsSinceEpoch;
    Timer.periodic(
      Duration(
        milliseconds: 100,
      ),
      (timer) {
        if (list.isNotEmpty) {
          int lastTime = DateTime.now().millisecondsSinceEpoch - timeout;
          if (lastTime > readTime) {
            for (var d in list) {
              buffer.write(d.toString());
            }
            print('接收数据${buffer.toString()}');

            setState(() {
              text = buffer.toString();

              try {
                text2 = list.map((hexString) {
                  List<int> bytes = List.generate(
                      hexString.length ~/ 2,
                      (i) => int.parse(hexString.substring(i * 2, i * 2 + 2),
                          radix: 16));
                  String chineseString = utf8.decode(
                    bytes,
                  );
                  return chineseString;
                }).toString();
              } catch (err) {}
              ;
            });

            buffer.clear();
            list.clear();
          }
        }
      },
    );
    reader.stream.listen((data) {
      // String hexString = data.map((byte) => byte.toRadixString(16)).join();
      //print('receivedHex: ${hexString.toUpperCase()}'); // 转换为16进制
      // list.add(hexString);
      // timeout = DateTime.now().millisecondsSinceEpoch;
      if (text.length < 32) {
        text += data.toString();
        setState(() {
          text;
        });
      }
    });
    //执行接下来的操作
  }

  void initPorts() {
    /// 获取 串口 列表
    setState(
      () => availablePorts = SerialPort.availablePorts,
    );

    // serialPortData(
    //   "COM2",
    // );
  }

  serialPortData(name) {
    port = SerialPort(name);
    port.config.baudRate = 115200;
    port.config.stopBits = 2;
    port.config.bits = 8;
    port.config.parity = 0;
    _readData();
  }

  void listen(SerialPort port) async {
    if (reader != null) {
      close();
    }

    await Future.delayed(
      Duration(seconds: 1),
      () {
        // port.config.baudRate = 115200;

        final value = port.openRead();
        if (!value) {
          setState(() {
            text2 = "connect...open... $value";
          });
          return;
        }

        reader = SerialPortReader(
          port,
        );

        reader!.stream.listen(
          (list) {
            operationalGoodsUnit.add(
              list.toList(),
            );
          },
        );
      },
    );
  }

  void close() {
    /// 关闭
    reader?.port.close();
    reader?.close();

    /// 取消订阅
    reader = null;
  }

  @override
  void dispose() {
    /// 释放
    reader?.port.dispose();
    reader?.close();
    subscription?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Serial Port example'),
        ),
        body: Scrollbar(
          child: ListView(
            children: [
              Text(
                text,
              ),
              Text(
                text2,
              ),
              for (final address in availablePorts)
                Builder(builder: (context) {
                  final port = SerialPort(address);
                  // port.openRead();

                  return TextButton(
                    onPressed: () {
                      listen(port);
                    },
                    child: Text(address),
                  );

                  return ExpansionTile(
                    title: Text(address),
                    children: [
                      CardListTile('Description', port.description),
                      // CardListTile('Transport', port.transport.toTransport()),
                      // CardListTile('USB Bus', port.busNumber?.toPadded()),
                      // CardListTile('USB Device', port.deviceNumber?.toPadded()),
                      // CardListTile('Vendor ID', port.vendorId?.toHex()),
                      // CardListTile('Product ID', port.productId?.toHex()),
                      // CardListTile('Manufacturer', port.manufacturer),
                      // CardListTile('Product Name', port.productName),
                      // CardListTile('Serial Number', port.serialNumber),
                      // CardListTile('MAC Address', port.macAddress),
                      TextButton(
                        onPressed: () {
                          listen(port);
                        },
                        child: Text('open'),
                      )
                    ],
                  );
                }),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.refresh),
          onPressed: initPorts,
        ),
      ),
    );
  }
}

class CardListTile extends StatelessWidget {
  final String name;
  final String? value;

  CardListTile(this.name, this.value);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(value ?? 'N/A'),
        subtitle: Text(name),
      ),
    );
  }
}
