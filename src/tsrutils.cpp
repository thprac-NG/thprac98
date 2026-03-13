int hex_digit(char ch) {
  if ('0' <= ch && ch <= '9') {
    return ch - '0';
  }
  if ('a' <= ch && ch <= 'f') {
    return ch - 'a' + 10;
  }
  if ('A' <= ch && ch <= 'F') {
    return ch - 'A' + 10;
  }
  return -1;
}