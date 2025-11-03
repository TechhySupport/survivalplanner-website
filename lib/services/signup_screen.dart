import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'analytics_service.dart';

final supabase = Supabase.instance.client;

// Use the same Google Web Client ID as login to ensure ID tokens are accepted by Supabase.
const String kGoogleWebClientId =
    '258192286365-4qi5u7h604nn1paug7c58r364o5dqqb8.apps.googleusercontent.com';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isAppleAvailable = false;
  StreamSubscription<AuthState>? _sub;
  bool _didNavigateBackOnAuth = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logPage('SignUpScreen');
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((e) {
      if (!mounted) return;
      if (e.session != null && !_didNavigateBackOnAuth) {
        _didNavigateBackOnAuth = true;
        // Return to caller with success so the flow can continue (e.g., to Hive Map)
        Future.microtask(() {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop(true);
          }
        });
      }
    });

    // Check if Sign in with Apple is available for this device/simulator
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

  Future<void> _signUpWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password.')),
      );
      return;
    }
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters.'),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final res = await supabase.auth.signUp(
        email: email,
        password: password,
        // Optionally provide redirect for email confirmation if enabled server-side
        // emailRedirectTo: Platform.isIOS
        //     ? 'io.supabase.flutter://login-callback/'
        //     : 'com.maikl.survivalplanner://login-callback/',
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res.session != null
                ? 'Sign up successful!'
                : 'Check your email to confirm your account.',
          ),
          backgroundColor: res.session != null ? Colors.green : Colors.orange,
        ),
      );
      // Only navigate via the auth state listener when a session exists.
      // For email sign-up without session (confirmation flow), stay on screen.
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUpWithGoogle() async {
    try {
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        // On web, explicitly return to site root to avoid 404s on static hosting
        // On native, use the deep link callback.
        redirectTo: kIsWeb
            ? '${Uri.base.origin}/'
            : 'io.supabase.flutter://login-callback/',
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google sign-up auth error: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google sign-up failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Apple sign-in for SignUp flow (local success like Login screen)
  Future<void> _signUpWithApple() async {
    try {
      final available = await SignInWithApple.isAvailable();
      if (!available) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Sign in with Apple isn't available. Ensure you're on iOS 13+ and signed into iCloud, and the app has the 'Sign in with Apple' capability.",
            ),
            backgroundColor: Colors.red,
          ),
        );
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
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signed up with Apple'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('No identity token received from Apple');
      }
    } on SignInWithAppleAuthorizationException catch (e) {
      if (!mounted) return;
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
          content: Text('Apple sign-up failed: $code. $hint'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Apple sign-up failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                          'Create your account',
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
                          onPressed: _isLoading ? null : _signUpWithEmail,
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
                              : const Text('Create Account'),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: _signUpWithGoogle,
                          icon: const Icon(Icons.login, color: Colors.red),
                          label: const Text('Sign up with Google'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (!kIsWeb &&
                            (defaultTargetPlatform == TargetPlatform.iOS ||
                                defaultTargetPlatform ==
                                    TargetPlatform.macOS) &&
                            _isAppleAvailable)
                          SignInWithAppleButton(
                            onPressed: _signUpWithApple,
                            style: SignInWithAppleButtonStyle.black,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(8),
                            ),
                          ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Already have an account? Sign in'),
                        ),
                        const Divider(height: 24),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: const [
                            Text(
                              'By continuing, you agree to our ',
                              style: TextStyle(fontSize: 12),
                            ),
                            // Links provided on Login screen; keep text here
                            Text(
                              'Terms & Services',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                            Text(' and ', style: TextStyle(fontSize: 12)),
                            Text(
                              'Privacy Policy',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                            Text('.', style: TextStyle(fontSize: 12)),
                          ],
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
