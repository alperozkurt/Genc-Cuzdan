import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic>? initialProfileData;
  final Function(Map<String, dynamic>) onProfileSaved;
  final VoidCallback onLogout;

  const ProfilePage({
    this.initialProfileData,
    required this.onProfileSaved,
    required this.onLogout,
    super.key,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _salaryController;
  String? _selectedJobType;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialProfileData?['name'] ?? '');
    _salaryController = TextEditingController(
      text: widget.initialProfileData?['monthly_salary']?.toString() ?? '',
    );
    _selectedJobType = widget.initialProfileData?['job_type'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_3_rounded, size: 28, color: Colors.purple),
              ),
              const SizedBox(width: 12),
              const Text(
                'Profil',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Personal Info Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.badge_outlined, size: 20, color: Colors.purple),
                    const SizedBox(width: 8),
                    Text(
                      'Kişisel Bilgiler',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Adınızı girin',
                    labelText: 'Tam Ad',
                    labelStyle: const TextStyle(color: Colors.purple),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.purple, width: 2),
                    ),
                    prefixIcon: const Icon(Icons.person_outline, color: Colors.purple),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),

          // Job Status Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.work_outline_rounded, size: 20, color: Colors.purple),
                    const SizedBox(width: 8),
                    Text(
                      'Meslek Durumu',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'öğrenci',
                        label: Text('Öğrenci'),
                        icon: Icon(Icons.school_outlined, size: 18),
                      ),
                      ButtonSegment(
                        value: 'çalışan',
                        label: Text('Çalışan'),
                        icon: Icon(Icons.business_center_outlined, size: 18),
                      ),
                    ],
                    selected: _selectedJobType != null ? {_selectedJobType!} : <String>{},
                    emptySelectionAllowed: true,
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _selectedJobType = newSelection.isEmpty ? null : newSelection.first;
                      });
                    },
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: Colors.purple.withValues(alpha: 0.1),
                      selectedForegroundColor: Colors.purple,
                      side: BorderSide(color: Colors.grey.shade200),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                if (_selectedJobType != null) ...[
                  const SizedBox(height: 20),
                  TextField(
                    controller: _salaryController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: _selectedJobType == 'öğrenci' ? 'Aylık Harçlık/Gelir (₺)' : 'Aylık Maaş (₺)',
                      labelText: 'Aylık Gelir',
                      labelStyle: const TextStyle(color: Colors.purple),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.purple, width: 2),
                      ),
                      prefixIcon: const Icon(Icons.account_balance_wallet_outlined, color: Colors.purple),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final double? salary = double.tryParse(_salaryController.text);
                widget.onProfileSaved({
                  'name': _nameController.text,
                  if (_selectedJobType != null) 'job_type': _selectedJobType,
                  if (salary != null) 'monthly_salary': salary,
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Profil bilgileriniz başarıyla güncellendi'),
                    backgroundColor: Colors.green.shade600,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: Colors.purple.withValues(alpha: 0.3),
              ),
              child: const Text('Değişiklikleri Kaydet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          
          const SizedBox(height: 48),
          const Divider(),
          const SizedBox(height: 24),
          
          Center(
            child: TextButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) => AlertDialog(
                    title: const Text('Çıkış Yap'),
                    content: const Text(
                      'Hesabınızdan çıkış yapmak istediğinize emin misiniz?',
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Vazgeç'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onLogout();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Çıkış Yap'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.logout_rounded, color: Colors.red),
              label: const Text('Hesaptan Çıkış Yap', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
