import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'api_service.dart';

void main() {
  runApp(const NexusOmniApp());
}

class NexusOmniApp extends StatelessWidget {
  const NexusOmniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nexus Omni - Secure System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const AuthScreen(),
    );
  }
}

// 1. شاشة تسجيل الدخول والإنشاء (Authentication Screen)
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  final String baseUrl = ApiConfig.baseUrl;

  void _submitAuth() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showSnackBar('يرجى إدخال اسم المستخدم وكلمة المرور', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    final endpoint =
        _isLogin ? '$baseUrl/api/v1/login' : '$baseUrl/api/v1/register';

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _showSnackBar(data['message'] ?? 'تم بنجاح', Colors.green);
        if (_isLogin) {
          final String token = data['token'] ?? '';
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardScreen(
                username: username,
                token: token,
              ),
            ),
          );
        } else {
          setState(() {
            _isLogin = true;
          });
        }
      } else {
        _showSnackBar(data['error'] ?? 'حدث خطأ ما', Colors.red);
      }
    } catch (e) {
      _showSnackBar('تعذر الاتصال بالسيرفر المحلي', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.security, size: 64, color: Colors.indigo),
                  const SizedBox(height: 16),
                  Text(
                    _isLogin ? 'تسجيل الدخول - Nexus Omni' : 'إنشاء حساب جديد',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم المستخدم',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'كلمة المرور',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _isLoading ? null : _submitAuth,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              _isLogin ? 'دخول' : 'تسجيل حساب',
                              style: const TextStyle(fontSize: 18),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLogin = !_isLogin;
                      });
                    },
                    child: Text(
                      _isLogin
                          ? 'ليس لديك حساب؟ أنشئ حساباً جديداً'
                          : 'لديك حساب بالفعل؟ سجل دخولك',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 2. لوحة التحكم الرئيسية المحمية بالتوكن (Dashboard Screen)
class DashboardScreen extends StatefulWidget {
  final String username;
  final String token;
  const DashboardScreen({
    super.key,
    required this.username,
    required this.token,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _actionController = TextEditingController();
  final TextEditingController _appController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _records = [];
  List<dynamic> _filteredRecords = [];
  String _selectedAppFilter = 'الكل';
  bool _isLoading = false;

  final String baseUrl = ApiConfig.baseUrl;

  Map<String, String> get _authHeaders => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      };

  @override
  void initState() {
    super.initState();
    _fetchRecords();
    _searchController.addListener(_applyFilters);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleUnauthorized() {
    _showSnackBar('انتهت صلاحية الجلسة، يرجى تسجيل الدخول مجدداً', Colors.red);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AuthScreen()),
    );
  }

  Future<void> _fetchRecords() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/records'),
        headers: _authHeaders,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _records = data['records'];
          final availableApps =
              _records.map((r) => r['app'].toString()).toSet();
          if (_selectedAppFilter != 'الكل' &&
              !availableApps.contains(_selectedAppFilter)) {
            _selectedAppFilter = 'الكل';
          }
        });
        _applyFilters();
        _showSnackBar('تم جلب السجلات المحمية بنجاح', Colors.green);
      } else if (response.statusCode == 401) {
        _handleUnauthorized();
      } else {
        _showSnackBar('فشل في جلب السجلات', Colors.red);
      }
    } catch (e) {
      _showSnackBar('خطأ في الاتصال بالسيرفر', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveRecord() async {
    final action = _actionController.text.trim();
    final app = _appController.text.trim();

    if (action.isEmpty || app.isEmpty) {
      _showSnackBar('يرجى إدخال اسم الإجراء والتطبيق', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/data'),
        headers: _authHeaders,
        body: jsonEncode({
          'action': action,
          'app': app,
        }),
      );

      if (response.statusCode == 200) {
        _showSnackBar('تم حفظ السجل بنجاح في السحابة المحلية', Colors.green);
        _actionController.clear();
        _appController.clear();
        _fetchRecords();
      } else if (response.statusCode == 401) {
        _handleUnauthorized();
      } else {
        _showSnackBar('فشل حفظ البيانات', Colors.red);
      }
    } catch (e) {
      _showSnackBar('خطأ في الاتصال', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _editRecordDialog(Map<String, dynamic> record) async {
    final editActionController = TextEditingController(text: record['action']);
    final editAppController = TextEditingController(text: record['app']);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('تعديل السجل #${record['id']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: editActionController,
                decoration: const InputDecoration(
                  labelText: 'اسم الإجراء (Action)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: editAppController,
                decoration: const InputDecoration(
                  labelText: 'اسم التطبيق أو المكون (App)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final newAction = editActionController.text.trim();
                final newApp = editAppController.text.trim();
                if (newAction.isEmpty || newApp.isEmpty) {
                  _showSnackBar('لا يمكن ترك الحقول فارغة', Colors.orange);
                  return;
                }
                Navigator.pop(context);
                try {
                  final response = await http.put(
                    Uri.parse('$baseUrl/api/v1/data/${record['id']}'),
                    headers: _authHeaders,
                    body: jsonEncode({'action': newAction, 'app': newApp}),
                  );
                  if (response.statusCode == 200) {
                    _showSnackBar('تم تعديل السجل بنجاح', Colors.green);
                    _fetchRecords();
                  } else if (response.statusCode == 401) {
                    _handleUnauthorized();
                  } else {
                    _showSnackBar('فشل تعديل السجل', Colors.red);
                  }
                } catch (e) {
                  _showSnackBar('خطأ في الاتصال بالسيرفر', Colors.red);
                }
              },
              child: const Text('حفظ التعديل'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteRecord(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/v1/data/$id'),
        headers: _authHeaders,
      );
      if (response.statusCode == 200) {
        _showSnackBar('تم حذف السجل بنجاح', Colors.redAccent);
        _fetchRecords();
      } else if (response.statusCode == 401) {
        _handleUnauthorized();
      }
    } catch (e) {
      _showSnackBar('خطأ أثناء الحذف', Colors.red);
    }
  }

  // نافذة تأكيد وحذف جميع سجلات المستخدم الحالي
  Future<void> _confirmClearAllRecords() async {
    if (_records.isEmpty) {
      _showSnackBar('لا توجد سجلات لحذفها', Colors.orange);
      return;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text('تأكيد تصفير السجلات'),
            ],
          ),
          content: Text(
            'هل أنت متأكد من حذف جميع سجلاتك (${_records.length} سجل) نهائياً؟\n'
            'يُنصح بتصدير نسخة احتياطية (JSON) قبل المتابعة.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(context);
                setState(() => _isLoading = true);
                try {
                  final response = await http.delete(
                    Uri.parse('$baseUrl/api/v1/data/clear'),
                    headers: _authHeaders,
                  );
                  if (response.statusCode == 200) {
                    final data = jsonDecode(response.body);
                    _showSnackBar(
                        data['message'] ?? 'تم تصفير السجلات', Colors.redAccent);
                    _fetchRecords();
                  } else if (response.statusCode == 401) {
                    _handleUnauthorized();
                  } else {
                    _showSnackBar('فشل مسح السجلات', Colors.red);
                  }
                } catch (e) {
                  _showSnackBar('خطأ في الاتصال بالسيرفر', Colors.red);
                } finally {
                  setState(() => _isLoading = false);
                }
              },
              child: const Text('نعم، احذف الكل'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportBackup() async {
    final success =
        await ApiService.exportBackup(widget.username, widget.token);
    if (success) {
      _showSnackBar('تم تصدير النسخة الاحتياطية (JSON) بنجاح!', Colors.teal);
    } else {
      _showSnackBar('فشل تصدير النسخة الاحتياطية', Colors.red);
    }
  }

  Future<void> _exportCsvReport() async {
    final success =
        await ApiService.exportCsvReport(widget.username, widget.token);
    if (success) {
      _showSnackBar('تم تحميل تقرير Excel (CSV) بنجاح!', Colors.blueGrey);
    } else {
      _showSnackBar('فشل تصدير تقرير Excel', Colors.red);
    }
  }

  Future<void> _importBackup() async {
    final result = await ApiService.importBackup(widget.token);
    if (result['success'] == true) {
      _showSnackBar(result['message'], Colors.green);
      _fetchRecords();
    } else {
      _showSnackBar(result['message'], Colors.red);
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredRecords = _records.where((r) {
        final action = r['action'].toString().toLowerCase();
        final app = r['app'].toString();
        final user = r['user'].toString().toLowerCase();

        final matchesApp =
            _selectedAppFilter == 'الكل' || app == _selectedAppFilter;
        final matchesQuery = query.isEmpty ||
            action.contains(query) ||
            app.toLowerCase().contains(query) ||
            user.contains(query);

        return matchesApp && matchesQuery;
      }).toList();
    });
  }

  Widget _buildQuickFilterChips() {
    final uniqueApps = <String>{'الكل'};
    for (var r in _records) {
      uniqueApps.add(r['app'].toString());
    }

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: uniqueApps.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final appName = uniqueApps.elementAt(index);
          final isSelected = _selectedAppFilter == appName;
          return ChoiceChip(
            label: Text(
              appName,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.indigo,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            selected: isSelected,
            selectedColor: Colors.indigo,
            backgroundColor: Colors.white,
            side: const BorderSide(color: Colors.indigo),
            onSelected: (selected) {
              if (selected) {
                _selectedAppFilter = appName;
                _applyFilters();
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildAnalyticsRow() {
    final totalRecords = _records.length;

    String topApp = 'لا يوجد';
    if (_records.isNotEmpty) {
      final Map<String, int> appCounts = {};
      for (var r in _records) {
        final appName = r['app'].toString();
        appCounts[appName] = (appCounts[appName] ?? 0) + 1;
      }
      topApp = appCounts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    }

    final lastActivity = _records.isNotEmpty
        ? _records.first['created_at'].toString().split(' ').last
        : '--:--';

    return Row(
      children: [
        _statCard('إجمالي السجلات', '$totalRecords', Icons.storage, Colors.indigo),
        const SizedBox(width: 8),
        _statCard('الأكثر نشاطاً', topApp, Icons.star, Colors.teal),
        const SizedBox(width: 8),
        _statCard('آخر نشاط', lastActivity, Icons.access_time, Colors.deepOrange),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.verified_user, size: 20),
            const SizedBox(width: 8),
            Text('Nexus Omni Dashboard — مرحباً: ${widget.username}'),
          ],
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'حذف جميع سجلاتي',
            onPressed: _isLoading ? null : _confirmClearAllRecords,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'تسجيل الخروج',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AuthScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildAnalyticsRow(),
            const SizedBox(height: 12),
            TextField(
              controller: _actionController,
              decoration: const InputDecoration(
                labelText: 'اسم الإجراء (Action)',
                prefixIcon: Icon(Icons.flash_on),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _appController,
              decoration: const InputDecoration(
                labelText: 'اسم التطبيق أو المكون (App)',
                prefixIcon: Icon(Icons.apps),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: _isLoading ? null : _saveRecord,
              icon: const Icon(Icons.cloud_upload),
              label: const Text(
                'حفظ البيانات مع الختم الزمني في السحابة',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 12),
            // صف أزرار التحكم: جلب السجلات + Excel CSV + JSON + استيراد
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 45),
                    ),
                    onPressed: _isLoading ? null : _fetchRecords,
                    icon: const Icon(Icons.refresh),
                    label: const Text('جلب السجلات'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 45),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  onPressed: _isLoading ? null : _exportCsvReport,
                  icon: const Icon(Icons.table_chart),
                  label: const Text('تقرير Excel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 45),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  onPressed: _isLoading ? null : _exportBackup,
                  icon: const Icon(Icons.download),
                  label: const Text('تصدير JSON'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 45),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  onPressed: _isLoading ? null : _importBackup,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('استيراد JSON'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'بحث فوري في السجلات...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            _buildQuickFilterChips(),
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                ':سجل النشاط الزمني (Activity Log)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredRecords.isEmpty
                      ? const Center(
                          child: Text(
                              'لا توجد سجلات مطابقة، اضغط زر جلب السجلات'),
                        )
                      : ListView.builder(
                          itemCount: _filteredRecords.length,
                          itemBuilder: (context, index) {
                            final record = _filteredRecords[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              elevation: 3,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.indigo,
                                  foregroundColor: Colors.white,
                                  child: Text('${record['id']}'),
                                ),
                                title: Text('الإجراء: ${record['action']}'),
                                subtitle: Text(
                                  'التطبيق: ${record['app']} | المستخدم: ${record['user']}\n'
                                  'الإنشاء: ${record['created_at']}',
                                ),
                                isThreeLine: true,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.indigo),
                                      tooltip: 'تعديل السجل',
                                      onPressed: () =>
                                          _editRecordDialog(record),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      tooltip: 'حذف السجل',
                                      onPressed: () =>
                                          _deleteRecord(record['id']),
                                    ),
                                  ],
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