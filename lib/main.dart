import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Firebase and Google Mobile Ads are mobile-only; remove for web build
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'generated/app_localizations.dart';
import 'settings_page.dart';
import 'bottom_nav_bar.dart';
import 'services/loginscreen.dart';
import 'chief_gear_calculator.dart';
import 'chief_charm_calculator.dart';
import 'SVS_calculator.dart';
import 'events/officer_project.dart';
import 'events/armament_competition.dart';
import 'troops_page.dart';
import 'splash_screen.dart';
import 'services/purchase_service.dart';
import 'chief_page.dart';
import 'hero_page.dart';
import 'building_page.dart';
import 'event_page.dart';
import 'services/analytics_service.dart';
// route logging removed
import 'web/web_landing.dart';
import 'hivemap/hivemap_screen.dart';
import 'hivemap/hivemap_editor.dart';

// Clean single implementation of Survival Planner main entry.
const supabaseUrl = 'https://wdjophtkpqtpdkbcwxsq.supabase.co';
const supabaseKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indkam9waHRrcHF0cGRrYmN3eHNxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ2MzAxMTYsImV4cCI6MjA3MDIwNjExNn0.FG3LnqOIJ3fwp5qMAEmYRbF8mwF1ujBiGjEj7E8HnwI';
late final SupabaseClient supabase;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
bool _handledAuthRedirect = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase removed for web-safe build
  await PurchaseService.init();
  // Load saved locale, default to English
  final _prefs = await SharedPreferences.getInstance();
  final _code = _prefs.getString('app_locale') ?? 'en';
  appLocale.value = Locale(_code);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  // Ads initialization removed for web-safe build

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  supabase = Supabase.instance.client;
  // Handle post-OAuth redirect_to param to return users to their original page
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    final session = data.session;
    if (session == null || _handledAuthRedirect) return;
    final qp = Uri.base.queryParameters;
    final back = qp['redirect_to'];
    if (back != null && back.isNotEmpty) {
      _handledAuthRedirect = true;
      try {
        final backUri = Uri.parse(back);
        final frag = backUri.fragment; // e.g. "/hivemap" or "map/slug"
        final route = frag.isNotEmpty
            ? (frag.startsWith('/') ? frag : '/$frag')
            : (backUri.path.isNotEmpty ? backUri.path : '/');
        // Navigate inside the Flutter app
        navigatorKey.currentState?.pushNamedAndRemoveUntil(route, (r) => false);
      } catch (_) {}
    }
  });
  runApp(const MyApp());
}

Stream<Session?> sessionStreamWithInitial() async* {
  yield supabase.auth.currentSession;
  yield* supabase.auth.onAuthStateChange.map((e) => e.session);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale?>(
      valueListenable: appLocale,
      builder: (_, locale, __) => MaterialApp(
        title: 'Survival Planner',
        navigatorKey: navigatorKey,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale ?? const Locale('en'),
        onGenerateRoute: (settings) {
          final name = settings.name;
          if (name != null) {
            final uri = Uri.parse(name);
            // Direct editor route: /hivemap -> open HiveMapEditor immediately
            if (uri.pathSegments.length == 1 &&
                uri.pathSegments[0] == 'hivemap') {
              return MaterialPageRoute(
                builder: (_) => const HiveMapEditor(),
                settings: settings,
              );
            }
            if (uri.pathSegments.length == 2 && uri.pathSegments[0] == 'map') {
              final slug = uri.pathSegments[1];
              final canEdit = uri.queryParameters['edit'] == '1';
              return MaterialPageRoute(
                builder: (_) => HiveMapScreen(slug: slug, wantEdit: canEdit),
                settings: settings,
              );
            }
          }
          return null; // default routing
        },
        // no debug overlay
        builder: (context, child) {
          if (child == null) return const SizedBox.shrink();
          final size = MediaQuery.of(context).size;
          final isWideWeb = kIsWeb && size.width > 900;

          Widget content = child;
          if (isWideWeb) {
            content = Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: child,
                ),
              ),
            );
          }

          // No global click listener; ads are scheduled on a timer
          return content;
        },
        home: kIsWeb ? const WebLandingPage() : const RootHost(),
      ),
    );
  }
}

// Root host shows a brief splash before switching to auth-driven UI
class RootHost extends StatefulWidget {
  const RootHost({super.key});
  @override
  State<RootHost> createState() => _RootHostState();
}

