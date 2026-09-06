// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'daily_stats.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DailyStats {

/// 口頭作文の回答数
 int get drillCount;/// 独り言の実施回数
 int get monologueCount;/// 学習秒数（独り言の発話時間の合計）
 int get studySeconds;
/// Create a copy of DailyStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DailyStatsCopyWith<DailyStats> get copyWith => _$DailyStatsCopyWithImpl<DailyStats>(this as DailyStats, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailyStats&&(identical(other.drillCount, drillCount) || other.drillCount == drillCount)&&(identical(other.monologueCount, monologueCount) || other.monologueCount == monologueCount)&&(identical(other.studySeconds, studySeconds) || other.studySeconds == studySeconds));
}


@override
int get hashCode => Object.hash(runtimeType,drillCount,monologueCount,studySeconds);

@override
String toString() {
  return 'DailyStats(drillCount: $drillCount, monologueCount: $monologueCount, studySeconds: $studySeconds)';
}


}

/// @nodoc
abstract mixin class $DailyStatsCopyWith<$Res>  {
  factory $DailyStatsCopyWith(DailyStats value, $Res Function(DailyStats) _then) = _$DailyStatsCopyWithImpl;
@useResult
$Res call({
 int drillCount, int monologueCount, int studySeconds
});




}
/// @nodoc
class _$DailyStatsCopyWithImpl<$Res>
    implements $DailyStatsCopyWith<$Res> {
  _$DailyStatsCopyWithImpl(this._self, this._then);

  final DailyStats _self;
  final $Res Function(DailyStats) _then;

/// Create a copy of DailyStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? drillCount = null,Object? monologueCount = null,Object? studySeconds = null,}) {
  return _then(_self.copyWith(
drillCount: null == drillCount ? _self.drillCount : drillCount // ignore: cast_nullable_to_non_nullable
as int,monologueCount: null == monologueCount ? _self.monologueCount : monologueCount // ignore: cast_nullable_to_non_nullable
as int,studySeconds: null == studySeconds ? _self.studySeconds : studySeconds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [DailyStats].
extension DailyStatsPatterns on DailyStats {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DailyStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DailyStats() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DailyStats value)  $default,){
final _that = this;
switch (_that) {
case _DailyStats():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DailyStats value)?  $default,){
final _that = this;
switch (_that) {
case _DailyStats() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int drillCount,  int monologueCount,  int studySeconds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DailyStats() when $default != null:
return $default(_that.drillCount,_that.monologueCount,_that.studySeconds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int drillCount,  int monologueCount,  int studySeconds)  $default,) {final _that = this;
switch (_that) {
case _DailyStats():
return $default(_that.drillCount,_that.monologueCount,_that.studySeconds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int drillCount,  int monologueCount,  int studySeconds)?  $default,) {final _that = this;
switch (_that) {
case _DailyStats() when $default != null:
return $default(_that.drillCount,_that.monologueCount,_that.studySeconds);case _:
  return null;

}
}

}

/// @nodoc


class _DailyStats extends DailyStats {
  const _DailyStats({this.drillCount = 0, this.monologueCount = 0, this.studySeconds = 0}): super._();
  

/// 口頭作文の回答数
@override@JsonKey() final  int drillCount;
/// 独り言の実施回数
@override@JsonKey() final  int monologueCount;
/// 学習秒数（独り言の発話時間の合計）
@override@JsonKey() final  int studySeconds;

/// Create a copy of DailyStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DailyStatsCopyWith<_DailyStats> get copyWith => __$DailyStatsCopyWithImpl<_DailyStats>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DailyStats&&(identical(other.drillCount, drillCount) || other.drillCount == drillCount)&&(identical(other.monologueCount, monologueCount) || other.monologueCount == monologueCount)&&(identical(other.studySeconds, studySeconds) || other.studySeconds == studySeconds));
}


@override
int get hashCode => Object.hash(runtimeType,drillCount,monologueCount,studySeconds);

@override
String toString() {
  return 'DailyStats(drillCount: $drillCount, monologueCount: $monologueCount, studySeconds: $studySeconds)';
}


}

/// @nodoc
abstract mixin class _$DailyStatsCopyWith<$Res> implements $DailyStatsCopyWith<$Res> {
  factory _$DailyStatsCopyWith(_DailyStats value, $Res Function(_DailyStats) _then) = __$DailyStatsCopyWithImpl;
@override @useResult
$Res call({
 int drillCount, int monologueCount, int studySeconds
});




}
/// @nodoc
class __$DailyStatsCopyWithImpl<$Res>
    implements _$DailyStatsCopyWith<$Res> {
  __$DailyStatsCopyWithImpl(this._self, this._then);

  final _DailyStats _self;
  final $Res Function(_DailyStats) _then;

/// Create a copy of DailyStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? drillCount = null,Object? monologueCount = null,Object? studySeconds = null,}) {
  return _then(_DailyStats(
drillCount: null == drillCount ? _self.drillCount : drillCount // ignore: cast_nullable_to_non_nullable
as int,monologueCount: null == monologueCount ? _self.monologueCount : monologueCount // ignore: cast_nullable_to_non_nullable
as int,studySeconds: null == studySeconds ? _self.studySeconds : studySeconds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
