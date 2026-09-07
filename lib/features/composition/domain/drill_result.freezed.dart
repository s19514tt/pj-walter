// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'drill_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WordUnit {

/// 語の表記（句読点だけの語もある）
 String get text;/// その語の標準的なピンイン（音節ごとに半角スペース区切り）。発話側は null
 String? get reading;
/// Create a copy of WordUnit
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WordUnitCopyWith<WordUnit> get copyWith => _$WordUnitCopyWithImpl<WordUnit>(this as WordUnit, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WordUnit&&(identical(other.text, text) || other.text == text)&&(identical(other.reading, reading) || other.reading == reading));
}


@override
int get hashCode => Object.hash(runtimeType,text,reading);

@override
String toString() {
  return 'WordUnit(text: $text, reading: $reading)';
}


}

/// @nodoc
abstract mixin class $WordUnitCopyWith<$Res>  {
  factory $WordUnitCopyWith(WordUnit value, $Res Function(WordUnit) _then) = _$WordUnitCopyWithImpl;
@useResult
$Res call({
 String text, String? reading
});




}
/// @nodoc
class _$WordUnitCopyWithImpl<$Res>
    implements $WordUnitCopyWith<$Res> {
  _$WordUnitCopyWithImpl(this._self, this._then);

  final WordUnit _self;
  final $Res Function(WordUnit) _then;

/// Create a copy of WordUnit
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? text = null,Object? reading = freezed,}) {
  return _then(_self.copyWith(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,reading: freezed == reading ? _self.reading : reading // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [WordUnit].
extension WordUnitPatterns on WordUnit {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WordUnit value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WordUnit() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WordUnit value)  $default,){
final _that = this;
switch (_that) {
case _WordUnit():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WordUnit value)?  $default,){
final _that = this;
switch (_that) {
case _WordUnit() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String text,  String? reading)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WordUnit() when $default != null:
return $default(_that.text,_that.reading);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String text,  String? reading)  $default,) {final _that = this;
switch (_that) {
case _WordUnit():
return $default(_that.text,_that.reading);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String text,  String? reading)?  $default,) {final _that = this;
switch (_that) {
case _WordUnit() when $default != null:
return $default(_that.text,_that.reading);case _:
  return null;

}
}

}

/// @nodoc


class _WordUnit implements WordUnit {
  const _WordUnit({required this.text, this.reading});
  

/// 語の表記（句読点だけの語もある）
@override final  String text;
/// その語の標準的なピンイン（音節ごとに半角スペース区切り）。発話側は null
@override final  String? reading;

/// Create a copy of WordUnit
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WordUnitCopyWith<_WordUnit> get copyWith => __$WordUnitCopyWithImpl<_WordUnit>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WordUnit&&(identical(other.text, text) || other.text == text)&&(identical(other.reading, reading) || other.reading == reading));
}


@override
int get hashCode => Object.hash(runtimeType,text,reading);

@override
String toString() {
  return 'WordUnit(text: $text, reading: $reading)';
}


}

