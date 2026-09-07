// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'monologue_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Correction {

 String get original; String get corrected;/// 修正の理由（`uiLocale` の言語）
 String get reason;
/// Create a copy of Correction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CorrectionCopyWith<Correction> get copyWith => _$CorrectionCopyWithImpl<Correction>(this as Correction, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Correction&&(identical(other.original, original) || other.original == original)&&(identical(other.corrected, corrected) || other.corrected == corrected)&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,original,corrected,reason);

@override
String toString() {
  return 'Correction(original: $original, corrected: $corrected, reason: $reason)';
}


}

/// @nodoc
abstract mixin class $CorrectionCopyWith<$Res>  {
  factory $CorrectionCopyWith(Correction value, $Res Function(Correction) _then) = _$CorrectionCopyWithImpl;
@useResult
$Res call({
 String original, String corrected, String reason
});




}
/// @nodoc
class _$CorrectionCopyWithImpl<$Res>
    implements $CorrectionCopyWith<$Res> {
  _$CorrectionCopyWithImpl(this._self, this._then);

  final Correction _self;
  final $Res Function(Correction) _then;

/// Create a copy of Correction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? original = null,Object? corrected = null,Object? reason = null,}) {
  return _then(_self.copyWith(
original: null == original ? _self.original : original // ignore: cast_nullable_to_non_nullable
as String,corrected: null == corrected ? _self.corrected : corrected // ignore: cast_nullable_to_non_nullable
as String,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Correction].
extension CorrectionPatterns on Correction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Correction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Correction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Correction value)  $default,){
final _that = this;
switch (_that) {
case _Correction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Correction value)?  $default,){
final _that = this;
switch (_that) {
case _Correction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String original,  String corrected,  String reason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Correction() when $default != null:
return $default(_that.original,_that.corrected,_that.reason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String original,  String corrected,  String reason)  $default,) {final _that = this;
switch (_that) {
case _Correction():
return $default(_that.original,_that.corrected,_that.reason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String original,  String corrected,  String reason)?  $default,) {final _that = this;
switch (_that) {
case _Correction() when $default != null:
return $default(_that.original,_that.corrected,_that.reason);case _:
  return null;

}
}

}

/// @nodoc


class _Correction implements Correction {
  const _Correction({required this.original, required this.corrected, required this.reason});
  

@override final  String original;
@override final  String corrected;
/// 修正の理由（`uiLocale` の言語）
@override final  String reason;

/// Create a copy of Correction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CorrectionCopyWith<_Correction> get copyWith => __$CorrectionCopyWithImpl<_Correction>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Correction&&(identical(other.original, original) || other.original == original)&&(identical(other.corrected, corrected) || other.corrected == corrected)&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,original,corrected,reason);

@override
String toString() {
  return 'Correction(original: $original, corrected: $corrected, reason: $reason)';
}


}

/// @nodoc
abstract mixin class _$CorrectionCopyWith<$Res> implements $CorrectionCopyWith<$Res> {
  factory _$CorrectionCopyWith(_Correction value, $Res Function(_Correction) _then) = __$CorrectionCopyWithImpl;
@override @useResult
$Res call({
 String original, String corrected, String reason
});




}
/// @nodoc
class __$CorrectionCopyWithImpl<$Res>
    implements _$CorrectionCopyWith<$Res> {
  __$CorrectionCopyWithImpl(this._self, this._then);

  final _Correction _self;
  final $Res Function(_Correction) _then;

/// Create a copy of Correction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? original = null,Object? corrected = null,Object? reason = null,}) {
  return _then(_Correction(
original: null == original ? _self.original : original // ignore: cast_nullable_to_non_nullable
as String,corrected: null == corrected ? _self.corrected : corrected // ignore: cast_nullable_to_non_nullable
as String,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$UsefulPhrase {

/// 学習言語での表現
 String get target;/// 日本語訳（`uiLocale` の言語）
 String get ja;
/// Create a copy of UsefulPhrase
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UsefulPhraseCopyWith<UsefulPhrase> get copyWith => _$UsefulPhraseCopyWithImpl<UsefulPhrase>(this as UsefulPhrase, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UsefulPhrase&&(identical(other.target, target) || other.target == target)&&(identical(other.ja, ja) || other.ja == ja));
}


@override
int get hashCode => Object.hash(runtimeType,target,ja);

@override
String toString() {
  return 'UsefulPhrase(target: $target, ja: $ja)';
}


}

/// @nodoc
abstract mixin class $UsefulPhraseCopyWith<$Res>  {
  factory $UsefulPhraseCopyWith(UsefulPhrase value, $Res Function(UsefulPhrase) _then) = _$UsefulPhraseCopyWithImpl;
@useResult
$Res call({
 String target, String ja
});




}
/// @nodoc
class _$UsefulPhraseCopyWithImpl<$Res>
    implements $UsefulPhraseCopyWith<$Res> {
  _$UsefulPhraseCopyWithImpl(this._self, this._then);

  final UsefulPhrase _self;
  final $Res Function(UsefulPhrase) _then;

/// Create a copy of UsefulPhrase
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? target = null,Object? ja = null,}) {
  return _then(_self.copyWith(
target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as String,ja: null == ja ? _self.ja : ja // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [UsefulPhrase].
extension UsefulPhrasePatterns on UsefulPhrase {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UsefulPhrase value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UsefulPhrase() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UsefulPhrase value)  $default,){
final _that = this;
switch (_that) {
case _UsefulPhrase():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UsefulPhrase value)?  $default,){
final _that = this;
switch (_that) {
case _UsefulPhrase() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String target,  String ja)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UsefulPhrase() when $default != null:
return $default(_that.target,_that.ja);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String target,  String ja)  $default,) {final _that = this;
switch (_that) {
case _UsefulPhrase():
return $default(_that.target,_that.ja);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String target,  String ja)?  $default,) {final _that = this;
switch (_that) {
case _UsefulPhrase() when $default != null:
return $default(_that.target,_that.ja);case _:
  return null;

}
}

}

/// @nodoc


class _UsefulPhrase implements UsefulPhrase {
  const _UsefulPhrase({required this.target, required this.ja});
  

/// 学習言語での表現
@override final  String target;
/// 日本語訳（`uiLocale` の言語）
@override final  String ja;

/// Create a copy of UsefulPhrase
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UsefulPhraseCopyWith<_UsefulPhrase> get copyWith => __$UsefulPhraseCopyWithImpl<_UsefulPhrase>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UsefulPhrase&&(identical(other.target, target) || other.target == target)&&(identical(other.ja, ja) || other.ja == ja));
}


@override
int get hashCode => Object.hash(runtimeType,target,ja);

@override
String toString() {
  return 'UsefulPhrase(target: $target, ja: $ja)';
}


}

