import 'package:flutter/material.dart';

import '../../models/drill_result.dart';
import '../../models/learning_language.dart';
import '../../models/sentence.dart';
import '../../models/tone_note.dart';
import '../../theme/app_theme.dart';
import '../../utils/pinyin.dart';
import '../../utils/score_colors.dart';
import '../../utils/word_diff.dart';
import '../../widgets/app_card.dart';
import '../../widgets/bottom_cta_bar.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/secondary_button.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/score_ring.dart';
import '../../widgets/stat_badge.dart';

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
/// 中国語（[LanguageProfile.readingLabel]が非null）では、模範解答のピンインと
/// [spokenReading]の音節列が一致し、かつ声調の食い違いが1件以上あるときだけ
/// stage 2で「気づいた点」カードを出す（DESIGN.md「声調フィードバック」の
/// 3つのガード）。それ以外はカードごと出さない（「問題なし」の表示は無い）。
class DrillFeedbackView extends StatelessWidget {
  const DrillFeedbackView({
    super.key,
    required this.sentence,
    required this.spoken,
    required this.feedback,
    required this.onNext,
    required this.onRetry,
    this.profile = LanguageProfile.english,
    this.spokenReading,
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

  /// 「次の問題へ」（最終問題では「結果を見る」）タップ時のコールバック
  final VoidCallback onNext;

  /// 「もう一度」タップ時のコールバック（同じ問題を録り直す）
  final VoidCallback onRetry;

  /// 最終問題かどうか（プライマリボタンのラベルに反映）
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final feedback = this.feedback;
    final spoken = this.spoken;
    final timedOut = feedback != null && feedback.corrected.isEmpty;
    // 声調の気づき。null（未判定）または空（指摘なし）ならカードを出さない。
    // 文字起こしが確定した時点（stage 1）から求まるので、採点を待たずにルビに反映する。
    final toneNotes = timedOut
        ? null
        : toneNotesFor(
            profile: profile,
            sentence: sentence,
            spokenReading: spokenReading,
          );
    final withRuby = profile.readingLabel != null;
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
              // スコアカード: 採点完了（stage 2）まではスケルトン
              if (feedback == null)
                const _ScoreSkeletonCard()
              else
                _ScoreCard(
                  feedback: feedback,
                  toneNoteCount: toneNotes?.length ?? 0,
                ),
              const SizedBox(height: 14),
              // 文字起こしカード:
              //   stage 0 = スケルトン＋認識中バッジ
              //   stage 1 = 素の認識テキストのみ（差分・凡例なし）
              //   stage 2 = 差分ハイライト＋凡例
              if (!timedOut) ...[
                if (spoken == null)
                  const SkeletonSectionCard(
                    title: 'あなたの発話（文字起こし）',
                    badge: '認識中',
                  )
                else if (feedback == null)
                  _PlainTranscriptCard(
                    spoken: spoken,
                    withRuby: withRuby,
                    spokenReading: spokenReading,
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
                      spokenReading: spokenReading,
                      correctedReading: feedback.correctedReading,
                      toneNotes: toneNotes ?? const [],
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
                    content: sentence.target,
                    // 中国語: 模範解答のピンインを漢字ごとのルビにする
                    reading: withRuby ? sentence.reading : null,
                    tips: sentence.tips,
                    highlight: timedOut,
                  ),
                ),
                const SizedBox(height: 12),
                staggered(
                  _Section(
                    icon: Icons.lightbulb_outline,
                    title: '解説',
                    content: feedback.explanationJa,
                  ),
                ),
                if (feedback.comparisonJa.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  staggered(
                    _Section(
                      icon: Icons.compare_arrows,
                      title: '模範解答との比較',
                      content: feedback.comparisonJa,
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
                  child: SecondaryButton(label: 'もう一度', onPressed: onRetry),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: PrimaryButton(
                    label: isLast ? '結果を見る' : '次の問題へ',
                    onPressed: onNext,
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
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
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
    this.toneNotes = const [],
  });

  final String spoken;
  final String corrected;

  /// 漢字ごとにピンインのルビを付けるか（中国語のみ）
  final bool withRuby;

  /// 音声認識が聞き取った読み（あなたの発話のルビ。参考値）
  final String? spokenReading;

  /// 修正版の標準ピンイン（修正版のルビ）
  final String? correctedReading;

  /// 声調の気づき。該当する漢字のルビを赤にし、下に期待された声調を添える
  final List<ToneNote> toneNotes;

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
                  const _SectionLabel(icon: Icons.edit, title: '修正版'),
                  const SizedBox(height: 8),
                  if (withRuby)
                    _RubyDiffText(
                      segments: correctedSegments,
                      reading: correctedReading,
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
/// [reading]の音節を[alignReading]で各漢字に割り当てる。漢字数と音節数が
/// 合わない場合はルビ無しで漢字だけを並べる（位置のずれたルビを出さない）。
/// 差分のある文字は[changedColor]／[changedBackground]で強調し、
/// [toneNotes]に該当する文字はルビを赤にして下段に期待された声調を添える。
class _RubyDiffText extends StatelessWidget {
  const _RubyDiffText({
    required this.segments,
    required this.reading,
    required this.changedColor,
    required this.changedBackground,
    this.toneNotes = const [],
    this.changedDecoration,
  });

  final List<DiffSegment> segments;
  final String? reading;
  final Color changedColor;
  final Color changedBackground;
  final List<ToneNote> toneNotes;
  final TextDecoration? changedDecoration;

  @override
  Widget build(BuildContext context) {
    final tokens = segments.map((s) => s.text).toList();
    final readings = reading == null
        ? null
        : alignReading(tokens: tokens, reading: reading!);
    // あなたの発話のルビは聞き取ったピンインの音節位置（spokenIndex）で引く
    final notesBySyllable = {for (final n in toneNotes) n.spokenIndex: n};

    // 上揃え: ルビ行の高さは全セル同じなので漢字が横一列に揃う。
    // 期待声調の下段があるセルだけ下にぶら下がる（他の漢字を持ち上げない）。
    return Wrap(
      spacing: 2,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: [
        for (var i = 0; i < segments.length; i++)
          _rubyCell(
            segment: segments[i],
            ruby: readings?[i],
            note: readings?[i] == null
                ? null
                : notesBySyllable[readings![i]!.syllableIndex],
          ),
      ],
    );
  }

  Widget _rubyCell({
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
    return _RubyCell(
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
  });

  final String text;
  final String? ruby;
  final Color rubyColor;
  final String? rubyBelow;
  final Color textColor;
  final Color? background;
  final TextDecoration? decoration;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      decoration: background == null
          ? null
          : BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(4),
            ),
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
  });

  final IconData icon;
  final String title;
  final String content;

  /// [content]のピンイン（中国語の模範解答）。指定時は漢字ごとのルビ付きで描画する
  final String? reading;

  final String? tips;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: highlight ? AppColors.primarySurface : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(icon: icon, title: title),
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
