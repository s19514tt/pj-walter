// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sentence.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Sentence {

/// `s{level}-{連番3桁}` 形式のID（例: `s700-001`）
 String get id;/// 出題される日本語原文
 String get ja;/// 学習言語での模範解答
 String get target;/// テーマ（`daily` / `business` / `travel`）
 String get theme;/// 表現のヒント・解説
 String get tips;/// デッキのレベル（英語 700 / 800、中国語 3 / 4）
 int get level;/// [target]の発音表記（中国語のピンインなど。不要な言語ではnull）
 String? get reading;
/// Create a copy of Sentence
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SentenceCopyWith<Sentence> get copyWith => _$SentenceCopyWithImpl<Sentence>(this as Sentence, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Sentence&&(identical(other.id, id) || other.id == id)&&(identical(other.ja, ja) || other.ja == ja)&&(identical(other.target, target) || other.target == target)&&(identical(other.theme, theme) || other.theme == theme)&&(identical(other.tips, tips) || other.tips == tips)&&(identical(other.level, level) || other.level == level)&&(identical(other.reading, reading) || other.reading == reading));
}


@override
int get hashCode => Object.hash(runtimeType,id,ja,target,theme,tips,level,reading);

@override
String toString() {
  return 'Sentence(id: $id, ja: $ja, target: $target, theme: $theme, tips: $tips, level: $level, reading: $reading)';
}


}

/// @nodoc
abstract mixin class $SentenceCopyWith<$Res>  {
  factory $SentenceCopyWith(Sentence value, $Res Function(Sentence) _then) = _$SentenceCopyWithImpl;
@useResult
$Res call({
 String id, String ja, String target, String theme, String tips, int level, String? reading
});




}
/// @nodoc
class _$SentenceCopyWithImpl<$Res>
    implements $SentenceCopyWith<$Res> {
  _$SentenceCopyWithImpl(this._self, this._then);

  final Sentence _self;
  final $Res Function(Sentence) _then;

/// Create a copy of Sentence
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? ja = null,Object? target = null,Object? theme = null,Object? tips = null,Object? level = null,Object? reading = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ja: null == ja ? _self.ja : ja // ignore: cast_nullable_to_non_nullable
as String,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as String,theme: null == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as String,tips: null == tips ? _self.tips : tips // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,reading: freezed == reading ? _self.reading : reading // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Sentence].
extension SentencePatterns on Sentence {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Sentence value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Sentence() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Sentence value)  $default,){
final _that = this;
switch (_that) {
case _Sentence():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Sentence value)?  $default,){
final _that = this;
switch (_that) {
case _Sentence() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String ja,  String target,  String theme,  String tips,  int level,  String? reading)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Sentence() when $default != null:
return $default(_that.id,_that.ja,_that.target,_that.theme,_that.tips,_that.level,_that.reading);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String ja,  String target,  String theme,  String tips,  int level,  String? reading)  $default,) {final _that = this;
switch (_that) {
case _Sentence():
return $default(_that.id,_that.ja,_that.target,_that.theme,_that.tips,_that.level,_that.reading);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String ja,  String target,  String theme,  String tips,  int level,  String? reading)?  $default,) {final _that = this;
switch (_that) {
case _Sentence() when $default != null:
return $default(_that.id,_that.ja,_that.target,_that.theme,_that.tips,_that.level,_that.reading);case _:
  return null;

}
}

}

/// @nodoc


class _Sentence implements Sentence {
  const _Sentence({required this.id, required this.ja, required this.target, required this.theme, required this.tips, required this.level, this.reading});
  

/// `s{level}-{連番3桁}` 形式のID（例: `s700-001`）
@override final  String id;
/// 出題される日本語原文
@override final  String ja;
/// 学習言語での模範解答
@override final  String target;
/// テーマ（`daily` / `business` / `travel`）
@override final  String theme;
/// 表現のヒント・解説
@override final  String tips;
/// デッキのレベル（英語 700 / 800、中国語 3 / 4）
@override final  int level;
/// [target]の発音表記（中国語のピンインなど。不要な言語ではnull）
@override final  String? reading;

/// Create a copy of Sentence
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SentenceCopyWith<_Sentence> get copyWith => __$SentenceCopyWithImpl<_Sentence>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Sentence&&(identical(other.id, id) || other.id == id)&&(identical(other.ja, ja) || other.ja == ja)&&(identical(other.target, target) || other.target == target)&&(identical(other.theme, theme) || other.theme == theme)&&(identical(other.tips, tips) || other.tips == tips)&&(identical(other.level, level) || other.level == level)&&(identical(other.reading, reading) || other.reading == reading));
}


@override
int get hashCode => Object.hash(runtimeType,id,ja,target,theme,tips,level,reading);

@override
String toString() {
  return 'Sentence(id: $id, ja: $ja, target: $target, theme: $theme, tips: $tips, level: $level, reading: $reading)';
}


}

/// @nodoc
abstract mixin class _$SentenceCopyWith<$Res> implements $SentenceCopyWith<$Res> {
  factory _$SentenceCopyWith(_Sentence value, $Res Function(_Sentence) _then) = __$SentenceCopyWithImpl;
@override @useResult
$Res call({
 String id, String ja, String target, String theme, String tips, int level, String? reading
});




}
/// @nodoc
class __$SentenceCopyWithImpl<$Res>
    implements _$SentenceCopyWith<$Res> {
  __$SentenceCopyWithImpl(this._self, this._then);

  final _Sentence _self;
  final $Res Function(_Sentence) _then;

/// Create a copy of Sentence
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? ja = null,Object? target = null,Object? theme = null,Object? tips = null,Object? level = null,Object? reading = freezed,}) {
  return _then(_Sentence(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ja: null == ja ? _self.ja : ja // ignore: cast_nullable_to_non_nullable
as String,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as String,theme: null == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as String,tips: null == tips ? _self.tips : tips // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,reading: freezed == reading ? _self.reading : reading // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