/// @nodoc
abstract mixin class _$WordUnitCopyWith<$Res> implements $WordUnitCopyWith<$Res> {
  factory _$WordUnitCopyWith(_WordUnit value, $Res Function(_WordUnit) _then) = __$WordUnitCopyWithImpl;
@override @useResult
$Res call({
 String text, String? reading
});




}
/// @nodoc
class __$WordUnitCopyWithImpl<$Res>
    implements _$WordUnitCopyWith<$Res> {
  __$WordUnitCopyWithImpl(this._self, this._then);

  final _WordUnit _self;
  final $Res Function(_WordUnit) _then;

/// Create a copy of WordUnit
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? text = null,Object? reading = freezed,}) {
  return _then(_WordUnit(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,reading: freezed == reading ? _self.reading : reading // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$CompositionFeedback {

/// 伝わりやすさ・正確さの総合スコア（0-100）
 int get score;/// score>=70相当の合否
 bool get isAcceptable;/// 発話を最小修正した学習言語の文
 String get corrected;/// 誤りの解説（`uiLocale` の言語）
 String get explanation;/// 模範解答との違い・どちらでも良い点の解説（`uiLocale` の言語）
 String get comparison;/// [corrected]の標準的なピンイン（中国語のみ。修正版のルビ表示に使う）。
/// 英語では null。[correctedWords]があるときはそれを繋いだもの。
 String? get correctedReading;/// [corrected]の語区切り＋語ごとのピンイン（中国語のみ。英語では null）。
///
/// 差分のハイライトを単語ずつの箱にするのと、ルビを語ごとに割り当てるのに使う
/// （語ごとなら音節数が合わない語だけルビを落とせる）。
 List<WordUnit>? get correctedWords;/// 生徒の発話（文字起こし）の語区切り（中国語のみ。ピンインは持たない）。
 List<WordUnit>? get spokenWords;
/// Create a copy of CompositionFeedback
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CompositionFeedbackCopyWith<CompositionFeedback> get copyWith => _$CompositionFeedbackCopyWithImpl<CompositionFeedback>(this as CompositionFeedback, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CompositionFeedback&&(identical(other.score, score) || other.score == score)&&(identical(other.isAcceptable, isAcceptable) || other.isAcceptable == isAcceptable)&&(identical(other.corrected, corrected) || other.corrected == corrected)&&(identical(other.explanation, explanation) || other.explanation == explanation)&&(identical(other.comparison, comparison) || other.comparison == comparison)&&(identical(other.correctedReading, correctedReading) || other.correctedReading == correctedReading)&&const DeepCollectionEquality().equals(other.correctedWords, correctedWords)&&const DeepCollectionEquality().equals(other.spokenWords, spokenWords));
}


@override
int get hashCode => Object.hash(runtimeType,score,isAcceptable,corrected,explanation,comparison,correctedReading,const DeepCollectionEquality().hash(correctedWords),const DeepCollectionEquality().hash(spokenWords));

@override
String toString() {
  return 'CompositionFeedback(score: $score, isAcceptable: $isAcceptable, corrected: $corrected, explanation: $explanation, comparison: $comparison, correctedReading: $correctedReading, correctedWords: $correctedWords, spokenWords: $spokenWords)';
}


}

/// @nodoc
abstract mixin class $CompositionFeedbackCopyWith<$Res>  {
  factory $CompositionFeedbackCopyWith(CompositionFeedback value, $Res Function(CompositionFeedback) _then) = _$CompositionFeedbackCopyWithImpl;
@useResult
$Res call({
 int score, bool isAcceptable, String corrected, String explanation, String comparison, String? correctedReading, List<WordUnit>? correctedWords, List<WordUnit>? spokenWords
});




}
/// @nodoc
class _$CompositionFeedbackCopyWithImpl<$Res>
    implements $CompositionFeedbackCopyWith<$Res> {
  _$CompositionFeedbackCopyWithImpl(this._self, this._then);

  final CompositionFeedback _self;
  final $Res Function(CompositionFeedback) _then;

/// Create a copy of CompositionFeedback
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? score = null,Object? isAcceptable = null,Object? corrected = null,Object? explanation = null,Object? comparison = null,Object? correctedReading = freezed,Object? correctedWords = freezed,Object? spokenWords = freezed,}) {
  return _then(_self.copyWith(
score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,isAcceptable: null == isAcceptable ? _self.isAcceptable : isAcceptable // ignore: cast_nullable_to_non_nullable
as bool,corrected: null == corrected ? _self.corrected : corrected // ignore: cast_nullable_to_non_nullable
as String,explanation: null == explanation ? _self.explanation : explanation // ignore: cast_nullable_to_non_nullable
as String,comparison: null == comparison ? _self.comparison : comparison // ignore: cast_nullable_to_non_nullable
as String,correctedReading: freezed == correctedReading ? _self.correctedReading : correctedReading // ignore: cast_nullable_to_non_nullable
as String?,correctedWords: freezed == correctedWords ? _self.correctedWords : correctedWords // ignore: cast_nullable_to_non_nullable
as List<WordUnit>?,spokenWords: freezed == spokenWords ? _self.spokenWords : spokenWords // ignore: cast_nullable_to_non_nullable
as List<WordUnit>?,
  ));
}

}


