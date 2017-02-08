import 'package:source_span/source_span.dart';

import 'code_point.dart';
import 'input_stream.dart';
import 'predicates.dart';
import 'token.dart';

export 'input_stream.dart';
export 'token.dart';

typedef Token CodeUnitTransition(int codePoint);

class Lexer {
  /// Input stream to be tokenized.
  final InputStream _input;

  /// Staring code unit index of current token.
  int _start;

  /// Lookup table of methods for ASCII code points.
  List<CodeUnitTransition> _transitions;

  Lexer(this._input) {
    _transitions = [
      _eof, // NUL
      _delim, // SOM
      _delim, // STX
      _delim, // ETX
      _delim, // EOT
      _delim, // ENQ
      _delim, // ACK
      _delim, // BEL
      _delim, // BS
      _whitespace, // TAB
      _whitespace, // LF
      _delim, // VT
      _whitespace, // FF
      _whitespace, // CR
      _delim, // SO
      _delim, // SI
      _delim, // DLE
      _delim, // DC1
      _delim, // DC2
      _delim, // DC3
      _delim, // DC4
      _delim, // NAK
      _delim, // SYN
      _delim, // ETB
      _delim, // CAN
      _delim, // EM
      _delim, // SUB
      _delim, // ESC
      _delim, // FS
      _delim, // GS
      _delim, // RS
      _delim, // US
      _whitespace, // Space
      _delim, // !
      _string, // "
      _hash, // #
      _dollar, // $
      _delim, // %
      _delim, // &
      _string, // '
      _leftParen, // (
      _rightParen, // )
      _asterisk, // *
      _plusOrFullStop, // +
      _comma, // ,
      _minus, // -
      _plusOrFullStop, // .
      _solidus, // /
      _digit, // 0
      _digit, // 1
      _digit, // 2
      _digit, // 3
      _digit, // 4
      _digit, // 5
      _digit, // 6
      _digit, // 7
      _digit, // 8
      _digit, // 9
      _colon, // :
      _semicolon, // ;
      _lessThan, // <
      _delim, // =
      _delim, // >
      _delim, // ?
      _commercialAt, // @
      _nameStart, // A
      _nameStart, // B
      _nameStart, // C
      _nameStart, // D
      _nameStart, // E
      _nameStart, // F
      _nameStart, // G
      _nameStart, // H
      _nameStart, // I
      _nameStart, // J
      _nameStart, // K
      _nameStart, // L
      _nameStart, // M
      _nameStart, // N
      _nameStart, // O
      _nameStart, // P
      _nameStart, // Q
      _nameStart, // R
      _nameStart, // S
      _nameStart, // T
      _letterU, // U
      _nameStart, // V
      _nameStart, // W
      _nameStart, // X
      _nameStart, // Y
      _nameStart, // Z
      _leftBracket, // [
      _reverseSolidus, // \
      _rightBracket, // ]
      _circumflexAccent, // ^
      _nameStart, // _
      _delim, // `
      _nameStart, // a
      _nameStart, // b
      _nameStart, // c
      _nameStart, // d
      _nameStart, // e
      _nameStart, // f
      _nameStart, // g
      _nameStart, // h
      _nameStart, // i
      _nameStart, // j
      _nameStart, // k
      _nameStart, // l
      _nameStart, // m
      _nameStart, // n
      _nameStart, // o
      _nameStart, // p
      _nameStart, // q
      _nameStart, // r
      _nameStart, // s
      _nameStart, // t
      _letterU, // u
      _nameStart, // v
      _nameStart, // w
      _nameStart, // x
      _nameStart, // y
      _nameStart, // z
      _leftBrace, // {
      _verticalLine, // |
      _rightBrace, // }
      _tilde, // ~
      _delim, // DEL
    ];
  }

  FileSpan get _currentSpan => _input.spanFrom(_start);

  /// Returns the next token and advances the token stream.
  Token next() {
    _start = _input.offset;

    var codeUnit = _input.consume();
    if (isAscii(codeUnit)) {
      return _transitions[codeUnit](codeUnit);
    } else {
      return _nameStart(codeUnit);
    }
  }

