import 'dart:math' as math;

/// جزء أو بروفايل داخل القطاع (حلق ببار، حلق بدون بار، ضلفة شباك، ضلفة باب، سكينة، تجميع، سؤاس، باكتة، ضلفة سلك...)
class SectorPart {
  String id;
  String name;
  String role; // حلق | ضلفة | سكينة | منخل | سؤاس | باكتة | تجميع | بار | مكمل
  String dimensionBasis; // width | height | net_width | net_height | net_width_per_sash | width_per_sash | fixed_perimeter | fixed
  double offsetCm; // قيمة التخصيم أو الزيادة بالسنتيمتر
  int quantityPerWindow;
  bool multiplyBySashes;
  String? svgAssetPath; // مسار رسمة مقطع الألومنيوم (SVG/PNG)
  String condition; // all | with_bar | without_bar | window_only | door_only | fly_screen | fixed_only | single_glass | double_glass

  SectorPart({
    required this.id,
    required this.name,
    required this.role,
    required this.dimensionBasis,
    double? offsetCm,
    double? deductFromWidthCm,
    double? deductFromHeightCm,
    int? quantityPerWindow,
    int? multiplier,
    this.multiplyBySashes = false,
    double? addPerSashCm,
    this.svgAssetPath,
    this.condition = 'all',
  })  : offsetCm = offsetCm ??
            (-(deductFromWidthCm ?? deductFromHeightCm ?? -(addPerSashCm ?? 0.0))),
        quantityPerWindow = quantityPerWindow ?? multiplier ?? 1;

  double get deductFromWidthCm => -offsetCm;
  double get deductFromHeightCm => -offsetCm;
  int get multiplier => quantityPerWindow;
  double get addPerSashCm => offsetCm;

  /// حساب طول القطعة بالسنتيمتر مع مراعاة صافي المتحرك بعد خصم الثوابت إن وجدت
  double calculatePieceLength(
    double totalWidthCm,
    double totalHeightCm,
    int sashCount, {
    double netWidthCm = 0,
    double netHeightCm = 0,
  }) {
    final int safeSashes = sashCount > 0 ? sashCount : 1;
    final double effNetW = netWidthCm > 0 ? netWidthCm : totalWidthCm;
    final double effNetH = netHeightCm > 0 ? netHeightCm : totalHeightCm;

    double baseVal = 0.0;
    switch (dimensionBasis) {
      case 'width':
        baseVal = totalWidthCm;
        break;
      case 'height':
        baseVal = totalHeightCm;
        break;
      case 'net_width':
        baseVal = effNetW;
        break;
      case 'net_height':
        baseVal = effNetH;
        break;
      case 'net_width_per_sash':
      case 'width_per_sash':
        baseVal = effNetW / safeSashes;
        break;
      case 'height_per_sash':
        baseVal = effNetH / safeSashes;
        break;
      case 'fixed':
        baseVal = 0.0;
        break;
      default:
        baseVal = totalWidthCm;
    }
    final double result = baseVal + offsetCm;
    return result > 0 ? double.parse(result.toStringAsFixed(2)) : 0.0;
  }

  int calculateTotalCount(int windowQuantity, int sashCount) {
    final int safeWindows = windowQuantity > 0 ? windowQuantity : 1;
    final int safeSashes = sashCount > 0 ? sashCount : 1;
    final int perWindow = multiplyBySashes
        ? (quantityPerWindow * safeSashes)
        : quantityPerWindow;
    return perWindow * safeWindows;
  }

  int calculateTotalPieces(int sashCount) => calculateTotalCount(1, sashCount);

