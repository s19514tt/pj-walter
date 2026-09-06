import 'package:flutter/material.dart';

import '../../features/composition/domain/drill_result.dart';
import '../../core/language/learning_language.dart';
import '../../features/content/domain/sentence.dart';
import '../../core/domain/token_usage.dart';
import '../../features/composition/domain/tone_note.dart';
import '../../features/speech/domain/tts_service.dart';
import '../../core/domain/app_failure.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../features/composition/domain/pinyin.dart';
import '../../core/utils/score_colors.dart';
import '../../core/utils/word_diff.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bottom_cta_bar.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/secondary_button.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/score_ring.dart';
import '../../core/widgets/speak_button.dart';
import '../../core/widgets/stat_badge.dart';

/// 口頭英作文1問分のGemini添削結果の段階表示。
///
/// 「採点する」押下と同時にこのビューへ遷移し、3段階でコンテンツを埋める：
/// - stage 0（[spoken]=null・[feedback]=null）: 全カードがスケルトン
/// - stage 1（[spoken]あり・[feedback]=null）: 文字起こしカードだけ素の
///   認識テキスト（差分ハイライト・凡例は出さない）。他はスケルトン＋バッジ
/// - stage 2（[feedback]あり）: 全部実データ。フッターの次アクションが出現
///
/// feedbackの`corrected`が空文字（時間切れで回答できなかった場合）は
/// 「あなたの発話」差分カードを非表示にし、模範解答＋tipsを主役として表示する。
///
/// [skipped]（「わからないので飛ばす」で未回答のまま進んだ場合）は、スコア
/// リングの代わりに「未採点」カードを出し、「あなたの発話」の位置には録音が
/// 無かったことの説明を置く。模範解答・解説はそのまま表示する
/// （飛ばしても学べるようにするのが目的で、罰を与える画面にはしない）。
///
/// 中国語（[LanguageProfile.readingLabel]が非null）では、模範解答のピンインと
/// [spokenReading]の音節列が一致し、かつ声調の食い違いが1件以上あるときだけ
/// stage 2で「気づいた点」カードを出す（DESIGN.md「声調フィードバック」の
/// 3つのガード）。それ以外はカードごと出さない（「問題なし」の表示は無い）。
///
/// スコアカードの直下には出題された日本語文（問題文）を常に表示する。採点を
/// 待っている間も何に答えたのかを見失わないようにするため、段階表示の対象外。
/// 「修正版」「模範解答」には[SpeakButton]を置き、[ttsService]（Gemini TTS）で
/// 学習言語の発音を確認できるようにする。読み上げで消費したトークンは
/// [onSpeechUsage]で親に渡し、まとめ画面のコスト表示に含める。
class DrillFeedbackView extends StatefulWidget {
  const DrillFeedbackView({
    super.key,
    required this.sentence,
    required this.spoken,
    required this.feedback,
    required this.onNext,
    required this.onRetry,
    required this.ttsService,
    this.profile = LanguageProfile.english,
    this.spokenReading,
    this.skipped = false,
    this.onSpeechUsage,
    this.isLast = false,
  });

  /// 出題されたSentence
  final Sentence sentence;

  /// 学習言語。英語（`readingLabel == null`）では声調に関わる処理は一切走らない。
  final LanguageProfile profile;

  /// ユーザーの発話の文字起こし。nullは音声認識の完了待ち（stage 0）。
  final String? spoken;

  /// 文字起こしと一緒に返った「聞こえたままの声調付きピンイン」（中国語のみ）。
  final String? spokenReading;

  /// Geminiによる添削結果。nullは採点待ち（stage 0〜1）。
  final CompositionFeedback? feedback;

  /// 「わからないので飛ばす」で未回答のまま進んだ問題かどうか。
  final bool skipped;

  /// 「次の問題へ」（最終問題では「結果を見る」）タップ時のコールバック
  final VoidCallback onNext;

  /// 「もう一度」タップ時のコールバック（同じ問題を録り直す）
  final VoidCallback onRetry;

  /// 「修正版」「模範解答」の読み上げに使う音声合成
  final TtsService ttsService;

  /// 読み上げでGeminiが消費したトークンの通知。
  /// キャッシュから再生した場合は[TokenUsage.zero]なので呼ばれない。
  final void Function(TokenUsage usage)? onSpeechUsage;

