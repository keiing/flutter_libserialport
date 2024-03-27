import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';

import 'operational_unit.dart';

void main() => runApp(ExampleApp());

class ExampleApp extends StatefulWidget {
  @override
  _ExampleAppState createState() => _ExampleAppState();
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
  List<String> availablePorts = [];
  SerialPortReader? reader;
  SerialPort? port;

  String text = "";
  String text2 = "";

  OperationalGoodsUnit operationalGoodsUnit = OperationalGoodsUnit();

  /// 订阅者
  StreamSubscription<double>? subscription;

  int readTime = 0;
  int sendTimeout = 0;

  final TextEditingController controller = TextEditingController(
    text: "115200",
  );

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
      port!.write(bytes);
      sendTimeout = DateTime.now().millisecondsSinceEpoch;
    }
  }

  void _readData() async {
    // 读数据
    final reader = SerialPortReader(
      port!,
      timeout: 10,
    );
    List<String> list = [];
    if (!port!.openReadWrite()) {
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
      () {
        text = "";
        text2 = "";
        availablePorts = SerialPort.availablePorts;
      },
    );

    // serialPortData(
    //   "COM2",
    // );
  }

  serialPortData(name) {
    port = SerialPort(name);

    // baudRates = [
    //   9600,
    //   19200,
    //   115200,
    // ]
    /// 波特率。波特率是串行通信中每秒传输的符号数，用于控制数据传输的速度。
    port!.config.baudRate = 9600;

    /// 数据位。数据位表示每个字符中用于表示信息的位数
    port!.config.bits = 8;

    /// 校验位。校验位用于检测数据在传输过程中是否发生错误。
    // port!.config.parity = 0;

    /// 停止位。停止位用于标记字符的结束。
    // port!.config.stopBits = 2;
    _readData();
  }

  void listen(String address) async {
    setState(() {
      text2 = "初始化中...1";
    });

    if (reader != null) {
      close();
    }
    setState(() {
      text2 = "初始化中...2";
    });
    try {
      port = SerialPort(address);

      if (Platform.isWindows) {
        port!.config.baudRate = int.parse(controller.text);
        // port!.config.stopBits = 2;
        // port!.config.bits = 8;
        // port!.config.parity = 0;
      }

      await Future.delayed(
        Duration(
          milliseconds: 100,
        ),
        () {
          try {
            setState(() {
              text2 = "初始化成功 等待连接中...";
            });

            /// 只读
            final value = port!.openRead();

            if (!value) {
              setState(() {
                text2 = "连接失败$value";
              });
              return;
            }

            setState(() {
              text2 = "连接成功";
            });

            reader = SerialPortReader(
              port!,
            );

            setState(() {
              text2 = "连接成功...reader?.port == port:${reader?.port == port}";
            });

            reader!.stream.listen(
              (list) {
                operationalGoodsUnit.add(
                  list.toList(),
                );
              },
            );
          } catch (err) {
            setState(() {
              text2 = "连接异常 $err";
            });
          }
        },
      );
    } catch (err) {
      setState(() {
        text2 = "初始化异常 $err";
      });
    }
  }

  void close() {
    try {
      port?.dispose();

      /// 关闭
      reader?.port.close();
      reader?.close();

      /// 取消订阅
      reader = null;
    } catch (err) {
      print('关闭异常');
    }
  }

  @override
  void dispose() {
    /// 销毁
    reader?.port.dispose();

    /// 关闭
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
              TextField(
                controller: controller,
              ),
              Text(
                text,
              ),
              Text(
                text2,
              ),
              for (final address in availablePorts)
                Builder(builder: (context) {
                  // port.openRead();

                  return TextButton(
                    onPressed: () {
                      listen(address);
                    },
                    child: Text(address),
                  );

                  // return ExpansionTile(
                  //   title: Text(address),
                  //   children: [
                  //     CardListTile('Description', port.description),
                  //     // CardListTile('Transport', port.transport.toTransport()),
                  //     // CardListTile('USB Bus', port.busNumber?.toPadded()),
                  //     // CardListTile('USB Device', port.deviceNumber?.toPadded()),
                  //     // CardListTile('Vendor ID', port.vendorId?.toHex()),
                  //     // CardListTile('Product ID', port.productId?.toHex()),
                  //     // CardListTile('Manufacturer', port.manufacturer),
                  //     // CardListTile('Product Name', port.productName),
                  //     // CardListTile('Serial Number', port.serialNumber),
                  //     // CardListTile('MAC Address', port.macAddress),
                  //     TextButton(
                  //       onPressed: () {
                  //         listen(port);
                  //       },
                  //       child: Text('open'),
                  //     )
                  //   ],
                  // );
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
