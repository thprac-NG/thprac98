## Contribute (draft)

- In the `.CPP` and `.HPP` files, please avoid non-printable-ASCII characters.
  Spaces (0x20), Carriage Return (CR, 0x0D), and Line Feed (LF, 0x0A) can be
  exceptions. If you want to use other characters, make sure to...
  - Use Shift-JIS encoding. To be more specific, use the encoding that
    DOS on PC-9800 systems uses, and...
  - Keep the characters in `.INC` files.
- Please try to fit as many lines as possible into 80 characters. Exceptions
  are:
  - The line with many contributors' names in the `LICENSE` file, since it's
    necessary for GitHub to recognise it's an MIT license encoded with
    Shift-JIS;
  - A line with a URL, since otherwise it will be a pain to copy it.
- Please fit the filenames of as many files as possible into the 8.3 filename
  format.
- Use space for indentation.