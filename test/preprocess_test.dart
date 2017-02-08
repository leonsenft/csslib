import 'package:csslib/src/preprocess.dart';
import 'package:test/test.dart';

void main() {
  test('replaces CR with LF', () {
    var input = 'a {\r  color: red;\r}';
    var expectedOutput = 'a {\n  color: red;\n}';
    var output = preprocess(input);
    expect(output, expectedOutput);
  });

  test('replaces CRLF with LF', () {
    var input = 'a {\r\n  color: red;\r\n}';
    var expectedOutput = 'a {\n  color: red;\n}';
    var output = preprocess(input);
    expect(output, expectedOutput);
  });

  test('replaces FF with LF', () {
    var input = 'a { color: red; }\fp { color: blue; }';
    var expectedOutput = 'a { color: red; }\np { color: blue; }';
    var output = preprocess(input);
    expect(output, expectedOutput);
  });

  test('replaces NUL with �', () {
    var input = 'a::before { content: "\u0000"; }';
    var expectedOutput = 'a::before { content: "�"; }';
    var output = preprocess(input);
    expect(output, expectedOutput);
  });
}
