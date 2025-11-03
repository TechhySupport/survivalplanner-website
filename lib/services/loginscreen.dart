import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'signup_screen.dart';
import 'terms_and_services.dart';
import 'privacy_policy.dart';
import 'analytics_service.dart';

// The global Supabase client instance from main.dart
final supabase = Supabase.instance.client;

// Google OAuth Web Client ID (kept for reference; OAuth flow is handled by Supabase)
const String kGoogleWebClientId =
    '258192286365-4qi5u7h604nn1paug7c58r364o5dqqb8.apps.googleusercontent.com';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isAppleAvailable = false;
  StreamSubscription<AuthState>? _sub;
  bool _didNavigateBackOnAuth = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logPage('LoginScreen');

    // 🔑 Listen for Supabase auth changes
    _sub = supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null && mounted) {
        if (!_didNavigateBackOnAuth) {
          _didNavigateBackOnAuth = true;
          // Return to the previous screen with success so callers can continue their flow
          Future.microtask(() {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop(true);
            }
          });
        }
      }

      if (event == AuthChangeEvent.signedOut) {
        // Optionally handle logout
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Signed out'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });

    // Check if Sign in with Apple is available (iOS 13+/macOS 10.15+, iCloud signed-in, capability present)
    SignInWithApple.isAvailable().then((available) {
      if (mounted) setState(() => _isAppleAvailable = available);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // Navigation handled by auth change listener in initState
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      // Preserve current location so we can return here after OAuth
      final currentUrl = Uri.base.toString();
      final appEntry = '${Uri.base.origin}/web/index.html';
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? appEntry : 'io.supabase.flutter://login-callback/',
        // Pass through desired return URL so we can navigate back post-login
        queryParams: {'redirect_to': currentUrl},
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google sign-in error: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google sign-in failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Native Apple Sign-In (no Supabase). Only available on Apple platforms.
  Future<void> _signInWithAppleNative() async {
    try {
      // Fast availability guard with helpful hint
      final available = await SignInWithApple.isAvailable();
      if (!available) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Sign in with Apple isn't available. Ensure you're on iOS 13+ and signed into iCloud, and the app has the 'Sign in with Apple' capability.",
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Request Apple credential
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Sign into Supabase with Apple ID token
      if (credential.identityToken != null) {
        await supabase.auth.signInWithIdToken(
          provider: OAuthProvider.apple,
          idToken: credential.identityToken!,
        );
        // Navigation handled by auth change listener in initState
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Signed in with Apple'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('No identity token received from Apple');
      }
    } on SignInWithAppleAuthorizationException catch (e) {
      if (mounted) {
        final code = e.code;
        String hint = '';
        switch (code) {
          case AuthorizationErrorCode.canceled:
            hint = 'You canceled the sign-in.';
            break;
          case AuthorizationErrorCode.failed:
            hint = 'Authorization failed. Try again.';
            break;
          case AuthorizationErrorCode.invalidResponse:
            hint = 'Invalid response from Apple. Retry.';
            break;
          case AuthorizationErrorCode.notHandled:
            hint = 'Request not handled. Retry or restart the app.';
            break;
          case AuthorizationErrorCode.unknown:
          default:
            hint =
                "Unknown error. On Simulator, sign into iCloud in Settings. Also ensure 'Sign in with Apple' capability is enabled for the app.";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Apple sign-in failed: $code. $hint'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Apple sign-in failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isApplePlatform =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1C2A78), Color(0xFF4A1D88)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 10,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: CircleAvatar(
                            radius: 42,
                            backgroundColor: Colors.white,
                            child: Image.asset(
                              'assets/logo.png',
                              filterQuality: FilterQuality.high,
                              width: 56,
                              height: 56,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Welcome back',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _signIn,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                              : const Text('Sign In'),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: _signInWithGoogle,
                          icon: const Icon(
                            Icons.g_mobiledata,
                            color: Colors.red,
                            size: 28,
                          ),
                          label: const Text('Continue with Google'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (isApplePlatform && _isAppleAvailable)
                          SignInWithAppleButton(
                            onPressed: _signInWithAppleNative,
                            style: SignInWithAppleButtonStyle.black,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(8),
                            ),
                          ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SignUpScreen(),
                              ),
                            );
                          },
                          child: const Text("Don't have an account? Sign up"),
                        ),
                        const Divider(height: 24),
                        GestureDetector(
                          onTap: () {
                            // noop to allow tap-through on links below
                          },
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                'By continuing, you agree to our ',
                                style: TextStyle(fontSize: 12),
                              ),
                              InkWell(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const TermsAndServicesPage(),
                                  ),
                                ),
                                child: const Text(
                                  'Terms & Services',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                              const Text(
                                ' and ',
                                style: TextStyle(fontSize: 12),
                              ),
                              InkWell(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const PrivacyPolicyPage(),
                                  ),
                                ),
                                child: const Text(
                                  'Privacy Policy',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                              const Text('.', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
