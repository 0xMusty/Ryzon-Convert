class Validators {
  Validators._();

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final phoneClean = value.replaceAll(RegExp(r'\s+'), '');
    if (phoneClean.length < 10 || phoneClean.length > 14) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    return null;
  }

  static String? validateNin(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'National Identity Number (NIN) is required';
    }
    final clean = value.trim();
    if (clean.length != 11 || int.tryParse(clean) == null) {
      return 'NIN must be exactly 11 digits';
    }
    return null;
  }

  static String? validateBvn(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Bank Verification Number (BVN) is required';
    }
    final clean = value.trim();
    if (clean.length != 11 || int.tryParse(clean) == null) {
      return 'BVN must be exactly 11 digits';
    }
    return null;
  }

  static String? validateWithdrawalAmount(String? value, double remainingLimit) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter withdrawal amount';
    }
    final amount = double.tryParse(value.trim().replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      return 'Enter a valid positive amount';
    }
    if (amount < 100) {
      return 'Minimum withdrawal is ₦100';
    }
    if (amount > remainingLimit) {
      return 'Amount exceeds remaining daily limit of ₦${remainingLimit.toStringAsFixed(2)}';
    }
    return null;
  }
}
