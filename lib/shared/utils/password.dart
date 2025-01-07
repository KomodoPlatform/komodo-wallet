import 'dart:math';

String generatePassword() {
  final List<String> passwords = [];

  final rng = Random();

  const String lowerCase = 'abcdefghijklmnopqrstuvwxyz';
  const String upperCase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  const String digit = '0123456789';
  const String punctuation = '*.!@#\$%^(){}:;\',.?/~`_+\\-=|';

  final string = [lowerCase, upperCase, digit, punctuation];

  final length = rng.nextInt(24) + 8;

  final List<String> tab = [];

  while (true) {
    // This loop make sure the new RPC password will contains all the requirement
    // characters type in password, it generate automatically the position.
    tab.clear();
    for (var x = 0; x < length; x++) {
      tab.add(string[rng.nextInt(4)]);
    }

    if (tab.contains(lowerCase) &&
        tab.contains(upperCase) &&
        tab.contains(digit) &&
        tab.contains(punctuation)) {
      break;
    }
  }

  for (int i = 0; i < tab.length; i++) {
    // Here we constitute new RPC password, and check the repetition.
    final chars = tab[i];
    final character = chars[rng.nextInt(chars.length)];
    final count = passwords.where((c) => c == character).toList().length;
    if (count < 2) {
      passwords.add(character);
    } else {
      tab.add(chars);
    }
  }

  return passwords.join('');
}

/// unit tests: [testValidateRPCPassword]
bool validateRPCPassword(String src) {
  if (src.isEmpty) return false;

  // Password can't contain word 'password'
  if (src.toLowerCase().contains('password')) return false;

  // Password must contain one digit, one lowercase letter, one uppercase letter,
  // one special character and its length must be between 8 and 32 characters
  final RegExp exp = RegExp(
      r'^(?:(?=.*[0-9])(?=.*[a-z])(?=.*[A-Z])(?=.*[^A-Za-z0-9])).{8,32}$');
  if (!src.contains(exp)) return false;

  // Password can't contain same character three time in a row,
  // so some code below to check that:

  // MRC: Divide the password into all possible 3 character blocks
  final pieces = <String>[];
  for (int start = 0, end = 3; end <= src.length; start += 1, end += 1) {
    pieces.add(src.substring(start, end));
  }

  // If, for any block, all 3 character are the same, block doesn't fit criteria
  for (String p in pieces) {
    final src = p[0];
    int count = 1;
    if (p[1] == src) count += 1;
    if (p[2] == src) count += 1;

    if (count == 3) return false;
  }

  return true;
}