/// Adds pattern-matching-related methods to [CompositionFeedback].
extension CompositionFeedbackPatterns on CompositionFeedback {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CompositionFeedback value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CompositionFeedback() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CompositionFeedback value)  $default,){
final _that = this;
switch (_that) {
case _CompositionFeedback():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CompositionFeedback value)?  $default,){
final _that = this;
switch (_that) {
case _CompositionFeedback() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int score,  bool isAcceptable,  String corrected,  String explanation,  String comparison,  String? correctedReading,  List<WordUnit>? correctedWords,  List<WordUnit>? spokenWords)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CompositionFeedback() when $default != null:
return $default(_that.score,_that.isAcceptable,_that.corrected,_that.explanation,_that.comparison,_that.correctedReading,_that.correctedWords,_that.spokenWords);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int score,  bool isAcceptable,  String corrected,  String explanation,  String comparison,  String? correctedReading,  List<WordUnit>? correctedWords,  List<WordUnit>? spokenWords)  $default,) {final _that = this;
switch (_that) {
case _CompositionFeedback():
return $default(_that.score,_that.isAcceptable,_that.corrected,_that.explanation,_that.comparison,_that.correctedReading,_that.correctedWords,_that.spokenWords);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int score,  bool isAcceptable,  String corrected,  String explanation,  String comparison,  String? correctedReading,  List<WordUnit>? correctedWords,  List<WordUnit>? spokenWords)?  $default,) {final _that = this;
switch (_that) {
case _CompositionFeedback() when $default != null:
return $default(_that.score,_that.isAcceptable,_that.corrected,_that.explanation,_that.comparison,_that.correctedReading,_that.correctedWords,_that.spokenWords);case _:
  return null;

}
}

}

/// @nodoc


class _CompositionFeedback extends CompositionFeedback {
  const _CompositionFeedback({required this.score, required this.isAcceptable, required this.corrected, required this.explanation, required this.comparison, this.correctedReading, final  List<WordUnit>? correctedWords, final  List<WordUnit>? spokenWords}): _correctedWords = correctedWords,_spokenWords = spokenWords,super._();
  

/// 伝わりやすさ・正確さの総合スコア（0-100）
@override final  int score;
/// score>=70相当の合否
@override final  bool isAcceptable;
/// 発話を最小修正した学習言語の文
@override final  String corrected;
/// 誤りの解説（`uiLocale` の言語）
@override final  String explanation;
/// 模範解答との違い・どちらでも良い点の解説（`uiLocale` の言語）
@override final  String comparison;
/// [corrected]の標準的なピンイン（中国語のみ。修正版のルビ表示に使う）。
/// 英語では null。[correctedWords]があるときはそれを繋いだもの。
@override final  String? correctedReading;
/// [corrected]の語区切り＋語ごとのピンイン（中国語のみ。英語では null）。
///
/// 差分のハイライトを単語ずつの箱にするのと、ルビを語ごとに割り当てるのに使う
/// （語ごとなら音節数が合わない語だけルビを落とせる）。
 final  List<WordUnit>? _correctedWords;
/// [corrected]の語区切り＋語ごとのピンイン（中国語のみ。英語では null）。
///
/// 差分のハイライトを単語ずつの箱にするのと、ルビを語ごとに割り当てるのに使う
/// （語ごとなら音節数が合わない語だけルビを落とせる）。
@override List<WordUnit>? get correctedWords {
  final value = _correctedWords;
  if (value == null) return null;
  if (_correctedWords is EqualUnmodifiableListView) return _correctedWords;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// 生徒の発話（文字起こし）の語区切り（中国語のみ。ピンインは持たない）。
 final  List<WordUnit>? _spokenWords;
/// 生徒の発話（文字起こし）の語区切り（中国語のみ。ピンインは持たない）。
@override List<WordUnit>? get spokenWords {
  final value = _spokenWords;
  if (value == null) return null;
  if (_spokenWords is EqualUnmodifiableListView) return _spokenWords;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of CompositionFeedback
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CompositionFeedbackCopyWith<_CompositionFeedback> get copyWith => __$CompositionFeedbackCopyWithImpl<_CompositionFeedback>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CompositionFeedback&&(identical(other.score, score) || other.score == score)&&(identical(other.isAcceptable, isAcceptable) || other.isAcceptable == isAcceptable)&&(identical(other.corrected, corrected) || other.corrected == corrected)&&(identical(other.explanation, explanation) || other.explanation == explanation)&&(identical(other.comparison, comparison) || other.comparison == comparison)&&(identical(other.correctedReading, correctedReading) || other.correctedReading == correctedReading)&&const DeepCollectionEquality().equals(other._correctedWords, _correctedWords)&&const DeepCollectionEquality().equals(other._spokenWords, _spokenWords));
}


@override
int get hashCode => Object.hash(runtimeType,score,isAcceptable,corrected,explanation,comparison,correctedReading,const DeepCollectionEquality().hash(_correctedWords),const DeepCollectionEquality().hash(_spokenWords));

@override
String toString() {
  return 'CompositionFeedback(score: $score, isAcceptable: $isAcceptable, corrected: $corrected, explanation: $explanation, comparison: $comparison, correctedReading: $correctedReading, correctedWords: $correctedWords, spokenWords: $spokenWords)';
}


}

