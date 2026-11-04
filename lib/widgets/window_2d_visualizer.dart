import 'dart:math' as math;
import 'package:flutter/material.dart';

/// شاشة المعاينة الحية التفاعلية للشباك / الباب (مطابقة للمشروع المماثل وتدعم جميع الثوابت والاتجاهات)
class Window2DVisualizer extends StatelessWidget {
  final double widthCm;
  final double heightCm;
  final String unitType; // شباك | باب | مطبخ
  final String openType; // جرار | مفصلي | قلاب | ثابت
  final int sashCount; // 1, 2, 3, 4
  final String barType; // ببار | بدون بار | بار مقلوب | تجميع
  final String openDirection; // يمين للداخل | شمال للداخل | يمين للخارج | شمال للخارج | قلاب لأعلى
  final String sectorColor; // بيج | أبيض | أسود | رمادي | خشابي | فضي | شامبين

  // الثوابت وأماكنها ومقاساتها وتقسيماتها
  final bool hasTopFixed;
  final double topFixedHeightCm;
  final int topFixedSplits;

  final bool hasBottomFixed;
  final double bottomFixedHeightCm;
  final int bottomFixedSplits;

  final bool hasRightFixed;
  final double rightFixedWidthCm;
  final int rightFixedSplits;

  final bool hasLeftFixed;
  final double leftFixedWidthCm;
  final int leftFixedSplits;

  // الشفاط
  final bool hasExhaustFan;
  final String exhaustFanShape; // دائري | مربع
  final double exhaustFanDiameterCm;
  final String exhaustFanPosition; // في الثابت العلوي | في الضلفة يمين | في الضلفة شمال | في المنتصف

  final bool hasGlass;
  final bool isDoubleGlass;
  final bool hasGeorgian;
  final bool hasFlyScreen;
  final double height;
  final bool isCompact; // وضع مصغر لبطاقات القائمة

  const Window2DVisualizer({
    super.key,
    required this.widthCm,
    required this.heightCm,
    this.unitType = 'شباك',
    this.openType = 'جرار',
    this.sashCount = 2,
    this.barType = 'ببار',
    this.openDirection = 'يمين للداخل',
    this.sectorColor = 'بيج',
    this.hasTopFixed = false,
    this.topFixedHeightCm = 40.0,
    this.topFixedSplits = 1,
    this.hasBottomFixed = false,
    this.bottomFixedHeightCm = 40.0,
    this.bottomFixedSplits = 1,
    this.hasRightFixed = false,
    this.rightFixedWidthCm = 40.0,
    this.rightFixedSplits = 1,
    this.hasLeftFixed = false,
    this.leftFixedWidthCm = 40.0,
    this.leftFixedSplits = 1,
    this.hasExhaustFan = false,
    this.exhaustFanShape = 'دائري',
    this.exhaustFanDiameterCm = 25.0,
    this.exhaustFanPosition = 'في الثابت العلوي',
    this.hasGlass = true,
    this.isDoubleGlass = false,
    this.hasGeorgian = false,
    this.hasFlyScreen = false,
    this.height = 190,
    this.isCompact = false,
  });

  String? _getSlideTrackAsset() {
    if (!openType.contains('جرار') && !openType.contains('منزلق')) return null;
    if (sashCount == 2) return 'assets/images/windows/slide/0.png';
    if (sashCount == 3) return 'assets/images/windows/slide/1.png';
    if (sashCount >= 4) return 'assets/images/windows/slide/4.png';
    return 'assets/images/windows/slide/2.png';
  }

