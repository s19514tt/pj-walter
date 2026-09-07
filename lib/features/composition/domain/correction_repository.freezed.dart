// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'correction_repository.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CorrectionRequest {

/// 解説（`explanation` / `comparison`）を書く言語の BCP-47 コード（例: `ja`）
 String get uiLocale;/// 学習言語コード（[LanguageProfile.code]。例: `en` / `zh`）
 String get learningLanguage;/// 出題文（[uiLocale] の言語で書かれた原文）
 String get source;/// 模範解答（学習言語）
 String get modelAnswer;/// 学習者の発話（文字起こし）
 String get spoken;
/// Create a copy of CorrectionRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CorrectionRequestCopyWith<CorrectionRequest> get copyWith => _$CorrectionRequestCopyWithImpl<CorrectionRequest>(this as CorrectionRequest, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CorrectionRequest&&(identical(other.uiLocale, uiLocale) || other.uiLocale == uiLocale)&&(identical(other.learningLanguage, learningLanguage) || other.learningLanguage == learningLanguage)&&(identical(other.source, source) || other.source == source)&&(identical(other.modelAnswer, modelAnswer) || other.modelAnswer == modelAnswer)&&(identical(other.spoken, spoken) || other.spoken == spoken));
}


@override
int get hashCode => Object.hash(runtimeType,uiLocale,learningLanguage,source,modelAnswer,spoken);

@override
String toString() {
  return 'CorrectionRequest(uiLocale: $uiLocale, learningLanguage: $learningLanguage, source: $source, modelAnswer: $modelAnswer, spoken: $spoken)';
}


}

/// @nodoc
abstract mixin class $CorrectionRequestCopyWith<$Res>  {
  factory $CorrectionRequestCopyWith(CorrectionRequest value, $Res Function(CorrectionRequest) _then) = _$CorrectionRequestCopyWithImpl;
@useResult
$Res call({
 String uiLocale, String learningLanguage, String source, String modelAnswer, String spoken
});




}
/// @nodoc
class _$CorrectionRequestCopyWithImpl<$Res>
    implements $CorrectionRequestCopyWith<$Res> {
  _$CorrectionRequestCopyWithImpl(this._self, this._then);

  final CorrectionRequest _self;
  final $Res Function(CorrectionRequest) _then;

/// Create a copy of CorrectionRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uiLocale = null,Object? learningLanguage = null,Object? source = null,Object? modelAnswer = null,Object? spoken = null,}) {
  return _then(_self.copyWith(
uiLocale: null == uiLocale ? _self.uiLocale : uiLocale // ignore: cast_nullable_to_non_nullable
as String,learningLanguage: null == learningLanguage ? _self.learningLanguage : learningLanguage // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,modelAnswer: null == modelAnswer ? _self.modelAnswer : modelAnswer // ignore: cast_nullable_to_non_nullable
as String,spoken: null == spoken ? _self.spoken : spoken // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CorrectionRequest].
extension CorrectionRequestPatterns on CorrectionRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CorrectionRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CorrectionRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CorrectionRequest value)  $default,){
final _that = this;
switch (_that) {
case _CorrectionRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CorrectionRequest value)?  $default,){
final _that = this;
switch (_that) {
case _CorrectionRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uiLocale,  String learningLanguage,  String source,  String modelAnswer,  String spoken)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CorrectionRequest() when $default != null:
return $default(_that.uiLocale,_that.learningLanguage,_that.source,_that.modelAnswer,_that.spoken);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uiLocale,  String learningLanguage,  String source,  String modelAnswer,  String spoken)  $default,) {final _that = this;
switch (_that) {
case _CorrectionRequest():
return $default(_that.uiLocale,_that.learningLanguage,_that.source,_that.modelAnswer,_that.spoken);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uiLocale,  String learningLanguage,  String source,  String modelAnswer,  String spoken)?  $default,) {final _that = this;
switch (_that) {
case _CorrectionRequest() when $default != null:
return $default(_that.uiLocale,_that.learningLanguage,_that.source,_that.modelAnswer,_that.spoken);case _:
  return null;

}
}

}

/// @nodoc