/// @nodoc
abstract mixin class _$CompositionFeedbackCopyWith<$Res> implements $CompositionFeedbackCopyWith<$Res> {
  factory _$CompositionFeedbackCopyWith(_CompositionFeedback value, $Res Function(_CompositionFeedback) _then) = __$CompositionFeedbackCopyWithImpl;
@override @useResult
$Res call({
 int score, bool isAcceptable, String corrected, String explanation, String comparison, String? correctedReading, List<WordUnit>? correctedWords, List<WordUnit>? spokenWords
});




}
/// @nodoc
class __$CompositionFeedbackCopyWithImpl<$Res>
    implements _$CompositionFeedbackCopyWith<$Res> {
  __$CompositionFeedbackCopyWithImpl(this._self, this._then);

  final _CompositionFeedback _self;
  final $Res Function(_CompositionFeedback) _then;

/// Create a copy of CompositionFeedback
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? score = null,Object? isAcceptable = null,Object? corrected = null,Object? explanation = null,Object? comparison = null,Object? correctedReading = freezed,Object? correctedWords = freezed,Object? spokenWords = freezed,}) {
  return _then(_CompositionFeedback(
score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,isAcceptable: null == isAcceptable ? _self.isAcceptable : isAcceptable // ignore: cast_nullable_to_non_nullable
as bool,corrected: null == corrected ? _self.corrected : corrected // ignore: cast_nullable_to_non_nullable
as String,explanation: null == explanation ? _self.explanation : explanation // ignore: cast_nullable_to_non_nullable
as String,comparison: null == comparison ? _self.comparison : comparison // ignore: cast_nullable_to_non_nullable
as String,correctedReading: freezed == correctedReading ? _self.correctedReading : correctedReading // ignore: cast_nullable_to_non_nullable
as String?,correctedWords: freezed == correctedWords ? _self._correctedWords : correctedWords // ignore: cast_nullable_to_non_nullable
as List<WordUnit>?,spokenWords: freezed == spokenWords ? _self._spokenWords : spokenWords // ignore: cast_nullable_to_non_nullable
as List<WordUnit>?,
  ));
}


}

/// @nodoc
mixin _$DrillResult {

/// 結果のuuid
 String get id;/// 出題された [Sentence] のid
 String get sentenceId;/// 出題文の学習言語コード（[LanguageProfile.code]）
 String get language;/// 出題文のデッキレベル
 int get level;/// 音声認識で得られたユーザーの発話文
 String get spoken;/// 受験日時
 DateTime get timestamp;/// 添削結果
 CompositionFeedback get feedback;/// 声調の「気づいた点」（中国語のみ。DESIGN.md「声調フィードバック」参照）。
///
/// null は判定していない（英語・模範解答にピンインが無い・音節列が模範解答と
/// 一致しなかった）。空リストは判定したが指摘なし。スコアには一切影響しない。
 List<ToneNote>? get toneNotes;
/// Create a copy of DrillResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DrillResultCopyWith<DrillResult> get copyWith => _$DrillResultCopyWithImpl<DrillResult>(this as DrillResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DrillResult&&(identical(other.id, id) || other.id == id)&&(identical(other.sentenceId, sentenceId) || other.sentenceId == sentenceId)&&(identical(other.language, language) || other.language == language)&&(identical(other.level, level) || other.level == level)&&(identical(other.spoken, spoken) || other.spoken == spoken)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.feedback, feedback) || other.feedback == feedback)&&const DeepCollectionEquality().equals(other.toneNotes, toneNotes));
}