  @override
  Widget build(BuildContext context) {
    final slideTrackAsset = _getSlideTrackAsset();

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
        ),
        borderRadius: BorderRadius.circular(isCompact ? 8 : 12),
        border: Border.all(
          color: isCompact ? const Color(0xFF94A3B8) : const Color(0xFF31869B),
          width: isCompact ? 1.0 : 1.8,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isCompact ? 7 : 10),
        child: Stack(
          children: [
            // خلفية الشبكة الهندسية الخفيفة
            CustomPaint(
              size: Size.infinite,
              painter: LightArchitecturalGridPainter(),
            ),

            // الرسم الهندسي التفاعلي للشباك والثوابت
            Padding(
              padding: EdgeInsets.fromLTRB(
                isCompact ? 6 : 34,
                isCompact ? 6 : (slideTrackAsset != null ? 28 : 22),
                isCompact ? 6 : 34,
                isCompact ? 6 : 24,
              ),
              child: CustomPaint(
                size: Size.infinite,
                painter: RealisticWindowPainter(
                  widthCm: widthCm,
                  heightCm: heightCm,
                  unitType: unitType,
                  openType: openType,
                  sashCount: sashCount,
                  barType: barType,
                  openDirection: openDirection,
                  sectorColor: sectorColor,
                  hasTopFixed: hasTopFixed,
                  topFixedHeightCm: topFixedHeightCm,
                  topFixedSplits: topFixedSplits,
                  hasBottomFixed: hasBottomFixed,
                  bottomFixedHeightCm: bottomFixedHeightCm,
                  bottomFixedSplits: bottomFixedSplits,
                  hasRightFixed: hasRightFixed,
                  rightFixedWidthCm: rightFixedWidthCm,
                  rightFixedSplits: rightFixedSplits,
                  hasLeftFixed: hasLeftFixed,
                  leftFixedWidthCm: leftFixedWidthCm,
                  leftFixedSplits: leftFixedSplits,
                  hasExhaustFan: hasExhaustFan,
                  exhaustFanShape: exhaustFanShape,
                  exhaustFanDiameterCm: exhaustFanDiameterCm,
                  exhaustFanPosition: exhaustFanPosition,
                  hasGlass: hasGlass,
                  isDoubleGlass: isDoubleGlass,
                  hasGeorgian: hasGeorgian,
                  hasFlyScreen: hasFlyScreen,
                  isCompact: isCompact,
                ),
              ),
            ),

            // رسمة مسار السكك العلوية للجرار كما في المشروع المماثل
            if (!isCompact && slideTrackAsset != null)
              Positioned(
                top: 4,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Image.asset(
                      slideTrackAsset,
                      height: 14,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),

            // شارة نوع الفتحة والثوابت المفعلة (فوق يمين)
            if (!isCompact)
              Positioned(
                top: 4,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withOpacity(0.82),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _buildStatusBadge(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            // شارة الأبعاد الكلية والمساحة (أسفل شمال)
            if (!isCompact)
              Positioned(
                bottom: 3,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF31869B),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    'عرض ${widthCm.toStringAsFixed(0)} × طول ${heightCm.toStringAsFixed(0)} سم (${((widthCm / 100) * (heightCm / 100)).toStringAsFixed(2)} م²)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _buildStatusBadge() {
    final List<String> tags = [];
    tags.add('$unitType $openType');
    if (openType != 'ثابت') {
      tags.add('$sashCount ضلفة');
    }
    if (hasLeftFixed) tags.add('ثابت شمال ${leftFixedWidthCm.toStringAsFixed(0)}سم');
    if (hasRightFixed) tags.add('ثابت يمين ${rightFixedWidthCm.toStringAsFixed(0)}سم');
    if (hasTopFixed) tags.add('ثابت فوق ${topFixedHeightCm.toStringAsFixed(0)}سم');
    if (hasBottomFixed) tags.add('ثابت تحت ${bottomFixedHeightCm.toStringAsFixed(0)}سم');
    if (hasExhaustFan) tags.add('شفاط');
    return tags.join(' • ');
  }
}

class LightArchitecturalGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFCBD5E1).withOpacity(0.45)
      ..strokeWidth = 0.5;

    const double step = 16.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RealisticWindowPainter extends CustomPainter {
  final double widthCm;
  final double heightCm;
  final String unitType;
  final String openType;
  final int sashCount;
  final String barType;
  final String openDirection;
  final String sectorColor;

  final bool hasTopFixed;
  final double topFixedHeightCm;
  final int topFixedSplits;

  final bool hasBottomFixed;
  final double bottomFixedHeightCm;
  final int bottomFixedSplits;

  final bool hasRightFixed;
  final double rightFixedWidthCm;
  final int rightFixedSplits;

  final bool hasLeftFixed;
  final double leftFixedWidthCm;
  final int leftFixedSplits;

  final bool hasExhaustFan;
  final String exhaustFanShape;
  final double exhaustFanDiameterCm;
  final String exhaustFanPosition;

  final bool hasGlass;
  final bool isDoubleGlass;
  final bool hasGeorgian;
  final bool hasFlyScreen;
  final bool isCompact;

  RealisticWindowPainter({
    required this.widthCm,
    required this.heightCm,
    required this.unitType,
    required this.openType,
    required this.sashCount,
    required this.barType,
    required this.openDirection,
    required this.sectorColor,
    required this.hasTopFixed,
    required this.topFixedHeightCm,
    required this.topFixedSplits,
    required this.hasBottomFixed,
    required this.bottomFixedHeightCm,
    required this.bottomFixedSplits,
    required this.hasRightFixed,
    required this.rightFixedWidthCm,
    required this.rightFixedSplits,
    required this.hasLeftFixed,
    required this.leftFixedWidthCm,
    required this.leftFixedSplits,
    required this.hasExhaustFan,
    required this.exhaustFanShape,
    required this.exhaustFanDiameterCm,
    required this.exhaustFanPosition,
    required this.hasGlass,
    required this.isDoubleGlass,
    required this.hasGeorgian,
    required this.hasFlyScreen,
    required this.isCompact,
  });

  Color _getFrameFillColor() {
    switch (sectorColor) {
      case 'أسود':
        return const Color(0xFF1E293B);
      case 'بيج':
        return const Color(0xFFE6DEC8);
      case 'رمادي':
        return const Color(0xFF94A3B8);
      case 'خشابي':
        return const Color(0xFF8B5A2B);
      case 'شامبين':
        return const Color(0xFFD4AF37);
      case 'فضي':
        return const Color(0xFFCBD5E1);
      case 'أبيض':
      default:
        return const Color(0xFFF8FAFC);
    }
  }

  Color _getFrameStrokeColor() {
    switch (sectorColor) {
      case 'أسود':
        return const Color(0xFF0F172A);
      case 'خشابي':
        return const Color(0xFF5C3A21);
      default:
        return const Color(0xFF475569);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double safeW = math.max(20.0, widthCm);
    final double safeH = math.max(20.0, heightCm);
    final double aspect = safeW / safeH;

    double drawW = size.width;
    double drawH = drawW / aspect;

    if (drawH > size.height) {
      drawH = size.height;
      drawW = drawH * aspect;
    }

    final double startX = (size.width - drawW) / 2;
    final double startY = (size.height - drawH) / 2;
    final Rect outerRect = Rect.fromLTWH(startX, startY, drawW, drawH);

    final Color frameFill = _getFrameFillColor();
    final Color frameStroke = _getFrameStrokeColor();

    // 1. رسم البار الخارجي إذا كان ببار
    final bool hasBar = !barType.contains('بدون');
    final double barThick = hasBar ? math.max(2.5, math.min(6.0, drawW * 0.035)) : 0.0;
    if (hasBar) {
      final Rect barRect = outerRect.inflate(barThick);
      canvas.drawRect(barRect, Paint()..color = frameFill);
      canvas.drawRect(
        barRect,
        Paint()
          ..color = frameStroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
      // خطوط شطف الزوايا 45 درجة
      final miterPaint = Paint()
        ..color = frameStroke
        ..strokeWidth = 0.8;
      canvas.drawLine(barRect.topLeft, outerRect.topLeft, miterPaint);
      canvas.drawLine(barRect.topRight, outerRect.topRight, miterPaint);
      canvas.drawLine(barRect.bottomLeft, outerRect.bottomLeft, miterPaint);
      canvas.drawLine(barRect.bottomRight, outerRect.bottomRight, miterPaint);
    }

    // 2. رسم الحلق الرئيسي
    final double frameThick = math.max(3.5, math.min(8.0, drawW * 0.045));
    canvas.drawRect(outerRect, Paint()..color = frameFill);
    canvas.drawRect(
      outerRect,
      Paint()
        ..color = frameStroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    final Rect innerRect = outerRect.deflate(frameThick);
    canvas.drawRect(
      innerRect,
      Paint()
        ..color = frameStroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // 3. تقسيم المساحة الداخلية بين الثوابت (فوق، تحت، يمين، شمال) والجزء المتحرك
    final double scaleX = innerRect.width / safeW;
    final double scaleY = innerRect.height / safeH;

    final double topH = hasTopFixed
        ? math.min(topFixedHeightCm * scaleY, innerRect.height * 0.42)
        : 0.0;
    final double botH = hasBottomFixed
        ? math.min(bottomFixedHeightCm * scaleY, innerRect.height * 0.42)
        : 0.0;
    final double leftW = hasLeftFixed
        ? math.min(leftFixedWidthCm * scaleX, innerRect.width * 0.42)
        : 0.0;
    final double rightW = hasRightFixed
        ? math.min(rightFixedWidthCm * scaleX, innerRect.width * 0.42)
        : 0.0;

    final double midY = innerRect.top + topH;
    final double midH = math.max(10.0, innerRect.height - topH - botH);
    final double midX = innerRect.left + leftW;
    final double midW = math.max(10.0, innerRect.width - leftW - rightW);

    final double mullionThick = math.max(2.5, frameThick * 0.75);

    // أ) رسم الثابت العلوي (فوق)
    if (hasTopFixed && topH > 2) {
      final Rect topRect =
          Rect.fromLTWH(innerRect.left, innerRect.top, innerRect.width, topH);
      _drawFixedSection(
        canvas,
        topRect,
        splits: topFixedSplits,
        isHorizontalSplits: true,
        frameFill: frameFill,
        frameStroke: frameStroke,
        mullionThick: mullionThick,
        label: isCompact ? '' : 'ثابت ${topFixedHeightCm.toStringAsFixed(0)}سم',
      );
      // السؤاس الفاصل
      canvas.drawRect(
        Rect.fromLTWH(
            innerRect.left, midY - mullionThick / 2, innerRect.width, mullionThick),
        Paint()..color = frameFill,
      );
      canvas.drawRect(
        Rect.fromLTWH(
            innerRect.left, midY - mullionThick / 2, innerRect.width, mullionThick),
        Paint()
          ..color = frameStroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9,
      );
    }

    // ب) رسم الثابت السفلي (تحت)
    if (hasBottomFixed && botH > 2) {
      final double botTop = innerRect.bottom - botH;
      final Rect botRect =
          Rect.fromLTWH(innerRect.left, botTop, innerRect.width, botH);
      _drawFixedSection(
        canvas,
        botRect,
        splits: bottomFixedSplits,
        isHorizontalSplits: true,
        frameFill: frameFill,
        frameStroke: frameStroke,
        mullionThick: mullionThick,
        label: isCompact ? '' : 'ثابت ${bottomFixedHeightCm.toStringAsFixed(0)}سم',
      );
      canvas.drawRect(
        Rect.fromLTWH(
            innerRect.left, botTop - mullionThick / 2, innerRect.width, mullionThick),
        Paint()..color = frameFill,
      );
      canvas.drawRect(
        Rect.fromLTWH(
            innerRect.left, botTop - mullionThick / 2, innerRect.width, mullionThick),
        Paint()
          ..color = frameStroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9,
      );
    }

    // ج) رسم الثابت الشمال (يسار)
    if (hasLeftFixed && leftW > 2) {
      final Rect leftRect = Rect.fromLTWH(innerRect.left, midY, leftW, midH);
      _drawFixedSection(
        canvas,
        leftRect,
        splits: leftFixedSplits,
        isHorizontalSplits: false,
        frameFill: frameFill,
        frameStroke: frameStroke,
        mullionThick: mullionThick,
        label: isCompact ? '' : 'ثابت ${leftFixedWidthCm.toStringAsFixed(0)}',
      );
      canvas.drawRect(
        Rect.fromLTWH(midX - mullionThick / 2, midY, mullionThick, midH),
        Paint()..color = frameFill,
      );
      canvas.drawRect(
        Rect.fromLTWH(midX - mullionThick / 2, midY, mullionThick, midH),
        Paint()
          ..color = frameStroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9,
      );
    }

    // د) رسم الثابت اليمين (يمين)
    if (hasRightFixed && rightW > 2) {
      final double rightLeft = innerRect.right - rightW;
      final Rect rightRect = Rect.fromLTWH(rightLeft, midY, rightW, midH);
      _drawFixedSection(
        canvas,
        rightRect,
        splits: rightFixedSplits,
        isHorizontalSplits: false,
        frameFill: frameFill,
        frameStroke: frameStroke,
        mullionThick: mullionThick,
        label: isCompact ? '' : 'ثابت ${rightFixedWidthCm.toStringAsFixed(0)}',
      );
      canvas.drawRect(
        Rect.fromLTWH(rightLeft - mullionThick / 2, midY, mullionThick, midH),
        Paint()..color = frameFill,
      );
      canvas.drawRect(
        Rect.fromLTWH(rightLeft - mullionThick / 2, midY, mullionThick, midH),
        Paint()
          ..color = frameStroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9,
      );
    }

    // هـ) رسم الضلف المتحركة في المنتصف
    final Rect mainRect = Rect.fromLTWH(midX, midY, midW, midH);
    if (openType == 'ثابت') {
      _drawFixedSection(
        canvas,
        mainRect,
        splits: sashCount,
        isHorizontalSplits: true,
        frameFill: frameFill,
        frameStroke: frameStroke,
        mullionThick: mullionThick,
        label: isCompact ? '' : 'ثابت',
      );
    } else {
      _drawOperableSashes(
        canvas,
        mainRect,
        frameFill: frameFill,
        frameStroke: frameStroke,
        sashThick: math.max(2.5, frameThick * 0.72),
      );
    }

    // 4. رسم فتحة الشفاط إن وجدت
    if (hasExhaustFan) {
      _drawExhaustFan(
        canvas,
        innerRect,
        topH,
        midX,
        midY,
        midW,
        midH,
        scaleX,
      );
    }

    // 5. رسم خطوط الأبعاد في الوضع الكامل
    if (!isCompact) {
      _drawOuterDimensionLabels(canvas, outerRect.inflate(barThick));
    }
  }

  void _drawGlassPane(Canvas canvas, Rect paneRect) {
    if (paneRect.width <= 1 || paneRect.height <= 1) return;

    final Paint glassFill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: hasGlass
            ? (isDoubleGlass
                ? [const Color(0xFF67C6E3), const Color(0xFF38A3C7)]
                : [const Color(0xFF8BE0F7), const Color(0xFF5BC0DE)])
            : [const Color(0xFFE2E8F0), const Color(0xFFCBD5E1)],
      ).createShader(paneRect);

    canvas.drawRect(paneRect, glassFill);

    // لمعة الزجاج المائلة (مطابقة لرسمة الـ PDF والمشروع المماثل)
    if (paneRect.width > 12 && paneRect.height > 12) {
      final Paint sheenPaint = Paint()
        ..color = Colors.white.withOpacity(0.45)
        ..strokeWidth = isCompact ? 1.2 : 2.2
        ..strokeCap = StrokeCap.round;

      final double s = math.min(paneRect.width, paneRect.height) * 0.35;
      canvas.drawLine(
        Offset(paneRect.left + 4, paneRect.top + s),
        Offset(paneRect.left + s, paneRect.top + 4),
        sheenPaint,
      );
      canvas.drawLine(
        Offset(paneRect.left + 8, paneRect.top + s + 5),
        Offset(paneRect.left + s + 5, paneRect.top + 8),
        sheenPaint,
      );
    }

    // أعواد الجورجيا
    if (hasGeorgian && paneRect.width > 10 && paneRect.height > 10) {
      final Paint geoPaint = Paint()
        ..color = const Color(0xFFD97706).withOpacity(0.85)
        ..strokeWidth = isCompact ? 0.8 : 1.3;
      canvas.drawLine(
        Offset(paneRect.left, paneRect.center.dy),
        Offset(paneRect.right, paneRect.center.dy),
        geoPaint,
      );
      canvas.drawLine(
        Offset(paneRect.center.dx, paneRect.top),
        Offset(paneRect.center.dx, paneRect.bottom),
        geoPaint,
      );
    }
  }

  void _drawFixedSection(
    Canvas canvas,
    Rect rect, {
    required int splits,
    required bool isHorizontalSplits,
    required Color frameFill,
    required Color frameStroke,
    required double mullionThick,
    required String label,
  }) {
    final int safeSplits = math.max(1, splits);
    if (isHorizontalSplits) {
      final double subW = rect.width / safeSplits;
      for (int i = 0; i < safeSplits; i++) {
        final Rect sub =
            Rect.fromLTWH(rect.left + i * subW, rect.top, subW, rect.height);
        _drawGlassPane(canvas, sub.deflate(1.5));
        canvas.drawRect(
          sub.deflate(1.5),
          Paint()
            ..color = frameStroke
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8,
        );
        if (i > 0) {
          final double mx = rect.left + i * subW - mullionThick / 2;
          canvas.drawRect(
            Rect.fromLTWH(mx, rect.top, mullionThick, rect.height),
            Paint()..color = frameFill,
          );
        }
      }
    } else {
      final double subH = rect.height / safeSplits;
      for (int i = 0; i < safeSplits; i++) {
        final Rect sub =
            Rect.fromLTWH(rect.left, rect.top + i * subH, rect.width, subH);
        _drawGlassPane(canvas, sub.deflate(1.5));
        canvas.drawRect(
          sub.deflate(1.5),
          Paint()
            ..color = frameStroke
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8,
        );
        if (i > 0) {
          final double my = rect.top + i * subH - mullionThick / 2;
          canvas.drawRect(
            Rect.fromLTWH(rect.left, my, rect.width, mullionThick),
            Paint()..color = frameFill,
          );
        }
      }
    }

    if (label.isNotEmpty && rect.width > 28 && rect.height > 14) {
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 8.5,
            fontWeight: FontWeight.bold,
            backgroundColor: Color(0xCCFFFFFF),
          ),
        ),
        textDirection: TextDirection.rtl,
      )..layout();
      tp.paint(
        canvas,
        Offset(
          rect.center.dx - tp.width / 2,
          rect.center.dy - tp.height / 2,
        ),
      );
    }
  }

  void _drawOperableSashes(
    Canvas canvas,
    Rect r, {
    required Color frameFill,
    required Color frameStroke,
    required double sashThick,
  }) {
    final int count = math.max(1, sashCount);
    final double sashW = r.width / count;

    for (int i = 0; i < count; i++) {
      final Rect sashRect =
          Rect.fromLTWH(r.left + i * sashW, r.top, sashW, r.height);

      // برواز الضلفة
      canvas.drawRect(sashRect, Paint()..color = frameFill);
      canvas.drawRect(
        sashRect,
        Paint()
          ..color = frameStroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );

      final Rect glassRect = sashRect.deflate(sashThick);
      _drawGlassPane(canvas, glassRect);
      canvas.drawRect(
        glassRect,
        Paint()
          ..color = frameStroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );

      // خطوط الحركة والمقبض
      _drawSashDirectionAndHardware(canvas, glassRect, sashRect, i, count);
    }
  }

  void _drawSashDirectionAndHardware(
    Canvas canvas,
    Rect glassRect,
    Rect sashRect,
    int index,
    int totalCount,
  ) {
    final Paint linePaint = Paint()
      ..color = const Color(0xFF0F172A).withOpacity(0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isCompact ? 0.9 : 1.3;

    if (openType.contains('قلا') || openDirection.contains('قلاب')) {
      // مثلث القلاب (يفتح من أعلى والارتكاز بالأسفل)
      final Path p = Path()
        ..moveTo(glassRect.left, glassRect.bottom)
        ..lineTo(glassRect.center.dx, glassRect.top)
        ..lineTo(glassRect.right, glassRect.bottom);
      canvas.drawPath(p, linePaint);
    } else if (openType.contains('مفصلي')) {
      final bool openLeft =
          (totalCount == 1 && openDirection.contains('شمال')) ||
              (totalCount > 1 && index % 2 == 1);
      final Path p = Path();
      if (openLeft) {
        p.moveTo(glassRect.left, glassRect.top);
        p.lineTo(glassRect.right, glassRect.center.dy);
        p.lineTo(glassRect.left, glassRect.bottom);
      } else {
        p.moveTo(glassRect.right, glassRect.top);
        p.lineTo(glassRect.left, glassRect.center.dy);
        p.lineTo(glassRect.right, glassRect.bottom);
      }
      canvas.drawPath(p, linePaint);
    } else if (openType.contains('جرار') || openType.contains('منزلق')) {
      // سهم الجرار الأفقي في منتصف الضلفة
      if (!isCompact && glassRect.width > 18) {
        final double ay = glassRect.center.dy;
        final double len = math.min(18.0, glassRect.width * 0.45);
        final double dir = (index % 2 == 0) ? 1.0 : -1.0;
        final double cx = glassRect.center.dx;
        canvas.drawLine(
          Offset(cx - (len / 2 * dir), ay),
          Offset(cx + (len / 2 * dir), ay),
          linePaint,
        );
        canvas.drawLine(
          Offset(cx + (len / 2 * dir), ay),
          Offset(cx + ((len / 2 - 4) * dir), ay - 3),
          linePaint,
        );
        canvas.drawLine(
          Offset(cx + (len / 2 * dir), ay),
          Offset(cx + ((len / 2 - 4) * dir), ay + 3),
          linePaint,
        );
      }
    }

    // رسم المقبض / الصكاك
    if (!isCompact) {
      final Paint handlePaint = Paint()
        ..color = const Color(0xFF1E293B)
        ..style = PaintingStyle.fill;
      final double hH = math.min(14.0, sashRect.height * 0.14);
      const double hW = 3.0;
      double hx = (index % 2 == 0) ? sashRect.right - 3.5 : sashRect.left + 3.5;
      if (openType.contains('قلا')) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(sashRect.center.dx, sashRect.top + 3.5),
                width: hH,
                height: hW),
            const Radius.circular(1.5),
          ),
          handlePaint,
        );
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(hx, sashRect.center.dy), width: hW, height: hH),
            const Radius.circular(1.5),
          ),
          handlePaint,
        );
      }
    }
  }

  void _drawExhaustFan(
    Canvas canvas,
    Rect innerRect,
    double topH,
    double midX,
    double midY,
    double midW,
    double midH,
    double scaleX,
  ) {
    Offset fanCenter;
    double fanSize = math.max(14.0, math.min(34.0, exhaustFanDiameterCm * scaleX));

    if (hasTopFixed && exhaustFanPosition.contains('الثابت') && topH > 8) {
      fanCenter = Offset(innerRect.center.dx, innerRect.top + topH / 2);
      fanSize = math.min(fanSize, topH * 0.82);
    } else if (exhaustFanPosition.contains('شمال')) {
      fanCenter = Offset(midX + midW * 0.25, midY + midH * 0.32);
    } else if (exhaustFanPosition.contains('يمين')) {
      fanCenter = Offset(midX + midW * 0.75, midY + midH * 0.32);
    } else {
      fanCenter = Offset(midX + midW * 0.5, midY + midH * 0.32);
    }

    final Rect box = Rect.fromCenter(center: fanCenter, width: fanSize, height: fanSize);
    canvas.drawRRect(
      RRect.fromRectAndRadius(box, const Radius.circular(3)),
      Paint()..color = Colors.white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(box, const Radius.circular(3)),
      Paint()
        ..color = const Color(0xFF334155)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    final double r = fanSize * 0.38;
    canvas.drawCircle(fanCenter, r, Paint()..color = const Color(0xFF0F172A));
    final Paint bladePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.2;
    for (int i = 0; i < 6; i++) {
      final double ang = (i * 60) * math.pi / 180.0;
      canvas.drawLine(
        fanCenter,
        fanCenter.translate(math.cos(ang) * r * 0.85, math.sin(ang) * r * 0.85),
        bladePaint,
      );
    }
    canvas.drawCircle(fanCenter, r * 0.25, Paint()..color = Colors.white);
  }

  void _drawOuterDimensionLabels(Canvas canvas, Rect frameRect) {
    final Paint dimPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeWidth = 0.9;

    // خط العرض بالأسفل
    final double by = frameRect.bottom + 9;
    canvas.drawLine(Offset(frameRect.left, by), Offset(frameRect.right, by), dimPaint);
    canvas.drawLine(Offset(frameRect.left, by - 3), Offset(frameRect.left, by + 3), dimPaint);
    canvas.drawLine(Offset(frameRect.right, by - 3), Offset(frameRect.right, by + 3), dimPaint);

    final tpW = TextPainter(
      text: TextSpan(
        text: '${widthCm.toStringAsFixed(0)} سم',
        style: const TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          backgroundColor: Color(0xEEFFFFFF),
        ),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    tpW.paint(canvas, Offset(frameRect.center.dx - tpW.width / 2, by - tpW.height / 2));

    // خط الطول على اليمين
    final double rx = frameRect.right + 10;
    canvas.drawLine(Offset(rx, frameRect.top), Offset(rx, frameRect.bottom), dimPaint);
    canvas.drawLine(Offset(rx - 3, frameRect.top), Offset(rx + 3, frameRect.top), dimPaint);
    canvas.drawLine(Offset(rx - 3, frameRect.bottom), Offset(rx + 3, frameRect.bottom), dimPaint);

    final tpH = TextPainter(
      text: TextSpan(
        text: '${heightCm.toStringAsFixed(0)}',
        style: const TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 9,
          fontWeight: FontWeight.bold,
          backgroundColor: Color(0xEEFFFFFF),
        ),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    tpH.paint(canvas, Offset(rx - tpH.width / 2, frameRect.center.dy - tpH.height / 2));
  }

  @override
  bool shouldRepaint(covariant RealisticWindowPainter oldDelegate) {
    return oldDelegate.widthCm != widthCm ||
        oldDelegate.heightCm != heightCm ||
        oldDelegate.sashCount != sashCount ||
        oldDelegate.openType != openType ||
        oldDelegate.barType != barType ||
        oldDelegate.sectorColor != sectorColor ||
        oldDelegate.openDirection != openDirection ||
        oldDelegate.hasTopFixed != hasTopFixed ||
        oldDelegate.topFixedHeightCm != topFixedHeightCm ||
        oldDelegate.topFixedSplits != topFixedSplits ||
        oldDelegate.hasBottomFixed != hasBottomFixed ||
        oldDelegate.bottomFixedHeightCm != bottomFixedHeightCm ||
        oldDelegate.bottomFixedSplits != bottomFixedSplits ||
        oldDelegate.hasRightFixed != hasRightFixed ||
        oldDelegate.rightFixedWidthCm != rightFixedWidthCm ||
        oldDelegate.rightFixedSplits != rightFixedSplits ||
        oldDelegate.hasLeftFixed != hasLeftFixed ||
        oldDelegate.leftFixedWidthCm != leftFixedWidthCm ||
        oldDelegate.leftFixedSplits != leftFixedSplits ||
        oldDelegate.hasExhaustFan != hasExhaustFan ||
        oldDelegate.exhaustFanShape != exhaustFanShape ||
        oldDelegate.exhaustFanDiameterCm != exhaustFanDiameterCm ||
        oldDelegate.exhaustFanPosition != exhaustFanPosition ||
        oldDelegate.hasGlass != hasGlass ||
        oldDelegate.isDoubleGlass != isDoubleGlass ||
        oldDelegate.hasGeorgian != hasGeorgian ||
        oldDelegate.hasFlyScreen != hasFlyScreen;
  }
}
