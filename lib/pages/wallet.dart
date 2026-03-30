import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/market_service.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/design_system.dart';

// WalletPage now uses DesignSystem and unified theme.

// --- MAIN WIDGET ---

class WalletPage extends StatefulWidget {
  final String userName;
  final double monthlyIncome;
  final double monthlyExpense;
  final double monthlySavings;
  final String? investmentProfile;
  final List<Map<String, dynamic>> goals;
  final List<Map<String, dynamic>> activities;
  final List<Map<String, dynamic>> savings;
  final Function(String) onStartInvestmentTest;
  final Function() onRetakeInvestmentTest;

  const WalletPage({
    required this.userName,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.monthlySavings,
    required this.investmentProfile,
    required this.goals,
    required this.activities,
    required this.savings,
    required this.onStartInvestmentTest,
    required this.onRetakeInvestmentTest,
    super.key,
  });

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  List<dynamic> _savings = [];
  Map<String, double> _marketData = {};
  bool _isLoading = true;
  Map<String, dynamic>? _summary;
  double _totalBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final summaryData = await ApiService.getFinancialSummary();
      final savingsData = await ApiService.getSavings();
      final marketData = await MarketService.getMarketData();
      
      setState(() {
        _summary = summaryData;
        _savings = savingsData;
        _marketData = marketData;
        _totalBalance = _calculateTotalBalance();
        _isLoading = false;
      });
    } catch (e) {
      // Handle error
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  double _convertResultToTry(double amount, String currency) {
    if (currency == 'TRY') return amount;
    if (_marketData.isEmpty) return amount; // Or fallback

    switch (currency) {
      case 'USD':
        return amount * (_marketData['USD/TL'] ?? 1.0);
      case 'EUR':
        return amount * (_marketData['EUR/TL'] ?? 1.0);
      case 'GOLD':
        return amount * (_marketData['Gram Altın'] ?? 1.0);
      default:
        return amount;
    }
  }

  double _calculateTotalBalance() {
    double total = 0;
    for (var item in _savings) {
      double amount = (item['amount'] as num).toDouble();
      String currency = item['currency'] ?? 'TRY';
      total += _convertResultToTry(amount, currency);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.background,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSavingDialog,
        backgroundColor: DesignSystem.primaryIndigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HEADER SECTION: Avatar + Greeting + Balance (Component Pattern)
                    _buildOverviewSection(),

                    const SizedBox(height: 32),

                    Text('Varlıklarım', style: DesignSystem.subheading()),
                    const SizedBox(height: 16),
                    _buildSavingsList(),

                    const SizedBox(height: 32),

                    Text('Hedefler Özeti', style: DesignSystem.subheading()),
                    const SizedBox(height: 16),
                    _buildGoalsSummaryCard(),

                    const SizedBox(height: 32),

                    // INVESTMENT SECTION
                    Text('Yatırım Stratejisi', style: DesignSystem.subheading()),
                    const SizedBox(height: 16),

                    if (widget.investmentProfile == null)
                      _buildEmptyStateCard()
                    else
                      _buildInvestorProfileSection(),

                    const SizedBox(height: 80), // Bottom spacing
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildOverviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Premium Asset Section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [DesignSystem.primaryIndigo, DesignSystem.darkIndigo],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOPLAM VARLIKLAR',
                style: GoogleFonts.manrope(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${NumberFormat.currency(locale: 'tr_TR', symbol: '₺').format(_totalBalance)}',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Tighter Financial Summary Section
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'Gelir',
                amount: _summary?['monthly_income'] ?? 0,
                icon: Icons.south_west_rounded,
                color: const Color(0xFF2ECC71),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                title: 'Gider',
                amount: _summary?['monthly_expense'] ?? 0,
                icon: Icons.north_east_rounded,
                color: const Color(0xFFFF6B6B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSummaryCard(
          title: 'Aylık Birikim',
          amount: _summary?['monthly_savings'] ?? 0,
          icon: Icons.savings_outlined,
          color: DesignSystem.primaryIndigo,
          isFullWidth: true,
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    bool isFullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '₺${NumberFormat('#,##0', 'tr_TR').format(amount)}',
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2D3436),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsSummaryCard() {
    int activeGoals = widget.goals.where((g) => g['is_completed'] != true && g['is_completed'] != 1).length;
    int completedGoals = widget.goals.where((g) => g['is_completed'] == true || g['is_completed'] == 1).length;
    
    double totalGoalSavings = 0.0;
    for (var activity in widget.activities) {
      if (activity['goal_id'] != null) {
        if (activity['type'] == 'gelir') {
          totalGoalSavings += (activity['amount'] as num).toDouble();
        } else if (activity['type'] == 'gider') {
          totalGoalSavings -= (activity['amount'] as num).toDouble();
        }
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignSystem.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: DesignSystem.premiumCard().boxShadow!,
        border: Border.all(color: DesignSystem.accentCoral.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildIconContainer(Icons.track_changes, DesignSystem.accentCoral),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Toplanan Hedef Tasarrufu', style: TextStyle(color: DesignSystem.gray, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('₺${totalGoalSavings.toStringAsFixed(0)}', style: DesignSystem.heading(size: 24)),
                ],
              ),
            ]
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          Row(
             mainAxisAlignment: MainAxisAlignment.spaceAround,
             children: [
               Column(
                 children: [
                   Text(activeGoals.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: DesignSystem.primaryIndigo)),
                   const Text('Aktif Hedefler', style: TextStyle(color: DesignSystem.gray, fontSize: 13)),
                 ],
               ),
               Column(
                 children: [
                   Text(completedGoals.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: DesignSystem.secondaryGreen)),
                   const Text('Tamamlananlar', style: TextStyle(color: DesignSystem.gray, fontSize: 13)),
                 ],
               ),
             ]
          )
        ],
      ),
    );
  }

  Widget _buildTransactionCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    bool isHorizontal = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: DesignSystem.premiumCard().boxShadow!,
      ),
      child: isHorizontal
          ? Row(
              children: [
                _buildIconContainer(icon, iconColor),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: DesignSystem.body().copyWith(fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      '₺${amount.toStringAsFixed(2)}',
                      style: DesignSystem.heading(size: 24).copyWith(fontSize: 20),
                    ),
                  ],
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIconContainer(icon, iconColor),
                const SizedBox(height: 12),
                Text(title, style: DesignSystem.body().copyWith(fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  '₺${amount.toStringAsFixed(0)}',
                  style: DesignSystem.heading(size: 24).copyWith(fontSize: 18),
                ),
              ],
            ),
    );
  }

  Widget _buildIconContainer(IconData icon, Color color) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildEmptyStateCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DesignSystem.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: DesignSystem.premiumCard().boxShadow!,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DesignSystem.primaryIndigo.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.quiz_outlined,
              color: DesignSystem.primaryIndigo,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Yatırım Profilinizi Belirleyin',
            style: DesignSystem.subheading(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Risk toleransınızı ölçmek ve size özel portföy önerileri almak için testi tamamlayın.',
            textAlign: TextAlign.center,
            style: DesignSystem.body(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onStartInvestmentTest(''),
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignSystem.primaryIndigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Testi Başlat',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestorProfileSection() {
    final profile = widget.investmentProfile!;

    // Map profile to design system colors
    Color profileColor;
    String profileName;
    String description;

    if (profile == 'korumacı') {
      profileColor = DesignSystem.primaryIndigo; // Conservative matches Primary
      profileName = 'Korumacı';
      description = 'Düşük risk, sabit getiri odaklı strateji.';
    } else if (profile == 'dengeli') {
      profileColor = DesignSystem.warningOrange; // Balanced
      profileName = 'Dengeli';
      description = 'Orta risk ve büyüme dengesi.';
    } else {
      profileColor = DesignSystem.accentCoral; // Aggressive
      profileName = 'Agresif';
      description = 'Yüksek büyüme potansiyeli için yüksek risk.';
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: DesignSystem.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: DesignSystem.premiumCard().boxShadow!,
            border: Border.all(
              color: profileColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header of Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: profileColor.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.pie_chart, color: profileColor),
                    const SizedBox(width: 8),
                    Text(
                      profileName,
                      style: TextStyle(
                        color: profileColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(description, style: DesignSystem.body()),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 10),
                    const Text(
                      'Önerilen Dağılım',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: DesignSystem.gray,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildPortfolioList(profile, profileColor),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: widget.onRetakeInvestmentTest,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Testi Tekrarla'),
          style: TextButton.styleFrom(foregroundColor: DesignSystem.gray),
        ),
      ],
    );
  }

  Widget _buildPortfolioList(String profile, Color color) {
    List<Map<String, dynamic>> allocation = [];

    // Logic kept from original
    if (profile == 'korumacı') {
      allocation = [
        {'name': 'Tahvil & Bono', 'pct': 60, 'icon': Icons.account_balance},
        {'name': 'Altın', 'pct': 25, 'icon': Icons.monetization_on},
        {'name': 'Mevduat', 'pct': 15, 'icon': Icons.savings},
      ];
    } else if (profile == 'dengeli') {
      allocation = [
        {'name': 'Hisse Senedi', 'pct': 50, 'icon': Icons.show_chart},
        {'name': 'Tahvil', 'pct': 35, 'icon': Icons.account_balance},
        {'name': 'Emtia', 'pct': 15, 'icon': Icons.diamond},
      ];
    } else {
      allocation = [
        {'name': 'Hisse Senedi', 'pct': 70, 'icon': Icons.show_chart},
        {'name': 'Teknoloji/Kripto', 'pct': 20, 'icon': Icons.currency_bitcoin},
        {'name': 'Tahvil', 'pct': 10, 'icon': Icons.account_balance},
      ];
    }

    return Column(
      children: allocation.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            children: [
              Icon(item['icon'], size: 16, color: DesignSystem.gray),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item['name'],
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${item['pct']}%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: item['pct'] / 100,
                        backgroundColor: DesignSystem.background,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSavingsList() {
    final savings = widget.savings;
    if (savings.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: DesignSystem.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: DesignSystem.premiumCard().boxShadow!,
        ),
        child: Center(
          child: Text('Henüz varlık eklenmemiş.', style: DesignSystem.body()),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: savings.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final saving = savings[index];
        final double amount = (saving['amount'] as num).toDouble();
        final String currency = saving['currency'];
        final double amountInTry = _convertResultToTry(amount, currency);

        IconData icon;
        Color iconColor;
        String symbol;

        switch (currency) {
          case 'USD':
            icon = Icons.attach_money;
            iconColor = Colors.green;
            symbol = '\$';
            break;
          case 'EUR':
            icon = Icons.euro;
            iconColor = Colors.blue;
            symbol = '€';
            break;
          case 'GOLD':
            icon = Icons.diamond;
            iconColor = Colors.orange;
            symbol = 'gr';
            break;
          default:
            icon = Icons.currency_lira;
            iconColor = DesignSystem.primaryIndigo;
            symbol = '₺';
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: DesignSystem.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: DesignSystem.premiumCard().boxShadow!,
          ),
          child: Row(
            children: [
              _buildIconContainer(icon, iconColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      saving['description'] ?? 'Tasarruf',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      saving['date'],
                      style: const TextStyle(color: DesignSystem.gray, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$symbol${amount.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  if (currency != 'TRY')
                    Text(
                      '₺${amountInTry.toStringAsFixed(2)}',
                      style: const TextStyle(color: DesignSystem.gray, fontSize: 12),
                    ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: DesignSystem.accentCoral, size: 20),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: DesignSystem.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      title: Text('Varlığı Sil', style: DesignSystem.subheading()),
                      content: const Text('Bu varlığı silmek istediğinize emin misiniz?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Sil', style: TextStyle(color: DesignSystem.accentCoral, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    try {
                      await ApiService.deleteSaving(saving['id']);
                      _loadData();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddSavingDialog() {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCurrency = 'TRY';
    DateTime selectedDate = DateTime.now();

    DesignSystem.showPremiumDialog(
      context: context,
      title: 'Varlık Ekle',
      content: StatefulBuilder(
        builder: (context, setDialogState) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Miktar',
                  prefixIcon: const Icon(Icons.monetization_on_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCurrency,
                items: const [
                  DropdownMenuItem(value: 'TRY', child: Text('Türk Lirası (₺)')),
                  DropdownMenuItem(value: 'USD', child: Text('Amerikan Doları (\$)')),
                  DropdownMenuItem(value: 'EUR', child: Text('Euro (€)')),
                  DropdownMenuItem(value: 'GOLD', child: Text('Gram Altın (gr)')),
                ],
                onChanged: (val) => setDialogState(() => selectedCurrency = val!),
                decoration: InputDecoration(
                  labelText: 'Para Birimi',
                  prefixIcon: const Icon(Icons.currency_exchange_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Açıklama',
                  prefixIcon: const Icon(Icons.description_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setDialogState(() => selectedDate = picked);
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Tarih',
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
        ElevatedButton(
          onPressed: () async {
            final amount = double.tryParse(amountController.text);
            if (amount != null && amount > 0) {
              try {
                await ApiService.addSaving(
                  amount: amount,
                  currency: selectedCurrency,
                  description: descriptionController.text.isEmpty ? 'Birikim' : descriptionController.text,
                  date: DateFormat('yyyy-MM-dd').format(selectedDate),
                );
                Navigator.pop(context);
                _loadData();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: DesignSystem.primaryIndigo,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Ekle'),
        ),
      ],
    );
  }
}

// --- DIALOG COMPONENT ---

class InvestmentTestDialog extends StatefulWidget {
  final Function(String) onTestComplete;

  const InvestmentTestDialog({required this.onTestComplete, super.key});

  @override
  State<InvestmentTestDialog> createState() => _InvestmentTestDialogState();
}

class _InvestmentTestDialogState extends State<InvestmentTestDialog> {
  int currentQuestion = 0;
  int score = 0;

  // Logic: Reused original questions
  final List<InvestmentQuestion> questions = [
    InvestmentQuestion(
      question: 'Uzun vadeli hedefleriniz için ne kadar zaman ayırabilirsiniz?',
      answers: [
        {'text': 'Az (1-3 yıl)', 'score': 0},
        {'text': 'Orta (3-10 yıl)', 'score': 1},
        {'text': 'Uzun (10+ yıl)', 'score': 2},
      ],
    ),
    InvestmentQuestion(
      question: 'Finansal acil durumlar için ne kadar reserve fonunuz var?',
      answers: [
        {'text': 'Hiç', 'score': 0},
        {'text': '1-3 ay', 'score': 1},
        {'text': '6+ ay', 'score': 2},
      ],
    ),
    InvestmentQuestion(
      question: 'Yatırım deneyiminiz?',
      answers: [
        {'text': 'Başlangıç', 'score': 0},
        {'text': 'Orta', 'score': 1},
        {'text': 'İleri', 'score': 2},
      ],
    ),
    InvestmentQuestion(
      question: 'Risk toleransınız?',
      answers: [
        {'text': 'Düşük risk, güvenli liman', 'score': 0},
        {'text': 'Dengeli dalgalanma', 'score': 1},
        {'text': 'Yüksek risk, yüksek getiri', 'score': 2},
      ],
    ),
    InvestmentQuestion(
      question: 'Yatırım bütçesi (Aylık gelire oranla)?',
      answers: [
        {'text': '%5\'ten az', 'score': 0},
        {'text': '%5 - %15', 'score': 1},
        {'text': '%15+', 'score': 2},
      ],
    ),
  ];

  void _answerQuestion(int answerScore) {
    score += answerScore;
    if (currentQuestion < questions.length - 1) {
      setState(() {
        currentQuestion++;
      });
    } else {
      _completeTest();
    }
  }

  void _completeTest() {
    String profile;
    int maxScore = questions.length * 2;
    double percentage = score / maxScore;

    if (percentage <= 0.33) {
      profile = 'korumacı';
    } else if (percentage <= 0.66) {
      profile = 'dengeli';
    } else {
      profile = 'agresif';
    }
    widget.onTestComplete(profile);
  }

  @override
  Widget build(BuildContext context) {
    final question = questions[currentQuestion];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: DesignSystem.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Yatırım Testi', style: DesignSystem.subheading()),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: DesignSystem.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${currentQuestion + 1}/${questions.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: DesignSystem.primaryIndigo,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: (currentQuestion + 1) / questions.length,
              backgroundColor: DesignSystem.background,
              valueColor: const AlwaysStoppedAnimation<Color>(DesignSystem.primaryIndigo),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 24),
            Text(
              question.question,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ...question.answers.map((answer) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => _answerQuestion(answer['score'] as int),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: DesignSystem.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.transparent),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          answer['text'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            color: DesignSystem.black,
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: DesignSystem.lightGray,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class InvestmentQuestion {
  final String question;
  final List<Map<String, dynamic>> answers;
  InvestmentQuestion({required this.question, required this.answers});
}
