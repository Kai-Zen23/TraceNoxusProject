import 'dart:math' as math;

class ResponsiveSpec {
  final double topSpacing;
  final double logoHeight;
  final double logoFallbackHeight;
  final double logoIconSize;
  final double brandSpacing;
  final double heroSpacing;
  final double voucherHeight;
  final double voucherFallbackFontSize;
  final double cardOuterPadding;
  final double cardMaxWidth;
  final double cardVerticalPadding;
  final double cardHorizontalPadding;
  final double cardRightRadius;
  final double cardLeftRadius;
  final double cardBottomRadius;
  final double cardBottomPadding;
  final double fieldSpacing;
  final double sectionGap;
  final double buttonMaxWidth;
  final double buttonVerticalPadding;
  final double buttonRadius;
  final double buttonFontSize;

  const ResponsiveSpec({
    required this.topSpacing,
    required this.logoHeight,
    required this.logoFallbackHeight,
    required this.logoIconSize,
    required this.brandSpacing,
    required this.heroSpacing,
    required this.voucherHeight,
    required this.voucherFallbackFontSize,
    required this.cardOuterPadding,
    required this.cardMaxWidth,
    required this.cardVerticalPadding,
    required this.cardHorizontalPadding,
    required this.cardRightRadius,
    required this.cardLeftRadius,
    required this.cardBottomRadius,
    required this.cardBottomPadding,
    required this.fieldSpacing,
    required this.sectionGap,
    required this.buttonMaxWidth,
    required this.buttonVerticalPadding,
    required this.buttonRadius,
    required this.buttonFontSize,
  });

  factory ResponsiveSpec.fromWidth(double width) {
    final isTablet = width >= 768;
    final isDesktop = width >= 1024;

    final topSpacing = _clampDouble(width * 0.18, 160, 300);
    final logoHeight = _clampDouble(width * 0.25, 170, 300);
    final logoFallbackHeight = _clampDouble(logoHeight * 0.72, 90, 150);
    final logoIconSize = _clampDouble(logoHeight * 0.22, 28, 44);
    final brandSpacing = _clampDouble(width * 0.03, 10, 20);
    final heroSpacing = _clampDouble(width * 0.08, 48, 80);
    final voucherHeight = _clampDouble(width * 0.22, 200, 200);
    final voucherFallbackFontSize = _clampDouble(voucherHeight * 0.16, 18, 26);

    final cardOuterPadding = isDesktop ? 80.0 : isTablet ? 32.0 : 0.0;
    final cardMaxWidth = isDesktop
        ? _clampDouble(width * 0.72, 560.0, 820.0)
        : isTablet
        ? _clampDouble(width * 0.88, 400.0, 640.0)
        : width;
    final cardVerticalPadding = _clampDouble(width * 0.08, 24, 40);
    final cardHorizontalPadding = isTablet ? 32.0 : 20.0;
    final cardRightRadius = _clampDouble(width * 0.22, 72, 140);
    final cardLeftRadius = 0.0;
    final cardBottomRadius = 0.0;
    final cardBottomPadding = isDesktop ? 64.0 : 32.0;
    final fieldSpacing = _clampDouble(width * 0.045, 16.0, 26.0);
    final sectionGap = _clampDouble(width * 0.035, 14.0, 24.0);

    final buttonMaxWidth = _clampDouble(width * 0.65, 220.0, isDesktop ? 420.0 : 320.0);
    final buttonVerticalPadding = _clampDouble(width * 0.035, 12.0, 18.0);
    final buttonRadius = 32.0;
    final buttonFontSize = _clampDouble(width * 0.045, 16.0, 20.0);

    return ResponsiveSpec(
      topSpacing: topSpacing,
      logoHeight: logoHeight,
      logoFallbackHeight: logoFallbackHeight,
      logoIconSize: logoIconSize,
      brandSpacing: brandSpacing,
      heroSpacing: heroSpacing,
      voucherHeight: voucherHeight,
      voucherFallbackFontSize: voucherFallbackFontSize,
      cardOuterPadding: cardOuterPadding,
      cardMaxWidth: cardMaxWidth,
      cardVerticalPadding: cardVerticalPadding,
      cardHorizontalPadding: cardHorizontalPadding,
      cardRightRadius: cardRightRadius,
      cardLeftRadius: cardLeftRadius,
      cardBottomRadius: cardBottomRadius,
      cardBottomPadding: cardBottomPadding,
      fieldSpacing: fieldSpacing,
      sectionGap: sectionGap,
      buttonMaxWidth: buttonMaxWidth,
      buttonVerticalPadding: buttonVerticalPadding,
      buttonRadius: buttonRadius,
      buttonFontSize: buttonFontSize,
    );
  }
}

double _clampDouble(double value, double min, double max) {
  return math.min(math.max(value, min), max);
}