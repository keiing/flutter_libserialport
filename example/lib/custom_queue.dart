import 'dart:async';

import 'package:flutter/foundation.dart';

class CustomQueueData {
  final Completer completer;
  final AsyncValueGetter callback;
  bool execute = false;

  /// 设置是否执行过
  setExecute() {
    execute = true;
  }

  CustomQueueData({
    required this.completer,
    required this.callback,
  });
}

/// 队列类
class CustomQueue {
  /// 是否只取最后一个任务执行
  ///
  final bool onlyLastTask;

  /// 执行任务间隔
  ///
  final Duration interval;

  CustomQueue({
    this.onlyLastTask = false,
    this.interval = Duration.zero,
  });

  /// 已经执行
  int startIndex = 0;

  final List<CustomQueueData> statck = [];

  bool inProgress = false;

  ///
  clear() {
    final CustomQueueData? lastElement = statck.lastOrNull;
    for (var element in statck) {
        if (element.execute == false && element != lastElement) {
          element
            ..completer.complete(
              null,
            )
            ..setExecute();
        }
      }

    statck.removeWhere((element) => element.execute);
  }

  /// 删除任务
  start({
    Duration? duration,
  }) async {
    /// 任务执行中
    if (inProgress) {
      return;
    }

    if (statck.isNotEmpty) {
      /// 设置任务执行中
      inProgress = true;

      /// 等待时间
      await Future.delayed(
        duration ?? interval,
      );

      if (onlyLastTask) {
        /// 开始执行任务
        final customQueueData = statck.lastOrNull;

        if (customQueueData == null) {
          return clear();
        }

        if (customQueueData.execute) {
          /// 清空队列
          return clear();
        }

        customQueueData
          ..callback.call().then(
            (value) {
              customQueueData.completer.complete(
                value,
              );
              clear();
            },
          )
          ..setExecute();
        ;
      } else {
        /// 开始执行任务
        final customQueueData = statck.removeAt(
          0,
        );
        customQueueData
          ..completer.complete(
            customQueueData.callback.call(),
          )

          /// 设置已经执行过
          ..setExecute();
      }
    }
  }

  /// 新增任务
  void _add({
    required Completer completer,
    required AsyncValueGetter callback,
  }) {
    /// 添加任务
    statck.add(
      CustomQueueData(
        callback: callback,
        completer: completer,
      ),
    );
  }

  /// 启动任务
  Future<T> add<T>(
    AsyncValueGetter<T> callback,
  ) {
    /// 创建任务
    final completer = Completer<T>();

    final isFirst = statck.isEmpty;

    _add(
      completer: completer,
      callback: callback,
    );

    if (isFirst) {
      /// 启动任务
      start(
        duration: isFirst ? Duration.zero : interval,
      );
    }

    return completer.future.whenComplete(
      () {
        /// 任务结束
        _end(
          completer: completer,
          callback: callback,
        );
      },
    );
  }

  /// 任务结束
  _end({
    required Completer completer,
    required AsyncValueGetter callback,
  }) {
    inProgress = false;

    /// 继续执行
    start();
  }
}
