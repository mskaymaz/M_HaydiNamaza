import 'package:flutter/material.dart';

import '../../features/daily_content/editor/daily_content_editor_models.dart';
import '../../features/daily_content/editor/daily_content_editor_storage.dart';

class DailyContentReviewScreen extends StatefulWidget {
  final String approvedBasePath;

  const DailyContentReviewScreen({
    super.key,
    this.approvedBasePath = 'assets/data/daily_content/approved',
  });

  @override
  State<DailyContentReviewScreen> createState() =>
      _DailyContentReviewScreenState();
}

class _DailyContentReviewScreenState extends State<DailyContentReviewScreen>
    with SingleTickerProviderStateMixin {
  late final DailyContentEditorStorage _storage;
  late final TabController _tabController;

  ContentDatasetPayload? _ayahPayload;
  ContentDatasetPayload? _hadithPayload;
  ContentDatasetPayload? _esmaPayload;
  bool _isLoading = true;
  String _searchQuery = '';

  ContentItemRecord? _selectedItem;
  final TextEditingController _arController = TextEditingController();
  final TextEditingController _trController = TextEditingController();
  final TextEditingController _enController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _storage = DailyContentEditorStorage(
      approvedBasePath: widget.approvedBasePath,
    );
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    final ayahs = await _storage.readAyahs();
    final hadiths = await _storage.readHadiths();
    final esma = await _storage.readEsma();
    if (!mounted) return;
    setState(() {
      _ayahPayload = ayahs;
      _hadithPayload = hadiths;
      _esmaPayload = esma;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _arController.dispose();
    _trController.dispose();
    _enController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İçerik İnceleme & Yayınlama Aracı'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Yenile',
            onPressed: _loadAllData,
          ),
          IconButton(
            icon: const Icon(Icons.save_rounded),
            tooltip: 'Kaydet ve Dışa Aktar',
            onPressed: _saveAndExport,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.menu_book_rounded), text: 'Ayetler'),
            Tab(icon: Icon(Icons.format_quote_rounded), text: 'Hadisler'),
            Tab(icon: Icon(Icons.stars_rounded), text: 'Esma-i Hüsna'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Arama Yap (ID, Metin veya Referans)',
                      prefixIcon: Icon(Icons.search_rounded),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildListAndDetail(_ayahPayload?.records ?? []),
                      _buildListAndDetail(_hadithPayload?.records ?? []),
                      _buildListAndDetail(_esmaPayload?.records ?? []),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildListAndDetail(List<ContentItemRecord> records) {
    final filtered = records.where((item) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return item.id.toLowerCase().contains(q) ||
          item.ref.toLowerCase().contains(q) ||
          item.tr.toLowerCase().contains(q) ||
          item.ar.contains(q);
    }).toList();

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final item = filtered[index];
              final isSelected = _selectedItem?.id == item.id;
              return ListTile(
                selected: isSelected,
                leading: CircleAvatar(
                  backgroundColor: item.isApproved
                      ? Colors.green.shade100
                      : Colors.orange.shade100,
                  child: Icon(
                    item.isApproved
                        ? Icons.check_circle_rounded
                        : Icons.pending_rounded,
                    color: item.isApproved ? Colors.green : Colors.orange,
                  ),
                ),
                title: Text(
                  item.ref.isNotEmpty ? item.ref : item.id,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  item.tr,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => _selectItem(item),
              );
            },
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 6,
          child: _selectedItem == null
              ? const Center(child: Text('Düzenlemek için sol taraftan bir öğe seçin.'))
              : _buildEditForm(),
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    final item = _selectedItem!;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Kimlik / Referans: ${item.ref.isNotEmpty ? item.ref : item.id}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SwitchListTile(
                title: Text(item.isApproved ? 'Onaylandı' : 'Beklemede'),
                value: item.isApproved,
                onChanged: (val) {
                  setState(() {
                    _selectedItem = item.copyWith(isApproved: val);
                    _updateCurrentItemInList(_selectedItem!);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _arController,
            maxLines: 3,
            textDirection: TextDirection.rtl,
            decoration: const InputDecoration(
              labelText: 'Arapça Metin (AR)',
              border: OutlineInputBorder(),
            ),
            onChanged: (val) {
              _selectedItem = _selectedItem!.copyWith(ar: val);
              _updateCurrentItemInList(_selectedItem!);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _trController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Türkçe Metin (TR)',
              border: OutlineInputBorder(),
            ),
            onChanged: (val) {
              _selectedItem = _selectedItem!.copyWith(tr: val);
              _updateCurrentItemInList(_selectedItem!);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _enController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'İngilizce Metin (EN)',
              border: OutlineInputBorder(),
            ),
            onChanged: (val) {
              _selectedItem = _selectedItem!.copyWith(en: val);
              _updateCurrentItemInList(_selectedItem!);
            },
          ),
        ],
      ),
    );
  }

  void _selectItem(ContentItemRecord item) {
    setState(() {
      _selectedItem = item;
      _arController.text = item.ar;
      _trController.text = item.tr;
      _enController.text = item.en;
    });
  }

  void _updateCurrentItemInList(ContentItemRecord updated) {
    int index = -1;
    if (_tabController.index == 0 && _ayahPayload != null) {
      index = _ayahPayload!.records.indexWhere((r) => r.id == updated.id);
      if (index != -1) _ayahPayload!.records[index] = updated;
    } else if (_tabController.index == 1 && _hadithPayload != null) {
      index = _hadithPayload!.records.indexWhere((r) => r.id == updated.id);
      if (index != -1) _hadithPayload!.records[index] = updated;
    } else if (_tabController.index == 2 && _esmaPayload != null) {
      index = _esmaPayload!.records.indexWhere((r) => r.id == updated.id);
      if (index != -1) _esmaPayload!.records[index] = updated;
    }
  }

  Future<void> _saveAndExport() async {
    try {
      if (_ayahPayload != null) await _storage.writeAyahs(_ayahPayload!);
      if (_hadithPayload != null) await _storage.writeHadiths(_hadithPayload!);
      if (_esmaPayload != null) await _storage.writeEsma(_esmaPayload!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Onaylanan içerikler başarıyla dışa aktarıldı ve kaydedildi!'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kaydetme hatası: $e')),
      );
    }
  }
}