@override
int get hashCode => Object.hash(runtimeType,id,sentenceId,language,level,spoken,timestamp,feedback,const DeepCollectionEquality().hash(toneNotes));

@override
String toString() {
  return 'DrillResult(id: $id, sentenceId: $sentenceId, language: $language, level: $level, spoken: $spoken, timestamp: $timestamp, feedback: $feedback, toneNotes: $toneNotes)';
}


}

/// @nodoc
abstract mixin class $DrillResultCopyWith<$Res>  {
  factory $DrillResultCopyWith(DrillResult value, $Res Function(DrillResult) _then) = _$DrillResultCopyWithImpl;
@useResult
$Res call({
 String id, String sentenceId, String language, int level, String spoken, DateTime timestamp, CompositionFeedback feedback, List<ToneNote>? toneNotes
});


$CompositionFeedbackCopyWith<$Res> get feedback;

}
/// @nodoc
class _$DrillResultCopyWithImpl<$Res>
    implements $DrillResultCopyWith<$Res> {
  _$DrillResultCopyWithImpl(this._self, this._then);

  final DrillResult _self;
  final $Res Function(DrillResult) _then;

/// Create a copy of DrillResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? sentenceId = null,Object? language = null,Object? level = null,Object? spoken = null,Object? timestamp = null,Object? feedback = null,Object? toneNotes = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sentenceId: null == sentenceId ? _self.sentenceId : sentenceId // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,spoken: null == spoken ? _self.spoken : spoken // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,feedback: null == feedback ? _self.feedback : feedback // ignore: cast_nullable_to_non_nullable
as CompositionFeedback,toneNotes: freezed == toneNotes ? _self.toneNotes : toneNotes // ignore: cast_nullable_to_non_nullable
as List<ToneNote>?,
  ));
}
/// Create a copy of DrillResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CompositionFeedbackCopyWith<$Res> get feedback {
  
  return $CompositionFeedbackCopyWith<$Res>(_self.feedback, (value) {
    return _then(_self.copyWith(feedback: value));
  });
}
}


/// Adds pattern-matching-related methods to [DrillResult].
extension DrillResultPatterns on DrillResult {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DrillResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DrillResult() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DrillResult value)  $default,){
final _that = this;
switch (_that) {
case _DrillResult():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DrillResult value)?  $default,){
final _that = this;
switch (_that) {
case _DrillResult() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String sentenceId,  String language,  int level,  String spoken,  DateTime timestamp,  CompositionFeedback feedback,  List<ToneNote>? toneNotes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DrillResult() when $default != null:
return $default(_that.id,_that.sentenceId,_that.language,_that.level,_that.spoken,_that.timestamp,_that.feedback,_that.toneNotes);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String sentenceId,  String language,  int level,  String spoken,  DateTime timestamp,  CompositionFeedback feedback,  List<ToneNote>? toneNotes)  $default,) {final _that = this;
switch (_that) {
case _DrillResult():
return $default(_that.id,_that.sentenceId,_that.language,_that.level,_that.spoken,_that.timestamp,_that.feedback,_that.toneNotes);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String sentenceId,  String language,  int level,  String spoken,  DateTime timestamp,  CompositionFeedback feedback,  List<ToneNote>? toneNotes)?  $default,) {final _that = this;
switch (_that) {
case _DrillResult() when $default != null:
return $default(_that.id,_that.sentenceId,_that.language,_that.level,_that.spoken,_that.timestamp,_that.feedback,_that.toneNotes);case _:
  return null;

}
}

}

/// @nodoc