  String get basisArabicLabel {
    switch (dimensionBasis) {
      case 'width':
        return 'العرض الكلي (W)';
      case 'height':
        return 'الارتفاع الكلي (H)';
      case 'net_width':
        return 'صافي عرض المتحرك';
      case 'net_height':
        return 'صافي ارتفاع المتحرك';
      case 'net_width_per_sash':
      case 'width_per_sash':
        return 'صافي العرض ÷ عدد الضلف';
      case 'height_per_sash':
        return 'صافي الارتفاع ÷ عدد الضلف';
      case 'fixed':
        return 'طول ثابت (سم)';
      default:
        return 'العرض الكلي (W)';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role,
        'dimensionBasis': dimensionBasis,
        'offsetCm': offsetCm,
        'quantityPerWindow': quantityPerWindow,
        'multiplyBySashes': multiplyBySashes,
        'svgAssetPath': svgAssetPath,
        'condition': condition,
      };

  factory SectorPart.fromJson(Map<String, dynamic> json) => SectorPart(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        role: json['role']?.toString() ?? 'حلق',
        dimensionBasis: json['dimensionBasis']?.toString() ?? 'width',
        offsetCm: (json['offsetCm'] as num?)?.toDouble() ??
            (-(json['deductFromWidthCm'] as num? ?? 0.0).toDouble()),
        quantityPerWindow: (json['quantityPerWindow'] as num?)?.toInt() ??
            (json['multiplier'] as num?)?.toInt() ??
            1,
        multiplyBySashes: json['multiplyBySashes'] == true,
        svgAssetPath: json['svgAssetPath']?.toString(),
        condition: json['condition']?.toString() ?? 'all',
      );
}

/// تعريف القطاع الكامل (مع شعار الشركة، صور مقاطع البروفايل، ورابط الكتالوج)
class SectorProfile {
  String id;
  String name;
  String shortPdfName; // الاسم المختصر في جدول عرض السعر (مثل: UPVC كبير / صغير P.S)
  String category; // منزلق | مفصلي | مطبخ | ثابت
  String companyGroup; // قطاعات السعد PS | مركز الماكينات - الشارقة | فالف القباري | الدولية 21 ماكسيم | ألوميل | فولكانو | UPVC المصري | UPVC المستورد
  String systemType; // شباك جرار | شباك مفصلي | باب مفصلي | قلاب | مطبخ
  int defaultSashCount;
  String? imagePath; // مسار صورة مخصصة أو شعار الشركة
  String? companyLogoAsset; // شعار الشركة من assets/images/windows/systems/
  String? profileSvgFolder; // مجلد رسومات مقاطع البروفايل في assets/images/svg/profiles/
  String catalogUrl; // رابط كتالوج القطاع الرسمي
  double pricePerSquareMeter;
  double barPrice; // سعر العود القياسي (اختياري لحساب تكلفة الخامات)
  double glassWidthDeductCm;
  double glassHeightDeductCm;
  bool isCustom;
  List<SectorPart> parts;

  SectorProfile({
    required this.id,
    required this.name,
    String? shortPdfName,
    this.category = 'منزلق',
    required this.companyGroup,
    required this.systemType,
    this.defaultSashCount = 2,
    this.imagePath,
    this.companyLogoAsset,
    this.profileSvgFolder,
    this.catalogUrl = '',
    required this.pricePerSquareMeter,
    this.barPrice = 1450.0,
    this.glassWidthDeductCm = 11.4,
    this.glassHeightDeductCm = 11.4,
    this.isCustom = false,
    required this.parts,
  }) : shortPdfName = shortPdfName ?? name;

  bool get isDoor => systemType.contains('باب');
  bool get isSliding =>
      category.contains('منزلق') ||
      category.contains('جرار') ||
      systemType.contains('جرار') ||
      systemType.contains('منزلق');
  bool get isHinged =>
      category.contains('مفصلي') ||
      systemType.contains('مفصلي') ||
      systemType.contains('قلاب');

  /// صورة المقطع الرئيسية للقطاع
  String? get primaryProfileSvg {
    for (final p in parts) {
      if (p.svgAssetPath != null && p.svgAssetPath!.isNotEmpty) {
        return p.svgAssetPath;
      }
    }
    if (profileSvgFolder != null && profileSvgFolder!.isNotEmpty) {
      return '$profileSvgFolder/001.svg';
    }
    return null;
  }

  double calculateSingleSashWidth(double netWidthCm, int sashCount) {
    for (final p in parts) {
      if (p.role == 'ضلفة' || p.role == 'درفة') {
        if (p.dimensionBasis == 'net_width_per_sash' ||
            p.dimensionBasis == 'width_per_sash' ||
            p.dimensionBasis == 'width') {
          return p.calculatePieceLength(
            netWidthCm,
            0,
            sashCount,
            netWidthCm: netWidthCm,
          );
        }
      }
    }
    final int safeSashes = sashCount > 0 ? sashCount : 1;
    return (netWidthCm / safeSashes) + (isSliding ? 1.5 : -4.8);
  }

  double calculateSingleSashHeight(double netHeightCm, int sashCount) {
    for (final p in parts) {
      if ((p.role == 'ضلفة' || p.role == 'درفة') &&
          (p.dimensionBasis == 'height' || p.dimensionBasis == 'net_height')) {
        return p.calculatePieceLength(
          0,
          netHeightCm,
          sashCount,
          netHeightCm: netHeightCm,
        );
      }
    }
    return math.max(0.0, netHeightCm - (isSliding ? 8.2 : 4.8));
  }

  double calculateGlassWidthCm(double netWidthCm, int sashCount) {
    final double sashW = calculateSingleSashWidth(netWidthCm, sashCount);
    return math.max(
        0.0, double.parse((sashW - glassWidthDeductCm).toStringAsFixed(2)));
  }

