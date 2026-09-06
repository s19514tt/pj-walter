// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'srs_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SrsItem {

/// 対象の[Sentence]のid（Hive boxのキーとしても使う）
 String get sentenceId;/// 対象文の学習言語コード（[LanguageProfile.code]）
 String get language;/// 対象文のデッキレベル
 int get level;/// 復習段階（0〜4。5で卒業）
 int get stage;/// 次回復習予定日（時刻は無視し日単位で比較する）
 DateTime get dueDate;/// 失敗（不正解）した回数
 int get lapses;/// 直近の復習結果（正解=true）
 bool get lastResult;
/// Create a copy of SrsItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SrsItemCopyWith<SrsItem> get copyWith => _$SrsItemCopyWithImpl<SrsItem>(this as SrsItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SrsItem&&(identical(other.sentenceId, sentenceId) || other.sentenceId == sentenceId)&&(identical(other.language, language) || other.language == language)&&(identical(other.level, level) || other.level == level)&&(identical(other.stage, stage) || other.stage == stage)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.lapses, lapses) || other.lapses == lapses)&&(identical(other.lastResult, lastResult) || other.lastResult == lastResult));
}


@override
int get hashCode => Object.hash(runtimeType,sentenceId,language,level,stage,dueDate,lapses,lastResult);

@override
String toString() {
  return 'SrsItem(sentenceId: $sentenceId, language: $language, level: $level, stage: $stage, dueDate: $dueDate, lapses: $lapses, lastResult: $lastResult)';
}


}

/// @nodoc
abstract mixin class $SrsItemCopyWith<$Res>  {
  factory $SrsItemCopyWith(SrsItem value, $Res Function(SrsItem) _then) = _$SrsItemCopyWithImpl;
@useResult
$Res call({
 String sentenceId, String language, int level, int stage, DateTime dueDate, int lapses, bool lastResult
});




}
/// @nodoc
class _$SrsItemCopyWithImpl<$Res>
    implements $SrsItemCopyWith<$Res> {
  _$SrsItemCopyWithImpl(this._self, this._then);

  final SrsItem _self;
  final $Res Function(SrsItem) _then;

/// Create a copy of SrsItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sentenceId = null,Object? language = null,Object? level = null,Object? stage = null,Object? dueDate = null,Object? lapses = null,Object? lastResult = null,}) {
  return _then(_self.copyWith(
sentenceId: null == sentenceId ? _self.sentenceId : sentenceId // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,stage: null == stage ? _self.stage : stage // ignore: cast_nullable_to_non_nullable
as int,dueDate: null == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime,lapses: null == lapses ? _self.lapses : lapses // ignore: cast_nullable_to_non_nullable
as int,lastResult: null == lastResult ? _self.lastResult : lastResult // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SrsItem].
extension SrsItemPatterns on SrsItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SrsItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SrsItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SrsItem value)  $default,){
final _that = this;
switch (_that) {
case _SrsItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SrsItem value)?  $default,){
final _that = this;
switch (_that) {
case _SrsItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String sentenceId,  String language,  int level,  int stage,  DateTime dueDate,  int lapses,  bool lastResult)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SrsItem() when $default != null:
return $default(_that.sentenceId,_that.language,_that.level,_that.stage,_that.dueDate,_that.lapses,_that.lastResult);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String sentenceId,  String language,  int level,  int stage,  DateTime dueDate,  int lapses,  bool lastResult)  $default,) {final _that = this;
switch (_that) {
case _SrsItem():
return $default(_that.sentenceId,_that.language,_that.level,_that.stage,_that.dueDate,_that.lapses,_that.lastResult);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String sentenceId,  String language,  int level,  int stage,  DateTime dueDate,  int lapses,  bool lastResult)?  $default,) {final _that = this;
switch (_that) {
case _SrsItem() when $default != null:
return $default(_that.sentenceId,_that.language,_that.level,_that.stage,_that.dueDate,_that.lapses,_that.lastResult);case _:
  return null;

}
}

}

/// @nodoc


class _SrsItem implements SrsItem {
  const _SrsItem({required this.sentenceId, required this.language, required this.level, required this.stage, required this.dueDate, required this.lapses, required this.lastResult});
  

/// 対象の[Sentence]のid（Hive boxのキーとしても使う）
@override final  String sentenceId;
/// 対象文の学習言語コード（[LanguageProfile.code]）
@override final  String language;
/// 対象文のデッキレベル
@override final  int level;
/// 復習段階（0〜4。5で卒業）
@override final  int stage;
/// 次回復習予定日（時刻は無視し日単位で比較する）
@override final  DateTime dueDate;
/// 失敗（不正解）した回数
@override final  int lapses;
/// 直近の復習結果（正解=true）
@override final  bool lastResult;

/// Create a copy of SrsItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SrsItemCopyWith<_SrsItem> get copyWith => __$SrsItemCopyWithImpl<_SrsItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SrsItem&&(identical(other.sentenceId, sentenceId) || other.sentenceId == sentenceId)&&(identical(other.language, language) || other.language == language)&&(identical(other.level, level) || other.level == level)&&(identical(other.stage, stage) || other.stage == stage)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.lapses, lapses) || other.lapses == lapses)&&(identical(other.lastResult, lastResult) || other.lastResult == lastResult));
}


@override
int get hashCode => Object.hash(runtimeType,sentenceId,language,level,stage,dueDate,lapses,lastResult);

@override
String toString() {
  return 'SrsItem(sentenceId: $sentenceId, language: $language, level: $level, stage: $stage, dueDate: $dueDate, lapses: $lapses, lastResult: $lastResult)';
}


}

/// @nodoc
abstract mixin class _$SrsItemCopyWith<$Res> implements $SrsItemCopyWith<$Res> {
  factory _$SrsItemCopyWith(_SrsItem value, $Res Function(_SrsItem) _then) = __$SrsItemCopyWithImpl;
@override @useResult
$Res call({
 String sentenceId, String language, int level, int stage, DateTime dueDate, int lapses, bool lastResult
});




}
/// @nodoc
class __$SrsItemCopyWithImpl<$Res>
    implements _$SrsItemCopyWith<$Res> {
  __$SrsItemCopyWithImpl(this._self, this._then);

  final _SrsItem _self;
  final $Res Function(_SrsItem) _then;

/// Create a copy of SrsItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sentenceId = null,Object? language = null,Object? level = null,Object? stage = null,Object? dueDate = null,Object? lapses = null,Object? lastResult = null,}) {
  return _then(_SrsItem(
sentenceId: null == sentenceId ? _self.sentenceId : sentenceId // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,stage: null == stage ? _self.stage : stage // ignore: cast_nullable_to_non_nullable
as int,dueDate: null == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime,lapses: null == lapses ? _self.lapses : lapses // ignore: cast_nullable_to_non_nullable
as int,lastResult: null == lastResult ? _self.lastResult : lastResult // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