/// @nodoc
abstract mixin class _$UsefulPhraseCopyWith<$Res> implements $UsefulPhraseCopyWith<$Res> {
  factory _$UsefulPhraseCopyWith(_UsefulPhrase value, $Res Function(_UsefulPhrase) _then) = __$UsefulPhraseCopyWithImpl;
@override @useResult
$Res call({
 String target, String ja
});




}
/// @nodoc
class __$UsefulPhraseCopyWithImpl<$Res>
    implements _$UsefulPhraseCopyWith<$Res> {
  __$UsefulPhraseCopyWithImpl(this._self, this._then);

  final _UsefulPhrase _self;
  final $Res Function(_UsefulPhrase) _then;

/// Create a copy of UsefulPhrase
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? target = null,Object? ja = null,}) {
  return _then(_UsefulPhrase(
target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as String,ja: null == ja ? _self.ja : ja // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$MonologueFeedback {

/// 流暢さスコア（0-100）
 int get fluencyScore;/// 全文を自然な学習言語の文に直したもの
 String get correctedTranscript;/// 個別の修正点一覧
 List<Correction> get corrections;/// 次回使える表現（3-5個）
 List<UsefulPhrase> get usefulPhrases;/// 良かった点・改善点の総評（`uiLocale` の言語）
 String get overallFeedback;
/// Create a copy of MonologueFeedback
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MonologueFeedbackCopyWith<MonologueFeedback> get copyWith => _$MonologueFeedbackCopyWithImpl<MonologueFeedback>(this as MonologueFeedback, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MonologueFeedback&&(identical(other.fluencyScore, fluencyScore) || other.fluencyScore == fluencyScore)&&(identical(other.correctedTranscript, correctedTranscript) || other.correctedTranscript == correctedTranscript)&&const DeepCollectionEquality().equals(other.corrections, corrections)&&const DeepCollectionEquality().equals(other.usefulPhrases, usefulPhrases)&&(identical(other.overallFeedback, overallFeedback) || other.overallFeedback == overallFeedback));
}


@override
int get hashCode => Object.hash(runtimeType,fluencyScore,correctedTranscript,const DeepCollectionEquality().hash(corrections),const DeepCollectionEquality().hash(usefulPhrases),overallFeedback);

@override
String toString() {
  return 'MonologueFeedback(fluencyScore: $fluencyScore, correctedTranscript: $correctedTranscript, corrections: $corrections, usefulPhrases: $usefulPhrases, overallFeedback: $overallFeedback)';
}


}

/// @nodoc
abstract mixin class $MonologueFeedbackCopyWith<$Res>  {
  factory $MonologueFeedbackCopyWith(MonologueFeedback value, $Res Function(MonologueFeedback) _then) = _$MonologueFeedbackCopyWithImpl;
@useResult
$Res call({
 int fluencyScore, String correctedTranscript, List<Correction> corrections, List<UsefulPhrase> usefulPhrases, String overallFeedback
});




}
/// @nodoc
class _$MonologueFeedbackCopyWithImpl<$Res>
    implements $MonologueFeedbackCopyWith<$Res> {
  _$MonologueFeedbackCopyWithImpl(this._self, this._then);

  final MonologueFeedback _self;
  final $Res Function(MonologueFeedback) _then;

/// Create a copy of MonologueFeedback
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fluencyScore = null,Object? correctedTranscript = null,Object? corrections = null,Object? usefulPhrases = null,Object? overallFeedback = null,}) {
  return _then(_self.copyWith(
fluencyScore: null == fluencyScore ? _self.fluencyScore : fluencyScore // ignore: cast_nullable_to_non_nullable
as int,correctedTranscript: null == correctedTranscript ? _self.correctedTranscript : correctedTranscript // ignore: cast_nullable_to_non_nullable
as String,corrections: null == corrections ? _self.corrections : corrections // ignore: cast_nullable_to_non_nullable
as List<Correction>,usefulPhrases: null == usefulPhrases ? _self.usefulPhrases : usefulPhrases // ignore: cast_nullable_to_non_nullable
as List<UsefulPhrase>,overallFeedback: null == overallFeedback ? _self.overallFeedback : overallFeedback // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MonologueFeedback].
extension MonologueFeedbackPatterns on MonologueFeedback {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MonologueFeedback value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MonologueFeedback() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MonologueFeedback value)  $default,){
final _that = this;
switch (_that) {
case _MonologueFeedback():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MonologueFeedback value)?  $default,){
final _that = this;
switch (_that) {
case _MonologueFeedback() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int fluencyScore,  String correctedTranscript,  List<Correction> corrections,  List<UsefulPhrase> usefulPhrases,  String overallFeedback)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MonologueFeedback() when $default != null:
return $default(_that.fluencyScore,_that.correctedTranscript,_that.corrections,_that.usefulPhrases,_that.overallFeedback);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int fluencyScore,  String correctedTranscript,  List<Correction> corrections,  List<UsefulPhrase> usefulPhrases,  String overallFeedback)  $default,) {final _that = this;
switch (_that) {
case _MonologueFeedback():
return $default(_that.fluencyScore,_that.correctedTranscript,_that.corrections,_that.usefulPhrases,_that.overallFeedback);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int fluencyScore,  String correctedTranscript,  List<Correction> corrections,  List<UsefulPhrase> usefulPhrases,  String overallFeedback)?  $default,) {final _that = this;
switch (_that) {
case _MonologueFeedback() when $default != null:
return $default(_that.fluencyScore,_that.correctedTranscript,_that.corrections,_that.usefulPhrases,_that.overallFeedback);case _:
  return null;

}
}

}

