import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../screens/messages_inbox_screen.dart';
import '../theme/app_theme.dart';

class MamaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final bool showMessages;
  final List<Widget>? actions;

  const MamaAppBar({
    super.key,
    this.title = 'MamaSalama',
    this.showBack = false,
    this.showMessages = true,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: AppSpacing.edgeMargin,
      title: Row(
        children: [
          if (showBack)
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: Icon(Icons.arrow_back, color: AppColors.primary),
              padding: EdgeInsets.zero,
            )
          else
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.secondaryContainer,
              child: Icon(Icons.pregnant_woman, color: AppColors.primary, size: 20),
            ),
          const SizedBox(width: 10),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 20,
                  color: AppColors.primary,
                ),
          ),
        ],
      ),
      actions: [
        ...?actions,
        if (showMessages && !showBack)
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const MessagesInboxScreen(useBrandAppBar: true),
              ),
            ),
            tooltip: 'Messages',
            icon: Icon(Icons.chat_bubble_outline, color: AppColors.primary),
          ),
        const SizedBox(width: 4),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64);
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionHeader({super.key, required this.title, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.secondary)),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// The "bento" style card seen throughout the Stitch mockups: white card,
/// thin outline border, 16px radius.
class BentoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;

  const BentoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: card,
    );
  }
}

class PillChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const PillChip({super.key, required this.label, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryContainer : AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.onPrimaryContainer : AppColors.secondary,
          ),
        ),
      ),
    );
  }
}

class ProgressTrack extends StatelessWidget {
  final double value; // 0..1
  final Color? trackColor;
  final Color? fillColor;
  final double height;

  const ProgressTrack({
    super.key,
    required this.value,
    this.trackColor,
    this.fillColor,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: height,
        backgroundColor: trackColor ?? AppColors.surfaceContainer,
        valueColor: AlwaysStoppedAnimation(fillColor ?? AppColors.primary),
      ),
    );
  }
}

class EmptyHint extends StatelessWidget {
  final String text;
  final IconData icon;
  const EmptyHint({super.key, required this.text, this.icon = Icons.check_circle_outline});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Center(
        child: Column(
          children: [
            Icon(icon, color: AppColors.outline, size: 32),
            const SizedBox(height: 8),
            Text(text, style: TextStyle(color: AppColors.secondary)),
          ],
        ),
      ),
    );
  }
}

class ConnectivityBanner extends StatefulWidget {
  const ConnectivityBanner({super.key});

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    Connectivity().checkConnectivity().then(_onResult);
    Connectivity().onConnectivityChanged.listen(_onResult);
  }

  void _onResult(List<ConnectivityResult> results) {
    final offline = results.every((r) => r == ConnectivityResult.none);
    if (mounted && offline != _offline) setState(() => _offline = offline);
  }

  @override
  Widget build(BuildContext context) {
    if (!_offline) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      color: AppColors.error,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: AppSpacing.edgeMargin),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, color: Colors.white, size: 14),
          SizedBox(width: 6),
          Text("You're offline — changes will sync when you're back online",
              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
