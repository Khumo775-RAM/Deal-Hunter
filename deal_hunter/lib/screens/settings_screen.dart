import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/deals_provider.dart';
import '../providers/theme_provider.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';

// ── Notification toggle ───────────────────────────────────────────────────────
class _NotificationToggle extends StatelessWidget {
  const _NotificationToggle();

  @override
  Widget build(BuildContext context) {
    final auth    = context.watch<AuthProvider>();
    final c       = context.colors;
    if (auth.user == null) return const SizedBox.shrink();

    final enabled = auth.user!.emailNotifications;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: c.accentSubtle,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.notifications_outlined,
                color: c.accent, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Email Deal Alerts',
                    style: TextStyle(
                        color: c.textPrimary, fontWeight: FontWeight.w600)),
                Text(
                  enabled
                      ? 'Notifying ${auth.user!.email}'
                      : 'Get emailed when tracked games go on sale',
                  style: TextStyle(color: c.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            activeColor: c.accent,
            onChanged: (val) async {
              final ok = await auth.toggleNotifications(val);
              if (!context.mounted) return;
              if (!ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text(auth.error ?? 'Could not update notification setting.'),
                    backgroundColor: Colors.red.shade700,
                  ),
                );
                auth.clearError();
              }
            },
          ),
        ],
      ),
    );
  }
}

// ── Theme picker ──────────────────────────────────────────────────────────────
class _ThemePicker extends StatelessWidget {
  const _ThemePicker();

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final c = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: c.accentSubtle,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.palette_outlined, color: c.accent, size: 20),
              ),
              const SizedBox(width: 14),
              Text('App Theme',
                  style: TextStyle(
                      color: c.textPrimary, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ThemeOption(
                  label: 'Purple',
                  background: const Color(0xFF0F0F1A),
                  surface: const Color(0xFF1A1A2E),
                  accent: const Color(0xFF6C63FF),
                  isSelected: !themeProvider.isOrange,
                  onTap: () => themeProvider.setOrange(false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ThemeOption(
                  label: 'Ember',
                  background: const Color(0xFF000000),
                  surface: const Color(0xFF1F1F1F),
                  accent: const Color(0xFFFFA252),
                  isSelected: themeProvider.isOrange,
                  onTap: () => themeProvider.setOrange(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.background,
    required this.surface,
    required this.accent,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final Color background;
  final Color surface;
  final Color accent;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accent : c.textDisabled,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mini colour swatches
            Row(
              children: [
                _Dot(color: background, border: c.textDisabled),
                const SizedBox(width: 4),
                _Dot(color: surface),
                const SizedBox(width: 4),
                _Dot(color: accent),
              ],
            ),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    color: isSelected
                        ? accent
                        : (background.computeLuminance() > 0.4
                            ? Colors.black54
                            : Colors.white54),
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: accent, size: 14),
                    const SizedBox(width: 4),
                    Text('Active',
                        style: TextStyle(color: accent, fontSize: 11)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, this.border});
  final Color color;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
            color: border ?? color.withValues(alpha: 0.6), width: 1.5),
      ),
    );
  }
}

