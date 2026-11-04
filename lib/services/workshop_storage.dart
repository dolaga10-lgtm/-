import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workshop_models.dart';

class WorkshopStorage extends ChangeNotifier {
  static const String _kSectorsKey = 'hafez_sw_sectors_v10';
  static const String _kGlassesKey = 'hafez_sw_glasses_v10';
  static const String _kAccessoriesKey = 'hafez_sw_accessories_v10';
  static const String _kSettingsKey = 'hafez_sw_pricing_settings_v10';
  static const String _kClientsKey = 'hafez_sw_clients_records_v10';

  List<SectorProfile> sectors = [];
  List<GlassTypeItem> glassTypes = [];
  List<AccessoryPriceItem> accessories = [];
  PricingSettings pricingSettings = PricingSettings();
  List<ClientRecord> clients = [];
  bool isLoaded = false;

  /// ترتيب مجموعات الشركات المطابق تماماً للمشروع المماثل (الورشة الذكية)
  static const List<Map<String, String>> companyGroupsOrder = [
    {
      'name': 'قطاعات السعد (PS)',
      'logo': 'assets/images/windows/systems/s000.png',
      'subtitle': 'PS 9600 • PS 6600 • PS 5600 • PS 4800',
      'catalogUrl': 'https://drive.google.com/drive/search?q=PS+aluminium+catalogue',
    },
    {
      'name': 'مركز الماكينات - الشارقة',
      'logo': 'assets/images/windows/systems/s001.png',
      'subtitle': 'جامبو 100 • تانجو 60 • تندو 120 • تيمبو 84 • سوناتا 45 • نانو 50',
      'catalogUrl': 'https://mac-eg.com/',
    },
    {
      'name': 'فالف القباري (VALVE)',
      'logo': 'assets/images/windows/systems/s002.png',
      'subtitle': 'فالف V170 • فالف V140 • فالف MV100',
      'catalogUrl': 'https://alkabbary.com/',
    },
    {
      'name': 'الدولية 21 - ماكسيم',
      'logo': 'assets/images/windows/systems/s003.png',
      'subtitle': 'ماكسيم E777 • ماكسيم E105 • إيكونومي E47 • إيكونومي E37',
      'catalogUrl': 'https://dawlia21.com/',
    },
    {
      'name': 'قطاعات ألوميل (AluMil)',
      'logo': 'assets/images/windows/systems/s004.png',
      'subtitle': 'M12000 • M9200 • M900 • M9400 • M940',
      'catalogUrl': 'https://www.alumil.com/egypt/ar/homeowners/products',
    },
    {
      'name': 'إيجماس - فولكانو (Volcano)',
      'logo': 'assets/images/windows/systems/s007.jpg',
      'subtitle': 'فولكانو V120 • فولكانو V70 • فولكانو V44',
      'catalogUrl': 'https://egmas.com/',
    },
    {
      'name': 'قطاعات UPVC المصري (Emapen)',
      'logo': 'assets/images/windows/systems/upvc_eg.jpg',
      'subtitle': 'UPVC كبير جرار • UPVC صغير • UPVC مفصلي وقلاب',
      'catalogUrl': 'https://emapen.com/',
    },
    {
      'name': 'قطاعات UPVC المستورد',
      'logo': 'assets/images/windows/systems/s005.png',
      'subtitle': 'وينتك Wintech • كومبن Kompen • بيمابن Pimapen',
      'catalogUrl': 'https://www.wintech.com.tr/',
    },
  ];

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    final String? sectorsRaw = prefs.getString(_kSectorsKey);
    if (sectorsRaw != null && sectorsRaw.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(sectorsRaw);
        sectors = list
            .map((e) => SectorProfile.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } catch (_) {
        sectors = _allStandardSectors();
      }
    } else {
      sectors = _allStandardSectors();
    }

    final String? glassesRaw = prefs.getString(_kGlassesKey);
    if (glassesRaw != null && glassesRaw.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(glassesRaw);
        glassTypes = list
            .map((e) => GlassTypeItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } catch (_) {
        glassTypes = _defaultGlassTypes();
      }
    } else {
      glassTypes = _defaultGlassTypes();
    }

    final String? accRaw = prefs.getString(_kAccessoriesKey);
    if (accRaw != null && accRaw.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(accRaw);
        accessories = list
            .map((e) =>
                AccessoryPriceItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } catch (_) {
        accessories = _defaultAccessories();
      }
    } else {
      accessories = _defaultAccessories();
    }

    final String? settingsRaw = prefs.getString(_kSettingsKey);
    if (settingsRaw != null && settingsRaw.isNotEmpty) {
      try {
        pricingSettings = PricingSettings.fromJson(
            Map<String, dynamic>.from(jsonDecode(settingsRaw)));
      } catch (_) {
        pricingSettings = PricingSettings();
      }
    }

    final String? clientsRaw = prefs.getString(_kClientsKey);
    if (clientsRaw != null && clientsRaw.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(clientsRaw);
        clients = list
            .map((e) => ClientRecord.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } catch (_) {
        clients = [_sampleAhmedAboElYazeedRecord()];
      }
    } else {
      clients = [_sampleAhmedAboElYazeedRecord()];
    }

