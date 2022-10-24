import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:traceit_app/screens/user_auth/form_validator.dart';
import 'package:traceit_app/server_auth.dart';
import 'package:traceit_app/storage/storage.dart';
import 'package:traceit_app/utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final Storage _storage = Storage();

  bool _isLogin = true;

  // Login form
  final _loginFormKey = GlobalKey<FormState>();
  final _loginUsernameController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _loginPasswordIsObscure = true;

  // Register form
  final _registrationFormKey = GlobalKey<FormState>();
  final _registrationUsernameController = TextEditingController();
  bool _registreationPasswordIsObscure = true;
  final _registrationPasswordController = TextEditingController();
  bool _registreationConfirmPasswordIsObscure = true;
  final _registrationConfirmPasswordController = TextEditingController();
  final _registrationEmailController = TextEditingController();
  final _registrationPhoneNumberController = TextEditingController();
  final _registrationNricController = TextEditingController();
  final _registrationNameController = TextEditingController();
  final _registrationDobController = TextEditingController();
  String? _registrationGenderSelected;
  final _registrationAddressController = TextEditingController();
  final _registrationPostalCodeController = TextEditingController();

  Future<void> _requestAppPermissions() async {
    final Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.bluetooth,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.camera,
    ].request();

    debugPrint(statuses.toString());
  }

  Future<bool> _checkIsLoggedIn() async {
    bool isLoggedIn = await _storage.getLoginStatus();

    // If user is logged in, go to tracing screen
    if (mounted && isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/tracing');
    }

    return isLoggedIn;
  }

  void _toggleCard() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  Future<void> _submitLogin() async {
    String username = _loginUsernameController.text;
    String password = _loginPasswordController.text;

    if (_loginFormKey.currentState != null &&
        !_loginFormKey.currentState!.validate()) {
      Utils.showSnackBar(
        context,
        'Please check your login credentials!',
        color: Colors.red,
      );

      return;
    }

    // Send login request to server
    Map<String, dynamic> loginStatus =
        await ServerAuth.login(username, password);

    if (loginStatus['statusCode'] == 200) {
      // Save token to secure storage
      bool hasOtp = loginStatus['hasOtp'];
      String tempAccessToken = loginStatus['tempAccessToken'];
      String tempRefreshToken = loginStatus['tempRefreshToken'];

      // Navigate to TOTP screen
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/totp',
          arguments: {
            'hasOtp': hasOtp,
            'tempAccessToken': tempAccessToken,
            'tempRefreshToken': tempRefreshToken,
          },
        );
      }
    } else if (loginStatus['statusCode'] >= 400 &&
        loginStatus['statusCode'] < 500) {
      if (mounted) {
        Utils.showSnackBar(
          context,
          'Login failed! Please check your credentials.',
          color: Colors.red,
        );
      }
    } else {
      if (mounted) {
        Utils.showSnackBar(
          context,
          'Login failed! Please try again later.',
          color: Colors.red,
        );
      }
    }
  }

  Future<void> _submitRegister() async {
    if (_registrationFormKey.currentState != null &&
        !_registrationFormKey.currentState!.validate()) {
      Utils.showSnackBar(
        context,
        'Please check your registration details!',
        color: Colors.red,
      );

      return;
    }

    String username = _registrationUsernameController.text;
    String password = _registrationPasswordController.text;
    String email = _registrationEmailController.text;
    String phoneNumber = _registrationPhoneNumberController.text;
    String nric = _registrationNricController.text;
    String name = _registrationNameController.text;
    String dob = _registrationDobController.text;
    String gender = _registrationGenderSelected!;
    String address = _registrationAddressController.text;
    String postalCode = _registrationPostalCodeController.text;

    // Send registration request to server
    Map<String, dynamic> registrationStatus = await ServerAuth.register(
      username,
      password,
      email,
      phoneNumber,
      nric,
      name,
      dob,
      gender,
      address,
      postalCode,
    );

    int statusCode = registrationStatus['statusCode'];
    String statusBody = registrationStatus['body'];

    if (statusCode == 201) {
      // Proceed with login
      setState(() {
        _loginUsernameController.text = username;
        _loginPasswordController.text = password;
      });
      _toggleCard();
      _submitLogin();
    } else if (statusCode == 408) {
      if (mounted) {
        Utils.showSnackBar(
          context,
          'Request Timeout! Please try again later.',
          color: Colors.red,
        );
      }
    } else if (statusCode == 400) {
      Map<String, dynamic> responseBody = jsonDecode(statusBody);

      // Check if error is due to password
      if (!responseBody.containsKey('errors') ||
          !responseBody['errors'].containsKey('password')) {
        if (mounted) {
          Utils.showSnackBar(
            context,
            'Registration failed! Please try again later.',
            color: Colors.red,
          );
        }

        return;
      }

      // Show password error
      String passwordError = responseBody['errors']['password'][0];
      if (mounted) {
        Utils.showSnackBar(
          context,
          passwordError,
          color: Colors.red,
        );
      }
    } else if (statusCode > 400 && statusCode < 500) {
      if (mounted) {
        Utils.showSnackBar(
          context,
          'Registration failed! Please check your credentials.',
          color: Colors.red,
        );
      }
    } else {
      if (mounted) {
        Utils.showSnackBar(
          context,
          'Registration failed! Please try again later.',
          color: Colors.red,
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();

    _requestAppPermissions();

    _checkIsLoggedIn().then((isLoggedIn) {
      if (!isLoggedIn) {
        // Wait for storage to be initialized
        Future.doWhile(() async {
          bool storageLoaded = _storage.isLoaded();

          if (storageLoaded) {
            // Delete temp IDs
            await _storage.deleteAllTempIds();

            // Delete tokens
            _storage.deleteTokens();

            // Set login status to false
            _storage.setLoginStatus(false);
          } else {
            await Future.delayed(const Duration(milliseconds: 100));
          }

          return !storageLoaded;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'TraceIT',
                style: Theme.of(context)
                    .textTheme
                    .apply(
                      displayColor: Colors.white,
                      fontSizeFactor: 0.6,
                    )
                    .headline1,
              ),
              Visibility(
                visible: _isLogin,
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 30,
                    ),
                    width: 300,
                    child: Form(
                      key: _loginFormKey,
                      autovalidateMode: AutovalidateMode.always,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _loginUsernameController,
                            decoration: const InputDecoration(
                              labelText: 'Username',
                              prefixIcon: Icon(Icons.account_circle),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(30),
                                ),
                              ),
                            ),
                            validator: (username) =>
                                FormValidator.isValidUsername(username),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _loginPasswordController,
                            obscureText: _loginPasswordIsObscure,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock),
                              border: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(30),
                                ),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _loginPasswordIsObscure
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _loginPasswordIsObscure =
                                        !_loginPasswordIsObscure;
                                  });
                                },
                              ),
                            ),
                            validator: (password) =>
                                FormValidator.isValidPassword(password),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () => _submitLogin(),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text('Login'),
                          ),
                          OutlinedButton(
                            onPressed: () => _toggleCard(),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text('Register'),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Visibility(
                visible: !_isLogin,
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 30,
                    ),
                    width: 300,
                    child: Form(
                      key: _registrationFormKey,
                      autovalidateMode: AutovalidateMode.always,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _registrationUsernameController,
                            decoration: const InputDecoration(
                              labelText: 'Username',
                              prefixIcon: Icon(Icons.account_circle),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(30),
                                ),
                              ),
                            ),
                            validator: (username) =>
                                FormValidator.isValidUsername(username),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _registrationPasswordController,
                            obscureText: _registreationPasswordIsObscure,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock),
                              border: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(30),
                                ),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _registreationPasswordIsObscure
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _registreationPasswordIsObscure =
                                        !_registreationPasswordIsObscure;
                                  });
                                },
                              ),
                            ),
                            validator: (password) =>
                                FormValidator.isValidPassword(password),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _registrationConfirmPasswordController,
                            obscureText: _registreationConfirmPasswordIsObscure,
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              prefixIcon: const Icon(Icons.lock),
                              border: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(30),
                                ),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _registreationConfirmPasswordIsObscure
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _registreationConfirmPasswordIsObscure =
                                        !_registreationConfirmPasswordIsObscure;
                                  });
                                },
                              ),
                            ),
                            validator: (confirmPassword) =>
                                FormValidator.isMatchingPassword(
                              _registrationPasswordController.text,
                              confirmPassword,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _registrationEmailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(30),
                                ),
                              ),
                            ),
                            validator: (email) =>
                                FormValidator.isValidEmail(email),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _registrationPhoneNumberController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              prefixIcon: Icon(Icons.phone_rounded),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(30),
                                ),
                              ),
                            ),
                            validator: (phoneNumber) =>
                                FormValidator.isValidPhoneNumber(phoneNumber),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _registrationNricController,
                            maxLength: 9,
                            decoration: const InputDecoration(
                              labelText: 'NRIC',
                              prefixIcon: Icon(Icons.badge),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(30),
                                ),
                              ),
                            ),
                            validator: (name) =>
                                FormValidator.isValidNric(name),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _registrationNameController,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(30),
                                ),
                              ),
                            ),
                            validator: (name) =>
                                FormValidator.isValidName(name),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _registrationDobController,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Date of Birth',
                              prefixIcon: Icon(Icons.calendar_today),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(30),
                                ),
                              ),
                            ),
                            onTap: () async {
                              DateTime? dateOfBirth = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                              );

                              if (dateOfBirth != null) {
                                String formattedDob = DateFormat('yyyy-MM-dd')
                                    .format(dateOfBirth);
                                setState(() {
                                  _registrationDobController.text =
                                      formattedDob;
                                });
                              }
                            },
                            validator: (dateOfBirth) =>
                                FormValidator.isValidDateOfBirth(dateOfBirth),
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField(
                            value: _registrationGenderSelected,
                            items: const [
                              DropdownMenuItem(
                                value: 'm',
                                child: Text('Male'),
                              ),
                              DropdownMenuItem(
                                value: 'f',
                                child: Text('Female'),
                              ),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Gender',
                              prefixIcon: Icon(Icons.face),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(30),
                                ),
                              ),
                            ),
                            onChanged: (gender) {
                              setState(() {
                                _registrationGenderSelected = gender;
                              });
                            },
                            validator: (gender) =>
                                FormValidator.isValidGender(gender),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _registrationAddressController,
                            decoration: const InputDecoration(
                              labelText: 'Address',
                              prefixIcon: Icon(Icons.home),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(30),
                                ),
                              ),
                            ),
                            validator: (address) =>
                                FormValidator.isValidAddress(address),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _registrationPostalCodeController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            decoration: const InputDecoration(
                              labelText: 'Postal Code',
                              prefixIcon: Icon(Icons.contact_mail),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(30),
                                ),
                              ),
                            ),
                            validator: (postalCode) =>
                                FormValidator.isValidPostalCode(postalCode),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'By registering, you consent to the '
                            'collection and use of your personal data by '
                            'official contact tracers for the purpose of '
                            'contacting you in the event of infection and '
                            'for research.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () => _submitRegister(),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text('Register'),
                          ),
                          OutlinedButton(
                            onPressed: () => _toggleCard(),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text('Login'),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