/// @nodoc


class _MonologueFeedback implements MonologueFeedback {
  const _MonologueFeedback({required this.fluencyScore, required this.correctedTranscript, required final  List<Correction> corrections, required final  List<UsefulPhrase> usefulPhrases, required this.overallFeedback}): _corrections = corrections,_usefulPhrases = usefulPhrases;
  

/// 流暢さスコア（0-100）
@override final  int fluencyScore;
/// 全文を自然な学習言語の文に直したもの
@override final  String correctedTranscript;
/// 個別の修正点一覧
 final  List<Correction> _corrections;
/// 個別の修正点一覧
@override List<Correction> get corrections {
  if (_corrections is EqualUnmodifiableListView) return _corrections;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_corrections);
}

/// 次回使える表現（3-5個）
 final  List<UsefulPhrase> _usefulPhrases;
/// 次回使える表現（3-5個）
@override List<UsefulPhrase> get usefulPhrases {
  if (_usefulPhrases is EqualUnmodifiableListView) return _usefulPhrases;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_usefulPhrases);
}

/// 良かった点・改善点の総評（`uiLocale` の言語）
@override final  String overallFeedback;

/// Create a copy of MonologueFeedback
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MonologueFeedbackCopyWith<_MonologueFeedback> get copyWith => __$MonologueFeedbackCopyWithImpl<_MonologueFeedback>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MonologueFeedback&&(identical(other.fluencyScore, fluencyScore) || other.fluencyScore == fluencyScore)&&(identical(other.correctedTranscript, correctedTranscript) || other.correctedTranscript == correctedTranscript)&&const DeepCollectionEquality().equals(other._corrections, _corrections)&&const DeepCollectionEquality().equals(other._usefulPhrases, _usefulPhrases)&&(identical(other.overallFeedback, overallFeedback) || other.overallFeedback == overallFeedback));
}


