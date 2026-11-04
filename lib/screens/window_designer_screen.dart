import 'package:flutter/material.dart';
import '../models/workshop_models.dart';
import '../services/native_file_service.dart';
import '../services/workshop_storage.dart';
import '../widgets/svg_profile_widget.dart';
import '../widgets/window_2d_visualizer.dart';

/// شاشة تصميم ومعاينة الشباك / الباب التفاعلية (مثل المشروع المماثل تماماً)
/// شاشة المعاينة مثبتة في الأعلى دائماً ولا تختفي أبداً أثناء تعديل المقاسات أو إضافة الثوابت!
class WindowDesignerScreen extends StatefulWidget {
  final WorkshopStorage storage;
  final ClientWindowItem? existingItem;
  final int nextIndex;
  final String? initialCategory; // منزلق | مفصلي
  final String? initialCompanyGroup;
  final SectorProfile? initialSector;

  const WindowDesignerScreen({
    super.key,
    required this.storage,
    this.existingItem,
    this.nextIndex = 1,
    this.initialCategory,
    this.initialCompanyGroup,
    this.initialSector,
  });

  @override
  State<WindowDesignerScreen> createState() => _WindowDesignerScreenState();
}

class _WindowDesignerScreenState extends State<WindowDesignerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _optionsTabController;

  late String _selectedCategory; // منزلق | مفصلي
  late SectorProfile _selectedSector;

  late TextEditingController _labelCtrl;
  late TextEditingController _widthCtrl;
  late TextEditingController _heightCtrl;
  late TextEditingController _qtyCtrl;
  late TextEditingController _pricePerM2Ctrl;
  late TextEditingController _customPdfDescCtrl;

  String _unitType = 'شباك';
  String _openType = 'جرار';
  String _barType = 'ببار';
  String _openDirection = 'يمين للداخل';
  String _sectorColor = 'بيج';
  int _sashCount = 2;
  int _trackCount = 2;
  bool _hasFlyScreen = true;
  bool _isCombinedMeterPrice = true;

  // الثوابت وأماكنها ومقاساتها (شمال، يمين، فوق، تحت)
  bool _hasLeftFixed = false;
  late TextEditingController _leftFixedWCtrl;
  int _leftFixedSplits = 1;

  bool _hasRightFixed = false;
  late TextEditingController _rightFixedWCtrl;
  int _rightFixedSplits = 1;

  bool _hasTopFixed = false;
  late TextEditingController _topFixedHCtrl;
  int _topFixedSplits = 1;

  bool _hasBottomFixed = false;
  late TextEditingController _bottomFixedHCtrl;
  int _bottomFixedSplits = 1;

  // الشفاط
  bool _hasExhaustFan = false;
  String _exhaustFanShape = 'دائري';
  late TextEditingController _exhaustFanDiamCtrl;
  String _exhaustFanPosition = 'في الثابت العلوي';

  // الزجاج والجورجيا
  bool _hasGlass = true;
  bool _isDoubleGlass = true;
  late GlassTypeItem _selectedGlass1;
  late GlassTypeItem _selectedGlass2;
  late TextEditingController _customGlassTextCtrl;

  bool _hasGeorgian = false;
  late TextEditingController _georgianMetersCtrl;

  @override
  void initState() {
    super.initState();
    _optionsTabController = TabController(length: 4, vsync: this);

    final sectors = widget.storage.sectors;
    final glasses = widget.storage.glassTypes;
    final ex = widget.existingItem;

    if (ex != null) {
      _selectedSector =
          widget.storage.getSectorById(ex.sectorId) ?? sectors.first;
      _selectedCategory = _selectedSector.isSliding ? 'منزلق' : 'مفصلي';
      _unitType = ex.unitType;
      _openType = ex.openType;
      _barType = ex.barType;
      _openDirection = ex.openDirection;
      _sectorColor = ex.sectorColor;
      _sashCount = ex.sashCount;
      _trackCount = ex.trackCount;
      _hasFlyScreen = ex.hasFlyScreen;
      _isCombinedMeterPrice = ex.isCombinedMeterPrice;

      _labelCtrl = TextEditingController(text: ex.label);
      _widthCtrl =
          TextEditingController(text: ex.widthCm.toStringAsFixed(0));
      _heightCtrl =
          TextEditingController(text: ex.heightCm.toStringAsFixed(0));
      _qtyCtrl = TextEditingController(text: '${ex.quantity}');
      _pricePerM2Ctrl = TextEditingController(
          text: ex.sectorPricePerM2.toStringAsFixed(0));
      _customPdfDescCtrl =
          TextEditingController(text: ex.customPdfDescription);

      _hasLeftFixed = ex.hasLeftFixed;
      _leftFixedWCtrl = TextEditingController(
          text: ex.leftFixedWidthCm.toStringAsFixed(0));
      _leftFixedSplits = ex.leftFixedSplits;

      _hasRightFixed = ex.hasRightFixed;
      _rightFixedWCtrl = TextEditingController(
          text: ex.rightFixedWidthCm.toStringAsFixed(0));
      _rightFixedSplits = ex.rightFixedSplits;

      _hasTopFixed = ex.hasTopFixed;
      _topFixedHCtrl = TextEditingController(
          text: ex.topFixedHeightCm.toStringAsFixed(0));
      _topFixedSplits = ex.topFixedSplits;

      _hasBottomFixed = ex.hasBottomFixed;
      _bottomFixedHCtrl = TextEditingController(
          text: ex.bottomFixedHeightCm.toStringAsFixed(0));
      _bottomFixedSplits = ex.bottomFixedSplits;

      _hasExhaustFan = ex.hasExhaustFan;
      _exhaustFanShape = ex.exhaustFanShape;
      _exhaustFanDiamCtrl = TextEditingController(
          text: ex.exhaustFanDiameterCm.toStringAsFixed(0));
      _exhaustFanPosition = ex.exhaustFanPosition;

      _hasGlass = ex.hasGlass;
      _isDoubleGlass = ex.isDoubleGlass;
      _selectedGlass1 = glasses.firstWhere(
        (g) => g.id == ex.glass1Id || g.name == ex.glass1Name,
        orElse: () => glasses.first,
      );
      _selectedGlass2 = glasses.firstWhere(
        (g) => g.id == ex.glass2Id,
        orElse: () => glasses.length > 1 ? glasses[1] : glasses.first,
      );
      _customGlassTextCtrl = TextEditingController(text: ex.glass1Name);

      _hasGeorgian = ex.hasGeorgianBars;
      _georgianMetersCtrl = TextEditingController(
          text: ex.georgianMetersPerWindow.toStringAsFixed(1));
    } else {
      _selectedCategory = widget.initialCategory ?? 'منزلق';
      if (widget.initialSector != null) {
        _selectedSector = widget.initialSector!;
        _selectedCategory = _selectedSector.isSliding ? 'منزلق' : 'مفصلي';
      } else {
        final matching = sectors.where((s) {
          final catMatch = _selectedCategory == 'منزلق'
              ? s.isSliding
              : s.isHinged;
          final grpMatch = widget.initialCompanyGroup == null ||
              s.companyGroup == widget.initialCompanyGroup;
          return catMatch && grpMatch;
        }).toList();
        _selectedSector =
            matching.isNotEmpty ? matching.first : sectors.first;
      }

      _openType = _selectedCategory == 'منزلق' ? 'جرار' : 'مفصلي';
      _sashCount = _selectedCategory == 'منزلق' ? 2 : 1;

      _labelCtrl = TextEditingController(text: 'W${widget.nextIndex}');
      _widthCtrl = TextEditingController(text: '150');
      _heightCtrl = TextEditingController(text: '120');
      _qtyCtrl = TextEditingController(text: '1');
      _pricePerM2Ctrl = TextEditingController(
          text: _selectedSector.pricePerSquareMeter.toStringAsFixed(0));
      _customPdfDescCtrl = TextEditingController(text: '');

      _leftFixedWCtrl = TextEditingController(text: '40');
      _rightFixedWCtrl = TextEditingController(text: '40');
      _topFixedHCtrl = TextEditingController(text: '40');
      _bottomFixedHCtrl = TextEditingController(text: '40');
      _exhaustFanDiamCtrl = TextEditingController(text: '25');

      _selectedGlass1 = glasses.first;
      _selectedGlass2 = glasses.length > 1 ? glasses[1] : glasses.first;
      _isDoubleGlass = _selectedGlass1.isDoublePreset;
      _customGlassTextCtrl =
          TextEditingController(text: _selectedGlass1.name);
      _georgianMetersCtrl = TextEditingController(text: '3.0');
    }
  }

  @override
  void dispose() {
    _optionsTabController.dispose();
    _labelCtrl.dispose();
    _widthCtrl.dispose();
    _heightCtrl.dispose();
    _qtyCtrl.dispose();
    _pricePerM2Ctrl.dispose();
    _customPdfDescCtrl.dispose();
    _leftFixedWCtrl.dispose();
    _rightFixedWCtrl.dispose();
    _topFixedHCtrl.dispose();
    _bottomFixedHCtrl.dispose();
    _exhaustFanDiamCtrl.dispose();
    _customGlassTextCtrl.dispose();
    _georgianMetersCtrl.dispose();
    super.dispose();
  }

  void _switchCategory(String newCat) {
    setState(() {
      _selectedCategory = newCat;
      if (newCat == 'منزلق') {
        _openType = 'جرار';
        if (_sashCount < 2) _sashCount = 2;
      } else {
        if (_openType == 'جرار') _openType = 'مفصلي';
      }
      final matching = widget.storage.sectors.where((s) {
        final sameGroup = s.companyGroup == _selectedSector.companyGroup;
        final catMatch = newCat == 'منزلق' ? s.isSliding : s.isHinged;
        return sameGroup && catMatch;
      }).toList();
      if (matching.isNotEmpty) {
        _selectedSector = matching.first;
        _pricePerM2Ctrl.text =
            _selectedSector.pricePerSquareMeter.toStringAsFixed(0);
      } else {
        final anyCat = widget.storage.sectors
            .where((s) => newCat == 'منزلق' ? s.isSliding : s.isHinged)
            .toList();
        if (anyCat.isNotEmpty) {
          _selectedSector = anyCat.first;
          _pricePerM2Ctrl.text =
              _selectedSector.pricePerSquareMeter.toStringAsFixed(0);
        }
      }
    });
  }

  ClientWindowItem _buildCurrentWindowItem() {
    final double w = double.tryParse(_widthCtrl.text.trim()) ?? 150.0;
    final double h = double.tryParse(_heightCtrl.text.trim()) ?? 120.0;
    final int q = int.tryParse(_qtyCtrl.text.trim()) ?? 1;
    final double priceM2 = double.tryParse(_pricePerM2Ctrl.text.trim()) ??
        _selectedSector.pricePerSquareMeter;

    return ClientWindowItem(
      id: widget.existingItem?.id ??
          'win_${DateTime.now().millisecondsSinceEpoch}',
      label: _labelCtrl.text.trim().isEmpty
          ? 'W${widget.nextIndex}'
          : _labelCtrl.text.trim(),
      unitType: _unitType,
      openType: _openType,
      barType: _barType,
      openDirection: _openDirection,
      sectorId: _selectedSector.id,
      sectorName: _selectedSector.shortPdfName,
      customPdfDescription: _customPdfDescCtrl.text.trim(),
      sectorPricePerM2: priceM2,
      isCombinedMeterPrice: _isCombinedMeterPrice,
      sectorColor: _sectorColor,
      widthCm: w,
      heightCm: h,
      quantity: q > 0 ? q : 1,
      sashCount: _sashCount,
      trackCount: _trackCount,
      hasFlyScreen: _hasFlyScreen,
      hasTopFixed: _hasTopFixed,
      topFixedHeightCm:
          double.tryParse(_topFixedHCtrl.text.trim()) ?? 40.0,
      topFixedSplits: _topFixedSplits,
      hasBottomFixed: _hasBottomFixed,
      bottomFixedHeightCm:
          double.tryParse(_bottomFixedHCtrl.text.trim()) ?? 40.0,
      bottomFixedSplits: _bottomFixedSplits,
      hasRightFixed: _hasRightFixed,
      rightFixedWidthCm:
          double.tryParse(_rightFixedWCtrl.text.trim()) ?? 40.0,
      rightFixedSplits: _rightFixedSplits,
      hasLeftFixed: _hasLeftFixed,
      leftFixedWidthCm:
          double.tryParse(_leftFixedWCtrl.text.trim()) ?? 40.0,
      leftFixedSplits: _leftFixedSplits,
      hasExhaustFan: _hasExhaustFan,
      exhaustFanShape: _exhaustFanShape,
      exhaustFanDiameterCm:
          double.tryParse(_exhaustFanDiamCtrl.text.trim()) ?? 25.0,
      exhaustFanPosition: _exhaustFanPosition,
      hasGlass: _hasGlass,
      isDoubleGlass: _isDoubleGlass,
      glass1Id: _selectedGlass1.id,
      glass1Name: _customGlassTextCtrl.text.trim().isNotEmpty
          ? _customGlassTextCtrl.text.trim()
          : _selectedGlass1.name,
      glass1PricePerM2: _selectedGlass1.pricePerSquareMeter,
      glass2Id: _selectedGlass2.id,
      glass2Name: _selectedGlass2.name,
      glass2PricePerM2: _selectedGlass2.pricePerSquareMeter,
      spacerPricePerMeter:
          widget.storage.pricingSettings.doubleSpacerPricePerMeter,
      hasGeorgianBars: _hasGeorgian,
      georgianMetersPerWindow:
          double.tryParse(_georgianMetersCtrl.text.trim()) ?? 0.0,
      georgianPricePerMeter:
          widget.storage.pricingSettings.georgianBarPricePerMeter,
    );
  }

  @override
  Widget build(BuildContext context) {
    final curItem = _buildCurrentWindowItem();
    final minOneM2 =
        widget.storage.pricingSettings.enforceMinimumOneSquareMeter;
    final singleArea = curItem.displaySingleAreaM2(minOneM2: minOneM2);
    final totalCost =
        curItem.calculateTotalCost(_selectedSector, minOneM2: minOneM2);

    return Scaffold(
      resizeToAvoidBottomInset: false, // يمنع اختفاء شاشة المعاينة عند فتح الكيبورد!
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B110A),
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: Row(
          children: [
            if (_selectedSector.companyLogoAsset != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    _selectedSector.companyLogoAsset!,
                    width: 28,
                    height: 28,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            Expanded(
              child: Text(
                _selectedSector.name,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // زر اختيار سريع بين (منزلق) و (مفصلي) في الهيدر
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: SegmentedButton<String>(
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 6)),
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const Color(0xFFD97706);
                  }
                  return const Color(0xFF334155);
                }),
                foregroundColor: const WidgetStatePropertyAll(Colors.white),
              ),
              segments: const [
                ButtonSegment(
                  value: 'منزلق',
                  label: Text('منزلق', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                ButtonSegment(
                  value: 'مفصلي',
                  label: Text('مفصلي', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
              selected: {_selectedCategory},
              onSelectionChanged: (s) => _switchCategory(s.first),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ==================== 1. شاشة المعاينة الحية المثبتة في الأعلى دائماً ====================
          Container(
            color: const Color(0xFF0F172A),
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
            child: Column(
              children: [
                Window2DVisualizer(
                  widthCm: curItem.widthCm,
                  heightCm: curItem.heightCm,
                  unitType: curItem.unitType,
                  openType: curItem.openType,
                  sashCount: curItem.sashCount,
                  barType: curItem.barType,
                  openDirection: curItem.openDirection,
                  sectorColor: curItem.sectorColor,
                  hasTopFixed: curItem.hasTopFixed,
                  topFixedHeightCm: curItem.topFixedHeightCm,
                  topFixedSplits: curItem.topFixedSplits,
                  hasBottomFixed: curItem.hasBottomFixed,
                  bottomFixedHeightCm: curItem.bottomFixedHeightCm,
                  bottomFixedSplits: curItem.bottomFixedSplits,
                  hasRightFixed: curItem.hasRightFixed,
                  rightFixedWidthCm: curItem.rightFixedWidthCm,
                  rightFixedSplits: curItem.rightFixedSplits,
                  hasLeftFixed: curItem.hasLeftFixed,
                  leftFixedWidthCm: curItem.leftFixedWidthCm,
                  leftFixedSplits: curItem.leftFixedSplits,
                  hasExhaustFan: curItem.hasExhaustFan,
                  exhaustFanShape: curItem.exhaustFanShape,
                  exhaustFanDiameterCm: curItem.exhaustFanDiameterCm,
                  exhaustFanPosition: curItem.exhaustFanPosition,
                  hasGlass: curItem.hasGlass,
                  isDoubleGlass: curItem.isDoubleGlass,
                  hasGeorgian: curItem.hasGeorgianBars,
                  hasFlyScreen: curItem.hasFlyScreen,
                  height: 175,
                ),
                const SizedBox(height: 6),
                // شريط ملخص فوري تحت المعاينة
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'صافي المتحرك: ${curItem.netOperableWidthCm.toStringAsFixed(0)}×${curItem.netOperableHeightCm.toStringAsFixed(0)} سم',
                      style: const TextStyle(
                        color: Color(0xFFBAE6FD),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'المساحة: ${singleArea.toStringAsFixed(2)} م² × ${curItem.quantity}',
                      style: const TextStyle(
                        color: Color(0xFFFDE68A),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF15803D),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        'الإجمالي: ${totalCost.toStringAsFixed(0)} ج.م',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ==================== 2. تبويبات الخيارات السفلية المدمجة ====================
          Container(
            color: const Color(0xFF1E293B),
            child: TabBar(
              controller: _optionsTabController,
              isScrollable: false,
              labelColor: const Color(0xFFF59E0B),
              unselectedLabelColor: Colors.white70,
              indicatorColor: const Color(0xFFF59E0B),
              labelStyle:
                  const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: '1. المقاس والضلف'),
                Tab(text: '2. الثوابت (٤ جهات)'),
                Tab(text: '3. القطاع والزجاج'),
                Tab(text: '4. الشفاط وإضافات'),
              ],
            ),
          ),

          // ==================== 3. محتوى التبويب المختار (مع بقاء المعاينة فوق مرئية دائماً) ====================
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom > 0
                    ? MediaQuery.of(context).viewInsets.bottom * 0.45
                    : 0,
              ),
              child: TabBarView(
                controller: _optionsTabController,
                children: [
                  _buildDimensionsAndSashesTab(),
                  _buildFixedPanelsTab(),
                  _buildSectorAndGlassTab(),
                  _buildExhaustAndExtrasTab(),
                ],
              ),
            ),
          ),

          // ==================== 4. زر الحفظ والإضافة بنفس الشكل ====================
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF15803D),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.pop(context, _buildCurrentWindowItem());
                  },
                  icon: const Icon(Icons.check_circle, size: 20),
                  label: Text(
                    widget.existingItem == null
                        ? 'إضافة الشباك بنفس شكله للطلبية وعرض السعر'
                        : 'حفظ التعديلات على الشباك',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// التبويب الأول: المقاس، نوع الفتحة، منزلق/مفصلي، عدد الضلف، البار، السلك
  Widget _buildDimensionsAndSashesTab() {
    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        // صف المقاسات الأساسي (العرض، الطول، العدد، رمز البند)
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _widthCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'العرض (سم)',
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _heightCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'الطول / الارتفاع (سم)',
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: TextField(
                controller: _qtyCtrl,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'العدد',
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: TextField(
                controller: _labelCtrl,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'الرمز',
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // اختيار طريقة الفتح (جرار منزلق | مفصلي | قلاب | ثابت)
        const Text(
          'نظام الفتح وعدد الضلف:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final t in ['جرار', 'مفصلي', 'قلاب', 'ثابت'])
              ChoiceChip(
                label: Text(t == 'جرار' ? 'منزلق (جرار)' : t),
                selected: _openType == t,
                selectedColor: const Color(0xFF31869B),
                labelStyle: TextStyle(
                  color: _openType == t ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                onSelected: (_) {
                  setState(() {
                    _openType = t;
                    if (t == 'جرار') {
                      _selectedCategory = 'منزلق';
                      if (_sashCount < 2) _sashCount = 2;
                    } else if (t == 'مفصلي' || t == 'قلاب') {
                      _selectedCategory = 'مفصلي';
                      if (t == 'قلاب') _sashCount = 1;
                    }
                  });
                },
              ),
          ],
        ),
        const SizedBox(height: 8),

        // عدد الضلف (1، 2، 3، 4) + نوع الوحدة (شباك / باب)
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  const Text('الضلف: ',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  for (final sc in [1, 2, 3, 4])
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: ChoiceChip(
                        visualDensity: VisualDensity.compact,
                        label: Text('$sc'),
                        selected: _sashCount == sc,
                        selectedColor: const Color(0xFFD97706),
                        labelStyle: TextStyle(
                          color:
                              _sashCount == sc ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        onSelected: (_) => setState(() => _sashCount = sc),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                value: _unitType,
                decoration: const InputDecoration(
                  labelText: 'شباك / باب',
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'شباك', child: Text('شباك')),
                  DropdownMenuItem(value: 'باب', child: Text('باب')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _unitType = v);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // البار، اتجاه الفتح، والسلك
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _barType,
                decoration: const InputDecoration(
                  labelText: 'البار (الحلق)',
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'ببار', child: Text('حلق ببار')),
                  DropdownMenuItem(
                      value: 'بدون بار', child: Text('حلق بدون بار')),
                  DropdownMenuItem(
                      value: 'بار مقلوب', child: Text('بار مقلوب / تجميع')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _barType = v);
                },
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _openDirection,
                decoration: const InputDecoration(
                  labelText: 'اتجاه الفتح',
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'يمين للداخل', child: Text('يمين للداخل')),
                  DropdownMenuItem(
                      value: 'شمال للداخل', child: Text('شمال للداخل')),
                  DropdownMenuItem(
                      value: 'يمين للخارج', child: Text('يمين للخارج')),
                  DropdownMenuItem(
                      value: 'شمال للخارج', child: Text('شمال للخارج')),
                  DropdownMenuItem(
                      value: 'قلاب لأعلى', child: Text('قلاب لأعلى')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _openDirection = v);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SwitchListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: const Text('إضافة سلك مانع للحشرات (ضلفة سلك)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
          value: _hasFlyScreen,
          onChanged: (v) => setState(() => _hasFlyScreen = v),
        ),
      ],
    );
  }

  /// التبويب الثاني: الثوابت وأماكنها (شمال، يمين، فوق، تحت) ومقاساتها وتقسيماتها
  Widget _buildFixedPanelsTab() {
    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        const Text(
          'اختر مكان الثابت (شمال / يمين / فوق / تحت) وحدد مقاسه بالـ سم، وشاهد تغيّره فوراً في المعاينة بالأعلى:',
          style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 8),

        // 1. ثابت شمال (يسار)
        _buildFixedPanelControlCard(
          title: '⬅️ ثابت شمال (يسار الشباك)',
          enabled: _hasLeftFixed,
          onToggle: (v) => setState(() => _hasLeftFixed = v),
          sizeCtrl: _leftFixedWCtrl,
          sizeLabel: 'عرض الثابت الشمال (سم)',
          splits: _leftFixedSplits,
          onSplitsChanged: (s) => setState(() => _leftFixedSplits = s),
        ),

        // 2. ثابت يمين
        _buildFixedPanelControlCard(
          title: '➡️ ثابت يمين الشباك',
          enabled: _hasRightFixed,
          onToggle: (v) => setState(() => _hasRightFixed = v),
          sizeCtrl: _rightFixedWCtrl,
          sizeLabel: 'عرض الثابت اليمين (سم)',
          splits: _rightFixedSplits,
          onSplitsChanged: (s) => setState(() => _rightFixedSplits = s),
        ),

        // 3. ثابت علوي (فوق)
        _buildFixedPanelControlCard(
          title: '⬆️ ثابت علوي (فوق الشباك)',
          enabled: _hasTopFixed,
          onToggle: (v) => setState(() => _hasTopFixed = v),
          sizeCtrl: _topFixedHCtrl,
          sizeLabel: 'ارتفاع الثابت العلوي (سم)',
          splits: _topFixedSplits,
          onSplitsChanged: (s) => setState(() => _topFixedSplits = s),
        ),

        // 4. ثابت سفلي (تحت)
        _buildFixedPanelControlCard(
          title: '⬇️ ثابت سفلي (جلسة تحت الشباك)',
          enabled: _hasBottomFixed,
          onToggle: (v) => setState(() => _hasBottomFixed = v),
          sizeCtrl: _bottomFixedHCtrl,
          sizeLabel: 'ارتفاع الثابت السفلي (سم)',
          splits: _bottomFixedSplits,
          onSplitsChanged: (s) => setState(() => _bottomFixedSplits = s),
        ),
      ],
    );
  }

  Widget _buildFixedPanelControlCard({
    required String title,
    required bool enabled,
    required ValueChanged<bool> onToggle,
    required TextEditingController sizeCtrl,
    required String sizeLabel,
    required int splits,
    required ValueChanged<int> onSplitsChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: enabled ? const Color(0xFFFEF3C7) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: enabled ? const Color(0xFFD97706) : Colors.grey.shade300,
          width: enabled ? 1.4 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12.5)),
                Switch(
                  value: enabled,
                  activeColor: const Color(0xFFD97706),
                  onChanged: onToggle,
                ),
              ],
            ),
            if (enabled)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: sizeCtrl,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: sizeLabel,
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<int>(
                        value: splits,
                        decoration: const InputDecoration(
                          labelText: 'تقسيم الثابت',
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('قطعة واحدة')),
                          DropdownMenuItem(value: 2, child: Text('مقسوم 2')),
                          DropdownMenuItem(value: 3, child: Text('مقسوم 3')),
                          DropdownMenuItem(value: 4, child: Text('مقسوم 4')),
                        ],
                        onChanged: (v) {
                          if (v != null) onSplitsChanged(v);
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// التبويب الثالث: اختيار القطاع، اللون، نوع الزجاج، وسعر المتر
  Widget _buildSectorAndGlassTab() {
    final allSectors = widget.storage.sectors;
    final glasses = widget.storage.glassTypes;

    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        // اختيار القطاع مع عرض صورة المقطع ورابط الكتالوج
        Row(
          children: [
            SvgProfileWidget(
              assetPath: _selectedSector.primaryProfileSvg,
              width: 46,
              height: 46,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedSector.id,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'القطاع المختار',
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
                items: allSectors
                    .map((s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(
                            '[${s.companyGroup}] ${s.name}',
                            style: const TextStyle(fontSize: 11.5),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    final found = widget.storage.getSectorById(val);
                    if (found != null) {
                      setState(() {
                        _selectedSector = found;
                        _pricePerM2Ctrl.text =
                            found.pricePerSquareMeter.toStringAsFixed(0);
                      });
                    }
                  }
                },
              ),
            ),
            if (_selectedSector.catalogUrl.isNotEmpty)
              IconButton(
                tooltip: 'فتح كتالوج القطاع',
                icon: const Icon(Icons.menu_book, color: Color(0xFFD97706)),
                onPressed: () {
                  NativeFileService.openExternalUrl(_selectedSector.catalogUrl);
                },
              ),
          ],
        ),
        const SizedBox(height: 8),

        // لون القطاع + سعر المتر المربع
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _sectorColor,
                decoration: const InputDecoration(
                  labelText: 'لون القطاع',
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'بيج', child: Text('بيج')),
                  DropdownMenuItem(value: 'أسود', child: Text('أسود')),
                  DropdownMenuItem(value: 'أبيض', child: Text('أبيض')),
                  DropdownMenuItem(value: 'رمادي', child: Text('رمادي')),
                  DropdownMenuItem(value: 'خشابي', child: Text('خشابي')),
                  DropdownMenuItem(value: 'شامبين', child: Text('شامبين')),
                  DropdownMenuItem(value: 'فضي', child: Text('فضي')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _sectorColor = v);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _pricePerM2Ctrl,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'سعر المتر المربع (ج.م)',
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // اختيار نوع الزجاج من قائمة التسعير
        DropdownButtonFormField<String>(
          value: _selectedGlass1.id,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'اختيار نوع الزجاج من قائمة التسعير',
            isDense: true,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(),
          ),
          items: glasses
              .map((g) => DropdownMenuItem(
                    value: g.id,
                    child: Text(
                      '${g.name.replaceAll('\n', ' ')} (${g.pricePerSquareMeter.toStringAsFixed(0)} ج.م/م²)',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) {
              final g = glasses.firstWhere((e) => e.id == v);
              setState(() {
                _selectedGlass1 = g;
                _isDoubleGlass = g.isDoublePreset;
                _customGlassTextCtrl.text = g.name;
              });
            }
          },
        ),
        const SizedBox(height: 8),

        // نص نوع الزجاج والتوصيف المطبوع في جدول عرض السعر PDF
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customGlassTextCtrl,
                maxLines: 2,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'تسمية الزجاج في الـ PDF',
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _customPdfDescCtrl,
                maxLines: 2,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'توصيف البند في الـ PDF (اختياري)',
                  hintText: 'تلقائي: جرار ٢ ضلفة UPVC كبير',
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SwitchListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'سعر المتر شامل الزجاج والإكسسوارات (كما في نظام عرض السعر)',
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
          ),
          subtitle: const Text(
            'عند الإلغاء يجمع البرنامج سعر متر القطاع + سعر متر الزجاج منفصلين',
            style: TextStyle(fontSize: 10.5),
          ),
          value: _isCombinedMeterPrice,
          onChanged: (v) => setState(() => _isCombinedMeterPrice = v),
        ),
      ],
    );
  }

  /// التبويب الرابع: الشفاط والجورجيا
  Widget _buildExhaustAndExtrasTab() {
    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  secondary: Image.asset(
                    'assets/images/windows/suction.png',
                    width: 34,
                    height: 34,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.cyclone, color: Colors.red),
                  ),
                  title: const Text('إضافة فتحة شفاط (للمطابخ والحمامات)',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  value: _hasExhaustFan,
                  onChanged: (v) => setState(() => _hasExhaustFan = v),
                ),
                if (_hasExhaustFan) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _exhaustFanDiamCtrl,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'مقاس الشفاط (سم)',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _exhaustFanPosition,
                          decoration: const InputDecoration(
                            labelText: 'مكان الشفاط',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'في الثابت العلوي',
                                child: Text('في الثابت العلوي')),
                            DropdownMenuItem(
                                value: 'في الضلفة يمين',
                                child: Text('في الضلفة يمين')),
                            DropdownMenuItem(
                                value: 'في الضلفة شمال',
                                child: Text('في الضلفة شمال')),
                            DropdownMenuItem(
                                value: 'في المنتصف',
                                child: Text('في المنتصف')),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _exhaustFanPosition = v);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('إضافة شبكة أعواد جورجيا داخل الزجاج',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  value: _hasGeorgian,
                  onChanged: (v) => setState(() => _hasGeorgian = v),
                ),
                if (_hasGeorgian)
                  TextField(
                    controller: _georgianMetersCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'عدد أمتار الجورجيا للشباك الواحد',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
