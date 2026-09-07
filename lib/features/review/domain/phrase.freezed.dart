// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'phrase.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Phrase {

/// エントリのuuid
 String get id;/// 学習言語での表現
 String get target;/// 日本語訳
 String get ja;/// 追加元（例: お題ID）
 String get source;/// 追加日時
 DateTime get createdAt;
/// Create a copy of Phrase
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PhraseCopyWith<Phrase> get copyWith => _$PhraseCopyWithImpl<Phrase>(this as Phrase, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Phrase&&(identical(other.id, id) || other.id == id)&&(identical(other.target, target) || other.target == target)&&(identical(other.ja, ja) || other.ja == ja)&&(identical(other.source, source) || other.source == source)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,target,ja,source,createdAt);

@override
String toString() {
  return 'Phrase(id: $id, target: $target, ja: $ja, source: $source, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $PhraseCopyWith<$Res>  {
  factory $PhraseCopyWith(Phrase value, $Res Function(Phrase) _then) = _$PhraseCopyWithImpl;
@useResult
$Res call({
 String id, String target, String ja, String source, DateTime createdAt
});




}
/// @nodoc
class _$PhraseCopyWithImpl<$Res>
    implements $PhraseCopyWith<$Res> {
  _$PhraseCopyWithImpl(this._self, this._then);

  final Phrase _self;
  final $Res Function(Phrase) _then;

/// Create a copy of Phrase
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? target = null,Object? ja = null,Object? source = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as String,ja: null == ja ? _self.ja : ja // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Phrase].
extension PhrasePatterns on Phrase {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Phrase value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Phrase() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Phrase value)  $default,){
final _that = this;
switch (_that) {
case _Phrase():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Phrase value)?  $default,){
final _that = this;
switch (_that) {
case _Phrase() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String target,  String ja,  String source,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Phrase() when $default != null:
return $default(_that.id,_that.target,_that.ja,_that.source,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String target,  String ja,  String source,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _Phrase():
return $default(_that.id,_that.target,_that.ja,_that.source,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String target,  String ja,  String source,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Phrase() when $default != null:
return $default(_that.id,_that.target,_that.ja,_that.source,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _Phrase implements Phrase {
  const _Phrase({required this.id, required this.target, required this.ja, required this.source, required this.createdAt});
  

/// エントリのuuid
@override final  String id;
/// 学習言語での表現
@override final  String target;
/// 日本語訳
@override final  String ja;
/// 追加元（例: お題ID）
@override final  String source;
/// 追加日時
@override final  DateTime createdAt;

/// Create a copy of Phrase
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PhraseCopyWith<_Phrase> get copyWith => __$PhraseCopyWithImpl<_Phrase>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Phrase&&(identical(other.id, id) || other.id == id)&&(identical(other.target, target) || other.target == target)&&(identical(other.ja, ja) || other.ja == ja)&&(identical(other.source, source) || other.source == source)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,target,ja,source,createdAt);

@override
String toString() {
  return 'Phrase(id: $id, target: $target, ja: $ja, source: $source, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$PhraseCopyWith<$Res> implements $PhraseCopyWith<$Res> {
  factory _$PhraseCopyWith(_Phrase value, $Res Function(_Phrase) _then) = __$PhraseCopyWithImpl;
@override @useResult
$Res call({
 String id, String target, String ja, String source, DateTime createdAt
});




}
/// @nodoc
class __$PhraseCopyWithImpl<$Res>
    implements _$PhraseCopyWith<$Res> {
  __$PhraseCopyWithImpl(this._self, this._then);

  final _Phrase _self;
  final $Res Function(_Phrase) _then;

/// Create a copy of Phrase
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? target = null,Object? ja = null,Object? source = null,Object? createdAt = null,}) {
  return _then(_Phrase(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as String,ja: null == ja ? _self.ja : ja // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
