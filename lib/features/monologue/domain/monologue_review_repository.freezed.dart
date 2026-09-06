// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'monologue_review_repository.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MonologueReviewRequest {

/// 解説（`reason` / `overall_feedback` / `ja`）を書く言語の BCP-47 コード
 String get uiLocale;/// 学習言語コード（[LanguageProfile.code]）
 String get learningLanguage;/// お題（[uiLocale] の言語）
 String get topicSource;/// お題（学習言語）
 String get topicTarget;/// 発話時間（秒）
 int get seconds;/// 発話の文字起こし
 String get transcript;
/// Create a copy of MonologueReviewRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MonologueReviewRequestCopyWith<MonologueReviewRequest> get copyWith => _$MonologueReviewRequestCopyWithImpl<MonologueReviewRequest>(this as MonologueReviewRequest, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MonologueReviewRequest&&(identical(other.uiLocale, uiLocale) || other.uiLocale == uiLocale)&&(identical(other.learningLanguage, learningLanguage) || other.learningLanguage == learningLanguage)&&(identical(other.topicSource, topicSource) || other.topicSource == topicSource)&&(identical(other.topicTarget, topicTarget) || other.topicTarget == topicTarget)&&(identical(other.seconds, seconds) || other.seconds == seconds)&&(identical(other.transcript, transcript) || other.transcript == transcript));
}


@override
int get hashCode => Object.hash(runtimeType,uiLocale,learningLanguage,topicSource,topicTarget,seconds,transcript);

@override
String toString() {
  return 'MonologueReviewRequest(uiLocale: $uiLocale, learningLanguage: $learningLanguage, topicSource: $topicSource, topicTarget: $topicTarget, seconds: $seconds, transcript: $transcript)';
}


}

/// @nodoc
abstract mixin class $MonologueReviewRequestCopyWith<$Res>  {
  factory $MonologueReviewRequestCopyWith(MonologueReviewRequest value, $Res Function(MonologueReviewRequest) _then) = _$MonologueReviewRequestCopyWithImpl;
@useResult
$Res call({
 String uiLocale, String learningLanguage, String topicSource, String topicTarget, int seconds, String transcript
});




}
/// @nodoc
class _$MonologueReviewRequestCopyWithImpl<$Res>
    implements $MonologueReviewRequestCopyWith<$Res> {
  _$MonologueReviewRequestCopyWithImpl(this._self, this._then);

  final MonologueReviewRequest _self;
  final $Res Function(MonologueReviewRequest) _then;

/// Create a copy of MonologueReviewRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uiLocale = null,Object? learningLanguage = null,Object? topicSource = null,Object? topicTarget = null,Object? seconds = null,Object? transcript = null,}) {
  return _then(_self.copyWith(
uiLocale: null == uiLocale ? _self.uiLocale : uiLocale // ignore: cast_nullable_to_non_nullable
as String,learningLanguage: null == learningLanguage ? _self.learningLanguage : learningLanguage // ignore: cast_nullable_to_non_nullable
as String,topicSource: null == topicSource ? _self.topicSource : topicSource // ignore: cast_nullable_to_non_nullable
as String,topicTarget: null == topicTarget ? _self.topicTarget : topicTarget // ignore: cast_nullable_to_non_nullable
as String,seconds: null == seconds ? _self.seconds : seconds // ignore: cast_nullable_to_non_nullable
as int,transcript: null == transcript ? _self.transcript : transcript // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MonologueReviewRequest].
extension MonologueReviewRequestPatterns on MonologueReviewRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MonologueReviewRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MonologueReviewRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MonologueReviewRequest value)  $default,){
final _that = this;
switch (_that) {
case _MonologueReviewRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MonologueReviewRequest value)?  $default,){
final _that = this;
switch (_that) {
case _MonologueReviewRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uiLocale,  String learningLanguage,  String topicSource,  String topicTarget,  int seconds,  String transcript)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MonologueReviewRequest() when $default != null:
return $default(_that.uiLocale,_that.learningLanguage,_that.topicSource,_that.topicTarget,_that.seconds,_that.transcript);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uiLocale,  String learningLanguage,  String topicSource,  String topicTarget,  int seconds,  String transcript)  $default,) {final _that = this;
switch (_that) {
case _MonologueReviewRequest():
return $default(_that.uiLocale,_that.learningLanguage,_that.topicSource,_that.topicTarget,_that.seconds,_that.transcript);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uiLocale,  String learningLanguage,  String topicSource,  String topicTarget,  int seconds,  String transcript)?  $default,) {final _that = this;
switch (_that) {
case _MonologueReviewRequest() when $default != null:
return $default(_that.uiLocale,_that.learningLanguage,_that.topicSource,_that.topicTarget,_that.seconds,_that.transcript);case _:
  return null;

}
}

}

