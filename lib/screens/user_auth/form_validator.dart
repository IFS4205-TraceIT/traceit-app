import 'package:email_validator/email_validator.dart';

class FormValidator {
  static String? isValidUsername(String? username) {
    if (username == null || username.isEmpty) {
      return 'Username cannot be empty!';
    }
    return null;
  }

  static String? isValidPassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password cannot be empty!';
    } else if (password.length < 8) {
      return 'Password must have at least 8 characters!';
    }
    return null;
  }

  static String? isMatchingPassword(String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Confirm password cannot be empty!';
    } else if (password != confirmPassword) {
      return 'Passwords do not match!';
    }
    return null;
  }

  static String? isValidEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email cannot be empty!';
    } else if (!EmailValidator.validate(email)) {
      return 'Invalid email!';
    }
    return null;
  }

  static String? isValidPhoneNumber(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      return 'Phone number cannot be empty!';
    } else if (!RegExp(r'^[+]?\d{8,}$').hasMatch(phoneNumber)) {
      // Example: +6598765432
      // Example: 98765432
      return 'Phone number must have at least 8 digits!';
    }
    return null;
  }

  static String? isValidNric(String? nric) {
    if (nric == null || nric.isEmpty) {
      return 'NRIC cannot be empty!';
    } else if (!RegExp(r'^[STFG]\d{7}[A-Z]$').hasMatch(nric)) {
      // Example: S1234567A
      return 'Invalid NRIC!';
    }
    return null;
  }

  static String? isValidName(String? name) {
    if (name == null || name.isEmpty) {
      return 'Name cannot be empty!';
    }
    return null;
  }

  static String? isValidDateOfBirth(String? dateOfBirth) {
    if (dateOfBirth == null || dateOfBirth.isEmpty) {
      return 'Date of birth cannot be empty!';
    }
    return null;
  }

  static String? isValidGender(String? gender) {
    if (gender == null || gender.isEmpty) {
      return 'Gender cannot be empty!';
    }
    return null;
  }

  static String? isValidAddress(String? address) {
    if (address == null || address.isEmpty) {
      return 'Address cannot be empty!';
    }
    return null;
  }

  static String? isValidPostalCode(String? postalCode) {
    if (postalCode == null || postalCode.isEmpty) {
      return 'Postal code cannot be empty!';
    } else if (!RegExp(r'^\d{6}$').hasMatch(postalCode)) {
      // Example: 123456
      return 'Invalid postal code!';
    }
    return null;
  }
}
