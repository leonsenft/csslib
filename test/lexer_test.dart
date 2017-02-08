import 'package:csslib/src/code_point.dart';
import 'package:csslib/src/input_stream.dart';
import 'package:csslib/src/lexer.dart';
import 'package:csslib/src/token.dart';
import 'package:test/test.dart';

void main() {
  group('<at-keyword-token', () {
    // TODO(leonsenft): coverage.
  });

  test('<CDC-token>', () => expectToken('-->', new CDCToken()));
  test('<CDO-token>', () => expectToken('<!--', new CDOToken()));
  test('<colon-token>', () => expectToken(':', new ColonToken()));
  test('<column-token>', () => expectToken('||', new ColumnToken()));
  test('<comma-token>', () => expectToken(',', new CommaToken()));
  test('<dash-match-token>', () => expectToken('|=', new DashMatchToken()));

  group('<delim-token>', () {
    test('#', () => expectToken('#', new DelimToken($hash)));
    test(r'$', () => expectToken(r'$', new DelimToken($dollar)));
    test('*', () => expectToken('*', new DelimToken($asterisk)));
    test('+', () => expectToken('+', new DelimToken($plus)));
    test('-', () => expectToken('-', new DelimToken($minus)));
    test('.', () => expectToken('.', new DelimToken($dot)));
    test('/', () => expectToken('/', new DelimToken($solidus)));
    test('<', () => expectToken('<', new DelimToken($lt)));
    test('@', () => expectToken('@', new DelimToken($at)));
    test('\\', () {
      // TODO(leonsenft): expect parse error.
      expectTokens('\\\n', [
        new DelimToken($backslash),
        new WhitespaceToken(),
      ]);
    });
    test('^', () => expectToken('^', new DelimToken($circumflex)));
    test('~', () => expectToken('~', new DelimToken($tilde)));
    test('|', () => expectToken('|', new DelimToken($bar)));
  });

  group('<function-token>', () {
    // TODO(leonsenft): coverage.
  });

  group('<hash-token>', () {
    // TODO(leonsenft): coverage.
    test("'id'", () {
      expectToken('#id-selector', new HashToken('id-selector', HashType.id));
    });

    test("'id' hex color", () {
      expectToken('#FF0000', new HashToken('FF0000', HashType.id));
    });

    test("'id' leading dash", () {
      expectToken('#-id-selector', new HashToken('-id-selector', HashType.id));
    });

    test("'id' leading escape", () {
      expectToken(r'#\ ', new HashToken(' ', HashType.id));
    });

    test("'unrestricted' hex color", () {
      expectToken('#00FF00', new HashToken('00FF00', HashType.unrestricted));
    });
  });

  group('<ident-token>', () {
    // TODO(leonsenft): coverage.
  });

  test('<include-match-token>', () {
    expectToken('~=', new IncludeMatchToken());
  });

  test('<number-token>', () {
    expectToken('10', new NumberToken(10));
    expectToken('12.0', new NumberToken(12));
    expectToken('+45.6', new NumberToken(45.6));
    expectToken('-7', new NumberToken(-7));
    expectToken('010', new NumberToken(10));
    expectToken('10e0', new NumberToken(10));
    expectToken('12e3', new NumberToken(12000));
    expectToken('3e+1', new NumberToken(30));
    expectToken('12E-1', new NumberToken(1.2));
    expectToken('.7', new NumberToken(0.7));
    expectToken('-.3', new NumberToken(-0.3));
    expectToken('+637.54e-2', new NumberToken(6.3754));
    expectToken('-12.34E+2', new NumberToken(-1234));
    expectToken('1000000000000000000000000', new NumberToken(1e24));

    expectTokens('+ 5', [
      new DelimToken($plus),
      new WhitespaceToken(),
      new NumberToken(5),
    ]);
    expectTokens('-+12', [new DelimToken($minus), new NumberToken(12)]);
    expectTokens('+-21', [new DelimToken($plus), new NumberToken(-21)]);
    expectTokens('++22', [new DelimToken($plus), new NumberToken(22)]);
    expectTokens('13.', [new NumberToken(13), new DelimToken($dot)]);
    expectTokens('1.e2', [
      new NumberToken(1),
      new DelimToken($dot),
      new IdentToken('e2'),
    ]);
    expectTokens('2e3.5', [new NumberToken(2000), new NumberToken(0.5)]);
    expectTokens('2e3.', [new NumberToken(2000), new DelimToken($dot)]);
    expectToken('2e-', new DimensionToken(2, 'e-'));
  });

  test('<prefix-match-token>', () {
    expectToken('^=', new PrefixMatchToken());
  });

  test('<semicolon-token>', () => expectToken(';', new SemicolonToken()));

  group('<string-token>', () {
    test('bad string', () {
      expectTokens('"bad\nstring', [
        new BadStringToken(),
        new WhitespaceToken(),
        new IdentToken('string'),
      ]);
    });

    test('double quotes', () {
      expectToken('"double quotes"', new StringToken('double quotes'));
    });

    test('comments', () {
      expectToken('/* * / */a', new IdentToken('a'));
    });

    test('escaped', () {
      expectToken(r'"e\sca\ped"', new StringToken('escaped'));
    });

    test('escaped hex', () {
      expectToken(r'"\68\65\78"', new StringToken('hex'));
    });

    test('escaped hex invalid code points', () {
      expectToken(r'"\0  \D800  \DFFF  \110000"', new StringToken('� � � �'));
    });

    test('escaped hex max digits', () {
      expectToken(r'"\1000000"', new StringToken('\u{100000}0'));
    });

    test('escaped hex space terminated', () {
      expectToken(r'"\F00 F00"', new StringToken('\u0F00F00'));
    });

    test('multi-line', () {
      expectToken('"multi-\\\nline"', new StringToken('multi-line'));
    });

    test('trailing end-of-file', () {
      expectToken('"end-of-file', new StringToken('end-of-file'));
    });

    test('single quotes', () {
      expectToken("'single quotes'", new StringToken('single quotes'));
    });
  });

  test('<substring-match-token>', () {
    expectToken('*=', new SubstringMatchToken());
  });

  test('<suffix-match-token>', () {
    expectToken(r'$=', new SuffixMatchToken());
  });

  group('<unicode-range-token>', () {
    test('single codepoint', () {
      expectToken('u+26', new UnicodeRangeToken(0x26, 0x26));
      expectToken('U+26', new UnicodeRangeToken(0x26, 0x26));
    });

    test('codepoint range', () {
      expectToken('u+778-7A2', new UnicodeRangeToken(0x778, 0x7A2));
      expectToken('U+778-7A2', new UnicodeRangeToken(0x778, 0x7A2));
    });

    test('wildcard range', () {
      expectToken('u+?', new UnicodeRangeToken(0x0, 0xF));
      expectToken('u+4??', new UnicodeRangeToken(0x400, 0x4FF));
      expectToken('U+4??', new UnicodeRangeToken(0x400, 0x4FF));
    });
  });

  test('<whitespace-token>', () {
    expectToken(' \t\r\n\f', new WhitespaceToken());
  });

  test('<[-token>', () => expectToken('[', new LeftBracketToken()));
  test('<]-token>', () => expectToken(']', new RightBracketToken()));
  test('<(-token>', () => expectToken('(', new LeftParenToken()));
  test('<)-token>', () => expectToken(')', new RightParenToken()));
  test('<{-token>', () => expectToken('{', new LeftBraceToken()));
  test('<}-token>', () => expectToken('}', new RightBraceToken()));

  group('Comment', () {
    test('Comment is ignored.', () {
      expectTokens('p /* comment */ {}', [
        new IdentToken('p'),
        new WhitespaceToken(),
        new WhitespaceToken(),
        new LeftBraceToken(),
        new RightBraceToken(),
      ]);
    });
    test('Unclosed comment is ignored.', () {
      expectTokens('p /* comment {}', [
        new IdentToken('p'),
        new WhitespaceToken(),
      ]);
    });
  });
}