  double calculateGlassHeightCm(double netHeightCm, int sashCount) {
    final double sashH = calculateSingleSashHeight(netHeightCm, sashCount);
    return math.max(
        0.0, double.parse((sashH - glassHeightDeductCm).toStringAsFixed(2)));
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'shortPdfName': shortPdfName,
        'category': category,
        'companyGroup': companyGroup,
        'systemType': systemType,
        'defaultSashCount': defaultSashCount,
        'imagePath': imagePath,
        'companyLogoAsset': companyLogoAsset,
        'profileSvgFolder': profileSvgFolder,
        'catalogUrl': catalogUrl,
        'pricePerSquareMeter': pricePerSquareMeter,
        'barPrice': barPrice,
        'glassWidthDeductCm': glassWidthDeductCm,
        'glassHeightDeductCm': glassHeightDeductCm,
        'isCustom': isCustom,
        'parts': parts.map((e) => e.toJson()).toList(),
      };

  factory SectorProfile.fromJson(Map<String, dynamic> json) => SectorProfile(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        shortPdfName: json['shortPdfName'] ?? json['name'] ?? '',
        category: json['category'] ?? 'منزلق',
        companyGroup: json['companyGroup'] ?? json['category'] ?? 'عام',
        systemType: json['systemType'] ?? json['category'] ?? 'شباك جرار',
        defaultSashCount: json['defaultSashCount'] ?? 2,
        imagePath: json['imagePath'],
        companyLogoAsset: json['companyLogoAsset'],
        profileSvgFolder: json['profileSvgFolder'],
        catalogUrl: json['catalogUrl']?.toString() ?? '',
        pricePerSquareMeter:
            (json['pricePerSquareMeter'] as num?)?.toDouble() ?? 4500.0,
        barPrice: (json['barPrice'] as num?)?.toDouble() ?? 1450.0,
        glassWidthDeductCm:
            (json['glassWidthDeductCm'] as num?)?.toDouble() ?? 11.4,
        glassHeightDeductCm:
            (json['glassHeightDeductCm'] as num?)?.toDouble() ?? 11.4,
        isCustom: json['isCustom'] ?? false,
        parts: (json['parts'] as List<dynamic>?)
                ?.map((e) => SectorPart.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            [],
      );
}

/// نوع الزجاج في قائمة التسعير
class GlassTypeItem {
  String id;
  String name; // مثل: دبل عاكس أخضر على شفاف / سنجل مصنفر
  double pricePerSquareMeter;
  String thickness;
  String color;
  bool isDoublePreset; // هل هو توصيف دبل جاهز؟

  GlassTypeItem({
    required this.id,
    required this.name,
    required this.pricePerSquareMeter,
    this.thickness = '6 مم',
    this.color = 'شفاف',
    this.isDoublePreset = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'pricePerSquareMeter': pricePerSquareMeter,
        'thickness': thickness,
        'color': color,
        'isDoublePreset': isDoublePreset,
      };

  factory GlassTypeItem.fromJson(Map<String, dynamic> json) => GlassTypeItem(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        pricePerSquareMeter:
            (json['pricePerSquareMeter'] as num?)?.toDouble() ?? 500.0,
        thickness: json['thickness'] ?? '6 مم',
        color: json['color'] ?? 'شفاف',
        isDoublePreset: json['isDoublePreset'] ?? false,
      );
}

/// بند إكسسوار أو إضافات في قائمة التسعير
class AccessoryPriceItem {
  String id;
  String name;
  String unit; // متر مربع | متر طولي | قطعة | طقم
  double price;

  AccessoryPriceItem({
    required this.id,
    required this.name,
    required this.unit,
    required this.price,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'unit': unit,
        'price': price,
      };

  factory AccessoryPriceItem.fromJson(Map<String, dynamic> json) =>
      AccessoryPriceItem(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        unit: json['unit'] ?? 'قطعة',
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
      );
}

/// إعدادات التسعير والورشة الشاملة
class PricingSettings {
  double doubleSpacerPricePerMeter;
  double georgianBarPricePerMeter;
  double flyScreenPricePerM2;
  double shutterPricePerM2;
  double exhaustFanPrice;
  double defaultArchPrice;
  double defaultStockBarLengthCm;
  double defaultSawKerfMm;
  bool enforceMinimumOneSquareMeter;

  String companyName;
  String companySubtitle;
  String companyPhones;
  String companyAddress;
  String pdfNoteLine1;
  String pdfNoteLine2;
  String pdfNoteLine3;
  String pdfNoteLine4;
  String pdfNoteLine5;
  String pdfNoteLine6;
  String termsAndConditions;

