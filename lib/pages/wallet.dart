import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
  Map<String, dynamic>? _savingsSummary;
  double _totalBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getFinancialSummary(),
        ApiService.getSavingsSummary(),
        MarketService.getMarketData(),
        ApiService.getSavings(),
      ]);
      setState(() {
        _summary = results[0] as Map<String, dynamic>;
        _savingsSummary = results[1] as Map<String, dynamic>;
        _marketData = (results[2] as Map<String, dynamic>).map(
            (k, v) => MapEntry(k, (v as num).toDouble()));
        _savings = results[3] as List<dynamic>;
        _totalBalance = _calculateTotalBalance();
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading wallet data: $e');
      setState(() => _isLoading = false);
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
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 700;
                  if (isDesktop) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOverviewSection(),
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left: savings
                            Expanded(
                              flex: 55,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildWalletSectionHeader('Varlıklarım', Icons.account_balance_wallet_rounded),
                                  const SizedBox(height: 12),
                                  _buildSavingsList(),
                                  const SizedBox(height: 12),
                                  _buildAddSavingButton(),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            // Right: goals + investment
                            Expanded(
                              flex: 45,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildWalletSectionHeader('Hedefler Özeti', Icons.track_changes_rounded),
                                  const SizedBox(height: 12),
                                  _buildGoalsSummaryCard(),
                                  const SizedBox(height: 20),
                                  _buildWalletSectionHeader('Yatırım Stratejisi', Icons.trending_up_rounded),
                                  const SizedBox(height: 12),
                                  if (widget.investmentProfile == null)
                                    _buildEmptyStateCard()
                                  else
                                    _buildInvestorProfileSection(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }
                  // Mobile: single column
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOverviewSection(),
                      const SizedBox(height: 24),
                      _buildWalletSectionHeader('Varlıklarım', Icons.account_balance_wallet_rounded),
                      const SizedBox(height: 12),
                      _buildSavingsList(),
                      const SizedBox(height: 12),
                      _buildAddSavingButton(),
                      const SizedBox(height: 24),
                      _buildWalletSectionHeader('Hedefler Özeti', Icons.track_changes_rounded),
                      const SizedBox(height: 12),
                      _buildGoalsSummaryCard(),
                      const SizedBox(height: 24),
                      _buildWalletSectionHeader('Yatırım Stratejisi', Icons.trending_up_rounded),
                      const SizedBox(height: 12),
                      if (widget.investmentProfile == null)
                        _buildEmptyStateCard()
                      else
                        _buildInvestorProfileSection(),
                    ],
                  );
                },
              ),
            ),
          );
  }

  Widget _buildWalletSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: DesignSystem.primaryIndigo),
        const SizedBox(width: 8),
        Text(title, style: DesignSystem.subheading(size: 15)),
      ],
    );
  }

  Widget _buildAddSavingButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _showAddSavingDialog,
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('Yeni Varlık Ekle'),
        style: OutlinedButton.styleFrom(
          foregroundColor: DesignSystem.primaryIndigo,
          side: BorderSide(color: DesignSystem.primaryIndigo.withValues(alpha: 0.4), width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildOverviewSection() {
    final breakdown = (_savingsSummary?['breakdown'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final grandTotal = (_savingsSummary?['grand_total_try'] as num?)?.toDouble() ?? _totalBalance;
    final income = (_summary?['monthly_income'] as num?)?.toDouble() ?? widget.monthlyIncome;
    final expense = (_summary?['monthly_expense'] as num?)?.toDouble() ?? widget.monthlyExpense;
    final savings = (_summary?['monthly_savings'] as num?)?.toDouble() ?? widget.monthlySavings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Main Page Matching Hero Card ────────────────────────────────
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
                color: DesignSystem.primaryIndigo.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOPLAM VARLIKLAR',
                        style: GoogleFonts.manrope(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        NumberFormat.currency(locale: 'tr_TR', symbol: '₺').format(grandTotal),
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ],
              ),
              if (breakdown.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildCurrencyBreakdownBar(breakdown, grandTotal),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  children: breakdown.map((item) {
                    final curr = (item['currency'] ?? 'TRY').toString();
                    final tryVal = ((item['total_try'] ?? 0) as num).toDouble();
                    final pct = grandTotal > 0 ? (tryVal / grandTotal * 100) : 0.0;
                    final meta = _getCurrencyMeta(curr);
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: curr == 'TRY' ? Colors.white : (meta['color'] as Color? ?? Colors.blue),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$curr ${pct.toStringAsFixed(0)}%',
                          style: GoogleFonts.manrope(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 20),
              // Income, Expense, Savings Pills (Matching Home Hero Card)
              Row(
                children: [
                  Expanded(
                    child: _buildWalletSummaryPill(
                      label: 'Gelir',
                      amount: income,
                      icon: Icons.arrow_downward_rounded,
                      color: const Color(0xFF34D399),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildWalletSummaryPill(
                      label: 'Gider',
                      amount: expense,
                      icon: Icons.arrow_upward_rounded,
                      color: const Color(0xFFFB7185),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildWalletSummaryPill(
                      label: 'Birikim',
                      amount: savings,
                      icon: Icons.savings_rounded,
                      color: const Color(0xFF818CF8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildNeedsVsWantsTracker(),
      ],
    );
  }

  Widget _buildWalletSummaryPill({
    required String label,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    final fmt = amount >= 1000
        ? '${(amount / 1000).toStringAsFixed(1)}k'
        : amount.toStringAsFixed(0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 13),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '₺$fmt',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeedsVsWantsTracker() {
    double needsTotal = 0.0;
    double wantsTotal = 0.0;

    for (var goal in widget.goals) {
      // Only include the target amount of the goals
      final amount = (goal['target_amount'] as num).toDouble();
      if (goal['is_need'] == true || goal['is_need'] == 1) {
        needsTotal += amount;
      } else {
        wantsTotal += amount;
      }
    }

    final totalValue = needsTotal + wantsTotal;
    if (totalValue == 0) return const SizedBox.shrink();

    final needsPct = needsTotal / totalValue;
    final wantsPct = wantsTotal / totalValue;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: DesignSystem.premiumCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Hedeflerin İhtiyaç ve İstek Analizi', style: DesignSystem.subheading(size: 14)),
              Icon(Icons.bar_chart, size: 18, color: DesignSystem.gray),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  if (needsPct > 0)
                    Expanded(
                      flex: (needsPct * 100).toInt(),
                      child: Container(color: DesignSystem.primaryIndigo),
                    ),
                  if (wantsPct > 0)
                    Expanded(
                      flex: (wantsPct * 100).toInt(),
                      child: Container(color: DesignSystem.accentCoral),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: DesignSystem.primaryIndigo, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('İhtiyaç (₺${needsTotal.toStringAsFixed(0)})', style: DesignSystem.body(size: 11, color: DesignSystem.gray)),
                ],
              ),
              Row(
                children: [
                  Text('İstek (₺${wantsTotal.toStringAsFixed(0)})', style: DesignSystem.body(size: 11, color: DesignSystem.gray)),
                  const SizedBox(width: 6),
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: DesignSystem.accentCoral, shape: BoxShape.circle)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyBreakdownBar(
      List<Map<String, dynamic>> breakdown, double grandTotal) {
    const currencyOrder = ['TRY', 'USD', 'EUR', 'GOLD'];
    final sorted = [...breakdown]..sort((a, b) {
        final ai = currencyOrder.indexOf((a['currency'] ?? 'TRY').toString());
        final bi = currencyOrder.indexOf((b['currency'] ?? 'TRY').toString());
        return ai.compareTo(bi);
      });
    return Container(
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          height: 10,
          child: Row(
            children: sorted.map((item) {
              final tryVal = ((item['total_try'] ?? 0) as num).toDouble();
              final frac = grandTotal > 0 ? tryVal / grandTotal : 0.0;
              final currency = (item['currency'] ?? 'TRY').toString();
              final meta = _getCurrencyMeta(currency);
              
              // Use white for TRY in the breakdown bar for maximum visibility on indigo
              final color = currency == 'TRY' ? Colors.red : meta['color'] as Color;
              
              return Flexible(
                flex: (frac * 1000).round(),
                child: Container(color: color),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }



  Widget _buildGoalsSummaryCard() {
    final activeGoals = widget.goals.where((g) => g['is_completed'] != true && g['is_completed'] != 1).toList();
    final completedGoals = widget.goals.where((g) => g['is_completed'] == true || g['is_completed'] == 1).toList();

    double totalGoalSavings = 0.0;
    for (var g in widget.goals) {
      final saved = ((g['current_amount'] ?? g['saved_amount'] ?? 0) as num).toDouble();
      totalGoalSavings += saved;
    }

    // Show top 3 active goals with progress
    final topGoals = activeGoals.take(3).toList();

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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Toplanan Hedef Tasarrufu',
                        style: TextStyle(color: DesignSystem.gray, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('₺${totalGoalSavings.toStringAsFixed(0)}',
                        style: DesignSystem.heading(size: 22)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text('${activeGoals.length}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: DesignSystem.primaryIndigo)),
                  const Text('Aktif', style: TextStyle(color: DesignSystem.gray, fontSize: 12)),
                ],
              ),
              Container(width: 1, height: 32, color: Colors.grey.shade200),
              Column(
                children: [
                  Text('${completedGoals.length}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: DesignSystem.secondaryGreen)),
                  const Text('Tamamlandı', style: TextStyle(color: DesignSystem.gray, fontSize: 12)),
                ],
              ),
            ],
          ),
          if (topGoals.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Text('Aktif Hedefler',
                style: DesignSystem.body(
                    size: 12, color: DesignSystem.gray, weight: FontWeight.w600)),
            const SizedBox(height: 10),
            ...topGoals.map((g) {
              final target = ((g['target_amount'] ?? 0) as num).toDouble();
              final saved = ((g['current_amount'] ?? g['saved_amount'] ?? 0) as num).toDouble();
              final progress = target > 0 ? (saved / target).clamp(0.0, 1.0) : 0.0;
              final titleText = (g['name'] ?? g['title'] ?? 'Hedef').toString();
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(titleText,
                              style: DesignSystem.body(
                                  size: 13,
                                  color: DesignSystem.black,
                                  weight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        Text('${(progress * 100).toStringAsFixed(0)}%',
                            style: DesignSystem.body(
                                size: 12,
                                color: DesignSystem.accentCoral,
                                weight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,
                        backgroundColor: DesignSystem.lightGray,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            DesignSystem.accentCoral),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
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

  // Currency metadata helper (reused in multiple places)
  Map<String, dynamic> _getCurrencyMeta(String currency) {
    switch (currency) {
      case 'USD': return {'icon': Icons.attach_money, 'color': DesignSystem.secondaryGreen, 'symbol': '\$', 'label': 'Amerikan Doları'};
      case 'EUR': return {'icon': Icons.euro, 'color': const Color(0xFF0EA5E9), 'symbol': '€', 'label': 'Euro'};
      case 'GOLD': return {'icon': Icons.diamond, 'color': DesignSystem.warningOrange, 'symbol': 'gr', 'label': 'Gram Altın'};
      default:     return {'icon': Icons.currency_lira, 'color': DesignSystem.primaryIndigo, 'symbol': '₺', 'label': 'Türk Lirası'};
    }
  }

  Widget _buildSavingsList() {
    final savings = _savings;
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
          child: Column(
            children: [
              Icon(Icons.savings_outlined, size: 48, color: DesignSystem.primaryIndigo.withValues(alpha: 0.4)),
              const SizedBox(height: 12),
              Text('Henüz varlık eklenmemiş.', style: DesignSystem.body()),
              const SizedBox(height: 4),
              Text('Sağ alttaki + butonuyla birikim ekleyin', style: DesignSystem.body(size: 12)),
            ],
          ),
        ),
      );
    }

    // Group savings by currency for display
    final Map<String, List<dynamic>> grouped = {};
    for (final s in savings) {
      final c = s['currency'] as String? ?? 'TRY';
      grouped.putIfAbsent(c, () => []).add(s);
    }

    return Column(
      children: grouped.entries.map((entry) {
        final currency = entry.key;
        final items = entry.value;
        final meta = _getCurrencyMeta(currency);
        final color = meta['color'] as Color;
        final symbol = meta['symbol'] as String;
        final icon = meta['icon'] as IconData;
        final label = meta['label'] as String;

        // Total for this currency
        final double total = items.fold(0.0, (sum, s) => sum + (s['amount'] as num).toDouble());
        final double totalTry = _convertResultToTry(total, currency);

        return GestureDetector(
          onTap: () => _showSavingHistory(currency, items, meta),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: DesignSystem.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: color.withValues(alpha: 0.15)),
              boxShadow: DesignSystem.premiumCard().boxShadow!,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: DesignSystem.subheading(size: 15)),
                      Text('${items.length} kayıt', style: DesignSystem.body(size: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$symbol${total.toStringAsFixed(currency == 'GOLD' ? 2 : 0)}',
                        style: DesignSystem.heading(size: 17, color: color)),
                    if (currency != 'TRY')
                      Text('\u20ba${totalTry.toStringAsFixed(0)}',
                          style: DesignSystem.body(size: 12, color: DesignSystem.gray)),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.6), size: 20),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showSavingHistory(String currency, List<dynamic> items, Map<String, dynamic> meta) {
    final color = (meta['color'] as Color? ?? Colors.indigo);
    final symbol = (meta['symbol'] ?? '₺').toString();
    final icon = (meta['icon'] as IconData? ?? Icons.monetization_on);
    final label = (meta['label'] ?? currency).toString();

    // Sort newest first
    final sorted = List<dynamic>.from(items)
      ..sort((a, b) => ((b['date'] ?? '').toString()).compareTo((a['date'] ?? '').toString()));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setSheetState) {
          // Recompute totals after potential delete
          final double total = sorted.fold(0.0, (s, e) => s + (e['amount'] as num).toDouble());
          final double totalTry = _convertResultToTry(total, currency);

          return Container(
            height: MediaQuery.of(context).size.height * 0.82,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                // Drag handle
                const SizedBox(height: 12),
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                // Header banner
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.04)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
                        child: Icon(icon, color: color, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(label, style: DesignSystem.heading(size: 18)),
                            Text('${sorted.length} kayıt • toplam $symbol${total.toStringAsFixed(currency == 'GOLD' ? 2 : 0)}',
                                style: DesignSystem.body(color: color, size: 13)),
                          ],
                        ),
                      ),
                      if (currency != 'TRY') ...
                        [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('₺${totalTry.toStringAsFixed(0)}',
                                  style: DesignSystem.heading(size: 16, color: color)),
                              Text('TL karşılığı', style: DesignSystem.body(size: 11)),
                            ],
                          ),
                        ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // History list
                Expanded(
                  child: sorted.isEmpty
                    ? Center(child: Text('Kayıt yok', style: DesignSystem.body()))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: sorted.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = sorted[index];
                          final double amount = (item['amount'] as num).toDouble();
                          final double amountTry = _convertResultToTry(amount, currency);

                          // Running total up to this point (from oldest)
                          double runningTotal = 0;
                          for (int i = sorted.length - 1; i >= index; i--) {
                            runningTotal += (sorted[i]['amount'] as num).toDouble();
                          }
                          final double pct = total > 0 ? (runningTotal / total) * 100 : 0;

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: DesignSystem.lightGray,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              children: [
                                // Index bubble
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
                                  child: Center(
                                    child: Text('${sorted.length - index}',
                                        style: DesignSystem.body(color: color, size: 12, weight: FontWeight.w800)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item['description'] ?? 'Tasarruf',
                                          style: DesignSystem.body(color: DesignSystem.black, size: 13, weight: FontWeight.w600),
                                          maxLines: 1, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(Icons.calendar_today_outlined, size: 10, color: DesignSystem.gray),
                                          const SizedBox(width: 3),
                                          Text(item['date'] ?? '', style: DesignSystem.body(size: 10)),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(5)),
                                            child: Text('${pct.toStringAsFixed(0)}%',
                                                style: DesignSystem.body(color: color, size: 9, weight: FontWeight.w700)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('$symbol${amount.toStringAsFixed(currency == 'GOLD' ? 2 : 0)}',
                                        style: DesignSystem.subheading(size: 14, color: color)),
                                    if (currency != 'TRY')
                                      Text('₺${amountTry.toStringAsFixed(0)}',
                                          style: DesignSystem.body(size: 10)),
                                  ],
                                ),
                                const SizedBox(width: 4),
                                // Edit button
                                GestureDetector(
                                  onTap: () async {
                                    Navigator.pop(ctx);
                                    await _showEditSavingDialog(item, currency);
                                    _loadData();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.edit_outlined, color: color, size: 15),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                // Transfer button (non-TRY only)
                                if (currency != 'TRY')
                                  GestureDetector(
                                    onTap: () async {
                                      Navigator.pop(ctx);
                                      await _showTransferDialog(item, currency, meta);
                                      _loadData();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: DesignSystem.secondaryGreen.withValues(alpha: 0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.swap_horiz_rounded, color: DesignSystem.secondaryGreen, size: 15),
                                    ),
                                  ),
                                if (currency != 'TRY') const SizedBox(width: 4),
                                // Delete button
                                GestureDetector(
                                  onTap: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx2) => AlertDialog(
                                        backgroundColor: DesignSystem.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        title: Text('Varlığı Sil', style: DesignSystem.subheading()),
                                        content: const Text('Bu varlığı silmek istediğinize emin misiniz?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx2, false), child: const Text('İptal')),
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx2, true),
                                            child: const Text('Sil', style: TextStyle(color: DesignSystem.accentCoral, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirmed == true) {
                                      try {
                                        await ApiService.deleteSaving(item['id']);
                                        // Bug 5 fix: update both local list and parent state immediately
                                        setSheetState(() => sorted.removeAt(index));
                                        setState(() {});
                                        _loadData();
                                        if (sorted.isEmpty && context.mounted) Navigator.pop(context);
                                      } catch (e) {
                                        if (mounted) ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text('Hata: $e')));
                                      }
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: DesignSystem.accentCoral.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.delete_outline_rounded, color: DesignSystem.accentCoral, size: 15),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + MediaQuery.of(context).viewPadding.bottom),
                  child: Row(
                    children: [
                      // Bug 6 fix: pre-select the currency of this sheet
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showAddSavingDialog(initialCurrency: currency);
                          },
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: Text('$label Ekle'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  void _showAddSavingDialog({String initialCurrency = 'TRY'}) {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCurrency = initialCurrency;  // Bug 6: use pre-selected currency
    DateTime selectedDate = DateTime.now();

    // Currency metadata for chip display
    final currencies = [
      {'key': 'TRY', 'label': 'Türk Lirası', 'symbol': '₺', 'icon': Icons.currency_lira, 'color': DesignSystem.primaryIndigo},
      {'key': 'USD', 'label': 'Dolar', 'symbol': '\$', 'icon': Icons.attach_money, 'color': DesignSystem.secondaryGreen},
      {'key': 'EUR', 'label': 'Euro', 'symbol': '€', 'icon': Icons.euro, 'color': const Color(0xFF0EA5E9)},
      {'key': 'GOLD', 'label': 'Gram Altın', 'symbol': 'gr', 'icon': Icons.diamond, 'color': DesignSystem.warningOrange},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setSheetState) {
          final currMeta = currencies.firstWhere((c) => c['key'] == selectedCurrency, orElse: () => currencies[0]);
          final accentColor = currMeta['color'] as Color;
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  const SizedBox(height: 12),
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                  // Colored header
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accentColor.withValues(alpha: 0.15), accentColor.withValues(alpha: 0.04)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accentColor.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.15), shape: BoxShape.circle),
                          child: Icon(currMeta['icon'] as IconData, color: accentColor, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Varlık Ekle', style: DesignSystem.heading(size: 20)),
                            Text('Birikim kaydı oluştur', style: DesignSystem.body(color: accentColor, size: 13)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Currency chip picker
                          Row(
                            children: [
                              Icon(Icons.currency_exchange_outlined, color: accentColor, size: 16),
                              const SizedBox(width: 6),
                              Text('Para Birimi', style: DesignSystem.body(color: accentColor, size: 13, weight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: currencies.map((c) {
                              final isSel = selectedCurrency == c['key'];
                              final cc = c['color'] as Color;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => setSheetState(() => selectedCurrency = c['key'] as String),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isSel ? cc : DesignSystem.lightGray,
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: isSel ? [BoxShadow(color: cc.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))] : null,
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(c['icon'] as IconData, color: isSel ? Colors.white : DesignSystem.gray, size: 18),
                                        const SizedBox(height: 3),
                                        Text(c['symbol'] as String, style: DesignSystem.body(color: isSel ? Colors.white : DesignSystem.gray, size: 12, weight: isSel ? FontWeight.w800 : FontWeight.w500)),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: amountController,
                            keyboardType: TextInputType.number,
                            style: DesignSystem.heading(size: 18, color: DesignSystem.black),
                            decoration: InputDecoration(
                              labelText: 'Miktar (${currMeta['symbol']})',
                              prefixIcon: Icon(currMeta['icon'] as IconData, color: accentColor),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: accentColor.withValues(alpha: 0.3))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: accentColor, width: 2)),
                              labelStyle: TextStyle(color: accentColor),
                              filled: true,
                              fillColor: accentColor.withValues(alpha: 0.04),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: descriptionController,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              labelText: 'Açıklama',
                              prefixIcon: const Icon(Icons.description_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Date row styled as a toggle-like tile
                          GestureDetector(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) setSheetState(() => selectedDate = picked);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: DesignSystem.lightGray,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today_outlined, color: accentColor, size: 20),
                                  const SizedBox(width: 12),
                                  Text(DateFormat('dd MMM yyyy').format(selectedDate),
                                      style: DesignSystem.body(color: DesignSystem.black, weight: FontWeight.w600)),
                                  const Spacer(),
                                  Icon(Icons.edit_calendar_outlined, color: DesignSystem.gray, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.of(context).viewPadding.bottom),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                            child: const Text('İptal'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
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
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  _loadData();
                                } catch (e) {
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Hata: $e')));
                                  }
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: const Text('Ekle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Future<void> _showEditSavingDialog(Map<String, dynamic> item, String currency) async {
    final meta = _getCurrencyMeta(currency);
    final color = meta['color'] as Color;
    final symbol = meta['symbol'] as String;
    final amountController = TextEditingController(
        text: (item['amount'] as num).toStringAsFixed(currency == 'GOLD' ? 4 : 0));
    final descController = TextEditingController(text: item['description'] ?? '');
    DateTime selectedDate = DateTime.tryParse(item['date'] ?? '') ?? DateTime.now();

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (context, setSt) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.04)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                  ),
                  child: Row(children: [
                    Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle), child: Icon(Icons.edit_rounded, color: color, size: 20)),
                    const SizedBox(width: 14),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Varlığı Düzenle', style: DesignSystem.heading(size: 18)),
                      Text('$currency kaydını güncelle', style: DesignSystem.body(color: color, size: 12)),
                    ]),
                  ]),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        style: DesignSystem.heading(size: 18, color: DesignSystem.black),
                        decoration: InputDecoration(
                          labelText: 'Miktar ($symbol)',
                          prefixIcon: Icon(meta['icon'] as IconData, color: color),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: color.withValues(alpha: 0.3))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: color, width: 2)),
                          labelStyle: TextStyle(color: color),
                          filled: true, fillColor: color.withValues(alpha: 0.04),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          labelText: 'Açıklama',
                          prefixIcon: const Icon(Icons.description_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2100));
                          if (picked != null) setSt(() => selectedDate = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(color: DesignSystem.lightGray, borderRadius: BorderRadius.circular(16)),
                          child: Row(children: [
                            Icon(Icons.calendar_today_outlined, color: color, size: 20),
                            const SizedBox(width: 12),
                            Text(DateFormat('dd MMM yyyy').format(selectedDate), style: DesignSystem.body(color: DesignSystem.black, weight: FontWeight.w600)),
                            const Spacer(),
                            Icon(Icons.edit_calendar_outlined, color: DesignSystem.gray, size: 18),
                          ]),
                        ),
                      ),
                    ]),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.of(context).viewPadding.bottom),
                  child: Row(children: [
                    Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: const Text('İptal'))),
                    const SizedBox(width: 12),
                    Expanded(flex: 2, child: ElevatedButton(
                      onPressed: () async {
                        final newAmount = double.tryParse(amountController.text);
                        if (newAmount == null || newAmount <= 0) return;
                        try {
                          // Delete old, create new (no edit endpoint — this keeps history clean)
                          await ApiService.deleteSaving(item['id']);
                          await ApiService.addSaving(
                            amount: newAmount,
                            currency: currency,
                            description: descController.text.isEmpty ? 'Birikim' : descController.text,
                            date: DateFormat('yyyy-MM-dd').format(selectedDate),
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                        } catch (e) {
                          if (mounted) ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text('Hata: $e')));
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                      child: const Text('Kaydet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    )),
                  ]),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Future<void> _showTransferDialog(Map<String, dynamic> item, String fromCurrency, Map<String, dynamic> fromMeta) async {
    final fromColor = fromMeta['color'] as Color;
    final fromAmount = (item['amount'] as num).toDouble();
    final fromAmountTry = _convertResultToTry(fromAmount, fromCurrency);

    // Available target currencies excluding the source
    final targets = ['TRY', 'USD', 'EUR', 'GOLD'].where((c) => c != fromCurrency).toList();
    String selectedTarget = targets.first;

    double previewAmount(String toCurrency) {
      final rate = _marketData[toCurrency == 'USD' ? 'USD/TL' : toCurrency == 'EUR' ? 'EUR/TL' : toCurrency == 'GOLD' ? 'Gram Altın' : 'TRY'] ?? 1.0;
      return toCurrency == 'TRY' ? fromAmountTry : (rate > 0 ? fromAmountTry / rate : 0);
    }

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (context, setSt) {
        final toMeta = _getCurrencyMeta(selectedTarget);
        final toColor = toMeta['color'] as Color;
        final preview = previewAmount(selectedTarget);
        final toSymbol = toMeta['symbol'] as String;

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const SizedBox(height: 12),
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [DesignSystem.secondaryGreen.withValues(alpha: 0.15), DesignSystem.secondaryGreen.withValues(alpha: 0.04)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: DesignSystem.secondaryGreen.withValues(alpha: 0.2)),
                ),
                child: Row(children: [
                  Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: DesignSystem.secondaryGreen.withValues(alpha: 0.15), shape: BoxShape.circle), child: const Icon(Icons.swap_horiz_rounded, color: DesignSystem.secondaryGreen, size: 22)),
                  const SizedBox(width: 14),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Dönüştür', style: DesignSystem.heading(size: 18)),
                    Text('Canlı kurla çevir', style: DesignSystem.body(color: DesignSystem.secondaryGreen, size: 12)),
                  ]),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  // From → To display
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Column(children: [
                      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: fromColor.withValues(alpha: 0.12), shape: BoxShape.circle), child: Icon(fromMeta['icon'] as IconData, color: fromColor, size: 22)),
                      const SizedBox(height: 6),
                      Text(fromCurrency, style: DesignSystem.body(color: fromColor, weight: FontWeight.w700)),
                      Text('${fromMeta['symbol']}${fromAmount.toStringAsFixed(fromCurrency == 'GOLD' ? 4 : 2)}', style: DesignSystem.subheading(size: 14, color: fromColor)),
                    ]),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(children: [
                        const Icon(Icons.arrow_forward_rounded, color: DesignSystem.secondaryGreen, size: 28),
                        Text('≈ ₺${fromAmountTry.toStringAsFixed(0)}', style: DesignSystem.body(size: 10, color: DesignSystem.gray)),
                      ]),
                    ),
                    Column(children: [
                      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: toColor.withValues(alpha: 0.12), shape: BoxShape.circle), child: Icon(toMeta['icon'] as IconData, color: toColor, size: 22)),
                      const SizedBox(height: 6),
                      Text(selectedTarget, style: DesignSystem.body(color: toColor, weight: FontWeight.w700)),
                      Text('$toSymbol${preview.toStringAsFixed(selectedTarget == 'GOLD' ? 4 : 2)}', style: DesignSystem.subheading(size: 14, color: toColor)),
                    ]),
                  ]),
                  const SizedBox(height: 20),
                  // Target currency picker
                  Text('Hedef Para Birimi', style: DesignSystem.body(size: 12, color: DesignSystem.gray, weight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Row(
                    children: targets.map((t) {
                      final tm = _getCurrencyMeta(t);
                      final tc = tm['color'] as Color;
                      final isSel = selectedTarget == t;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setSt(() => selectedTarget = t),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSel ? tc : DesignSystem.lightGray,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: isSel ? [BoxShadow(color: tc.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))] : null,
                            ),
                            child: Column(children: [
                              Icon(tm['icon'] as IconData, color: isSel ? Colors.white : DesignSystem.gray, size: 18),
                              const SizedBox(height: 3),
                              Text(t, style: DesignSystem.body(color: isSel ? Colors.white : DesignSystem.gray, size: 11, weight: isSel ? FontWeight.w800 : FontWeight.w500)),
                            ]),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ]),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.of(context).viewPadding.bottom),
                child: Row(children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: const Text('İptal'))),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: ElevatedButton(
                    onPressed: () async {
                      try {
                        await ApiService.transferSaving(fromSavingId: item['id'], toCurrency: selectedTarget);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${fromAmount.toStringAsFixed(2)} $fromCurrency → ${preview.toStringAsFixed(4)} $selectedTarget dönüştürüldü!'), backgroundColor: DesignSystem.secondaryGreen),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: DesignSystem.secondaryGreen, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                    child: const Text('Dönüştür', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  )),
                ]),
              ),
            ]),
          ),
        );
      }),
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
