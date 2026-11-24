import 'package:flutter/material.dart';
import 'api_service.dart';

class DashboardScreen extends StatefulWidget {
  final String username;
  const DashboardScreen({Key? key, required this.username}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _actionController = TextEditingController();
  final TextEditingController _appController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _records = [];
  List<dynamic> _filteredRecords = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchRecords();
  }

  // جلب السجلات من السيرفر المحلي
  Future<void> _fetchRecords() async {
    setState(() => _isLoading = true);
    try {
      final records = await ApiService.getRecords();
      setState(() {
        _records = records;
        _filteredRecords = records;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('تعذر الاتصال بالسيرفر المحلي', Colors.red);
    }
  }

  // حفظ سجل جديد مع الختم الزمني في السحابة المحلية
  Future<void> _saveRecord() async {
    final action = _actionController.text.trim();
    final app = _appController.text.trim();

    if (action.isEmpty || app.isEmpty) {
      _showSnackBar('يرجى ملء حقل الإجراء واسم التطبيق', Colors.orange);
      return;
    }

    try {
      final success = await ApiService.saveRecord(
        action: action,
        app: app,
        user: widget.username,
      );

      if (success) {
        _actionController.clear();
        _appController.clear();
        _showSnackBar('تم حفظ السجل بنجاح في السحابة المحلية', Colors.green);
        _fetchRecords();
      } else {
        _showSnackBar('فشل حفظ السجل', Colors.red);
      }
    } catch (e) {
      _showSnackBar('خطأ في الاتصال: $e', Colors.red);
    }
  }

  // حذف سجل محدد
  Future<void> _deleteRecord(int id) async {
    try {
      final success = await ApiService.deleteRecord(id);
      if (success) {
        _showSnackBar('تم الحذف بنجاح', Colors.green);
        _fetchRecords();
      } else {
        _showSnackBar('فشل حذف السجل', Colors.red);
      }
    } catch (e) {
      _showSnackBar('خطأ في الاتصال: $e', Colors.red);
    }
  }

  // استيراد النسخة الاحتياطية من ملف JSON
  Future<void> _importBackup() async {
    final result = await ApiService.importBackup();
    if (result['success'] == true) {
      _showSnackBar(result['message'], Colors.green);
      _fetchRecords(); // تحديث القائمة فوراً بعد الاستيراد
    } else {
      _showSnackBar(result['message'], Colors.red);
    }
  }

  // البحث الفوري في السجلات
  void _filterRecords(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredRecords = _records;
      } else {
        _filteredRecords = _records.where((r) {
          final action = r['action'].toString().toLowerCase();
          final app = r['app'].toString().toLowerCase();
          final search = query.toLowerCase();
          return action.contains(search) || app.contains(search);
        }).toList();
      }
    });
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nexus Omni Dashboard — مرحباً: ${widget.username}'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'تسجيل الخروج',
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // بطاقة إدخال البيانات والإجراءات
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _actionController,
                      decoration: const InputDecoration(
                        labelText: 'اسم الإجراء (Action)',
                        prefixIcon: Icon(Icons.bolt),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _appController,
                      decoration: const InputDecoration(
                        labelText: 'اسم التطبيق أو المكون (App)',
                        prefixIcon: Icon(Icons.apps),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _saveRecord,
                            icon: const Icon(Icons.cloud_upload),
                            label: const Text('حفظ البيانات مع الختم الزمني في السحابة'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // صف أزرار التحكم: جلب السجلات + تصدير + استيراد
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _fetchRecords,
                    icon: const Icon(Icons.refresh),
                    label: const Text('جلب السجلات'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    await ApiService.exportBackup();
                    _showSnackBar('تم تصدير النسخة الاحتياطية (JSON) بنجاح!', Colors.teal);
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('تصدير نسخة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _importBackup,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('استيراد نسخة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: _filterRecords,
              decoration: const InputDecoration(
                hintText: 'بحث فوري في السجلات...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                '(Activity Log) سجل النشاط الزمني:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            // قائمة عرض السجلات
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredRecords.isEmpty
                      ? const Center(
                          child: Text(
                            'لا توجد سجلات مطابقة، اضغط زر جلب السجلات',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredRecords.length,
                          itemBuilder: (context, index) {
                            final record = _filteredRecords[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              elevation: 2,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.indigo,
                                  child: Text(
                                    '${record['id']}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text('الإجراء: ${record['action']}'),
                                subtitle: Text(
                                    'المستخدم: ${record['user']} | التطبيق: ${record['app']}\nالإنشاء: ${record['created_at']}'),
                                isThreeLine: true,
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteRecord(record['id']),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}