  PricingSettings({
    this.doubleSpacerPricePerMeter = 45.0,
    this.georgianBarPricePerMeter = 85.0,
    this.flyScreenPricePerM2 = 250.0,
    this.shutterPricePerM2 = 1800.0,
    this.exhaustFanPrice = 350.0,
    this.defaultArchPrice = 600.0,
    this.defaultStockBarLengthCm = 600.0,
    this.defaultSawKerfMm = 4.0,
    this.enforceMinimumOneSquareMeter = true,
    this.companyName = 'شركة الحافظ',
    this.companySubtitle =
        'للمطابخ الألومنيوم والخشب وجميع أعمال الأخشاب والواجهات الزجاجية',
    this.companyPhones = '01000000000 - 01200000000',
    this.companyAddress = 'جمهورية مصر العربية',
    this.pdfNoteLine1 = 'ملحوظة هامة : السعر لا يشمل النقل والمشال',
    this.pdfNoteLine2 =
        'نوع القطاع Emapen الحاصل على شهادة الايزو ISO 9001 + جميع الاكسسوارات تركية الصنع',
    this.pdfNoteLine3 = 'ضمان ٢٠ سنة على القطاع + ٥ أعوام على الاكسسوارات',
    this.pdfNoteLine4 = 'القطاعات كلها مدعمة بكاوتش مدمج بها',
    this.pdfNoteLine5 =
        'القطاعات كلها مدعمة بحديد مجلفن سماكة ١.٢٥ ملل من الداخل',
    this.pdfNoteLine6 = 'الاسعار غير شاملة الضريبة',
    this.termsAndConditions =
        'عند التعاقد دفعة ٦٠ % // عند التوريد دفعة ٣٠ % // عند التسليم دفعة ١٠ %',
  });

  Map<String, dynamic> toJson() => {
        'doubleSpacerPricePerMeter': doubleSpacerPricePerMeter,
        'georgianBarPricePerMeter': georgianBarPricePerMeter,
        'flyScreenPricePerM2': flyScreenPricePerM2,
        'shutterPricePerM2': shutterPricePerM2,
        'exhaustFanPrice': exhaustFanPrice,
        'defaultArchPrice': defaultArchPrice,
        'defaultStockBarLengthCm': defaultStockBarLengthCm,
        'defaultSawKerfMm': defaultSawKerfMm,
        'enforceMinimumOneSquareMeter': enforceMinimumOneSquareMeter,
        'companyName': companyName,
        'companySubtitle': companySubtitle,
        'companyPhones': companyPhones,
        'companyAddress': companyAddress,
        'pdfNoteLine1': pdfNoteLine1,
        'pdfNoteLine2': pdfNoteLine2,
        'pdfNoteLine3': pdfNoteLine3,
        'pdfNoteLine4': pdfNoteLine4,
        'pdfNoteLine5': pdfNoteLine5,
        'pdfNoteLine6': pdfNoteLine6,
        'termsAndConditions': termsAndConditions,
      };

  factory PricingSettings.fromJson(Map<String, dynamic> json) => PricingSettings(
        doubleSpacerPricePerMeter:
            (json['doubleSpacerPricePerMeter'] as num?)?.toDouble() ?? 45.0,
        georgianBarPricePerMeter:
            (json['georgianBarPricePerMeter'] as num?)?.toDouble() ?? 85.0,
        flyScreenPricePerM2:
            (json['flyScreenPricePerM2'] as num?)?.toDouble() ?? 250.0,
        shutterPricePerM2:
            (json['shutterPricePerM2'] as num?)?.toDouble() ?? 1800.0,
        exhaustFanPrice:
            (json['exhaustFanPrice'] as num?)?.toDouble() ?? 350.0,
        defaultArchPrice:
            (json['defaultArchPrice'] as num?)?.toDouble() ?? 600.0,
        defaultStockBarLengthCm:
            (json['defaultStockBarLengthCm'] as num?)?.toDouble() ?? 600.0,
        defaultSawKerfMm:
            (json['defaultSawKerfMm'] as num?)?.toDouble() ?? 4.0,
        enforceMinimumOneSquareMeter:
            json['enforceMinimumOneSquareMeter'] ?? true,
        companyName: json['companyName'] ?? 'شركة الحافظ',
        companySubtitle: json['companySubtitle'] ??
            'للمطابخ الألومنيوم والخشب وجميع أعمال الأخشاب والواجهات الزجاجية',
        companyPhones: json['companyPhones'] ?? '01000000000 - 01200000000',
        companyAddress: json['companyAddress'] ?? 'جمهورية مصر العربية',
        pdfNoteLine1:
            json['pdfNoteLine1'] ?? 'ملحوظة هامة : السعر لا يشمل النقل والمشال',
        pdfNoteLine2: json['pdfNoteLine2'] ??
            'نوع القطاع Emapen الحاصل على شهادة الايزو ISO 9001 + جميع الاكسسوارات تركية الصنع',
        pdfNoteLine3: json['pdfNoteLine3'] ??
            'ضمان ٢٠ سنة على القطاع + ٥ أعوام على الاكسسوارات',
        pdfNoteLine4:
            json['pdfNoteLine4'] ?? 'القطاعات كلها مدعمة بكاوتش مدمج بها',
        pdfNoteLine5: json['pdfNoteLine5'] ??
            'القطاعات كلها مدعمة بحديد مجلفن سماكة ١.٢٥ ملل من الداخل',
        pdfNoteLine6: json['pdfNoteLine6'] ?? 'الاسعار غير شاملة الضريبة',
        termsAndConditions: json['termsAndConditions'] ??
            'عند التعاقد دفعة ٦٠ % // عند التوريد دفعة ٣٠ % // عند التسليم دفعة ١٠ %',
      );
}

/// عنصر شباك أو باب في الورشة الذكية ومقايسة العميل
class ClientWindowItem {
  String id;
  String label;
  String unitType; // شباك | باب | مطبخ
  String openType; // جرار | مفصلي | قلاب | ثابت
  String barType; // ببار | بدون بار | بار مقلوب | تجميع
  String openDirection; // يمين للداخل | شمال للداخل | يمين للخارج | شمال للخارج | قلاب لأعلى
  String sectorId;
  String sectorName;
  String customPdfDescription; // التوصيف المطبوع في عمود "توصيف" بملف الـ PDF
  double sectorPricePerM2; // سعر المتر المربع المعتمد في الجدول (شامل أو قطاع فقط)
  bool isCombinedMeterPrice; // إذا كان true فإن sectorPricePerM2 هو سعر المتر النهائي مباشرة (مثل 5500 أو 4500)
  String sectorColor; // بيج | أسود | أبيض | رمادي | خشابي | فضي | شامبين
  double widthCm;
  double heightCm;
  int quantity;
  int sashCount;
  int trackCount; // 2 أو 3 سكة للجرار
  bool hasFlyScreen; // بسلك / بدون سلك
  bool hasShutter; // شيش حصيرة

