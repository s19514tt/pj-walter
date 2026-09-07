// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'drill_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DrillQuestionUsage {

/// 音声の文字起こし（やり直した分も含む合計）
 TokenUsage get transcription;/// 添削
 TokenUsage get correction;/// 添削結果の読み上げ（TTSモデル。単価が別なので分けて持つ）
 TokenUsage get speech;
/// Create a copy of DrillQuestionUsage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DrillQuestionUsageCopyWith<DrillQuestionUsage> get copyWith => _$DrillQuestionUsageCopyWithImpl<DrillQuestionUsage>(this as DrillQuestionUsage, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DrillQuestionUsage&&(identical(other.transcription, transcription) || other.transcription == transcription)&&(identical(other.correction, correction) || other.correction == correction)&&(identical(other.speech, speech) || other.speech == speech));
}


@override
int get hashCode => Object.hash(runtimeType,transcription,correction,speech);

@override
String toString() {
  return 'DrillQuestionUsage(transcription: $transcription, correction: $correction, speech: $speech)';
}


}

/// @nodoc
abstract mixin class $DrillQuestionUsageCopyWith<$Res>  {
  factory $DrillQuestionUsageCopyWith(DrillQuestionUsage value, $Res Function(DrillQuestionUsage) _then) = _$DrillQuestionUsageCopyWithImpl;
@useResult
$Res call({
 TokenUsage transcription, TokenUsage correction, TokenUsage speech
});


$TokenUsageCopyWith<$Res> get transcription;$TokenUsageCopyWith<$Res> get correction;$TokenUsageCopyWith<$Res> get speech;

}
/// @nodoc
class _$DrillQuestionUsageCopyWithImpl<$Res>
    implements $DrillQuestionUsageCopyWith<$Res> {
  _$DrillQuestionUsageCopyWithImpl(this._self, this._then);

  final DrillQuestionUsage _self;
  final $Res Function(DrillQuestionUsage) _then;

/// Create a copy of DrillQuestionUsage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? transcription = null,Object? correction = null,Object? speech = null,}) {
  return _then(_self.copyWith(
transcription: null == transcription ? _self.transcription : transcription // ignore: cast_nullable_to_non_nullable
as TokenUsage,correction: null == correction ? _self.correction : correction // ignore: cast_nullable_to_non_nullable
as TokenUsage,speech: null == speech ? _self.speech : speech // ignore: cast_nullable_to_non_nullable
as TokenUsage,
  ));
}
/// Create a copy of DrillQuestionUsage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TokenUsageCopyWith<$Res> get transcription {
  
  return $TokenUsageCopyWith<$Res>(_self.transcription, (value) {
    return _then(_self.copyWith(transcription: value));
  });
}/// Create a copy of DrillQuestionUsage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TokenUsageCopyWith<$Res> get correction {
  
  return $TokenUsageCopyWith<$Res>(_self.correction, (value) {
    return _then(_self.copyWith(correction: value));
  });
}/// Create a copy of DrillQuestionUsage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TokenUsageCopyWith<$Res> get speech {
  
  return $TokenUsageCopyWith<$Res>(_self.speech, (value) {
    return _then(_self.copyWith(speech: value));
  });
}
}


/// Adds pattern-matching-related methods to [DrillQuestionUsage].
extension DrillQuestionUsagePatterns on DrillQuestionUsage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DrillQuestionUsage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DrillQuestionUsage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DrillQuestionUsage value)  $default,){
final _that = this;
switch (_that) {
case _DrillQuestionUsage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DrillQuestionUsage value)?  $default,){
final _that = this;
switch (_that) {
case _DrillQuestionUsage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TokenUsage transcription,  TokenUsage correction,  TokenUsage speech)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DrillQuestionUsage() when $default != null:
return $default(_that.transcription,_that.correction,_that.speech);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TokenUsage transcription,  TokenUsage correction,  TokenUsage speech)  $default,) {final _that = this;
switch (_that) {
case _DrillQuestionUsage():
return $default(_that.transcription,_that.correction,_that.speech);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TokenUsage transcription,  TokenUsage correction,  TokenUsage speech)?  $default,) {final _that = this;
switch (_that) {
case _DrillQuestionUsage() when $default != null:
return $default(_that.transcription,_that.correction,_that.speech);case _:
  return null;

}
}

}

/// @nodoc


