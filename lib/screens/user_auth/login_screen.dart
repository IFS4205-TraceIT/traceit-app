import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:traceit_app/screens/user_auth/form_validator.dart';
import 'package:traceit_app/screens/user_auth/totp_screen.dart';
import 'package:traceit_app/server_auth.dart';
import 'package:traceit_app/storage/storage.dart';

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

  bool _hasOtp = false;

  Future<bool> _checkIsLoggedIn() async {
    bool isLoggedIn = await _storage.getLoginStatus();

    // If user is logged in, go to tracing screen
    if (mounted && isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/tracing');
    }

    return isLoggedIn;
  }

  void _showSnackBar(String message, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  void _toggleCard() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  Future<void> _submitLogin() async {
    String username = _loginUsernameController.text;
    String password = _loginPasswordController.text;

    debugPrint('Username: $username');
    debugPrint('Password: $password');

    if (_loginFormKey.currentState != null &&
        !_loginFormKey.currentState!.validate()) {
      _showSnackBar('Please check your login credentials!', color: Colors.red);
      return;
    }

    // Send login request to server
    Map<String, dynamic> loginStatus =
        await ServerAuth.login(username, password);

    if (loginStatus['statusCode'] == 200) {
      // Save token to secure storage
      String tempAccessToken = loginStatus['tempAccessToken'];
      String tempRefreshToken = loginStatus['tempRefreshToken'];
      await _storage.saveTokens(tempAccessToken, tempRefreshToken);

      setState(() {
        _hasOtp = loginStatus['hasOtp'];
      });

      // Navigate to TOTP screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TotpScreen(hasOtp: _hasOtp),
          ),
        );
      }
    } else if (loginStatus['statusCode'] >= 400 &&
        loginStatus['statusCode'] < 500) {
      _showSnackBar(
        'Login failed! Please check your credentials.',
        color: Colors.red,
      );
    } else {
      _showSnackBar('Login failed! Please try again later.', color: Colors.red);
    }
  }

  Future<void> _submitRegister() async {
    if (_registrationFormKey.currentState != null &&
        !_registrationFormKey.currentState!.validate()) {
      _showSnackBar(
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

    debugPrint('Username: $username');
    debugPrint('Password: $password');
    debugPrint('Email: $email');
    debugPrint('Phone number: $phoneNumber');
    debugPrint('NRIC: $nric');
    debugPrint('Name: $name');
    debugPrint('Date of birth: $dob');
    debugPrint('Gender: $gender');
    debugPrint('Address: $address');
    debugPrint('Postal code: $postalCode');

    // Send registration request to server
    int registrationStatus = await ServerAuth.register(
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

    if (registrationStatus == 201) {
      // Proceed with login
      setState(() {
        _loginUsernameController.text = username;
        _loginPasswordController.text = password;
      });
      _toggleCard();
      _submitLogin();
    } else if (registrationStatus >= 400 && registrationStatus < 500) {
      _showSnackBar(
        'Registration failed! Please check your credentials.',
        color: Colors.red,
      );
    } else {
      _showSnackBar(
        'Registration failed! Please try again later.',
        color: Colors.red,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _checkIsLoggedIn().then((isLoggedIn) {
      if (!isLoggedIn) {
        // Wait for storage to be initialized
        Future.doWhile(() async {
          bool storageLoaded = _storage.isLoaded();

          if (storageLoaded) {
            // Delete temp IDs
            _storage.deleteAllTempIds();

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