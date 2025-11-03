import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'loginscreen.dart';
import 'analytics_service.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  final _supabase = Supabase.instance.client;
  bool _deleting = false;
  bool _savingNames = false;

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    AnalyticsService.logPage('AccountSettingsPage');
    final user = _supabase.auth.currentUser;
    final meta = user?.userMetadata ?? {};
    _firstNameCtrl.text = (meta['first_name'] ?? '').toString();
    _lastNameCtrl.text = (meta['last_name'] ?? '').toString();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    super.dispose();
  }

  String _providerFor(User user) {
    try {
      final identities = user.identities;
      if (identities != null && identities.isNotEmpty) {
        // prefer explicit providers
        final provs = identities.map((i) => i.provider).toSet();
        if (provs.contains('google')) return 'google';
        if (provs.contains('apple')) return 'apple';
        if (provs.contains('email')) return 'email';
        return identities.first.provider;
      }
    } catch (_) {}
    return 'email';
  }

  String _providerLabel(String provider) {
    switch (provider) {
      case 'google':
        return 'Google';
      case 'apple':
        return 'Apple';
      case 'email':
      default:
        return 'Email';
    }
  }

  Future<void> _saveNames() async {
    final first = _firstNameCtrl.text.trim();
    final last = _lastNameCtrl.text.trim();
    if (first.isEmpty && last.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a first or last name.')),
      );
      return;
    }
    setState(() => _savingNames = true);
    try {
      await _supabase.auth.updateUser(
        UserAttributes(data: {
          'first_name': first,
          'last_name': last,
        }),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Names updated.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update names: $e')),
      );
    } finally {
      if (mounted) setState(() => _savingNames = false);
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
            'This will permanently delete your account. This cannot be undone. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _deleteAccount();
    }
  }

  Future<void> _deleteAccount() async {
    final session = _supabase.auth.currentSession;
    final user = session?.user;
    if (user == null) return;
    setState(() => _deleting = true);
    String? err;
    try {
      // Attempt to call an Edge Function if you have one set up server-side
      // that deletes the current user using the Service Role key.
      // Update the function name if different.
      final res = await _supabase.functions
          .invoke('delete-account', body: {'userId': user.id});
      if (res.status == 200) {
        err = null;
      } else if (res.status == 404) {
        err =
            'Delete service unavailable (404). The delete-account function is not deployed.';
      } else if (res.status == 401 || res.status == 403) {
        err = 'Not authorized to delete account (${res.status}).';
      } else {
        err = 'Server refused deletion (${res.status}).';
      }
    } catch (e) {
      err = 'Delete function unavailable: $e';
    }

    if (!mounted) return;
    setState(() => _deleting = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not delete account. $err',
          ),
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    // Sign out locally after deletion. If the user was deleted, server may return 403.
    try {
      await _supabase.auth.signOut();
    } on AuthException catch (e) {
      // Ignore 403 (user no longer exists) and proceed to clear UI/navigation.
      final msg = e.message.toLowerCase();
      if (!(msg.contains('does not exist') || e.statusCode == 403)) {
        // For other auth errors, show a soft warning but continue.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sign-out warning: ${e.message}')),
          );
        }
      }
    } catch (_) {
      // Swallow any non-auth errors
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Account deleted.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final session = _supabase.auth.currentSession;
    final user = session?.user;
    return Scaffold(
      appBar: AppBar(title: const Text('Account Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: user == null
            ? _LoggedOutView()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Builder(builder: (_) {
                    final provider = _providerFor(user);
                    final providerText = _providerLabel(provider);
                    return Column(
                      children: [
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.verified_user_outlined),
                            title: Text('Signed in with $providerText'),
                            subtitle: Text(
                              (user.email?.isNotEmpty ?? false)
                                  ? 'Email: ${user.email}'
                                  : 'Email: Unknown',
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (provider == 'email')
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Profile Name',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _firstNameCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'First name',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _lastNameCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Last name',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton(
                                      onPressed:
                                          _savingNames ? null : _saveNames,
                                      child: _savingNames
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text('Save'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    );
                  }),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.delete_forever),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 12),
                      ),
                      onPressed: _deleting ? null : _confirmDelete,
                      label: _deleting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Delete Account'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _LoggedOutView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('You are not logged in.'),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ).then((_) => Navigator.pop(context));
            },
            icon: const Icon(Icons.login),
            label: const Text('Log in'),
          )
        ],
      ),
    );
  }
}
