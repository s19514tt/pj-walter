// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transcription_repository.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TranscriptionRequest {

/// 学習言語コード（[LanguageProfile.code]）。聞き取る言語と、読み表記を
/// 併記するかどうか（中国語）がこれで決まる
 String get learningLanguage;/// 音声データ（WAV 推奨、16kHz mono）
 List<int> get audioBytes;/// [audioBytes] の MIME タイプ（例: `audio/wav`）
 String get mimeType;
/// Create a copy of TranscriptionRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TranscriptionRequestCopyWith<TranscriptionRequest> get copyWith => _$TranscriptionRequestCopyWithImpl<TranscriptionRequest>(this as TranscriptionRequest, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TranscriptionRequest&&(identical(other.learningLanguage, learningLanguage) || other.learningLanguage == learningLanguage)&&const DeepCollectionEquality().equals(other.audioBytes, audioBytes)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType));
}


@override
int get hashCode => Object.hash(runtimeType,learningLanguage,const DeepCollectionEquality().hash(audioBytes),mimeType);

@override
String toString() {
  return 'TranscriptionRequest(learningLanguage: $learningLanguage, audioBytes: $audioBytes, mimeType: $mimeType)';
}


}

/// @nodoc
abstract mixin class $TranscriptionRequestCopyWith<$Res>  {
  factory $TranscriptionRequestCopyWith(TranscriptionRequest value, $Res Function(TranscriptionRequest) _then) = _$TranscriptionRequestCopyWithImpl;
@useResult
$Res call({
 String learningLanguage, List<int> audioBytes, String mimeType
});




}
/// @nodoc
class _$TranscriptionRequestCopyWithImpl<$Res>
    implements $TranscriptionRequestCopyWith<$Res> {
  _$TranscriptionRequestCopyWithImpl(this._self, this._then);

  final TranscriptionRequest _self;
  final $Res Function(TranscriptionRequest) _then;

/// Create a copy of TranscriptionRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? learningLanguage = null,Object? audioBytes = null,Object? mimeType = null,}) {
  return _then(_self.copyWith(
learningLanguage: null == learningLanguage ? _self.learningLanguage : learningLanguage // ignore: cast_nullable_to_non_nullable
as String,audioBytes: null == audioBytes ? _self.audioBytes : audioBytes // ignore: cast_nullable_to_non_nullable
as List<int>,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TranscriptionRequest].
extension TranscriptionRequestPatterns on TranscriptionRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TranscriptionRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TranscriptionRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TranscriptionRequest value)  $default,){
final _that = this;
switch (_that) {
case _TranscriptionRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TranscriptionRequest value)?  $default,){
final _that = this;
switch (_that) {
case _TranscriptionRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String learningLanguage,  List<int> audioBytes,  String mimeType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TranscriptionRequest() when $default != null:
return $default(_that.learningLanguage,_that.audioBytes,_that.mimeType);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String learningLanguage,  List<int> audioBytes,  String mimeType)  $default,) {final _that = this;
switch (_that) {
case _TranscriptionRequest():
return $default(_that.learningLanguage,_that.audioBytes,_that.mimeType);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String learningLanguage,  List<int> audioBytes,  String mimeType)?  $default,) {final _that = this;
switch (_that) {
case _TranscriptionRequest() when $default != null:
return $default(_that.learningLanguage,_that.audioBytes,_that.mimeType);case _:
  return null;

}
}

}

/// @nodoc


class _TranscriptionRequest implements TranscriptionRequest {
  const _TranscriptionRequest({required this.learningLanguage, required final  List<int> audioBytes, required this.mimeType}): _audioBytes = audioBytes;
  

/// 学習言語コード（[LanguageProfile.code]）。聞き取る言語と、読み表記を
/// 併記するかどうか（中国語）がこれで決まる
@override final  String learningLanguage;
/// 音声データ（WAV 推奨、16kHz mono）
 final  List<int> _audioBytes;
/// 音声データ（WAV 推奨、16kHz mono）
@override List<int> get audioBytes {
  if (_audioBytes is EqualUnmodifiableListView) return _audioBytes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_audioBytes);
}

/// [audioBytes] の MIME タイプ（例: `audio/wav`）
@override final  String mimeType;

/// Create a copy of TranscriptionRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TranscriptionRequestCopyWith<_TranscriptionRequest> get copyWith => __$TranscriptionRequestCopyWithImpl<_TranscriptionRequest>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TranscriptionRequest&&(identical(other.learningLanguage, learningLanguage) || other.learningLanguage == learningLanguage)&&const DeepCollectionEquality().equals(other._audioBytes, _audioBytes)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType));
}


@override
int get hashCode => Object.hash(runtimeType,learningLanguage,const DeepCollectionEquality().hash(_audioBytes),mimeType);

@override
String toString() {
  return 'TranscriptionRequest(learningLanguage: $learningLanguage, audioBytes: $audioBytes, mimeType: $mimeType)';
}


}