void compareTokens(Token actual, Token expected) {
  if (expected is AtKeywordToken) {
    expect(actual, new isInstanceOf<AtKeywordToken>());
    var token = actual as AtKeywordToken;
    expect(token.value, expected.value);
  } else if (expected is BadStringToken) {
    expect(actual, new isInstanceOf<BadStringToken>());
  } else if (expected is BadUrlToken) {
    expect(actual, new isInstanceOf<BadUrlToken>());
  } else if (expected is CDCToken) {
    expect(actual, new isInstanceOf<CDCToken>());
  } else if (expected is CDOToken) {
    expect(actual, new isInstanceOf<CDOToken>());
  } else if (expected is ColonToken) {
    expect(actual, new isInstanceOf<ColonToken>());
  } else if (expected is ColumnToken) {
    expect(actual, new isInstanceOf<ColumnToken>());
  } else if (expected is CommaToken) {
    expect(actual, new isInstanceOf<CommaToken>());
  } else if (expected is DashMatchToken) {
    expect(actual, new isInstanceOf<DashMatchToken>());
  } else if (expected is DelimToken) {
    expect(actual, new isInstanceOf<DelimToken>());
    var token = actual as DelimToken;
    expect(token.value, expected.value);
  } else if (expected is DimensionToken) {
    expect(actual, new isInstanceOf<DimensionToken>());
    var token = actual as DimensionToken;
    expect(token.value, expected.value);
    expect(token.unit, expected.unit);
  } else if (expected is EOFToken) {
    expect(actual, new isInstanceOf<EOFToken>());
  } else if (expected is FunctionToken) {
    expect(actual, new isInstanceOf<FunctionToken>());
    var token = actual as IdentToken;
    expect(token.value, expected.value);
  } else if (expected is HashToken) {
    expect(actual, new isInstanceOf<HashToken>());
    var token = actual as HashToken;
    expect(token.value, expected.value);
    expect(token.type, expected.type);
  } else if (expected is IdentToken) {
    expect(actual, new isInstanceOf<IdentToken>());
    var token = actual as IdentToken;
    expect(token.value, expected.value);
  } else if (expected is IncludeMatchToken) {
    expect(actual, new isInstanceOf<IncludeMatchToken>());
  } else if (expected is LeftBraceToken) {
    expect(actual, new isInstanceOf<LeftBraceToken>());
  } else if (expected is LeftBracketToken) {
    expect(actual, new isInstanceOf<LeftBracketToken>());
  } else if (expected is LeftParenToken) {
    expect(actual, new isInstanceOf<LeftParenToken>());
  } else if (expected is NumberToken) {
    expect(actual, new isInstanceOf<NumberToken>());
    var token = actual as NumberToken;
    expect(token.value, expected.value);
  } else if (expected is PercentageToken) {
    expect(actual, new isInstanceOf<PercentageToken>());
    var token = actual as PercentageToken;
    expect(token.value, expected.value);
  } else if (expected is PrefixMatchToken) {
    expect(actual, new isInstanceOf<PrefixMatchToken>());
  } else if (expected is RightBraceToken) {
    expect(actual, new isInstanceOf<RightBraceToken>());
  } else if (expected is RightBracketToken) {
    expect(actual, new isInstanceOf<RightBracketToken>());
  } else if (expected is RightParenToken) {
    expect(actual, new isInstanceOf<RightParenToken>());
  } else if (expected is SemicolonToken) {
    expect(actual, new isInstanceOf<SemicolonToken>());
  } else if (expected is StringToken) {
    expect(actual, new isInstanceOf<StringToken>());
    var token = actual as StringToken;
    expect(token.value, expected.value);
  } else if (expected is SubstringMatchToken) {
    expect(actual, new isInstanceOf<SubstringMatchToken>());
  } else if (expected is SuffixMatchToken) {
    expect(actual, new isInstanceOf<SuffixMatchToken>());
  } else if (expected is UnicodeRangeToken) {
    expect(actual, new isInstanceOf<UnicodeRangeToken>());
    var token = actual as UnicodeRangeToken;
    expect(token.start, expected.start);
    expect(token.end, expected.end);
  } else if (expected is UrlToken) {
    expect(actual, new isInstanceOf<UrlToken>());
    var token = actual as UrlToken;
    expect(token.value, expected.value);
  } else if (expected is WhitespaceToken) {
    expect(actual, new isInstanceOf<WhitespaceToken>());
  }
}

void expectToken(String css, Token expectedToken) =>
    expectTokens(css, [expectedToken]);

void expectTokens(String css, List<Token> expectedTokens) {
  var input = new InputStream.fromString(css);
  var lexer = new Lexer(input);
  for (var expectedToken in expectedTokens) {
    compareTokens(lexer.next(), expectedToken);
  }
  compareTokens(lexer.next(), new EOFToken());
}