@override
int get hashCode => Object.hash(runtimeType,fluencyScore,correctedTranscript,const DeepCollectionEquality().hash(_corrections),const DeepCollectionEquality().hash(_usefulPhrases),overallFeedback);

@override
String toString() {
  return 'MonologueFeedback(fluencyScore: $fluencyScore, correctedTranscript: $correctedTranscript, corrections: $corrections, usefulPhrases: $usefulPhrases, overallFeedback: $overallFeedback)';
}


}

/// @nodoc
abstract mixin class _$MonologueFeedbackCopyWith<$Res> implements $MonologueFeedbackCopyWith<$Res> {
  factory _$MonologueFeedbackCopyWith(_MonologueFeedback value, $Res Function(_MonologueFeedback) _then) = __$MonologueFeedbackCopyWithImpl;
@override @useResult
$Res call({
 int fluencyScore, String correctedTranscript, List<Correction> corrections, List<UsefulPhrase> usefulPhrases, String overallFeedback
});




}
/// @nodoc
class __$MonologueFeedbackCopyWithImpl<$Res>
    implements _$MonologueFeedbackCopyWith<$Res> {
  __$MonologueFeedbackCopyWithImpl(this._self, this._then);

  final _MonologueFeedback _self;
  final $Res Function(_MonologueFeedback) _then;

/// Create a copy of MonologueFeedback
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fluencyScore = null,Object? correctedTranscript = null,Object? corrections = null,Object? usefulPhrases = null,Object? overallFeedback = null,}) {
  return _then(_MonologueFeedback(
fluencyScore: null == fluencyScore ? _self.fluencyScore : fluencyScore // ignore: cast_nullable_to_non_nullable
as int,correctedTranscript: null == correctedTranscript ? _self.correctedTranscript : correctedTranscript // ignore: cast_nullable_to_non_nullable
as String,corrections: null == corrections ? _self._corrections : corrections // ignore: cast_nullable_to_non_nullable
as List<Correction>,usefulPhrases: null == usefulPhrases ? _self._usefulPhrases : usefulPhrases // ignore: cast_nullable_to_non_nullable
as List<UsefulPhrase>,overallFeedback: null == overallFeedback ? _self.overallFeedback : overallFeedback // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$MonologueResult {

/// 結果のuuid
 String get id;/// 出題されたお題のid
 String get topicId;/// お題の学習言語コード（[LanguageProfile.code]）
 String get language;/// 発話時間（秒）
 int get seconds;/// 音声認識で得られた発話の文字起こし
 String get transcript;/// 実施日時
 DateTime get timestamp;/// フィードバック
 MonologueFeedback get feedback;
/// Create a copy of MonologueResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MonologueResultCopyWith<MonologueResult> get copyWith => _$MonologueResultCopyWithImpl<MonologueResult>(this as MonologueResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MonologueResult&&(identical(other.id, id) || other.id == id)&&(identical(other.topicId, topicId) || other.topicId == topicId)&&(identical(other.language, language) || other.language == language)&&(identical(other.seconds, seconds) || other.seconds == seconds)&&(identical(other.transcript, transcript) || other.transcript == transcript)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.feedback, feedback) || other.feedback == feedback));
}


@override
int get hashCode => Object.hash(runtimeType,id,topicId,language,seconds,transcript,timestamp,feedback);

@override
String toString() {
  return 'MonologueResult(id: $id, topicId: $topicId, language: $language, seconds: $seconds, transcript: $transcript, timestamp: $timestamp, feedback: $feedback)';
}


}

/// @nodoc
abstract mixin class $MonologueResultCopyWith<$Res>  {
  factory $MonologueResultCopyWith(MonologueResult value, $Res Function(MonologueResult) _then) = _$MonologueResultCopyWithImpl;
@useResult
$Res call({
 String id, String topicId, String language, int seconds, String transcript, DateTime timestamp, MonologueFeedback feedback
});


$MonologueFeedbackCopyWith<$Res> get feedback;

}
/// @nodoc
class _$MonologueResultCopyWithImpl<$Res>
    implements $MonologueResultCopyWith<$Res> {
  _$MonologueResultCopyWithImpl(this._self, this._then);

  final MonologueResult _self;
  final $Res Function(MonologueResult) _then;

/// Create a copy of MonologueResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? topicId = null,Object? language = null,Object? seconds = null,Object? transcript = null,Object? timestamp = null,Object? feedback = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,topicId: null == topicId ? _self.topicId : topicId // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,seconds: null == seconds ? _self.seconds : seconds // ignore: cast_nullable_to_non_nullable
as int,transcript: null == transcript ? _self.transcript : transcript // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,feedback: null == feedback ? _self.feedback : feedback // ignore: cast_nullable_to_non_nullable
as MonologueFeedback,
  ));
}
/// Create a copy of MonologueResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MonologueFeedbackCopyWith<$Res> get feedback {
  
  return $MonologueFeedbackCopyWith<$Res>(_self.feedback, (value) {
    return _then(_self.copyWith(feedback: value));
  });
}
}


