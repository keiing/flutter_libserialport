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
  // SerialPortReader? reader;
  // SerialPort? port;
  late File file;
  List textList = [];
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

  /// 停止位列表
  final List<String> stopBitsList = ["0", "1", "2"];
  String stopBit = "1";

  /// 校验位
  final List<String> parityList = ["0", "1", "2"];
  String parity = "0";

  @override
  void initState() {
    super.initState();
    initPorts();

    file = File("./list.txt");

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
        textList.clear();
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

  /// 是否开启已经通讯称
  bool isOpen = false;

  /// 未进行初始化
  int status = 0;

  /// 串口
  SerialPortReader? reader;
  SerialPort? port;

  /// 连接通讯称
  /// [address] 串口地址
  /// [baudRate] 波特率
  Future<void> connection({
    required String address,
    required int baudRate,
  }) async {
    if (reader != null || port != null) {
      close();
    }

    try {
      /// 启动初始化
      status = 1;
      port = SerialPort(address);

      if (Platform.isWindows) {
        port!.config.baudRate = baudRate;
        port!.config.stopBits = int.parse(stopBit);
        port!.config.bits = 8;
        port!.config.parity = int.parse(parity);
      }

      /// 初始化成功
      status = 2;

      return Future.delayed(
        const Duration(
          milliseconds: 100,
        ),
        () {
          /// 尝试读取
          status = 3;

          /// 只读
          final value = port!.openRead();

          /// 读取失败
          if (!value) {
            throw Error.safeToString("打开失败");
          }

          /// 尝试连接
          status = 4;

          reader = SerialPortReader(
            port!,
          );

          /// 连接成功
          status = 5;

          /// 尝试监听
          reader!.stream.listen(
            (list) {
              /// 通知栈发生变化
              operationalGoodsUnit.add(
                list.toList(),
              );
            },
          );

          /// 监听成功
          status = 6;
          isOpen = true;
        },
      ).catchError((err) {
        close();

        /// 打开失败
        status = 10;
      });
    } catch (err) {
      close();

      /// 初始化失败
      status = 11;
    }
  }

  void listen(String address) async {
    // await connection(
    //   address: address,
    //   baudRate: 9200,

    // );
    setState(() {
      text2 = "初始化中...$status";
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
        port!.config.stopBits = int.parse(stopBit);
        port!.config.bits = 8;
        port!.config.parity = int.parse(parity);
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
                setState(() {
                  textList.addAll(
                    list,
                  );
                  text = "${list}";
                });
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
      port?.close();
      port?.dispose();

      /// 释放 port 防止重复 dispose
      port = null;

      /// 关闭
      reader?.close();

      /// 取消订阅
      reader = null;
    } catch (err) {
      print('关闭异常');
    }
  }

  @override
  void dispose() {
    /// 关闭通讯秤
    close();

    /// 取消订阅者
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
                textList.toString(),
              ),
              Text(
                text,
              ),
              Text(
                text2,
              ),
              for (final address in availablePorts)
                Builder(
                  builder: (context) {
                    return TextButton(
                      onPressed: () {
                        listen(address);
                      },
                      child: Text(address),
                    );
                  },
                ),

              /// 停止位
              Text("停止位"),
              DropdownButton<String>(
                value: stopBit,
                items: stopBitsList.map(
                  (String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  },
                ).toList(),
                onChanged: (String? newValue) {
                  setState(
                    () {
                      stopBit = newValue ?? "";
                    },
                  );
                },
              ),

              Text("校验位"),
              DropdownButton<String>(
                value: parity,
                items: parityList.map(
                  (String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  },
                ).toList(),
                onChanged: (String? newValue) {
                  setState(
                    () {
                      parity = newValue ?? "";
                    },
                  );
                },
              ),

              TextButton(
                onPressed: () {
                  close();
                },
                child: Text("关闭"),
              ),
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