  // الثوابت في جميع الاتجاهات (شمال، يمين، فوق، تحت) مع مقاسها وعدد تقسيماتها
  bool hasTopFixed;
  double topFixedHeightCm;
  int topFixedSplits; // عدد قواطيع الثابت العلوي (1 = قطعة واحدة، 2 = مقسوم قطعتين...)

  bool hasBottomFixed;
  double bottomFixedHeightCm;
  int bottomFixedSplits;

  bool hasRightFixed;
  double rightFixedWidthCm;
  int rightFixedSplits;

  bool hasLeftFixed;
  double leftFixedWidthCm;
  int leftFixedSplits;

  // الشفاط
  bool hasExhaustFan;
  String exhaustFanShape; // دائري | مربع
  double exhaustFanDiameterCm;
  String exhaustFanPosition; // في الثابت العلوي | في الضلفة يمين | في الضلفة شمال | في المنتصف

  // الزجاج
  bool hasGlass;
  bool isDoubleGlass;
  String? glass1Id;
  String glass1Name; // مثل: دبل عاكس أخضر على شفاف / سنجل مصنفر
  double glass1PricePerM2;
  String? glass2Id;
  String glass2Name;
  double glass2PricePerM2;
  double spacerPricePerMeter;

  // الجورجيا
  bool hasGeorgianBars;
  double georgianMetersPerWindow;
  double georgianPricePerMeter;

  ClientWindowItem({
    required this.id,
    required this.label,
    this.unitType = 'شباك',
    this.openType = 'جرار',
    this.barType = 'ببار',
    this.openDirection = 'يمين للداخل',
    required this.sectorId,
    required this.sectorName,
    this.customPdfDescription = '',
    required this.sectorPricePerM2,
    this.isCombinedMeterPrice = true,
    this.sectorColor = 'بيج',
    required this.widthCm,
    required this.heightCm,
    this.quantity = 1,
    this.sashCount = 2,
    this.trackCount = 2,
    this.hasFlyScreen = true,
    this.hasShutter = false,
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
    this.isDoubleGlass = true,
    this.glass1Id,
    this.glass1Name = 'دبل عاكس أخضر على شفاف',
    this.glass1PricePerM2 = 0.0,
    this.glass2Id,
    this.glass2Name = 'شفاف 6 مم',
    this.glass2PricePerM2 = 0.0,
    this.spacerPricePerMeter = 45.0,
    this.hasGeorgianBars = false,
    this.georgianMetersPerWindow = 0.0,
    this.georgianPricePerMeter = 85.0,
  });

  /// صافي عرض الجزء المتحرك بعد خصم الثابت اليمين والثابت الشمال
  double get netOperableWidthCm {
    double w = widthCm;
    if (hasRightFixed) w -= rightFixedWidthCm;
    if (hasLeftFixed) w -= leftFixedWidthCm;
    return math.max(20.0, w);
  }

  /// صافي ارتفاع الجزء المتحرك بعد خصم الثابت العلوي والثابت السفلي
  double get netOperableHeightCm {
    double h = heightCm;
    if (hasTopFixed) h -= topFixedHeightCm;
    if (hasBottomFixed) h -= bottomFixedHeightCm;
    return math.max(20.0, h);
  }

  /// مساحة الشباك الواحد بالمتر المربع (مع جبر الأقل من 1 م² إلى 1.00 م² عند التفعيل)
  double singleWindowAreaM2({bool minOneM2 = true}) {
    final double rawArea = (widthCm / 100.0) * (heightCm / 100.0);
    if (minOneM2 && rawArea < 1.0) {
      return 1.0;
    }
    return rawArea;
  }

