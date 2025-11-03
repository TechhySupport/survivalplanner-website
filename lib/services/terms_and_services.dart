import 'package:flutter/material.dart';

class TermsAndServicesPage extends StatelessWidget {
  const TermsAndServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Services'),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _HeaderCard(),
            const SizedBox(height: 16),

            // 1. Introduction
            const _SectionCard(
              icon: Icons.policy,
              title: '1. Introduction',
              children: [
                Text(
                  'Welcome to Survival Planner (the “App”). This App is a fan-made utility designed to help players plan and calculate strategies for the game Whiteout Survival. We are not affiliated with, endorsed by, or sponsored by Century Games or any of its partners. All trademarks and game assets remain the property of their respective owners. Our App does not use copyrighted graphics, music, or in-game assets from Whiteout Survival.',
                ),
                SizedBox(height: 12),
                Text(
                  'By logging in to or using the App, you confirm that you have read, understood, and agreed to these Terms of Service and Privacy Policy. If you do not agree, you must not use the App.',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 2. Privacy & Data Use
            const _SectionCard(
              icon: Icons.privacy_tip,
              title: '2. Privacy & Data Use',
              children: [
                _Bullet('We do not sell or share your personal information.'),
                _Bullet(
                    'We may collect limited crash logs and analytics data to improve performance.'),
                _Bullet(
                    'If you create an account or use cloud sync (via Supabase), your email and saved data are securely stored and only used to provide App functionality.'),
                _Bullet(
                    'Advertising partners (such as Google AdMob) may collect anonymized usage data to display relevant ads.'),
              ],
            ),
            const SizedBox(height: 12),

            // 3. Location Data
            const _SectionCard(
              icon: Icons.location_off,
              title: '3. Location Data',
              children: [
                _Bullet(
                    'The App does not track your GPS or physical location.'),
                _Bullet(
                    'Timezone conversions (e.g., UTC to local time) are based only on the system time settings of your device.'),
              ],
            ),
            const SizedBox(height: 12),

            // 4. Fan-Based Content
            const _SectionCard(
              icon: Icons.sports_esports,
              title: '4. Fan-Based Content',
              children: [
                _Bullet('This App is created by fans, for fans.'),
                _Bullet(
                    'It is intended for educational and entertainment purposes only.'),
                _Bullet(
                    'All original game content, characters, and assets belong to Century Games.'),
                _Bullet(
                    'Our App provides independent tools and calculators to assist players and does not copy or distribute official game assets.'),
              ],
            ),
            const SizedBox(height: 12),

            // 5. Limitations of Liability
            const _SectionCard(
              icon: Icons.warning_amber_rounded,
              title: '5. Limitations of Liability',
              children: [
                _Bullet(
                    'The App is provided “as-is” without warranties of any kind.'),
                _Bullet(
                    'We are not responsible for any loss, in-game issues, or damages resulting from reliance on the App.'),
              ],
            ),
            const SizedBox(height: 12),

            // 6. Changes to These Terms
            const _SectionCard(
              icon: Icons.update,
              title: '6. Changes to These Terms',
              children: [
                Text(
                  'We may update these Terms and this Privacy Policy from time to time. Updates will be posted within the App, and continued use means you accept the revised terms.',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 7. Contact
            const _SectionCard(
              icon: Icons.apartment,
              title: '7. Contact',
              children: [
                Text('This App is developed and published by MANH STUDIO.'),
              ],
            ),

            const SizedBox(height: 24),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Terms of Service & Privacy Policy',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6),
                _UpdatedChip(),
              ],
            ),
          ),
        ],
      ),
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
