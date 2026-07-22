import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'terms.dart';
import 'wallet.dart';
import 'ai_chat.dart';
import 'profile.dart';
import '../services/api_service.dart';
import '../services/market_service.dart';
import 'package:confetti/confetti.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import '../theme/design_system.dart';

// HomePage now uses DesignSystem and unified theme.

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String savedName = '';
  String? savedJobType;
  double? savedMonthlySalary;
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = true;

  // Financial values (fetched from API)
  double monthlyIncome = 0.0;
  double monthlyExpense = 0.0;
  double monthlySavings = 0.0;

  // Detailed transactions (fetched from API)
  List<Map<String, dynamic>> incomeTransactions = [];
  List<Map<String, dynamic>> expenseTransactions = [];
  List<Map<String, dynamic>> activities = [];
  List<Map<String, dynamic>> savings = [];
  List<Map<String, dynamic>> savedExpenses = [];

  // Goal tracking state
  List<Map<String, dynamic>> goals = [];

  // Market Rates Data
  Map<String, double> liveMarketRates = {
    'USD/TL': 44.36,
    'EUR/TL': 51.45,
    'GBP/TL': 56.20,
    'JPY/TL': 0.296,
    'CHF/TL': 50.10,
    'CNY/TL': 6.10,
    'Gram Altın': 6500.0,
    'Gümüş': 55.0,
    'BTC/TL': 3160000.0,
    'ETH/TL': 72000.0,
  };

  // Currency registry — all available currencies with metadata
  static final List<Map<String, dynamic>> _currencyRegistry = [
    {
      'key': 'USD/TL',
      'label': 'ABD Doları',
      'symbol': '\$',
      'iconData': Icons.attach_money,
      'color': const Color(0xFF10B981),
    },
    {
      'key': 'EUR/TL',
      'label': 'Euro',
      'symbol': '€',
      'iconData': Icons.euro,
      'color': const Color(0xFF6366F1),
    },
    {
      'key': 'GBP/TL',
      'label': 'İngiliz Sterlini',
      'symbol': '£',
      'iconData': Icons.currency_pound,
      'color': const Color(0xFF8B5CF6),
    },
    {
      'key': 'Gram Altın',
      'label': 'Gram Altın',
      'symbol': '₺',
      'iconData': Icons.diamond,
      'color': const Color(0xFFF59E0B),
    },
    {
      'key': 'BTC/TL',
      'label': 'Bitcoin',
      'symbol': '₺',
      'iconData': Icons.currency_bitcoin,
      'color': const Color(0xFFF97316),
    },
    {
      'key': 'ETH/TL',
      'label': 'Ethereum',
      'symbol': '₺',
      'iconData': Icons.hexagon_outlined,
      'color': const Color(0xFF6366F1),
    },
    {
      'key': 'JPY/TL',
      'label': 'Japon Yeni',
      'symbol': '¥',
      'iconData': Icons.currency_yen,
      'color': const Color(0xFFEF4444),
    },
    {
      'key': 'CHF/TL',
      'label': 'İsviçre Frangı',
      'symbol': 'Fr',
      'iconData': Icons.money,
      'color': const Color(0xFFDC2626),
    },
    {
      'key': 'Gümüş',
      'label': 'Gümüş (gram)',
      'symbol': '₺',
      'iconData': Icons.grain,
      'color': const Color(0xFF94A3B8),
    },
    {
      'key': 'CNY/TL',
      'label': 'Çin Yuanı',
      'symbol': '¥',
      'iconData': Icons.currency_yuan,
      'color': const Color(0xFFDC2626),
    },
  ];

  // Selected currencies for dashboard (max 6, min 1)
  List<String> _selectedCurrencies = [
    'USD/TL',
    'EUR/TL',
    'Gram Altın',
    'BTC/TL',
  ];

  // Color mapping helper for API
  final Map<String, Color> _colorMap = {
    'purple': Colors.purple,
    'blue': Colors.blue,
    'orange': Colors.orange,
    'pink': Colors.pink,
    'teal': Colors.teal,
    'indigo': Colors.indigo,
    'green': Colors.green,
    'amber': Colors.amber,
    'red': Colors.red,
    'cyan': Colors.cyan,
  };

  DateTime selectedCalendarDate = DateTime.now();
  int _currentGoalIndex = 0;

  late ConfettiController _confettiController;

  final List<String> _categories = [
    'Gıda',
    'Ulaşım',
    'Eğlence',
    'Sağlık',
    'Eğitim',
    'Alışveriş',
    'Abonelik',
    'Kira/Fatura',
    'Spor',
    'Diğer',
  ];

  bool _showCompletedGoals = false;
  final List<Map<String, dynamic>> _goalIconOptions = [
    {'label': 'Genel', 'iconData': Icons.stars_rounded, 'key': 'stars_rounded'},
    {
      'label': 'Oyun',
      'iconData': Icons.sports_esports_rounded,
      'key': 'sports_esports_rounded',
    },
    {
      'label': 'Kıyafet',
      'iconData': Icons.checkroom_rounded,
      'key': 'checkroom_rounded',
    },
    {
      'label': 'Araç',
      'iconData': Icons.directions_car_rounded,
      'key': 'directions_car_rounded',
    },
    {
      'label': 'Eğitim',
      'iconData': Icons.school_rounded,
      'key': 'school_rounded',
    },
    {
      'label': 'Tatil',
      'iconData': Icons.flight_takeoff_rounded,
      'key': 'flight_takeoff_rounded',
    },
    {
      'label': 'Teknoloji',
      'iconData': Icons.computer_rounded,
      'key': 'computer_rounded',
    },
  ];

  IconData _getIconData(String key) {
    return _goalIconOptions.firstWhere(
      (e) => e['key'] == key,
      orElse: () => _goalIconOptions.first,
    )['iconData'];
  }

  // Investment test variables
  String? investmentProfile;
  Timer? _marketTimer;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _nameController.text = savedName;
    _loadSelectedCurrencies();
    _loadData();

    // Refresh market data every 5 minutes
    _marketTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _loadMarketData(),
    );
  }

  @override
  void dispose() {
    _marketTimer?.cancel();
    _confettiController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load financial summary
      final financialData = await ApiService.getFinancialSummary();
      setState(() {
        monthlyIncome = financialData['monthly_income'] ?? 0.0;
        monthlyExpense = financialData['monthly_expense'] ?? 0.0;
        monthlySavings = financialData['monthly_savings'] ?? 0.0;
      });

      // Load transactions (passing selected calendar date)
      final transactionsData = await ApiService.getTransactions(
        year: selectedCalendarDate.year,
        month: selectedCalendarDate.month,
      );
      setState(() {
        incomeTransactions = List<Map<String, dynamic>>.from(
          transactionsData['income'] ?? [],
        );
        expenseTransactions = List<Map<String, dynamic>>.from(
          transactionsData['expenses'] ?? [],
        );
        activities = List<Map<String, dynamic>>.from(
          transactionsData['activities'] ?? [],
        );
      });

      // Load investment profile
      final profileData = await ApiService.getInvestmentProfile();
      setState(() {
        investmentProfile = profileData['profile'];
      });

      // Load goals
      try {
        final goalsData = await ApiService.getGoals();
        final savingsData = await ApiService.getSavings();
        final savedExpData = await ApiService.getSavedExpenses();
        setState(() {
          goals = List<Map<String, dynamic>>.from(goalsData);
          savings = List<Map<String, dynamic>>.from(savingsData);
          savedExpenses = List<Map<String, dynamic>>.from(savedExpData);
          if (_currentGoalIndex >= goals.length && goals.isNotEmpty) {
            _currentGoalIndex = goals.length - 1;
          } else if (goals.isEmpty) {
            _currentGoalIndex = 0;
          }
        });
      } catch (e) {
        print('Error loading goals: $e');
      }

      // Load user name — prefer locally stored value from login,
      // fall back to the API for updates made on other sessions.
      final localUser = await ApiService.getLocalUser();
      if (localUser['name'] != null &&
          (localUser['name'] as String).isNotEmpty) {
        setState(() {
          savedName = localUser['name'];
          _nameController.text = savedName;
        });
      } else {
        try {
          final userData = await ApiService.getUserProfile();
          setState(() {
            savedName = userData['name'] ?? '';
            savedJobType = userData['job_type'];
            savedMonthlySalary = userData['monthly_salary'] != null
                ? (userData['monthly_salary'] as num).toDouble()
                : null;
            _nameController.text = savedName;
          });
        } catch (_) {}
      }

      // Load Market Data — Load independently to avoid blocking main content
      _loadMarketData();
    } catch (e) {
      // Handle error - for now, keep default values
      print('Error loading data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMarketData() async {
    try {
      final mData = await MarketService.getMarketData();
      if (mData.isNotEmpty) {
        setState(() {
          mData.forEach((key, value) {
            liveMarketRates[key] = value;
          });
        });
      }
    } catch (e) {
      print('Error loading market data: $e');
    }
  }

  Future<void> _loadSelectedCurrencies() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('selected_currencies');
    if (saved != null) {
      final list = List<String>.from(json.decode(saved));
      if (list.isNotEmpty && list.length <= 6) {
        setState(() => _selectedCurrencies = list);
      }
    }
  }

  Future<void> _saveSelectedCurrencies() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'selected_currencies',
      json.encode(_selectedCurrencies),
    );
  }

  Future<void> _loadCalendarData() async {
    try {
      final transactionsData = await ApiService.getTransactions(
        year: selectedCalendarDate.year,
        month: selectedCalendarDate.month,
      );
      setState(() {
        activities = List<Map<String, dynamic>>.from(
          transactionsData['activities'] ?? [],
        );
      });
    } catch (e) {
      print('Error loading calendar data: $e');
    }
  }

  void _changeCalendarMonth(int diff) {
    setState(() {
      selectedCalendarDate = DateTime(
        selectedCalendarDate.year,
        selectedCalendarDate.month + diff,
        1,
      );
    });
    _loadCalendarData();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 800;

    final bodyContent = Stack(
      children: [
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildBody(),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
            ],
          ),
        ),
      ],
    );

    // Wide screen (web/tablet): custom branded sidebar
    if (isWideScreen) {
      return Scaffold(
        backgroundColor: DesignSystem.background,
        body: Row(
          children: [
            // ── Custom Sidebar ──────────────────────────────────────────
            Container(
              width: 220,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  right: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                DesignSystem.primaryIndigo,
                                DesignSystem.darkIndigo,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Genç Cüzdan',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: DesignSystem.black,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              'Demo Sürümü',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: DesignSystem.primaryIndigo,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Divider(
                      color: const Color(0xFFF1F5F9),
                      thickness: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Nav items
                  ..._buildSidebarItems(),
                  const Spacer(),
                  // User card at bottom
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: DesignSystem.primaryIndigo.withValues(
                          alpha: 0.06,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: DesignSystem.primaryIndigo.withValues(
                                alpha: 0.15,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: DesignSystem.primaryIndigo,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  savedName.isEmpty
                                      ? 'Demo Kullanıcı'
                                      : savedName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: DesignSystem.black,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Text(
                                  'alper@alper.codes',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: DesignSystem.gray,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ── Main content ────────────────────────────────────────────
            Expanded(child: bodyContent),
          ],
        ),
      );
    }

    // Narrow screen: use BottomNavigationBar
    return Scaffold(
      backgroundColor: DesignSystem.background,
      body: bodyContent,
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Anasayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Cüzdan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome_rounded),
            label: 'AI Asistan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_rounded),
            label: 'Terimler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_3_rounded),
            label: 'Profil',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: Colors.white,
        selectedItemColor: DesignSystem.primaryIndigo,
        unselectedItemColor: DesignSystem.gray.withOpacity(0.5),
        selectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        iconSize: 28,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeSection();
      case 1:
        return WalletPage(
          userName: savedName,
          monthlyIncome: monthlyIncome,
          monthlyExpense: monthlyExpense,
          monthlySavings: monthlySavings,
          investmentProfile: investmentProfile,
          goals: goals,
          activities: activities,
          savings: savings,
          onStartInvestmentTest: (_) {
            _startInvestmentTest();
          },
          onRetakeInvestmentTest: _startInvestmentTest,
        );
      case 2:
        return const AiChatPage();
      case 3:
        return const TermsPage();
      case 4:
        return ProfilePage(
          completedGoalsCount: goals
              .where((g) => g['is_completed'] == true || g['is_completed'] == 1)
              .length,
          initialProfileData: {
            'name': savedName,
            'job_type': savedJobType,
            'monthly_salary': savedMonthlySalary,
          },
          onProfileSaved: (profileData) async {
            try {
              await ApiService.updateUserProfile(profileData);
              setState(() {
                if (profileData.containsKey('name')) {
                  savedName = profileData['name'];
                }
                if (profileData.containsKey('job_type')) {
                  savedJobType = profileData['job_type'];
                }
                if (profileData.containsKey('monthly_salary')) {
                  savedMonthlySalary = double.tryParse(
                    profileData['monthly_salary'].toString(),
                  );
                }
              });
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Sunucu hatası: $e'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
              print('Error saving user profile: $e');
              setState(() {
                if (profileData.containsKey('name')) {
                  savedName = profileData['name'];
                }
                if (profileData.containsKey('job_type')) {
                  savedJobType = profileData['job_type'];
                }
                if (profileData.containsKey('monthly_salary')) {
                  savedMonthlySalary = double.tryParse(
                    profileData['monthly_salary'].toString(),
                  );
                }
              });
            }
          },
          onLogout: () async {
            // In web demo mode, just reload the data instead of navigating to login
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Demo hesabındasınız. Veriler sıfırlanıyor...'),
                  backgroundColor: Color(0xFF6366F1),
                ),
              );
              await _loadData();
            }
          },
        );
      default:
        return Center(child: Text('Page ${_selectedIndex + 1}'));
    }
  }

  Widget _buildHomeSection() {
    final savingsRate = monthlyIncome > 0
        ? ((monthlySavings / monthlyIncome) * 100).clamp(0.0, 100.0)
        : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 720;
        if (isDesktop) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column — main content
                Expanded(
                  flex: 62,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroCard(savingsRate),
                      const SizedBox(height: 20),
                      if (goals.isNotEmpty) ...[
                        _buildSectionHeader(
                          'Hedeflerim',
                          icon: Icons.track_changes_rounded,
                        ),
                        const SizedBox(height: 12),
                        _buildGoalsTabbedSection(),
                        const SizedBox(height: 20),
                      ],
                      _buildSectionHeader(
                        'Hızlı İşlemler',
                        icon: Icons.flash_on_rounded,
                      ),
                      const SizedBox(height: 12),
                      _buildQuickActionsRow(),
                      const SizedBox(height: 20),
                      _buildSectionHeader(
                        'Son İşlemler',
                        icon: Icons.receipt_long_rounded,
                      ),
                      const SizedBox(height: 12),
                      _buildTransactionsList(),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // Right column — sidebar content
                SizedBox(
                  width: 320,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 0),
                      _buildSectionHeader(
                        'Takvim',
                        icon: Icons.calendar_today_rounded,
                      ),
                      const SizedBox(height: 12),
                      _buildActivityCalendar(),
                      const SizedBox(height: 20),
                      _buildSectionHeader(
                        'Piyasa',
                        icon: Icons.show_chart_rounded,
                        trailing: IconButton(
                          onPressed: _showCurrencySelectionDialog,
                          icon: const Icon(
                            Icons.tune_rounded,
                            color: DesignSystem.primaryIndigo,
                            size: 18,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildCurrencyGrid(),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        // Mobile: single column
        return _buildHomeSectionMobile(savingsRate);
      },
    );
  }

  Widget _buildSectionHeader(
    String title, {
    required IconData icon,
    Widget? trailing,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: DesignSystem.primaryIndigo),
            const SizedBox(width: 8),
            Text(title, style: DesignSystem.subheading(size: 15)),
          ],
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildQuickActionsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            title: 'Gelir/Gider Ekle',
            icon: Icons.add_chart_rounded,
            color: DesignSystem.primaryIndigo,
            onTap: _showAddTransactionDialog,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionCard(
            title: 'Kayıtlı Gider',
            icon: Icons.flash_on_rounded,
            color: DesignSystem.warningOrange,
            onTap: _showQuickAddDialog,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionCard(
            title: 'Yeni Hedef',
            icon: Icons.track_changes_rounded,
            color: DesignSystem.accentCoral,
            onTap: _showAddGoalDialog,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsList() {
    if (activities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: DesignSystem.premiumCard(),
        child: Center(
          child: Text('Henüz işlem kaydı yok', style: DesignSystem.body()),
        ),
      );
    }
    return Column(
      children: [
        ...activities.take(7).map((activity) {
          final parsedDate = DateTime.tryParse(activity['date'].toString());
          final formattedDate = parsedDate != null
              ? '${parsedDate.day}/${parsedDate.month}/${parsedDate.year}'
              : activity['date'].toString();
          return _buildTransactionItem(
            activity['description'] ?? 'İşlem',
            activity['category'] ?? 'Genel',
            (activity['amount'] as num).toDouble(),
            formattedDate,
            activity['type'] != 'gelir',
          );
        }),
      ],
    );
  }

  Widget _buildHeroCard(double savingsRate) {
    return Container(
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
          Text(
            savedName.isEmpty
                ? 'Hoşgeldiniz 👋'
                : 'Hoşgeldiniz, ${savedName.split(' ').first} 👋',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Text(
                'Birikim Oranı',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '%${savingsRate.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: savingsRate / 100,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF34D399),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeSectionMobile(double savingsRate) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroCard(savingsRate),
          const SizedBox(height: 20),
          if (goals.isNotEmpty) ...[
            _buildSectionHeader(
              'Hedeflerim',
              icon: Icons.track_changes_rounded,
            ),
            const SizedBox(height: 12),
            _buildGoalsTabbedSection(),
            const SizedBox(height: 20),
          ],
          _buildSectionHeader('Hızlı İşlemler', icon: Icons.flash_on_rounded),
          const SizedBox(height: 12),
          _buildQuickActionsRow(),
          const SizedBox(height: 24),
          _buildActivityCalendar(),
          const SizedBox(height: 24),
          _buildSectionHeader(
            'Piyasa',
            icon: Icons.show_chart_rounded,
            trailing: IconButton(
              onPressed: _showCurrencySelectionDialog,
              icon: const Icon(
                Icons.tune_rounded,
                color: DesignSystem.primaryIndigo,
                size: 18,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
          const SizedBox(height: 12),
          _buildCurrencyGrid(),
          const SizedBox(height: 24),
          _buildSectionHeader('Son İşlemler', icon: Icons.receipt_long_rounded),
          const SizedBox(height: 12),
          _buildTransactionsList(),
        ],
      ),
    );
  }

  List<Widget> _buildSidebarItems() {
    final items = [
      {
        'index': 0,
        'selIcon': Icons.home_rounded,
        'unselIcon': Icons.home_outlined,
        'label': 'Anasayfa',
      },
      {
        'index': 1,
        'selIcon': Icons.account_balance_wallet_rounded,
        'unselIcon': Icons.account_balance_wallet_outlined,
        'label': 'Cüzdan',
      },
      {
        'index': 2,
        'selIcon': Icons.auto_awesome_rounded,
        'unselIcon': Icons.auto_awesome_outlined,
        'label': 'AI Asistan',
      },
      {
        'index': 3,
        'selIcon': Icons.book_rounded,
        'unselIcon': Icons.book_outlined,
        'label': 'Terimler',
      },
      {
        'index': 4,
        'selIcon': Icons.person_rounded,
        'unselIcon': Icons.person_outlined,
        'label': 'Profil',
      },
    ];
    return items.map((item) {
      final index = item['index'] as int;
      final selIcon = item['selIcon'] as IconData;
      final unselIcon = item['unselIcon'] as IconData;
      final label = item['label'] as String;
      final isSelected = _selectedIndex == index;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => setState(() => _selectedIndex = index),
            borderRadius: BorderRadius.circular(12),
            hoverColor: DesignSystem.primaryIndigo.withValues(alpha: 0.06),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? DesignSystem.primaryIndigo.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? selIcon : unselIcon,
                    color: isSelected
                        ? DesignSystem.primaryIndigo
                        : DesignSystem.gray,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? DesignSystem.primaryIndigo
                          : DesignSystem.gray,
                    ),
                  ),
                  if (isSelected) ...[
                    const Spacer(),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: DesignSystem.primaryIndigo,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildActivityCalendar() {
    DateTime now = DateTime.now();
    int daysInMonth = DateTime(
      selectedCalendarDate.year,
      selectedCalendarDate.month + 1,
      0,
    ).day;
    int firstDayOfMonth = DateTime(
      selectedCalendarDate.year,
      selectedCalendarDate.month,
      1,
    ).weekday;

    // Get dates with activities
    Set<int> activeDates = {};
    for (var activity in activities) {
      final parsedDate = DateTime.tryParse(activity['date'].toString());
      if (parsedDate != null &&
          parsedDate.month == selectedCalendarDate.month &&
          parsedDate.year == selectedCalendarDate.year) {
        activeDates.add(parsedDate.day);
      }
    }

    List<String> weekDays = ['Pzt', 'Sal', 'Çrş', 'Prş', 'Cum', 'Cmt', 'Paz'];
    List<String> monthNames = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignSystem.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [DesignSystem.premiumCard().boxShadow![0]],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${monthNames[selectedCalendarDate.month - 1]} ${selectedCalendarDate.year}',
                style: DesignSystem.subheading().copyWith(
                  color: DesignSystem.primaryIndigo,
                  fontSize: 18,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _changeCalendarMonth(-1),
                    icon: const Icon(
                      Icons.chevron_left,
                      color: DesignSystem.primaryIndigo,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: () => _changeCalendarMonth(1),
                    icon: const Icon(
                      Icons.chevron_right,
                      color: DesignSystem.primaryIndigo,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Week day headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekDays
                .map(
                  (day) => SizedBox(
                    width: 32,
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          // Calendar grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
            ),
            itemCount: firstDayOfMonth - 1 + daysInMonth,
            itemBuilder: (context, index) {
              if (index < firstDayOfMonth - 1) {
                return const SizedBox();
              }

              int day = index - (firstDayOfMonth - 1) + 1;
              bool isToday =
                  day == now.day &&
                  selectedCalendarDate.month == now.month &&
                  selectedCalendarDate.year == now.year;
              bool hasActivity = activeDates.contains(day);

              return Container(
                decoration: BoxDecoration(
                  color: isToday
                      ? DesignSystem.primaryIndigo
                      : hasActivity
                      ? DesignSystem.warningOrange.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isToday
                      ? Border.all(color: DesignSystem.primaryIndigo, width: 2)
                      : hasActivity
                      ? Border.all(
                          color: DesignSystem.warningOrange.withValues(
                            alpha: 0.3,
                          ),
                          width: 1.5,
                        )
                      : null,
                ),
                child: Center(
                  child: Text(
                    day.toString(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isToday
                          ? Colors.white
                          : hasActivity
                          ? DesignSystem.warningOrange
                          : Colors.black87,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: DesignSystem.primaryIndigo,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              const Text('Bugün', style: TextStyle(fontSize: 10)),
              const SizedBox(width: 16),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.3),
                  border: Border.all(color: Colors.orange, width: 1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              const Text('İşlem Var', style: TextStyle(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        height: 100,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: DesignSystem.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [DesignSystem.premiumCard().boxShadow![0]],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIconContainer(icon, color),
            const SizedBox(height: 8),
            Text(
              title,
              style: DesignSystem.body().copyWith(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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

  void _showAddTransactionDialog() {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedType = 'gelir';
    String selectedCategory = 'Diğer';
    bool isNeed = true;
    int? selectedGoalId;

    if (goals.isNotEmpty && _currentGoalIndex < goals.length) {
      final g = goals[_currentGoalIndex];
      if (g['is_completed'] != true && g['is_completed'] != 1) {
        selectedGoalId = g['id'];
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isGelir = selectedType == 'gelir';
            final accentColor = isGelir
                ? DesignSystem.secondaryGreen
                : DesignSystem.accentCoral;
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
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
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Animated colored header
                    TweenAnimationBuilder<Color?>(
                      tween: ColorTween(
                        begin: isGelir
                            ? DesignSystem.accentCoral
                            : DesignSystem.secondaryGreen,
                        end: accentColor,
                      ),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      builder: (context, animColor, _) {
                        final c = animColor ?? accentColor;
                        return Container(
                          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                c.withValues(alpha: 0.15),
                                c.withValues(alpha: 0.04),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: c.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                transitionBuilder: (child, anim) =>
                                    ScaleTransition(
                                      scale: CurvedAnimation(
                                        parent: anim,
                                        curve: Curves.easeOutBack,
                                      ),
                                      child: FadeTransition(
                                        opacity: anim,
                                        child: child,
                                      ),
                                    ),
                                child: Container(
                                  key: ValueKey(selectedType),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: c.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isGelir
                                        ? Icons.arrow_upward_rounded
                                        : Icons.arrow_downward_rounded,
                                    color: c,
                                    size: 22,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'İşlem Ekle',
                                    style: DesignSystem.heading(size: 20),
                                  ),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    transitionBuilder: (child, anim) =>
                                        FadeTransition(
                                          opacity: anim,
                                          child: SlideTransition(
                                            position: Tween<Offset>(
                                              begin: const Offset(0, 0.3),
                                              end: Offset.zero,
                                            ).animate(anim),
                                            child: child,
                                          ),
                                        ),
                                    child: Text(
                                      key: ValueKey(selectedType),
                                      isGelir
                                          ? 'Gelir kaydı ekle'
                                          : 'Gider kaydı ekle',
                                      style: DesignSystem.body(
                                        color: c,
                                        size: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Type toggle
                            Container(
                              decoration: BoxDecoration(
                                color: DesignSystem.lightGray,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: Row(
                                children: ['gelir', 'gider'].map((type) {
                                  final sel = selectedType == type;
                                  final tc = type == 'gelir'
                                      ? DesignSystem.secondaryGreen
                                      : DesignSystem.accentCoral;
                                  return Expanded(
                                    child: GestureDetector(
                                      onTap: () => setSheetState(
                                        () => selectedType = type,
                                      ),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: sel
                                              ? Colors.white
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          boxShadow: sel
                                              ? [
                                                  BoxShadow(
                                                    color: tc.withValues(
                                                      alpha: 0.15,
                                                    ),
                                                    blurRadius: 8,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              type == 'gelir'
                                                  ? Icons.arrow_upward_rounded
                                                  : Icons
                                                        .arrow_downward_rounded,
                                              color: sel
                                                  ? tc
                                                  : DesignSystem.gray,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              type == 'gelir'
                                                  ? 'Gelir'
                                                  : 'Gider',
                                              style: DesignSystem.body(
                                                color: sel
                                                    ? tc
                                                    : DesignSystem.gray,
                                                weight: sel
                                                    ? FontWeight.w700
                                                    : FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TweenAnimationBuilder<Color?>(
                              tween: ColorTween(
                                begin: isGelir
                                    ? DesignSystem.accentCoral
                                    : DesignSystem.secondaryGreen,
                                end: accentColor,
                              ),
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              builder: (context, animColor, _) {
                                final c = animColor ?? accentColor;
                                return TextField(
                                  controller: amountController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  style: DesignSystem.heading(
                                    size: 18,
                                    color: DesignSystem.black,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Miktar (₺)',
                                    prefixIcon: Icon(
                                      Icons.monetization_on_outlined,
                                      color: c,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: c.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: c,
                                        width: 2,
                                      ),
                                    ),
                                    labelStyle: TextStyle(color: c),
                                    filled: true,
                                    fillColor: c.withValues(alpha: 0.04),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: descriptionController,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                labelText: 'Açıklama',
                                prefixIcon: const Icon(
                                  Icons.description_outlined,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Goal picker — pill chips
                            _buildGoalChips(
                              goals: goals,
                              selectedGoalId: selectedGoalId,
                              onChanged: (val) =>
                                  setSheetState(() => selectedGoalId = val),
                              accentColor: accentColor,
                            ),
                            const SizedBox(height: 12),
                            // Category chips
                            _buildCategoryChips(
                              categories: _categories,
                              selected: selectedCategory,
                              onChanged: (val) =>
                                  setSheetState(() => selectedCategory = val),
                              accentColor: accentColor,
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        0,
                        20,
                        20 +
                            (MediaQuery.of(context).viewInsets.bottom > 0
                                ? 0
                                : MediaQuery.of(context).viewPadding.bottom),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text('İptal'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TweenAnimationBuilder<Color?>(
                              tween: ColorTween(
                                begin: isGelir
                                    ? DesignSystem.accentCoral
                                    : DesignSystem.secondaryGreen,
                                end: accentColor,
                              ),
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              builder: (context, animColor, _) {
                                final c = animColor ?? accentColor;
                                return ElevatedButton(
                                  onPressed: () async {
                                    final amount = double.tryParse(
                                      amountController.text,
                                    );
                                    if (amount != null && amount > 0) {
                                      Navigator.pop(ctx);
                                      try {
                                        await ApiService.addTransaction(
                                          amount: amount,
                                          description:
                                              descriptionController.text.isEmpty
                                              ? (selectedType == 'gelir'
                                                    ? 'Gelir'
                                                    : 'Gider')
                                              : descriptionController.text,
                                          type: selectedType,
                                          date: DateTime.now()
                                              .toIso8601String()
                                              .substring(0, 10),
                                          goalId: selectedGoalId,
                                          category: selectedCategory,
                                          isNeed: isGelir ? true : isNeed,
                                        );
                                        await _loadData();
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            this.context,
                                          ).showSnackBar(
                                            SnackBar(content: Text('Hata: $e')),
                                          );
                                        }
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: c,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    'Kaydet',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showQuickAddDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.65,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Hızlı Gider Ekle',
                          style: DesignSystem.subheading(
                            size: 18,
                            color: DesignSystem.black,
                          ),
                        ),
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: DesignSystem.warningOrange.withOpacity(
                                0.1,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add,
                              color: DesignSystem.warningOrange,
                              size: 20,
                            ),
                          ),
                          onPressed: () {
                            _showCreateSavedExpenseDialog(setSheetState);
                          },
                        ),
                      ],
                    ),
                  ),
                  if (savedExpenses.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.flash_off_rounded,
                            size: 48,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Henüz kayıtlı gider yok.',
                            style: DesignSystem.body(color: DesignSystem.gray),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sık kullandığınız giderleri ekleyerek tek dokunuşla harcama kaydedin.',
                            style: DesignSystem.body(
                              color: DesignSystem.gray,
                              size: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: savedExpenses.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final exp = savedExpenses[i];
                          return Dismissible(
                            key: Key('saved_exp_${exp['id']}'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: DesignSystem.accentCoral.withOpacity(
                                  0.1,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.delete_outline,
                                color: DesignSystem.accentCoral,
                              ),
                            ),
                            onDismissed: (_) async {
                              try {
                                await ApiService.deleteSavedExpense(exp['id']);
                                final refreshed =
                                    await ApiService.getSavedExpenses();
                                setState(
                                  () => savedExpenses =
                                      List<Map<String, dynamic>>.from(
                                        refreshed,
                                      ),
                                );
                                setSheetState(() {});
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(
                                    this.context,
                                  ).showSnackBar(
                                    SnackBar(content: Text('Hata: $e')),
                                  );
                                }
                              }
                            },
                            child: ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              tileColor: DesignSystem.warningOrange.withOpacity(
                                0.05,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: DesignSystem.warningOrange
                                    .withOpacity(0.15),
                                child: const Icon(
                                  Icons.receipt_long_rounded,
                                  color: DesignSystem.warningOrange,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                exp['label'] ?? '',
                                style: DesignSystem.subheading(
                                  size: 14,
                                  color: DesignSystem.black,
                                ),
                              ),
                              subtitle: Text(
                                '${exp['category'] ?? 'Genel'} • ₺${(exp['amount'] as num).toStringAsFixed(0)}',
                                style: DesignSystem.body(
                                  size: 12,
                                  color: DesignSystem.gray,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right,
                                size: 18,
                                color: DesignSystem.gray,
                              ),
                              onTap: () {
                                Navigator.pop(ctx);
                                _showApplySavedExpenseDialog(exp);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCreateSavedExpenseDialog(StateSetter? parentSetState) {
    final labelController = TextEditingController();
    final amountController = TextEditingController();
    String selectedCategory = 'Diğer';
    const accentColor = DesignSystem.warningOrange;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Header
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accentColor.withValues(alpha: 0.15),
                            accentColor.withValues(alpha: 0.04),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.bookmark_add_outlined,
                              color: accentColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Yeni Hızlı Gider',
                                style: DesignSystem.heading(size: 20),
                              ),
                              Text(
                                'Şablon oluştur',
                                style: DesignSystem.body(
                                  color: accentColor,
                                  size: 13,
                                ),
                              ),
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
                            TextField(
                              controller: labelController,
                              textCapitalization: TextCapitalization.sentences,
                              style: DesignSystem.heading(
                                size: 16,
                                color: DesignSystem.black,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Gider Adı (örn: Otobüs)',
                                prefixIcon: const Icon(
                                  Icons.label_outline,
                                  color: accentColor,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: accentColor.withValues(alpha: 0.3),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: accentColor,
                                    width: 2,
                                  ),
                                ),
                                labelStyle: const TextStyle(color: accentColor),
                                filled: true,
                                fillColor: accentColor.withValues(alpha: 0.04),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: amountController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              style: DesignSystem.heading(
                                size: 18,
                                color: DesignSystem.black,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Varsayılan Miktar (₺)',
                                prefixIcon: const Icon(
                                  Icons.monetization_on_outlined,
                                  color: accentColor,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: accentColor.withValues(alpha: 0.3),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: accentColor,
                                    width: 2,
                                  ),
                                ),
                                labelStyle: const TextStyle(color: accentColor),
                                filled: true,
                                fillColor: accentColor.withValues(alpha: 0.04),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildCategoryChips(
                              categories: _categories,
                              selected: selectedCategory,
                              onChanged: (val) =>
                                  setSheetState(() => selectedCategory = val),
                              accentColor: accentColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        0,
                        20,
                        20 +
                            (MediaQuery.of(context).viewInsets.bottom > 0
                                ? 0
                                : MediaQuery.of(context).viewPadding.bottom),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text('İptal'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () async {
                                final amount = double.tryParse(
                                  amountController.text,
                                );
                                if (labelController.text.isNotEmpty &&
                                    amount != null &&
                                    amount > 0) {
                                  Navigator.pop(ctx);
                                  try {
                                    await ApiService.createSavedExpense(
                                      label: labelController.text.trim(),
                                      amount: amount,
                                      category: selectedCategory,
                                    );
                                    final refreshed =
                                        await ApiService.getSavedExpenses();
                                    setState(
                                      () => savedExpenses =
                                          List<Map<String, dynamic>>.from(
                                            refreshed,
                                          ),
                                    );
                                    parentSetState?.call(() {});
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        this.context,
                                      ).showSnackBar(
                                        SnackBar(content: Text('Hata: $e')),
                                      );
                                    }
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Kaydet',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showApplySavedExpenseDialog(Map<String, dynamic> expense) {
    final amountController = TextEditingController(
      text: (expense['amount'] as num).toStringAsFixed(0),
    );
    const accentColor = DesignSystem.warningOrange;
    final label = expense['label'] as String? ?? 'Gider';
    final category = expense['category'] as String? ?? 'Genel';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Header
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accentColor.withValues(alpha: 0.15),
                        accentColor.withValues(alpha: 0.04),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.receipt_long_rounded,
                          color: accentColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: DesignSystem.heading(size: 20),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              category,
                              style: DesignSystem.body(
                                color: accentColor,
                                size: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: DesignSystem.heading(
                          size: 22,
                          color: DesignSystem.black,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Miktar (₺)',
                          prefixIcon: const Icon(
                            Icons.monetization_on_outlined,
                            color: accentColor,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: accentColor.withValues(alpha: 0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: accentColor,
                              width: 2,
                            ),
                          ),
                          labelStyle: const TextStyle(color: accentColor),
                          filled: true,
                          fillColor: accentColor.withValues(alpha: 0.04),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Miktarı değiştirebilir veya varsayılan değerle ekleyebilirsiniz.',
                        style: DesignSystem.body(
                          color: DesignSystem.gray,
                          size: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    0,
                    20,
                    20 +
                        (MediaQuery.of(context).viewInsets.bottom > 0
                            ? 0
                            : MediaQuery.of(context).viewPadding.bottom),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('İptal'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () async {
                            final amount = double.tryParse(
                              amountController.text,
                            );
                            if (amount != null && amount > 0) {
                              Navigator.pop(ctx);
                              try {
                                final defaultAmount = (expense['amount'] as num)
                                    .toDouble();
                                await ApiService.applySavedExpense(
                                  expense['id'],
                                  overrideAmount: amount != defaultAmount
                                      ? amount
                                      : null,
                                );
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '$label eklendi: ₺${amount.toStringAsFixed(0)}',
                                      ),
                                      backgroundColor: accentColor,
                                    ),
                                  );
                                }
                                await _loadData();
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Hata: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Gider Olarak Ekle',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddGoalDialog() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    String selectedColor = 'purple';
    String selectedCategory = 'Diğer';
    String selectedIcon = 'stars_rounded';
    bool isNeed = true;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final accentColor =
                _colorMap[selectedColor] ?? DesignSystem.primaryIndigo;
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accentColor.withValues(alpha: 0.15),
                            accentColor.withValues(alpha: 0.04),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.track_changes_rounded,
                              color: accentColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Yeni Hedef',
                                style: DesignSystem.heading(size: 20),
                              ),
                              Text(
                                'Tasarruf hedefinizi belirleyin',
                                style: DesignSystem.body(
                                  color: accentColor,
                                  size: 13,
                                ),
                              ),
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
                            TextField(
                              controller: nameController,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                labelText: 'Hedef Adı (örn: Laptop)',
                                prefixIcon: Icon(
                                  Icons.edit_outlined,
                                  color: accentColor,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: accentColor.withValues(alpha: 0.3),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: accentColor,
                                    width: 2,
                                  ),
                                ),
                                labelStyle: TextStyle(color: accentColor),
                                filled: true,
                                fillColor: accentColor.withValues(alpha: 0.04),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: amountController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                labelText: 'Hedef Miktar (₺)',
                                prefixIcon: Icon(
                                  Icons.flag_outlined,
                                  color: accentColor,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: accentColor.withValues(alpha: 0.3),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: accentColor,
                                    width: 2,
                                  ),
                                ),
                                labelStyle: TextStyle(color: accentColor),
                                filled: true,
                                fillColor: accentColor.withValues(alpha: 0.04),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Bu Hedef Türü Nedir?',
                              style: DesignSystem.body(weight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: SegmentedButton<bool>(
                                segments: const [
                                  ButtonSegment(
                                    value: true,
                                    label: Text('İhtiyaç'),
                                    icon: Icon(
                                      Icons.check_circle_outline,
                                      size: 18,
                                    ),
                                  ),
                                  ButtonSegment(
                                    value: false,
                                    label: Text('İstek'),
                                    icon: Icon(Icons.favorite_border, size: 18),
                                  ),
                                ],
                                selected: {isNeed},
                                emptySelectionAllowed: false,
                                onSelectionChanged: (Set<bool> s) =>
                                    setSheetState(() => isNeed = s.first),
                                style: SegmentedButton.styleFrom(
                                  selectedBackgroundColor: DesignSystem
                                      .primaryIndigo
                                      .withOpacity(0.1),
                                  selectedForegroundColor:
                                      DesignSystem.primaryIndigo,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildCategoryChips(
                              categories: _categories,
                              selected: selectedCategory,
                              onChanged: (val) =>
                                  setSheetState(() => selectedCategory = val),
                              accentColor: accentColor,
                            ),
                            const SizedBox(height: 12),
                            // Icon picker chips
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star_outline,
                                      color: accentColor,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'İkon Seç',
                                      style: DesignSystem.body(
                                        color: accentColor,
                                        size: 13,
                                        weight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: _goalIconOptions.map((iconMap) {
                                      final key = iconMap['key'] as String;
                                      final isSel = selectedIcon == key;
                                      return GestureDetector(
                                        onTap: () => setSheetState(
                                          () => selectedIcon = key,
                                        ),
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 180,
                                          ),
                                          margin: const EdgeInsets.only(
                                            right: 10,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 9,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSel
                                                ? accentColor
                                                : DesignSystem.lightGray,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            boxShadow: isSel
                                                ? [
                                                    BoxShadow(
                                                      color: accentColor
                                                          .withValues(
                                                            alpha: 0.3,
                                                          ),
                                                      blurRadius: 8,
                                                      offset: const Offset(
                                                        0,
                                                        3,
                                                      ),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                iconMap['iconData'] as IconData,
                                                size: 16,
                                                color: isSel
                                                    ? Colors.white
                                                    : DesignSystem.gray,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                iconMap['label'] as String,
                                                style: DesignSystem.body(
                                                  color: isSel
                                                      ? Colors.white
                                                      : DesignSystem.gray,
                                                  size: 12,
                                                  weight: isSel
                                                      ? FontWeight.w700
                                                      : FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Renk Seç',
                              style: DesignSystem.body(
                                size: 13,
                                color: DesignSystem.gray,
                                weight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: _colorMap.keys.map((colorName) {
                                final isSelected = selectedColor == colorName;
                                final c = _colorMap[colorName]!;
                                return GestureDetector(
                                  onTap: () => setSheetState(
                                    () => selectedColor = colorName,
                                  ),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: c,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.black87
                                            : Colors.transparent,
                                        width: 2.5,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: c.withValues(alpha: 0.5),
                                                blurRadius: 10,
                                                offset: const Offset(0, 3),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: isSelected
                                        ? const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 20,
                                          )
                                        : null,
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        0,
                        20,
                        20 +
                            (MediaQuery.of(context).viewInsets.bottom > 0
                                ? 0
                                : MediaQuery.of(context).viewPadding.bottom),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text('İptal'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () async {
                                final amountValue = double.tryParse(
                                  amountController.text,
                                );
                                if (nameController.text.isNotEmpty &&
                                    amountValue != null) {
                                  Navigator.pop(ctx);
                                  try {
                                    await ApiService.createGoal({
                                      'title': nameController.text.trim(),
                                      'target_amount': amountValue,
                                      'category': selectedCategory,
                                      'color': selectedColor,
                                      'icon': selectedIcon,
                                      'is_need': isNeed,
                                    });
                                    await _loadData();
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        this.context,
                                      ).showSnackBar(
                                        SnackBar(content: Text('Hata: $e')),
                                      );
                                    }
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Oluştur',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGoalsTabbedSection() {
    final activeGoals = goals
        .where((g) => g['is_completed'] != true && g['is_completed'] != 1)
        .toList();
    final completedGoals = goals
        .where((g) => g['is_completed'] == true || g['is_completed'] == 1)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTabButton(
              'Devam Eden (${activeGoals.length})',
              !_showCompletedGoals,
            ),
            const SizedBox(width: 16),
            _buildTabButton(
              'Tamamlanan (${completedGoals.length})',
              _showCompletedGoals,
            ),
          ],
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: _showCompletedGoals
              ? _buildCompletedGoalsGrid(completedGoals)
              : _buildOngoingGoalsGrid(activeGoals),
        ),
      ],
    );
  }

  Widget _buildTabButton(String text, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showCompletedGoals = text.startsWith('Tamamlanan');
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? DesignSystem.primaryIndigo : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? DesignSystem.primaryIndigo
                : DesignSystem.gray.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : DesignSystem.gray,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Chip-grid category selector — replaces plain dropdown, faster and on-brand
  Widget _buildCategoryChips({
    required List<String> categories,
    required String selected,
    required ValueChanged<String> onChanged,
    required Color accentColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.category_outlined, color: accentColor, size: 16),
            const SizedBox(width: 6),
            Text(
              'Kategori',
              style: DesignSystem.body(
                color: accentColor,
                size: 13,
                weight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((cat) {
            final isSel = cat == selected;
            return GestureDetector(
              onTap: () => onChanged(cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isSel ? accentColor : DesignSystem.lightGray,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSel
                      ? [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  cat,
                  style: DesignSystem.body(
                    color: isSel ? Colors.white : DesignSystem.gray,
                    size: 13,
                    weight: isSel ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Chip-based goal picker — shows active goals as tappable pills + "Hedefsiz"
  Widget _buildGoalChips({
    required List<Map<String, dynamic>> goals,
    required int? selectedGoalId,
    required ValueChanged<int?> onChanged,
    required Color accentColor,
  }) {
    final activeGoals = goals
        .where((g) => g['is_completed'] != true && g['is_completed'] != 1)
        .toList();
    if (activeGoals.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.track_changes_rounded, color: accentColor, size: 16),
            const SizedBox(width: 6),
            Text(
              'İlişkili Hedef',
              style: DesignSystem.body(
                color: accentColor,
                size: 13,
                weight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // "Hedefsiz" pill
              GestureDetector(
                onTap: () => onChanged(null),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: selectedGoalId == null
                        ? DesignSystem.gray
                        : DesignSystem.lightGray,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Hedefsiz',
                    style: DesignSystem.body(
                      color: selectedGoalId == null
                          ? Colors.white
                          : DesignSystem.gray,
                      size: 13,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              ...activeGoals.map((g) {
                final gId = g['id'] as int;
                final isSel = selectedGoalId == gId;
                final gColor =
                    (_colorMap[g['color'] ?? g['color_key']] ?? accentColor);
                return GestureDetector(
                  onTap: () => onChanged(gId),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isSel ? gColor : DesignSystem.lightGray,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isSel
                          ? [
                              BoxShadow(
                                color: gColor.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      (g['name'] ?? g['title'] ?? 'Hedef').toString(),
                      style: DesignSystem.body(
                        color: isSel ? Colors.white : DesignSystem.gray,
                        size: 13,
                        weight: isSel ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOngoingGoalsGrid(List<Map<String, dynamic>> activeGoals) {
    return _buildGoalsGrid(
      activeGoals,
      keyPrefix: 'activeGrid',
      emptyMessage: 'Aktif hedefiniz bulunmamaktadır',
      emptyIcon: Icons.track_changes_rounded,
    );
  }

  Widget _buildCompletedGoalsGrid(List<Map<String, dynamic>> completedGoals) {
    return _buildGoalsGrid(
      completedGoals,
      keyPrefix: 'completedGrid',
      emptyMessage: 'Henüz tamamlanmış bir hedefiniz bulunmamaktadır',
      emptyIcon: Icons.emoji_events_rounded,
    );
  }

  Widget _buildGoalsGrid(
    List<Map<String, dynamic>> goalList, {
    required String keyPrefix,
    required String emptyMessage,
    required IconData emptyIcon,
  }) {
    if (goalList.isEmpty) {
      return Padding(
        key: ValueKey('empty_$keyPrefix'),
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                emptyIcon,
                size: 56,
                color: DesignSystem.gray.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 14),
              Text(
                emptyMessage,
                style: DesignSystem.subheading(
                  color: DesignSystem.gray,
                  size: 15,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final int crossAxisCount = constraints.maxWidth > 700 ? 3 : 2;
        final double childAspectRatio = constraints.maxWidth > 500 ? 1.55 : 1.15;

        return GridView.builder(
          key: ValueKey(keyPrefix),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: goalList.length,
          itemBuilder: (context, index) {
            return _buildNewGoalCard(goalList[index]);
          },
        );
      },
    );
  }

  Widget _buildNewGoalCard(Map<String, dynamic> goal) {
    bool isCompleted =
        goal['is_completed'] == true || goal['is_completed'] == 1;
    final colorKey = (goal['color'] ?? goal['color_key'] ?? 'purple')
        .toString();
    Color goalCol = isCompleted
        ? Colors.amber
        : (_colorMap[colorKey] ?? Colors.purple);
    double amount = (goal['target_amount'] as num).toDouble();
    double savedAmount =
        ((goal['saved_amount'] ?? goal['current_amount']) as num?)
            ?.toDouble() ??
        0.0;

    if (isCompleted) savedAmount = amount;
    double currentProgress = (savedAmount / amount).clamp(0.0, 1.0);
    IconData icon = _getIconData(
      (goal['icon'] ?? goal['icon_key'] ?? 'stars_rounded').toString(),
    );

    final fmtSaved = savedAmount >= 1000 ? '${(savedAmount / 1000).toStringAsFixed(1)}k' : savedAmount.toStringAsFixed(0);
    final fmtTarget = amount >= 1000 ? '${(amount / 1000).toStringAsFixed(1)}k' : amount.toStringAsFixed(0);

    return RepaintBoundary(
      child: GestureDetector(
        onTap: () => _showGoalModal(
          goal,
          goalCol,
          amount,
          savedAmount,
          currentProgress,
          isCompleted,
        ),
        child: LayoutBuilder(
          builder: (context, cardConstraints) {
            final isCompact = cardConstraints.maxWidth < 180;
            return Container(
              padding: EdgeInsets.all(isCompact ? 10 : 14),
              decoration: isCompleted
                  ? BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withValues(alpha: 0.18),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    )
                  : DesignSystem.premiumCard(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Row: Icon + Badge + Progress Pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: isCompact ? 32 : 36,
                        height: isCompact ? 32 : 36,
                        decoration: BoxDecoration(
                          color: goalCol.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCompleted ? Icons.emoji_events_rounded : icon,
                          color: goalCol,
                          size: isCompact ? 18 : 20,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (goal['is_need'] != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: DesignSystem.lightGray,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    goal['is_need'] == true || goal['is_need'] == 1 ? 'İhtiyaç' : 'İstek',
                                    style: DesignSystem.body(size: 10, color: DesignSystem.gray, weight: FontWeight.w600),
                                  ),
                                ),
                                const SizedBox(width: 4),
                              ],
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: goalCol.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  isCompleted ? 'Tamamlandı ✅' : '%${(currentProgress * 100).toStringAsFixed(0)}',
                                  style: DesignSystem.body(
                                    color: goalCol,
                                    weight: FontWeight.w800,
                                    size: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Title and Amounts
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (goal['name'] ?? goal['title'] ?? 'Hedef').toString(),
                        style: DesignSystem.heading(size: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            '₺$fmtSaved',
                            style: DesignSystem.subheading(size: 14, color: goalCol, weight: FontWeight.w800),
                          ),
                          Text(
                            ' / ₺$fmtTarget',
                            style: DesignSystem.body(size: 13, color: DesignSystem.gray, weight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Bottom Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: currentProgress,
                      minHeight: 6,
                      backgroundColor: goalCol.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(goalCol),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showGoalModal(
    Map<String, dynamic> goal,
    Color goalCol,
    double amount,
    double savedSoFar,
    double currentProgress,
    bool isCompleted,
  ) {
    if (isCompleted) {
      _confettiController.play();
    }

    showGeneralDialog(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: true,
      barrierLabel: 'Close',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580, maxHeight: 850),
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Container(
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 20),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
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
                                      (goal['name'] ?? goal['title'] ?? 'Hedef')
                                          .toString(),
                                      style: DesignSystem.heading(size: 22),
                                      maxLines: 2,
                                    ),
                                    if (goal['is_need'] != null) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            goal['is_need'] == true ||
                                                    goal['is_need'] == 1
                                                ? Icons.check_circle_outline
                                                : Icons.favorite_border,
                                            size: 14,
                                            color: DesignSystem.gray,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            goal['is_need'] == true ||
                                                    goal['is_need'] == 1
                                                ? 'İhtiyaç'
                                                : 'İstek',
                                            style: DesignSystem.body(
                                              size: 13,
                                              color: DesignSystem.gray,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                          if (isCompleted)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.amber.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.emoji_events,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Hedef Tamamlandı! \u2705 ' +
                                          (goal['completed_at'] ?? ''),
                                      style: DesignSystem.subheading(
                                        color: Colors.amber,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 24),
                          Center(
                            child: SizedBox(
                              width: 120,
                              height: 120,
                              child: CustomPaint(
                                painter: _ProgressRingPainter(
                                  progress: currentProgress,
                                  color: goalCol,
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _getIconData(
                                          goal['icon'] ?? 'stars_rounded',
                                        ),
                                        color: goalCol,
                                        size: 32,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${(currentProgress * 100).toStringAsFixed(0)}%',
                                        style: DesignSystem.heading(
                                          size: 20,
                                          color: goalCol,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildStatBox(
                                'Hedef',
                                '₺${amount.toStringAsFixed(0)}',
                                goalCol,
                              ),
                              _buildStatBox(
                                'Biriktirilen',
                                '₺${savedSoFar.toStringAsFixed(0)}',
                                goalCol,
                              ),
                              _buildStatBox(
                                'Kalan',
                                '₺${max(0, amount - savedSoFar).toStringAsFixed(0)}',
                                goalCol,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'İlerleme Grafiği',
                            style: DesignSystem.subheading(size: 16),
                          ),
                          const SizedBox(height: 16),
                          FutureBuilder<Map<String, dynamic>>(
                            future: ApiService.getGoalHistory(
                              goal['id'] as int,
                            ),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const SizedBox(
                                  height: 180,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              if (snapshot.hasError) {
                                return SizedBox(
                                  height: 180,
                                  child: Center(
                                    child: Text(
                                      'Grafik yüklenemedi: ${snapshot.error}',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              final rawData = snapshot.data ?? {};
                              final Map<String, double> historyPoints = {};

                              if (rawData.containsKey('history') &&
                                  rawData['history'] is List) {
                                final list = rawData['history'] as List;
                                for (int i = 0; i < list.length; i++) {
                                  final item = list[i];
                                  if (item is Map) {
                                    final label =
                                        (item['date'] ??
                                                item['label'] ??
                                                'Aşama $i')
                                            .toString();
                                    final amt =
                                        (item['amount'] as num?)?.toDouble() ??
                                        0.0;
                                    historyPoints[label] = amt;
                                  }
                                }
                              } else {
                                rawData.forEach((key, value) {
                                  if (value is num) {
                                    historyPoints[key] = value.toDouble();
                                  }
                                });
                              }

                              // Build spots — either real data or a flat zero placeholder
                              final List<FlSpot> spots;
                              final bool hasData = historyPoints.isNotEmpty;
                              if (hasData) {
                                spots = historyPoints.values
                                    .toList()
                                    .asMap()
                                    .entries
                                    .map(
                                      (e) => FlSpot(e.key.toDouble(), e.value),
                                    )
                                    .toList();
                              } else {
                                // Empty template: a flat line at 0 across 5 dummy points
                                spots = List.generate(
                                  5,
                                  (i) => FlSpot(i.toDouble(), 0),
                                );
                              }

                              return Stack(
                                children: [
                                  SizedBox(
                                    height: 180,
                                    child: LineChart(
                                      LineChartData(
                                        gridData: FlGridData(
                                          show: true,
                                          drawVerticalLine: false,
                                          getDrawingHorizontalLine: (_) =>
                                              FlLine(
                                                color: Colors.grey.withOpacity(
                                                  0.15,
                                                ),
                                                strokeWidth: 1,
                                              ),
                                        ),
                                        titlesData: FlTitlesData(
                                          show: true,
                                          leftTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              reservedSize: 42,
                                              getTitlesWidget: (value, meta) {
                                                if (value == 0) {
                                                  return const Text('');
                                                }
                                                return Text(
                                                  '₺${value >= 1000 ? '${(value / 1000).toStringAsFixed(0)}k' : value.toStringAsFixed(0)}',
                                                  style: const TextStyle(
                                                    fontSize: 9,
                                                    color: Colors.grey,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          rightTitles: const AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: false,
                                            ),
                                          ),
                                          topTitles: const AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: false,
                                            ),
                                          ),
                                          bottomTitles: const AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: false,
                                            ),
                                          ),
                                        ),
                                        borderData: FlBorderData(
                                          show: true,
                                          border: Border(
                                            bottom: BorderSide(
                                              color: Colors.grey.withOpacity(
                                                0.2,
                                              ),
                                              width: 1,
                                            ),
                                            left: BorderSide(
                                              color: Colors.grey.withOpacity(
                                                0.2,
                                              ),
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                        minX: 0,
                                        maxX: max(
                                          4,
                                          spots.length.toDouble() - 1,
                                        ),
                                        minY: 0,
                                        maxY: amount > 0 ? amount : 1,
                                        // Target line
                                        extraLinesData: ExtraLinesData(
                                          horizontalLines: [
                                            HorizontalLine(
                                              y: amount > 0 ? amount : 1,
                                              color: goalCol.withOpacity(0.4),
                                              strokeWidth: 1.5,
                                              dashArray: [6, 4],
                                              label: HorizontalLineLabel(
                                                show: true,
                                                alignment: Alignment.topRight,
                                                labelResolver: (_) => 'Hedef',
                                                style: TextStyle(
                                                  color: goalCol,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        lineBarsData: [
                                          LineChartBarData(
                                            spots: spots,
                                            isCurved: true,
                                            color: hasData
                                                ? goalCol
                                                : Colors.grey.shade300,
                                            barWidth: hasData ? 3 : 2,
                                            isStrokeCapRound: true,
                                            dotData: FlDotData(
                                              show: hasData,
                                              getDotPainter:
                                                  (
                                                    spot,
                                                    percent,
                                                    barData,
                                                    index,
                                                  ) => FlDotCirclePainter(
                                                    radius: 3,
                                                    color: Colors.white,
                                                    strokeWidth: 2,
                                                    strokeColor: goalCol,
                                                  ),
                                            ),
                                            belowBarData: BarAreaData(
                                              show: true,
                                              gradient: LinearGradient(
                                                colors: hasData
                                                    ? [
                                                        goalCol.withOpacity(
                                                          0.25,
                                                        ),
                                                        goalCol.withOpacity(
                                                          0.0,
                                                        ),
                                                      ]
                                                    : [
                                                        Colors.grey.withOpacity(
                                                          0.08,
                                                        ),
                                                        Colors.grey.withOpacity(
                                                          0.0,
                                                        ),
                                                      ],
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (!hasData)
                                    Positioned.fill(
                                      child: Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.show_chart_rounded,
                                              size: 32,
                                              color: Colors.grey.shade300,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              'Henüz işlem kaydı yok',
                                              style: TextStyle(
                                                color: Colors.grey.shade400,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              'Gelir/gider ekledikçe grafik oluşacak',
                                              style: TextStyle(
                                                color: Colors.grey.shade300,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  if (hasData)
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton.icon(
                                        onPressed: () {
                                          _showAllProgressHistory(
                                            goal,
                                            historyPoints,
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.history,
                                          size: 16,
                                        ),
                                        label: const Text(
                                          'Tüm Geçmişi Gör',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          // Action Buttons Logic
                          if (!isCompleted && currentProgress >= 1.0)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _purchaseGoalAction(goal);
                                  _confettiController.play();
                                },
                                icon: const Icon(
                                  Icons.shopping_cart_checkout,
                                  size: 18,
                                ),
                                label: const Text('Satın Al / Tamamla'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: DesignSystem.secondaryGreen,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          if (!isCompleted &&
                              savings.isNotEmpty &&
                              currentProgress < 1.0)
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _showUseSavingsDialog(goal);
                                },
                                icon: Icon(
                                  Icons.account_balance_wallet_outlined,
                                  size: 16,
                                  color: goalCol,
                                ),
                                label: Text(
                                  'Varlıktan Kullan',
                                  style: TextStyle(
                                    color: goalCol,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: goalCol.withOpacity(0.5),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          if (!isCompleted)
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _showGoalCustomizeDialog(goal);
                                    },
                                    child: Text(
                                      'Düzenle',
                                      style: DesignSystem.body(
                                        color: DesignSystem.primaryIndigo,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _deleteGoalConfirm(goal);
                                    },
                                    child: Text(
                                      'Sil',
                                      style: DesignSystem.body(
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (isCompleted)
                    ConfettiWidget(
                      confettiController: _confettiController,
                      blastDirectionality: BlastDirectionality.explosive,
                      shouldLoop: false,
                      numberOfParticles: 30,
                      gravity: 0.2,
                      colors: const [
                        Colors.green,
                        Colors.blue,
                        Colors.pink,
                        Colors.orange,
                        Colors.purple,
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: CurvedAnimation(
            parent: anim1,
            curve: Curves.easeOutBack,
          ).value,
          child: Opacity(opacity: anim1.value, child: child),
        );
      },
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: DesignSystem.body(size: 12)),
        const SizedBox(height: 4),
        Text(value, style: DesignSystem.subheading(size: 14, color: color)),
      ],
    );
  }

  Future<void> _purchaseGoalAction(Map<String, dynamic> goal) async {
    try {
      await ApiService.purchaseGoal(goal['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${(goal['name'] ?? goal['title'] ?? 'Hedef').toString()} hedefini başarıyla satın aldınız!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _confettiController.play();
      }
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Satın alma hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showUseSavingsDialog(Map<String, dynamic> goal) {
    final goalCol =
        _colorMap[goal['color'] ?? goal['color_key']] ?? Colors.purple;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Varlık Seç',
                  style: DesignSystem.subheading(
                    size: 18,
                    color: DesignSystem.black,
                  ),
                ),
              ),
              if (savings.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Kullanılabilir varlık yok.',
                    style: DesignSystem.body(color: DesignSystem.gray),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: savings.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final s = savings[i];
                      final currency = s['currency'] ?? 'TRY';
                      final amount = (s['amount'] as num).toDouble();
                      final desc = s['description'] ?? currency;
                      String symbol = currency == 'USD'
                          ? '\$'
                          : currency == 'EUR'
                          ? '€'
                          : currency == 'GOLD'
                          ? 'gr'
                          : '₺';
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        tileColor: goalCol.withOpacity(0.05),
                        leading: CircleAvatar(
                          backgroundColor: goalCol.withOpacity(0.15),
                          child: Icon(
                            Icons.account_balance_wallet,
                            color: goalCol,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          desc,
                          style: DesignSystem.subheading(
                            size: 14,
                            color: DesignSystem.black,
                          ),
                        ),
                        subtitle: Text(
                          '$symbol${amount.toStringAsFixed(2)}',
                          style: DesignSystem.body(
                            size: 12,
                            color: DesignSystem.gray,
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: goalCol,
                        ),
                        onTap: () async {
                          Navigator.pop(ctx);
                          try {
                            await ApiService.fundGoalFromSaving(
                              goal['id'],
                              s['id'],
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('$desc hedefe uygulandı!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                            await _loadData();
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Hata: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteGoalConfirm(Map<String, dynamic> goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DesignSystem.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Hedefi Sil?', style: DesignSystem.subheading()),
        content: Text(
          '${(goal['name'] ?? goal['title'] ?? 'Hedef').toString()} hedefini silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Sil',
              style: TextStyle(
                color: DesignSystem.accentCoral,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.deleteGoal(goal['id']);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Hedef silindi')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Hata: $e')));
        }
      }
    }
  }

  Widget _buildTransactionItem(
    String title,
    String category,
    double amount,
    String date,
    bool isExpense,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: DesignSystem.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  (isExpense
                          ? DesignSystem.accentCoral
                          : DesignSystem.secondaryGreen)
                      .withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isExpense ? Icons.arrow_outward : Icons.arrow_downward,
              color: isExpense
                  ? DesignSystem.accentCoral
                  : DesignSystem.secondaryGreen,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: DesignSystem.subheading(
                    size: 13,
                    color: DesignSystem.black,
                  ),
                ),
                Text(
                  '$category • $date',
                  style: DesignSystem.body(size: 11, color: DesignSystem.gray),
                ),
              ],
            ),
          ),
          Text(
            '${isExpense ? '-' : '+'}₺${_fmtAmount(amount)}',
            style: DesignSystem.subheading(
              size: 13,
              color: isExpense
                  ? DesignSystem.accentCoral
                  : DesignSystem.secondaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  String _fmtAmount(double amount) {
    if (amount >= 1000) {
      return amount
          .toStringAsFixed(0)
          .replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]}.',
          );
    }
    return amount.toStringAsFixed(2);
  }

  Widget _buildCurrencyGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 500 ? 3 : 2;
        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
          ),
          itemCount: _selectedCurrencies.length,
          itemBuilder: (context, index) {
            String key = _selectedCurrencies[index];
            return _buildUnifiedCurrencyCard(key);
          },
        );
      },
    );
  }

  Widget _buildUnifiedCurrencyCard(String key) {
    final meta = _currencyRegistry.firstWhere(
      (c) => c['key'] == key,
      orElse: () => _currencyRegistry.first,
    );
    final isCryptoOrCommodity =
        meta['key'] == 'Gram Altın' ||
        meta['key'] == 'Gümüş' ||
        meta['key'] == 'BTC/TL' ||
        meta['key'] == 'ETH/TL';

    double rate = liveMarketRates[key] ?? 0.0;
    String displayRate;
    if (isCryptoOrCommodity) {
      displayRate =
          '₺${rate > 1000 ? rate.toStringAsFixed(0) : rate.toStringAsFixed(2)}';
    } else {
      displayRate = rate.toStringAsFixed(2);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border(
          left: BorderSide(color: meta['color'] as Color, width: 3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    meta['label'],
                    style: DesignSystem.subheading(
                      size: 13,
                      color: DesignSystem.gray,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: DesignSystem.secondaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: DesignSystem.secondaryGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Canlı',
                        style: DesignSystem.body(
                          color: DesignSystem.secondaryGreen,
                          weight: FontWeight.w700,
                          size: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: meta['color'].withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(meta['iconData'], color: meta['color'], size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    displayRate,
                    style: DesignSystem.heading(size: 18),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrencySelectionDialog() {
    List<String> tempSelection = List.from(_selectedCurrencies);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bottomPad = MediaQuery.of(context).viewPadding.bottom;
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  // Colored header
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          DesignSystem.primaryIndigo.withValues(alpha: 0.12),
                          DesignSystem.primaryIndigo.withValues(alpha: 0.04),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: DesignSystem.primaryIndigo.withValues(
                          alpha: 0.2,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: DesignSystem.primaryIndigo.withValues(
                              alpha: 0.15,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            color: DesignSystem.primaryIndigo,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Döviz Kurlarını Özelleştir',
                              style: DesignSystem.heading(size: 18),
                            ),
                            Text(
                              'En az 1, en fazla 6 kur seçin',
                              style: DesignSystem.body(
                                color: DesignSystem.primaryIndigo,
                                size: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _currencyRegistry.length,
                      itemBuilder: (context, index) {
                        final meta = _currencyRegistry[index];
                        final isSelected = tempSelection.contains(meta['key']);
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (meta['color'] as Color).withValues(
                                    alpha: 0.07,
                                  )
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? (meta['color'] as Color).withValues(
                                      alpha: 0.3,
                                    )
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: CheckboxListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            title: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: (meta['color'] as Color).withValues(
                                      alpha: 0.12,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    meta['iconData'],
                                    color: meta['color'],
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  meta['label'],
                                  style: DesignSystem.subheading(
                                    size: 15,
                                    color: isSelected
                                        ? meta['color']
                                        : DesignSystem.black,
                                  ),
                                ),
                              ],
                            ),
                            activeColor: meta['color'],
                            checkColor: Colors.white,
                            value: isSelected,
                            onChanged: (bool? val) {
                              setModalState(() {
                                if (val == true) {
                                  if (tempSelection.length < 6) {
                                    tempSelection.add(meta['key']);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'En fazla 6 kur seçebilirsiniz.',
                                        ),
                                      ),
                                    );
                                  }
                                } else {
                                  if (tempSelection.length > 1) {
                                    tempSelection.remove(meta['key']);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'En az 1 kur seçmelisiniz.',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomPad),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedCurrencies = List.from(tempSelection);
                          });
                          _saveSelectedCurrencies();
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text(
                          'Kaydet ve Uygula',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DesignSystem.primaryIndigo,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAllProgressHistory(
    Map<String, dynamic> goal,
    Map<String, double> history,
  ) {
    Color goalCol =
        _colorMap[goal['color'] ?? goal['color_key']] ?? Colors.purple;
    double amount = (goal['target_amount'] as num).toDouble();

    DesignSystem.showPremiumDialog(
      context: context,
      title: 'İlerleme Geçmişi',
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (goal['name'] ?? goal['title'] ?? 'Hedef').toString(),
                style: DesignSystem.subheading(color: goalCol),
              ),
              const SizedBox(height: 20),
              ...history.entries
                  .toList()
                  .asMap()
                  .entries
                  .map((item) {
                    int index = item.key;
                    var entry = item.value;
                    String month = entry.key;
                    double currentValue = entry.value;
                    double previousValue = index > 0
                        ? history.values.toList()[index - 1]
                        : 0;
                    double monthlyAddition = currentValue - previousValue;
                    double percentage = (currentValue / amount) * 100;
                    double monthlyPercentage = (monthlyAddition / amount) * 100;

                    return _buildGoalProgressItem(
                      month,
                      monthlyAddition,
                      currentValue,
                      monthlyPercentage,
                      percentage,
                      monthlyAddition > 0,
                      goalCol,
                      amount,
                    );
                  })
                  .toList()
                  .reversed,
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Kapat'),
        ),
      ],
    );
  }

  Widget _buildGoalProgressItem(
    String month,
    double monthlyAddition,
    double totalProgress,
    double monthlyPercentage,
    double totalPercentage,
    bool isPositive,
    Color goalColor,
    double goalAmount,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                month,
                style: DesignSystem.body(size: 13, weight: FontWeight.w600),
              ),
              Row(
                children: [
                  Icon(
                    isPositive ? Icons.trending_up : Icons.trending_down,
                    color: goalColor,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '+ ₺${monthlyAddition.toStringAsFixed(0)} / ${monthlyPercentage.toStringAsFixed(1)}%',
                    style: DesignSystem.body(
                      size: 13,
                      weight: FontWeight.w700,
                      color: goalColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LayoutBuilder(
              builder: (context, constraints) {
                double previousPercentage =
                    ((totalProgress - monthlyAddition) / goalAmount).clamp(
                      0.0,
                      1.0,
                    );
                double monthlyPercentageBar = (monthlyAddition / goalAmount)
                    .clamp(0.0, 1.0 - previousPercentage);

                return SizedBox(
                  height: 8,
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        color: DesignSystem.gray.withOpacity(0.1),
                      ),
                      Positioned(
                        left: 0,
                        top: 0,
                        width: previousPercentage * constraints.maxWidth,
                        height: 8,
                        child: Container(
                          color: goalColor.withValues(alpha: 0.5),
                        ),
                      ),
                      Positioned(
                        left: previousPercentage * constraints.maxWidth,
                        top: 0,
                        width: monthlyPercentageBar * constraints.maxWidth,
                        height: 8,
                        child: Container(color: goalColor),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Toplam: ₺${totalProgress.toStringAsFixed(0)} (${totalPercentage.toStringAsFixed(1)}%)',
            style: DesignSystem.body(size: 11, color: DesignSystem.gray),
          ),
        ],
      ),
    );
  }

  void _showGoalCustomizeDialog(Map<String, dynamic> goal) {
    DesignSystem.showPremiumDialog(
      context: context,
      title: 'Hedefi Özelleştir',
      content: _GoalCustomizeDialog(
        initialName: (goal['name'] ?? goal['title'] ?? 'Hedef').toString(),
        initialAmount: (goal['target_amount'] as num).toDouble(),
        initialColor:
            _colorMap[goal['color'] ?? goal['color_key']] ?? Colors.purple,
        initialIcon: (goal['icon'] ?? goal['icon_key'] ?? 'stars_rounded')
            .toString(),
        initialIsNeed: goal['is_need'] ?? true,
        onSave: (newName, newAmount, newColor, newIcon, newIsNeed) async {
          String colorString = 'purple';
          _colorMap.forEach((key, value) {
            if (value.value == newColor.value) colorString = key;
          });

          try {
            await ApiService.updateGoal(goal['id'], {
              'title': newName,
              'target_amount': newAmount,
              'color': colorString,
              'icon': newIcon,
              'is_need': newIsNeed,
            });
            await _loadData();
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Hata: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _startInvestmentTest() {
    setState(() {
      investmentProfile = null;
    });
    showDialog(
      context: context,
      builder: (context) => InvestmentTestDialog(
        onTestComplete: (profile) async {
          final navigatorContext = context;
          try {
            await ApiService.saveInvestmentProfile(profile);
            setState(() {
              investmentProfile = profile;
            });
          } catch (e) {
            print('Error saving investment profile: $e');
            setState(() {
              investmentProfile = profile;
            });
          }
          if (mounted && navigatorContext.mounted) {
            Navigator.pop(navigatorContext);
          }
        },
      ),
    );
  }
}

class _GoalCustomizeDialog extends StatefulWidget {
  final String initialName;
  final double initialAmount;
  final Color initialColor;
  final String initialIcon;
  final bool initialIsNeed;
  final Function(String, double, Color, String, bool) onSave;

  const _GoalCustomizeDialog({
    required this.initialName,
    required this.initialAmount,
    required this.initialColor,
    required this.initialIcon,
    required this.initialIsNeed,
    required this.onSave,
  });

  @override
  State<_GoalCustomizeDialog> createState() => _GoalCustomizeDialogState();
}

class _GoalCustomizeDialogState extends State<_GoalCustomizeDialog> {
  late TextEditingController nameController;
  late TextEditingController amountController;
  late Color selectedColor;
  late String selectedIcon;
  late bool isNeed;

  final List<Map<String, dynamic>> _goalIconOptions = [
    {'label': 'Genel', 'iconData': Icons.stars_rounded, 'key': 'stars_rounded'},
    {
      'label': 'Oyun',
      'iconData': Icons.sports_esports_rounded,
      'key': 'sports_esports_rounded',
    },
    {
      'label': 'Kıyafet',
      'iconData': Icons.checkroom_rounded,
      'key': 'checkroom_rounded',
    },
    {
      'label': 'Araç',
      'iconData': Icons.directions_car_rounded,
      'key': 'directions_car_rounded',
    },
    {
      'label': 'Eğitim',
      'iconData': Icons.school_rounded,
      'key': 'school_rounded',
    },
    {
      'label': 'Tatil',
      'iconData': Icons.flight_takeoff_rounded,
      'key': 'flight_takeoff_rounded',
    },
    {
      'label': 'Teknoloji',
      'iconData': Icons.computer_rounded,
      'key': 'computer_rounded',
    },
  ];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.initialName);
    amountController = TextEditingController(
      text: widget.initialAmount.toStringAsFixed(0),
    );
    selectedColor = widget.initialColor;
    selectedIcon = widget.initialIcon;
    isNeed = widget.initialIsNeed;
  }

  @override
  void dispose() {
    nameController.dispose();
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hedef Adı (Max 25 karakter)',
            style: DesignSystem.body(
              size: 14,
              color: DesignSystem.gray,
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: nameController,
            maxLength: 25,
            style: DesignSystem.body(
              color: DesignSystem.black,
              weight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'Hedef adı',
              prefixIcon: const Icon(
                Icons.edit,
                color: DesignSystem.primaryIndigo,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Hedef Tutarı (₺)',
            style: DesignSystem.body(
              size: 14,
              color: DesignSystem.gray,
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: DesignSystem.body(
              color: DesignSystem.black,
              weight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'Tutar',
              prefixIcon: const Icon(
                Icons.money,
                color: DesignSystem.primaryIndigo,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Bu Hedef Türü Nedir?',
            style: DesignSystem.body(
              size: 14,
              color: DesignSystem.gray,
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  label: Text('İhtiyaç'),
                  icon: Icon(Icons.check_circle_outline, size: 18),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('İstek'),
                  icon: Icon(Icons.favorite_border, size: 18),
                ),
              ],
              selected: {isNeed},
              emptySelectionAllowed: false,
              onSelectionChanged: (Set<bool> s) =>
                  setState(() => isNeed = s.first),
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: DesignSystem.primaryIndigo.withOpacity(
                  0.1,
                ),
                selectedForegroundColor: DesignSystem.primaryIndigo,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'İkon Seç',
            style: DesignSystem.body(
              size: 14,
              color: DesignSystem.gray,
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: selectedIcon,
            items: _goalIconOptions
                .map(
                  (iconMap) => DropdownMenuItem(
                    value: iconMap['key'] as String,
                    child: Row(
                      children: [
                        Icon(
                          iconMap['iconData'] as IconData,
                          size: 20,
                          color: DesignSystem.gray,
                        ),
                        const SizedBox(width: 8),
                        Text(iconMap['label'] as String),
                      ],
                    ),
                  ),
                )
                .toList(),
            onChanged: (val) => setState(() => selectedIcon = val!),
            decoration: InputDecoration(
              hintText: 'İkon',
              prefixIcon: const Icon(Icons.star_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Renk Seç',
            style: DesignSystem.body(
              size: 14,
              color: DesignSystem.gray,
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children:
                [
                  Colors.purple,
                  Colors.blue,
                  Colors.orange,
                  Colors.pink,
                  Colors.teal,
                  Colors.indigo,
                ].map((color) {
                  bool isSelected = selectedColor.value == color.value;
                  return GestureDetector(
                    onTap: () => setState(() => selectedColor = color),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? DesignSystem.primaryIndigo
                              : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  final amt = double.tryParse(amountController.text);
                  if (nameController.text.isNotEmpty &&
                      amt != null &&
                      amt > 0) {
                    widget.onSave(
                      nameController.text.trim(),
                      amt,
                      selectedColor,
                      selectedIcon,
                      isNeed,
                    );
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignSystem.primaryIndigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text('Kaydet'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  _ProgressRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final bgPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    final fgPaint = Paint()
      ..shader = SweepGradient(
        colors: [color.withOpacity(0.4), color],
        startAngle: -pi / 2,
        endAngle: 3 * pi / 2,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6;

    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi * progress.clamp(0.0, 1.0),
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
