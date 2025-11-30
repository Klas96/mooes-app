import 'package:flutter/material.dart';
import 'package:mooves/screens/auth/signin_screen.dart';
import 'package:mooves/screens/auth/signup_screen.dart';
import 'package:mooves/screens/auth/email_verification_screen.dart';
import 'package:mooves/screens/auth/forgot_password_screen.dart';
import 'package:mooves/screens/auth/reset_password_screen.dart';
import 'package:mooves/screens/tabs/home_tab.dart';
import 'package:mooves/screens/tabs/profile_tab.dart';
import 'package:mooves/screens/coupons_screen.dart';
import 'package:mooves/screens/store_goals_screen.dart';
import 'package:mooves/screens/profile_setup_screen.dart';
import 'package:mooves/screens/debug_screen.dart';
import 'package:mooves/constants/colors.dart';
import 'package:mooves/services/notification_service.dart';
import 'package:mooves/services/auth_service.dart';
import 'package:mooves/services/profile_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications
  await NotificationService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lightScheme = AppColors.getColorScheme(Brightness.light);
    final darkScheme = AppColors.getColorScheme(Brightness.dark);

    return MaterialApp(
      title: 'Mooves',
      theme: ThemeData(
        colorScheme: lightScheme,
        scaffoldBackgroundColor: AppColors.backgroundPink, // Pink background
        canvasColor: AppColors.backgroundPink,
        cardColor: AppColors.pinkCard, // Pink cards
        useMaterial3: true,
        textTheme: Typography.blackMountainView.apply(
          bodyColor: AppColors.textColor(Brightness.light),
          displayColor: AppColors.textColor(Brightness.light),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.pinkCard, // Pink background for inputs
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.pinkAccent.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.pinkAccent.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.accentCoral, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          labelStyle: const TextStyle(color: AppColors.textSecondary),
          hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.6)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: lightScheme.primary,
            foregroundColor: lightScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 6,
            shadowColor: lightScheme.primary.withOpacity(0.25),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: lightScheme.primary,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: lightScheme.primary,
            side: BorderSide(color: lightScheme.primary),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: lightScheme.primary,
          foregroundColor: lightScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.pinkCard, // Pink app bar
          foregroundColor: AppColors.textOnPink, // Dark text on pink
          elevation: 0,
          centerTitle: true,
          titleTextStyle: const TextStyle(
            color: AppColors.textOnPink,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: lightScheme.primary,
          unselectedItemColor: AppColors.textSecondaryColor(Brightness.light),
          backgroundColor: AppColors.pinkCard, // Pink bottom nav
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        cardTheme: CardThemeData(
          color: AppColors.pinkCard, // Pink cards
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.pinkCard, // Pink background
          contentTextStyle: const TextStyle(
            color: AppColors.textOnPink, // Dark text on pink
            fontSize: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.pinkCard, // Pink background
          titleTextStyle: const TextStyle(
            color: AppColors.textOnPink, // Dark text on pink
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          contentTextStyle: const TextStyle(
            color: AppColors.textOnPink, // Dark text on pink
            fontSize: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        datePickerTheme: DatePickerThemeData(
          backgroundColor: AppColors.pinkCard, // Pink background
          headerBackgroundColor: AppColors.pinkCard,
          headerForegroundColor: AppColors.textOnPink,
          dayStyle: const TextStyle(color: AppColors.textOnPink),
          weekdayStyle: const TextStyle(color: AppColors.textOnPink),
          yearStyle: const TextStyle(color: AppColors.textOnPink),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: darkScheme,
        scaffoldBackgroundColor: darkScheme.background,
        canvasColor: darkScheme.background,
        useMaterial3: true,
        textTheme: Typography.whiteMountainView,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceAlt(Brightness.dark),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: darkScheme.primary.withOpacity(.4)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: darkScheme.primary, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: darkScheme.primary,
            foregroundColor: darkScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24))
                  .borderRadius,
            ),
            elevation: 4,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: darkScheme.primary,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: darkScheme.primary,
            side: BorderSide(color: darkScheme.primary),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: darkScheme.primary,
          foregroundColor: darkScheme.onPrimary,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: darkScheme.background,
          foregroundColor: darkScheme.onBackground,
          elevation: 0,
          centerTitle: true,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: darkScheme.primary,
          unselectedItemColor: AppColors.textSecondaryColor(Brightness.dark),
          backgroundColor: darkScheme.background,
        ),
        cardTheme: CardThemeData(
          color: AppColors.surfaceAlt(Brightness.dark),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
      home: const SplashScreen(),
      routes: {
        '/signin': (context) => const SignInScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const MainTabScreen(),
        '/profile-setup': (context) => const ProfileSetupScreen(),
        '/debug': (context) => const DebugScreen(),
        '/email-verification': (context) => EmailVerificationScreen(
              email: '',
              firstName: '',
            ),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      print('=== DEBUG: App initialization started ===');

      // Check network connectivity first (disabled - not needed for VPS backend)
      // try {
      //   final result = await http.get(Uri.parse('https://www.google.com'));
      //   if (result.statusCode == 200) {
      //     print('Network connectivity: OK');
      //   }
      // } catch (e) {
      //   print('Network connectivity: FAILED - $e');
      //   // Continue anyway, but this might explain backend issues
      // }

      // Initialize authentication system with shorter timeout
      final hasValidSession = await AuthService.initialize()
          .timeout(const Duration(seconds: 10), onTimeout: () {
        print('App initialization timeout, redirecting to sign in');
        throw Exception('Initialization timeout');
      });

      if (hasValidSession) {
        print('Valid session found, checking user status...');

        // Get current user to check email verification status
        final user = await AuthService.getCurrentUser();

        if (user != null) {
          // Check if email is verified
          final isEmailVerified = user['emailVerified'] ?? false;

          if (!isEmailVerified) {
            print('Email not verified, redirecting to email verification');
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

            if (profile != null) {
              print(
                  'User authenticated and profile complete, redirecting to main app');
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/home');
              }
            } else {
              print('No complete profile found, redirecting to profile setup');
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/profile-setup');
              }
            }
          } catch (e) {
            print('Profile check error: $e');

            // Check if this is a profile incompleteness error
            if (e.toString().contains('Profile incomplete')) {
              print('Profile incomplete, redirecting to profile setup');
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/profile-setup');
              }
              return;
            }

            // For other errors (network, auth), redirect to sign in
            print('Profile check failed with error, redirecting to sign in');
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/signin');
            }
            return;
          }
        } else {
          print('No user data found, redirecting to sign in');
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/signin');
          }
        }
      } else {
        print('No valid session found, redirecting to sign in');
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/signin');
        }
      }
    } catch (e) {
      print('App initialization error: $e');

      // Check if this is a user not found error
      if (e.toString().contains('User not found') ||
          e.toString().contains('USER_NOT_FOUND')) {
        print('User not found in database, clearing invalid tokens');
        await AuthService.handleInvalidToken();
      }

      // Always redirect to sign in on any error
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/signin');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPink, // Pink background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo or icon
            Icon(
              Icons.favorite,
              size: 80,
              color: AppColors.primaryPurple, // Purple icon on pink
            ),
            const SizedBox(height: 24),

            // App name
            const Text(
              'Mooves',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.textOnPink, // Dark text on pink
              ),
            ),

            const SizedBox(height: 48),

            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPurple), // Purple spinner
            ),

            const SizedBox(height: 24),

            // Loading text
            const Text(
              'Loading...',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary, // Dark secondary text
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({Key? key}) : super(key: key);

  @override
  _MainTabScreenState createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _currentIndex = 0;

  // Define a type for the callback
  // typedef NavigateToTabCallback = void Function(int index); // Not strictly necessary to define type here

  // Method to change the tab
  void _navigateToTab(int index) {
    if (index >= 0 && index < _tabs.length) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  // Updated list of tabs that will receive the callback
  // Note: The individual tab files (HomeTab, ExploreTab, etc.) will need to be updated
  // to accept this callback in their constructors.
  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();

    print('=== DEBUG: MainTabScreen.initState started ===');

    try {
      // Initialize _tabs here where _navigateToTab is available
      _tabs = [
        HomeTab(navigateToTab: _navigateToTab),
        const StoreGoalsScreen(),
        const CouponsScreen(),
        ProfileTab(navigateToTab: _navigateToTab),
      ];
      print('=== DEBUG: MainTabScreen tabs initialized successfully ===');

      // Register FCM token if not already registered (don't await - let it run in background)
      NotificationService.registerFCMTokenAfterLogin().then((_) {
        print('=== DEBUG: FCM token registration attempted ===');
      }).catchError((e) {
        print('=== DEBUG: FCM token registration failed: $e ===');
      });

      // WebSocket removed - using FCM for push notifications instead

      // Set up periodic session refresh
      _setupSessionRefresh();
      print('=== DEBUG: Session refresh setup complete ===');
    } catch (e) {
      print('=== DEBUG: MainTabScreen initialization error: $e ===');
      rethrow;
    }
  }

  void _setupSessionRefresh() {
    // Refresh session every 6 hours to keep it alive
    Future.delayed(const Duration(hours: 6), () async {
      if (mounted) {
        await AuthService.refreshSessionIfNeeded();
        _setupSessionRefresh(); // Schedule next refresh
      }
    });
  }

  @override
  void dispose() {
    // WebSocket removed - using FCM for push notifications instead
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: AppColors.activeTabYellow,
        unselectedItemColor: AppColors.textSecondaryLight,
        backgroundColor: AppColors.pinkCard, // Pink bottom nav
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Log',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: 'Challenges',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer),
            label: 'Coupons',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