  /// المساحة المطبوعة في جدول عرض السعر (منزلتين عشريتين)
  double displaySingleAreaM2({bool minOneM2 = true}) {
    return double.parse(
        singleWindowAreaM2(minOneM2: minOneM2).toStringAsFixed(2));
  }

  double totalAreaM2({bool minOneM2 = true}) =>
      singleWindowAreaM2(minOneM2: minOneM2) * quantity;

  double displayTotalAreaM2({bool minOneM2 = true}) =>
      displaySingleAreaM2(minOneM2: minOneM2) * quantity;

  double totalSpacerMeters(SectorProfile? sector) {
    if (!hasGlass || !isDoubleGlass) return 0.0;
    final double gwCm = sector != null
        ? sector.calculateGlassWidthCm(netOperableWidthCm, sashCount)
        : math.max(0.0,
            (netOperableWidthCm / (sashCount > 0 ? sashCount : 1)) - 10.0);
    final double ghCm = sector != null
        ? sector.calculateGlassHeightCm(netOperableHeightCm, sashCount)
        : math.max(0.0, netOperableHeightCm - 18.0);
    final double singleSashPerimeterM = 2.0 * ((gwCm + ghCm) / 100.0);
    return singleSashPerimeterM * (sashCount > 0 ? sashCount : 1) * quantity;
  }

  /// سعر المتر النهائي المطبوع في عمود "سعر المتر"
  double effectiveMeterPrice(SectorProfile? sector) {
    if (isCombinedMeterPrice) {
      return sectorPricePerM2;
    }
    double p = sectorPricePerM2;
    if (hasGlass) {
      p += glass1PricePerM2;
      if (isDoubleGlass && glass2PricePerM2 > 0) {
        p += glass2PricePerM2;
      }
    }
    return p;
  }

  double calculateSectorCost({bool minOneM2 = true}) =>
      totalAreaM2(minOneM2: minOneM2) * sectorPricePerM2;

  double calculateGlassAndSpacerCost(SectorProfile? sector,
      {bool minOneM2 = true}) {
    if (isCombinedMeterPrice || !hasGlass) return 0.0;
    final double area = totalAreaM2(minOneM2: minOneM2);
    if (!isDoubleGlass) {
      return area * glass1PricePerM2;
    } else {
      final double panesCost = area * (glass1PricePerM2 + glass2PricePerM2);
      final double spacerCost = totalSpacerMeters(sector) * spacerPricePerMeter;
      return panesCost + spacerCost;
    }
  }

  double calculateGeorgianCost() {
    if (isCombinedMeterPrice || !hasGeorgianBars || georgianMetersPerWindow <= 0) {
      return 0.0;
    }
    return georgianMetersPerWindow * quantity * georgianPricePerMeter;
  }

  /// إجمالي سعر البند (مطابق تماماً لحساب أ. احمد ابو اليزيد.pdf: المساحة الفعلية × سعر المتر مقرباً لأقرب جنيه)
  double calculateTotalCost(SectorProfile? sector, {bool minOneM2 = true}) {
    if (isCombinedMeterPrice) {
      final double singleArea = singleWindowAreaM2(minOneM2: minOneM2);
      final double singleUnitCost = (singleArea * sectorPricePerM2).roundToDouble();
      return singleUnitCost * quantity;
    }
    return (calculateSectorCost(minOneM2: minOneM2) +
            calculateGlassAndSpacerCost(sector, minOneM2: minOneM2) +
            calculateGeorgianCost())
        .roundToDouble();
  }

  /// التوصيف المطبوع في عمود "توصيف" في ملف الـ PDF
  String pdfDescriptionText(SectorProfile? sector) {
    if (customPdfDescription.trim().isNotEmpty) {
      return customPdfDescription.trim();
    }
    final String shortSec = sector?.shortPdfName ?? sectorName;
    final String sCount = _toArabicDigits('$sashCount');
    return '$openType $sCount ضلفة\n$shortSec';
  }

  static String _toArabicDigits(String input) {
    const en = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const ar = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    String out = input;
    for (int i = 0; i < 10; i++) {
      out = out.replaceAll(en[i], ar[i]);
    }
    return out;
  }

  /// النص المطبوع في عمود "نوع الزجاج" في ملف الـ PDF
  String get glassSummaryText {
    if (!hasGlass) return 'بدون زجاج';
    return glass1Name;
  }

