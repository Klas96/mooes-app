import 'package:flutter/material.dart';
import 'package:mooves/widgets/themed_text.dart';
import 'package:mooves/services/auth_service.dart';
import 'package:mooves/services/profile_service.dart';
import 'package:mooves/services/notification_service.dart';
import 'package:mooves/constants/colors.dart';
import 'email_verification_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Attempting Google Sign-In...');
      
      final result = await AuthService.signInWithGoogle();
      
      if (result['success'] == true) {
        final user = result['user'];
        
        if (user == null) {
          if (mounted) {
            _showErrorDialog('Invalid response from server. Please try again.');
          }
          return;
        }
        
        // Register FCM token after successful login
        try {
          await NotificationService.registerFCMTokenAfterLogin();
        } catch (e) {
          print('⚠️ Failed to register FCM token after login: $e');
        }
        
        final isEmailVerified = user['emailVerified'] ?? true; // Google accounts are pre-verified
        final isNewUser = result['isNewUser'] ?? false;
        
        if (!isEmailVerified) {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => EmailVerificationScreen(
                  email: user['email'] ?? '',
                  firstName: user['firstName'] ?? '',
                ),
              ),
            );
          }
          return;
        }
        
        // Check if user has a complete profile
        try {
          final profile = await ProfileService.getCompleteProfile();
          
          if (profile != null && !isNewUser) {
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/home');
            }
          } else {
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/profile-setup');
            }
          }
        } catch (e) {
          print('Profile check error: $e');
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/profile-setup');
          }
        }
      } else {
        // Handle error from AuthService
        final errorMessage = result['message'] ?? 'Google Sign-In failed. Please try again.';
        if (mounted && result['code'] != 'SIGN_IN_CANCELLED') {
          _showErrorDialog(errorMessage);
        }
      }
    } catch (error) {
      print('Google Sign-In error: $error');
      if (mounted) {
        _showErrorDialog('Google Sign-In failed. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showErrorDialog('Please enter both email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('Attempting to sign in...');
      
      // Use AuthService instead of direct HTTP call
      final result = await AuthService.signIn(email, password);
      
      if (result['success'] == true) {
        final user = result['user'];
        
        // Add null check for user object
        if (user == null) {
          if (mounted) {
            _showErrorDialog('Invalid response from server. Please try again.');
          }
          return;
        }
        
        // Register FCM token after successful login
        try {
          await NotificationService.registerFCMTokenAfterLogin();
        } catch (e) {
          print('⚠️ Failed to register FCM token after login: $e');
          // Don't block login if FCM registration fails
        }
        
        final isEmailVerified = user['emailVerified'] ?? false;
        
        if (!isEmailVerified) {
          print('Email not verified, redirecting to email verification');
          print('User data: $user');
          print('User email: ${user['email']}');
          print('Original email: $email');
          print('Final email to pass: ${user['email'] ?? email}');
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => EmailVerificationScreen(
                  email: user['email'] ?? email,
                  firstName: user['firstName'] ?? '',
                ),
              ),
            );
          }
          return;
        }
        
        // Email is verified, check if user has a complete profile
        try {
          print('=== DEBUG: Checking for complete profile ===');
          final profile = await ProfileService.getCompleteProfile();
          print('=== DEBUG: Complete profile found: ${profile != null} ===');
          
          if (profile != null) {
            print('=== DEBUG: Profile is complete, navigating to home ===');
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/home');
            }
          } else {
            print('=== DEBUG: No profile or incomplete profile, navigating to profile setup ===');
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/profile-setup');
            }
          }
        } catch (e) {
          print('=== DEBUG: Profile check error: $e ===');
          
          // Check if this is a profile incompleteness error
          if (e.toString().contains('Profile incomplete')) {
            print('=== DEBUG: Profile incomplete, redirecting to profile setup ===');
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/profile-setup');
            }
            return;
          }
          
          // Check if this is an authentication error
          if (e.toString().contains('Network error') || 
              e.toString().contains('No authentication token') ||
              e.toString().contains('401') ||
              e.toString().contains('403')) {
            print('=== DEBUG: Authentication error during profile check, showing error ===');
            if (mounted) {
              _showErrorDialog('Authentication error. Please try logging in again.');
            }
            return;
          }
          
          // For other profile errors, redirect to profile setup
          print('=== DEBUG: Profile error, redirecting to profile setup ===');
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/profile-setup');
          }
        }
      } else {
        // Handle error from AuthService
        final errorMessage = result['message'] ?? 'Sign in failed. Please try again.';
        if (mounted) {
          _showErrorDialog(errorMessage);
        }
      }
    } catch (error) {
      print('Sign in error: $error');
      if (mounted) {
        _showErrorDialog('Network error. Please check your connection and try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const ThemedText('Sign In Error', type: ThemedTextType.subtitle),
        content: ThemedText(message),
        actions: <Widget>[
          TextButton(
            child: const ThemedText('Okay', type: ThemedTextType.link),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required Map<String, Color> colors,
    Widget? suffixIcon,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
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
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      hintStyle: TextStyle(color: AppColors.textSecondaryLight.withOpacity(0.7)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = AppColors.colors[isDark ? 'dark' : 'light']!;

    return Scaffold(
      backgroundColor: colors['background'],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ThemedText(
                'Welcome Back',
                type: ThemedTextType.title,
                style: TextStyle(
                  color: colors['text'],
                ),
              ),
              const SizedBox(height: 30),
              Theme(
                data: Theme.of(context).copyWith(
                  inputDecorationTheme: InputDecorationTheme(
                    fillColor: Colors.white,
                    filled: true,
                  ),
                ),
                child: TextFormField(
                  controller: _emailController,
                  enabled: !_isLoading,
                  decoration: _inputDecoration(
                    label: 'Email',
                    hint: 'Email',
                    colors: colors,
                    prefixIcon: Icon(Icons.email, color: AppColors.primaryGreen),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(
                    color: AppColors.textPrimaryLight,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  cursorColor: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(height: 15),
              Theme(
                data: Theme.of(context).copyWith(
                  inputDecorationTheme: InputDecorationTheme(
                    fillColor: Colors.white,
                    filled: true,
                  ),
                ),
                child: TextFormField(
                  controller: _passwordController,
                  enabled: !_isLoading,
                  decoration: _inputDecoration(
                    label: 'Password',
                    hint: 'Password',
                    colors: colors,
                    prefixIcon: Icon(Icons.lock, color: AppColors.primaryGreen),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        color: AppColors.primaryGreen,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                  style: TextStyle(
                    color: AppColors.textPrimaryLight,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  cursorColor: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSignIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors['tint'],
                  foregroundColor: isDark && colors['tint'] == AppColors.tintColorDark 
                      ? colors['background'] 
                      : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3, 
                          color: Colors.white,
                        ),
                      )
                    : const ThemedText(
                        'Sign In', 
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 20),
              // Divider with "OR" text
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: AppColors.primaryGreenLightest,
                      thickness: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ThemedText(
                      'OR',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: AppColors.primaryGreenLightest,
                      thickness: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Google Sign-In Button
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _handleGoogleSignIn,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.textPrimaryLight,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  side: BorderSide(color: AppColors.primaryGreenLightest),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: Image.network(
                  'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                  height: 24,
                  width: 24,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.g_mobiledata, size: 24, color: AppColors.primaryGreen);
                  },
                ),
                label: ThemedText(
                  'Continue with Google',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: _isLoading ? null : () {
                  Navigator.pushNamed(context, '/signup');
                },
                child: ThemedText(
                  "Don't have an account? Sign Up",
                  type: ThemedTextType.link,
                  style: TextStyle(color: Colors.grey[300]),
                ),
              ),
              TextButton(
                onPressed: _isLoading ? null : () {
                  Navigator.pushNamed(context, '/forgot-password');
                },
                child: ThemedText(
                  "Forgot Password?",
                  type: ThemedTextType.link,
                  style: TextStyle(color: Colors.grey[300]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