/// Adds pattern-matching-related methods to [MonologueResult].
extension MonologueResultPatterns on MonologueResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MonologueResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MonologueResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MonologueResult value)  $default,){
final _that = this;
switch (_that) {
case _MonologueResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MonologueResult value)?  $default,){
final _that = this;
switch (_that) {
case _MonologueResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String topicId,  String language,  int seconds,  String transcript,  DateTime timestamp,  MonologueFeedback feedback)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MonologueResult() when $default != null:
return $default(_that.id,_that.topicId,_that.language,_that.seconds,_that.transcript,_that.timestamp,_that.feedback);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String topicId,  String language,  int seconds,  String transcript,  DateTime timestamp,  MonologueFeedback feedback)  $default,) {final _that = this;
switch (_that) {
case _MonologueResult():
return $default(_that.id,_that.topicId,_that.language,_that.seconds,_that.transcript,_that.timestamp,_that.feedback);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String topicId,  String language,  int seconds,  String transcript,  DateTime timestamp,  MonologueFeedback feedback)?  $default,) {final _that = this;
switch (_that) {
case _MonologueResult() when $default != null:
return $default(_that.id,_that.topicId,_that.language,_that.seconds,_that.transcript,_that.timestamp,_that.feedback);case _:
  return null;

}
}

}