  String get configurationSummary {
    final List<String> list = [];
    list.add('$unitType $openType $sashCount ضلفة');
    if (hasTopFixed) list.add('ثابت فوق (${topFixedHeightCm.toStringAsFixed(0)} سم)');
    if (hasBottomFixed) list.add('ثابت تحت (${bottomFixedHeightCm.toStringAsFixed(0)} سم)');
    if (hasRightFixed) list.add('ثابت يمين (${rightFixedWidthCm.toStringAsFixed(0)} سم)');
    if (hasLeftFixed) list.add('ثابت شمال (${leftFixedWidthCm.toStringAsFixed(0)} سم)');
    if (hasExhaustFan) list.add('شفاط $exhaustFanShape (${exhaustFanDiameterCm.toStringAsFixed(0)} سم)');
    return list.join(' • ');
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'unitType': unitType,
        'openType': openType,
        'barType': barType,
        'openDirection': openDirection,
        'sectorId': sectorId,
        'sectorName': sectorName,
        'customPdfDescription': customPdfDescription,
        'sectorPricePerM2': sectorPricePerM2,
        'isCombinedMeterPrice': isCombinedMeterPrice,
        'sectorColor': sectorColor,
        'widthCm': widthCm,
        'heightCm': heightCm,
        'quantity': quantity,
        'sashCount': sashCount,
        'trackCount': trackCount,
        'hasFlyScreen': hasFlyScreen,
        'hasShutter': hasShutter,
        'hasTopFixed': hasTopFixed,
        'topFixedHeightCm': topFixedHeightCm,
        'topFixedSplits': topFixedSplits,
        'hasBottomFixed': hasBottomFixed,
        'bottomFixedHeightCm': bottomFixedHeightCm,
        'bottomFixedSplits': bottomFixedSplits,
        'hasRightFixed': hasRightFixed,
        'rightFixedWidthCm': rightFixedWidthCm,
        'rightFixedSplits': rightFixedSplits,
        'hasLeftFixed': hasLeftFixed,
        'leftFixedWidthCm': leftFixedWidthCm,
        'leftFixedSplits': leftFixedSplits,
        'hasExhaustFan': hasExhaustFan,
        'exhaustFanShape': exhaustFanShape,
        'exhaustFanDiameterCm': exhaustFanDiameterCm,
        'exhaustFanPosition': exhaustFanPosition,
        'hasGlass': hasGlass,
        'isDoubleGlass': isDoubleGlass,
        'glass1Id': glass1Id,
        'glass1Name': glass1Name,
        'glass1PricePerM2': glass1PricePerM2,
        'glass2Id': glass2Id,
        'glass2Name': glass2Name,
        'glass2PricePerM2': glass2PricePerM2,
        'spacerPricePerMeter': spacerPricePerMeter,
        'hasGeorgianBars': hasGeorgianBars,
        'georgianMetersPerWindow': georgianMetersPerWindow,
        'georgianPricePerMeter': georgianPricePerMeter,
      };

  factory ClientWindowItem.fromJson(Map<String, dynamic> json) =>
      ClientWindowItem(
        id: json['id'] ?? '',
        label: json['label'] ?? 'شباك',
        unitType: json['unitType'] ?? 'شباك',
        openType: json['openType'] ?? 'جرار',
        barType: json['barType'] ?? 'ببار',
        openDirection: json['openDirection'] ?? 'يمين للداخل',
        sectorId: json['sectorId'] ?? '',
        sectorName: json['sectorName'] ?? '',
        customPdfDescription: json['customPdfDescription']?.toString() ?? '',
        sectorPricePerM2:
            (json['sectorPricePerM2'] as num?)?.toDouble() ?? 5500.0,
        isCombinedMeterPrice: json['isCombinedMeterPrice'] ?? true,
        sectorColor: json['sectorColor']?.toString() ?? 'بيج',
        widthCm: (json['widthCm'] as num?)?.toDouble() ?? 100.0,
        heightCm: (json['heightCm'] as num?)?.toDouble() ?? 100.0,
        quantity: json['quantity'] ?? 1,
        sashCount: json['sashCount'] ?? 2,
        trackCount: json['trackCount'] ?? 2,
        hasFlyScreen: json['hasFlyScreen'] ?? true,
        hasShutter: json['hasShutter'] ?? false,
        hasTopFixed: json['hasTopFixed'] ?? false,
        topFixedHeightCm:
            (json['topFixedHeightCm'] as num?)?.toDouble() ?? 40.0,
        topFixedSplits: (json['topFixedSplits'] as num?)?.toInt() ?? 1,
        hasBottomFixed: json['hasBottomFixed'] ?? false,
        bottomFixedHeightCm:
            (json['bottomFixedHeightCm'] as num?)?.toDouble() ?? 40.0,
        bottomFixedSplits: (json['bottomFixedSplits'] as num?)?.toInt() ?? 1,
        hasRightFixed: json['hasRightFixed'] ?? false,
        rightFixedWidthCm:
            (json['rightFixedWidthCm'] as num?)?.toDouble() ?? 40.0,
        rightFixedSplits: (json['rightFixedSplits'] as num?)?.toInt() ?? 1,
        hasLeftFixed: json['hasLeftFixed'] ?? false,
        leftFixedWidthCm:
            (json['leftFixedWidthCm'] as num?)?.toDouble() ?? 40.0,
        leftFixedSplits: (json['leftFixedSplits'] as num?)?.toInt() ?? 1,
        hasExhaustFan: json['hasExhaustFan'] ?? false,
        exhaustFanShape: json['exhaustFanShape'] ?? 'دائري',
        exhaustFanDiameterCm:
            (json['exhaustFanDiameterCm'] as num?)?.toDouble() ?? 25.0,
        exhaustFanPosition:
            json['exhaustFanPosition'] ?? 'في الثابت العلوي',
        hasGlass: json['hasGlass'] ?? true,
        isDoubleGlass: json['isDoubleGlass'] ?? true,
        glass1Id: json['glass1Id'],
        glass1Name: json['glass1Name'] ?? 'دبل عاكس أخضر على شفاف',
        glass1PricePerM2:
            (json['glass1PricePerM2'] as num?)?.toDouble() ?? 0.0,
        glass2Id: json['glass2Id'],
        glass2Name: json['glass2Name'] ?? 'شفاف 6 مم',
        glass2PricePerM2:
            (json['glass2PricePerM2'] as num?)?.toDouble() ?? 0.0,
        spacerPricePerMeter:
            (json['spacerPricePerMeter'] as num?)?.toDouble() ?? 45.0,
        hasGeorgianBars: json['hasGeorgianBars'] ?? false,
        georgianMetersPerWindow:
            (json['georgianMetersPerWindow'] as num?)?.toDouble() ?? 0.0,
        georgianPricePerMeter:
            (json['georgianPricePerMeter'] as num?)?.toDouble() ?? 85.0,
      );
}

/// سجل مقايسة وعرض سعر العميل وطلبية الورشة
class ClientRecord {
  String id;
  String clientName;
  String clientPhone;
  String clientAddress;
  String createdAt;
  String notes;
  double discountAmount;
  double depositAmount;
  double archCost;
  List<ClientWindowItem> items;

