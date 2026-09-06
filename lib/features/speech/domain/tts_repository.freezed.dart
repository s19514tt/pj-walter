// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tts_repository.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TtsRequest {

/// 学習言語コード（[LanguageProfile.code]）。読み上げの声・指示文がこれで決まる
 String get learningLanguage;/// 読み上げる文
 String get text;
/// Create a copy of TtsRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TtsRequestCopyWith<TtsRequest> get copyWith => _$TtsRequestCopyWithImpl<TtsRequest>(this as TtsRequest, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TtsRequest&&(identical(other.learningLanguage, learningLanguage) || other.learningLanguage == learningLanguage)&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,learningLanguage,text);

@override
String toString() {
  return 'TtsRequest(learningLanguage: $learningLanguage, text: $text)';
}


}

/// @nodoc
abstract mixin class $TtsRequestCopyWith<$Res>  {
  factory $TtsRequestCopyWith(TtsRequest value, $Res Function(TtsRequest) _then) = _$TtsRequestCopyWithImpl;
@useResult
$Res call({
 String learningLanguage, String text
});




}
/// @nodoc
class _$TtsRequestCopyWithImpl<$Res>
    implements $TtsRequestCopyWith<$Res> {
  _$TtsRequestCopyWithImpl(this._self, this._then);

  final TtsRequest _self;
  final $Res Function(TtsRequest) _then;

/// Create a copy of TtsRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? learningLanguage = null,Object? text = null,}) {
  return _then(_self.copyWith(
learningLanguage: null == learningLanguage ? _self.learningLanguage : learningLanguage // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TtsRequest].
extension TtsRequestPatterns on TtsRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TtsRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TtsRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TtsRequest value)  $default,){
final _that = this;
switch (_that) {
case _TtsRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TtsRequest value)?  $default,){
final _that = this;
switch (_that) {
case _TtsRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String learningLanguage,  String text)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TtsRequest() when $default != null:
return $default(_that.learningLanguage,_that.text);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String learningLanguage,  String text)  $default,) {final _that = this;
switch (_that) {
case _TtsRequest():
return $default(_that.learningLanguage,_that.text);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String learningLanguage,  String text)?  $default,) {final _that = this;
switch (_that) {
case _TtsRequest() when $default != null:
return $default(_that.learningLanguage,_that.text);case _:
  return null;

}
}

}

/// @nodoc


class _TtsRequest implements TtsRequest {
  const _TtsRequest({required this.learningLanguage, required this.text});
  

/// 学習言語コード（[LanguageProfile.code]）。読み上げの声・指示文がこれで決まる
@override final  String learningLanguage;
/// 読み上げる文
@override final  String text;

/// Create a copy of TtsRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TtsRequestCopyWith<_TtsRequest> get copyWith => __$TtsRequestCopyWithImpl<_TtsRequest>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TtsRequest&&(identical(other.learningLanguage, learningLanguage) || other.learningLanguage == learningLanguage)&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,learningLanguage,text);

@override
String toString() {
  return 'TtsRequest(learningLanguage: $learningLanguage, text: $text)';
}


}