/// @nodoc


class _MonologueReviewRequest implements MonologueReviewRequest {
  const _MonologueReviewRequest({required this.uiLocale, required this.learningLanguage, required this.topicSource, required this.topicTarget, required this.seconds, required this.transcript});
  

/// 解説（`reason` / `overall_feedback` / `ja`）を書く言語の BCP-47 コード
@override final  String uiLocale;
/// 学習言語コード（[LanguageProfile.code]）
@override final  String learningLanguage;
/// お題（[uiLocale] の言語）
@override final  String topicSource;
/// お題（学習言語）
@override final  String topicTarget;
/// 発話時間（秒）
@override final  int seconds;
/// 発話の文字起こし
@override final  String transcript;

/// Create a copy of MonologueReviewRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MonologueReviewRequestCopyWith<_MonologueReviewRequest> get copyWith => __$MonologueReviewRequestCopyWithImpl<_MonologueReviewRequest>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MonologueReviewRequest&&(identical(other.uiLocale, uiLocale) || other.uiLocale == uiLocale)&&(identical(other.learningLanguage, learningLanguage) || other.learningLanguage == learningLanguage)&&(identical(other.topicSource, topicSource) || other.topicSource == topicSource)&&(identical(other.topicTarget, topicTarget) || other.topicTarget == topicTarget)&&(identical(other.seconds, seconds) || other.seconds == seconds)&&(identical(other.transcript, transcript) || other.transcript == transcript));
}


@override
int get hashCode => Object.hash(runtimeType,uiLocale,learningLanguage,topicSource,topicTarget,seconds,transcript);

@override
String toString() {
  return 'MonologueReviewRequest(uiLocale: $uiLocale, learningLanguage: $learningLanguage, topicSource: $topicSource, topicTarget: $topicTarget, seconds: $seconds, transcript: $transcript)';
}


}

/// @nodoc
abstract mixin class _$MonologueReviewRequestCopyWith<$Res> implements $MonologueReviewRequestCopyWith<$Res> {
  factory _$MonologueReviewRequestCopyWith(_MonologueReviewRequest value, $Res Function(_MonologueReviewRequest) _then) = __$MonologueReviewRequestCopyWithImpl;
@override @useResult
$Res call({
 String uiLocale, String learningLanguage, String topicSource, String topicTarget, int seconds, String transcript
});




}
/// @nodoc
class __$MonologueReviewRequestCopyWithImpl<$Res>
    implements _$MonologueReviewRequestCopyWith<$Res> {
  __$MonologueReviewRequestCopyWithImpl(this._self, this._then);

  final _MonologueReviewRequest _self;
  final $Res Function(_MonologueReviewRequest) _then;

/// Create a copy of MonologueReviewRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uiLocale = null,Object? learningLanguage = null,Object? topicSource = null,Object? topicTarget = null,Object? seconds = null,Object? transcript = null,}) {
  return _then(_MonologueReviewRequest(
uiLocale: null == uiLocale ? _self.uiLocale : uiLocale // ignore: cast_nullable_to_non_nullable
as String,learningLanguage: null == learningLanguage ? _self.learningLanguage : learningLanguage // ignore: cast_nullable_to_non_nullable
as String,topicSource: null == topicSource ? _self.topicSource : topicSource // ignore: cast_nullable_to_non_nullable
as String,topicTarget: null == topicTarget ? _self.topicTarget : topicTarget // ignore: cast_nullable_to_non_nullable
as String,seconds: null == seconds ? _self.seconds : seconds // ignore: cast_nullable_to_non_nullable
as int,transcript: null == transcript ? _self.transcript : transcript // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$MonologueReviewResult {

 MonologueFeedback get feedback; TokenUsage get usage;
/// Create a copy of MonologueReviewResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MonologueReviewResultCopyWith<MonologueReviewResult> get copyWith => _$MonologueReviewResultCopyWithImpl<MonologueReviewResult>(this as MonologueReviewResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MonologueReviewResult&&(identical(other.feedback, feedback) || other.feedback == feedback)&&(identical(other.usage, usage) || other.usage == usage));
}


@override
int get hashCode => Object.hash(runtimeType,feedback,usage);

@override
String toString() {
  return 'MonologueReviewResult(feedback: $feedback, usage: $usage)';
}


}

/// @nodoc
abstract mixin class $MonologueReviewResultCopyWith<$Res>  {
  factory $MonologueReviewResultCopyWith(MonologueReviewResult value, $Res Function(MonologueReviewResult) _then) = _$MonologueReviewResultCopyWithImpl;
@useResult
$Res call({
 MonologueFeedback feedback, TokenUsage usage
});


$MonologueFeedbackCopyWith<$Res> get feedback;$TokenUsageCopyWith<$Res> get usage;

}
/// @nodoc
class _$MonologueReviewResultCopyWithImpl<$Res>
    implements $MonologueReviewResultCopyWith<$Res> {
  _$MonologueReviewResultCopyWithImpl(this._self, this._then);

  final MonologueReviewResult _self;
  final $Res Function(MonologueReviewResult) _then;

/// Create a copy of MonologueReviewResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? feedback = null,Object? usage = null,}) {
  return _then(_self.copyWith(
feedback: null == feedback ? _self.feedback : feedback // ignore: cast_nullable_to_non_nullable
as MonologueFeedback,usage: null == usage ? _self.usage : usage // ignore: cast_nullable_to_non_nullable
as TokenUsage,
  ));
}
/// Create a copy of MonologueReviewResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MonologueFeedbackCopyWith<$Res> get feedback {
  
  return $MonologueFeedbackCopyWith<$Res>(_self.feedback, (value) {
    return _then(_self.copyWith(feedback: value));
  });
}/// Create a copy of MonologueReviewResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TokenUsageCopyWith<$Res> get usage {
  
  return $TokenUsageCopyWith<$Res>(_self.usage, (value) {
    return _then(_self.copyWith(usage: value));
  });
}
}