  Token _asterisk(int codeUnit) => _input.consumeIfNext($equal)
      ? new SubstringMatchToken(_currentSpan)
      : new DelimToken(codeUnit, _currentSpan);

  Token _circumflexAccent(int codeUnit) => _input.consumeIfNext($equal)
      ? new PrefixMatchToken(_currentSpan)
      : new DelimToken(codeUnit, _currentSpan);

  Token _colon(int _) => new ColonToken(_currentSpan);

  Token _comma(int _) => new CommaToken(_currentSpan);

  Token _commercialAt(int codeUnit) {
    if (_nextStartsIdentifier()) {
      var name = _consumeName();
      return new AtKeywordToken(name, _currentSpan);
    }
    return new DelimToken(codeUnit, _currentSpan);
  }

  int _consumeEscapedCode() {
    var code = _input.consume();
    if (code == $nul) {
      return $replacement;
    } else if (isHexDigit(code)) {
      var hexDigitsConsumed = 1;
      var sb = new StringBuffer()..writeCharCode(code);
      // Consume at most 6 hex digits.
      while (isHexDigit(_input.peek()) && hexDigitsConsumed < 6) {
        hexDigitsConsumed++;
        sb.writeCharCode(_input.consume());
      }
      // Optional whitespace prevents interpreting following code units as hex
      // digits.
      if (isWhitespace(_input.peek())) _input.consume();
      var value = int.parse(sb.toString(), radix: 16);
      if (value == 0 || value > $max || isSurrogateCodePoint(value)) {
        return $replacement;
      }
      return value;
    } else {
      return code;
    }
  }

  Token _consumeIdentLikeToken() {
    var name = _consumeName();
    if (_input.consumeIfNext($lparen)) {
      return name.toLowerCase() == 'url'
          ? _consumeUrlToken()
          : new FunctionToken(name, _currentSpan);
    }
    return new IdentToken(name, _currentSpan);
  }

  String _consumeName() {
    var sb = new StringBuffer();
    while (true) {
      var code = _input.consume();
      if (isNameCodePoint(code)) {
        sb.writeCharCode(code);
      } else if (isValidEscape(code, _input.peek())) {
        sb.writeCharCode(_consumeEscapedCode());
      } else {
        _input.reconsume(code);
        return sb.toString();
      }
    }
  }

  num _consumeNumber() {
    var isDouble = false;
    var start = _input.offset;

    // Consume sign.
    var next = _input.peek();
    if (next == $minus || next == $plus) _input.advance();

    // Consume integer.
    _input.advanceWhile(isDigit);

    // Consume mantissa.
    if (_input.peek() == $dot && isDigit(_input.peek(1))) {
      isDouble = true;
      _input.advance();
      _input.advanceWhile(isDigit);
    }

    // Consume exponent.
    next = _input.peek();
    if (next == $E || next == $e) {
      next = _input.peek(1);
      if (isDigit(next)) {
        isDouble = true;
        _input.advance(2);
        _input.advanceWhile(isDigit);
      } else if ((next == $minus || next == $plus) && isDigit(_input.peek(2))) {
        isDouble = true;
        _input.advance(3);
        _input.advanceWhile(isDigit);
      }
    }

    var number = _input.spanFrom(start).text;
    return isDouble ? double.parse(number) : int.parse(number);
  }

  Token _consumeNumericToken() {
    var value = _consumeNumber();
    if (_nextStartsIdentifier()) {
      var unit = _consumeName();
      return new DimensionToken(value, unit, _currentSpan);
    } else if (_input.consumeIfNext($percent)) {
      return new PercentageToken(value, _currentSpan);
    }
    return new NumberToken(value, _currentSpan);
  }

