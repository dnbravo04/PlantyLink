String formatPhoneNumber(String phoneNumber) {
  String cleaned = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
  if (!cleaned.startsWith('+')) {
    cleaned = '+57$cleaned';
  }
  return cleaned;
}
