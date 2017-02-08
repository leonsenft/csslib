import 'package:source_span/source_span.dart';

class AtKeywordToken extends _TokenWith<String> {
  AtKeywordToken(String value, [FileSpan span]) : super(value, span);
}

class BadStringToken extends Token {
  BadStringToken([FileSpan span]) : super(span);
}

class BadUrlToken extends Token {
  BadUrlToken([FileSpan span]) : super(span);
}

class CDCToken extends Token {
  CDCToken([FileSpan span]) : super(span);
}

class CDOToken extends Token {
  CDOToken([FileSpan span]) : super(span);
}

class ColonToken extends Token {
  ColonToken([FileSpan span]) : super(span);
}

class ColumnToken extends Token {
  ColumnToken([FileSpan span]) : super(span);
}

class CommaToken extends Token {
  CommaToken([FileSpan span]) : super(span);
}

class DashMatchToken extends Token {
  DashMatchToken([FileSpan span]) : super(span);
}

class DelimToken extends _TokenWith<int> {
  DelimToken(int value, [FileSpan span]) : super(value, span);
}

class DimensionToken extends _TokenWith<num> {
  final String unit;
  DimensionToken(num value, this.unit, [FileSpan span]) : super(value, span);
}

class EOFToken extends Token {}

class FunctionToken extends _TokenWith<String> {
  FunctionToken(String value, [FileSpan span]) : super(value, span);
}

class HashToken extends _TokenWith<String> {
  final HashType type;
  HashToken(String value, this.type, [FileSpan span]) : super(value, span);
}

enum HashType {
  id,
  unrestricted,
}

class IdentToken extends _TokenWith<String> {
  IdentToken(String value, [FileSpan span]) : super(value, span);
}

class IncludeMatchToken extends Token {
  IncludeMatchToken([FileSpan span]) : super(span);
}

class LeftBraceToken extends Token {
  LeftBraceToken([FileSpan span]) : super(span);
}

class LeftBracketToken extends Token {
  LeftBracketToken([FileSpan span]) : super(span);
}

class LeftParenToken extends Token {
  LeftParenToken([FileSpan span]) : super(span);
}

class NumberToken extends _TokenWith<num> {
  NumberToken(num value, [FileSpan span]) : super(value, span);
}

class PercentageToken extends _TokenWith<num> {
  PercentageToken(num value, [FileSpan span]) : super(value, span);
}

class PrefixMatchToken extends Token {
  PrefixMatchToken([FileSpan span]) : super(span);
}

class RightBraceToken extends Token {
  RightBraceToken([FileSpan span]) : super(span);
}

class RightBracketToken extends Token {
  RightBracketToken([FileSpan span]) : super(span);
}

class RightParenToken extends Token {
  RightParenToken([FileSpan span]) : super(span);
}

class SemicolonToken extends Token {
  SemicolonToken([FileSpan span]) : super(span);
}

class StringToken extends _TokenWith<String> {
  StringToken(String value, [FileSpan span]) : super(value, span);
}

class SubstringMatchToken extends Token {
  SubstringMatchToken([FileSpan span]) : super(span);
}

class SuffixMatchToken extends Token {
  SuffixMatchToken([FileSpan span]) : super(span);
}

abstract class Token {
  final FileSpan span;
  Token([this.span]);
}

class UnicodeRangeToken extends Token {
  final int start;
  final int end;
  UnicodeRangeToken(this.start, this.end, [FileSpan span]) : super(span);
}

class UrlToken extends _TokenWith<String> {
  UrlToken(String value, [FileSpan span]) : super(value, span);
}

class WhitespaceToken extends Token {
  WhitespaceToken([FileSpan span]) : super(span);
}

abstract class _TokenWith<T> extends Token {
  final T value;
  _TokenWith(this.value, [FileSpan span]) : super(span);
}
