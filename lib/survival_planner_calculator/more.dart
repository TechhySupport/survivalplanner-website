import 'package:flutter/material.dart';
import 'event_page.dart';
import 'settings_page.dart';
import '../services/analytics_service.dart';
import 'bottom_nav_bar.dart';

// Local copy of the GradientTileButton to mirror Hero page styling
class GradientTileButton extends StatefulWidget {
  final String title;
  final VoidCallback? onTap;
  final IconData? leadingIcon;
  final List<Color>? gradient;
  final double borderRadius;
  final double height;
  final bool enabled;

  const GradientTileButton({
    super.key,
    required this.title,
    this.onTap,
    this.leadingIcon,
    this.gradient,
    this.borderRadius = 22,
    this.height = 120,
    this.enabled = true,
  });

  @override
  State<GradientTileButton> createState() => _GradientTileButtonState();
}

class _GradientTileButtonState extends State<GradientTileButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final baseColors = widget.gradient ??
        const [Color(0xFF5AA9FF), Color(0xFF6C7CFF), Color(0xFF8A6CFF)];
    final disabledColors = [
      Colors.grey.shade400,
      Colors.grey.shade500,
      Colors.grey.shade600,
    ];
    final colors = widget.enabled ? baseColors : disabledColors;

    return AnimatedScale(
      duration: const Duration(milliseconds: 90),
      scale: widget.enabled && _pressed ? 0.98 : 1.0,
      child: GestureDetector(
        onTapDown: widget.enabled
            ? (_) => setState(() => _pressed = true)
            : null,
        onTapCancel: widget.enabled
            ? () => setState(() => _pressed = false)
            : null,
        onTapUp:
            widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTap: widget.enabled ? widget.onTap : null,
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: widget.enabled ? 24 : 6,
                offset: const Offset(0, 12),
                color: const Color(0x40000000).withOpacity(
                  widget.enabled ? 1.0 : 0.3,
                ),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.white.withOpacity(widget.enabled ? 0.22 : 0.10),
                        Colors.white.withOpacity(widget.enabled ? 0.06 : 0.04),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.leadingIcon != null) ...[
                        Icon(widget.leadingIcon, color: Colors.white, size: 26),
                        const SizedBox(width: 10),
                      ],
                      Flexible(
                        child: Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                            height: 1.15,
                            shadows: [
                              Shadow(
                                  offset: Offset(0, 1),
                                  blurRadius: 2,
                                  color: Color(0x33000000)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    border: Border.all(
                        color: Colors.white
                            .withOpacity(widget.enabled ? 0.18 : 0.12),
                        width: 1),
                  ),
                ),
              ),
              if (!widget.enabled)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Coming soon',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  @override
  void initState() {
    super.initState();
    AnalyticsService.logPage('MorePage');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            GradientTileButton(
              title: 'Events',
              leadingIcon: Icons.event,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EventPage()),
                );
              },
            ),
            GradientTileButton(
              title: 'Pets',
              leadingIcon: Icons.pets,
              enabled: false,
              onTap: null,
            ),
            GradientTileButton(
              title: 'Experts',
              leadingIcon: Icons.school,
              enabled: false,
              onTap: null,
            ),
            GradientTileButton(
              title: 'Settings',
              leadingIcon: Icons.settings,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(),
    );
  }
}
