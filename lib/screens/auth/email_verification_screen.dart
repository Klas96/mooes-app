import 'package:flutter/material.dart';
import 'dart:async'; // Import for Timer
import 'package:flutter/foundation.dart'; // Import for kDebugMode
import '../../services/auth_service.dart';
import '../../constants/colors.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String firstName;

  const EmailVerificationScreen({
    Key? key,
    required this.email,
    required this.firstName,
  }) : super(key: key);

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isVerifying = false;
  bool _isResending = false;
  bool _codeExpired = false; // Changed from _tokenExpired
  final TextEditingController _codeController = TextEditingController(); // Changed from _tokenController
  String _email = '';
  String _firstName = '';

  // Timer for code expiration
  Timer? _timer;
  final int _codeExpiryMinutes = 10; // Matches backend expiry

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _startTimer();
  }

  Future<void> _loadUserData() async {
    print('=== DEBUG: EmailVerificationScreen._loadUserData ===');
    print('Widget email: "${widget.email}"');
    print('Widget firstName: "${widget.firstName}"');
    
    // Prioritize the email passed via widget arguments
    if (widget.email.isNotEmpty) {
      print('Using widget email: "${widget.email}"');
      setState(() {
        _email = widget.email;
        _firstName = widget.firstName;
      });
      return;
    }

    // If not provided, try to get it from the current user
    try {
      final user = await AuthService.getCurrentUser();
      if (user != null) {
        setState(() {
          _email = user['email'] ?? '';
          _firstName = user['firstName'] ?? '';
        });
      } else {
        // If no user data, navigate back to sign-in
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/signin');
        }
      }
    } catch (error) {
      print('Error loading user data: $error');
      // If an error occurs, navigate back to sign-in
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/signin');
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer(Duration(minutes: _codeExpiryMinutes), () {
      setState(() {
        _codeExpired = true;
      });
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    // Reset timer and code expired state
    _startTimer();
    setState(() {
      _codeExpired = false;
    });
  }

  Future<void> _resendVerificationEmail() async {
    setState(() {
      _isResending = true;
    });

    try {
      final result = await AuthService.resendVerificationEmail(_email);

      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification email sent successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          _resetTimer();
        }
      } else {
        // Use the error message from the result
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to resend email: ${result['message'] ?? 'An unknown error occurred.'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resend email: ${e.toString()}'), // Fallback for unexpected errors
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  Future<void> _verifyEmail() async {
    setState(() {
      _isVerifying = true;
    });

    try {
      final code = _codeController.text.trim();
      if (code.isEmpty) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Missing Code'),
            content: Text('Please enter the verification code'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      print('=== DEBUG: Starting email verification with code: ${code.substring(0, 3)}... ===');
      final result = await AuthService.verifyEmail(code);
      print('=== DEBUG: Verification result: $result ===');
      
      if (result['success']) {
        print('=== DEBUG: Verification successful, navigating to profile setup ===');
        print('=== DEBUG: Result data: $result ===');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Email verified successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Add a small delay to ensure the snackbar is shown
          await Future.delayed(const Duration(milliseconds: 500));
          
          print('=== DEBUG: About to navigate to profile setup ===');
          // Navigate directly to profile setup without calling getCurrentUser
          Navigator.of(context).pushReplacementNamed('/profile-setup');
          print('=== DEBUG: Navigation command sent ===');
        }
      } else {
        print('=== DEBUG: Verification failed: ${result['message']} ===');
        
        // Show more helpful error message for invalid codes
        String errorMessage = result['message'] ?? 'Verification failed';
        String additionalHelp = '';
        
        if (result['code'] == 'INVALID_CODE' || result['code'] == 'EXPIRED_CODE') {
          additionalHelp = '\n\nPlease check your email for the correct verification code, or request a new one using the "Resend Code" button below.';
        } else if (code.toLowerCase() == 'test') {
          additionalHelp = '\n\nIt looks like you entered "test" as the verification code. Please check your email for the actual verification code that was sent to you.';
        }
        
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Verification Failed'),
              content: Text('$errorMessage$additionalHelp'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      print('=== DEBUG: Verification exception: $e ===');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Verify Your Email'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            
            // Icon
            Icon(
              Icons.mark_email_unread_outlined,
              size: 80,
              color: AppColors.primaryGreen,
            ),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              'Check Your Email',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // Message
            Text(
              'Hi ${_firstName}, we\'ve sent a verification code to:',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            // Email
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryGreenLightest),
              ),
              child: Text(
                _email,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryGreen,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryGreenLightest),
              ),
              child: Column(
                children: [
                  Text(
                    'To complete your registration:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInstructionStep('1', 'Check your email inbox'),
                  _buildInstructionStep('2', 'Find the verification code'),
                  _buildInstructionStep('3', 'Enter the verification code below'),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Verification Code Input
            Text(
              'Verification Code',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryLight,
              ),
            ),
            
            const SizedBox(height: 8),
            
            TextFormField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: 'Verification Code',
                hintText: 'Enter the code from your email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primaryGreenLightest),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primaryGreenLightest),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primaryGreen, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: Icon(Icons.security, color: AppColors.primaryGreen),
                labelStyle: TextStyle(color: AppColors.textSecondaryLight),
                hintStyle: TextStyle(color: AppColors.textSecondaryLight.withOpacity(0.7)),
              ),
              style: TextStyle(
                color: AppColors.textPrimaryLight,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              enabled: !_codeExpired, // Disable if code expired
              onChanged: (value) {
                setState(() {
                  // Enable verify button when code is entered
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Helpful note about verification code
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primaryGreenLightest),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.primaryGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'The verification code is a 6-digit number sent to your email. Please check your inbox and spam folder.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Verify Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isVerifying || _codeExpired ? null : _verifyEmail, // Disable if code expired
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: _isVerifying
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(_codeExpired ? 'Code Expired - Resend' : 'Verify Email'), // Change text if code expired
              ),
            ),
            
            // Display message if code expired
            if (_codeExpired)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'Your verification code has expired. Please resend a new one.',
                  style: TextStyle(color: Colors.orange),
                  textAlign: TextAlign.center,
                ),
              ),
            
            const SizedBox(height: 24),
            
            // Divider
            Row(
              children: [
                Expanded(child: Divider(color: AppColors.primaryGreenLightest)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'OR',
                    style: TextStyle(
                      color: AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: AppColors.primaryGreenLightest)),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Resend Button
            OutlinedButton(
              onPressed: _isResending ? null : _resendVerificationEmail,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryGreen,
                side: BorderSide(color: AppColors.primaryGreen),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isResending
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                      ),
                    )
                  : const Text(
                      'Resend Verification Email',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            
            const SizedBox(height: 24),
            
            // Back to Login
            TextButton(
              onPressed: () => Navigator.of(context).pushReplacementNamed('/signin'),
              child: Text(
                'Back to Login',
                style: TextStyle(
                  color: AppColors.primaryGreen,
                  fontSize: 16,
                ),
              ),
            ),
            
            // Development mode helper (only shown in debug mode)
            if (kDebugMode)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.developer_mode,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Development Mode',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'For testing purposes, you can use a test verification code. However, you need to register first to get a valid code.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pushReplacementNamed('/signup'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange,
                              side: BorderSide(color: Colors.orange),
                            ),
                            child: Text('Go to Registration'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 