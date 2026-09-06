import 'package:flutter/foundation.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// 画面（またはアプリ）スコープの状態を持つ Store の基底クラス。
///
/// signals のライフサイクル規約（DESIGN.md「signals のライフサイクル規約」）を
/// 型で強制するためのもの:
///
/// - signal / computed / effect / FutureSignal は必ず [createSignal] /
///   [createComputed] / [createEffect] / [createFutureSignal] で作る。
///   ここで作ったものは Store に登録され、[dispose] で一括破棄される
/// - 画面スコープの Store は `State.initState` で生成し、`State.dispose` で
///   必ず [dispose] を呼ぶ。`build` の中で Store や signal を作らない
/// - Timer や録音サービスのような外部リソースも [addDisposer] で登録し、
///   [dispose] で解放する
///
/// Store は `BuildContext` を保持しない。ナビゲーションや SnackBar は画面側が
/// Store のメソッドの戻り値や signal の変化を受けて行う。
abstract class Store {
  final _disposers = <void Function()>[];
  bool _disposed = false;

  /// [dispose] 済みかどうか（テストでの検証用）
  bool get disposed => _disposed;

  /// Store の寿命に紐づく signal を作る。
  @protected
  Signal<T> createSignal<T>(T value, {String? name}) {
    _checkNotDisposed();
    final s = signal<T>(value, options: SignalOptions<T>(name: name));
    _disposers.add(s.dispose);
    return s;
  }

  /// Store の寿命に紐づく computed を作る。
  @protected
  Computed<T> createComputed<T>(T Function() compute, {String? name}) {
    _checkNotDisposed();
    final c = computed<T>(compute, options: ComputedOptions<T>(name: name));
    _disposers.add(c.dispose);
    return c;
  }

  /// Store の寿命に紐づく effect を張る。cleanup は [dispose] で呼ばれる。
  @protected
  void createEffect(void Function() fn, {String? name}) {
    _checkNotDisposed();
    final cleanup = effect(fn, options: EffectOptions(name: name));
    _disposers.add(cleanup);
  }

  /// Store の寿命に紐づく [FutureSignal] を作る。
  ///
  /// 非同期の読み込み状態（loading / data / error）はこれで表し、画面に
  /// bool を手書きしない。[dependencies] の signal が変わると loading に戻して
  /// [fn] を実行し直す（[fn] の中では依存 signal を `peek()` で読む）。
  ///
  /// signals_core 7 の `AsyncSignalOptions.dependencies` は初期値が null の
  /// signal の最初の変化を無視するため使わず、ここで effect を張って `reset()` する。
  @protected
  FutureSignal<T> createFutureSignal<T>(
    Future<T> Function() fn, {
    List<ReadonlySignal<dynamic>> dependencies = const [],
    bool lazy = true,
    String? name,
  }) {
    _checkNotDisposed();
    final f = FutureSignal<T>(
      fn,
      options: AsyncSignalOptions<T>(lazy: lazy, name: name),
    );
    _disposers.add(f.dispose);
    if (dependencies.isNotEmpty) {
      var first = true;
      createEffect(() {
        for (final dependency in dependencies) {
          dependency.value;
        }
        if (first) {
          first = false;
          return;
        }
        untracked(f.reset);
      }, name: name == null ? null : '$name.dependencies');
    }
    return f;
  }

  /// signal 以外のリソース（Timer・サービス等）の解放処理を登録する。
  @protected
  void addDisposer(void Function() dispose) {
    _checkNotDisposed();
    _disposers.add(dispose);
  }

  /// 登録されたものを生成の逆順に破棄する。二重呼び出しは無視する。
  @mustCallSuper
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final d in _disposers.reversed) {
      d();
    }
    _disposers.clear();
  }

  void _checkNotDisposed() {
    assert(!_disposed, '$runtimeType is already disposed');
  }
}
