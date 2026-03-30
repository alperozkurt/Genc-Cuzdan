import 'package:flutter/material.dart';
import '../theme/design_system.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: DesignSystem.primaryIndigo.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_3_rounded, size: 32, color: DesignSystem.primaryIndigo),
              ),
              const SizedBox(width: 16),
              Text('Profil', style: DesignSystem.heading()),
            ],
          ),
          const SizedBox(height: 32),
          
          // Personal Info Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: DesignSystem.premiumCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.badge_outlined, size: 20, color: DesignSystem.primaryIndigo),
                    const SizedBox(width: 8),
                    Text('Kişisel Bilgiler', style: DesignSystem.subheading(size: 16)),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _nameController,
                  style: DesignSystem.body(color: DesignSystem.black, weight: FontWeight.w600),
                  decoration: InputDecoration(
                    labelText: 'Tam Ad',
                    labelStyle: DesignSystem.body(color: DesignSystem.primaryIndigo),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    prefixIcon: const Icon(Icons.person_outline, color: DesignSystem.primaryIndigo),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),

          // Job Status Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: DesignSystem.premiumCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.work_outline_rounded, size: 20, color: DesignSystem.primaryIndigo),
                    const SizedBox(width: 8),
                    Text('Meslek Durumu', style: DesignSystem.subheading(size: 16)),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'öğrenci', label: Text('Öğrenci'), icon: Icon(Icons.school_outlined, size: 18)),
                      ButtonSegment(value: 'çalışan', label: Text('Çalışan'), icon: Icon(Icons.business_center_outlined, size: 18)),
                    ],
                    selected: _selectedJobType != null ? {_selectedJobType!} : <String>{},
                    emptySelectionAllowed: true,
                    onSelectionChanged: (Set<String> s) => setState(() => _selectedJobType = s.isEmpty ? null : s.first),
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: DesignSystem.primaryIndigo.withOpacity(0.1),
                      selectedForegroundColor: DesignSystem.primaryIndigo,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                if (_selectedJobType != null) ...[
                  const SizedBox(height: 20),
                  TextField(
                    controller: _salaryController,
                    keyboardType: TextInputType.number,
                    style: DesignSystem.body(color: DesignSystem.black, weight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: _selectedJobType == 'öğrenci' ? 'Aylık Harçlık (₺)' : 'Aylık Maaş (₺)',
                      labelStyle: DesignSystem.body(color: DesignSystem.primaryIndigo),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      prefixIcon: const Icon(Icons.account_balance_wallet_outlined, color: DesignSystem.primaryIndigo),
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
                    content: const Text('Profil güncellendi'),
                    backgroundColor: DesignSystem.secondaryGreen,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignSystem.primaryIndigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: Colors.black.withOpacity(0.15),
              ),
              child: Text('Değişiklikleri Kaydet', style: DesignSystem.subheading(color: Colors.white, size: 16)),
            ),
          ),
          
          const SizedBox(height: 48),
          const Divider(),
          const SizedBox(height: 24),
          
          Center(
            child: TextButton.icon(
              onPressed: () {
                DesignSystem.showPremiumDialog(
                  context: context,
                  title: 'Çıkış Yap',
                  content: const Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onLogout();
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: DesignSystem.accentCoral, foregroundColor: Colors.white),
                      child: const Text('Çıkış Yap'),
                    ),
                  ],
                );
              },
              icon: const Icon(Icons.logout_rounded, color: DesignSystem.accentCoral),
              label: Text('Hesaptan Çıkış Yap', style: DesignSystem.subheading(color: DesignSystem.accentCoral, size: 14)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