class _RootHostState extends State<RootHost> {
  late final Future<void> _splashDelay;
  @override
  void initState() {
    super.initState();
    _splashDelay = Future<void>.delayed(const Duration(milliseconds: 1000));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _splashDelay,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const SplashScreen();
        }
        // Always go to Home; login is optional via button in Home app bar
        return const HomeScreen();
      },
    );
  }
}

// LoginScreen now provided by services/loginscreen.dart

// HOME SCREEN
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// Conversion direction for UTC tool
enum _ConvDir { localToUtc, utcToLocal }

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  static const String _usedMsKey = 'usage_ms_total';
  static const String _discordShownKey = 'discord_prompt_shown';
  static const String _discordNeverKey = 'discord_prompt_never';
  static const int _oneHourMs = 60 * 60 * 1000;
  static const String _discordUrl = 'https://discord.gg/your-invite';
  static const String _reviewShownKey = 'review_prompt_shown';
  static const String _reviewNeverKey = 'review_prompt_never';
  static const int _fourHoursMs = 4 * 60 * 60 * 1000;
  static const String _androidStoreUrl =
      'https://play.google.com/store/apps/details?id=com.maikl.survivalplanner&reviewId=0';
  static const String _iosStoreUrl =
      'https://apps.apple.com/app/id6749657629?action=write-review';
  bool use24 = false;
  // UTC converter: separate inputs + result + direction
  final TextEditingController _hourController = TextEditingController();
  final TextEditingController _minuteController = TextEditingController();
  String? _resultText;
  _ConvDir _dir = _ConvDir.localToUtc;
  bool _isPm = false; // relevant only in 12h mode
  AnimationController? _bannerCtrl;
  Timer? _usageTimer;
  int _usedMs = 0;
  bool _discordShown = false;
  bool _discordNever = false;
  bool _reviewShown = false;
  bool _reviewNever = false;
  final List<String> options = [
    'Chief Gear',
    'Chief Charm',
    'SVS Calculator',
    'Officer Project',
    'Troops',
    'Armament Competition',
  ];
  final Map<String, Widget Function()> pages = {
    'Chief Gear': () => const ChiefGearCalculatorPage(),
    'Chief Charm': () => const ChiefCharmCalculatorPage(),
    'SVS Calculator': () => const SVSCalculatorPage(),
    'Officer Project': () => const OfficerProjectPage(),
    'Troops': () => const TroopsPage(),
    'Armament Competition': () => const ArmamentCompetitionPage(),
  };
  List<String> favs = List.filled(4, 'Select Shortcut');
  @override
  void initState() {
    super.initState();
    AnalyticsService.logPage('HomeScreen');
    _bannerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // No ads on web; keep potential mobile hooks disabled
    });
    // Recompute conversion when the input changes
    _hourController.addListener(_recomputeConversion);
    _minuteController.addListener(_recomputeConversion);
    // Default to 12:00
    _hourController.text = '12';
    _minuteController.text = '00';
    _isPm = false;
    // Trigger initial compute
    WidgetsBinding.instance.addPostFrameCallback((_) => _recomputeConversion());
    _loadFavs();
    _initUsageTracking();
    supabase.auth.onAuthStateChange.listen((e) {
      if (e.session != null) _syncFavsCloud();
    });
  }

  @override
  void dispose() {
    _bannerCtrl?.dispose();
    _usageTimer?.cancel();
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
  }

  Future<void> _initUsageTracking() async {
    final p = await SharedPreferences.getInstance();
    _usedMs = p.getInt(_usedMsKey) ?? 0;
    _discordShown = p.getBool(_discordShownKey) ?? false;
    _discordNever = p.getBool(_discordNeverKey) ?? false;
    _reviewShown = p.getBool(_reviewShownKey) ?? false;
    _reviewNever = p.getBool(_reviewNeverKey) ?? false;
    _usageTimer?.cancel();
    _usageTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      _usedMs += 60 * 1000;
      await p.setInt(_usedMsKey, _usedMs);
      _maybePromptDiscord(p);
      _maybePromptReview(p);
    });
    // Immediate check on startup as well
    _maybePromptDiscord(p);
    _maybePromptReview(p);
  }

  void _maybePromptDiscord(SharedPreferences p) {
    if (_discordNever) return;
    if (!_discordShown && _usedMs >= _oneHourMs) {
      _showDiscordPrompt();
      _discordShown = true;
      p.setBool(_discordShownKey, true);
    }
  }

  void _maybePromptReview(SharedPreferences p) {
    if (_reviewNever) return;
    if (_reviewShown) return;
    // Only auto-prompt on mobile platforms
    final isMobile =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    if (!isMobile) return;
    if (_usedMs >= _fourHoursMs) {
      _showReviewPrompt();
      _reviewShown = true;
      p.setBool(_reviewShownKey, true);
    }
  }

  Future<void> _showDiscordPrompt() async {
    if (!mounted) return;
    // Animated, stylish dialog via showGeneralDialog
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Join Discord',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (ctx, a1, a2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, __) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
        );
        return Opacity(
          opacity: anim.value,
          child: Transform.scale(
            scale: 0.92 + 0.08 * curved.value,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 420,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1C2A78), Color(0xFF4A1D88)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blueAccent.withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.white,
                          child: Image(
                            image: AssetImage('assets/logo.png'),
                            width: 42,
                            height: 42,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Join Our Discord',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Come join our Discord community!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white70),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              onPressed: () async {
                                final p = await SharedPreferences.getInstance();
                                _discordNever = true;
                                await p.setBool(_discordNeverKey, true);
                                await p.setBool(_discordShownKey, true);
                                if (ctx.mounted) Navigator.pop(ctx);
                              },
                              child: const Text('Never ask again'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text(
                              'Later',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 14,
                              ),
                            ),
                            icon: const Icon(Icons.forum),
                            label: const Text('Join Discord'),
                            onPressed: () async {
                              final uri = Uri.parse(_discordUrl);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                );
                              }
                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showReviewPrompt() async {
    if (!mounted) return;
    int rating = 0;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Leave a Review',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (ctx, a1, a2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, __) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
        );
        return Opacity(
          opacity: anim.value,
          child: Transform.scale(
            scale: 0.92 + 0.08 * curved.value,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 420,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1C2A78), Color(0xFF4A1D88)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: StatefulBuilder(
                    builder: (ctx, setStateSB) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Enjoying Survival Planner?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Love it so far? Why not leave us a review to show your love.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (i) {
                            final idx = i + 1;
                            final filled = rating >= idx;
                            return IconButton(
                              iconSize: 32,
                              color: Colors.white,
                              onPressed: () async {
                                setStateSB(() => rating = idx);
                                final url =
                                    (defaultTargetPlatform ==
                                        TargetPlatform.android)
                                    ? _androidStoreUrl
                                    : (defaultTargetPlatform ==
                                          TargetPlatform.iOS)
                                    ? _iosStoreUrl
                                    : '';
                                if (url.isNotEmpty) {
                                  final uri = Uri.parse(url);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(
                                      uri,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  }
                                }
                                final p = await SharedPreferences.getInstance();
                                _reviewShown = true;
                                await p.setBool(_reviewShownKey, true);
                                if (ctx.mounted) Navigator.pop(ctx);
                              },
                              icon: Icon(
                                filled ? Icons.star : Icons.star_border,
                                color: Colors.grey.shade300,
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white70),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                onPressed: () async {
                                  final p =
                                      await SharedPreferences.getInstance();
                                  _reviewNever = true;
                                  await p.setBool(_reviewNeverKey, true);
                                  await p.setBool(_reviewShownKey, true);
                                  if (ctx.mounted) Navigator.pop(ctx);
                                },
                                child: const Text('Never ask again'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text(
                                'Later',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Premium banner removed — site is fully free.

  void _open(String label) {
    final b = pages[label];
    if (b != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => b()));
    }
  }

  Future<void> _pick(int i) async {
    final r = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Select Shortcut'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: options
                .map(
                  (o) => ListTile(
                    leading: const Icon(Icons.bolt, color: Colors.blueAccent),
                    title: Text(o),
                    onTap: () => Navigator.pop(c, o),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (r != null) {
      setState(() => favs[i] = r);
      _saveFavs();
    }
  }

  // ----- UTC Converter helpers -----

  void _recomputeConversion() {
    final hStr = _hourController.text.trim();
    final mStr = _minuteController.text.trim();
    if (hStr.isEmpty && mStr.isEmpty) {
      setState(() => _resultText = null);
      return;
    }
    final h = int.tryParse(hStr);
    final m = int.tryParse(mStr);
    if (h == null || m == null) {
      setState(() => _resultText = 'Invalid time');
      return;
    }
    final validHour = use24 ? (h >= 0 && h <= 23) : (h >= 1 && h <= 12);
    final validMinute = m >= 0 && m <= 59;
    if (!validHour || !validMinute) {
      setState(() => _resultText = 'Invalid time');
      return;
    }
    final now = DateTime.now();
    int hour24;
    if (use24) {
      hour24 = h;
    } else {
      // 12h input: convert to 24h; 12 AM -> 0, 12 PM -> 12
      hour24 = (h % 12) + (_isPm ? 12 : 0);
    }
    DateTime target;
    String label;
    if (_dir == _ConvDir.localToUtc) {
      final local = DateTime(now.year, now.month, now.day, hour24, m);
      target = local.toUtc();
      label = 'UTC';
    } else {
      final utc = DateTime.utc(now.year, now.month, now.day, hour24, m);
      target = utc.toLocal();
      label = 'Local';
    }
    final fmt = use24 ? DateFormat.Hm() : DateFormat('hh:mm a');
    setState(() => _resultText = '${fmt.format(target)} ($label)');
  }

  Future<void> _loadFavs() async {
    final p = await SharedPreferences.getInstance();
    final l = <String>[];
    for (int i = 0; i < 4; i++) {
      l.add(p.getString('favorite_slot_$i') ?? 'Select Shortcut');
    }
    setState(() => favs = l);
  }

  Future<void> _saveFavs() async {
    final p = await SharedPreferences.getInstance();
    for (int i = 0; i < favs.length; i++) {
      await p.setString('favorite_slot_$i', favs[i]);
    }
  }

  Future<void> _syncFavsCloud() async {}
  @override
  Widget build(BuildContext context) {
    final isWide = kIsWeb || MediaQuery.of(context).size.width > 800;
    // Site is 100% free — no premium gating
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: _UtcBadge(use24: use24),
        ),
        bottom: isWide
            ? PreferredSize(
                preferredSize: const Size.fromHeight(42),
                child: _WebTopNav(
                  onNavigate: (label) {
                    switch (label) {
                      case 'Home':
                        if (kIsWeb) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const WebLandingPage(),
                            ),
                          );
                        } else {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HomeScreen(),
                            ),
                          );
                        }
                        break;
                      case 'Chief':
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ChiefPage()),
                        );
                        break;
                      case 'Heroes':
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const HeroPage()),
                        );
                        break;
                      case 'Building':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BuildingPage(),
                          ),
                        );
                        break;
                      case 'Event':
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const EventPage()),
                        );
                        break;
                      case 'Troops':
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TroopsPage()),
                        );
                        break;
                    }
                  },
                ),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ).then((_) => setState(() {})),
          ),
          if (supabase.auth.currentSession != null)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await supabase.auth.signOut();
                if (mounted) setState(() {});
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.login),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ).then((_) => setState(() {}));
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Image.asset(
              'assets/logo.png',
              height: 90,
              filterQuality: FilterQuality.high,
            ),
            // No ads or premium banners on the free site
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: Colors.blueAccent,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'UTC Time Converter',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Direction toggle (single button) and 24h switch
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.swap_horiz),
                              label: Text(
                                _dir == _ConvDir.localToUtc
                                    ? 'Local → UTC'
                                    : 'UTC → Local',
                                overflow: TextOverflow.ellipsis,
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  _dir = _dir == _ConvDir.localToUtc
                                      ? _ConvDir.utcToLocal
                                      : _ConvDir.localToUtc;
                                });
                                _recomputeConversion();
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: use24,
                                onChanged: (v) {
                                  setState(() => use24 = v);
                                  _recomputeConversion();
                                },
                              ),
                              const SizedBox(width: 6),
                              Text(
                                use24 ? '24h' : '12h',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _dir == _ConvDir.localToUtc
                                ? 'Enter Local Time'
                                : 'Enter UTC Time',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              SizedBox(
                                width: 56,
                                child: TextField(
                                  controller: _hourController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(2),
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: 'HH',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 10,
                                    ),
                                  ),
                                  onSubmitted: (_) => _recomputeConversion(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 56,
                                child: TextField(
                                  controller: _minuteController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(2),
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: 'MM',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 10,
                                    ),
                                  ),
                                  onSubmitted: (_) => _recomputeConversion(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (!use24)
                                Wrap(
                                  spacing: 6,
                                  children: [
                                    Theme(
                                      data: Theme.of(context).copyWith(
                                        chipTheme: Theme.of(context).chipTheme
                                            .copyWith(
                                              checkmarkColor:
                                                  Colors.transparent,
                                            ),
                                      ),
                                      child: ChoiceChip(
                                        label: const Text('AM'),
                                        selected: !_isPm,
                                        selectedColor: Colors.blueAccent
                                            .withOpacity(0.15),
                                        onSelected: (s) {
                                          setState(() => _isPm = false);
                                          _recomputeConversion();
                                        },
                                      ),
                                    ),
                                    Theme(
                                      data: Theme.of(context).copyWith(
                                        chipTheme: Theme.of(context).chipTheme
                                            .copyWith(
                                              checkmarkColor:
                                                  Colors.transparent,
                                            ),
                                      ),
                                      child: ChoiceChip(
                                        label: const Text('PM'),
                                        selected: _isPm,
                                        selectedColor: Colors.blueAccent
                                            .withOpacity(0.15),
                                        onSelected: (s) {
                                          setState(() => _isPm = true);
                                          _recomputeConversion();
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_resultText != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.blue.withOpacity(0.06),
                            border: Border.all(color: Colors.blueAccent),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.public,
                                size: 18,
                                color: Colors.blueAccent,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _resultText!,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 24,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Favorite Shortcuts',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            // All shortcuts are free
                          ],
                        ),
                        const SizedBox(height: 8),
                        GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          padding: const EdgeInsets.only(bottom: 4),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12.0,
                                crossAxisSpacing: 12.0,
                                childAspectRatio: 1.2,
                              ),
                          itemCount: favs.length,
                          itemBuilder: (context, i) {
                            final label = favs[i];
                            final locked = false;
                            final empty = label == 'Select Shortcut';
                            final isActive = !empty && !locked;
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () {
                                  if (empty) {
                                    _pick(i);
                                  } else {
                                    _open(label);
                                  }
                                },
                                onLongPress: () {
                                  if (!locked && !empty) {
                                    setState(() => favs[i] = 'Select Shortcut');
                                    _saveFavs();
                                  }
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOut,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    color: empty ? Colors.grey.shade50 : null,
                                    gradient: isActive
                                        ? const LinearGradient(
                                            colors: [
                                              Color(0xFF2196F3),
                                              Color(0xFF64B5F6),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : null,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(.06),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: empty
                                          ? Colors.blueGrey.shade200
                                          : Colors.blueAccent,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 26,
                                            height: 26,
                                            decoration: BoxDecoration(
                                              color: isActive
                                                  ? Colors.white24
                                                  : Colors.black12,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              empty ? Icons.add : Icons.bolt,
                                              size: 16,
                                              color: isActive
                                                  ? Colors.white
                                                  : Colors.blueGrey,
                                            ),
                                          ),
                                          const Spacer(),
                                          // no lock icon
                                        ],
                                      ),
                                      Center(
                                        child: Text(
                                          empty ? 'Slot ${i + 1}' : label,
                                          maxLines: 3,
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: isActive
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        // Footer moved outside Card for clean alignment
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Long-press a tile to clear',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text(
                    'Reset Favorites',
                    style: TextStyle(fontSize: 12),
                  ),
                  onPressed: () {
                    setState(() => favs = List.filled(4, 'Select Shortcut'));
                    _saveFavs();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: isWide ? null : const CustomBottomNavBar(),
    );
  }
}

// Premium sheet removed — everything is free on the web.

// Benefit row removed with premium sheet

// ADS
// AdClickManager removed for web-safe build

// UTC BADGE
class _UtcBadge extends StatelessWidget {
  final bool use24;
  const _UtcBadge({required this.use24});
  @override
  Widget build(BuildContext context) {
    final loc = Localizations.localeOf(context).toLanguageTag();
    return StreamBuilder<DateTime>(
      stream: Stream.periodic(
        const Duration(seconds: 1),
        (_) => DateTime.now().toUtc(),
      ),
      builder: (c, s) {
        final utc = s.data ?? DateTime.now().toUtc();
        final fmt = use24
            ? DateFormat.Hms(loc).format(utc)
            : DateFormat('hh:mm:ss a', loc).format(utc);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.lightBlue),
            borderRadius: BorderRadius.circular(14),
            color: Colors.white,
          ),
          child: Text(
            '${AppLocalizations.of(context)!.utcTime}: $fmt',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.lightBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
    );
  }
}

class _WebTopNav extends StatelessWidget {
  final void Function(String label) onNavigate;
  const _WebTopNav({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final labels = const [
      'Home',
      'Chief',
      'Heroes',
      'Building',
      'Event',
      'Troops',
    ];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SizedBox(
        height: 42,
        child: Row(
          children: [
            for (final l in labels) ...[
              TextButton(
                onPressed: () => onNavigate(l),
                child: Text(
                  l,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
            ],
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
