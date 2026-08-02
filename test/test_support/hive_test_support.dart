// テスト用にHiveを一時ディレクトリで初期化するためのヘルパー。
//
// `Hive.initFlutter()`はpath_providerのプラットフォームチャンネルに依存するため
// 単体テストでは使えない。代わりに`Hive.init`に一時ディレクトリを渡す。

import 'dart:io';

import 'package:hive/hive.dart';

Directory? _tempDir;

/// 一時ディレクトリにHiveを初期化する。各テストの`setUp`で呼ぶこと。
Future<void> initTestHive() async {
  _tempDir = await Directory.systemTemp.createTemp('pj_walter_test_');
  Hive.init(_tempDir!.path);
}

/// Hiveを閉じ、一時ディレクトリを削除する。各テストの`tearDown`で呼ぶこと。
Future<void> tearDownTestHive() async {
  await Hive.deleteFromDisk();
  final dir = _tempDir;
  if (dir != null && dir.existsSync()) {
    dir.deleteSync(recursive: true);
  }
  _tempDir = null;
}
