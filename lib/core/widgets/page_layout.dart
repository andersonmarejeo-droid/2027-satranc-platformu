import 'package:flutter/material.dart';

class PageLayout extends StatelessWidget {
  const PageLayout({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    required this.children,
    this.trailing,
    this.compact = false,
  });
  final String eyebrow, title;
  final String? subtitle;
  final List<Widget> children;
  final Widget? trailing;
  final bool compact;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, compact ? 6 : 12, 16, compact ? 12 : 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (Localizations.maybeLocaleOf(context)?.languageCode ==
                                      'tr'
                                  ? eyebrow
                                        .replaceAll('i', 'İ')
                                        .replaceAll('ı', 'I')
                                  : eyebrow)
                              .toUpperCase(),
                          style: TextStyle(
                            fontSize: compact ? 10 : 11,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: compact ? 2 : 4),
                        Text(
                          title,
                          style: compact
                              ? Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  )
                              : Theme.of(context).textTheme.headlineLarge,
                        ),
                      ],
                    ),
                  ),
                  ?trailing,
                ],
              ),
              if (subtitle != null) ...[
                SizedBox(height: compact ? 2 : 4),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: compact ? 12 : 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              SizedBox(height: compact ? 8 : 12),
              ...children,
            ],
          ),
        ),
      ),
    ),
  );
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(10),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final radius = BorderRadius.circular(16);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? .12 : .035),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .8)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(
                  scheme.surface,
                  dark ? scheme.primary : Colors.white,
                  dark ? .035 : .6,
                )!,
                Color.lerp(
                  scheme.surface,
                  scheme.secondary,
                  dark ? .025 : .035,
                )!,
              ],
            ),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action});
  final String title;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.tertiary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        ?action,
      ],
    ),
  );
}

class ActionCard extends StatelessWidget {
  const ActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
    this.highlighted = false,
    this.dense = false,
  });

  final IconData icon;
  final String title, subtitle;
  final VoidCallback? onPressed;
  final bool highlighted;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final prominent = highlighted && onPressed != null;
    final foreground = prominent ? scheme.onPrimary : scheme.onSurface;
    final iconBoxSize = dense ? 32.0 : 38.0;
    final iconSize = dense ? 18.0 : 22.0;
    final titleSize = dense ? 14.0 : 16.0;
    final subtitleSize = dense ? 11.5 : 13.0;
    final minHeight = dense ? 48.0 : 64.0;
    final cardPadding = dense
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 5)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 8);

    final content = Row(
      children: [
        Container(
          width: iconBoxSize,
          height: iconBoxSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(dense ? 10 : 12),
            color: prominent
                ? Colors.white.withValues(alpha: .1)
                : scheme.primary.withValues(alpha: .08),
            border: Border.all(
              color: prominent
                  ? Colors.white.withValues(alpha: .12)
                  : scheme.primary.withValues(alpha: .06),
            ),
          ),
          child: Icon(icon, size: iconSize),
        ),
        SizedBox(width: dense ? 8 : 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: subtitleSize,
                  fontWeight: FontWeight.normal,
                  height: 1.25,
                  color: prominent
                      ? foreground.withValues(alpha: .82)
                      : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Icon(Icons.chevron_right, size: dense ? 18 : 20),
      ],
    );
    final style = ButtonStyle(
      alignment: Alignment.centerLeft,
      minimumSize: WidgetStatePropertyAll(Size.fromHeight(minHeight)),
      padding: WidgetStatePropertyAll(cardPadding),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? scheme.onSurface.withValues(alpha: .38)
            : foreground,
      ),
      backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
      overlayColor: WidgetStatePropertyAll(foreground.withValues(alpha: .07)),
      side: WidgetStatePropertyAll(
        BorderSide(
          color: prominent
              ? scheme.primary.withValues(alpha: .28)
              : scheme.outlineVariant.withValues(alpha: .9),
        ),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: prominent
              ? [
                  Color.lerp(scheme.primary, scheme.onPrimary, .035)!,
                  scheme.primary,
                ]
              : [
                  Color.lerp(
                    scheme.surface,
                    scheme.primary,
                    dark ? .04 : .015,
                  )!,
                  Color.lerp(scheme.surface, scheme.secondary, .025)!,
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? .12 : .04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: highlighted
            ? FilledButton(onPressed: onPressed, style: style, child: content)
            : OutlinedButton(
                onPressed: onPressed,
                style: style,
                child: content,
              ),
      ),
    );
  }
}

void showNotice(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

class DemoLabel extends StatelessWidget {
  const DemoLabel({super.key, this.text = 'Örnek veriler'});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 11,
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
