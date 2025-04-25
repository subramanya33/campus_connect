import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String usn;
  final bool isFirstLogin;

  const ResetPasswordScreen({super.key, required this.usn, required this.isFirstLogin});

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  String _errorMessage = '';
  bool _isLoading = false;
  bool _otpSent = false;

  @override
  void initState() {
    super.initState();
    _emailController.text = '${widget.usn.toLowerCase()}@mite.ac.in';
    print('DEBUG: ResetPasswordScreen initialized with USN: ${widget.usn}, isFirstLogin: ${widget.isFirstLogin}');
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim().toLowerCase();
    final expectedEmail = '${widget.usn.toLowerCase()}@mite.ac.in';
    print('DEBUG: Sending OTP for USN: ${widget.usn}, Entered Email: $email, Expected Email: $expectedEmail');

    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter institute email';
      });
      print('DEBUG: Email field empty');
      return;
    }
    if (!RegExp(r'^[a-zA-Z0-9]+@mite\.ac\.in$').hasMatch(email)) {
      setState(() {
        _errorMessage = 'Email must be in the format <usn>@mite.ac.in';
      });
      print('DEBUG: Invalid email format: $email');
      return;
    }
    if (email != expectedEmail) {
      setState(() {
        _errorMessage = 'Email must be ${widget.usn.toLowerCase()}@mite.ac.in';
      });
      print('DEBUG: Email mismatch. Entered: $email, Expected: $expectedEmail');
      return;
    }

    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });

    try {
      await _authService.requestOtp(widget.usn, email);
      setState(() {
        _otpSent = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OTP sent to $email')),
        );
      }
      print('DEBUG: OTP sent successfully to $email');
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
      print('DEBUG: Error sending OTP: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyAndReset() async {
    final otp = _otpController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    print('DEBUG: Verifying OTP: $otp, New Password: [HIDDEN], Confirm Password: [HIDDEN] for USN: ${widget.usn}');

    if (otp.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter OTP, new password, and confirm password';
      });
      print('DEBUG: OTP, new password, or confirm password empty');
      return;
    }
    if (newPassword.length < 8) {
      setState(() {
        _errorMessage = 'Password must be at least 8 characters long';
      });
      print('DEBUG: Password too short');
      return;
    }
    if (newPassword != confirmPassword) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      print('DEBUG: Password mismatch');
      return;
    }

    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });

    try {
      await _authService.verifyOtp(widget.usn, otp);
      print('DEBUG: OTP verified for USN: ${widget.usn}');
      await _authService.resetPassword(widget.usn, newPassword);
      print('DEBUG: Password reset for USN: ${widget.usn}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isFirstLogin ? 'Password set successfully!' : 'Password reset successfully!'),
          ),
        );
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
      print('DEBUG: Error verifying/resetting: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.isFirstLogin ? Colors.green : Colors.indigo;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isFirstLogin ? 'Set Your Password' : 'Reset Password'),
        backgroundColor: themeColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.isFirstLogin ? 'Welcome! Set your password.' : 'Reset your password.',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: themeColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (_errorMessage.isNotEmpty)
                  Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 16),
                if (!_otpSent) ...[
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Institute Email',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: Icon(Icons.email, color: themeColor),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _sendOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Send OTP', style: TextStyle(fontSize: 16)),
                  ),
                ] else ...[
                  TextField(
                    controller: _otpController,
                    decoration: InputDecoration(
                      labelText: 'OTP',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: Icon(widget.isFirstLogin ? Icons.star : Icons.lock, color: themeColor),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _newPasswordController,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: Icon(widget.isFirstLogin ? Icons.star : Icons.lock, color: themeColor),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: Icon(widget.isFirstLogin ? Icons.star : Icons.lock, color: themeColor),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _verifyAndReset,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            widget.isFirstLogin ? 'Set Password' : 'Reset Password',
                            style: const TextStyle(fontSize: 16),
                          ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    print('DEBUG: ResetPasswordScreen disposed');
    super.dispose();
  }
}