  /// 最終問題かどうか（プライマリボタンのラベルに反映）
  final bool isLast;

  @override
  State<DrillFeedbackView> createState() => _DrillFeedbackViewState();
}

class _DrillFeedbackViewState extends State<DrillFeedbackView> {
  /// いま読み上げている文。読み上げていなければnull。
  ///
  /// 「修正版」「模範解答」のどちらのボタンを停止表示にするかの判定に使う。
  String? _speaking;

  @override
  void dispose() {
    // 画面を離れた後に読み上げが続かないようにする（サービス自体の破棄は
    // 生成元のDrillScreenが行う）。
    widget.ttsService.stop();
    super.dispose();
  }

  /// [text]の読み上げをトグルする。読み上げ中の文をもう一度押すと停止する。
  Future<void> _toggleSpeak(String text) async {
    if (_speaking == text) {
      await widget.ttsService.stop();
      if (mounted) setState(() => _speaking = null);
      return;
    }
    setState(() => _speaking = text);
    try {
      final (:usage) = await widget.ttsService.speak(text);
      if (usage != TokenUsage.zero) widget.onSpeechUsage?.call(usage);
    } on AppFailure catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.failureMessage(error.kind.name))),
      );
    } finally {
      // 別の文の読み上げに切り替わっている場合は、そちらの表示を消さない。
      if (mounted && _speaking == text) setState(() => _speaking = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedback = widget.feedback;
    final spoken = widget.spoken;
    final timedOut = feedback != null && feedback.corrected.isEmpty;
    // 声調の気づき。null（未判定）または空（指摘なし）ならカードを出さない。
    // 文字起こしが確定した時点（stage 1）から求まるので、採点を待たずにルビに反映する。
    final toneNotes = timedOut
        ? null
        : toneNotesFor(
            profile: widget.profile,
            sentence: widget.sentence,
            spokenReading: widget.spokenReading,
          );
    final withRuby = widget.profile.hasReading;
    var delayStep = 0;
    Widget staggered(Widget child) {
      final delay = Duration(milliseconds: 60 * delayStep);
      delayStep++;
      return _FadeInCard(delay: delay, child: child);
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // スコアカード: 採点完了（stage 2）まではスケルトン。
              // 飛ばした問題は採点していないので「未採点」カードに差し替える。
              if (widget.skipped)
                const _SkippedCard()
              else if (feedback == null)
                const _ScoreSkeletonCard()
              else
                _ScoreCard(
                  feedback: feedback,
                  toneNoteCount: toneNotes?.length ?? 0,
                ),
              const SizedBox(height: 14),
              // 問題文は採点を待たずに出せるので、段階表示の対象にしない
              _QuestionCard(ja: widget.sentence.ja),
              const SizedBox(height: 12),
              // 文字起こしカード:
              //   stage 0 = スケルトン＋認識中バッジ
              //   stage 1 = 素の認識テキストのみ（差分・凡例なし）
              //   stage 2 = 差分ハイライト＋凡例
              if (widget.skipped) ...[
                staggered(const _NoRecordingCard()),
                const SizedBox(height: 12),
              ] else if (!timedOut) ...[
                if (spoken == null)
                  const SkeletonSectionCard(
                    title: 'あなたの発話（文字起こし）',
                    badge: '認識中',
                  )
                else if (feedback == null)
                  _PlainTranscriptCard(
                    spoken: spoken,
                    withRuby: withRuby,
                    spokenReading: widget.spokenReading,
                    toneNotes: toneNotes ?? const [],
                  )
                else
                  staggered(
                    _DiffCard(
                      spoken: spoken,
                      corrected: feedback.corrected,
                      // 中国語: ルビ（聞き取った読み／修正版の標準ピンイン）と
                      // 声調の気づき（赤ルビ）を重ねる
                      withRuby: withRuby,
                      spokenReading: widget.spokenReading,
                      correctedReading: feedback.correctedReading,
                      // 語区切り（添削応答）。差分のハイライトを1文字ずつでは
                      // なく単語ずつの箱にする
                      spokenWords: feedback.spokenWords,
                      correctedWords: feedback.correctedWords,
                      toneNotes: toneNotes ?? const [],
                      correctedTrailing: SpeakButton(
                        speaking: _speaking == feedback.corrected,
                        onPressed: () => _toggleSpeak(feedback.corrected),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
              ],
              // 気づいた点（声調）: 指摘が1件以上あるときだけ。0件や未判定では
              // カードごと出さない（「声調OK」と受け取られる見せ方をしない）。
              if (feedback != null &&
                  toneNotes != null &&
                  toneNotes.isNotEmpty) ...[
                staggered(_ToneNotesCard(notes: toneNotes)),
                const SizedBox(height: 12),
              ],
              // 模範解答・添削コメント: 採点完了までスケルトン＋AI採点中バッジ
              if (feedback == null)
                const SkeletonSectionCard(title: '模範解答・添削コメント', badge: 'AI採点中')
              else ...[
                staggered(
                  _Section(
                    icon: Icons.menu_book_outlined,
                    title: '模範解答',
                    content: widget.sentence.target,
                    // 中国語: 模範解答のピンインを漢字ごとのルビにする
                    reading: withRuby ? widget.sentence.reading : null,
                    tips: widget.sentence.tips,
                    highlight: timedOut,
                    trailing: SpeakButton(
                      speaking: _speaking == widget.sentence.target,
                      onPressed: () => _toggleSpeak(widget.sentence.target),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                staggered(
                  _Section(
                    icon: Icons.lightbulb_outline,
                    title: '解説',
                    content: feedback.explanation,
                  ),
                ),
                if (feedback.comparison.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  staggered(
                    _Section(
                      icon: Icons.compare_arrows,
                      title: '模範解答との比較',
                      content: feedback.comparison,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
        // フッターの次アクションは採点完了（stage 2）で出現する。
        // カードの段階表示とフッターのゲートは必ずセット（片方だけ隠さない）。
        if (feedback != null)
          BottomCtaBar(
            child: Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'もう一度',
                    onPressed: widget.onRetry,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: PrimaryButton(
                    label: widget.isLast ? '結果を見る' : '次の問題へ',
                    onPressed: widget.onNext,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// スコアリング＋判定＋総評のカード（stage 2）。
class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.feedback, this.toneNoteCount = 0});

  final CompositionFeedback feedback;

  /// 声調の気づきの件数（中国語のみ）。1件以上なら総評の一文で赤ルビへ誘導する
  final int toneNoteCount;

  @override
  Widget build(BuildContext context) {
    final color = scoreColor(feedback.score);
    // デザインの3段階判定。合否ライン（70点・SRS登録条件）はisAcceptableに従う
    final (verdict, verdictSurface, defaultHeadline) = feedback.isAcceptable
        ? ('合格', AppColors.scoreGoodSurface, 'よくできました。この調子で次へ進みましょう。')
        : feedback.score >= 50
        ? ('あと少し', AppColors.scoreMediumSurface, '惜しい！解説を確認して仕上げましょう。')
        : ('要復習', AppColors.scoreLowSurface, '復習キューに登録されます。模範解答を確認しましょう。');
    // 声調の気づきがあるときは、デザインの総評と同様に声調へ誘導する一文にする。
    // 気づきが無いときに「声調は問題ありません」とは言わない（見逃しがそのまま嘘になる）。
    final headline = toneNoteCount > 0
        ? '声調が違って聞こえた音節が$toneNoteCountつあります。赤いルビを確認しましょう。'
        : defaultHeadline;
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          ScoreRing(score: feedback.score, size: 116),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatBadge(
                  label: verdict,
                  surfaceColor: verdictSurface,
                  textColor: color,
                ),
                const SizedBox(height: 8),
                Text(
                  headline,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.7,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 「わからないので飛ばす」で未回答のまま進んだ問題の、スコアカード相当。
///
/// スコアは付けていないので数字は出さず、グレーの「未採点」表示にする。
/// 復習キューに入ったことをここで伝え、模範解答・解説へ目を向けさせる。
class _SkippedCard extends StatelessWidget {
  const _SkippedCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 116,
            height: 116,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.pageBackground,
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.do_not_disturb_on_outlined,
                  size: 28,
                  color: Color(0xFFB9BDC4),
                ),
                SizedBox(height: 7),
                Text(
                  '未採点',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF9AA0A6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StatBadge(
                  label: 'この問題は飛ばしました',
                  surfaceColor: Color(0xFFF0F1F3),
                  textColor: Color(0xFF5F6368),
                ),
                const SizedBox(height: 8),
                Text(
                  '模範解答と解説を確認しましょう。この問題は復習キューに登録されました。',
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.7,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 飛ばした問題の「あなたの発話」カード（録音が無いことの説明）。
class _NoRecordingCard extends StatelessWidget {
  const _NoRecordingCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(
            icon: Icons.mic_off_outlined,
            title: 'あなたの発話',
            muted: true,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 17, color: Color(0xFF9AA0A6)),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    '録音がないため、文字起こしと修正版はありません。次に同じ問題が出たときは、'
                    '模範解答をまねて声に出すところから始めましょう。',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.8,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// スコアカードのスケルトン（リング位置に円プレースホルダー）。
class _ScoreSkeletonCard extends StatelessWidget {
  const _ScoreSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 116,
            height: 116,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFEDEEF1),
            ),
          ),
          const SizedBox(width: 18),
          const Expanded(child: SkeletonParagraph(widths: [0.45, 1, 0.7])),
        ],
      ),
    );
  }
}

/// stage 1の文字起こしカード。素の認識テキストのみ（差分・凡例は出さない）。
class _PlainTranscriptCard extends StatelessWidget {
  const _PlainTranscriptCard({
    required this.spoken,
    this.withRuby = false,
    this.spokenReading,
    this.toneNotes = const [],
  });

  final String spoken;

  /// 中国語: 聞き取った読みを漢字ごとのルビにする（声調の気づきは赤ルビ）
  final bool withRuby;
  final String? spokenReading;
  final List<ToneNote> toneNotes;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'あなたの発話（文字起こし）',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const ProgressBadge(label: 'AI採点中'),
            ],
          ),
          const SizedBox(height: 8),
          if (withRuby)
            _RubyDiffText(
              segments: diffWords(spoken, spoken),
              reading: spokenReading,
              toneNotes: toneNotes,
              changedColor: AppColors.scoreLow,
              changedBackground: AppColors.scoreLowSurface,
            )
          else
            Text(
              spoken,
              style: const TextStyle(
                fontSize: 15,
                height: 1.8,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
        ],
      ),
    );
  }
}

/// [delay]経過後に300msでフェード＋わずかな上方向スライドで出現するカード。
class _FadeInCard extends StatefulWidget {
  const _FadeInCard({required this.delay, required this.child});

  final Duration delay;
  final Widget child;

  @override
  State<_FadeInCard> createState() => _FadeInCardState();
}

class _FadeInCardState extends State<_FadeInCard> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      offset: _visible ? Offset.zero : const Offset(0, 0.08),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: _visible ? 1 : 0,
        child: widget.child,
      ),
    );
  }
}

/// アイコン＋ラベルの小見出し（14px bold、アイコンはオレンジ、8px間隔）。
///
/// [trailing]を渡すと行の右端に寄せて並べる（読み上げボタンなど）。
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.icon,
    required this.title,
    this.trailing,
    this.muted = false,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;

  /// 中身が無いカードの見出し（アイコン・文字をグレーに落とす）
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final trailing = this.trailing;
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: muted ? const Color(0xFFB9BDC4) : AppColors.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: muted ? AppColors.textSecondary : AppColors.textPrimary,
          ),
        ),
        if (trailing != null) ...[const Spacer(), trailing],
      ],
    );
  }
}

