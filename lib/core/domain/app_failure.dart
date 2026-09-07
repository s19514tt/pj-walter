/// アプリ内で起きる、ユーザーに伝えるべき失敗の種類。
///
/// Repository / Service は表示文言を持たず [AppFailure] に種類だけを載せて投げる。
/// UI が `context.l10n.failureMessage(kind.name)`（ARB の select）で文言に変換する。
/// 実装（Gemini 直叩き／将来のサーバ呼び出し）を問わず同じ種類を使う。
enum FailureKind {
  /// API キーが未設定（次フェーズでサーバに集約されると消える）
  apiKeyMissing,

  /// API キーが無効（401 / 403）
  apiKeyInvalid,

  /// レート制限（429）
  rateLimited,

  /// リクエスト不正（400）
  badRequest,

  /// サーバ側のエラー（5xx）
  serverError,

  /// 上記以外の HTTP ステータス
  unexpectedStatus,

  /// タイムアウト
  timeout,

  /// ネットワーク到達不可などの通信エラー
  network,

  /// 応答を解析できない
  invalidResponse,

  /// 本文が空の応答が続いた（再試行しても結果が返らない）
  emptyResponse,

  /// 聞き取れる発話が無かった（録音が空・無音マーカー）
  noSpeech,

  /// 読み上げ音声が返らなかった
  noAudio,

  /// マイク権限が無い
  micPermission,

  /// 端末で音声を再生できない
  playback,
}

/// ユーザーに伝えるべき失敗。[kind] を UI が文言に変換する。
///
/// [detail] はログ・デバッグ用の補足（HTTP ステータスなど）で、UI には出さない。
class AppFailure implements Exception {
  const AppFailure(this.kind, {this.detail});

  final FailureKind kind;
  final String? detail;

  @override
  String toString() =>
      'AppFailure(${kind.name}${detail == null ? '' : ': $detail'})';
}