  Token _consumeUnicodeRangeToken() {
    // Assumes that the initial 'u+' has been consumed.
    assert(isHexDigit(_input.peek()) || _input.peek() == $question);

    var hexDigitsConsumed = 0;
    var start = 0;

    while (isHexDigit(_input.peek()) && hexDigitsConsumed < 6) {
      start = start * 16 + toHexValue(_input.consume());
      hexDigitsConsumed++;
    }

    var end = start;

    if (hexDigitsConsumed < 6 && _input.consumeIfNext($question)) {
      // Wildcard range (U+4??).
      do {
        start *= 16;
        end = end * 16 + 0xF;
        hexDigitsConsumed++;
      } while (hexDigitsConsumed < 6 && _input.consumeIfNext($question));
    } else if (_input.peek() == $minus && isHexDigit(_input.peek(1))) {
      // Codepoint range (U+778-7A2).
      _input.advance();
      hexDigitsConsumed = 0;
      end = 0;
      do {
        end = end * 16 + toHexValue(_input.consume());
        hexDigitsConsumed++;
      } while (isHexDigit(_input.peek()) && hexDigitsConsumed < 6);
    } // Single codepoint (U+26).

    return new UnicodeRangeToken(start, end, _currentSpan);
  }

  Token _consumeUrlToken() {
    // Assumes that 'url(' has been consumed.
    _input.advanceWhile(isWhitespace);
    var codeUnit = _input.consume();
    if (codeUnit == $quotation || codeUnit == $apostrophe) {
      // URL with quoted parameter.
      var token = _string(codeUnit);
      if (token is StringToken) {
        _input.advanceWhile(isWhitespace);
        if (_input.consumeIfNext($rparen) || _input.consumeIfNext($nul)) {
          return new UrlToken(token.value, _currentSpan);
        }
      }
    } else {
      // URL with unquoted parameter.
      var sb = new StringBuffer();
      while (true) {
        if (codeUnit == $rparen || codeUnit == $nul) {
          return new UrlToken(sb.toString(), _currentSpan);
        }
        if (isWhitespace(codeUnit)) {
          _input.advanceWhile(isWhitespace);
          if (_input.consumeIfNext($rparen) || _input.consumeIfNext($nul)) {
            return new UrlToken(sb.toString(), _currentSpan);
          }
          break;
        }
        if (codeUnit == $quotation ||
            codeUnit == $apostrophe ||
            codeUnit == $lparen ||
            isNonPrintable(codeUnit)) {
          // TODO(leonsenft): parse error.
          break;
        }
        if (codeUnit == $backslash) {
          if (isValidEscape(codeUnit, _input.peek())) {
            sb.writeCharCode(_consumeEscapedCode());
          } else {
            // TODO(leonsenft): parse error.
            break;
          }
        } else {
          sb.writeCharCode(codeUnit);
        }
        codeUnit = _input.consume();
      }
    }

    // Consume remnants of a bad URL.
    while (true) {
      codeUnit = _input.consume();
      if (codeUnit == $rparen || codeUnit == $nul) break;
      if (isValidEscape(codeUnit, _input.peek())) _consumeEscapedCode();
    }
    return new BadUrlToken(_currentSpan);
  }

  Token _delim(int codeUnit) => new DelimToken(codeUnit, _currentSpan);

  Token _digit(int codeUnit) {
    _input.reconsume(codeUnit);
    return _consumeNumericToken();
  }

  Token _dollar(int codeUnit) {
    return _input.consumeIfNext($equal)
        ? new SuffixMatchToken(_currentSpan)
        : new DelimToken(codeUnit, _currentSpan);
  }

  Token _eof(int _) => new EOFToken();

  Token _hash(int codeUnit) {
    var first = _input.peek();
    if (isNameCodePoint(first) || isValidEscape(first, _input.peek(1))) {
      var type = _nextStartsIdentifier() ? HashType.id : HashType.unrestricted;
      var name = _consumeName();
      return new HashToken(name, type, _currentSpan);
    }
    return new DelimToken(codeUnit, _currentSpan);
  }

  Token _leftBrace(int _) => new LeftBraceToken(_currentSpan);

  Token _leftBracket(int _) => new LeftBracketToken(_currentSpan);

  Token _leftParen(int _) => new LeftParenToken(_currentSpan);

  Token _lessThan(int codeUnit) {
    if (_input.peek(0) == $exclamation &&
        _input.peek(1) == $minus &&
        _input.peek(2) == $minus) {
      _input.advance(3);
      return new CDOToken(_currentSpan);
    }
    return new DelimToken(codeUnit, _currentSpan);
  }

  Token _letterU(int codeUnit) {
    if (_input.peek() == $plus) {
      var afterPlus = _input.peek(1);
      if (isHexDigit(afterPlus) || afterPlus == $question) {
        _input.advance();
        return _consumeUnicodeRangeToken();
      }
    }
    _input.reconsume(codeUnit);
    return _consumeIdentLikeToken();
  }