class _DrillResult implements DrillResult {
  const _DrillResult({required this.id, required this.sentenceId, required this.language, required this.level, required this.spoken, required this.timestamp, required this.feedback, final  List<ToneNote>? toneNotes}): _toneNotes = toneNotes;
  

/// 結果のuuid
@override final  String id;
/// 出題された [Sentence] のid
@override final  String sentenceId;
/// 出題文の学習言語コード（[LanguageProfile.code]）
@override final  String language;
/// 出題文のデッキレベル
@override final  int level;
/// 音声認識で得られたユーザーの発話文
@override final  String spoken;
/// 受験日時
@override final  DateTime timestamp;
/// 添削結果
@override final  CompositionFeedback feedback;
/// 声調の「気づいた点」（中国語のみ。DESIGN.md「声調フィードバック」参照）。
///
/// null は判定していない（英語・模範解答にピンインが無い・音節列が模範解答と
/// 一致しなかった）。空リストは判定したが指摘なし。スコアには一切影響しない。
 final  List<ToneNote>? _toneNotes;
/// 声調の「気づいた点」（中国語のみ。DESIGN.md「声調フィードバック」参照）。
///
/// null は判定していない（英語・模範解答にピンインが無い・音節列が模範解答と
/// 一致しなかった）。空リストは判定したが指摘なし。スコアには一切影響しない。
@override List<ToneNote>? get toneNotes {
  final value = _toneNotes;
  if (value == null) return null;
  if (_toneNotes is EqualUnmodifiableListView) return _toneNotes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of DrillResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DrillResultCopyWith<_DrillResult> get copyWith => __$DrillResultCopyWithImpl<_DrillResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DrillResult&&(identical(other.id, id) || other.id == id)&&(identical(other.sentenceId, sentenceId) || other.sentenceId == sentenceId)&&(identical(other.language, language) || other.language == language)&&(identical(other.level, level) || other.level == level)&&(identical(other.spoken, spoken) || other.spoken == spoken)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.feedback, feedback) || other.feedback == feedback)&&const DeepCollectionEquality().equals(other._toneNotes, _toneNotes));
}


@override
int get hashCode => Object.hash(runtimeType,id,sentenceId,language,level,spoken,timestamp,feedback,const DeepCollectionEquality().hash(_toneNotes));

@override
String toString() {
  return 'DrillResult(id: $id, sentenceId: $sentenceId, language: $language, level: $level, spoken: $spoken, timestamp: $timestamp, feedback: $feedback, toneNotes: $toneNotes)';
}


}

/// @nodoc
abstract mixin class _$DrillResultCopyWith<$Res> implements $DrillResultCopyWith<$Res> {
  factory _$DrillResultCopyWith(_DrillResult value, $Res Function(_DrillResult) _then) = __$DrillResultCopyWithImpl;
@override @useResult
$Res call({
 String id, String sentenceId, String language, int level, String spoken, DateTime timestamp, CompositionFeedback feedback, List<ToneNote>? toneNotes
});


@override $CompositionFeedbackCopyWith<$Res> get feedback;

}
/// @nodoc
class __$DrillResultCopyWithImpl<$Res>
    implements _$DrillResultCopyWith<$Res> {
  __$DrillResultCopyWithImpl(this._self, this._then);

  final _DrillResult _self;
  final $Res Function(_DrillResult) _then;

/// Create a copy of DrillResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sentenceId = null,Object? language = null,Object? level = null,Object? spoken = null,Object? timestamp = null,Object? feedback = null,Object? toneNotes = freezed,}) {
  return _then(_DrillResult(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sentenceId: null == sentenceId ? _self.sentenceId : sentenceId // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,spoken: null == spoken ? _self.spoken : spoken // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,feedback: null == feedback ? _self.feedback : feedback // ignore: cast_nullable_to_non_nullable
as CompositionFeedback,toneNotes: freezed == toneNotes ? _self._toneNotes : toneNotes // ignore: cast_nullable_to_non_nullable
as List<ToneNote>?,
  ));
}

/// Create a copy of DrillResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CompositionFeedbackCopyWith<$Res> get feedback {
  
  return $CompositionFeedbackCopyWith<$Res>(_self.feedback, (value) {
    return _then(_self.copyWith(feedback: value));
  });
}
}

// dart format on