/// Adds pattern-matching-related methods to [MonologueReviewResult].
extension MonologueReviewResultPatterns on MonologueReviewResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MonologueReviewResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MonologueReviewResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MonologueReviewResult value)  $default,){
final _that = this;
switch (_that) {
case _MonologueReviewResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MonologueReviewResult value)?  $default,){
final _that = this;
switch (_that) {
case _MonologueReviewResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MonologueFeedback feedback,  TokenUsage usage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MonologueReviewResult() when $default != null:
return $default(_that.feedback,_that.usage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MonologueFeedback feedback,  TokenUsage usage)  $default,) {final _that = this;
switch (_that) {
case _MonologueReviewResult():
return $default(_that.feedback,_that.usage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MonologueFeedback feedback,  TokenUsage usage)?  $default,) {final _that = this;
switch (_that) {
case _MonologueReviewResult() when $default != null:
return $default(_that.feedback,_that.usage);case _:
  return null;

}
}

}

/// @nodoc


class _MonologueReviewResult implements MonologueReviewResult {
  const _MonologueReviewResult({required this.feedback, required this.usage});
  

@override final  MonologueFeedback feedback;
@override final  TokenUsage usage;

/// Create a copy of MonologueReviewResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MonologueReviewResultCopyWith<_MonologueReviewResult> get copyWith => __$MonologueReviewResultCopyWithImpl<_MonologueReviewResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MonologueReviewResult&&(identical(other.feedback, feedback) || other.feedback == feedback)&&(identical(other.usage, usage) || other.usage == usage));
}


@override
int get hashCode => Object.hash(runtimeType,feedback,usage);

@override
String toString() {
  return 'MonologueReviewResult(feedback: $feedback, usage: $usage)';
}


}

/// @nodoc
abstract mixin class _$MonologueReviewResultCopyWith<$Res> implements $MonologueReviewResultCopyWith<$Res> {
  factory _$MonologueReviewResultCopyWith(_MonologueReviewResult value, $Res Function(_MonologueReviewResult) _then) = __$MonologueReviewResultCopyWithImpl;
@override @useResult
$Res call({
 MonologueFeedback feedback, TokenUsage usage
});


@override $MonologueFeedbackCopyWith<$Res> get feedback;@override $TokenUsageCopyWith<$Res> get usage;

}
/// @nodoc
class __$MonologueReviewResultCopyWithImpl<$Res>
    implements _$MonologueReviewResultCopyWith<$Res> {
  __$MonologueReviewResultCopyWithImpl(this._self, this._then);

  final _MonologueReviewResult _self;
  final $Res Function(_MonologueReviewResult) _then;

/// Create a copy of MonologueReviewResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? feedback = null,Object? usage = null,}) {
  return _then(_MonologueReviewResult(
feedback: null == feedback ? _self.feedback : feedback // ignore: cast_nullable_to_non_nullable
as MonologueFeedback,usage: null == usage ? _self.usage : usage // ignore: cast_nullable_to_non_nullable
as TokenUsage,
  ));
}

/// Create a copy of MonologueReviewResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MonologueFeedbackCopyWith<$Res> get feedback {
  
  return $MonologueFeedbackCopyWith<$Res>(_self.feedback, (value) {
    return _then(_self.copyWith(feedback: value));
  });
}/// Create a copy of MonologueReviewResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TokenUsageCopyWith<$Res> get usage {
  
  return $TokenUsageCopyWith<$Res>(_self.usage, (value) {
    return _then(_self.copyWith(usage: value));
  });
}
}

// dart format on