// ── Settings screen ───────────────────────────────────────────────────────────
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const List<Map<String, String>> _currencies = [
    {'code': 'USD', 'name': 'US Dollar',            'country': 'US'},
    {'code': 'EUR', 'name': 'Euro',                  'country': 'EU'},
    {'code': 'GBP', 'name': 'British Pound',         'country': 'GB'},
    {'code': 'ZAR', 'name': 'South African Rand',    'country': 'ZA'},
    {'code': 'AUD', 'name': 'Australian Dollar',     'country': 'AU'},
    {'code': 'CAD', 'name': 'Canadian Dollar',       'country': 'CA'},
    {'code': 'JPY', 'name': 'Japanese Yen',          'country': 'JP'},
    {'code': 'CHF', 'name': 'Swiss Franc',           'country': 'CH'},
    {'code': 'CNY', 'name': 'Chinese Yuan',          'country': 'CN'},
    {'code': 'INR', 'name': 'Indian Rupee',          'country': 'IN'},
    {'code': 'BRL', 'name': 'Brazilian Real',        'country': 'BR'},
    {'code': 'MXN', 'name': 'Mexican Peso',          'country': 'MX'},
    {'code': 'NZD', 'name': 'New Zealand Dollar',    'country': 'NZ'},
    {'code': 'SGD', 'name': 'Singapore Dollar',      'country': 'SG'},
    {'code': 'KRW', 'name': 'South Korean Won',      'country': 'KR'},
    {'code': 'SEK', 'name': 'Swedish Krona',         'country': 'SE'},
    {'code': 'NOK', 'name': 'Norwegian Krone',       'country': 'NO'},
    {'code': 'DKK', 'name': 'Danish Krone',          'country': 'DK'},
    {'code': 'PLN', 'name': 'Polish Złoty',          'country': 'PL'},
    {'code': 'TRY', 'name': 'Turkish Lira',          'country': 'TR'},
  ];

  @override
  Widget build(BuildContext context) {
    final auth     = context.watch<AuthProvider>();
    final deals    = context.watch<DealsProvider>();
    final currency = StorageService.getCurrency();
    final c        = context.colors;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        elevation: 0,
        title: Text('Settings',
            style: TextStyle(
                color: c.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 22)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (auth.user != null) ...[
            _SectionHeader('Account'),
            _InfoTile(
              icon: Icons.person_outline,
              title: auth.user!.username,
              subtitle: auth.user!.email,
            ),
            const SizedBox(height: 20),
          ],
          _SectionHeader('Appearance'),
          const _ThemePicker(),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.currency_exchange,
            title: 'Currency',
            subtitle: currency,
            onTap: () => _showCurrencyPicker(context, deals),
          ),
          const SizedBox(height: 20),
          _SectionHeader('Notifications'),
          const _NotificationToggle(),
          const SizedBox(height: 20),
          _SectionHeader('Account'),
          _SettingsTile(
            icon: Icons.logout,
            title: 'Sign Out',
            subtitle: 'You will be redirected to login',
            iconColor: Colors.redAccent,
            titleColor: Colors.redAccent,
            onTap: () => _confirmLogout(context, auth),
          ),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.delete_forever_outlined,
            title: 'Delete Account',
            subtitle: 'Permanently removes your account and all data',
            iconColor: Colors.red.shade800,
            titleColor: Colors.red.shade800,
            onTap: () => _confirmDeleteAccount(context, auth),
          ),
          const SizedBox(height: 32),
          Center(
            child: Text('DealHunter v1.0.0',
                style: TextStyle(color: c.textFaint, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context, DealsProvider deals) {
    final c = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        String query = '';
        final selected = StorageService.getCurrency();
        return StatefulBuilder(
          builder: (ctx, setState) {
            final c2 = ctx.colors;
            final filtered = _currencies
                .where((cur) =>
                    cur['code']!.toLowerCase().contains(query.toLowerCase()) ||
                    cur['name']!.toLowerCase().contains(query.toLowerCase()))
                .toList();
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.6,
              maxChildSize: 0.9,
              builder: (_, scrollCtrl) => Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: c2.textDisabled,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text('Select Currency',
                        style: TextStyle(
                            color: c2.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: TextField(
                      autofocus: false,
                      style: TextStyle(color: c2.textPrimary),
                      onChanged: (v) => setState(() => query = v),
                      decoration: InputDecoration(
                        hintText: 'Search currencies...',
                        hintStyle: TextStyle(color: c2.textMuted),
                        prefixIcon: Icon(Icons.search, color: c2.textMuted),
                        filled: true,
                        fillColor: c2.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: c2.accent, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollCtrl,
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final cur       = filtered[i];
                        final isSelected = cur['code'] == selected;
                        return ListTile(
                          leading: _CountryBadge(country: cur['country']!),
                          title: Text('${cur['code']} — ${cur['name']}',
                              style: TextStyle(
                                  color: isSelected
                                      ? c2.accent
                                      : c2.textPrimary,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal)),
                          trailing: isSelected
                              ? Icon(Icons.check_circle, color: c2.accent)
                              : null,
                          onTap: () {
                            deals.updateCurrency(cur['code']!);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmLogout(BuildContext context, AuthProvider auth) {
    final c = context.colors;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.surface,
        title: Text('Sign Out', style: TextStyle(color: c.textPrimary)),
        content: Text('Are you sure you want to sign out?',
            style: TextStyle(color: c.textHigh)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(color: c.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await auth.logout();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent),
            child: const Text('Sign Out',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, AuthProvider auth) {
    final c           = context.colors;
    final confirmCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: c.surface,
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Colors.red.shade400, size: 22),
              const SizedBox(width: 8),
              Text('Delete Account',
                  style: TextStyle(color: c.textPrimary)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This will permanently delete your account, tracked games, '
                'and all associated data. This cannot be undone.',
                style: TextStyle(color: c.textHigh, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Text('Type DELETE to confirm:',
                  style: TextStyle(color: c.textSecondary, fontSize: 12)),
              const SizedBox(height: 8),
              TextField(
                controller: confirmCtrl,
                style: TextStyle(color: c.textPrimary),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'DELETE',
                  hintStyle: TextStyle(color: c.textFaint),
                  filled: true,
                  fillColor: c.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: Colors.red.shade700, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                confirmCtrl.dispose();
                Navigator.pop(ctx);
              },
              child: Text('Cancel',
                  style: TextStyle(color: c.textSecondary)),
            ),
            ElevatedButton(
              onPressed: confirmCtrl.text == 'DELETE'
                  ? () async {
                      Navigator.pop(ctx);
                      final ok = await auth.deleteAccount();
                      if (!context.mounted) return;
                      if (ok) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                          (_) => false,
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                auth.error ?? 'Could not delete account.'),
                            backgroundColor: Colors.red.shade700,
                          ),
                        );
                        auth.clearError();
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade800,
                  disabledBackgroundColor:
                      Colors.red.shade800.withValues(alpha: 0.3)),
              child: const Text('Delete Account',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title.toUpperCase(),
          style: TextStyle(
              color: context.colors.accent,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5)),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile(
      {required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: c.accentSubtle,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: c.accent, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      color: c.textPrimary, fontWeight: FontWeight.w600)),
              Text(subtitle,
                  style: TextStyle(color: c.textSecondary, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

/// A small styled badge showing the 2-letter country/region code.
class _CountryBadge extends StatelessWidget {
  const _CountryBadge({required this.country});
  final String country;

  static const _colors = {
    'US': Color(0xFF3B82F6),
    'EU': Color(0xFF6366F1),
    'GB': Color(0xFFEF4444),
    'ZA': Color(0xFF22C55E),
    'AU': Color(0xFF0EA5E9),
    'CA': Color(0xFFEF4444),
    'JP': Color(0xFFF43F5E),
    'CH': Color(0xFFEF4444),
    'CN': Color(0xFFEF4444),
    'IN': Color(0xFFF97316),
    'BR': Color(0xFF22C55E),
    'MX': Color(0xFF22C55E),
    'NZ': Color(0xFF3B82F6),
    'SG': Color(0xFFEF4444),
    'KR': Color(0xFF3B82F6),
    'SE': Color(0xFF3B82F6),
    'NO': Color(0xFFEF4444),
    'DK': Color(0xFFEF4444),
    'PL': Color(0xFFEF4444),
    'TR': Color(0xFFEF4444),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[country] ?? context.colors.accent;
    return Container(
      width: 40,
      height: 28,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      alignment: Alignment.center,
      child: Text(
        country,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
    this.titleColor,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final c          = context.colors;
    final resolvedIcon  = iconColor ?? c.accent;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: resolvedIcon.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: resolvedIcon, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: titleColor ?? c.textPrimary,
                          fontWeight: FontWeight.w600)),
                  Text(subtitle,
                      style: TextStyle(
                          color: c.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: c.textDisabled),
          ],
        ),
      ),
    );
  }
}
