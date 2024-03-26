# Serial Port for Flutter

`flutter_libserialport` is a simple wrapper around the [`libserialport`](https://pub.dev/packages/libserialport)
Dart package, utilizing Flutter's build system to build and deploy the [libserialport](https://sigrok.org/wiki/Libserialport)
C-library under the hood. This package does not provide any additional API, but merely helps to make the `libserialport` Dart
package work "out of the box" without the need of manually building and deploying the `libserialport` C-library.

Supported platforms:
- Linux
- macOS
- Windows
- Android

## Usage

To use this package, add `flutter_libserialport` as a [dependency in your pubspec.yaml file](https://dart.dev/tools/pub/dependencies).

![screenshot](https://raw.githubusercontent.com/jpnurmi/flutter_libserialport/main/doc/images/flutter_libserialport.png)

在示例中添加 完成与通讯城 通讯
使用 flutter_libserialport 库 与 窗口通讯城完成通讯
windows 已测试成功！ 2024/02/23

android 已测试成功 2024/3/26

ascii码编码表前 后字符代表 [https://www.kmw.com/news/6872705.html]