    isLoaded = true;
    notifyListeners();
  }

  Future<void> _saveAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _kSectorsKey, jsonEncode(sectors.map((e) => e.toJson()).toList()));
    await prefs.setString(
        _kGlassesKey, jsonEncode(glassTypes.map((e) => e.toJson()).toList()));
    await prefs.setString(_kAccessoriesKey,
        jsonEncode(accessories.map((e) => e.toJson()).toList()));
    await prefs.setString(_kSettingsKey, jsonEncode(pricingSettings.toJson()));
    await prefs.setString(
        _kClientsKey, jsonEncode(clients.map((e) => e.toJson()).toList()));
    notifyListeners();
  }

  SectorProfile? getSectorById(String id) {
    for (final s in sectors) {
      if (s.id == id) return s;
    }
    return sectors.isNotEmpty ? sectors.first : null;
  }

  Future<void> addOrUpdateSector(SectorProfile sector) async {
    final idx = sectors.indexWhere((e) => e.id == sector.id);
    if (idx >= 0) {
      sectors[idx] = sector;
    } else {
      sectors.insert(0, sector);
    }
    await _saveAll();
  }

  Future<void> deleteSector(String id) async {
    sectors.removeWhere((e) => e.id == id);
    await _saveAll();
  }

  Future<void> updateSectorPrice(String sectorId, double newPrice,
      {double? barPrice, String? catalogUrl}) async {
    final idx = sectors.indexWhere((e) => e.id == sectorId);
    if (idx >= 0) {
      sectors[idx].pricePerSquareMeter = newPrice;
      if (barPrice != null) sectors[idx].barPrice = barPrice;
      if (catalogUrl != null) sectors[idx].catalogUrl = catalogUrl;
      await _saveAll();
    }
  }

  Future<void> addOrUpdateGlassType(GlassTypeItem item) async {
    final idx = glassTypes.indexWhere((e) => e.id == item.id);
    if (idx >= 0) {
      glassTypes[idx] = item;
    } else {
      glassTypes.add(item);
    }
    await _saveAll();
  }

  Future<void> deleteGlassType(String id) async {
    glassTypes.removeWhere((e) => e.id == id);
    await _saveAll();
  }

  Future<void> addOrUpdateAccessory(AccessoryPriceItem item) async {
    final idx = accessories.indexWhere((e) => e.id == item.id);
    if (idx >= 0) {
      accessories[idx] = item;
    } else {
      accessories.add(item);
    }
    await _saveAll();
  }

  Future<void> deleteAccessory(String id) async {
    accessories.removeWhere((e) => e.id == id);
    await _saveAll();
  }

  Future<void> updatePricingSettings(PricingSettings newSettings) async {
    pricingSettings = newSettings;
    await _saveAll();
  }

  Future<void> saveClientRecord(ClientRecord record) async {
    final idx = clients.indexWhere((e) => e.id == record.id);
    if (idx >= 0) {
      clients[idx] = record;
    } else {
      clients.insert(0, record);
    }
    await _saveAll();
  }

  Future<void> deleteClientRecord(String clientId) async {
    clients.removeWhere((e) => e.id == clientId);
    await _saveAll();
  }

  /// خوارزمية تقسيم الأعواد القياسية (First-Fit Decreasing)
  static List<BarCutPlan> optimize1DBars({
    required List<double> requiredPiecesCm,
    double stockLengthCm = 600.0,
    double sawKerfMm = 4.0,
  }) {
    final double kerfCm = sawKerfMm / 10.0;
    final List<double> sorted = requiredPiecesCm
        .where((p) => p > 0 && p <= stockLengthCm)
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final List<List<double>> bins = [];
    final List<double> binRemaining = [];

    for (final piece in sorted) {
      bool placed = false;
      for (int i = 0; i < bins.length; i++) {
        final double needed = piece + (bins[i].isEmpty ? 0.0 : kerfCm);
        if (binRemaining[i] >= needed - 1e-6) {
          bins[i].add(piece);
          binRemaining[i] = math.max(0.0, binRemaining[i] - needed);
          placed = true;
          break;
        }
      }
      if (!placed) {
        bins.add([piece]);
        binRemaining.add(math.max(0.0, stockLengthCm - piece));
      }
    }

    final List<BarCutPlan> plans = [];
    for (int i = 0; i < bins.length; i++) {
      final double waste = double.parse(binRemaining[i].toStringAsFixed(2));
      final double used =
          double.parse((stockLengthCm - waste).toStringAsFixed(2));
      plans.add(BarCutPlan(
        barNumber: i + 1,
        barLengthCm: stockLengthCm,
        kerfMm: sawKerfMm,
        cutsCm: bins[i],
        usedLengthCm: used,
        wasteLengthCm: waste,
        wastePercentage:
            stockLengthCm > 0 ? (waste / stockLengthCm) * 100 : 0.0,
      ));
    }
    return plans;
  }

  /// محرك حساب الطلبية الشامل (مطابق لحساب الطلبية في الورشة الذكية - المشروع المماثل)
  /// يقوم بتجميع كل البروفايلات بصور مقاطعها الـ SVG وحساب أطوال القص وتقسيم الأعواد 6 متر والزجاج والسلك والإكسسوارات
  List<AggregatedProfileOrder> calculateAggregatedProfilesOrder(
      List<ClientWindowItem> items) {
    final double stockLen = pricingSettings.defaultStockBarLengthCm;
    final double kerfMm = pricingSettings.defaultSawKerfMm;

    final Map<String, Map<String, dynamic>> grouped = {};

    for (final item in items) {
      final sector = getSectorById(item.sectorId);
      if (sector == null) continue;

      final bool isWithoutBar = item.barType.contains('بدون');
      final bool isDoor = item.unitType.contains('باب');
      final bool hasFixedAny = item.hasTopFixed ||
          item.hasBottomFixed ||
          item.hasRightFixed ||
          item.hasLeftFixed;

      for (final part in sector.parts) {
        // فلترة أجزاء القطاع الذكية حسب خيارات الشباك (ببار / بدون بار / سلك / شباك / باب / ثابت)
        if (part.condition == 'with_bar' && isWithoutBar) continue;
        if (part.condition == 'without_bar' && !isWithoutBar) continue;
        if (part.condition == 'window_only' && isDoor) continue;
        if (part.condition == 'door_only' && !isDoor) continue;
        if (part.condition == 'fly_screen' && !item.hasFlyScreen) continue;
        if (part.condition == 'fixed_only' && !hasFixedAny) continue;
        if (part.condition == 'single_glass' && item.isDoubleGlass) continue;
        if (part.condition == 'double_glass' && !item.isDoubleGlass) continue;

        final double cutLen = part.calculatePieceLength(
          item.widthCm,
          item.heightCm,
          item.sashCount,
          netWidthCm: item.netOperableWidthCm,
          netHeightCm: item.netOperableHeightCm,
        );
        if (cutLen <= 0) continue;

        final int count = part.calculateTotalCount(item.quantity, item.sashCount);
        final String key = '${sector.id}__${part.name}__${part.svgAssetPath ?? ""}';

        if (!grouped.containsKey(key)) {
          grouped[key] = {
            'sectorName': sector.name,
            'partName': part.name,
            'role': part.role,
            'svgAssetPath': part.svgAssetPath ?? sector.primaryProfileSvg,
            'lengthCounts': <double, int>{},
            'allPieces': <double>[],
          };
        }

        final Map<double, int> lc =
            grouped[key]!['lengthCounts'] as Map<double, int>;
        final List<double> allP = grouped[key]!['allPieces'] as List<double>;
        final double roundedLen = double.parse(cutLen.toStringAsFixed(1));
        lc[roundedLen] = (lc[roundedLen] ?? 0) + count;
        for (int k = 0; k < count; k++) {
          allP.add(roundedLen);
        }
      }

      // إضافة قواطيع وسؤاسات الثوابت (علوي / سفلي / يمين / شمال) تلقائياً في الطلبية
      if (hasFixedAny) {
        final String? fixedSvg = sector.profileSvgFolder != null
            ? '${sector.profileSvgFolder}/005.svg'
            : sector.primaryProfileSvg;
        final String key = '${sector.id}__سؤاس / قاطع ثابت__$fixedSvg';
        if (!grouped.containsKey(key)) {
          grouped[key] = {
            'sectorName': sector.name,
            'partName': 'سؤاس / قاطع ثابت',
            'role': 'سؤاس',
            'svgAssetPath': fixedSvg,
            'lengthCounts': <double, int>{},
            'allPieces': <double>[],
          };
        }
        final Map<double, int> lc =
            grouped[key]!['lengthCounts'] as Map<double, int>;
        final List<double> allP = grouped[key]!['allPieces'] as List<double>;

        void addTransom(double lenCm, int countPerWin) {
          final double r = double.parse(math.max(10.0, lenCm - 6.0).toStringAsFixed(1));
          final int tot = countPerWin * item.quantity;
          lc[r] = (lc[r] ?? 0) + tot;
          for (int k = 0; k < tot; k++) {
            allP.add(r);
          }
        }

        if (item.hasTopFixed) {
          addTransom(item.widthCm, 1);
          if (item.topFixedSplits > 1) {
            addTransom(item.topFixedHeightCm, item.topFixedSplits - 1);
          }
        }
        if (item.hasBottomFixed) {
          addTransom(item.widthCm, 1);
          if (item.bottomFixedSplits > 1) {
            addTransom(item.bottomFixedHeightCm, item.bottomFixedSplits - 1);
          }
        }
        if (item.hasRightFixed) {
          addTransom(item.netOperableHeightCm, 1);
        }
        if (item.hasLeftFixed) {
          addTransom(item.netOperableHeightCm, 1);
        }
      }
    }

    final List<AggregatedProfileOrder> result = [];
    grouped.forEach((_, data) {
      final List<double> allPieces = List<double>.from(data['allPieces']);
      if (allPieces.isEmpty) return;
      final plans = optimize1DBars(
        requiredPiecesCm: allPieces,
        stockLengthCm: stockLen,
        sawKerfMm: kerfMm,
      );
      result.add(AggregatedProfileOrder(
        sectorName: data['sectorName'],
        partName: data['partName'],
        role: data['role'],
        svgAssetPath: data['svgAssetPath'],
        lengthCounts: Map<double, int>.from(data['lengthCounts']),
        allPiecesCm: allPieces,
        barPlans: plans,
      ));
    });

    return result;
  }

  /// السجل النموذجي المطابق تماماً لملف (أ. احمد ابو اليزيد.pdf)
  ClientRecord _sampleAhmedAboElYazeedRecord() {
    return ClientRecord(
      id: 'client_ahmed_abo_elyazeed',
      clientName: 'أ. احمد ابو اليزيد',
      clientPhone: '01000000000',
      clientAddress: 'ابراج الروضه شارع ناصر',
      createdAt: '2026-11-04',
      discountAmount: 0.0,
      depositAmount: 0.0,
      archCost: 0.0,
      notes: 'مقايسة شبابيك UPVC و P.S مطابقة للنموذج المعتمد',
      items: [
        ClientWindowItem(
          id: 'w1',
          label: 'W1',
          unitType: 'شباك',
          openType: 'جرار',
          sashCount: 2,
          sectorId: 'sec_upvc_eg_large_sliding',
          sectorName: 'UPVC كبير',
          customPdfDescription: 'جرار ٢ ضلفة\nUPVC كبير',
          sectorColor: 'بيج',
          widthCm: 267,
          heightCm: 213,
          quantity: 1,
          sectorPricePerM2: 5500,
          isCombinedMeterPrice: true,
          hasGlass: true,
          isDoubleGlass: true,
          glass1Name: 'دبل\nعاكس\nأخضر\nعلى شفاف',
        ),
        ClientWindowItem(
          id: 'w2',
          label: 'W2',
          unitType: 'شباك',
          openType: 'جرار',
          sashCount: 2,
          sectorId: 'sec_upvc_eg_large_sliding',
          sectorName: 'UPVC كبير',
          customPdfDescription: 'جرار ٢ ضلفة\nUPVC كبير',
          sectorColor: 'بيج',
          widthCm: 231,
          heightCm: 214,
          quantity: 1,
          sectorPricePerM2: 5500,
          isCombinedMeterPrice: true,
          hasGlass: true,
          isDoubleGlass: true,
          glass1Name: 'دبل\nعاكس\nأخضر\nعلى شفاف',
        ),
        ClientWindowItem(
          id: 'w3',
          label: 'W3',
          unitType: 'شباك',
          openType: 'جرار',
          sashCount: 2,
          sectorId: 'sec_upvc_eg_large_sliding',
          sectorName: 'UPVC كبير',
          customPdfDescription: 'جرار ٢ ضلفة\nUPVC كبير',
          sectorColor: 'بيج',
          widthCm: 138,
          heightCm: 92,
          quantity: 1,
          sectorPricePerM2: 5500,
          isCombinedMeterPrice: true,
          hasGlass: true,
          isDoubleGlass: true,
          glass1Name: 'دبل\nعاكس\nأخضر\nعلى شفاف',
        ),
        ClientWindowItem(
          id: 'w4',
          label: 'W4',
          unitType: 'شباك',
          openType: 'جرار',
          sashCount: 2,
          sectorId: 'sec_upvc_eg_large_sliding',
          sectorName: 'UPVC كبير',
          customPdfDescription: 'جرار ٢ ضلفة\nUPVC كبير',
          sectorColor: 'بيج',
          widthCm: 119,
          heightCm: 99,
          quantity: 1,
          sectorPricePerM2: 4500,
          isCombinedMeterPrice: true,
          hasGlass: true,
          isDoubleGlass: false,
          glass1Name: 'سنجل\nمصنفر',
        ),
        ClientWindowItem(
          id: 'w5',
          label: 'W5',
          unitType: 'شباك',
          openType: 'جرار',
          sashCount: 2,
          sectorId: 'sec_ps_6600',
          sectorName: 'صغير P.S',
          customPdfDescription: 'جرار ٢ ضلفة\nصغير P.S',
          sectorColor: 'أسود',
          widthCm: 81,
          heightCm: 69,
          quantity: 1,
          sectorPricePerM2: 5500,
          isCombinedMeterPrice: true,
          hasGlass: true,
          isDoubleGlass: false,
          glass1Name: 'سنجل\nمصنفر',
        ),
        ClientWindowItem(
          id: 'w6',
          label: 'W6',
          unitType: 'شباك',
          openType: 'قلاب',
          sashCount: 1,
          sectorId: 'sec_upvc_eg_hinged',
          sectorName: 'UPVC كبير',
          customPdfDescription: 'قلاب ١ ضلفة\nUPVC كبير',
          sectorColor: 'بيج',
          widthCm: 45,
          heightCm: 56,
          quantity: 1,
          sectorPricePerM2: 4500,
          isCombinedMeterPrice: true,
          hasGlass: true,
          isDoubleGlass: false,
          glass1Name: 'سنجل\nمصنفر',
        ),
      ],
    );
  }

  /// جميع القطاعات القياسية بنفس أسماء وترتيب وصور المشروع المماثل (الورشة الذكية)
  List<SectorProfile> _allStandardSectors() {
    return [
      // ==================== 1. قطاعات السعد (PS) ====================
      _buildSlidingSectorWithSvg(
        id: 'sec_ps_9600',
        name: 'بي إس 9600 جرار كبير (PS 9600)',
        shortPdfName: 'كبير P.S',
        group: 'قطاعات السعد (PS)',
        logo: 'assets/images/windows/systems/s000.png',
        svgFolder: 'assets/images/svg/profiles/ps/9600',
        catalogUrl: 'https://drive.google.com/drive/search?q=PS+9600+profile',
        price: 4800,
        gwDeduct: 10.6,
        ghDeduct: 10.6,
        sashWOffset: -0.5,
        sashHOffset: -6.5,
      ),
      _buildSlidingSectorWithSvg(
        id: 'sec_ps_6600',
        name: 'بي إس 6600 جرار صغير (PS 6600)',
        shortPdfName: 'صغير P.S',
        group: 'قطاعات السعد (PS)',
        logo: 'assets/images/windows/systems/s000.png',
        svgFolder: 'assets/images/svg/profiles/ps/6600',
        catalogUrl: 'https://drive.google.com/drive/search?q=PS+6600+profile',
        price: 4500,
        gwDeduct: 8.8,
        ghDeduct: 8.8,
        sashWOffset: -0.4,
        sashHOffset: -5.8,
      ),
      _buildHingedSectorWithSvg(
        id: 'sec_ps_5600',
        name: 'بي إس 5600 مفصلي كبير (PS 5600)',
        shortPdfName: 'مفصلي كبير P.S',
        group: 'قطاعات السعد (PS)',
        logo: 'assets/images/windows/systems/s000.png',
        svgFolder: 'assets/images/svg/profiles/ps/5600',
        catalogUrl: 'https://drive.google.com/drive/search?q=PS+5600+profile',
        price: 4600,
        gwDeduct: 8.5,
        ghDeduct: 8.5,
        sashWOffset: -4.2,
        sashHOffset: -4.2,
      ),
      _buildHingedSectorWithSvg(
        id: 'sec_ps_4800',
        name: 'بي إس 4800 مفصلي صغير (PS 4800)',
        shortPdfName: 'مفصلي صغير P.S',
        group: 'قطاعات السعد (PS)',
        logo: 'assets/images/windows/systems/s000.png',
        svgFolder: 'assets/images/svg/profiles/ps/4800',
        catalogUrl: 'https://drive.google.com/drive/search?q=PS+4800+profile',
        price: 4300,
        gwDeduct: 8.0,
        ghDeduct: 8.0,
        sashWOffset: -4.0,
        sashHOffset: -4.0,
      ),

      // ==================== 2. مركز الماكينات - الشارقة (SH) ====================
      _buildSlidingSectorWithSvg(
        id: 'sec_jumbo_100',
        name: 'جامبو 100 جرار (JamBo 100)',
        shortPdfName: 'جامبو 100',
        group: 'مركز الماكينات - الشارقة',
        logo: 'assets/images/windows/systems/s001.png',
        svgFolder: 'assets/images/svg/profiles/sh/JamBo100',
        catalogUrl: 'https://mac-eg.com/',
        price: 5500,
        gwDeduct: 11.4,
        ghDeduct: 11.4,
        sashWOffset: 1.5,
        sashHOffset: -8.2,
      ),
      _buildSlidingSectorWithSvg(
        id: 'sec_tango_60',
        name: 'تانجو 60 جرار (Tango 60)',
        shortPdfName: 'تانجو 60',
        group: 'مركز الماكينات - الشارقة',
        logo: 'assets/images/windows/systems/s001.png',
        svgFolder: 'assets/images/svg/profiles/sh/Tango60',
        catalogUrl: 'https://mac-eg.com/',
        price: 5000,
        gwDeduct: 10.2,
        ghDeduct: 10.2,
        sashWOffset: 1.2,
        sashHOffset: -7.5,
      ),
      _buildSlidingSectorWithSvg(
        id: 'sec_tendu_120',
        name: 'تندو 120 جرار (TenDu 120)',
        shortPdfName: 'تندو 120',
        group: 'مركز الماكينات - الشارقة',
        logo: 'assets/images/windows/systems/s001.png',
        svgFolder: 'assets/images/svg/profiles/sh/TenDu120',
        catalogUrl: 'https://mac-eg.com/',
        price: 5800,
        gwDeduct: 12.0,
        ghDeduct: 12.0,
        sashWOffset: 1.8,
        sashHOffset: -9.0,
      ),
      _buildSlidingSectorWithSvg(
        id: 'sec_tembo_84',
        name: 'تيمبو 84 جرار (TemBo 84)',
        shortPdfName: 'تيمبو 84',
        group: 'مركز الماكينات - الشارقة',
        logo: 'assets/images/windows/systems/s001.png',
        svgFolder: 'assets/images/svg/profiles/sh/TemBo84',
        catalogUrl: 'https://mac-eg.com/',
        price: 5200,
        gwDeduct: 10.5,
        ghDeduct: 10.5,
        sashWOffset: 1.4,
        sashHOffset: -8.0,
      ),
      _buildHingedSectorWithSvg(
        id: 'sec_sonata_45',
        name: 'سوناتا 45 مفصلي (Sonata 45)',
        shortPdfName: 'سوناتا 45',
        group: 'مركز الماكينات - الشارقة',
        logo: 'assets/images/windows/systems/s001.png',
        svgFolder: 'assets/images/svg/profiles/sh/Sonata45',
        catalogUrl: 'https://mac-eg.com/',
        price: 5100,
        gwDeduct: 9.5,
        ghDeduct: 9.5,
        sashWOffset: -4.8,
        sashHOffset: -4.8,
      ),
      _buildHingedSectorWithSvg(
        id: 'sec_nano_50',
        name: 'نانو 50 مفصلي (Nano 50)',
        shortPdfName: 'نانو 50',
        group: 'مركز الماكينات - الشارقة',
        logo: 'assets/images/windows/systems/s001.png',
        svgFolder: 'assets/images/svg/profiles/sh/Nano50',
        catalogUrl: 'https://mac-eg.com/',
        price: 4700,
        gwDeduct: 9.2,
        ghDeduct: 9.2,
        sashWOffset: -4.2,
        sashHOffset: -4.2,
      ),

      // ==================== 3. فالف القباري (VALVE) ====================
      _buildSlidingSectorWithSvg(
        id: 'sec_valve_v170',
        name: 'فالف V170 جرار بانوراما (VALVE V170)',
        shortPdfName: 'فالف V170',
        group: 'فالف القباري (VALVE)',
        logo: 'assets/images/windows/systems/s002.png',
        svgFolder: 'assets/images/svg/profiles/valve/V170',
        catalogUrl: 'https://alkabbary.com/',
        price: 6200,
        gwDeduct: 12.8,
        ghDeduct: 12.8,
        sashWOffset: 2.0,
        sashHOffset: -9.8,
      ),
      _buildSlidingSectorWithSvg(
        id: 'sec_valve_v140',
        name: 'فالف V140 جرار (VALVE V140)',
        shortPdfName: 'فالف V140',
        group: 'فالف القباري (VALVE)',
        logo: 'assets/images/windows/systems/s002.png',
        svgFolder: 'assets/images/svg/profiles/valve/V140',
        catalogUrl: 'https://alkabbary.com/',
        price: 5600,
        gwDeduct: 11.2,
        ghDeduct: 11.2,
        sashWOffset: 1.5,
        sashHOffset: -8.4,
      ),
      _buildHingedSectorWithSvg(
        id: 'sec_valve_mv100',
        name: 'فالف MV100 مفصلي عازل (VALVE MV100)',
        shortPdfName: 'فالف MV100',
        group: 'فالف القباري (VALVE)',
        logo: 'assets/images/windows/systems/s002.png',
        svgFolder: 'assets/images/svg/profiles/valve/MV100',
        catalogUrl: 'https://alkabbary.com/',
        price: 5700,
        gwDeduct: 10.5,
        ghDeduct: 10.5,
        sashWOffset: -5.0,
        sashHOffset: -5.0,
      ),

      // ==================== 4. الدولية 21 - ماكسيم (Maxim) ====================
      _buildSlidingSectorWithSvg(
        id: 'sec_maxim_e777',
        name: 'ماكسيم E777 جرار عريض (Maxim E777)',
        shortPdfName: 'ماكسيم E777',
        group: 'الدولية 21 - ماكسيم',
        logo: 'assets/images/windows/systems/s003.png',
        svgFolder: 'assets/images/svg/profiles/maxim/e777',
        catalogUrl: 'https://dawlia21.com/',
        price: 5400,
        gwDeduct: 11.5,
        ghDeduct: 11.5,
        sashWOffset: 1.6,
        sashHOffset: -8.5,
      ),
      _buildSlidingSectorWithSvg(
        id: 'sec_maxim_e105',
        name: 'ماكسيم E105 جرار (Maxim E105)',
        shortPdfName: 'ماكسيم E105',
        group: 'الدولية 21 - ماكسيم',
        logo: 'assets/images/windows/systems/s003.png',
        svgFolder: 'assets/images/svg/profiles/maxim/e105',
        catalogUrl: 'https://dawlia21.com/',
        price: 4900,
        gwDeduct: 10.4,
        ghDeduct: 10.4,
        sashWOffset: 1.2,
        sashHOffset: -7.8,
      ),
      _buildHingedSectorWithSvg(
        id: 'sec_maxim_e47',
        name: 'إيكونومي E47 مفصلي كبير (Maxim E47)',
        shortPdfName: 'ماكسيم E47',
        group: 'الدولية 21 - ماكسيم',
        logo: 'assets/images/windows/systems/s003.png',
        svgFolder: 'assets/images/svg/profiles/maxim/e47',
        catalogUrl: 'https://dawlia21.com/',
        price: 5100,
        gwDeduct: 9.8,
        ghDeduct: 9.8,
        sashWOffset: -4.6,
        sashHOffset: -4.6,
      ),
      _buildHingedSectorWithSvg(
        id: 'sec_maxim_e37',
        name: 'إيكونومي E37 مفصلي صغير (Maxim E37)',
        shortPdfName: 'ماكسيم E37',
        group: 'الدولية 21 - ماكسيم',
        logo: 'assets/images/windows/systems/s003.png',
        svgFolder: 'assets/images/svg/profiles/maxim/e37',
        catalogUrl: 'https://dawlia21.com/',
        price: 4700,
        gwDeduct: 8.6,
        ghDeduct: 8.6,
        sashWOffset: -4.0,
        sashHOffset: -4.0,
      ),

      // ==================== 5. قطاعات ألوميل (AluMil) ====================
      _buildSlidingSectorWithSvg(
        id: 'sec_alumil_m12000',
        name: 'ألوميل M12000 جرار جامبو (AluMil M12000)',
        shortPdfName: 'ألوميل M12000',
        group: 'قطاعات ألوميل (AluMil)',
        logo: 'assets/images/windows/systems/s004.png',
        svgFolder: 'assets/images/svg/profiles/AluMil/M12000',
        catalogUrl: 'https://www.alumil.com/egypt/ar/homeowners/products',
        price: 6800,
        gwDeduct: 13.0,
        ghDeduct: 13.0,
        sashWOffset: 2.2,
        sashHOffset: -10.0,
      ),
      _buildSlidingSectorWithSvg(
        id: 'sec_alumil_m9200',
        name: 'ألوميل M9200 جرار عازل (AluMil M9200)',
        shortPdfName: 'ألوميل M9200',
        group: 'قطاعات ألوميل (AluMil)',
        logo: 'assets/images/windows/systems/s004.png',
        svgFolder: 'assets/images/svg/profiles/AluMil/M9200',
        catalogUrl: 'https://www.alumil.com/egypt/ar/homeowners/products',
        price: 6400,
        gwDeduct: 12.5,
        ghDeduct: 12.5,
        sashWOffset: 2.0,
        sashHOffset: -9.5,
      ),
      _buildSlidingSectorWithSvg(
        id: 'sec_alumil_m900',
        name: 'ألوميل M900 جرار (AluMil M900)',
        shortPdfName: 'ألوميل M900',
        group: 'قطاعات ألوميل (AluMil)',
        logo: 'assets/images/windows/systems/s004.png',
        svgFolder: 'assets/images/svg/profiles/AluMil/M900',
        catalogUrl: 'https://www.alumil.com/egypt/ar/homeowners/products',
        price: 5600,
        gwDeduct: 10.8,
        ghDeduct: 10.8,
        sashWOffset: 1.4,
        sashHOffset: -8.0,
      ),
      _buildHingedSectorWithSvg(
        id: 'sec_alumil_m9400',
        name: 'ألوميل M9400 مفصلي عازل (AluMil M9400)',
        shortPdfName: 'ألوميل M9400',
        group: 'قطاعات ألوميل (AluMil)',
        logo: 'assets/images/windows/systems/s004.png',
        svgFolder: 'assets/images/svg/profiles/AluMil/M9400',
        catalogUrl: 'https://www.alumil.com/egypt/ar/homeowners/products',
        price: 6200,
        gwDeduct: 11.0,
        ghDeduct: 11.0,
        sashWOffset: -5.2,
        sashHOffset: -5.2,
      ),
      _buildHingedSectorWithSvg(
        id: 'sec_alumil_m940',
        name: 'ألوميل M940 مفصلي (AluMil M940)',
        shortPdfName: 'ألوميل M940',
        group: 'قطاعات ألوميل (AluMil)',
        logo: 'assets/images/windows/systems/s004.png',
        svgFolder: 'assets/images/svg/profiles/AluMil/M940',
        catalogUrl: 'https://www.alumil.com/egypt/ar/homeowners/products',
        price: 5500,
        gwDeduct: 9.6,
        ghDeduct: 9.6,
        sashWOffset: -4.5,
        sashHOffset: -4.5,
      ),

      // ==================== 6. إيجماس - فولكانو (Volcano) ====================
      _buildSlidingSectorWithSvg(
        id: 'sec_volcano_v120',
        name: 'فولكانو V120 جرار ثقيل (Volcano V120)',
        shortPdfName: 'فولكانو V120',
        group: 'إيجماس - فولكانو (Volcano)',
        logo: 'assets/images/windows/systems/s007.jpg',
        svgFolder: 'assets/images/svg/profiles/Volcano/V120',
        catalogUrl: 'https://egmas.com/',
        price: 5900,
        gwDeduct: 12.0,
        ghDeduct: 12.0,
        sashWOffset: 1.8,
        sashHOffset: -9.0,
      ),
      _buildSlidingSectorWithSvg(
        id: 'sec_volcano_v70',
        name: 'فولكانو V70 جرار وسط (Volcano V70)',
        shortPdfName: 'فولكانو V70',
        group: 'إيجماس - فولكانو (Volcano)',
        logo: 'assets/images/windows/systems/s007.jpg',
        svgFolder: 'assets/images/svg/profiles/Volcano/V70',
        catalogUrl: 'https://egmas.com/',
        price: 5300,
        gwDeduct: 10.5,
        ghDeduct: 10.5,
        sashWOffset: 1.4,
        sashHOffset: -7.8,
      ),
      _buildHingedSectorWithSvg(
        id: 'sec_volcano_v44',
        name: 'فولكانو V44 مفصلي (Volcano V44)',
        shortPdfName: 'فولكانو V44',
        group: 'إيجماس - فولكانو (Volcano)',
        logo: 'assets/images/windows/systems/s007.jpg',
        svgFolder: 'assets/images/svg/profiles/Volcano/V44',
        catalogUrl: 'https://egmas.com/',
        price: 5200,
        gwDeduct: 10.0,
        ghDeduct: 10.0,
        sashWOffset: -4.8,
        sashHOffset: -4.8,
      ),

      // ==================== 7. قطاعات UPVC المصري (Emapen) ====================
      _buildSlidingSectorWithSvg(
        id: 'sec_upvc_eg_large_sliding',
        name: 'إيمابن UPVC كبير جرار (Emapen Large)',
        shortPdfName: 'UPVC كبير',
        group: 'قطاعات UPVC المصري (Emapen)',
        logo: 'assets/images/windows/systems/upvc_eg.jpg',
        svgFolder: 'assets/images/svg/profiles/sh/JamBo100',
        catalogUrl: 'https://emapen.com/',
        price: 5500,
        gwDeduct: 13.0,
        ghDeduct: 13.0,
        sashWOffset: 2.0,
        sashHOffset: -10.0,
      ),
      _buildSlidingSectorWithSvg(
        id: 'sec_upvc_eg_small_sliding',
        name: 'إيمابن UPVC صغير جرار (Emapen Small)',
        shortPdfName: 'UPVC صغير',
        group: 'قطاعات UPVC المصري (Emapen)',
        logo: 'assets/images/windows/systems/upvc_eg.jpg',
        svgFolder: 'assets/images/svg/profiles/sh/Tango60',
        catalogUrl: 'https://emapen.com/',
        price: 4500,
        gwDeduct: 11.5,
        ghDeduct: 11.5,
        sashWOffset: 1.5,
        sashHOffset: -8.5,
      ),
      _buildHingedSectorWithSvg(
        id: 'sec_upvc_eg_hinged',
        name: 'إيمابن UPVC مفصلي / قلاب كبير (Emapen)',
        shortPdfName: 'UPVC كبير',
        group: 'قطاعات UPVC المصري (Emapen)',
        logo: 'assets/images/windows/systems/upvc_eg.jpg',
        svgFolder: 'assets/images/svg/profiles/sh/Sonata45',
        catalogUrl: 'https://emapen.com/',
        price: 4500,
        gwDeduct: 11.8,
        ghDeduct: 11.8,
        sashWOffset: -5.2,
        sashHOffset: -5.2,
      ),

      // ==================== 8. قطاعات UPVC المستورد ====================
      _buildSlidingSectorWithSvg(
        id: 'sec_upvc_tr_sliding',
        name: 'وينتك / كومبن UPVC تركي جرار (Wintech)',
        shortPdfName: 'UPVC تركي جرار',
        group: 'قطاعات UPVC المستورد',
        logo: 'assets/images/windows/systems/s005.png',
        svgFolder: 'assets/images/svg/profiles/AluMil/M9200',
        catalogUrl: 'https://www.wintech.com.tr/',
        price: 6200,
        gwDeduct: 13.5,
        ghDeduct: 13.5,
        sashWOffset: 2.0,
        sashHOffset: -10.2,
      ),
      _buildHingedSectorWithSvg(
        id: 'sec_upvc_tr_hinged',
        name: 'وينتك / كومبن UPVC تركي مفصلي (Wintech)',
        shortPdfName: 'UPVC تركي مفصلي',
        group: 'قطاعات UPVC المستورد',
        logo: 'assets/images/windows/systems/s005.png',
        svgFolder: 'assets/images/svg/profiles/AluMil/M9400',
        catalogUrl: 'https://www.wintech.com.tr/',
        price: 6000,
        gwDeduct: 12.2,
        ghDeduct: 12.2,
        sashWOffset: -5.5,
        sashHOffset: -5.5,
      ),
    ];
  }

  List<GlassTypeItem> _defaultGlassTypes() {
    return [
      GlassTypeItem(
        id: 'g_double_green_ref_clear',
        name: 'دبل\nعاكس\nأخضر\nعلى شفاف',
        pricePerSquareMeter: 1100.0,
        thickness: '6+6 مم دبل',
        color: 'عاكس أخضر على شفاف',
        isDoublePreset: true,
      ),
      GlassTypeItem(
        id: 'g_single_frosted',
        name: 'سنجل\nمصنفر',
        pricePerSquareMeter: 500.0,
        thickness: '6 مم',
        color: 'مصنفر',
        isDoublePreset: false,
      ),
      GlassTypeItem(
        id: 'g_double_brown_ref_clear',
        name: 'دبل\nعاكس\nبني\nعلى شفاف',
        pricePerSquareMeter: 1100.0,
        thickness: '6+6 مم دبل',
        color: 'عاكس بني على شفاف',
        isDoublePreset: true,
      ),
      GlassTypeItem(
        id: 'g_double_blue_ref_clear',
        name: 'دبل\nعاكس\nأزرق\nعلى شفاف',
        pricePerSquareMeter: 1150.0,
        thickness: '6+6 مم دبل',
        color: 'عاكس أزرق على شفاف',
        isDoublePreset: true,
      ),
      GlassTypeItem(
        id: 'g_single_clear_6',
        name: 'سنجل\nشفاف 6 مم',
        pricePerSquareMeter: 450.0,
        thickness: '6 مم',
        color: 'شفاف',
        isDoublePreset: false,
      ),
      GlassTypeItem(
        id: 'g_single_ref_green_6',
        name: 'سنجل\nعاكس أخضر',
        pricePerSquareMeter: 620.0,
        thickness: '6 مم',
        color: 'عاكس أخضر',
        isDoublePreset: false,
      ),
      GlassTypeItem(
        id: 'g_single_ref_brown_6',
        name: 'سنجل\nعاكس بني',
        pricePerSquareMeter: 600.0,
        thickness: '6 مم',
        color: 'عاكس بني',
        isDoublePreset: false,
      ),
      GlassTypeItem(
        id: 'g_tempered_10',
        name: 'زجاج سيكوريت 10 مم',
        pricePerSquareMeter: 1250.0,
        thickness: '10 مم',
        color: 'سيكوريت',
        isDoublePreset: false,
      ),
    ];
  }

  List<AccessoryPriceItem> _defaultAccessories() {
    return [
      AccessoryPriceItem(
          id: 'acc_handle_sliding',
          name: 'طقم صكاك / مقبض جرار تركي',
          unit: 'طقم',
          price: 180.0),
      AccessoryPriceItem(
          id: 'acc_handle_hinged',
          name: 'مقبض مفصلي / قلاب تركي بالماكينة',
          unit: 'طقم',
          price: 220.0),
      AccessoryPriceItem(
          id: 'acc_rollers_double',
          name: 'طقم عجل جرار دبل روحين بالرمان بلي',
          unit: 'طقم',
          price: 160.0),
      AccessoryPriceItem(
          id: 'acc_hinges_pair',
          name: 'طقم مفصلات إيطالي / تركي ثقيل',
          unit: 'طقم',
          price: 120.0),
      AccessoryPriceItem(
          id: 'acc_fly_mesh',
          name: 'سلك فايبر / ألومنيوم بالفرش والكاوتش',
          unit: 'متر مربع',
          price: 250.0),
      AccessoryPriceItem(
          id: 'acc_rubber_gasket',
          name: 'كاوتش EPDM عازل للزجاج والضلف',
          unit: 'متر طولي',
          price: 15.0),
      AccessoryPriceItem(
          id: 'acc_brush_seal',
          name: 'فرش عازل للأتربة جرار',
          unit: 'متر طولي',
          price: 12.0),
    ];
  }

  static SectorProfile _buildSlidingSectorWithSvg({
    required String id,
    required String name,
    required String shortPdfName,
    required String group,
    required String logo,
    required String svgFolder,
    required String catalogUrl,
    required double price,
    required double gwDeduct,
    required double ghDeduct,
    required double sashWOffset,
    required double sashHOffset,
  }) {
    return SectorProfile(
      id: id,
      name: name,
      shortPdfName: shortPdfName,
      category: 'منزلق',
      companyGroup: group,
      systemType: 'شباك جرار',
      defaultSashCount: 2,
      companyLogoAsset: logo,
      profileSvgFolder: svgFolder,
      catalogUrl: catalogUrl,
      pricePerSquareMeter: price,
      glassWidthDeductCm: gwDeduct,
      glassHeightDeductCm: ghDeduct,
      parts: [
        SectorPart(
          id: '${id}_p1',
          name: 'حلق ببار (عرض)',
          role: 'حلق',
          dimensionBasis: 'width',
          offsetCm: 0.0,
          quantityPerWindow: 2,
          svgAssetPath: '$svgFolder/001.svg',
          condition: 'with_bar',
        ),
        SectorPart(
          id: '${id}_p2',
          name: 'حلق ببار (ارتفاع)',
          role: 'حلق',
          dimensionBasis: 'height',
          offsetCm: 0.0,
          quantityPerWindow: 2,
          svgAssetPath: '$svgFolder/001.svg',
          condition: 'with_bar',
        ),
        SectorPart(
          id: '${id}_p3',
          name: 'حلق بدون بار (عرض)',
          role: 'حلق',
          dimensionBasis: 'width',
          offsetCm: 0.0,
          quantityPerWindow: 2,
          svgAssetPath: '$svgFolder/002.svg',
          condition: 'without_bar',
        ),
        SectorPart(
          id: '${id}_p4',
          name: 'حلق بدون بار (ارتفاع)',
          role: 'حلق',
          dimensionBasis: 'height',
          offsetCm: 0.0,
          quantityPerWindow: 2,
          svgAssetPath: '$svgFolder/002.svg',
          condition: 'without_bar',
        ),
        SectorPart(
          id: '${id}_p5',
          name: 'ضلفة شباك جرار (عرض)',
          role: 'ضلفة',
          dimensionBasis: 'net_width_per_sash',
          offsetCm: sashWOffset,
          quantityPerWindow: 2,
          multiplyBySashes: true,
          svgAssetPath: '$svgFolder/003.svg',
        ),
        SectorPart(
          id: '${id}_p6',
          name: 'ضلفة شباك جرار (ارتفاع)',
          role: 'ضلفة',
          dimensionBasis: 'net_height',
          offsetCm: sashHOffset,
          quantityPerWindow: 2,
          multiplyBySashes: true,
          svgAssetPath: '$svgFolder/003.svg',
        ),
        SectorPart(
          id: '${id}_p7',
          name: 'سكينة تداخل (ارتفاع)',
          role: 'سكينة',
          dimensionBasis: 'net_height',
          offsetCm: sashHOffset,
          quantityPerWindow: 2,
          svgAssetPath: '$svgFolder/005.svg',
        ),
        SectorPart(
          id: '${id}_p8',
          name: 'ضلفة سلك (عرض)',
          role: 'منخل',
          dimensionBasis: 'net_width_per_sash',
          offsetCm: sashWOffset,
          quantityPerWindow: 2,
          svgAssetPath: '$svgFolder/004.svg',
          condition: 'fly_screen',
        ),
        SectorPart(
          id: '${id}_p9',
          name: 'ضلفة سلك (ارتفاع)',
          role: 'منخل',
          dimensionBasis: 'net_height',
          offsetCm: sashHOffset + 1.5,
          quantityPerWindow: 2,
          svgAssetPath: '$svgFolder/004.svg',
          condition: 'fly_screen',
        ),
      ],
    );
  }

  static SectorProfile _buildHingedSectorWithSvg({
    required String id,
    required String name,
    required String shortPdfName,
    required String group,
    required String logo,
    required String svgFolder,
    required String catalogUrl,
    required double price,
    required double gwDeduct,
    required double ghDeduct,
    required double sashWOffset,
    required double sashHOffset,
  }) {
    return SectorProfile(
      id: id,
      name: name,
      shortPdfName: shortPdfName,
      category: 'مفصلي',
      companyGroup: group,
      systemType: 'شباك مفصلي',
      defaultSashCount: 1,
      companyLogoAsset: logo,
      profileSvgFolder: svgFolder,
      catalogUrl: catalogUrl,
      pricePerSquareMeter: price,
      glassWidthDeductCm: gwDeduct,
      glassHeightDeductCm: ghDeduct,
      parts: [
        SectorPart(
          id: '${id}_h1',
          name: 'حلق مفصلي ببار (عرض)',
          role: 'حلق',
          dimensionBasis: 'width',
          offsetCm: 0.0,
          quantityPerWindow: 2,
          svgAssetPath: '$svgFolder/001.svg',
          condition: 'with_bar',
        ),
        SectorPart(
          id: '${id}_h2',
          name: 'حلق مفصلي ببار (ارتفاع)',
          role: 'حلق',
          dimensionBasis: 'height',
          offsetCm: 0.0,
          quantityPerWindow: 2,
          svgAssetPath: '$svgFolder/001.svg',
          condition: 'with_bar',
        ),
        SectorPart(
          id: '${id}_h3',
          name: 'حلق مفصلي بدون بار (عرض)',
          role: 'حلق',
          dimensionBasis: 'width',
          offsetCm: 0.0,
          quantityPerWindow: 2,
          svgAssetPath: '$svgFolder/002.svg',
          condition: 'without_bar',
        ),
        SectorPart(
          id: '${id}_h4',
          name: 'حلق مفصلي بدون بار (ارتفاع)',
          role: 'حلق',
          dimensionBasis: 'height',
          offsetCm: 0.0,
          quantityPerWindow: 2,
          svgAssetPath: '$svgFolder/002.svg',
          condition: 'without_bar',
        ),
        SectorPart(
          id: '${id}_h5',
          name: 'ضلفة مفصلي (عرض)',
          role: 'ضلفة',
          dimensionBasis: 'net_width_per_sash',
          offsetCm: sashWOffset,
          quantityPerWindow: 2,
          multiplyBySashes: true,
          svgAssetPath: '$svgFolder/003.svg',
        ),
        SectorPart(
          id: '${id}_h6',
          name: 'ضلفة مفصلي (ارتفاع)',
          role: 'ضلفة',
          dimensionBasis: 'net_height',
          offsetCm: sashHOffset,
          quantityPerWindow: 2,
          multiplyBySashes: true,
          svgAssetPath: '$svgFolder/003.svg',
        ),
        SectorPart(
          id: '${id}_h7',
          name: 'باكتة زجاج (عرض)',
          role: 'باكتة',
          dimensionBasis: 'net_width_per_sash',
          offsetCm: sashWOffset - 4.0,
          quantityPerWindow: 2,
          multiplyBySashes: true,
          svgAssetPath: '$svgFolder/004.svg',
        ),
        SectorPart(
          id: '${id}_h8',
          name: 'باكتة زجاج (ارتفاع)',
          role: 'باكتة',
          dimensionBasis: 'net_height',
          offsetCm: sashHOffset - 4.0,
          quantityPerWindow: 2,
          multiplyBySashes: true,
          svgAssetPath: '$svgFolder/004.svg',
        ),
      ],
    );
  }
}