/// @nodoc


class _MonologueResult implements MonologueResult {
  const _MonologueResult({required this.id, required this.topicId, required this.language, required this.seconds, required this.transcript, required this.timestamp, required this.feedback});
  

/// 結果のuuid
@override final  String id;
/// 出題されたお題のid
@override final  String topicId;
/// お題の学習言語コード（[LanguageProfile.code]）
@override final  String language;
/// 発話時間（秒）
@override final  int seconds;
/// 音声認識で得られた発話の文字起こし
@override final  String transcript;
/// 実施日時
@override final  DateTime timestamp;
/// フィードバック
@override final  MonologueFeedback feedback;

/// Create a copy of MonologueResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MonologueResultCopyWith<_MonologueResult> get copyWith => __$MonologueResultCopyWithImpl<_MonologueResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MonologueResult&&(identical(other.id, id) || other.id == id)&&(identical(other.topicId, topicId) || other.topicId == topicId)&&(identical(other.language, language) || other.language == language)&&(identical(other.seconds, seconds) || other.seconds == seconds)&&(identical(other.transcript, transcript) || other.transcript == transcript)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.feedback, feedback) || other.feedback == feedback));
}


@override
int get hashCode => Object.hash(runtimeType,id,topicId,language,seconds,transcript,timestamp,feedback);

@override
String toString() {
  return 'MonologueResult(id: $id, topicId: $topicId, language: $language, seconds: $seconds, transcript: $transcript, timestamp: $timestamp, feedback: $feedback)';
}


}

/// @nodoc
abstract mixin class _$MonologueResultCopyWith<$Res> implements $MonologueResultCopyWith<$Res> {
  factory _$MonologueResultCopyWith(_MonologueResult value, $Res Function(_MonologueResult) _then) = __$MonologueResultCopyWithImpl;
@override @useResult
$Res call({
 String id, String topicId, String language, int seconds, String transcript, DateTime timestamp, MonologueFeedback feedback
});


@override $MonologueFeedbackCopyWith<$Res> get feedback;

}
/// @nodoc
class __$MonologueResultCopyWithImpl<$Res>
    implements _$MonologueResultCopyWith<$Res> {
  __$MonologueResultCopyWithImpl(this._self, this._then);

  final _MonologueResult _self;
  final $Res Function(_MonologueResult) _then;

/// Create a copy of MonologueResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? topicId = null,Object? language = null,Object? seconds = null,Object? transcript = null,Object? timestamp = null,Object? feedback = null,}) {
  return _then(_MonologueResult(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,topicId: null == topicId ? _self.topicId : topicId // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,seconds: null == seconds ? _self.seconds : seconds // ignore: cast_nullable_to_non_nullable
as int,transcript: null == transcript ? _self.transcript : transcript // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,feedback: null == feedback ? _self.feedback : feedback // ignore: cast_nullable_to_non_nullable
as MonologueFeedback,
  ));
}

/// Create a copy of MonologueResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MonologueFeedbackCopyWith<$Res> get feedback {
  
  return $MonologueFeedbackCopyWith<$Res>(_self.feedback, (value) {
    return _then(_self.copyWith(feedback: value));
  });
}
}

// dart format on
