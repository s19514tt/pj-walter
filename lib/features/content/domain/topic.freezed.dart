// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'topic.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Topic {

/// `t-{連番3桁}` 形式のID（例: `t-001`）
 String get id;/// 日本語の指示文
 String get ja;/// 学習言語での指示文
 String get target;/// テーマ（`daily` / `business` / `travel`）
 String get theme;/// [target]の発音表記（中国語のピンインなど。不要な言語ではnull）
 String? get reading;
/// Create a copy of Topic
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TopicCopyWith<Topic> get copyWith => _$TopicCopyWithImpl<Topic>(this as Topic, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Topic&&(identical(other.id, id) || other.id == id)&&(identical(other.ja, ja) || other.ja == ja)&&(identical(other.target, target) || other.target == target)&&(identical(other.theme, theme) || other.theme == theme)&&(identical(other.reading, reading) || other.reading == reading));
}


@override
int get hashCode => Object.hash(runtimeType,id,ja,target,theme,reading);

@override
String toString() {
  return 'Topic(id: $id, ja: $ja, target: $target, theme: $theme, reading: $reading)';
}


}

/// @nodoc
abstract mixin class $TopicCopyWith<$Res>  {
  factory $TopicCopyWith(Topic value, $Res Function(Topic) _then) = _$TopicCopyWithImpl;
@useResult
$Res call({
 String id, String ja, String target, String theme, String? reading
});




}
/// @nodoc
class _$TopicCopyWithImpl<$Res>
    implements $TopicCopyWith<$Res> {
  _$TopicCopyWithImpl(this._self, this._then);

  final Topic _self;
  final $Res Function(Topic) _then;

/// Create a copy of Topic
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? ja = null,Object? target = null,Object? theme = null,Object? reading = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ja: null == ja ? _self.ja : ja // ignore: cast_nullable_to_non_nullable
as String,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as String,theme: null == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as String,reading: freezed == reading ? _self.reading : reading // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Topic].
extension TopicPatterns on Topic {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Topic value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Topic() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Topic value)  $default,){
final _that = this;
switch (_that) {
case _Topic():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Topic value)?  $default,){
final _that = this;
switch (_that) {
case _Topic() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String ja,  String target,  String theme,  String? reading)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Topic() when $default != null:
return $default(_that.id,_that.ja,_that.target,_that.theme,_that.reading);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String ja,  String target,  String theme,  String? reading)  $default,) {final _that = this;
switch (_that) {
case _Topic():
return $default(_that.id,_that.ja,_that.target,_that.theme,_that.reading);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String ja,  String target,  String theme,  String? reading)?  $default,) {final _that = this;
switch (_that) {
case _Topic() when $default != null:
return $default(_that.id,_that.ja,_that.target,_that.theme,_that.reading);case _:
  return null;

}
}

}

/// @nodoc


class _Topic implements Topic {
  const _Topic({required this.id, required this.ja, required this.target, required this.theme, this.reading});
  

/// `t-{連番3桁}` 形式のID（例: `t-001`）
@override final  String id;
/// 日本語の指示文
@override final  String ja;
/// 学習言語での指示文
@override final  String target;
/// テーマ（`daily` / `business` / `travel`）
@override final  String theme;
/// [target]の発音表記（中国語のピンインなど。不要な言語ではnull）
@override final  String? reading;

/// Create a copy of Topic
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TopicCopyWith<_Topic> get copyWith => __$TopicCopyWithImpl<_Topic>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Topic&&(identical(other.id, id) || other.id == id)&&(identical(other.ja, ja) || other.ja == ja)&&(identical(other.target, target) || other.target == target)&&(identical(other.theme, theme) || other.theme == theme)&&(identical(other.reading, reading) || other.reading == reading));
}


@override
int get hashCode => Object.hash(runtimeType,id,ja,target,theme,reading);

@override
String toString() {
  return 'Topic(id: $id, ja: $ja, target: $target, theme: $theme, reading: $reading)';
}


}

/// @nodoc
abstract mixin class _$TopicCopyWith<$Res> implements $TopicCopyWith<$Res> {
  factory _$TopicCopyWith(_Topic value, $Res Function(_Topic) _then) = __$TopicCopyWithImpl;
@override @useResult
$Res call({
 String id, String ja, String target, String theme, String? reading
});




}
/// @nodoc
class __$TopicCopyWithImpl<$Res>
    implements _$TopicCopyWith<$Res> {
  __$TopicCopyWithImpl(this._self, this._then);

  final _Topic _self;
  final $Res Function(_Topic) _then;

/// Create a copy of Topic
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? ja = null,Object? target = null,Object? theme = null,Object? reading = freezed,}) {
  return _then(_Topic(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ja: null == ja ? _self.ja : ja // ignore: cast_nullable_to_non_nullable
as String,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as String,theme: null == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as String,reading: freezed == reading ? _self.reading : reading // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
