// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tone_note.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ToneNote {

/// 模範解答のピンインでの音節位置（0始まり）
 int get index;/// 聞き取られたピンインでの音節位置（0始まり）。語順や語数が模範解答と違うと
/// [index]とはずれる（綴りでLCS整列した結果の対応先）
 int get spokenIndex;/// 模範解答の音節（声調記号つき、例: `shuǐ`）
 String get expected;/// 聞き取られた音節（声調記号つき、例: `shuì`）
 String get actual;/// 模範解答の声調番号（1〜4）
 int get expectedTone;/// 聞き取られた声調番号（1〜4）
 int get actualTone;/// 対応する漢字。模範解答の漢字数と音節数が一致しない（儿化など）場合はnull
 String? get hanzi;
/// Create a copy of ToneNote
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ToneNoteCopyWith<ToneNote> get copyWith => _$ToneNoteCopyWithImpl<ToneNote>(this as ToneNote, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ToneNote&&(identical(other.index, index) || other.index == index)&&(identical(other.spokenIndex, spokenIndex) || other.spokenIndex == spokenIndex)&&(identical(other.expected, expected) || other.expected == expected)&&(identical(other.actual, actual) || other.actual == actual)&&(identical(other.expectedTone, expectedTone) || other.expectedTone == expectedTone)&&(identical(other.actualTone, actualTone) || other.actualTone == actualTone)&&(identical(other.hanzi, hanzi) || other.hanzi == hanzi));
}


@override
int get hashCode => Object.hash(runtimeType,index,spokenIndex,expected,actual,expectedTone,actualTone,hanzi);

@override
String toString() {
  return 'ToneNote(index: $index, spokenIndex: $spokenIndex, expected: $expected, actual: $actual, expectedTone: $expectedTone, actualTone: $actualTone, hanzi: $hanzi)';
}


}

/// @nodoc
abstract mixin class $ToneNoteCopyWith<$Res>  {
  factory $ToneNoteCopyWith(ToneNote value, $Res Function(ToneNote) _then) = _$ToneNoteCopyWithImpl;
@useResult
$Res call({
 int index, int spokenIndex, String expected, String actual, int expectedTone, int actualTone, String? hanzi
});




}
/// @nodoc
class _$ToneNoteCopyWithImpl<$Res>
    implements $ToneNoteCopyWith<$Res> {
  _$ToneNoteCopyWithImpl(this._self, this._then);

  final ToneNote _self;
  final $Res Function(ToneNote) _then;

/// Create a copy of ToneNote
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? index = null,Object? spokenIndex = null,Object? expected = null,Object? actual = null,Object? expectedTone = null,Object? actualTone = null,Object? hanzi = freezed,}) {
  return _then(_self.copyWith(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,spokenIndex: null == spokenIndex ? _self.spokenIndex : spokenIndex // ignore: cast_nullable_to_non_nullable
as int,expected: null == expected ? _self.expected : expected // ignore: cast_nullable_to_non_nullable
as String,actual: null == actual ? _self.actual : actual // ignore: cast_nullable_to_non_nullable
as String,expectedTone: null == expectedTone ? _self.expectedTone : expectedTone // ignore: cast_nullable_to_non_nullable
as int,actualTone: null == actualTone ? _self.actualTone : actualTone // ignore: cast_nullable_to_non_nullable
as int,hanzi: freezed == hanzi ? _self.hanzi : hanzi // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ToneNote].
extension ToneNotePatterns on ToneNote {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ToneNote value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ToneNote() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ToneNote value)  $default,){
final _that = this;
switch (_that) {
case _ToneNote():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ToneNote value)?  $default,){
final _that = this;
switch (_that) {
case _ToneNote() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int index,  int spokenIndex,  String expected,  String actual,  int expectedTone,  int actualTone,  String? hanzi)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ToneNote() when $default != null:
return $default(_that.index,_that.spokenIndex,_that.expected,_that.actual,_that.expectedTone,_that.actualTone,_that.hanzi);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int index,  int spokenIndex,  String expected,  String actual,  int expectedTone,  int actualTone,  String? hanzi)  $default,) {final _that = this;
switch (_that) {
case _ToneNote():
return $default(_that.index,_that.spokenIndex,_that.expected,_that.actual,_that.expectedTone,_that.actualTone,_that.hanzi);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int index,  int spokenIndex,  String expected,  String actual,  int expectedTone,  int actualTone,  String? hanzi)?  $default,) {final _that = this;
switch (_that) {
case _ToneNote() when $default != null:
return $default(_that.index,_that.spokenIndex,_that.expected,_that.actual,_that.expectedTone,_that.actualTone,_that.hanzi);case _:
  return null;

}
}

}