/// @nodoc
abstract mixin class _$TtsRequestCopyWith<$Res> implements $TtsRequestCopyWith<$Res> {
  factory _$TtsRequestCopyWith(_TtsRequest value, $Res Function(_TtsRequest) _then) = __$TtsRequestCopyWithImpl;
@override @useResult
$Res call({
 String learningLanguage, String text
});




}
/// @nodoc
class __$TtsRequestCopyWithImpl<$Res>
    implements _$TtsRequestCopyWith<$Res> {
  __$TtsRequestCopyWithImpl(this._self, this._then);

  final _TtsRequest _self;
  final $Res Function(_TtsRequest) _then;

/// Create a copy of TtsRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? learningLanguage = null,Object? text = null,}) {
  return _then(_TtsRequest(
learningLanguage: null == learningLanguage ? _self.learningLanguage : learningLanguage // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$TtsResult {

 Uint8List get wavBytes; TokenUsage get usage;
/// Create a copy of TtsResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TtsResultCopyWith<TtsResult> get copyWith => _$TtsResultCopyWithImpl<TtsResult>(this as TtsResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TtsResult&&const DeepCollectionEquality().equals(other.wavBytes, wavBytes)&&(identical(other.usage, usage) || other.usage == usage));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(wavBytes),usage);

@override
String toString() {
  return 'TtsResult(wavBytes: $wavBytes, usage: $usage)';
}


}

/// @nodoc
abstract mixin class $TtsResultCopyWith<$Res>  {
  factory $TtsResultCopyWith(TtsResult value, $Res Function(TtsResult) _then) = _$TtsResultCopyWithImpl;
@useResult
$Res call({
 Uint8List wavBytes, TokenUsage usage
});


$TokenUsageCopyWith<$Res> get usage;

}
/// @nodoc
class _$TtsResultCopyWithImpl<$Res>
    implements $TtsResultCopyWith<$Res> {
  _$TtsResultCopyWithImpl(this._self, this._then);

  final TtsResult _self;
  final $Res Function(TtsResult) _then;

/// Create a copy of TtsResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? wavBytes = null,Object? usage = null,}) {
  return _then(_self.copyWith(
wavBytes: null == wavBytes ? _self.wavBytes : wavBytes // ignore: cast_nullable_to_non_nullable
as Uint8List,usage: null == usage ? _self.usage : usage // ignore: cast_nullable_to_non_nullable
as TokenUsage,
  ));
}
/// Create a copy of TtsResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TokenUsageCopyWith<$Res> get usage {
  
  return $TokenUsageCopyWith<$Res>(_self.usage, (value) {
    return _then(_self.copyWith(usage: value));
  });
}
}


/// Adds pattern-matching-related methods to [TtsResult].
extension TtsResultPatterns on TtsResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TtsResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TtsResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TtsResult value)  $default,){
final _that = this;
switch (_that) {
case _TtsResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TtsResult value)?  $default,){
final _that = this;
switch (_that) {
case _TtsResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Uint8List wavBytes,  TokenUsage usage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TtsResult() when $default != null:
return $default(_that.wavBytes,_that.usage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Uint8List wavBytes,  TokenUsage usage)  $default,) {final _that = this;
switch (_that) {
case _TtsResult():
return $default(_that.wavBytes,_that.usage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Uint8List wavBytes,  TokenUsage usage)?  $default,) {final _that = this;
switch (_that) {
case _TtsResult() when $default != null:
return $default(_that.wavBytes,_that.usage);case _:
  return null;

}
}

}

/// @nodoc


class _TtsResult implements TtsResult {
  const _TtsResult({required this.wavBytes, required this.usage});
  

@override final  Uint8List wavBytes;
@override final  TokenUsage usage;

/// Create a copy of TtsResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TtsResultCopyWith<_TtsResult> get copyWith => __$TtsResultCopyWithImpl<_TtsResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TtsResult&&const DeepCollectionEquality().equals(other.wavBytes, wavBytes)&&(identical(other.usage, usage) || other.usage == usage));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(wavBytes),usage);

@override
String toString() {
  return 'TtsResult(wavBytes: $wavBytes, usage: $usage)';
}


}

/// @nodoc
abstract mixin class _$TtsResultCopyWith<$Res> implements $TtsResultCopyWith<$Res> {
  factory _$TtsResultCopyWith(_TtsResult value, $Res Function(_TtsResult) _then) = __$TtsResultCopyWithImpl;
@override @useResult
$Res call({
 Uint8List wavBytes, TokenUsage usage
});


@override $TokenUsageCopyWith<$Res> get usage;

}
/// @nodoc
class __$TtsResultCopyWithImpl<$Res>
    implements _$TtsResultCopyWith<$Res> {
  __$TtsResultCopyWithImpl(this._self, this._then);

  final _TtsResult _self;
  final $Res Function(_TtsResult) _then;

/// Create a copy of TtsResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? wavBytes = null,Object? usage = null,}) {
  return _then(_TtsResult(
wavBytes: null == wavBytes ? _self.wavBytes : wavBytes // ignore: cast_nullable_to_non_nullable
as Uint8List,usage: null == usage ? _self.usage : usage // ignore: cast_nullable_to_non_nullable
as TokenUsage,
  ));
}

/// Create a copy of TtsResult
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
