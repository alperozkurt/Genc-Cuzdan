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
    _nameController = TextEditingController(
      text: widget.initialProfileData?['name'] ?? '',
    );
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 700;
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 28 : 20,
            vertical: isDesktop ? 28 : 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Profile Header Card ───────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [DesignSystem.primaryIndigo, DesignSystem.darkIndigo],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: DesignSystem.primaryIndigo.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                      ),
                      child: Center(
                        child: Text(
                          _nameController.text.isNotEmpty
                              ? _nameController.text[0].toUpperCase()
                              : 'D',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nameController.text.isEmpty ? 'Demo Kullanıcı' : _nameController.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedJobType == 'öğrenci' ? '🎓 Öğrenci'
                                : _selectedJobType == 'çalışan' ? '💼 Çalışan'
                                : 'Profil henüz tamamlanmadı',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '✦ Demo',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${widget.completedGoalsCount} hedef tamamlandı',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (isDesktop)
                // Desktop: 2 columns
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left: forms
                    Expanded(
                      flex: 55,
                      child: Column(
                        children: [
                          _buildPersonalInfoCard(),
                          const SizedBox(height: 16),
                          _buildJobStatusCard(),
                          const SizedBox(height: 16),
                          _buildSaveButton(),
                          const SizedBox(height: 16),
                          _buildDemoBanner(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Right: badges
                    Expanded(
                      flex: 45,
                      child: _buildBadgesSection(widget.completedGoalsCount),
                    ),
                  ],
                )
              else
                // Mobile: single column
                Column(
                  children: [
                    _buildPersonalInfoCard(),
                    const SizedBox(height: 16),
                    _buildJobStatusCard(),
                    const SizedBox(height: 24),
                    _buildSaveButton(),
                    const SizedBox(height: 24),
                    _buildBadgesSection(widget.completedGoalsCount),
                    const SizedBox(height: 24),
                    _buildDemoBanner(),
                  ],
                ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPersonalInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: DesignSystem.premiumCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.badge_outlined, size: 18, color: DesignSystem.primaryIndigo),
              const SizedBox(width: 8),
              Text('Kişisel Bilgiler', style: DesignSystem.subheading(size: 15)),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            onChanged: (_) => setState(() {}),
            style: DesignSystem.body(color: DesignSystem.black, weight: FontWeight.w600),
            decoration: InputDecoration(
              labelText: 'Tam Ad',
              labelStyle: DesignSystem.body(color: DesignSystem.primaryIndigo),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: DesignSystem.primaryIndigo, width: 2),
              ),
              prefixIcon: const Icon(Icons.person_outline, color: DesignSystem.primaryIndigo),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: DesignSystem.premiumCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.work_outline_rounded, size: 18, color: DesignSystem.primaryIndigo),
              const SizedBox(width: 8),
              Text('Meslek Durumu', style: DesignSystem.subheading(size: 15)),
            ],
          ),
          const SizedBox(height: 20),
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
                selectedBackgroundColor: DesignSystem.primaryIndigo.withValues(alpha: 0.1),
                selectedForegroundColor: DesignSystem.primaryIndigo,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          if (_selectedJobType != null) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _salaryController,
              keyboardType: TextInputType.number,
              style: DesignSystem.body(color: DesignSystem.black, weight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: _selectedJobType == 'öğrenci' ? 'Aylık Harçlık (₺)' : 'Aylık Maaş (₺)',
                labelStyle: DesignSystem.body(color: DesignSystem.primaryIndigo),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: DesignSystem.primaryIndigo, width: 2),
                ),
                prefixIcon: const Icon(Icons.account_balance_wallet_outlined, color: DesignSystem.primaryIndigo),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
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
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: Text('Değişiklikleri Kaydet', style: DesignSystem.subheading(color: Colors.white, size: 15)),
      ),
    );
  }

  Widget _buildDemoBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: DesignSystem.primaryIndigo.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DesignSystem.primaryIndigo.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline_rounded, color: DesignSystem.primaryIndigo, size: 18),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              'GençCüzdan Demo Sürümü — Tüm veriler simüle edilmektedir.',
              style: DesignSystem.body(color: DesignSystem.primaryIndigo, weight: FontWeight.w600, size: 12),
            ),
          ),
        ],
      ),
    );
  }




  Widget _buildBadgesSection(int completedGoalsCount) {
    final List<Map<String, dynamic>> badges = [
      {'title': 'İlk Adım', 'threshold': 1, 'icon': Icons.star_outline_rounded},
      {
        'title': 'İkili Zafer',
        'threshold': 2,
        'icon': Icons.two_wheeler_rounded,
      },
      {
        'title': 'Hedef Avcısı',
        'threshold': 3,
        'icon': Icons.track_changes_rounded,
      },
      {
        'title': 'Tasarruf Ustası',
        'threshold': 5,
        'icon': Icons.savings_rounded,
      },
      {
        'title': 'Kararlı Birikimci',
        'threshold': 10,
        'icon': Icons.trending_up_rounded,
      },
      {
        'title': 'Finans Gurusu',
        'threshold': 15,
        'icon': Icons.psychology_rounded,
      },
      {
        'title': 'Hedef Canavarı',
        'threshold': 20,
        'icon': Icons.rocket_launch_rounded,
      },
      {
        'title': 'Yıldız Tasarrufçu',
        'threshold': 25,
        'icon': Icons.stars_rounded,
      },
      {
        'title': 'Efsanevi Bütçeci',
        'threshold': 30,
        'icon': Icons.workspace_premium_rounded,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: DesignSystem.premiumCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.military_tech_rounded,
                size: 28,
                color: Colors.amber,
              ),
              const SizedBox(width: 8),
              Text(
                'Başarı Rozetleri',
                style: DesignSystem.subheading(size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Tamamlanan hedeflerine göre açılan rozetler.',
            style: DesignSystem.body(size: 14, color: DesignSystem.gray),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final int columns = constraints.maxWidth > 700
                  ? 5
                  : (constraints.maxWidth > 420 ? 4 : 3);
              final double ratio = constraints.maxWidth > 420 ? 0.82 : 0.72;
              return GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16,
                  childAspectRatio: ratio,
                ),
                itemCount: badges.length,
                itemBuilder: (context, index) {
                  final badge = badges[index];
                  final bool isUnlocked =
                      completedGoalsCount >= badge['threshold'];

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isUnlocked
                              ? Colors.amber.withValues(alpha: 0.15)
                              : DesignSystem.lightGray,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isUnlocked
                                ? Colors.amber
                                : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: isUnlocked
                              ? [
                                  BoxShadow(
                                    color: Colors.amber.withValues(alpha: 0.25),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          isUnlocked ? badge['icon'] : Icons.lock_rounded,
                          size: 28,
                          color: isUnlocked ? Colors.amber : DesignSystem.gray,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Flexible(
                        child: Text(
                          badge['title'],
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: DesignSystem.body(
                            size: 12,
                            weight:
                                isUnlocked ? FontWeight.w700 : FontWeight.w500,
                            color: isUnlocked
                                ? DesignSystem.black
                                : DesignSystem.gray,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${badge['threshold']} Hedef',
                        style: DesignSystem.body(
                          size: 10,
                          color: DesignSystem.gray,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