  Token _minus(int codeUnit) {
    if (_nextStartsNumber(codeUnit)) {
      _input.reconsume(codeUnit);
      return _consumeNumericToken();
    } else if (_nextStartsIdentifier()) {
      _input.reconsume(codeUnit);
      return _consumeIdentLikeToken();
    } else if (_input.peek() == $minus && _input.peek(1) == $gt) {
      _input.advance(2);
      return new CDCToken(_currentSpan);
    }
    return new DelimToken(codeUnit, _currentSpan);
  }

  Token _nameStart(int codeUnit) {
    _input.reconsume(codeUnit);
    return _consumeIdentLikeToken();
  }

  bool _nextStartsIdentifier() {
    var first = _input.peek();
    if (isNameStartCodePoint(first)) return true;
    var second = _input.peek(1);
    if (isValidEscape(first, second)) return true;
    var third = _input.peek(2);
    return first == $minus &&
        (isNameStartCodePoint(second) || isValidEscape(second, third));
  }

  bool _nextStartsNumber(int first) {
    if (isDigit(first)) return true;
    if (first == $dot) return isDigit(_input.peek());
    if (first == $minus || first == $plus) {
      var second = _input.peek();
      return isDigit(second) || (second == $dot && isDigit(_input.peek(1)));
    }
    return false;
  }

  Token _plusOrFullStop(int codeUnit) {
    if (_nextStartsNumber(codeUnit)) {
      _input.reconsume(codeUnit);
      return _consumeNumericToken();
    }
    return new DelimToken(codeUnit, _currentSpan);
  }

  Token _reverseSolidus(int codeUnit) {
    if (isValidEscape(codeUnit, _input.peek())) {
      _input.reconsume(codeUnit);
      return _consumeIdentLikeToken();
    }
    // TODO(leonsenft): parse error.
    return new DelimToken(codeUnit, _currentSpan);
  }

  Token _rightBrace(int _) => new RightBraceToken(_currentSpan);

  Token _rightBracket(int _) => new RightBracketToken(_currentSpan);

  Token _rightParen(int _) => new RightParenToken(_currentSpan);

  Token _semicolon(int _) => new SemicolonToken(_currentSpan);

  Token _solidus(int codeUnit) {
    if (_input.consumeIfNext($asterisk)) {
      while (true) {
        var codeUnit = _input.consume();
        if (codeUnit == $nul) break;
        if (codeUnit == $asterisk && _input.consumeIfNext($solidus)) break;
      }
      return next();
    }
    return new DelimToken(codeUnit, _currentSpan);
  }

  Token _string(int endingCode) {
    var sb = new StringBuffer();
    var code = _input.consume();

    while (code != endingCode && code != $nul) {
      if (code == $lf) {
        _input.reconsume($lf);
        // TODO(leonsenft): parse error.
        return new BadStringToken(_currentSpan);
      } else if (code == $backslash) {
        var nextCode = _input.peek();
        if (nextCode == $lf) {
          _input.advance();
        } else if (nextCode != $nul) {
          sb.writeCharCode(_consumeEscapedCode());
        }
      } else {
        sb.writeCharCode(code);
      }
      code = _input.consume();
    }

    return new StringToken(sb.toString(), _currentSpan);
  }

  Token _tilde(int codeUnit) => _input.consumeIfNext($equal)
      ? new IncludeMatchToken(_currentSpan)
      : new DelimToken(codeUnit, _currentSpan);

  Token _verticalLine(int codeUnit) {
    if (_input.consumeIfNext($equal)) return new DashMatchToken(_currentSpan);
    if (_input.consumeIfNext($bar)) return new ColumnToken(_currentSpan);
    return new DelimToken(codeUnit, _currentSpan);
  }

  Token _whitespace(int _) {
    _input.advanceWhile(isWhitespace);
    return new WhitespaceToken(_currentSpan);
  }
}

int toHexValue(int codePoint) {
  assert(isHexDigit(codePoint));
  return codePoint < $A ? codePoint - $0 : (codePoint - $A + 10) & 0xF;
}
