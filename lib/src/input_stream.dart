import 'dart:math';

import 'package:source_span/source_span.dart';

import 'code_point.dart';
import 'preprocess.dart';

class InputStream {
  /// Source file being streamed.
  final SourceFile _file;

  /// Text content of [_file].
  final String _text;

  /// Length of [_text].
  final int _length;

  /// Index of next code unit to be consumed.
  int _index;

  InputStream(this._file)
      : _text = _file.getText(0),
        _length = _file.length,
        _index = 0;

  factory InputStream.fromString(String text) =>
      new InputStream(new SourceFile(preprocess(text)));

  /// Index of next code unit to be consumed.
  int get offset => min(_index, _length);

  /// Advances the input stream by [offset] code units.
  void advance([int offset = 1]) {
      _index += offset;
  }

  /// Advances the input stream while the next code unit satisfies [predicate].
  void advanceWhile(bool predicate(int codeUnit)) {
    while (predicate(peek())) advance();
  }

  /// Returns the next code unit and advances the input stream.
  int consume() {
    var codeUnit = peek();
    advance();
    return codeUnit;
  }

  /// Returns true and advances the input stream if next is [codeUnit].
  bool consumeIfNext(int codeUnit) {
    if (peek() == codeUnit) {
      advance();
      return true;
    }
    return false;
  }

  /// Returns the code unit [offset] from the front of the input stream.
  ///
  /// Returns [$nul] if the input stream has been fully consumed.
  int peek([int offset = 0]) {
    var index = _index + offset;
    return index < _length ? _text.codeUnitAt(index) : $nul;
  }

  /// Pushes [codeUnit] back onto the front of the input stream.
  void reconsume(int codeUnit) {
    _index--;
    assert(peek() == codeUnit, '');
  }

  /// Returns the text segment from [start] until the front of the input stream.
  FileSpan spanFrom(int start) => _file.span(start, offset);
}