class _CorrectionRequest implements CorrectionRequest {
  const _CorrectionRequest({required this.uiLocale, required this.learningLanguage, required this.source, required this.modelAnswer, required this.spoken});
  

/// 解説（`explanation` / `comparison`）を書く言語の BCP-47 コード（例: `ja`）
@override final  String uiLocale;
/// 学習言語コード（[LanguageProfile.code]。例: `en` / `zh`）
@override final  String learningLanguage;
/// 出題文（[uiLocale] の言語で書かれた原文）
@override final  String source;
/// 模範解答（学習言語）
@override final  String modelAnswer;
/// 学習者の発話（文字起こし）
@override final  String spoken;

/// Create a copy of CorrectionRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CorrectionRequestCopyWith<_CorrectionRequest> get copyWith => __$CorrectionRequestCopyWithImpl<_CorrectionRequest>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CorrectionRequest&&(identical(other.uiLocale, uiLocale) || other.uiLocale == uiLocale)&&(identical(other.learningLanguage, learningLanguage) || other.learningLanguage == learningLanguage)&&(identical(other.source, source) || other.source == source)&&(identical(other.modelAnswer, modelAnswer) || other.modelAnswer == modelAnswer)&&(identical(other.spoken, spoken) || other.spoken == spoken));
}


@override
int get hashCode => Object.hash(runtimeType,uiLocale,learningLanguage,source,modelAnswer,spoken);

@override
String toString() {
  return 'CorrectionRequest(uiLocale: $uiLocale, learningLanguage: $learningLanguage, source: $source, modelAnswer: $modelAnswer, spoken: $spoken)';
}


}

/// @nodoc
abstract mixin class _$CorrectionRequestCopyWith<$Res> implements $CorrectionRequestCopyWith<$Res> {
  factory _$CorrectionRequestCopyWith(_CorrectionRequest value, $Res Function(_CorrectionRequest) _then) = __$CorrectionRequestCopyWithImpl;
@override @useResult
$Res call({
 String uiLocale, String learningLanguage, String source, String modelAnswer, String spoken
});




}
/// @nodoc
class __$CorrectionRequestCopyWithImpl<$Res>
    implements _$CorrectionRequestCopyWith<$Res> {
  __$CorrectionRequestCopyWithImpl(this._self, this._then);

  final _CorrectionRequest _self;
  final $Res Function(_CorrectionRequest) _then;

/// Create a copy of CorrectionRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uiLocale = null,Object? learningLanguage = null,Object? source = null,Object? modelAnswer = null,Object? spoken = null,}) {
  return _then(_CorrectionRequest(
uiLocale: null == uiLocale ? _self.uiLocale : uiLocale // ignore: cast_nullable_to_non_nullable
as String,learningLanguage: null == learningLanguage ? _self.learningLanguage : learningLanguage // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,modelAnswer: null == modelAnswer ? _self.modelAnswer : modelAnswer // ignore: cast_nullable_to_non_nullable
as String,spoken: null == spoken ? _self.spoken : spoken // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$CorrectionResult {

 CompositionFeedback get feedback; TokenUsage get usage;
/// Create a copy of CorrectionResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CorrectionResultCopyWith<CorrectionResult> get copyWith => _$CorrectionResultCopyWithImpl<CorrectionResult>(this as CorrectionResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CorrectionResult&&(identical(other.feedback, feedback) || other.feedback == feedback)&&(identical(other.usage, usage) || other.usage == usage));
}


@override
int get hashCode => Object.hash(runtimeType,feedback,usage);

@override
String toString() {
  return 'CorrectionResult(feedback: $feedback, usage: $usage)';
}


}

/// @nodoc
abstract mixin class $CorrectionResultCopyWith<$Res>  {
  factory $CorrectionResultCopyWith(CorrectionResult value, $Res Function(CorrectionResult) _then) = _$CorrectionResultCopyWithImpl;
@useResult
$Res call({
 CompositionFeedback feedback, TokenUsage usage
});


$CompositionFeedbackCopyWith<$Res> get feedback;$TokenUsageCopyWith<$Res> get usage;

}
/// @nodoc
class _$CorrectionResultCopyWithImpl<$Res>
    implements $CorrectionResultCopyWith<$Res> {
  _$CorrectionResultCopyWithImpl(this._self, this._then);

  final CorrectionResult _self;
  final $Res Function(CorrectionResult) _then;

/// Create a copy of CorrectionResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? feedback = null,Object? usage = null,}) {
  return _then(_self.copyWith(
feedback: null == feedback ? _self.feedback : feedback // ignore: cast_nullable_to_non_nullable
as CompositionFeedback,usage: null == usage ? _self.usage : usage // ignore: cast_nullable_to_non_nullable
as TokenUsage,
  ));
}
/// Create a copy of CorrectionResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CompositionFeedbackCopyWith<$Res> get feedback {
  
  return $CompositionFeedbackCopyWith<$Res>(_self.feedback, (value) {
    return _then(_self.copyWith(feedback: value));
  });
}/// Create a copy of CorrectionResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TokenUsageCopyWith<$Res> get usage {
  
  return $TokenUsageCopyWith<$Res>(_self.usage, (value) {
    return _then(_self.copyWith(usage: value));
  });
}
}


