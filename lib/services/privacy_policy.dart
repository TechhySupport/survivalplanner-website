import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderCard(),
            SizedBox(height: 16),
            _SectionCard(
              icon: Icons.info_outline,
              title: 'Privacy Policy',
              children: [
                Text(
                  'MANH STUDIO (“we,” “our,” or “us”) respects your privacy. This Privacy Policy explains how the Survival Planner app (“the App”) collects, uses, and protects your information.',
                ),
              ],
            ),
            SizedBox(height: 12),
            _SectionCard(
              icon: Icons.account_circle_outlined,
              title: 'Information We Collect',
              children: [
                _Bullet(
                    'Account Data: If you sign in with Supabase, we store your email and any data you choose to sync (e.g., calculator settings, preferences).'),
                _Bullet(
                    'Crash Reports & Analytics: We may collect anonymous logs to improve performance and fix issues.'),
                _Bullet(
                    'Advertising Data: Google AdMob may collect anonymized data (such as device identifiers) to deliver relevant ads.'),
                SizedBox(height: 8),
                Text('We do not collect or store:'),
                _Bullet('GPS or physical location'),
                _Bullet('Sensitive personal information'),
              ],
            ),
            SizedBox(height: 12),
            _SectionCard(
              icon: Icons.tune,
              title: 'How We Use Information',
              children: [
                _Bullet('To provide cloud sync features for your account.'),
                _Bullet(
                    'To improve the App through crash reports and analytics.'),
                _Bullet(
                    'To show relevant ads through trusted ad partners (e.g., Google AdMob).'),
                SizedBox(height: 8),
                Text('We do not sell your personal data to third parties.'),
              ],
            ),
            SizedBox(height: 12),
            _SectionCard(
              icon: Icons.handshake,
              title: 'Third-Party Services',
              children: [
                Text(
                    'The App uses third-party services that may collect information:'),
                _Bullet('Supabase (account login & cloud storage)'),
                _Bullet('Google AdMob (advertising)'),
                SizedBox(height: 8),
                Text('We encourage you to review their privacy policies.'),
              ],
            ),
            SizedBox(height: 12),
            _SectionCard(
              icon: Icons.security,
              title: 'Data Security',
              children: [
                Text(
                    'We use industry-standard methods to protect your data. However, no method of transmission or storage is 100% secure.'),
              ],
            ),
            SizedBox(height: 12),
            _SectionCard(
              icon: Icons.child_care_outlined,
              title: 'Children’s Privacy',
              children: [
                Text(
                    'The App is not directed toward children under 13. We do not knowingly collect data from children.'),
              ],
            ),
            SizedBox(height: 12),
            _SectionCard(
              icon: Icons.update,
              title: 'Changes to This Policy',
              children: [
                Text(
                    'We may update this Privacy Policy from time to time. Updates will be posted within the App and/or on our official page.'),
              ],
            ),
            SizedBox(height: 12),
            _SectionCard(
              icon: Icons.apartment,
              title: 'Contact',
              children: [
                Text('This App is developed and published by MANH STUDIO.'),
              ],
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: _HeaderIconWithTitle(),
    );
  }
}

class _HeaderIconWithTitle extends StatelessWidget {
  const _HeaderIconWithTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.privacy_tip, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: _HeaderTexts(),
        ),
      ],
    );
  }
}

class _HeaderTexts extends StatelessWidget {
  const _HeaderTexts();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Privacy Policy',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 6),
        _UpdatedChip(),
      ],
    );
  }
}

class _UpdatedChip extends StatelessWidget {
  const _UpdatedChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.schedule, color: Colors.white, size: 16),
          SizedBox(width: 6),
          Text(
            'Last updated: September 2025',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.circle, size: 6, color: Colors.black54),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
