import 'package:flutter/material.dart';
import '../models/workshop_models.dart';
import '../services/native_file_service.dart';
import '../services/pdf_generator_service.dart';
import '../services/workshop_storage.dart';
import '../widgets/svg_profile_widget.dart';
import '../widgets/window_2d_visualizer.dart';
import 'window_designer_screen.dart';

class ClientsQuotationsScreen extends StatefulWidget {
  final WorkshopStorage storage;
  const ClientsQuotationsScreen({super.key, required this.storage});

  @override
  State<ClientsQuotationsScreen> createState() =>
      _ClientsQuotationsScreenState();
}

class _ClientsQuotationsScreenState extends State<ClientsQuotationsScreen> {
  String _searchQuery = '';

  void _openClientEditor({
    ClientRecord? existing,
    String? initialCategory,
    String? initialCompanyGroup,
    SectorProfile? initialSector,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClientQuotationEditorPage(
          storage: widget.storage,
          existingClient: existing,
          initialCategory: initialCategory,
          initialCompanyGroup: initialCompanyGroup,
          initialSector: initialSector,
        ),
      ),
    );
  }

  /// عند الضغط على أي شركة في الورشة الذكية: يختار أولاً (منزلق) أو (مفصلي) ثم يختار القطاع أو يفتح الكتالوج
  void _showCompanySlidingOrHingedSelector(Map<String, String> company) {
    final String groupName = company['name']!;
    final String groupLogo = company['logo']!;
    String selectedCat = 'منزلق';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final matchingSectors = widget.storage.sectors.where((s) {
            final grpMatch = s.companyGroup == groupName;
            final catMatch =
                selectedCat == 'منزلق' ? s.isSliding : s.isHinged;
            return grpMatch && catMatch;
          }).toList();

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.72,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // هيدر الشركة ورابط الكتالوج
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        groupLogo,
                        width: 48,
                        height: 48,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.business, size: 40),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            groupName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            company['subtitle'] ?? '',
                            style: const TextStyle(
                                fontSize: 11.5, color: Color(0xFF475569)),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: const Color(0xFFB45309),
                      ),
                      onPressed: () {
                        NativeFileService.openExternalUrl(
                            company['catalogUrl'] ?? '');
                      },
                      icon: const Icon(Icons.menu_book, size: 16),
                      label: const Text('الكتالوج',
                          style: TextStyle(fontSize: 11.5)),
                    ),
                  ],
                ),
                const Divider(height: 20),

                // الخطوة 1: اختر منزلق ولا مفصلي أولاً
                const Text(
                  '1. اختر نوع النظام أولاً (منزلق أو مفصلي):',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: Color(0xFF7F1D1D)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setModalState(() => selectedCat = 'منزلق'),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selectedCat == 'منزلق'
                                ? const Color(0xFF31869B)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selectedCat == 'منزلق'
                                  ? const Color(0xFF31869B)
                                  : Colors.grey.shade400,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.compare_arrows,
                                color: selectedCat == 'منزلق'
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'منزلق (جرار)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: selectedCat == 'منزلق'
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () => setModalState(() => selectedCat = 'مفصلي'),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selectedCat == 'مفصلي'
                                ? const Color(0xFFD97706)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selectedCat == 'مفصلي'
                                  ? const Color(0xFFD97706)
                                  : Colors.grey.shade400,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.sensor_door_outlined,
                                color: selectedCat == 'مفصلي'
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'مفصلي / قلاب',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: selectedCat == 'مفصلي'
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // الخطوة 2: اختر القطاع لبدء التصميم وحساب الطلبية وعرض السعر
                Text(
                  '2. اختر قطاع الـ $selectedCat لبدء حساب الطلبية أو عرض السعر:',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: matchingSectors.length,
                    itemBuilder: (ctx, i) {
                      final sec = matchingSectors[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: ListTile(
                          onTap: () {
                            Navigator.pop(ctx);
                            _openClientEditor(
                              initialCategory: selectedCat,
                              initialCompanyGroup: groupName,
                              initialSector: sec,
                            );
                          },
                          leading: SvgProfileWidget(
                            assetPath: sec.primaryProfileSvg,
                            width: 48,
                            height: 48,
                          ),
                          title: Text(
                            sec.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13.5),
                          ),
                          subtitle: Text(
                            'سعر المتر: ${sec.pricePerSquareMeter.toStringAsFixed(0)} ج.م/م² • اضغط لفتح المعاينة والطلبية',
                            style: const TextStyle(fontSize: 11.5),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (sec.catalogUrl.isNotEmpty)
                                IconButton(
                                  tooltip: 'رابط الكتالوج',
                                  icon: const Icon(Icons.menu_book,
                                      color: Color(0xFFD97706), size: 20),
                                  onPressed: () {
                                    NativeFileService.openExternalUrl(
                                        sec.catalogUrl);
                                  },
                                ),
                              const Icon(Icons.arrow_forward_ios,
                                  size: 16, color: Color(0xFF31869B)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allClients = widget.storage.clients;
    final filtered = _searchQuery.trim().isEmpty
        ? allClients
        : allClients
            .where((c) =>
                c.clientName.contains(_searchQuery) ||
                c.clientAddress.contains(_searchQuery) ||
                c.clientPhone.contains(_searchQuery))
            .toList();

    final bool minOneM2 =
        widget.storage.pricingSettings.enforceMinimumOneSquareMeter;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // ==================== 1. قسم الورشة الذكية (نفس ترتيب وصور المشروع المماثل بالظبط) ====================
          Card(
            elevation: 2,
            color: const Color(0xFF0F172A),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/home_icon/repair-shop.png',
                        width: 28,
                        height: 28,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.precision_manufacturing,
                            color: Color(0xFFF59E0B)),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'الورشة الذكية — اختر الشركة ثم (منزلق / مفصلي) لحساب الطلبية أو عرض السعر:',
                          style: TextStyle(
                            color: Color(0xFFFDE68A),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: WorkshopStorage.companyGroupsOrder.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.82,
                    ),
                    itemBuilder: (ctx, i) {
                      final comp = WorkshopStorage.companyGroupsOrder[i];
                      return InkWell(
                        onTap: () => _showCompanySlidingOrHingedSelector(comp),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: const Color(0xFFD97706), width: 1.2),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Image.asset(
                                  comp['logo']!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.window, size: 32),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                comp['name']!,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                  height: 1.15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ==================== 2. شريط البحث وبدء عرض سعر / طلبية جديدة ====================
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'ابحث باسم العميل أو المكان...',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF15803D),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onPressed: () => _openClientEditor(),
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text(
                  'عرض سعر / طلبية جديدة',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ==================== 3. قائمة عروض الأسعار والطلبيات المحفوظة ====================
          ...filtered.map((client) {
            double totalPrice = 0.0;
            double totalArea = 0.0;
            for (final item in client.items) {
              final sec = widget.storage.getSectorById(item.sectorId);
              totalPrice += item.calculateTotalCost(sec, minOneM2: minOneM2);
              totalArea += item.displayTotalAreaM2(minOneM2: minOneM2);
            }
            final netPrice =
                (totalPrice - client.discountAmount + client.archCost - client.depositAmount)
                    .clamp(0.0, double.infinity);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'أسم العميل / ${client.clientName}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15.5,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              if (client.clientAddress.isNotEmpty)
                                Text(
                                  'المكان / ${client.clientAddress}',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFF31869B),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF388E9C),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${PdfGeneratorService.formatMoney(netPrice)} EGP',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'عدد الشبابيك: ${client.items.length} بند • إجمالي المساحة: ${totalArea.toStringAsFixed(2)} m² • التاريخ: ${client.createdAt}',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF475569)),
                    ),
                    const Divider(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E293B),
                            foregroundColor: Colors.white,
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () => _openClientEditor(existing: client),
                          icon: const Icon(Icons.edit_note, size: 18),
                          label: const Text('فتح وتعديل العرض والطلبية'),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF388E9C),
                            foregroundColor: Colors.white,
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () {
                            PdfGeneratorService.showPdfExportOptionsSheet(
                              context: context,
                              title: 'PDF عرض السعر — ${client.clientName}',
                              defaultFileName:
                                  'عرض_سعر_${client.clientName}.pdf',
                              buildBytes: () =>
                                  PdfGeneratorService.buildQuotationPdfBytes(
                                client: client,
                                storage: widget.storage,
                              ),
                            );
                          },
                          icon: const Icon(Icons.picture_as_pdf, size: 17),
                          label: const Text('PDF عرض السعر (حفظ/مشاركة)'),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF15803D),
                            foregroundColor: Colors.white,
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () {
                            PdfGeneratorService.showPdfExportOptionsSheet(
                              context: context,
                              title:
                                  'PDF حساب الطلبية وتقطيع الأعواد — ${client.clientName}',
                              defaultFileName:
                                  'حساب_طلبية_${client.clientName}.pdf',
                              buildBytes: () =>
                                  PdfGeneratorService.buildCuttingListPdfBytes(
                                client: client,
                                storage: widget.storage,
                              ),
                            );
                          },
                          icon: const Icon(Icons.carpenter, size: 17),
                          label: const Text('PDF حساب الطلبية'),
                        ),
                        IconButton(
                          tooltip: 'حذف المقايسة',
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          onPressed: () =>
                              widget.storage.deleteClientRecord(client.id),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// شاشة تحرير عرض السعر وحساب الطلبية للعميل
class ClientQuotationEditorPage extends StatefulWidget {
  final WorkshopStorage storage;
  final ClientRecord? existingClient;
  final String? initialCategory;
  final String? initialCompanyGroup;
  final SectorProfile? initialSector;

  const ClientQuotationEditorPage({
    super.key,
    required this.storage,
    this.existingClient,
    this.initialCategory,
    this.initialCompanyGroup,
    this.initialSector,
  });

  @override
  State<ClientQuotationEditorPage> createState() =>
      _ClientQuotationEditorPageState();
}

class _ClientQuotationEditorPageState extends State<ClientQuotationEditorPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _clientNameCtrl = TextEditingController();
  final _clientPhoneCtrl = TextEditingController();
  final _clientAddressCtrl = TextEditingController();
  final _discountCtrl = TextEditingController(text: '0');
  final _depositCtrl = TextEditingController(text: '0');
  final _archCostCtrl = TextEditingController(text: '0');

  List<ClientWindowItem> _items = [];
  late String _recordId;
  late String _createdAt;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final ex = widget.existingClient;
    if (ex != null) {
      _recordId = ex.id;
      _createdAt = ex.createdAt;
      _clientNameCtrl.text = ex.clientName;
      _clientPhoneCtrl.text = ex.clientPhone;
      _clientAddressCtrl.text = ex.clientAddress;
      _discountCtrl.text = ex.discountAmount.toStringAsFixed(0);
      _depositCtrl.text = ex.depositAmount.toStringAsFixed(0);
      _archCostCtrl.text = ex.archCost.toStringAsFixed(0);
      _items = ex.items
          .map((e) => ClientWindowItem.fromJson(e.toJson()))
          .toList();
    } else {
      final now = DateTime.now();
      _recordId = 'client_${now.millisecondsSinceEpoch}';
      _createdAt =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // إذا دخل المستخدم من اختيار قطاع في الورشة الذكية مباشرة نفتح له شاشة تصميم الشباك فوراً
      if (widget.initialSector != null || widget.initialCategory != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _openWindowDesigner(
            initialCategory: widget.initialCategory,
            initialCompanyGroup: widget.initialCompanyGroup,
            initialSector: widget.initialSector,
          );
        });
      }
    }
  }

  ClientRecord _buildCurrentRecord() {
    return ClientRecord(
      id: _recordId,
      clientName: _clientNameCtrl.text.trim().isEmpty
          ? 'أ. احمد ابو اليزيد'
          : _clientNameCtrl.text.trim(),
      clientPhone: _clientPhoneCtrl.text.trim(),
      clientAddress: _clientAddressCtrl.text.trim().isEmpty
          ? 'ابراج الروضه شارع ناصر'
          : _clientAddressCtrl.text.trim(),
      createdAt: _createdAt,
      discountAmount: double.tryParse(_discountCtrl.text.trim()) ?? 0.0,
      depositAmount: double.tryParse(_depositCtrl.text.trim()) ?? 0.0,
      archCost: double.tryParse(_archCostCtrl.text.trim()) ?? 0.0,
      items: _items,
    );
  }

  Future<void> _saveRecord({bool showSnack = true}) async {
    final rec = _buildCurrentRecord();
    await widget.storage.saveClientRecord(rec);
    if (showSnack && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('تم حفظ مقايسة وطلبية "${rec.clientName}" بنجاح')),
      );
    }
  }

  /// فتح شاشة تصميم الشباك المستقلة ذات المعاينة المثبتة بالأعلى
  Future<void> _openWindowDesigner({
    ClientWindowItem? existing,
    int? editIdx,
    String? initialCategory,
    String? initialCompanyGroup,
    SectorProfile? initialSector,
  }) async {
    final result = await Navigator.of(context).push<ClientWindowItem>(
      MaterialPageRoute(
        builder: (_) => WindowDesignerScreen(
          storage: widget.storage,
          existingItem: existing,
          nextIndex: _items.length + 1,
          initialCategory: initialCategory,
          initialCompanyGroup: initialCompanyGroup,
          initialSector: initialSector,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        if (editIdx != null) {
          _items[editIdx] = result;
        } else {
          _items.add(result);
        }
      });
      await _saveRecord(showSnack: false);
    }
  }

  /// اختيار سريع (منزلق أو مفصلي) قبل فتح مصمم الشباك
  void _promptSlidingOrHingedThenDesign() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('اختر نوع الشباك / الباب أولاً',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF31869B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _openWindowDesigner(initialCategory: 'منزلق');
                },
                icon: const Icon(Icons.compare_arrows),
                label: const Text('منزلق\n(جرار)',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _openWindowDesigner(initialCategory: 'مفصلي');
                },
                icon: const Icon(Icons.sensor_door_outlined),
                label: const Text('مفصلي\n/ قلاب',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool minOneM2 =
        widget.storage.pricingSettings.enforceMinimumOneSquareMeter;

    double totalAreaAll = 0.0;
    int totalQtyAll = 0;
    double grandTotalAll = 0.0;

    for (final it in _items) {
      final sec = widget.storage.getSectorById(it.sectorId);
      totalAreaAll += it.displayTotalAreaM2(minOneM2: minOneM2);
      totalQtyAll += it.quantity;
      grandTotalAll += it.calculateTotalCost(sec, minOneM2: minOneM2);
    }

    final double discount = double.tryParse(_discountCtrl.text.trim()) ?? 0.0;
    final double deposit = double.tryParse(_depositCtrl.text.trim()) ?? 0.0;
    final double arch = double.tryParse(_archCostCtrl.text.trim()) ?? 0.0;
    final double finalNet =
        (grandTotalAll - discount + arch - deposit).clamp(0.0, double.infinity);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B110A),
        foregroundColor: Colors.white,
        title: const Text('عرض السعر وحساب الطلبية — شركة الحافظ',
            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold)),
        actions: [
          TextButton.icon(
            onPressed: () => _saveRecord(showSnack: true),
            icon: const Icon(Icons.save, color: Color(0xFFF59E0B), size: 18),
            label: const Text('حفظ',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFF59E0B),
          unselectedLabelColor: Colors.white70,
          indicatorColor: const Color(0xFFF59E0B),
          tabs: const [
            Tab(
              icon: Icon(Icons.request_quote, size: 18),
              text: '1. عرض السعر بالرسم والمقاسات',
            ),
            Tab(
              icon: Icon(Icons.precision_manufacturing, size: 18),
              text: '2. حساب الطلبية وتقطيع الأعواد',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // بيانات العميل والعنوان والعربون والدورانات
          Container(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            color: const Color(0xFFF8FAFC),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _clientNameCtrl,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'أسم العميل /',
                          hintText: 'مثال: أ. احمد ابو اليزيد',
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        controller: _clientAddressCtrl,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'المكان / العنوان',
                          hintText: 'مثال: ابراج الروضه شارع ناصر',
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _depositCtrl,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'عربون (ج.م)',
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        controller: _archCostCtrl,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'دورانات (ج.م)',
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        controller: _discountCtrl,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'خصم (ج.م)',
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                      ),
                      onPressed: _promptSlidingOrHingedThenDesign,
                      icon: const Icon(Icons.add_box, size: 18),
                      label: const Text(
                        '+ إضافة شباك',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // محتوى التبويبين (عرض السعر بالرسم | حساب الطلبية وتقطيع الأعواد)
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildQuotationVisualListTab(
                  minOneM2: minOneM2,
                  totalQtyAll: totalQtyAll,
                  totalAreaAll: totalAreaAll,
                  grandTotalAll: grandTotalAll,
                  finalNet: finalNet,
                ),
                _buildSmartWorkshopOrderCalculationTab(),
              ],
            ),
          ),

          // شريط أزرار استخراج وحفظ الـ PDF في مدير الملفات بالأسفل
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: const Color(0xFF1B110A),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF388E9C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () async {
                        await _saveRecord(showSnack: false);
                        final rec = _buildCurrentRecord();
                        if (!context.mounted) return;
                        PdfGeneratorService.showPdfExportOptionsSheet(
                          context: context,
                          title: 'تصدير وحفظ PDF عرض السعر (${rec.clientName})',
                          defaultFileName: 'عرض_سعر_${rec.clientName}.pdf',
                          buildBytes: () =>
                              PdfGeneratorService.buildQuotationPdfBytes(
                            client: rec,
                            storage: widget.storage,
                          ),
                        );
                      },
                      icon: const Icon(Icons.picture_as_pdf, size: 18),
                      label: const Text(
                        'PDF عرض السعر (حفظ بمدير الملفات)',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 11.5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF15803D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () async {
                        await _saveRecord(showSnack: false);
                        final rec = _buildCurrentRecord();
                        if (!context.mounted) return;
                        PdfGeneratorService.showPdfExportOptionsSheet(
                          context: context,
                          title:
                              'تصدير وحفظ PDF حساب الطلبية (${rec.clientName})',
                          defaultFileName: 'حساب_طلبية_${rec.clientName}.pdf',
                          buildBytes: () =>
                              PdfGeneratorService.buildCuttingListPdfBytes(
                            client: rec,
                            storage: widget.storage,
                          ),
                        );
                      },
                      icon: const Icon(Icons.carpenter, size: 18),
                      label: const Text(
                        'PDF حساب الطلبية (حفظ بمدير الملفات)',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 11.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// التبويب الأول: قائمة الشبابيك المرسومة بنفس شكلها الحقيقي مع جدول الإجماليات
  Widget _buildQuotationVisualListTab({
    required bool minOneM2,
    required int totalQtyAll,
    required double totalAreaAll,
    required double grandTotalAll,
    required double finalNet,
  }) {
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.window_outlined, size: 58, color: Colors.grey),
            const SizedBox(height: 10),
            const Text(
              'لا توجد شبابيك مضافة بعد في هذا العرض',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 6),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF31869B),
                foregroundColor: Colors.white,
              ),
              onPressed: _promptSlidingOrHingedThenDesign,
              icon: const Icon(Icons.add),
              label: const Text('إضافة أول شباك (اختر منزلق أو مفصلي)'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        ...List.generate(_items.length, (idx) {
          final item = _items[idx];
          final sec = widget.storage.getSectorById(item.sectorId);
          final singleArea = item.displaySingleAreaM2(minOneM2: minOneM2);
          final totArea = item.displayTotalAreaM2(minOneM2: minOneM2);
          final rowTotal = item.calculateTotalCost(sec, minOneM2: minOneM2);
          final unitPrice =
              item.quantity > 0 ? (rowTotal / item.quantity) : rowTotal;

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: Color(0xFF388E9C), width: 1.1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  // شارة الرقم W1, W2
                  Container(
                    width: 30,
                    height: 86,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF388E9C),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'W${idx + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // رسمة الشباك بنفس شكلها وثوابتها واتجاهها بالضبط!
                  SizedBox(
                    width: 98,
                    height: 86,
                    child: Window2DVisualizer(
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
                      height: 86,
                      isCompact: true,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // بيانات ومقاسات الشباك
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.pdfDescriptionText(sec).replaceAll('\n', ' - '),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'عرض: ${item.widthCm.toStringAsFixed(0)} cm × طول: ${item.heightCm.toStringAsFixed(0)} cm | م²: ${singleArea.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 11.5, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'اللون: ${item.sectorColor} | الزجاج: ${item.glassSummaryText.replaceAll('\n', ' ')}',
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF334155)),
                        ),
                        if (item.hasTopFixed ||
                            item.hasBottomFixed ||
                            item.hasRightFixed ||
                            item.hasLeftFixed ||
                            item.hasExhaustFan)
                          Text(
                            item.configurationSummary,
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFFB45309),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        Text(
                          'سعر المتر: ${item.effectiveMeterPrice(sec).toStringAsFixed(0)} | سعر الوحدة: ${PdfGeneratorService.formatMoney(unitPrice)} | عدد: ${item.quantity}',
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                  ),

                  // الإجمالي وأزرار التعديل والحذف
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF388E9C),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${PdfGeneratorService.formatMoney(rowTotal)} ج.م',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.edit,
                                size: 18, color: Color(0xFF1D4ED8)),
                            onPressed: () => _openWindowDesigner(
                                existing: item, editIdx: idx),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.delete_outline,
                                size: 18, color: Colors.red),
                            onPressed: () {
                              setState(() => _items.removeAt(idx));
                              _saveRecord(showSnack: false);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),

        // ملخص المقايسة النهائي (بنفس ألوان وتصميم الـ PDF)
        Container(
          margin: const EdgeInsets.only(top: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF558ED5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.black, width: 1.2),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'إجمالي العدد: $totalQtyAll شباك',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'إجمالي المساحة: ${totalAreaAll.toStringAsFixed(2)} m2',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(color: Colors.white54),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'إجمالى المقايسة النهائي:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${PdfGeneratorService.formatMoney(finalNet)} EGP',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// التبويب الثاني: حساب الطلبية وتقطيع الأعواد والزجاج والإكسسوارات (مطابق للمشروع المماثل بالضبط)
  Widget _buildSmartWorkshopOrderCalculationTab() {
    if (_items.isEmpty) {
      return const Center(
        child: Text('أضف شبابيك أولاً ليظهر لك حساب الطلبية وتقطيع الأعواد هنا'),
      );
    }

    final aggregatedProfiles =
        widget.storage.calculateAggregatedProfilesOrder(_items);

    int totalBarsAll = 0;
    for (final p in aggregatedProfiles) {
      totalBarsAll += p.totalBarsNeeded;
    }

    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        // ملخص سريع لإجمالي الأعواد المطلوبة
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'إجمالي أعواد الألومنيوم / UPVC في الطلبية:',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$totalBarsAll عود (${widget.storage.pricingSettings.defaultStockBarLengthCm.toStringAsFixed(0)} سم)',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 1. بطاقات كل بروفايل مع صورة مقطعه الـ SVG وأطوال القص وتقسيم الأعواد
        const Text(
          'أولاً: تفصيل القطاعات وعدد الأعواد وخطة القص (كما في الورشة الذكية):',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF7F1D1D)),
        ),
        const SizedBox(height: 6),
        ...aggregatedProfiles.map((prof) {
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SvgProfileWidget(
                        assetPath: prof.svgAssetPath,
                        width: 56,
                        height: 56,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prof.partName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14.5),
                            ),
                            Text(
                              'القطاع: ${prof.sectorName} • إجمالي القطع: ${prof.totalPiecesCount} قطعة',
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF475569)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFD97706)),
                        ),
                        child: Text(
                          '${prof.totalBarsNeeded} عود',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 14),
                  const Text(
                    'مقاسات التفصيل والقص المطلوبة:',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: prof.lengthCounts.entries.map((entry) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF94A3B8)),
                        ),
                        child: Text(
                          'الطول: ${entry.key.toStringAsFixed(1)} سم × العدد: ${entry.value}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(
                      'عرض تقسيم الـ ${prof.totalBarsNeeded} عود وتفاصيل الفضلة (الهالك)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF31869B),
                      ),
                    ),
                    children: prof.barPlans.map((plan) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'العود #${plan.barNumber}: [ ${plan.cutsCm.map((c) => "${c.toStringAsFixed(1)} سم").join(" + ")} ]',
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                            Text(
                              'الفضلة: ${plan.wasteLengthCm.toStringAsFixed(1)} سم',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF991B1B),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        }),

        // 2. كشف مقاسات الزجاج الصافية (شاملاً الثوابت)
        const SizedBox(height: 8),
        const Text(
          'ثانياً: كشف مقاسات الزجاج الصافية (شاملاً الضلف والثوابت):',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF15803D)),
        ),
        const SizedBox(height: 6),
        ..._items.map((item) {
          final sec = widget.storage.getSectorById(item.sectorId);
          final double gw = sec != null
              ? sec.calculateGlassWidthCm(
                  item.netOperableWidthCm, item.sashCount)
              : (item.netOperableWidthCm / item.sashCount) - 10.0;
          final double gh = sec != null
              ? sec.calculateGlassHeightCm(
                  item.netOperableHeightCm, item.sashCount)
              : item.netOperableHeightCm - 18.0;
          final int panes =
              item.sashCount * (item.isDoubleGlass ? 2 : 1) * item.quantity;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              dense: true,
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF15803D),
                foregroundColor: Colors.white,
                child: Text(item.label,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              title: Text(
                'زجاج الضلف: ${gw.toStringAsFixed(1)} × ${gh.toStringAsFixed(1)} سم (العدد: $panes لوح)',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'النوع: ${item.glassSummaryText.replaceAll('\n', ' ')}'),
                  if (item.hasTopFixed)
                    Text(
                      '• زجاج الثابت العلوي: ${(item.widthCm / item.topFixedSplits - 6).toStringAsFixed(1)} × ${(item.topFixedHeightCm - 6).toStringAsFixed(1)} سم (${item.topFixedSplits * item.quantity} قطعة)',
                      style: const TextStyle(
                          color: Color(0xFFB45309),
                          fontWeight: FontWeight.bold),
                    ),
                  if (item.hasBottomFixed)
                    Text(
                      '• زجاج الثابت السفلي: ${(item.widthCm / item.bottomFixedSplits - 6).toStringAsFixed(1)} × ${(item.bottomFixedHeightCm - 6).toStringAsFixed(1)} سم (${item.bottomFixedSplits * item.quantity} قطعة)',
                      style: const TextStyle(
                          color: Color(0xFFB45309),
                          fontWeight: FontWeight.bold),
                    ),
                  if (item.hasRightFixed)
                    Text(
                      '• زجاج الثابت اليمين: ${(item.rightFixedWidthCm - 6).toStringAsFixed(1)} × ${(item.netOperableHeightCm / item.rightFixedSplits - 6).toStringAsFixed(1)} سم (${item.rightFixedSplits * item.quantity} قطعة)',
                      style: const TextStyle(
                          color: Color(0xFFB45309),
                          fontWeight: FontWeight.bold),
                    ),
                  if (item.hasLeftFixed)
                    Text(
                      '• زجاج الثابت الشمال: ${(item.leftFixedWidthCm - 6).toStringAsFixed(1)} × ${(item.netOperableHeightCm / item.leftFixedSplits - 6).toStringAsFixed(1)} سم (${item.leftFixedSplits * item.quantity} قطعة)',
                      style: const TextStyle(
                          color: Color(0xFFB45309),
                          fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
