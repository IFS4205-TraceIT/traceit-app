import 'dart:convert';

import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:traceit_app/screens/tracing_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

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

  void checkIsLoggedIn() async {
    String? token = await _secureStorage.read(key: 'isLoggedIn');

    // If user is logged in, go to tracing screen
    if (mounted && token != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const TracingScreen(),
        ),
      );
    }
  }

  Future<String?>? onLogin(LoginData loginData) async {
    debugPrint('Login info');
    debugPrint('Username: ${loginData.name}');
    debugPrint('Password: ${loginData.password}');

    // Send login request to server
    http.Response response = await http.post(
      Uri.parse('http://10.0.2.2:8080/auth/login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'username': loginData.name,
        'password': loginData.password,
      }),
    );

    debugPrint(response.body);
    Map<String, dynamic> responseBody = jsonDecode(response.body);

    // If login is successful, save token to secure storage
    if (response.statusCode == 200) {
      bool hasOtp = responseBody['user']['has_otp'] as bool;
      String accessToken = responseBody['user']['tokens']['access'] as String;

      // TODO: Save token to secure storage
      await _secureStorage.write(key: 'tempAccessToken', value: accessToken);
      return null;
    } else if (response.statusCode >= 400 && response.statusCode < 500) {
      return 'Login failed! Please check your credentials.';
    } else {
      return 'Login failed! Please try again later.';
    }
  }

  Future<String?>? onSignUp(SignupData signupData) async {
    // TODO: implement signup
    debugPrint('Signup info');
    debugPrint('Name: ${signupData.name}');
    debugPrint('Password: ${signupData.password}');

    signupData.additionalSignupData?.forEach((key, value) {
      debugPrint('$key: $value');
    });

    // Send register request to server
    // Send login request to server
    http.Response response = await http.post(
      Uri.parse('http://10.0.2.2:8080/auth/register'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'username': signupData.name!,
        'password': signupData.password!,
        'email': signupData.additionalSignupData!['email']!,
        'phone_number': signupData.additionalSignupData!['phoneNumber']!,
      }),
    );

    debugPrint('Signup response code: ${response.statusCode.toString()}');
    debugPrint('Response body: ${response.body}');

    if (response.statusCode == 201) {
      return null;
    } else if (response.statusCode >= 400 && response.statusCode < 500) {
      return 'Signup failed! Please check your credentials.';
    } else {
      return 'Signup failed! Please try again later.';
    }
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
      loginAfterSignUp: false,
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
      onSubmitAnimationCompleted: () {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => const TracingScreen(),
        ));
      },
      onRecoverPassword: (name) {
        debugPrint('Recover password info');
        debugPrint('Name: $name');
        return Future.value(null);
      },
    );
  }
}
