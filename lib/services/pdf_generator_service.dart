import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/workshop_models.dart';
import '../widgets/svg_profile_widget.dart';
import '../widgets/window_2d_visualizer.dart';
import 'native_file_service.dart';
import 'workshop_storage.dart';

class PdfGeneratorService {
  static ui.Image? _hafezLogoUiImage;

  static Future<ui.Image?> _loadUiImageFromAsset(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (_) {
      return null;
    }
  }

  static Future<ui.Image?> _loadUiImageFromBytes(Uint8List? bytes) async {
    if (bytes == null || bytes.isEmpty) return null;
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _ensureLogoLoaded() async {
    _hafezLogoUiImage ??=
        await _loadUiImageFromAsset('assets/images/hafez_logo.png') ??
            await _loadUiImageFromAsset('assets/images/hafez_icon.png');
  }

  static String formatMoney(double val) {
    final int intVal = val.round();
    final String s = intVal.toString();
    final StringBuffer sb = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        sb.write(',');
      }
      sb.write(s[i]);
    }
    return sb.toString();
  }

  static void _drawTextInRect(
    Canvas canvas,
    Rect rect,
    String text, {
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.normal,
    Color color = Colors.black,
    TextAlign textAlign = TextAlign.center,
    TextDirection textDirection = TextDirection.rtl,
    int? maxLines,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Rubik',
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: 1.18,
        ),
      ),
      textAlign: textAlign,
      textDirection: textDirection,
      maxLines: maxLines,
    )..layout(maxWidth: math.max(10.0, rect.width - 6));

    double dx = rect.left + (rect.width - tp.width) / 2;
    if (textAlign == TextAlign.right) {
      dx = rect.right - tp.width - 6;
    } else if (textAlign == TextAlign.left) {
      dx = rect.left + 6;
    }
    final double dy = rect.top + (rect.height - tp.height) / 2;
    tp.paint(canvas, Offset(dx, dy));
  }

  /// 1. توليد كشف عرض السعر المعماري المطابق 100% لملف (أ. احمد ابو اليزيد.pdf)
  /// يتم الرسم عبر محرك Flutter الأصلي (Canvas + TextPainter) بدقة عالية لضمان تشكيل الحروف العربية والجدول والألوان والرسومات بالملي
  static Future<Uint8List> buildQuotationPdfBytes({
    required ClientRecord client,
    required WorkshopStorage storage,
  }) async {
    await _ensureLogoLoaded();
    final pdf = pw.Document();
    final bool minOneM2 =
        storage.pricingSettings.enforceMinimumOneSquareMeter;
    final settings = storage.pricingSettings;

    double totalAreaAll = 0.0;
    int totalQuantityAll = 0;
    double grandTotalAll = 0.0;

    for (final it in client.items) {
      final double dispArea = it.displayTotalAreaM2(minOneM2: minOneM2);
      final double cost = it.calculateTotalCost(
          storage.getSectorById(it.sectorId),
          minOneM2: minOneM2);
      totalAreaAll += dispArea;
      totalQuantityAll += it.quantity;
      grandTotalAll += cost;
    }

    final double netTotal =
        (grandTotalAll - client.discountAmount).clamp(0.0, double.infinity);
    final double finalQuotationTotal =
        (netTotal + client.archCost - client.depositAmount)
            .clamp(0.0, double.infinity);

    // تقسيم البنود على صفحات عند الحاجة (كل صفحة تتسع لـ 6 شبابيك مع الهيدر والفوتر كما في النموذج الأصلي)
    const int itemsPerPage = 6;
    final int totalPages =
        math.max(1, (client.items.length / itemsPerPage).ceil());

    for (int pageIdx = 0; pageIdx < totalPages; pageIdx++) {
      final int startIdx = pageIdx * itemsPerPage;
      final int endIdx =
          math.min(client.items.length, startIdx + itemsPerPage);
      final pageItems = client.items.isEmpty
          ? <ClientWindowItem>[]
          : client.items.sublist(startIdx, endIdx);
      final bool isLastPage = (pageIdx == totalPages - 1);

      final Uint8List pagePng = await _renderQuotationPagePng(
        client: client,
        storage: storage,
        settings: settings,
        pageItems: pageItems,
        startIndex: startIdx,
        minOneM2: minOneM2,
        totalQuantityAll: totalQuantityAll,
        totalAreaAll: totalAreaAll,
        grandTotalAll: grandTotalAll,
        finalQuotationTotal: finalQuotationTotal,
        showFooterSummary: isLastPage,
      );

      final pageImg = pw.MemoryImage(pagePng);
      pdf.addPage(
        pw.Page(
          pageFormat: const PdfPageFormat(792, 612), // Landscape
          margin: pw.EdgeInsets.zero,
          build: (ctx) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Image(pageImg, fit: pw.BoxFit.contain),
          ),
        ),
      );
    }

    return pdf.save();
  }

  static Future<Uint8List> _renderQuotationPagePng({
    required ClientRecord client,
    required WorkshopStorage storage,
    required PricingSettings settings,
    required List<ClientWindowItem> pageItems,
    required int startIndex,
    required bool minOneM2,
    required int totalQuantityAll,
    required double totalAreaAll,
    required double grandTotalAll,
    required double finalQuotationTotal,
    required bool showFooterSummary,
  }) async {
    const double canvasW = 1650.0;
    const double canvasH = 1275.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, canvasW, canvasH));

    // خلفية الصفحة البيضاء
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, canvasW, canvasH),
      Paint()..color = Colors.white,
    );

    const Color tealHeader = Color(0xFF388E9C);
    const Color summaryBlue = Color(0xFF558ED5);
    const double tableLeft = 175.0;
    const double tableWidth = 1300.0;
    const double tableRight = tableLeft + tableWidth;

    // ==================== 1. البانر الأسود العلوي مع لوجو شركة الحافظ ====================
    const double bannerTop = 28.0;
    const double bannerHeight = 122.0;
    final Rect blackBanner =
        Rect.fromLTWH(tableLeft, bannerTop, tableWidth, bannerHeight);
    canvas.drawRect(blackBanner, Paint()..color = Colors.black);

    // صندوق "أسم العميل /" على اليمين
    final Rect rightClientBox =
        Rect.fromLTWH(tableRight - 430, bannerTop + 44, 418, 46);
    canvas.drawRect(rightClientBox, Paint()..color = tealHeader);
    canvas.drawLine(
      Offset(rightClientBox.right - 140, rightClientBox.top),
      Offset(rightClientBox.right - 140, rightClientBox.bottom),
      Paint()
        ..color = Colors.black54
        ..strokeWidth = 1.2,
    );
    _drawTextInRect(
      canvas,
      Rect.fromLTWH(rightClientBox.right - 140, rightClientBox.top, 140,
          rightClientBox.height),
      'أسم العميل /',
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF0F172A),
    );
    _drawTextInRect(
      canvas,
      Rect.fromLTWH(rightClientBox.left, rightClientBox.top,
          rightClientBox.width - 140, rightClientBox.height),
      client.clientName.isNotEmpty ? client.clientName : 'أ. احمد ابو اليزيد',
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF0F172A),
    );

    // صندوق "المكان /" على اليسار
    final Rect leftLocBox =
        Rect.fromLTWH(tableLeft + 12, bannerTop + 44, 330, 46);
    canvas.drawRect(leftLocBox, Paint()..color = tealHeader);
    canvas.drawLine(
      Offset(leftLocBox.right - 105, leftLocBox.top),
      Offset(leftLocBox.right - 105, leftLocBox.bottom),
      Paint()
        ..color = Colors.black54
        ..strokeWidth = 1.2,
    );
    _drawTextInRect(
      canvas,
      Rect.fromLTWH(
          leftLocBox.right - 105, leftLocBox.top, 105, leftLocBox.height),
      'المكان /',
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF0F172A),
    );
    _drawTextInRect(
      canvas,
      Rect.fromLTWH(leftLocBox.left, leftLocBox.top, leftLocBox.width - 105,
          leftLocBox.height),
      client.clientAddress.isNotEmpty
          ? client.clientAddress
          : 'ابراج الروضه شارع ناصر',
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF0F172A),
    );

    // لوجو شركة الحافظ في منتصف البانر الأسود
    if (_hafezLogoUiImage != null) {
      final Rect logoDst = Rect.fromCenter(
        center: Offset(blackBanner.center.dx - 35, blackBanner.center.dy),
        width: 118,
        height: 114,
      );
      paintImage(
        canvas: canvas,
        rect: logoDst,
        image: _hafezLogoUiImage!,
        fit: BoxFit.contain,
      );
    }

    // ==================== 2. جدول عرض السعر ذو الـ 13 عموداً (من اليمين لليسار) ====================
    // ترتيب الأعمدة من اليمين إلى اليسار مطابقاً لـ (أ. احمد ابو اليزيد.pdf):
    // 0: No. | 1: رسومات | 2: عرض | 3: طول | 4: متر مربع | 5: توصيف | 6: لون القطاع | 7: نوع الزجاج | 8: سعر المتر | 9: سعر الوحدة | 10: عدد | 11: اجمالي المتر المربع | 12: اجمالي السعر
    final List<double> colWidths = [
      34,  // No.
      146, // رسومات
      82,  // عرض
      82,  // طول
      84,  // متر مربع
      138, // توصيف
      80,  // لون القطاع
      95,  // نوع الزجاج
      96,  // سعر المتر
      108, // سعر الوحدة
      76,  // عدد
      115, // اجمالي المتر المربع
      164, // اجمالي السعر
    ];

    final List<String> colHeaders = [
      'No.',
      'رسومات',
      'عرض',
      'طول',
      'متر مربع',
      'توصيف',
      'لون القطاع',
      'نوع\nالزجاج',
      'سعر المتر',
      'سعر الوحدة',
      'عدد',
      'اجمالي المتر\nالمربع',
      'اجمالي السعر',
    ];

    // حساب إحداثيات كل عمود من اليمين إلى اليسار
    final List<Rect> colHeaderRects = [];
    double curRight = tableRight;
    const double headerRowTop = bannerTop + bannerHeight;
    const double headerRowHeight = 46.0;

    for (int c = 0; c < colWidths.length; c++) {
      final double w = colWidths[c];
      final Rect r =
          Rect.fromLTWH(curRight - w, headerRowTop, w, headerRowHeight);
      colHeaderRects.add(r);
      curRight -= w;
    }

    final Paint borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    // رسم صف عناوين الجدول
    for (int c = 0; c < colHeaderRects.length; c++) {
      final Rect r = colHeaderRects[c];
      canvas.drawRect(r, Paint()..color = tealHeader);
      canvas.drawRect(r, borderPaint);
      _drawTextInRect(
        canvas,
        r,
        colHeaders[c],
        fontSize: c == 0 ? 13 : 15,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF0F172A),
      );
    }

    // رسم صفوف الشبابيك
    double curRowTop = headerRowTop + headerRowHeight;
    const double rowHeight = 114.0;

    for (int i = 0; i < pageItems.length; i++) {
      final item = pageItems[i];
      final sector = storage.getSectorById(item.sectorId);
      final double singleArea = item.displaySingleAreaM2(minOneM2: minOneM2);
      final double totalArea = item.displayTotalAreaM2(minOneM2: minOneM2);
      final double rowTotal =
          item.calculateTotalCost(sector, minOneM2: minOneM2);
      final double unitPrice =
          item.quantity > 0 ? (rowTotal / item.quantity) : rowTotal;
      final double meterPrice = item.effectiveMeterPrice(sector);

      final List<String> rowValues = [
        'W${startIndex + i + 1}',
        '', // رسومات
        '${item.widthCm.toStringAsFixed(0)} cm',
        '${item.heightCm.toStringAsFixed(0)} cm',
        singleArea.toStringAsFixed(2),
        item.pdfDescriptionText(sector),
        item.sectorColor,
        item.glassSummaryText,
        meterPrice.toStringAsFixed(0),
        formatMoney(unitPrice),
        '${item.quantity}',
        totalArea.toStringAsFixed(2),
        formatMoney(rowTotal),
      ];

      for (int c = 0; c < colWidths.length; c++) {
        final Rect headerR = colHeaderRects[c];
        final Rect cellR =
            Rect.fromLTWH(headerR.left, curRowTop, headerR.width, rowHeight);

        if (c == 0) {
          // عمود No. بخلفية تركواز
          canvas.drawRect(cellR, Paint()..color = tealHeader);
        } else {
          canvas.drawRect(cellR, Paint()..color = Colors.white);
        }
        canvas.drawRect(cellR, borderPaint);

        if (c == 1) {
          // رسم الشباك بنفس شكله وثوابته داخل خلية "رسومات"
          canvas.save();
          final Rect drawArea = cellR.deflate(10);
          canvas.translate(drawArea.left, drawArea.top);
          final painter = RealisticWindowPainter(
            widthCm: item.widthCm,
            heightCm: item.heightCm,
            unitType: item.unitType,
            openType: item.openType,
            sashCount: item.sashCount,
            barType: item.barType,
            openDirection: item.openDirection,
            sectorColor: item.sectorColor,
            hasTopFixed: item.hasTopFixed,
            topFixedHeightCm: item.topFixedHeightCm,
            topFixedSplits: item.topFixedSplits,
            hasBottomFixed: item.hasBottomFixed,
            bottomFixedHeightCm: item.bottomFixedHeightCm,
            bottomFixedSplits: item.bottomFixedSplits,
            hasRightFixed: item.hasRightFixed,
            rightFixedWidthCm: item.rightFixedWidthCm,
            rightFixedSplits: item.rightFixedSplits,
            hasLeftFixed: item.hasLeftFixed,
            leftFixedWidthCm: item.leftFixedWidthCm,
            leftFixedSplits: item.leftFixedSplits,
            hasExhaustFan: item.hasExhaustFan,
            exhaustFanShape: item.exhaustFanShape,
            exhaustFanDiameterCm: item.exhaustFanDiameterCm,
            exhaustFanPosition: item.exhaustFanPosition,
            hasGlass: item.hasGlass,
            isDoubleGlass: item.isDoubleGlass,
            hasGeorgian: item.hasGeorgianBars,
            hasFlyScreen: item.hasFlyScreen,
            isCompact: true,
          );
          painter.paint(canvas, drawArea.size);
          canvas.restore();
        } else {
          _drawTextInRect(
            canvas,
            cellR,
            rowValues[c],
            fontSize: c == 0 ? 13 : (c == 7 ? 15 : 17.5),
            fontWeight: FontWeight.bold,
            color: Colors.black,
            textDirection: (c == 2 || c == 3 || c == 4 || c >= 8)
                ? TextDirection.ltr
                : TextDirection.rtl,
          );
        }
      }

      curRowTop += rowHeight;
    }

    // ==================== 3. صف إجماليات الجدول السفلي ====================
    const double totalRowH = 42.0;
    for (int c = 0; c < colWidths.length; c++) {
      final Rect headerR = colHeaderRects[c];
      final Rect cellR =
          Rect.fromLTWH(headerR.left, curRowTop, headerR.width, totalRowH);
      canvas.drawRect(cellR, Paint()..color = tealHeader);
      canvas.drawRect(cellR, borderPaint);

      if (c == 10) {
        _drawTextInRect(
          canvas,
          cellR,
          '$totalQuantityAll',
          fontSize: 16,
          fontWeight: FontWeight.bold,
          textDirection: TextDirection.ltr,
        );
      } else if (c == 11) {
        _drawTextInRect(
          canvas,
          cellR,
          '${totalAreaAll.toStringAsFixed(2)} m2',
          fontSize: 15,
          fontWeight: FontWeight.bold,
          textDirection: TextDirection.ltr,
        );
      } else if (c == 12) {
        _drawTextInRect(
          canvas,
          cellR,
          '${formatMoney(grandTotalAll)} EGP',
          fontSize: 15.5,
          fontWeight: FontWeight.bold,
          textDirection: TextDirection.ltr,
        );
      }
    }
    curRowTop += totalRowH;

    // ==================== 4. الفوتر وملخص المقايسة وشروط التعاقد ====================
    if (showFooterSummary) {
      // سطر "وتفضلو بقبول فائق الاحترام,,,"
      _drawTextInRect(
        canvas,
        Rect.fromLTWH(tableLeft, curRowTop + 4, tableWidth, 26),
        'وتفضلو بقبول فائق الاحترام,,,',
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      );

      // جدول الإجماليات الأزرق في المنتصف/اليمين كما في النموذج
      const double sumBoxW = 590.0;
      const double sumRowH = 34.0;
      final double sumLeft = tableLeft + 465.0;
      final double sumTop = curRowTop + 32.0;

      final List<Map<String, String>> sumRows = [
        {
          'label': 'يضاف للمقايسة قيمة : عربون',
          'val': client.depositAmount > 0
              ? '${formatMoney(client.depositAmount)} EGP'
              : '',
        },
        {
          'label': 'يضاف للمقايسة قيمة :دورانات',
          'val': client.archCost > 0
              ? '${formatMoney(client.archCost)} EGP'
              : '',
        },
        {
          'label': 'إجمالى المقايسة',
          'val': '${formatMoney(finalQuotationTotal)} EGP',
        },
      ];

      for (int r = 0; r < sumRows.length; r++) {
        final double ry = sumTop + r * sumRowH;
        final Rect valCell = Rect.fromLTWH(sumLeft, ry, 165, sumRowH);
        final Rect lblCell =
            Rect.fromLTWH(sumLeft + 165, ry, sumBoxW - 165, sumRowH);

        canvas.drawRect(valCell, Paint()..color = summaryBlue);
        canvas.drawRect(lblCell, Paint()..color = summaryBlue);
        canvas.drawRect(valCell, borderPaint);
        canvas.drawRect(lblCell, borderPaint);

        _drawTextInRect(
          canvas,
          valCell,
          sumRows[r]['val']!,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          textDirection: TextDirection.ltr,
        );
        _drawTextInRect(
          canvas,
          lblCell,
          sumRows[r]['label']!,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        );
      }

      // ملاحظات وشروط التعاقد في الأسفل
      double noteY = sumTop + (sumRowH * 3) + 10.0;
      final List<String> footerLines = [
        settings.pdfNoteLine1,
        settings.pdfNoteLine2,
        settings.pdfNoteLine3,
        settings.pdfNoteLine4,
        '${settings.pdfNoteLine5}  •  ${settings.pdfNoteLine6}',
        'شروط التعاقد : ${settings.termsAndConditions}',
      ];

      for (int n = 0; n < footerLines.length; n++) {
        _drawTextInRect(
          canvas,
          Rect.fromLTWH(tableLeft, noteY, tableWidth, 26),
          footerLines[n],
          fontSize: n == 0 ? 20 : 16.5,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        );
        noteY += 25.0;
      }
    }

    final picture = recorder.endRecording();
    final uiImage = await picture.toImage(canvasW.toInt(), canvasH.toInt());
    final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  /// 2. توليد كشف حساب الطلبية وتقطيع الأعواد والزجاج والـ SVG (مطابق لحساب الطلبية في الورشة الذكية)
  static Future<Uint8List> buildCuttingListPdfBytes({
    required ClientRecord client,
    required WorkshopStorage storage,
  }) async {
    await _ensureLogoLoaded();
    final pdf = pw.Document();
    final aggregatedProfiles =
        storage.calculateAggregatedProfilesOrder(client.items);

    // تحميل رسومات مقاطع الألومنيوم (SVG/PNG) لكل بروفايل
    final Map<String, ui.Image?> profileImages = {};
    for (final prof in aggregatedProfiles) {
      if (prof.svgAssetPath != null &&
          !profileImages.containsKey(prof.svgAssetPath)) {
        final bytes = await SvgProfileLoader.loadPngBytes(prof.svgAssetPath);
        profileImages[prof.svgAssetPath!] = await _loadUiImageFromBytes(bytes);
      }
    }

    final Uint8List orderPagePng = await _renderOrderCalculationPagePng(
      client: client,
      storage: storage,
      aggregatedProfiles: aggregatedProfiles,
      profileImages: profileImages,
    );

    final orderImg = pw.MemoryImage(orderPagePng);
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (ctx) => pw.FullPage(
          ignoreMargins: true,
          child: pw.Image(orderImg, fit: pw.BoxFit.contain),
        ),
      ),
    );

    return pdf.save();
  }

  static Future<Uint8List> _renderOrderCalculationPagePng({
    required ClientRecord client,
    required WorkshopStorage storage,
    required List<AggregatedProfileOrder> aggregatedProfiles,
    required Map<String, ui.Image?> profileImages,
  }) async {
    const double canvasW = 1240.0;
    const double canvasH = 1754.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, canvasW, canvasH));

    canvas.drawRect(
      const Rect.fromLTWH(0, 0, canvasW, canvasH),
      Paint()..color = Colors.white,
    );

    const Color tealHeader = Color(0xFF1E293B);
    const Color accentGold = Color(0xFFD97706);

    // هيدر كشف حساب الطلبية
    final Rect headerBox = const Rect.fromLTWH(40, 30, canvasW - 80, 90);
    canvas.drawRRect(
      RRect.fromRectAndRadius(headerBox, const Radius.circular(10)),
      Paint()..color = tealHeader,
    );

    if (_hafezLogoUiImage != null) {
      paintImage(
        canvas: canvas,
        rect: const Rect.fromLTWH(60, 40, 70, 70),
        image: _hafezLogoUiImage!,
        fit: BoxFit.contain,
      );
    }

    _drawTextInRect(
      canvas,
      const Rect.fromLTWH(150, 38, canvasW - 210, 40),
      'كشف حساب الطلبية وتقطيع الأعواد والزجاج — الورشة الذكية (شركة الحافظ)',
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: const Color(0xFFFDE68A),
      textAlign: TextAlign.right,
    );
    _drawTextInRect(
      canvas,
      const Rect.fromLTWH(150, 76, canvasW - 210, 34),
      'العميل: ${client.clientName}   |   العنوان: ${client.clientAddress}   |   عدد البنود: ${client.items.length}',
      fontSize: 17,
      fontWeight: FontWeight.bold,
      color: Colors.white,
      textAlign: TextAlign.right,
    );

    double curY = 138.0;
    final Paint borderPaint = Paint()
      ..color = const Color(0xFF475569)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    // أولاً: جدول البروفايلات وتقطيع الأعواد (6 متر) مع صورة كل قطاع
    _drawTextInRect(
      canvas,
      Rect.fromLTWH(40, curY, canvasW - 80, 32),
      'أولاً: كشف القطاعات وأطوال القص وعدد الأعواد المطلوبة (${storage.pricingSettings.defaultStockBarLengthCm.toStringAsFixed(0)} سم):',
      fontSize: 19,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF7F1D1D),
      textAlign: TextAlign.right,
    );
    curY += 36;

    // أعمدة جدول الطلبية من اليمين لليسار:
    // رسمة القطاع (90) | اسم البروفايل والقطاع (280) | أطوال القص × العدد (430) | إجمالي الأعواد (120) | خطة تقطيع الأعواد والفضلة (240)
    final List<double> pCols = [90, 270, 410, 120, 270];
    final List<String> pHeaders = [
      'رسمة القطاع',
      'اسم البروفايل / القطاع',
      'مقاسات القص المطلوبة (سم × عدد)',
      'عدد الأعواد',
      'تقسيم الأعواد والفضلة',
    ];

    double rx = canvasW - 40;
    for (int c = 0; c < pCols.length; c++) {
      final Rect hr = Rect.fromLTWH(rx - pCols[c], curY, pCols[c], 38);
      canvas.drawRect(hr, Paint()..color = const Color(0xFF31869B));
      canvas.drawRect(hr, borderPaint);
      _drawTextInRect(
        canvas,
        hr,
        pHeaders[c],
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      );
      rx -= pCols[c];
    }
    curY += 38;

    for (final prof in aggregatedProfiles.take(12)) {
      const double rowH = 68.0;
      if (curY + rowH > canvasH - 360) break;

      double cx = canvasW - 40;
      final lengthsText = prof.lengthCounts.entries
          .map((e) => '${e.key.toStringAsFixed(1)} سم × ${e.value}')
          .join('  ،  ');
      final barsSummary = prof.barPlans
          .take(2)
          .map((b) =>
              'عود#${b.barNumber}: [${b.cutsCm.map((x) => x.toStringAsFixed(0)).join("+")}] فضلة ${b.wasteLengthCm.toStringAsFixed(0)}سم')
          .join('\n');

      for (int c = 0; c < pCols.length; c++) {
        final Rect cr = Rect.fromLTWH(cx - pCols[c], curY, pCols[c], rowH);
        canvas.drawRect(cr, Paint()..color = Colors.white);
        canvas.drawRect(cr, borderPaint);

        if (c == 0) {
          final uiImg = prof.svgAssetPath != null
              ? profileImages[prof.svgAssetPath!]
              : null;
          if (uiImg != null) {
            paintImage(
              canvas: canvas,
              rect: cr.deflate(6),
              image: uiImg,
              fit: BoxFit.contain,
            );
          }
        } else if (c == 1) {
          _drawTextInRect(
            canvas,
            cr,
            '${prof.partName}\n(${prof.sectorName})',
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
          );
        } else if (c == 2) {
          _drawTextInRect(
            canvas,
            cr,
            lengthsText,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          );
        } else if (c == 3) {
          canvas.drawRect(cr.deflate(2), Paint()..color = const Color(0xFFFEF3C7));
          _drawTextInRect(
            canvas,
            cr,
            '${prof.totalBarsNeeded} عود',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFB45309),
          );
        } else if (c == 4) {
          _drawTextInRect(
            canvas,
            cr,
            barsSummary,
            fontSize: 11.5,
            color: const Color(0xFF334155),
          );
        }

        cx -= pCols[c];
      }
      curY += rowH;
    }

    // ثانياً: جدول مقاسات الزجاج الصافية (شاملاً زجاج الضلف وزجاج الثوابت)
    curY += 18;
    _drawTextInRect(
      canvas,
      Rect.fromLTWH(40, curY, canvasW - 80, 32),
      'ثانياً: كشف مقاسات الزجاج الصافية والنوع والعدد:',
      fontSize: 19,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF15803D),
      textAlign: TextAlign.right,
    );
    curY += 34;

    final List<double> gCols = [120, 260, 280, 220, 280];
    final List<String> gHeaders = [
      'الرمز',
      'القطاع والفتحة',
      'مقاس اللوح الصافي (عرض × ارتفاع)',
      'عدد الألواح',
      'نوع ومواصفات الزجاج',
    ];

    rx = canvasW - 40;
    for (int c = 0; c < gCols.length; c++) {
      final Rect hr = Rect.fromLTWH(rx - gCols[c], curY, gCols[c], 34);
      canvas.drawRect(hr, Paint()..color = const Color(0xFF15803D));
      canvas.drawRect(hr, borderPaint);
      _drawTextInRect(
        canvas,
        hr,
        gHeaders[c],
        fontSize: 14.5,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      );
      rx -= gCols[c];
    }
    curY += 34;

    for (final item in client.items) {
      if (!item.hasGlass) continue;
      if (curY + 34 > canvasH - 40) break;

      final sec = storage.getSectorById(item.sectorId);
      final double gw = sec != null
          ? sec.calculateGlassWidthCm(item.netOperableWidthCm, item.sashCount)
          : (item.netOperableWidthCm / item.sashCount) - 10.0;
      final double gh = sec != null
          ? sec.calculateGlassHeightCm(item.netOperableHeightCm, item.sashCount)
          : item.netOperableHeightCm - 18.0;
      final int panes =
          item.sashCount * (item.isDoubleGlass ? 2 : 1) * item.quantity;

      final List<String> gVals = [
        item.label,
        '${item.openType} ${item.sashCount} ضلفة (${item.sectorName})',
        '${gw.toStringAsFixed(1)} × ${gh.toStringAsFixed(1)} سم',
        '$panes لوح (${item.isDoubleGlass ? "دبل" : "سنجل"})',
        item.glassSummaryText.replaceAll('\n', ' '),
      ];

      double cx = canvasW - 40;
      for (int c = 0; c < gCols.length; c++) {
        final Rect cr = Rect.fromLTWH(cx - gCols[c], curY, gCols[c], 34);
        canvas.drawRect(cr, Paint()..color = Colors.white);
        canvas.drawRect(cr, borderPaint);
        _drawTextInRect(
          canvas,
          cr,
          gVals[c],
          fontSize: 13.5,
          fontWeight: FontWeight.bold,
        );
        cx -= gCols[c];
      }
      curY += 34;
    }

    final picture = recorder.endRecording();
    final uiImage = await picture.toImage(canvasW.toInt(), canvasH.toInt());
    final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  /// نافذة خيارات حفظ ومشاركة ومعاينة الـ PDF (مع فتح مدير الملفات لاختيار مكان الحفظ!)
  static Future<void> showPdfExportOptionsSheet({
    required BuildContext context,
    required String title,
    required String defaultFileName,
    required Future<Uint8List> Function() buildBytes,
  }) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        bool isBusy = false;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.picture_as_pdf,
                          color: Color(0xFF991B1B), size: 26),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      if (isBusy)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        ),
                    ],
                  ),
                  const Divider(height: 20),

                  // الخيار 1: اختيار مكان الحفظ في مدير الملفات
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF15803D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    onPressed: isBusy
                        ? null
                        : () async {
                            setSheetState(() => isBusy = true);
                            final bytes = await buildBytes();
                            final savedUri =
                                await NativeFileService.savePdfWithFilePicker(
                              fileName: defaultFileName,
                              bytes: bytes,
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (context.mounted && savedUri != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: const Color(0xFF15803D),
                                  content: Text(
                                      '✅ تم حفظ ملف الـ PDF بنجاح في المكان المختار ($defaultFileName)'),
                                ),
                              );
                            }
                          },
                    icon: const Icon(Icons.folder_open),
                    label: const Text(
                      'اختر مكان الحفظ في مدير الملفات (حفظ باسم...)',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // الخيار 2: حفظ مباشر في مجلد التنزيلات (Downloads) ومعاينة/طباعة
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D4ED8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: isBusy
                        ? null
                        : () async {
                            setSheetState(() => isBusy = true);
                            final bytes = await buildBytes();
                            final path =
                                await NativeFileService.savePdfToDownloadsDirect(
                              fileName: defaultFileName,
                              bytes: bytes,
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('✅ تم الحفظ في التنزيلات: $path'),
                                ),
                              );
                            }
                            await Printing.layoutPdf(
                              name: defaultFileName,
                              onLayout: (_) async => bytes,
                            );
                          },
                    icon: const Icon(Icons.print),
                    label: const Text(
                      'حفظ تلقائي في التنزيلات (Download) + معاينة وطباعة',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // الخيار 3: مشاركة عبر واتساب أو تليجرام
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: isBusy
                        ? null
                        : () async {
                            setSheetState(() => isBusy = true);
                            final bytes = await buildBytes();
                            final tmpFile =
                                await NativeFileService.saveTempPdfForShare(
                              fileName: defaultFileName,
                              bytes: bytes,
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                            await Share.shareXFiles(
                              [XFile(tmpFile.path)],
                              text: title,
                            );
                          },
                    icon: const Icon(Icons.share),
                    label: const Text(
                      'مشاركة الملف عبر واتساب / تليجرام / تطبيقات أخرى',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // دوال التوافق المباشرة
  static Future<File> savePdfToDevice({
    required Uint8List bytes,
    required String filename,
  }) async {
    await NativeFileService.savePdfToDownloadsDirect(
      fileName: filename,
      bytes: bytes,
    );
    return NativeFileService.saveTempPdfForShare(
      fileName: filename,
      bytes: bytes,
    );
  }

  static Future<File> savePdfToDeviceStorage({
    required Uint8List bytes,
    required String fileName,
  }) =>
      savePdfToDevice(bytes: bytes, filename: fileName);

  static Future<void> printOrSharePdf({
    required Uint8List bytes,
    required String filename,
  }) async {
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }

  static Future<void> previewPdfBytes(Uint8List bytes, String fileName) async {
    await Printing.layoutPdf(name: fileName, onLayout: (_) async => bytes);
  }

  static Future<Uint8List> buildOrderAndCuttingPdfBytes({
    required ClientRecord client,
    required WorkshopStorage storage,
  }) =>
      buildCuttingListPdfBytes(client: client, storage: storage);

  static Future<void> generateAndShareBothPdfs({
    required ClientRecord client,
    required WorkshopStorage storage,
  }) async {
    final quoteBytes =
        await buildQuotationPdfBytes(client: client, storage: storage);
    final orderBytes =
        await buildCuttingListPdfBytes(client: client, storage: storage);
    final f1 = await savePdfToDevice(
        bytes: quoteBytes,
        filename: 'عرض_سعر_شركة_الحافظ_${client.clientName}.pdf');
    final f2 = await savePdfToDevice(
        bytes: orderBytes,
        filename: 'كشف_طلبية_شركة_الحافظ_${client.clientName}.pdf');
    await Share.shareXFiles(
      [XFile(f1.path), XFile(f2.path)],
      text: 'عرض سعر وطلبية العميل: ${client.clientName}',
    );
  }
}