  ClientRecord({
    required this.id,
    required this.clientName,
    this.clientPhone = '',
    this.clientAddress = '',
    required this.createdAt,
    this.notes = '',
    this.discountAmount = 0.0,
    this.depositAmount = 0.0,
    this.archCost = 0.0,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'clientName': clientName,
        'clientPhone': clientPhone,
        'clientAddress': clientAddress,
        'createdAt': createdAt,
        'notes': notes,
        'discountAmount': discountAmount,
        'depositAmount': depositAmount,
        'archCost': archCost,
        'items': items.map((e) => e.toJson()).toList(),
      };

  factory ClientRecord.fromJson(Map<String, dynamic> json) => ClientRecord(
        id: json['id'] ?? '',
        clientName: json['clientName'] ?? '',
        clientPhone: json['clientPhone'] ?? '',
        clientAddress: json['clientAddress'] ?? '',
        createdAt: json['createdAt'] ?? '',
        notes: json['notes'] ?? '',
        discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
        depositAmount: (json['depositAmount'] as num?)?.toDouble() ?? 0.0,
        archCost: (json['archCost'] as num?)?.toDouble() ?? 0.0,
        items: (json['items'] as List<dynamic>?)
                ?.map((e) =>
                    ClientWindowItem.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            [],
      );
}

/// خطة تقطيع العود القياسي (600 سم أو 650 سم)
class BarCutPlan {
  int barNumber;
  int get barIndex => barNumber;
  set barIndex(int v) => barNumber = v;

  double barLengthCm;
  double kerfMm;

  List<double> cutsCm;
  List<double> get cutPiecesCm => cutsCm;
  set cutPiecesCm(List<double> v) => cutsCm = v;

  double usedLengthCm;
  double wasteLengthCm;
  double wastePercentage;

  BarCutPlan({
    int? barNumber,
    int? barIndex,
    this.barLengthCm = 600.0,
    this.kerfMm = 4.0,
    List<double>? cutsCm,
    List<double>? cutPiecesCm,
    required this.usedLengthCm,
    required this.wasteLengthCm,
    required this.wastePercentage,
  })  : barNumber = barNumber ?? barIndex ?? 1,
        cutsCm = cutsCm ?? cutPiecesCm ?? [];
}

/// ملخص تجميع وتقطيع بروفايل واحد في حساب الطلبية (الورشة الذكية)
class AggregatedProfileOrder {
  final String sectorName;
  final String partName;
  final String role;
  final String? svgAssetPath;
  final Map<double, int> lengthCounts; // الطول بالسنتيمتر -> العدد
  final List<double> allPiecesCm;
  final List<BarCutPlan> barPlans;

  AggregatedProfileOrder({
    required this.sectorName,
    required this.partName,
    required this.role,
    this.svgAssetPath,
    required this.lengthCounts,
    required this.allPiecesCm,
    required this.barPlans,
  });

  int get totalBarsNeeded => barPlans.length;
  int get totalPiecesCount => allPiecesCm.length;
}