class _DrillQuestionUsage extends DrillQuestionUsage {
  const _DrillQuestionUsage({this.transcription = TokenUsage.zero, this.correction = TokenUsage.zero, this.speech = TokenUsage.zero}): super._();
  

/// 音声の文字起こし（やり直した分も含む合計）
@override@JsonKey() final  TokenUsage transcription;
/// 添削
@override@JsonKey() final  TokenUsage correction;
/// 添削結果の読み上げ（TTSモデル。単価が別なので分けて持つ）
@override@JsonKey() final  TokenUsage speech;

/// Create a copy of DrillQuestionUsage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DrillQuestionUsageCopyWith<_DrillQuestionUsage> get copyWith => __$DrillQuestionUsageCopyWithImpl<_DrillQuestionUsage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DrillQuestionUsage&&(identical(other.transcription, transcription) || other.transcription == transcription)&&(identical(other.correction, correction) || other.correction == correction)&&(identical(other.speech, speech) || other.speech == speech));
}


@override
int get hashCode => Object.hash(runtimeType,transcription,correction,speech);

@override
String toString() {
  return 'DrillQuestionUsage(transcription: $transcription, correction: $correction, speech: $speech)';
}


}

/// @nodoc
abstract mixin class _$DrillQuestionUsageCopyWith<$Res> implements $DrillQuestionUsageCopyWith<$Res> {
  factory _$DrillQuestionUsageCopyWith(_DrillQuestionUsage value, $Res Function(_DrillQuestionUsage) _then) = __$DrillQuestionUsageCopyWithImpl;
@override @useResult
$Res call({
 TokenUsage transcription, TokenUsage correction, TokenUsage speech
});


@override $TokenUsageCopyWith<$Res> get transcription;@override $TokenUsageCopyWith<$Res> get correction;@override $TokenUsageCopyWith<$Res> get speech;

}
/// @nodoc
class __$DrillQuestionUsageCopyWithImpl<$Res>
    implements _$DrillQuestionUsageCopyWith<$Res> {
  __$DrillQuestionUsageCopyWithImpl(this._self, this._then);

  final _DrillQuestionUsage _self;
  final $Res Function(_DrillQuestionUsage) _then;

/// Create a copy of DrillQuestionUsage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? transcription = null,Object? correction = null,Object? speech = null,}) {
  return _then(_DrillQuestionUsage(
transcription: null == transcription ? _self.transcription : transcription // ignore: cast_nullable_to_non_nullable
as TokenUsage,correction: null == correction ? _self.correction : correction // ignore: cast_nullable_to_non_nullable
as TokenUsage,speech: null == speech ? _self.speech : speech // ignore: cast_nullable_to_non_nullable
as TokenUsage,
  ));
}

/// Create a copy of DrillQuestionUsage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TokenUsageCopyWith<$Res> get transcription {
  
  return $TokenUsageCopyWith<$Res>(_self.transcription, (value) {
    return _then(_self.copyWith(transcription: value));
  });
}/// Create a copy of DrillQuestionUsage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TokenUsageCopyWith<$Res> get correction {
  
  return $TokenUsageCopyWith<$Res>(_self.correction, (value) {
    return _then(_self.copyWith(correction: value));
  });
}/// Create a copy of DrillQuestionUsage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TokenUsageCopyWith<$Res> get speech {
  
  return $TokenUsageCopyWith<$Res>(_self.speech, (value) {
    return _then(_self.copyWith(speech: value));
  });
}
}

/// @nodoc
mixin _$DrillSummaryEntry {

/// 出題された日本語文
 String get ja;/// その問のスコア
 int get score;/// その問で消費したトークン
 DrillQuestionUsage get usage;
/// Create a copy of DrillSummaryEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DrillSummaryEntryCopyWith<DrillSummaryEntry> get copyWith => _$DrillSummaryEntryCopyWithImpl<DrillSummaryEntry>(this as DrillSummaryEntry, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DrillSummaryEntry&&(identical(other.ja, ja) || other.ja == ja)&&(identical(other.score, score) || other.score == score)&&(identical(other.usage, usage) || other.usage == usage));
}


@override
int get hashCode => Object.hash(runtimeType,ja,score,usage);

@override
String toString() {
  return 'DrillSummaryEntry(ja: $ja, score: $score, usage: $usage)';
}


}

