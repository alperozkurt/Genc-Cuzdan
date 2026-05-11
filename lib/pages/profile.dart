import 'package:flutter/material.dart';
import '../theme/design_system.dart';

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic>? initialProfileData;
  final Function(Map<String, dynamic>) onProfileSaved;
  final VoidCallback onLogout;
  final int completedGoalsCount;

  const ProfilePage({
    this.initialProfileData,
    required this.onProfileSaved,
    required this.onLogout,
    this.completedGoalsCount = 0,
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

          // Gamification Badges Section
          _buildBadgesSection(widget.completedGoalsCount),

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

  Widget _buildBadgesSection(int completedGoalsCount) {
    final List<Map<String, dynamic>> badges = [
      {'title': 'İlk Adım', 'threshold': 1, 'icon': Icons.star_outline_rounded},
      {'title': 'İkili Zafer', 'threshold': 2, 'icon': Icons.two_wheeler_rounded},
      {'title': 'Hedef Avcısı', 'threshold': 3, 'icon': Icons.track_changes_rounded},
      {'title': 'Tasarruf Ustası', 'threshold': 5, 'icon': Icons.savings_rounded},
      {'title': 'Kararlı Birikimci', 'threshold': 10, 'icon': Icons.trending_up_rounded},
      {'title': 'Finans Gurusu', 'threshold': 15, 'icon': Icons.psychology_rounded},
      {'title': 'Hedef Canavarı', 'threshold': 20, 'icon': Icons.rocket_launch_rounded},
      {'title': 'Yıldız Tasarrufçu', 'threshold': 25, 'icon': Icons.stars_rounded},
      {'title': 'Efsanevi Bütçeci', 'threshold': 30, 'icon': Icons.workspace_premium_rounded},  
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: DesignSystem.premiumCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.military_tech_rounded, size: 24, color: Colors.amber),
              const SizedBox(width: 8),
              Text('Başarı Rozetleri', style: DesignSystem.subheading(size: 16)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Tamamlanan hedeflerine göre açılan rozetler.',
            style: DesignSystem.body(size: 13, color: DesignSystem.gray),
          ),
          const SizedBox(height: 24),
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            itemCount: badges.length,
            itemBuilder: (context, index) {
              final badge = badges[index];
              final bool isUnlocked = completedGoalsCount >= badge['threshold'];

              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isUnlocked ? Colors.amber.withOpacity(0.15) : DesignSystem.lightGray,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isUnlocked ? Colors.amber : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: isUnlocked
                          ? [BoxShadow(color: Colors.amber.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))]
                          : null,
                    ),
                    child: Icon(
                      isUnlocked ? badge['icon'] : Icons.lock_rounded,
                      size: 28,
                      color: isUnlocked ? Colors.amber : DesignSystem.gray,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    badge['title'],
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: DesignSystem.body(
                      size: 11,
                      weight: isUnlocked ? FontWeight.w700 : FontWeight.w500,
                      color: isUnlocked ? DesignSystem.black : DesignSystem.gray,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${badge['threshold']} Hedef',
                    style: DesignSystem.body(size: 10, color: DesignSystem.gray),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