/// @nodoc


class _ToneNote implements ToneNote {
  const _ToneNote({required this.index, required this.spokenIndex, required this.expected, required this.actual, required this.expectedTone, required this.actualTone, this.hanzi});
  

/// 模範解答のピンインでの音節位置（0始まり）
@override final  int index;
/// 聞き取られたピンインでの音節位置（0始まり）。語順や語数が模範解答と違うと
/// [index]とはずれる（綴りでLCS整列した結果の対応先）
@override final  int spokenIndex;
/// 模範解答の音節（声調記号つき、例: `shuǐ`）
@override final  String expected;
/// 聞き取られた音節（声調記号つき、例: `shuì`）
@override final  String actual;
/// 模範解答の声調番号（1〜4）
@override final  int expectedTone;
/// 聞き取られた声調番号（1〜4）
@override final  int actualTone;
/// 対応する漢字。模範解答の漢字数と音節数が一致しない（儿化など）場合はnull
@override final  String? hanzi;

/// Create a copy of ToneNote
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ToneNoteCopyWith<_ToneNote> get copyWith => __$ToneNoteCopyWithImpl<_ToneNote>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ToneNote&&(identical(other.index, index) || other.index == index)&&(identical(other.spokenIndex, spokenIndex) || other.spokenIndex == spokenIndex)&&(identical(other.expected, expected) || other.expected == expected)&&(identical(other.actual, actual) || other.actual == actual)&&(identical(other.expectedTone, expectedTone) || other.expectedTone == expectedTone)&&(identical(other.actualTone, actualTone) || other.actualTone == actualTone)&&(identical(other.hanzi, hanzi) || other.hanzi == hanzi));
}


@override
int get hashCode => Object.hash(runtimeType,index,spokenIndex,expected,actual,expectedTone,actualTone,hanzi);

@override
String toString() {
  return 'ToneNote(index: $index, spokenIndex: $spokenIndex, expected: $expected, actual: $actual, expectedTone: $expectedTone, actualTone: $actualTone, hanzi: $hanzi)';
}


}

/// @nodoc
abstract mixin class _$ToneNoteCopyWith<$Res> implements $ToneNoteCopyWith<$Res> {
  factory _$ToneNoteCopyWith(_ToneNote value, $Res Function(_ToneNote) _then) = __$ToneNoteCopyWithImpl;
@override @useResult
$Res call({
 int index, int spokenIndex, String expected, String actual, int expectedTone, int actualTone, String? hanzi
});




}
/// @nodoc
class __$ToneNoteCopyWithImpl<$Res>
    implements _$ToneNoteCopyWith<$Res> {
  __$ToneNoteCopyWithImpl(this._self, this._then);

  final _ToneNote _self;
  final $Res Function(_ToneNote) _then;

/// Create a copy of ToneNote
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? index = null,Object? spokenIndex = null,Object? expected = null,Object? actual = null,Object? expectedTone = null,Object? actualTone = null,Object? hanzi = freezed,}) {
  return _then(_ToneNote(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,spokenIndex: null == spokenIndex ? _self.spokenIndex : spokenIndex // ignore: cast_nullable_to_non_nullable
as int,expected: null == expected ? _self.expected : expected // ignore: cast_nullable_to_non_nullable
as String,actual: null == actual ? _self.actual : actual // ignore: cast_nullable_to_non_nullable
as String,expectedTone: null == expectedTone ? _self.expectedTone : expectedTone // ignore: cast_nullable_to_non_nullable
as int,actualTone: null == actualTone ? _self.actualTone : actualTone // ignore: cast_nullable_to_non_nullable
as int,hanzi: freezed == hanzi ? _self.hanzi : hanzi // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
