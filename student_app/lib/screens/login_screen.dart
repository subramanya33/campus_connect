import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usnController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  String _errorMessage = '';
  bool _isFirstLogin = false;
  bool _isLoading = false;
  bool _hasCheckedStatus = false;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    print('DEBUG: LoginScreen initialized');
    // Enforce uppercase USN input
    _usnController.addListener(() {
      final text = _usnController.text.toUpperCase();
      if (_usnController.text != text) {
        _usnController.value = _usnController.value.copyWith(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      }
    });
  }

  Future<void> _checkLoginStatus() async {
    final usn = _usnController.text.trim();
    if (usn.isEmpty || usn != '4MT21AI058') {
      setState(() {
        _errorMessage = 'Please enter valid USN (e.g., 4MT21AI058)';
      });
      print('DEBUG: Invalid USN: $usn');
      return;
    }

    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });

    try {
      final result = await _authService.checkLoginStatus(usn);
      setState(() {
        _isFirstLogin = result['firstLogin'] ?? false;
        _hasCheckedStatus = true;
      });
      print('DEBUG: checkLoginStatus result - USN: $usn, isFirstLogin: $_isFirstLogin');
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
      print('DEBUG: Error in checkLoginStatus: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogin() async {
    final usn = _usnController.text.trim();
    final password = _passwordController.text.trim();
    if (usn.isEmpty || usn != '4MT21AI058') {
      setState(() {
        _errorMessage = 'Please enter valid USN (e.g., 4MT21AI058)';
      });
      print('DEBUG: Invalid USN in handleLogin: $usn');
      return;
    }
    if (password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter password';
      });
      print('DEBUG: Password empty in handleLogin');
      return;
    }

    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });

    try {
      await _authService.login(usn, password);
      print('DEBUG: Login successful for USN: $usn');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login successful!')),
      );
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
      print('DEBUG: Error in handleLogin: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handlePasswordReset() async {
    final usn = _usnController.text.trim();
    if (usn.isEmpty || usn != '4MT21AI058') {
      setState(() {
        _errorMessage = 'Please enter valid USN (e.g., 4MT21AI058)';
      });
      print('DEBUG: Invalid USN in handlePasswordReset: $usn');
      return;
    }

    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });

    try {
      await _checkLoginStatus();
      Navigator.pushNamed(
        context,
        '/reset-password',
        arguments: {'usn': usn, 'isFirstLogin': _isFirstLogin},
      );
      print('DEBUG: Navigating to ResetPasswordScreen for USN: $usn');
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
      print('DEBUG: Error in handlePasswordReset: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'CampusConnect Login',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_errorMessage.isNotEmpty)
                    Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _usnController,
                    decoration: InputDecoration(
                      labelText: 'USN',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: const Icon(Icons.person),
                      hintText: 'e.g., 4MT21AI058',
                    ),
                    onChanged: (value) {
                      setState(() {
                        _hasCheckedStatus = false;
                        _isFirstLogin = false;
                        _errorMessage = '';
                      });
                      print('DEBUG: USN changed: $value');
                      if (value.trim() == '4MT21AI058') {
                        _checkLoginStatus();
                      }
                    },
                  ),
                  if (_hasCheckedStatus && !_isFirstLogin) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscureText,
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (_hasCheckedStatus && !_isFirstLogin)
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Login',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  if (_hasCheckedStatus && _isFirstLogin)
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handlePasswordReset,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Set Password',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _isLoading || !_hasCheckedStatus || _isFirstLogin ? null : _handlePasswordReset,
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(color: Colors.indigo),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usnController.dispose();
    _passwordController.dispose();
    print('DEBUG: LoginScreen disposed');
    super.dispose();
  }
}