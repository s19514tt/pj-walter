// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'speech_input_service.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SpeechInputResult {

/// 文字起こしテキスト
 String get text;/// 文字起こしに使ったトークン数（料金表示用）
 TokenUsage get usage;/// 聞こえたままの声調付きピンイン（中国語のみ。英語では null）。
/// [TranscriptionResult.reading]をそのまま透過する。
 String? get reading;
/// Create a copy of SpeechInputResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpeechInputResultCopyWith<SpeechInputResult> get copyWith => _$SpeechInputResultCopyWithImpl<SpeechInputResult>(this as SpeechInputResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SpeechInputResult&&(identical(other.text, text) || other.text == text)&&(identical(other.usage, usage) || other.usage == usage)&&(identical(other.reading, reading) || other.reading == reading));
}


@override
int get hashCode => Object.hash(runtimeType,text,usage,reading);

@override
String toString() {
  return 'SpeechInputResult(text: $text, usage: $usage, reading: $reading)';
}


}

/// @nodoc
abstract mixin class $SpeechInputResultCopyWith<$Res>  {
  factory $SpeechInputResultCopyWith(SpeechInputResult value, $Res Function(SpeechInputResult) _then) = _$SpeechInputResultCopyWithImpl;
@useResult
$Res call({
 String text, TokenUsage usage, String? reading
});


$TokenUsageCopyWith<$Res> get usage;

}
/// @nodoc
class _$SpeechInputResultCopyWithImpl<$Res>
    implements $SpeechInputResultCopyWith<$Res> {
  _$SpeechInputResultCopyWithImpl(this._self, this._then);

  final SpeechInputResult _self;
  final $Res Function(SpeechInputResult) _then;

/// Create a copy of SpeechInputResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? text = null,Object? usage = null,Object? reading = freezed,}) {
  return _then(_self.copyWith(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,usage: null == usage ? _self.usage : usage // ignore: cast_nullable_to_non_nullable
as TokenUsage,reading: freezed == reading ? _self.reading : reading // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of SpeechInputResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TokenUsageCopyWith<$Res> get usage {
  
  return $TokenUsageCopyWith<$Res>(_self.usage, (value) {
    return _then(_self.copyWith(usage: value));
  });
}
}


/// Adds pattern-matching-related methods to [SpeechInputResult].
extension SpeechInputResultPatterns on SpeechInputResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SpeechInputResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SpeechInputResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SpeechInputResult value)  $default,){
final _that = this;
switch (_that) {
case _SpeechInputResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SpeechInputResult value)?  $default,){
final _that = this;
switch (_that) {
case _SpeechInputResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String text,  TokenUsage usage,  String? reading)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SpeechInputResult() when $default != null:
return $default(_that.text,_that.usage,_that.reading);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String text,  TokenUsage usage,  String? reading)  $default,) {final _that = this;
switch (_that) {
case _SpeechInputResult():
return $default(_that.text,_that.usage,_that.reading);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String text,  TokenUsage usage,  String? reading)?  $default,) {final _that = this;
switch (_that) {
case _SpeechInputResult() when $default != null:
return $default(_that.text,_that.usage,_that.reading);case _:
  return null;

}
}

}

/// @nodoc


class _SpeechInputResult implements SpeechInputResult {
  const _SpeechInputResult({required this.text, required this.usage, this.reading});
  

/// 文字起こしテキスト
@override final  String text;
/// 文字起こしに使ったトークン数（料金表示用）
@override final  TokenUsage usage;
/// 聞こえたままの声調付きピンイン（中国語のみ。英語では null）。
/// [TranscriptionResult.reading]をそのまま透過する。
@override final  String? reading;

/// Create a copy of SpeechInputResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SpeechInputResultCopyWith<_SpeechInputResult> get copyWith => __$SpeechInputResultCopyWithImpl<_SpeechInputResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SpeechInputResult&&(identical(other.text, text) || other.text == text)&&(identical(other.usage, usage) || other.usage == usage)&&(identical(other.reading, reading) || other.reading == reading));
}


@override
int get hashCode => Object.hash(runtimeType,text,usage,reading);

@override
String toString() {
  return 'SpeechInputResult(text: $text, usage: $usage, reading: $reading)';
}


}

/// @nodoc
abstract mixin class _$SpeechInputResultCopyWith<$Res> implements $SpeechInputResultCopyWith<$Res> {
  factory _$SpeechInputResultCopyWith(_SpeechInputResult value, $Res Function(_SpeechInputResult) _then) = __$SpeechInputResultCopyWithImpl;
@override @useResult
$Res call({
 String text, TokenUsage usage, String? reading
});


@override $TokenUsageCopyWith<$Res> get usage;

}
/// @nodoc
class __$SpeechInputResultCopyWithImpl<$Res>
    implements _$SpeechInputResultCopyWith<$Res> {
  __$SpeechInputResultCopyWithImpl(this._self, this._then);

  final _SpeechInputResult _self;
  final $Res Function(_SpeechInputResult) _then;

/// Create a copy of SpeechInputResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? text = null,Object? usage = null,Object? reading = freezed,}) {
  return _then(_SpeechInputResult(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,usage: null == usage ? _self.usage : usage // ignore: cast_nullable_to_non_nullable
as TokenUsage,reading: freezed == reading ? _self.reading : reading // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of SpeechInputResult
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
