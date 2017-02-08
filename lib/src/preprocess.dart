import 'package:charcode/charcode.dart';

/// Preprocesses styles for parsing by making code point substitutions.
///
/// https://www.w3.org/TR/css-syntax-3/#input-preprocessing
String preprocess(String input) {
  var length = input.length;
  var output = new StringBuffer();
  for (var i = 0; i < length; i++) {
    var code = input.codeUnitAt(i);
    if (code == $cr) {
      if (i + 1 < length && input.codeUnitAt(i + 1) == $lf) i++;
      output.writeCharCode($lf);
    } else if (code == $ff) {
      output.writeCharCode($lf);
    } else if (code == $nul) {
      output.writeCharCode(0xFFFD);
    } else {
      output.writeCharCode(code);
    }
  }
  return output.toString();
}