/// @nodoc
abstract mixin class $DrillSummaryEntryCopyWith<$Res>  {
  factory $DrillSummaryEntryCopyWith(DrillSummaryEntry value, $Res Function(DrillSummaryEntry) _then) = _$DrillSummaryEntryCopyWithImpl;
@useResult
$Res call({
 String ja, int score, DrillQuestionUsage usage
});


$DrillQuestionUsageCopyWith<$Res> get usage;

}
/// @nodoc
class _$DrillSummaryEntryCopyWithImpl<$Res>
    implements $DrillSummaryEntryCopyWith<$Res> {
  _$DrillSummaryEntryCopyWithImpl(this._self, this._then);

  final DrillSummaryEntry _self;
  final $Res Function(DrillSummaryEntry) _then;

/// Create a copy of DrillSummaryEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ja = null,Object? score = null,Object? usage = null,}) {
  return _then(_self.copyWith(
ja: null == ja ? _self.ja : ja // ignore: cast_nullable_to_non_nullable
as String,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,usage: null == usage ? _self.usage : usage // ignore: cast_nullable_to_non_nullable
as DrillQuestionUsage,
  ));
}
/// Create a copy of DrillSummaryEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DrillQuestionUsageCopyWith<$Res> get usage {
  
  return $DrillQuestionUsageCopyWith<$Res>(_self.usage, (value) {
    return _then(_self.copyWith(usage: value));
  });
}
}


/// Adds pattern-matching-related methods to [DrillSummaryEntry].
extension DrillSummaryEntryPatterns on DrillSummaryEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DrillSummaryEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DrillSummaryEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DrillSummaryEntry value)  $default,){
final _that = this;
switch (_that) {
case _DrillSummaryEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DrillSummaryEntry value)?  $default,){
final _that = this;
switch (_that) {
case _DrillSummaryEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String ja,  int score,  DrillQuestionUsage usage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DrillSummaryEntry() when $default != null:
return $default(_that.ja,_that.score,_that.usage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String ja,  int score,  DrillQuestionUsage usage)  $default,) {final _that = this;
switch (_that) {
case _DrillSummaryEntry():
return $default(_that.ja,_that.score,_that.usage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String ja,  int score,  DrillQuestionUsage usage)?  $default,) {final _that = this;
switch (_that) {
case _DrillSummaryEntry() when $default != null:
return $default(_that.ja,_that.score,_that.usage);case _:
  return null;

}
}

}

/// @nodoc


class _DrillSummaryEntry implements DrillSummaryEntry {
  const _DrillSummaryEntry({required this.ja, required this.score, this.usage = DrillQuestionUsage.zero});
  

/// 出題された日本語文
@override final  String ja;
/// その問のスコア
@override final  int score;
/// その問で消費したトークン
@override@JsonKey() final  DrillQuestionUsage usage;

/// Create a copy of DrillSummaryEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DrillSummaryEntryCopyWith<_DrillSummaryEntry> get copyWith => __$DrillSummaryEntryCopyWithImpl<_DrillSummaryEntry>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DrillSummaryEntry&&(identical(other.ja, ja) || other.ja == ja)&&(identical(other.score, score) || other.score == score)&&(identical(other.usage, usage) || other.usage == usage));
}


@override
int get hashCode => Object.hash(runtimeType,ja,score,usage);

@override
String toString() {
  return 'DrillSummaryEntry(ja: $ja, score: $score, usage: $usage)';
}


}

/// @nodoc
abstract mixin class _$DrillSummaryEntryCopyWith<$Res> implements $DrillSummaryEntryCopyWith<$Res> {
  factory _$DrillSummaryEntryCopyWith(_DrillSummaryEntry value, $Res Function(_DrillSummaryEntry) _then) = __$DrillSummaryEntryCopyWithImpl;
@override @useResult
$Res call({
 String ja, int score, DrillQuestionUsage usage
});


@override $DrillQuestionUsageCopyWith<$Res> get usage;

}
/// @nodoc
class __$DrillSummaryEntryCopyWithImpl<$Res>
    implements _$DrillSummaryEntryCopyWith<$Res> {
  __$DrillSummaryEntryCopyWithImpl(this._self, this._then);

  final _DrillSummaryEntry _self;
  final $Res Function(_DrillSummaryEntry) _then;

/// Create a copy of DrillSummaryEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ja = null,Object? score = null,Object? usage = null,}) {
  return _then(_DrillSummaryEntry(
ja: null == ja ? _self.ja : ja // ignore: cast_nullable_to_non_nullable
as String,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,usage: null == usage ? _self.usage : usage // ignore: cast_nullable_to_non_nullable
as DrillQuestionUsage,
  ));
}

/// Create a copy of DrillSummaryEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DrillQuestionUsageCopyWith<$Res> get usage {
  
  return $DrillQuestionUsageCopyWith<$Res>(_self.usage, (value) {
    return _then(_self.copyWith(usage: value));
  });
}
}

// dart format on