/// @nodoc
abstract mixin class _$TranscriptionRequestCopyWith<$Res> implements $TranscriptionRequestCopyWith<$Res> {
  factory _$TranscriptionRequestCopyWith(_TranscriptionRequest value, $Res Function(_TranscriptionRequest) _then) = __$TranscriptionRequestCopyWithImpl;
@override @useResult
$Res call({
 String learningLanguage, List<int> audioBytes, String mimeType
});




}
/// @nodoc
class __$TranscriptionRequestCopyWithImpl<$Res>
    implements _$TranscriptionRequestCopyWith<$Res> {
  __$TranscriptionRequestCopyWithImpl(this._self, this._then);

  final _TranscriptionRequest _self;
  final $Res Function(_TranscriptionRequest) _then;

/// Create a copy of TranscriptionRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? learningLanguage = null,Object? audioBytes = null,Object? mimeType = null,}) {
  return _then(_TranscriptionRequest(
learningLanguage: null == learningLanguage ? _self.learningLanguage : learningLanguage // ignore: cast_nullable_to_non_nullable
as String,audioBytes: null == audioBytes ? _self._audioBytes : audioBytes // ignore: cast_nullable_to_non_nullable
as List<int>,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$TranscriptionResult {

 String get text; TokenUsage get usage; String? get reading;
/// Create a copy of TranscriptionResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TranscriptionResultCopyWith<TranscriptionResult> get copyWith => _$TranscriptionResultCopyWithImpl<TranscriptionResult>(this as TranscriptionResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TranscriptionResult&&(identical(other.text, text) || other.text == text)&&(identical(other.usage, usage) || other.usage == usage)&&(identical(other.reading, reading) || other.reading == reading));
}


@override
int get hashCode => Object.hash(runtimeType,text,usage,reading);

@override
String toString() {
  return 'TranscriptionResult(text: $text, usage: $usage, reading: $reading)';
}


}

/// @nodoc
abstract mixin class $TranscriptionResultCopyWith<$Res>  {
  factory $TranscriptionResultCopyWith(TranscriptionResult value, $Res Function(TranscriptionResult) _then) = _$TranscriptionResultCopyWithImpl;
@useResult
$Res call({
 String text, TokenUsage usage, String? reading
});


$TokenUsageCopyWith<$Res> get usage;

}
/// @nodoc
class _$TranscriptionResultCopyWithImpl<$Res>
    implements $TranscriptionResultCopyWith<$Res> {
  _$TranscriptionResultCopyWithImpl(this._self, this._then);

  final TranscriptionResult _self;
  final $Res Function(TranscriptionResult) _then;

/// Create a copy of TranscriptionResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? text = null,Object? usage = null,Object? reading = freezed,}) {
  return _then(_self.copyWith(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,usage: null == usage ? _self.usage : usage // ignore: cast_nullable_to_non_nullable
as TokenUsage,reading: freezed == reading ? _self.reading : reading // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of TranscriptionResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TokenUsageCopyWith<$Res> get usage {
  
  return $TokenUsageCopyWith<$Res>(_self.usage, (value) {
    return _then(_self.copyWith(usage: value));
  });
}
}


/// Adds pattern-matching-related methods to [TranscriptionResult].
extension TranscriptionResultPatterns on TranscriptionResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TranscriptionResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TranscriptionResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TranscriptionResult value)  $default,){
final _that = this;
switch (_that) {
case _TranscriptionResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TranscriptionResult value)?  $default,){
final _that = this;
switch (_that) {
case _TranscriptionResult() when $default != null:
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
case _TranscriptionResult() when $default != null:
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
case _TranscriptionResult():
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
case _TranscriptionResult() when $default != null:
return $default(_that.text,_that.usage,_that.reading);case _:
  return null;

}
}

}

/// @nodoc


class _TranscriptionResult implements TranscriptionResult {
  const _TranscriptionResult({required this.text, required this.usage, this.reading});
  

@override final  String text;
@override final  TokenUsage usage;
@override final  String? reading;

/// Create a copy of TranscriptionResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TranscriptionResultCopyWith<_TranscriptionResult> get copyWith => __$TranscriptionResultCopyWithImpl<_TranscriptionResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TranscriptionResult&&(identical(other.text, text) || other.text == text)&&(identical(other.usage, usage) || other.usage == usage)&&(identical(other.reading, reading) || other.reading == reading));
}


@override
int get hashCode => Object.hash(runtimeType,text,usage,reading);

@override
String toString() {
  return 'TranscriptionResult(text: $text, usage: $usage, reading: $reading)';
}


}

/// @nodoc
abstract mixin class _$TranscriptionResultCopyWith<$Res> implements $TranscriptionResultCopyWith<$Res> {
  factory _$TranscriptionResultCopyWith(_TranscriptionResult value, $Res Function(_TranscriptionResult) _then) = __$TranscriptionResultCopyWithImpl;
@override @useResult
$Res call({
 String text, TokenUsage usage, String? reading
});


@override $TokenUsageCopyWith<$Res> get usage;

}
/// @nodoc
class __$TranscriptionResultCopyWithImpl<$Res>
    implements _$TranscriptionResultCopyWith<$Res> {
  __$TranscriptionResultCopyWithImpl(this._self, this._then);

  final _TranscriptionResult _self;
  final $Res Function(_TranscriptionResult) _then;

/// Create a copy of TranscriptionResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? text = null,Object? usage = null,Object? reading = freezed,}) {
  return _then(_TranscriptionResult(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,usage: null == usage ? _self.usage : usage // ignore: cast_nullable_to_non_nullable
as TokenUsage,reading: freezed == reading ? _self.reading : reading // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of TranscriptionResult
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
