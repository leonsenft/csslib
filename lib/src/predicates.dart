import 'package:charcode/ascii.dart';

bool isAscii(int codePoint) => codePoint & ~0x7F == 0;

bool isDigit(int codePoint) => codePoint >= $0 && codePoint <= $9;

bool isHexDigit(int codePoint) =>
    isDigit(codePoint) || (codePoint | 0x20) >= $a && (codePoint | 0x20) <= $f;

bool isLetter(int codePoint) =>
    (codePoint | 0x20) >= $a && (codePoint | 0x20) <= $z;

bool isNameCodePoint(int codePoint) =>
    isNameStartCodePoint(codePoint) || isDigit(codePoint) || codePoint == $minus;

bool isNameStartCodePoint(int codePoint) =>
    isLetter(codePoint) || !isAscii(codePoint) || codePoint == $underscore;

bool isNonPrintable(int codePoint) =>
    codePoint >= $nul && codePoint <= $bs ||
    codePoint >= $so && codePoint <= $us ||
    codePoint == $vt ||
    codePoint == $del;

bool isSurrogateCodePoint(int codePoint) =>
    codePoint >= 0xD800 && codePoint <= 0xDFFF;

bool isValidEscape(int firstCodePoint, int secondCodePoint) =>
    firstCodePoint == $backslash && secondCodePoint != $lf;

bool isWhitespace(int codePoint) =>
    codePoint == $lf || codePoint == $tab || codePoint == $space;