/// Adds pattern-matching-related methods to [CorrectionResult].
extension CorrectionResultPatterns on CorrectionResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CorrectionResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CorrectionResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CorrectionResult value)  $default,){
final _that = this;
switch (_that) {
case _CorrectionResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CorrectionResult value)?  $default,){
final _that = this;
switch (_that) {
case _CorrectionResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CompositionFeedback feedback,  TokenUsage usage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CorrectionResult() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CompositionFeedback feedback,  TokenUsage usage)  $default,) {final _that = this;
switch (_that) {
case _CorrectionResult():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CompositionFeedback feedback,  TokenUsage usage)?  $default,) {final _that = this;
switch (_that) {
case _CorrectionResult() when $default != null:
return $default(_that.feedback,_that.usage);case _:
  return null;

}
}

}

/// @nodoc


class _CorrectionResult implements CorrectionResult {
  const _CorrectionResult({required this.feedback, required this.usage});
  

@override final  CompositionFeedback feedback;
@override final  TokenUsage usage;

/// Create a copy of CorrectionResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CorrectionResultCopyWith<_CorrectionResult> get copyWith => __$CorrectionResultCopyWithImpl<_CorrectionResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CorrectionResult&&(identical(other.feedback, feedback) || other.feedback == feedback)&&(identical(other.usage, usage) || other.usage == usage));
}


@override
int get hashCode => Object.hash(runtimeType,feedback,usage);

@override
String toString() {
  return 'CorrectionResult(feedback: $feedback, usage: $usage)';
}


}

/// @nodoc
abstract mixin class _$CorrectionResultCopyWith<$Res> implements $CorrectionResultCopyWith<$Res> {
  factory _$CorrectionResultCopyWith(_CorrectionResult value, $Res Function(_CorrectionResult) _then) = __$CorrectionResultCopyWithImpl;
@override @useResult
$Res call({
 CompositionFeedback feedback, TokenUsage usage
});


@override $CompositionFeedbackCopyWith<$Res> get feedback;@override $TokenUsageCopyWith<$Res> get usage;

}
/// @nodoc
class __$CorrectionResultCopyWithImpl<$Res>
    implements _$CorrectionResultCopyWith<$Res> {
  __$CorrectionResultCopyWithImpl(this._self, this._then);

  final _CorrectionResult _self;
  final $Res Function(_CorrectionResult) _then;

/// Create a copy of CorrectionResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? feedback = null,Object? usage = null,}) {
  return _then(_CorrectionResult(
feedback: null == feedback ? _self.feedback : feedback // ignore: cast_nullable_to_non_nullable
as CompositionFeedback,usage: null == usage ? _self.usage : usage // ignore: cast_nullable_to_non_nullable
as TokenUsage,
  ));
}

/// Create a copy of CorrectionResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CompositionFeedbackCopyWith<$Res> get feedback {
  
  return $CompositionFeedbackCopyWith<$Res>(_self.feedback, (value) {
    return _then(_self.copyWith(feedback: value));
  });
}/// Create a copy of CorrectionResult
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