/// 出題された日本語文（問題文）のカード。
///
/// 添削結果を見ている間も何に対する回答だったのかが分かるように、
/// スコアカードのすぐ下に置く。
class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.ja});

  final String ja;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(icon: Icons.help_outline, title: '問題文'),
          const SizedBox(height: 8),
          Text(
            ja,
            style: const TextStyle(
              fontSize: 16,
              height: 1.7,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 「あなたの発話 → 修正版」を1枚のカードに統合した差分表示。
///
/// 上段に発話（削除/変更された語をグレー＋取り消し線）、下段に修正版
/// （primarySurface背景、追加/変更された語をオレンジ太字）を表示する。
/// 差分が無い（完全一致）場合は下段の代わりに「修正なし」メッセージを
/// good色（[AppColors.success]）で表示する。
class _DiffCard extends StatelessWidget {
  const _DiffCard({
    required this.spoken,
    required this.corrected,
    this.withRuby = false,
    this.spokenReading,
    this.correctedReading,
    this.spokenWords,
    this.correctedWords,
    this.toneNotes = const [],
    this.correctedTrailing,
  });

  final String spoken;
  final String corrected;

  /// 漢字ごとにピンインのルビを付けるか（中国語のみ）
  final bool withRuby;

  /// 音声認識が聞き取った読み（あなたの発話のルビ。参考値）
  final String? spokenReading;

  /// 修正版の標準ピンイン（修正版のルビ）
  final String? correctedReading;

  /// あなたの発話の語区切り（差分のハイライトを単語ずつの箱にする）
  final List<WordUnit>? spokenWords;

  /// 修正版の語区切り＋語ごとのピンイン（箱を単語ずつにし、ルビも語ごとに割り当てる）
  final List<WordUnit>? correctedWords;

  /// 声調の気づき。該当する漢字のルビを赤にし、下に期待された声調を添える
  final List<ToneNote> toneNotes;

  /// 「修正版」見出しの右端に置くウィジェット（読み上げボタン）。
  /// 差分が無く修正版セクションを出さない場合は使わない。
  final Widget? correctedTrailing;

  @override
  Widget build(BuildContext context) {
    final diff = diffWords(spoken, corrected);
    final hasChanges = diff.any((s) => s.type != DiffSegmentType.same);
    final spokenSegments = diff
        .where((s) => s.type != DiffSegmentType.added)
        .toList();
    final correctedSegments = diff
        .where((s) => s.type != DiffSegmentType.removed)
        .toList();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(
            icon: Icons.record_voice_over_outlined,
            title: 'あなたの発話',
          ),
          const SizedBox(height: 8),
          if (withRuby)
            _RubyDiffText(
              segments: spokenSegments,
              reading: spokenReading,
              words: spokenWords,
              toneNotes: toneNotes,
              changedColor: AppColors.scoreLow,
              changedBackground: AppColors.scoreLowSurface,
              changedDecoration: TextDecoration.lineThrough,
            )
          else
            _DiffText(
              segments: spokenSegments,
              changedColor: AppColors.scoreLow,
              changedBackground: AppColors.scoreLowSurface,
              changedDecoration: TextDecoration.lineThrough,
            ),
          const SizedBox(height: 16),
          if (hasChanges)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel(
                    icon: Icons.edit,
                    title: '修正版',
                    trailing: correctedTrailing,
                  ),
                  const SizedBox(height: 8),
                  if (withRuby)
                    _RubyDiffText(
                      segments: correctedSegments,
                      reading: correctedReading,
                      words: correctedWords,
                      changedColor: AppColors.scoreGood,
                      changedBackground: AppColors.scoreGoodSurface,
                    )
                  else
                    _DiffText(
                      segments: correctedSegments,
                      changedColor: AppColors.scoreGood,
                      changedBackground: AppColors.scoreGoodSurface,
                      changedWeight: FontWeight.bold,
                    ),
                ],
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '修正なし！そのままでOKです 🎉',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
          const Row(
            children: [
              _LegendSwatch(
                fill: AppColors.scoreLowSurface,
                border: Color(0xFFF3B4B4),
                label: '削除・誤り',
              ),
              SizedBox(width: 14),
              _LegendSwatch(
                fill: AppColors.scoreGoodSurface,
                border: Color(0xFF9AD9BC),
                label: '修正版の表現',
              ),
            ],
          ),
          // 声調の気づきがある場合だけ赤ルビの読み方を添える（デザインの注記）。
          // 「声調OK」のような肯定的な断定は出さない。
          if (withRuby && toneNotes.isNotEmpty) ...[
            const SizedBox(height: 6),
            const Text(
              '赤字のルビは上＝実際の声調（参考値）／下＝期待された声調',
              style: TextStyle(
                fontSize: 11,
                height: 1.6,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// [DiffSegment]列を、漢字ごとに「ピンインのルビ＋漢字」のセルとして描画する
/// （中国語用。デザイン `SpeakingApp-Chinese` のルビ表示）。
///
/// ルビは[words]（語ごとのピンイン）があれば語ごとに、無ければ[reading]を
/// 文全体で各漢字に割り当てる（`utils/pinyin.dart`）。漢字数と音節数が
/// 合わない範囲はルビ無しで漢字だけを並べる（位置のずれたルビを出さない）。
///
/// 差分のある文字は[changedColor]／[changedBackground]で強調し、隣り合う
/// 差分は1つの箱にまとめる（[groupDiffSegments]。[words]があれば単語ずつ、
/// 無ければ連続する差分ごと）。[toneNotes]に該当する文字はルビを赤にして
/// 下段に期待された声調を添える。
class _RubyDiffText extends StatelessWidget {
  const _RubyDiffText({
    required this.segments,
    required this.reading,
    required this.changedColor,
    required this.changedBackground,
    this.words,
    this.toneNotes = const [],
    this.changedDecoration,
  });

  final List<DiffSegment> segments;
  final String? reading;

  /// この側の文の語区切り（中国語の添削応答が返す。無ければ null）。
  /// 差分の箱を単語ずつに切るのと、修正版のルビの割り当てに使う。
  final List<WordUnit>? words;

  final Color changedColor;
  final Color changedBackground;
  final List<ToneNote> toneNotes;
  final TextDecoration? changedDecoration;

  @override
  Widget build(BuildContext context) {
    final tokens = segments.map((s) => s.text).toList();
    final words = this.words;
    final reading = this.reading;
    // 語ごとのピンインがあるときはそちらを優先する（合わない語だけルビが
    // 落ちる）。無い・使えないときだけ文全体のピンインで割り当てる。
    final readings =
        (words == null
            ? null
            : alignWordReadings(tokens: tokens, words: words)) ??
        (reading == null
            ? null
            : alignReading(tokens: tokens, reading: reading));
    // あなたの発話のルビは聞き取ったピンインの音節位置（spokenIndex）で引く
    final notesBySyllable = {for (final n in toneNotes) n.spokenIndex: n};
    final groups = groupDiffSegments(
      segments,
      words: words?.map((w) => w.text).toList(),
    );

    // セルの描画情報を先に組み立てる。隣のセルが同じ箱（同じまとまり・同じ
    // 背景色）かどうかで角丸と隙間を決め、単語ぶんの箱を1つに繋ぐ。
    final cells = <_RubyCellSpec>[];
    var index = 0;
    for (var group = 0; group < groups.length; group++) {
      for (final segment in groups[group].segments) {
        final ruby = readings?[index];
        cells.add(
          _spec(
            group: group,
            segment: segment,
            ruby: ruby,
            note: ruby == null ? null : notesBySyllable[ruby.syllableIndex],
          ),
        );
        index++;
      }
    }

    bool joined(int left, int right) =>
        left >= 0 &&
        right < cells.length &&
        cells[left].background != null &&
        cells[left].group == cells[right].group &&
        cells[left].background == cells[right].background;

    // 上揃え: ルビ行の高さは全セル同じなので漢字が横一列に揃う。
    // 期待声調の下段があるセルだけ下にぶら下がる（他の漢字を持ち上げない）。
    return Wrap(
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: [
        for (var i = 0; i < cells.length; i++)
          cells[i].toCell(
            joinLeft: joined(i - 1, i),
            joinRight: joined(i, i + 1),
          ),
      ],
    );
  }

  _RubyCellSpec _spec({
    required int group,
    required DiffSegment segment,
    required TokenReading? ruby,
    required ToneNote? note,
  }) {
    // 句読点だけのセル（「。」など）は差分があっても強調しない（空の色セルになるため）
    final changed =
        segment.type != DiffSegmentType.same && isCjkCharacter(segment.text);
    // 声調の気づきがある文字: 上のルビ（聞こえた声調）を赤に、下に期待声調
    final toneMismatch = note != null;
    final rubyColor = toneMismatch
        ? AppColors.scoreLow
        : changed
        ? changedColor
        : AppColors.textSecondary;
    return _RubyCellSpec(
      group: group,
      text: segment.text,
      ruby: ruby?.reading,
      rubyColor: rubyColor,
      rubyBelow: toneMismatch ? _rubyBelow(note, ruby!) : null,
      textColor: changed ? changedColor : AppColors.textPrimary,
      background: changed || toneMismatch
          ? (toneMismatch ? AppColors.scoreLowSurface : changedBackground)
          : null,
      decoration: changed ? changedDecoration : null,
    );
  }

  /// 期待された声調のルビ。儿化で「儿」側のセルには `r` のみ表示する。
  String _rubyBelow(ToneNote note, TokenReading ruby) {
    if (ruby.reading == 'r') return 'r';
    final expected = note.expected;
    // 儿化の本体側（diǎn）には期待側の r を除いた読みを付ける
    if (ruby.reading.length < note.actual.length &&
        note.actual.endsWith('r') &&
        expected.endsWith('r')) {
      return expected.substring(0, expected.length - 1);
    }
    return expected;
  }
}

/// [_RubyDiffText]が組み立てるセル1つ分の描画情報。
///
/// [group]が同じで背景色も同じセルが隣り合うときは、間の隙間を詰めて
/// 角丸を外側だけに寄せ、1つの箱（＝単語ぶんのハイライト）に見せる。
@immutable
class _RubyCellSpec {
  const _RubyCellSpec({
    required this.group,
    required this.text,
    required this.ruby,
    required this.rubyColor,
    required this.rubyBelow,
    required this.textColor,
    required this.background,
    required this.decoration,
  });

  /// 同じ箱にまとめる単位（[groupDiffSegments]が返すまとまりの添字）
  final int group;

  final String text;
  final String? ruby;
  final Color rubyColor;
  final String? rubyBelow;
  final Color textColor;
  final Color? background;
  final TextDecoration? decoration;

  /// 隣のセルと箱を繋ぐかどうかを受け取ってセルを組み立てる。
  Widget toCell({required bool joinLeft, required bool joinRight}) => _RubyCell(
    text: text,
    ruby: ruby,
    rubyColor: rubyColor,
    rubyBelow: rubyBelow,
    textColor: textColor,
    background: background,
    decoration: decoration,
    borderRadius: BorderRadius.horizontal(
      left: Radius.circular(joinLeft ? 0 : 4),
      right: Radius.circular(joinRight ? 0 : 4),
    ),
    gapAfter: joinRight ? 0 : 2,
  );
}

/// ピンインのルビ付き1文字分。ルビ（上）・漢字・期待声調（下、任意）を縦に並べる。
class _RubyCell extends StatelessWidget {
  const _RubyCell({
    required this.text,
    required this.ruby,
    required this.rubyColor,
    required this.textColor,
    this.rubyBelow,
    this.background,
    this.decoration,
    this.borderRadius = const BorderRadius.all(Radius.circular(4)),
    this.gapAfter = 0,
  });

  final String text;
  final String? ruby;
  final Color rubyColor;
  final String? rubyBelow;
  final Color textColor;
  final Color? background;
  final TextDecoration? decoration;

  /// 背景の角丸。隣のセルと同じ箱に繋げる側は0にする
  final BorderRadius borderRadius;

  /// 右隣のセルとの隙間。同じ箱に繋げるときは0にして背景を途切れさせない
  final double gapAfter;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(right: gapAfter),
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      decoration: background == null
          ? null
          : BoxDecoration(color: background, borderRadius: borderRadius),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ルビの無い文字（句読点など）も高さを揃えるため空行を置く
          Text(
            ruby ?? ' ',
            style: TextStyle(
              fontSize: 10,
              height: 1.4,
              fontWeight: FontWeight.w500,
              color: rubyColor,
            ),
          ),
          Text(
            text,
            style: TextStyle(
              fontSize: 17,
              height: 1.3,
              fontWeight: FontWeight.bold,
              color: textColor,
              decoration: decoration,
              decorationColor: textColor,
            ),
          ),
          if (rubyBelow != null)
            Text(
              rubyBelow!,
              style: const TextStyle(
                fontSize: 10,
                height: 1.4,
                fontWeight: FontWeight.bold,
                color: AppColors.scoreGood,
              ),
            ),
        ],
      ),
    );
  }
}

/// 差分の無いテキストを漢字ごとのルビ付きで描画する（模範解答用）。
class _RubyText extends StatelessWidget {
  const _RubyText({
    required this.text,
    required this.reading,
    required this.textColor,
  });

  final String text;
  final String reading;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final tokens = diffWords(text, text).map((s) => s.text).toList();
    final readings = alignReading(tokens: tokens, reading: reading);
    // 上揃え: ルビ行の高さは全セル同じなので漢字が横一列に揃う。
    // 期待声調の下段があるセルだけ下にぶら下がる（他の漢字を持ち上げない）。
    return Wrap(
      spacing: 2,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: [
        for (var i = 0; i < tokens.length; i++)
          _RubyCell(
            text: tokens[i],
            ruby: readings?[i]?.reading,
            rubyColor: AppColors.textSecondary,
            textColor: textColor,
          ),
      ],
    );
  }
}

/// 差分表示の凡例（色見本＋ラベル）。
class _LegendSwatch extends StatelessWidget {
  const _LegendSwatch({
    required this.fill,
    required this.border,
    required this.label,
  });

  final Color fill;
  final Color border;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: fill,
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

/// [DiffSegment]列を1つのテキストとして描画する。差分がある単語だけ
/// [changedColor]／[changedWeight]／[changedDecoration]を適用し、それ以外は
/// 通常のスタイルで表示する。単語間は半角スペース1つで繋ぐ。
class _DiffText extends StatelessWidget {
  const _DiffText({
    required this.segments,
    required this.changedColor,
    this.changedBackground,
    this.changedWeight = FontWeight.normal,
    this.changedDecoration,
  });

  final Iterable<DiffSegment> segments;
  final Color changedColor;
  final Color? changedBackground;
  final FontWeight changedWeight;
  final TextDecoration? changedDecoration;

  @override
  Widget build(BuildContext context) {
    final list = segments.toList();
    final spans = <InlineSpan>[];
    for (var i = 0; i < list.length; i++) {
      final segment = list[i];
      final changed = segment.type != DiffSegmentType.same;
      spans.add(
        TextSpan(
          text: segment.text,
          style: TextStyle(
            color: changed ? changedColor : AppColors.textPrimary,
            backgroundColor: changed ? changedBackground : null,
            fontWeight: changed ? changedWeight : FontWeight.normal,
            decoration: changed ? changedDecoration : null,
            decorationColor: changedColor,
          ),
        ),
      );
      if (i != list.length - 1) {
        spans.add(const TextSpan(text: ' '));
      }
    }
    return Text.rich(
      TextSpan(children: spans),
      style: const TextStyle(fontSize: 15),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.content,
    this.reading,
    this.tips,
    this.highlight = false,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String content;

  /// [content]のピンイン（中国語の模範解答）。指定時は漢字ごとのルビ付きで描画する
  final String? reading;

  final String? tips;
  final bool highlight;

  /// 見出し行の右端に置くウィジェット（読み上げボタン）
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: highlight ? AppColors.primarySurface : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(icon: icon, title: title, trailing: trailing),
          const SizedBox(height: 8),
          if (reading != null)
            _RubyText(
              text: content,
              reading: reading!,
              textColor: highlight ? AppColors.primary : AppColors.textPrimary,
            )
          else
            Text(
              content,
              style: TextStyle(
                fontSize: highlight ? 17 : 15,
                fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
                color: highlight ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          if (tips != null && tips!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.pageBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tips!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 「気づいた点」カード（口頭中国語作文のみ、stage 2）。
///
/// 模範解答のピンインと綴りは同じで声調だけが違った音節を控えめに列挙する。
/// 「声調チェック」「声調OK」といった断定的な語は使わない。音声認識の聞き取り
/// 誤差も混ざるため、参考値であることを補足文で明示する。
class _ToneNotesCard extends StatelessWidget {
  const _ToneNotesCard({required this.notes});

  final List<ToneNote> notes;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(icon: Icons.hearing, title: '気づいた点'),
          const SizedBox(height: 8),
          const Text(
            '音声認識が聞き取った声調（参考値）が模範解答のピンインと違っていた音節です。聞き取りの誤差も含まれます。',
            style: TextStyle(
              fontSize: 12,
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < notes.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _ToneNoteRow(note: notes[i]),
          ],
        ],
      ),
    );
  }
}

/// 気づいた点1件分の行: `[3声 → 4声]` ピル＋（漢字）＋ 模範解答の音節 → 聞こえた音節。
class _ToneNoteRow extends StatelessWidget {
  const _ToneNoteRow({required this.note});

  final ToneNote note;

  @override
  Widget build(BuildContext context) {
    final hanzi = note.hanzi;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.scoreLowSurface,
            borderRadius: BorderRadius.circular(AppTheme.pillRadius),
          ),
          child: Text(
            '${note.expectedTone}声 → ${note.actualTone}声',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.scoreLow,
            ),
          ),
        ),
        const SizedBox(width: 10),
        if (hanzi != null) ...[
          Text(
            hanzi,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: note.expected,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const TextSpan(
                  text: '  →  ',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                TextSpan(
                  text: note.actual,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.scoreLow,
                  ),
                ),
              ],
            ),
            style: const TextStyle(fontSize: 15),
          ),
        ),
      ],
    );
  }
}
