import 'dart:convert';

import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:http/http.dart';
import 'package:traceit_app/server_auth.dart';
import 'package:traceit_app/screens/totp_screen.dart';
import 'package:traceit_app/screens/tracing_screen.dart';
import 'package:traceit_app/storage/storage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final Storage _storage = Storage();

  bool _hasOtp = false;
  late String _tempAccessToken;
  late String _tempRefreshToken;

  void checkIsLoggedIn() async {
    Map<String, String?> tokens = await _storage.getTokens();

    // If user is logged in, go to tracing screen
    if (mounted && tokens['accessToken'] != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const TracingScreen(),
        ),
      );
    }
  }

  String? isValidEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email cannot be empty!';
    } else if (!EmailValidator.validate(email)) {
      return 'Invalid email!';
    }
    return null;
  }

  String? isValidPhoneNumber(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      return 'Phone number cannot be empty!';
    } else if (!RegExp(r'^[+]?\d{8,}$').hasMatch(phoneNumber)) {
      // Example: +6598765432
      // Example: 98765432
      return 'Phone number must have at least 8 digits!';
    }
    return null;
  }

  Future<String?>? onLogin(LoginData loginData) async {
    debugPrint('Login info');
    debugPrint('Username: ${loginData.name}');
    debugPrint('Password: ${loginData.password}');

    // Send login request to server
    Response response = await ServerAuth.login(
      loginData.name,
      loginData.password,
    );

    debugPrint(response.body);
    Map<String, dynamic> responseBody = jsonDecode(response.body);

    // If login is successful, save token to secure storage
    if (response.statusCode == 200) {
      bool hasOtp = responseBody['user']['has_otp'] as bool;
      String tempAccessToken =
          responseBody['user']['tokens']['access'] as String;
      String tempRefreshToken =
          responseBody['user']['tokens']['refresh'] as String;

      setState(() {
        _hasOtp = hasOtp;
        _tempAccessToken = tempAccessToken;
        _tempRefreshToken = tempRefreshToken;
      });
      return null;
    } else if (response.statusCode >= 400 && response.statusCode < 500) {
      return 'Login failed! Please check your credentials.';
    } else {
      return 'Login failed! Please try again later.';
    }
  }

  Future<String?>? onSignUp(SignupData signupData) async {
    debugPrint('Signup info');
    debugPrint('Name: ${signupData.name}');
    debugPrint('Password: ${signupData.password}');
    debugPrint('Email: ${signupData.additionalSignupData!['email']}');
    debugPrint(
        'Phone number: ${signupData.additionalSignupData!['phoneNumber']}');

    // Send register request to server
    Response response = await ServerAuth.register(
      signupData.name!,
      signupData.password!,
      signupData.additionalSignupData!['email'] as String,
      signupData.additionalSignupData!['phoneNumber'] as String,
    );

    debugPrint('Signup response code: ${response.statusCode.toString()}');
    debugPrint('Response body: ${response.body}');

    if (response.statusCode == 201) {
      LoginData loginData = LoginData(
        name: signupData.name!,
        password: signupData.password!,
      );
      await onLogin(loginData);
      return null;
    } else if (response.statusCode >= 400 && response.statusCode < 500) {
      return 'Signup failed! Please check your credentials.';
    } else {
      return 'Signup failed! Please try again later.';
    }
  }

  void onSubmitAnimationCompleted() {
    // Navigate to TOTP screen
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (context) => TotpScreen(
        hasOtp: _hasOtp,
        tempAccessToken: _tempAccessToken,
        tempRefreshToken: _tempRefreshToken,
      ),
    ));
  }

  @override
  void initState() {
    super.initState();
    checkIsLoggedIn();
  }

  @override
  Widget build(BuildContext context) {
    return FlutterLogin(
      title: 'TraceIT',
      // logo: 'assets/images/logo.png',
      hideForgotPasswordButton: true,
      userType: LoginUserType.name,
      messages: LoginMessages(
        userHint: 'Username',
        signUpSuccess: 'Sign up successful. Proceed to login.',
      ),
      additionalSignupFields: [
        UserFormField(
          keyName: 'email',
          displayName: 'Email',
          icon: const Icon(Icons.email),
          fieldValidator: (email) => isValidEmail(email),
        ),
        UserFormField(
          keyName: 'phoneNumber',
          displayName: 'Phone Number',
          icon: const Icon(Icons.phone),
          fieldValidator: (phoneNumber) => isValidPhoneNumber(phoneNumber),
        ),
      ],
      userValidator: (username) {
        if (username == null || username.isEmpty) {
          return 'Username cannot be empty!';
        }
        return null;
      },
      passwordValidator: (password) {
        if (password == null || password.isEmpty) {
          return 'Password cannot be empty!';
        } else if (password.length < 8) {
          return 'Password must have at least 8 characters!';
        }
        return null;
      },
      onLogin: (loginData) => onLogin(loginData),
      onSignup: (signUpData) => onSignUp(signUpData),
      onSubmitAnimationCompleted: () => onSubmitAnimationCompleted(),
      onRecoverPassword: (name) {
        debugPrint('Recover password info');
        debugPrint('Name: $name');
        return Future.value(null);
      },
    );
  }
}