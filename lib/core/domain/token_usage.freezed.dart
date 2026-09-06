// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'token_usage.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TokenUsage {

/// 入力（プロンプト＋音声など）のトークン数
 int get promptTokens;/// 返答本文の出力トークン数
 int get candidatesTokens;/// 思考（thinking）に使われた出力トークン数
 int get thoughtsTokens;
/// Create a copy of TokenUsage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TokenUsageCopyWith<TokenUsage> get copyWith => _$TokenUsageCopyWithImpl<TokenUsage>(this as TokenUsage, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TokenUsage&&(identical(other.promptTokens, promptTokens) || other.promptTokens == promptTokens)&&(identical(other.candidatesTokens, candidatesTokens) || other.candidatesTokens == candidatesTokens)&&(identical(other.thoughtsTokens, thoughtsTokens) || other.thoughtsTokens == thoughtsTokens));
}


@override
int get hashCode => Object.hash(runtimeType,promptTokens,candidatesTokens,thoughtsTokens);

@override
String toString() {
  return 'TokenUsage(promptTokens: $promptTokens, candidatesTokens: $candidatesTokens, thoughtsTokens: $thoughtsTokens)';
}


}

/// @nodoc
abstract mixin class $TokenUsageCopyWith<$Res>  {
  factory $TokenUsageCopyWith(TokenUsage value, $Res Function(TokenUsage) _then) = _$TokenUsageCopyWithImpl;
@useResult
$Res call({
 int promptTokens, int candidatesTokens, int thoughtsTokens
});




}
/// @nodoc
class _$TokenUsageCopyWithImpl<$Res>
    implements $TokenUsageCopyWith<$Res> {
  _$TokenUsageCopyWithImpl(this._self, this._then);

  final TokenUsage _self;
  final $Res Function(TokenUsage) _then;

/// Create a copy of TokenUsage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? promptTokens = null,Object? candidatesTokens = null,Object? thoughtsTokens = null,}) {
  return _then(_self.copyWith(
promptTokens: null == promptTokens ? _self.promptTokens : promptTokens // ignore: cast_nullable_to_non_nullable
as int,candidatesTokens: null == candidatesTokens ? _self.candidatesTokens : candidatesTokens // ignore: cast_nullable_to_non_nullable
as int,thoughtsTokens: null == thoughtsTokens ? _self.thoughtsTokens : thoughtsTokens // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TokenUsage].
extension TokenUsagePatterns on TokenUsage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TokenUsage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TokenUsage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TokenUsage value)  $default,){
final _that = this;
switch (_that) {
case _TokenUsage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TokenUsage value)?  $default,){
final _that = this;
switch (_that) {
case _TokenUsage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int promptTokens,  int candidatesTokens,  int thoughtsTokens)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TokenUsage() when $default != null:
return $default(_that.promptTokens,_that.candidatesTokens,_that.thoughtsTokens);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int promptTokens,  int candidatesTokens,  int thoughtsTokens)  $default,) {final _that = this;
switch (_that) {
case _TokenUsage():
return $default(_that.promptTokens,_that.candidatesTokens,_that.thoughtsTokens);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int promptTokens,  int candidatesTokens,  int thoughtsTokens)?  $default,) {final _that = this;
switch (_that) {
case _TokenUsage() when $default != null:
return $default(_that.promptTokens,_that.candidatesTokens,_that.thoughtsTokens);case _:
  return null;

}
}

}

/// @nodoc


class _TokenUsage extends TokenUsage {
  const _TokenUsage({required this.promptTokens, required this.candidatesTokens, this.thoughtsTokens = 0}): super._();
  

/// 入力（プロンプト＋音声など）のトークン数
@override final  int promptTokens;
/// 返答本文の出力トークン数
@override final  int candidatesTokens;
/// 思考（thinking）に使われた出力トークン数
@override@JsonKey() final  int thoughtsTokens;

/// Create a copy of TokenUsage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TokenUsageCopyWith<_TokenUsage> get copyWith => __$TokenUsageCopyWithImpl<_TokenUsage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TokenUsage&&(identical(other.promptTokens, promptTokens) || other.promptTokens == promptTokens)&&(identical(other.candidatesTokens, candidatesTokens) || other.candidatesTokens == candidatesTokens)&&(identical(other.thoughtsTokens, thoughtsTokens) || other.thoughtsTokens == thoughtsTokens));
}


@override
int get hashCode => Object.hash(runtimeType,promptTokens,candidatesTokens,thoughtsTokens);

@override
String toString() {
  return 'TokenUsage(promptTokens: $promptTokens, candidatesTokens: $candidatesTokens, thoughtsTokens: $thoughtsTokens)';
}


}

/// @nodoc
abstract mixin class _$TokenUsageCopyWith<$Res> implements $TokenUsageCopyWith<$Res> {
  factory _$TokenUsageCopyWith(_TokenUsage value, $Res Function(_TokenUsage) _then) = __$TokenUsageCopyWithImpl;
@override @useResult
$Res call({
 int promptTokens, int candidatesTokens, int thoughtsTokens
});




}
/// @nodoc
class __$TokenUsageCopyWithImpl<$Res>
    implements _$TokenUsageCopyWith<$Res> {
  __$TokenUsageCopyWithImpl(this._self, this._then);

  final _TokenUsage _self;
  final $Res Function(_TokenUsage) _then;

/// Create a copy of TokenUsage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? promptTokens = null,Object? candidatesTokens = null,Object? thoughtsTokens = null,}) {
  return _then(_TokenUsage(
promptTokens: null == promptTokens ? _self.promptTokens : promptTokens // ignore: cast_nullable_to_non_nullable
as int,candidatesTokens: null == candidatesTokens ? _self.candidatesTokens : candidatesTokens // ignore: cast_nullable_to_non_nullable
as int,thoughtsTokens: null == thoughtsTokens ? _self.thoughtsTokens : thoughtsTokens // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
