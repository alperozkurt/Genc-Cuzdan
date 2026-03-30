import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'terms.dart';
import 'wallet.dart';
import 'profile.dart';
import '../services/api_service.dart';
import '../services/market_service.dart';
import 'package:confetti/confetti.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _showGoalDetails = false;
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
    'USD/TL': 44.36, 'EUR/TL': 51.45, 'GBP/TL': 56.20, 'JPY/TL': 0.296,
    'CHF/TL': 50.10, 'CNY/TL': 6.10,
    'Gram Altın': 6500.0, 'Gümüş': 55.0,
    'BTC/TL': 3160000.0, 'ETH/TL': 72000.0,
  };

  // Currency registry — all available currencies with metadata
  static final List<Map<String, dynamic>> _currencyRegistry = [
    {'key': 'USD/TL', 'label': 'ABD Doları', 'symbol': '\$', 'iconData': Icons.attach_money, 'color': const Color(0xFF10B981)},
    {'key': 'EUR/TL', 'label': 'Euro', 'symbol': '€', 'iconData': Icons.euro, 'color': const Color(0xFF6366F1)},
    {'key': 'GBP/TL', 'label': 'İngiliz Sterlini', 'symbol': '£', 'iconData': Icons.currency_pound, 'color': const Color(0xFF8B5CF6)},
    {'key': 'Gram Altın', 'label': 'Gram Altın', 'symbol': '₺', 'iconData': Icons.diamond, 'color': const Color(0xFFF59E0B)},
    {'key': 'BTC/TL', 'label': 'Bitcoin', 'symbol': '₺', 'iconData': Icons.currency_bitcoin, 'color': const Color(0xFFF97316)},
    {'key': 'ETH/TL', 'label': 'Ethereum', 'symbol': '₺', 'iconData': Icons.hexagon_outlined, 'color': const Color(0xFF6366F1)},
    {'key': 'JPY/TL', 'label': 'Japon Yeni', 'symbol': '¥', 'iconData': Icons.currency_yen, 'color': const Color(0xFFEF4444)},
    {'key': 'CHF/TL', 'label': 'İsviçre Frangı', 'symbol': 'Fr', 'iconData': Icons.money, 'color': const Color(0xFFDC2626)},
    {'key': 'Gümüş', 'label': 'Gümüş (gram)', 'symbol': '₺', 'iconData': Icons.grain, 'color': const Color(0xFF94A3B8)},
    {'key': 'CNY/TL', 'label': 'Çin Yuanı', 'symbol': '¥', 'iconData': Icons.currency_yuan, 'color': const Color(0xFFDC2626)},
  ];

  // Selected currencies for dashboard (max 6, min 1)
  List<String> _selectedCurrencies = ['USD/TL', 'EUR/TL', 'Gram Altın', 'BTC/TL'];

  // Color mapping helper for API
  final Map<String, Color> _colorMap = {
    'purple': Colors.purple,
    'blue': Colors.blue,
    'orange': Colors.orange,
    'pink': Colors.pink,
    'teal': Colors.teal,
    'indigo': Colors.indigo,
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
    'Diğer'
  ];

  bool _showCompletedGoals = false;
  final List<Map<String, dynamic>> _goalIconOptions = [
    {'label': 'Genel', 'iconData': Icons.stars_rounded, 'key': 'stars_rounded'},
    {'label': 'Ev', 'iconData': Icons.home_rounded, 'key': 'home_rounded'},
    {'label': 'Araç', 'iconData': Icons.directions_car_rounded, 'key': 'directions_car_rounded'},
    {'label': 'Eğitim', 'iconData': Icons.school_rounded, 'key': 'school_rounded'},
    {'label': 'Tatil', 'iconData': Icons.flight_takeoff_rounded, 'key': 'flight_takeoff_rounded'},
    {'label': 'Teknoloji', 'iconData': Icons.computer_rounded, 'key': 'computer_rounded'},
  ];

  IconData _getIconData(String key) {
    return _goalIconOptions.firstWhere((e) => e['key'] == key, orElse: () => _goalIconOptions.first)['iconData'];
  }

  // Investment test variables
  String? investmentProfile;
  Timer? _marketTimer;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _nameController.text = savedName;
    _loadSelectedCurrencies();
    _loadData();
    
    // Refresh market data every 5 minutes
    _marketTimer = Timer.periodic(const Duration(minutes: 5), (_) => _loadMarketData());
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
            savedMonthlySalary = userData['monthly_salary'] != null ? (userData['monthly_salary'] as num).toDouble() : null;
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
    await prefs.setString('selected_currencies', json.encode(_selectedCurrencies));
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


  Map<String, double> _getMonthlyProgressForGoal(int goalId, double goalAmount) {
    Map<String, double> netPerMonth = {};
    for (var activity in activities) {
      if (activity['goal_id'] != goalId) continue;

      final date = DateTime.tryParse(activity['date'].toString());
      if (date == null) continue;

      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      final isIncome = activity['type'] == 'gelir';
      final amount = (activity['amount'] as num).toDouble();

      netPerMonth.update(
        monthKey,
        (val) => val + (isIncome ? amount : -amount),
        ifAbsent: () => isIncome ? amount : -amount,
      );
    }

    final sortedMonths = netPerMonth.keys.toList()..sort();

    final List<String> monthNames = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
    ];

    Map<String, double> newProgress = {};
    double runningTotal = 0;

    if (sortedMonths.isEmpty) {
      final now = DateTime.now();
      newProgress['${monthNames[now.month - 1]} ${now.year}'] = 0.0;
    } else {
      for (String monthKey in sortedMonths) {
        runningTotal += netPerMonth[monthKey]!;
        if (runningTotal < 0) runningTotal = 0;

        final parts = monthKey.split('-');
        final monthIndex = int.parse(parts[1]) - 1;
        final formattedName = '${monthNames[monthIndex]} ${parts[0]}';

        newProgress[formattedName] = runningTotal;
      }
    }
    return newProgress;
  }

  double _calculateCurrentProgressForGoal(int goalId, double goalAmount) {
    if (goalAmount <= 0) return 0.0;
    double total = 0.0;
    for (var activity in activities) {
      if (activity['goal_id'] == goalId) {
        if (activity['type'] == 'gelir') {
          total += (activity['amount'] as num).toDouble();
        } else if (activity['type'] == 'gider') {
          total -= (activity['amount'] as num).toDouble();
        }
      }
    }
    return (total / goalAmount).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.background,
      appBar: AppBar(
        title: const Text(
          'GençCüzdan',
          style: TextStyle(color: DesignSystem.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: DesignSystem.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: DesignSystem.black),
      ),
      body: Stack(
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
                Colors.purple
              ],
            ),
          ),
        ],
      ),
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
        return const TermsPage();
      case 3:
        return ProfilePage(
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
                   savedMonthlySalary = double.tryParse(profileData['monthly_salary'].toString());
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
                   savedMonthlySalary = double.tryParse(profileData['monthly_salary'].toString());
                }
              });
            }
          },
          onLogout: () async {
            await ApiService.logout();
            if (mounted) {
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/login', (route) => false);
            }
          },
        );
      default:
        return Center(child: Text('Page ${_selectedIndex + 1}'));
    }
  }

  Widget _buildHomeSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          Text(
            savedName.isEmpty ? 'Hoşgeldiniz' : 'Hoşgeldiniz, $savedName',
            style: DesignSystem.heading(size: 24),
          ),
          const SizedBox(height: 24),

          // Aktif ve Eski Hedefler Section — Vertical Grid
          if (goals.isNotEmpty) ...[
            Text(
              'Hedeflerim',
              style: DesignSystem.heading(size: 20),
            ),
            const SizedBox(height: 16),
            _buildGoalsTabbedSection(),
          ] else
             const Padding(
               padding: EdgeInsets.symmetric(vertical: 24),
               child: Center(child: Text('Henüz hiç hedefiniz yok. Tasarruf etmeye başlayın!', style: TextStyle(color: Colors.grey))),
             ),

          const SizedBox(height: 24),
          // Action Cards
          Text('Hızlı İşlemler', style: DesignSystem.subheading()),
          const SizedBox(height: 16),
          Row(
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
                  title: 'Hızlı Gider',
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
          ),

          const SizedBox(height: 32),

          // Calendar Section
          _buildActivityCalendar(),
          const SizedBox(height: 32),

          // Exchange Rates Section — Dynamic with selection
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Döviz Kurları', style: DesignSystem.subheading()),
              IconButton(
                onPressed: _showCurrencySelectionDialog,
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: DesignSystem.primaryIndigo.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.tune_rounded, color: DesignSystem.primaryIndigo, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildCurrencyGrid(),
          const SizedBox(height: 32),

          // Recent Transactions
          Text('Son İşlemler', style: DesignSystem.subheading()),
          const SizedBox(height: 16),
          if (activities.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Henüz işlem kaydı yok',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ),
            )
          else
            ...activities.take(5).map((activity) {
              final color = activity['type'] == 'gelir'
                  ? DesignSystem.secondaryGreen
                  : DesignSystem.accentCoral;
              final icon = activity['type'] == 'gelir'
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded;
              final sign = activity['type'] == 'gelir' ? '+' : '-';
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
      ),
    );
  }

  Widget _buildActivityCalendar() {
    DateTime now = DateTime.now();
    int daysInMonth = DateTime(selectedCalendarDate.year, selectedCalendarDate.month + 1, 0).day;
    int firstDayOfMonth = DateTime(selectedCalendarDate.year, selectedCalendarDate.month, 1).weekday;

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
                    icon: const Icon(Icons.chevron_left, color: DesignSystem.primaryIndigo),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: () => _changeCalendarMonth(1),
                    icon: const Icon(Icons.chevron_right, color: DesignSystem.primaryIndigo),
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
              bool isToday = day == now.day && 
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
                      ? Border.all(color: DesignSystem.warningOrange.withValues(alpha: 0.3), width: 1.5)
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DesignSystem.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [DesignSystem.premiumCard().boxShadow![0]],
        ),
        child: Column(
          children: [
            _buildIconContainer(icon, color),
            const SizedBox(height: 12),
            Text(
              title,
              style: DesignSystem.body().copyWith(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
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
    bool isRecurring = false;
    int? selectedGoalId;
    
    if (goals.isNotEmpty && _currentGoalIndex < goals.length) {
      final g = goals[_currentGoalIndex];
      if (g['is_completed'] != true && g['is_completed'] != 1) {
        selectedGoalId = g['id'];
      }
    }

    DesignSystem.showPremiumDialog(
      context: context,
      title: 'İşlem Ekle',
      content: StatefulBuilder(
        builder: (context, setDialogState) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'gelir', label: Text('Gelir'), icon: Icon(Icons.arrow_upward_rounded)),
                  ButtonSegment(value: 'gider', label: Text('Gider'), icon: Icon(Icons.arrow_downward_rounded)),
                ],
                selected: {selectedType},
                onSelectionChanged: (Set<String> newSelection) => setDialogState(() => selectedType = newSelection.first),
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: selectedType == 'gelir' ? DesignSystem.secondaryGreen.withOpacity(0.2) : DesignSystem.accentCoral.withOpacity(0.2),
                  selectedForegroundColor: selectedType == 'gelir' ? DesignSystem.secondaryGreen : DesignSystem.accentCoral,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Miktar (₺)',
                  prefixIcon: const Icon(Icons.monetization_on_outlined),
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
              DropdownButtonFormField<int>(
                value: selectedGoalId,
                items: [
                  const DropdownMenuItem(value: null, child: Text('Hedefsiz')),
                  ...goals.where((g) => g['is_completed'] != true).map((g) => DropdownMenuItem(value: g['id'], child: Text(g['title']))),
                ],
                onChanged: (val) => setDialogState(() => selectedGoalId = val),
                decoration: InputDecoration(
                  labelText: 'İlişkili Hedef',
                  prefixIcon: const Icon(Icons.track_changes),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setDialogState(() => selectedCategory = val!),
                decoration: InputDecoration(
                  labelText: 'Kategori',
                  prefixIcon: const Icon(Icons.category_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Düzenli İşlem', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                value: isRecurring,
                onChanged: (val) => setDialogState(() => isRecurring = val),
                activeColor: DesignSystem.primaryIndigo,
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
              Navigator.pop(context);
              try {
                await ApiService.addTransaction(
                  amount: amount,
                  description: descriptionController.text.isEmpty ? (selectedType == 'gelir' ? 'Gelir' : 'Gider') : descriptionController.text,
                  type: selectedType,
                  date: DateTime.now().toIso8601String().substring(0, 10),
                  goalId: selectedGoalId,
                  category: selectedCategory,
                  isRecurring: isRecurring,
                );
                await _loadData();
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: DesignSystem.primaryIndigo,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('Kaydet'),
        ),
      ],
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
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.65),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Hızlı Gider Ekle', style: DesignSystem.subheading(size: 18, color: DesignSystem.black)),
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: DesignSystem.warningOrange.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add, color: DesignSystem.warningOrange, size: 20),
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
                          Icon(Icons.flash_off_rounded, size: 48, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Text('Henüz kayıtlı gider yok.',
                            style: DesignSystem.body(color: DesignSystem.gray),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text('Sık kullandığınız giderleri ekleyerek tek dokunuşla harcama kaydedin.',
                            style: DesignSystem.body(color: DesignSystem.gray, size: 12),
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
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final exp = savedExpenses[i];
                          return Dismissible(
                            key: Key('saved_exp_${exp['id']}'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: DesignSystem.accentCoral.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.delete_outline, color: DesignSystem.accentCoral),
                            ),
                            onDismissed: (_) async {
                              try {
                                await ApiService.deleteSavedExpense(exp['id']);
                                final refreshed = await ApiService.getSavedExpenses();
                                setState(() => savedExpenses = List<Map<String, dynamic>>.from(refreshed));
                                setSheetState(() {});
                              } catch (e) {
                                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
                              }
                            },
                            child: ListTile(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              tileColor: DesignSystem.warningOrange.withOpacity(0.05),
                              leading: CircleAvatar(
                                backgroundColor: DesignSystem.warningOrange.withOpacity(0.15),
                                child: const Icon(Icons.receipt_long_rounded, color: DesignSystem.warningOrange, size: 20),
                              ),
                              title: Text(exp['label'] ?? '', style: DesignSystem.subheading(size: 14, color: DesignSystem.black)),
                              subtitle: Text('${exp['category'] ?? 'Genel'} • ₺${(exp['amount'] as num).toStringAsFixed(0)}',
                                style: DesignSystem.body(size: 12, color: DesignSystem.gray),
                              ),
                              trailing: const Icon(Icons.chevron_right, size: 18, color: DesignSystem.gray),
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

    DesignSystem.showPremiumDialog(
      context: context,
      title: 'Yeni Kayıtlı Gider',
      content: StatefulBuilder(
        builder: (context, setDialogState) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelController,
                decoration: InputDecoration(
                  labelText: 'Gider Adı (örn: Otobüs)',
                  prefixIcon: const Icon(Icons.label_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Varsayılan Miktar (₺)',
                  prefixIcon: const Icon(Icons.monetization_on_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setDialogState(() => selectedCategory = val!),
                decoration: InputDecoration(
                  labelText: 'Kategori',
                  prefixIcon: const Icon(Icons.category_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
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
            if (labelController.text.isNotEmpty && amount != null && amount > 0) {
              Navigator.pop(context);
              try {
                await ApiService.createSavedExpense(
                  label: labelController.text.trim(),
                  amount: amount,
                  category: selectedCategory,
                );
                final refreshed = await ApiService.getSavedExpenses();
                setState(() => savedExpenses = List<Map<String, dynamic>>.from(refreshed));
                parentSetState?.call(() {});
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: DesignSystem.warningOrange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Kaydet'),
        ),
      ],
    );
  }

  void _showApplySavedExpenseDialog(Map<String, dynamic> expense) {
    final amountController = TextEditingController(
      text: (expense['amount'] as num).toStringAsFixed(0),
    );

    DesignSystem.showPremiumDialog(
      context: context,
      title: expense['label'] ?? 'Gider Ekle',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kategori: ${expense['category'] ?? 'Genel'}',
            style: DesignSystem.body(color: DesignSystem.gray, size: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Miktar (₺)',
              prefixIcon: const Icon(Icons.monetization_on_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Miktarı değiştirebilir veya varsayılan değerle ekleyebilirsiniz.',
            style: DesignSystem.body(color: DesignSystem.gray, size: 11),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
        ElevatedButton(
          onPressed: () async {
            final amount = double.tryParse(amountController.text);
            if (amount != null && amount > 0) {
              Navigator.pop(context);
              try {
                final defaultAmount = (expense['amount'] as num).toDouble();
                await ApiService.applySavedExpense(
                  expense['id'],
                  overrideAmount: amount != defaultAmount ? amount : null,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${expense['label']} eklendi: ₺${amount.toStringAsFixed(0)}'),
                      backgroundColor: DesignSystem.warningOrange,
                    ),
                  );
                }
                await _loadData();
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: DesignSystem.warningOrange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('Gider Olarak Ekle'),
        ),
      ],
    );
  }

  void _showAddGoalDialog() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    String selectedColor = 'purple';
    String selectedCategory = 'Diğer';
    String selectedIcon = 'stars_rounded';

    DesignSystem.showPremiumDialog(
      context: context,
      title: 'Yeni Hedef Oluştur',
      content: StatefulBuilder(
        builder: (context, setDialogState) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Hedef Adı (örn: Laptop)',
                  prefixIcon: const Icon(Icons.edit_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Hedef Miktar (₺)',
                  prefixIcon: const Icon(Icons.flag_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setDialogState(() => selectedCategory = val!),
                decoration: InputDecoration(
                  labelText: 'Kategori',
                  prefixIcon: const Icon(Icons.category_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedIcon,
                items: _goalIconOptions.map((iconMap) => DropdownMenuItem(value: iconMap['key'] as String, child: Row(children: [Icon(iconMap['iconData'] as IconData, size: 20, color: DesignSystem.gray,), const SizedBox(width: 8), Text(iconMap['label'] as String)]))).toList(),
                onChanged: (val) => setDialogState(() => selectedIcon = val!),
                decoration: InputDecoration(
                  labelText: 'İkon',
                  prefixIcon: const Icon(Icons.star_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _colorMap.keys.map((colorName) {
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedColor = colorName),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _colorMap[colorName],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selectedColor == colorName ? Colors.black : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
        ElevatedButton(
          onPressed: () async {
            final amountValue = double.tryParse(amountController.text);
            if (nameController.text.isNotEmpty && amountValue != null) {
              Navigator.pop(context);
              try {
                await ApiService.createGoal({
                  'title': nameController.text.trim(),
                  'target_amount': amountValue,
                  'category': selectedCategory,
                  'color': selectedColor,
                });
                await _loadData();
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: DesignSystem.primaryIndigo,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Oluştur'),
        ),
      ],
    );
  }

  Widget _buildGoalsTabbedSection() {
    final activeGoals = goals.where((g) => g['is_completed'] != true && g['is_completed'] != 1).toList();
    final completedGoals = goals.where((g) => g['is_completed'] == true || g['is_completed'] == 1).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTabButton('Devam Eden (${activeGoals.length})', !_showCompletedGoals),
            const SizedBox(width: 16),
            _buildTabButton('Tamamlanan (${completedGoals.length})', _showCompletedGoals),
          ],
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
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
          border: Border.all(color: isSelected ? DesignSystem.primaryIndigo : DesignSystem.gray.withValues(alpha: 0.3)),
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

  Widget _buildOngoingGoalsGrid(List<Map<String, dynamic>> activeGoals) {
    if (activeGoals.isEmpty) {
       return const Padding(
         padding: EdgeInsets.symmetric(vertical: 24),
         child: Center(child: Text('Aktif hedefiniz bulunmamaktadır', style: TextStyle(color: Colors.grey))),
       );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
        if (activeGoals.length == 1) crossAxisCount = 1;

        return GridView.builder(
          key: const ValueKey('activeGrid'),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: activeGoals.length == 1 ? 2.5 : 1.1,
          ),
          itemCount: activeGoals.length,
          itemBuilder: (context, index) {
            return _buildNewGoalCard(activeGoals[index]);
          },
        );
      },
    );
  }

  Widget _buildCompletedGoalsGrid(List<Map<String, dynamic>> completedGoals) {
    if (completedGoals.isEmpty) {
       return Padding(
         key: const ValueKey('emptyCompleted'),
         padding: const EdgeInsets.symmetric(vertical: 40),
         child: Center(
           child: Column(
             children: [
               const Icon(Icons.emoji_events, size: 64, color: Colors.amber),
               const SizedBox(height: 16),
               Text('Başarı Odası Boş', style: DesignSystem.heading(color: Colors.amber, size: 20)),
               const SizedBox(height: 8),
               Text('İlk hedefinize ulaşmak için tasarruf etmeye devam edin!', style: DesignSystem.body(color: DesignSystem.gray), textAlign: TextAlign.center),
             ],
           ),
         ),
       );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
        if (completedGoals.length == 1) crossAxisCount = 1;

        return GridView.builder(
          key: const ValueKey('completedGrid'),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: completedGoals.length == 1 ? 2.5 : 1.1,
          ),
          itemCount: completedGoals.length,
          itemBuilder: (context, index) {
            return _buildNewGoalCard(completedGoals[index]);
          },
        );
      },
    );
  }

  Widget _buildNewGoalCard(Map<String, dynamic> goal) {
    bool isCompleted = goal['is_completed'] == true || goal['is_completed'] == 1;
    Color goalCol = isCompleted ? Colors.amber : (_colorMap[goal['color']] ?? Colors.purple);
    double amount = (goal['target_amount'] as num).toDouble();
    double savedAmount = (goal['saved_amount'] as num?)?.toDouble() ?? 0.0;
    
    // Safety check for completion bounds
    if (isCompleted) savedAmount = amount;
    
    double currentProgress = (savedAmount / amount).clamp(0.0, 1.0);
    IconData icon = _getIconData(goal['icon'] ?? 'stars_rounded');
    
    return GestureDetector(
      onTap: () => _showGoalModal(goal, goalCol, amount, savedAmount, currentProgress, isCompleted),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: isCompleted ? 
          BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.amber, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.2),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 5),
              ),
            ],
          ) : DesignSystem.premiumCard(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(isCompleted ? Icons.emoji_events : icon, color: isCompleted ? Colors.amber : goalCol, size: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: goalCol.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text(isCompleted ? '\u2705' : '${(currentProgress * 100).toStringAsFixed(0)}%', style: DesignSystem.body(color: goalCol, weight: FontWeight.w700, size: 12)),
                )
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: SizedBox(
                width: 60,
                height: 60,
                child: CustomPaint(
                  painter: _ProgressRingPainter(progress: currentProgress, color: goalCol),
                  child: Center(
                    child: Icon(icon, color: goalCol.withOpacity(0.5), size: 24),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(goal['title'], style: DesignSystem.subheading(size: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('₺${amount.toStringAsFixed(0)}', style: DesignSystem.heading(size: 16, color: goalCol)),
          ],
        ),
      ),
    );
  }

  void _showGoalModal(Map<String, dynamic> goal, Color goalCol, double amount, double savedSoFar, double currentProgress, bool isCompleted) {
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
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20)],
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
                              child: Text(goal['title'], style: DesignSystem.heading(size: 22), maxLines: 2),
                            ),
                            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                          ],
                        ),
                        if (isCompleted)
                           Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amber.withOpacity(0.3))),
                            child: Row(
                              children: [
                                const Icon(Icons.emoji_events, color: Colors.amber),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text('Hedef Tamamlandı! \u2705 ' + (goal['completed_at'] ?? ''), style: DesignSystem.subheading(color: Colors.amber, size: 14)),
                                ),
                              ]
                            ),
                          ),
                        const SizedBox(height: 24),
                        Center(
                          child: SizedBox(
                            width: 120,
                            height: 120,
                            child: CustomPaint(
                              painter: _ProgressRingPainter(progress: currentProgress, color: goalCol),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(_getIconData(goal['icon'] ?? 'stars_rounded'), color: goalCol, size: 32),
                                    const SizedBox(height: 4),
                                    Text('${(currentProgress * 100).toStringAsFixed(0)}%', style: DesignSystem.heading(size: 20, color: goalCol)),
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
                            _buildStatBox('Hedef', '₺${amount.toStringAsFixed(0)}', goalCol),
                            _buildStatBox('Biriktirilen', '₺${savedSoFar.toStringAsFixed(0)}', goalCol),
                            _buildStatBox('Kalan', '₺${max(0, amount - savedSoFar).toStringAsFixed(0)}', goalCol),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text('İlerleme Grafiği', style: DesignSystem.subheading(size: 16)),
                        const SizedBox(height: 16),
                        FutureBuilder<Map<String, dynamic>>(
                          future: ApiService.getGoalHistory(goal['id'] as int),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const SizedBox(height: 150, child: Center(child: CircularProgressIndicator()));
                            }
                            if (snapshot.hasError) {
                              return SizedBox(height: 150, child: Center(child: Text('Hata oluştu: ${snapshot.error}')));
                            }
                            
                            final history = snapshot.data ?? {};
                            if (history.isEmpty) {
                              return const SizedBox(height: 150, child: Center(child: Text('Henüz veri yok.')));
                            }
                            
                            return SizedBox(
                              height: 150,
                              child: LineChart(
                                LineChartData(
                                  gridData: const FlGridData(show: false),
                                  titlesData: const FlTitlesData(show: false),
                                  borderData: FlBorderData(show: false),
                                  minX: 0,
                                  maxX: max(1, history.length.toDouble() - 1),
                                  minY: 0,
                                  maxY: amount,
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: history.values.toList().asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value as num).toDouble())).toList(),
                                      isCurved: true,
                                      color: goalCol,
                                      barWidth: 3,
                                      isStrokeCapRound: true,
                                      dotData: const FlDotData(show: false),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        gradient: LinearGradient(colors: [goalCol.withOpacity(0.3), goalCol.withOpacity(0.0)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
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
                              icon: const Icon(Icons.shopping_cart_checkout, size: 18),
                              label: const Text('Satın Al / Tamamla'),
                              style: ElevatedButton.styleFrom(backgroundColor: DesignSystem.secondaryGreen, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            ),
                          ),
                        if (!isCompleted && savings.isNotEmpty && currentProgress < 1.0)
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () { Navigator.pop(context); _showUseSavingsDialog(goal); },
                              icon: Icon(Icons.account_balance_wallet_outlined, size: 16, color: goalCol),
                              label: Text('Varlıktan Kullan', style: TextStyle(color: goalCol, fontWeight: FontWeight.w600)),
                              style: OutlinedButton.styleFrom(side: BorderSide(color: goalCol.withOpacity(0.5)), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            ),
                          ),
                        if (!isCompleted)
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(onPressed: () { Navigator.pop(context); _showGoalCustomizeDialog(goal); }, child: Text('Düzenle', style: DesignSystem.body(color: DesignSystem.primaryIndigo)))),
                              Expanded(
                                child: TextButton(onPressed: () { Navigator.pop(context); _deleteGoalConfirm(goal); }, child: Text('Sil', style: DesignSystem.body(color: Colors.red)))),
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
                    colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
                  ),
              ],
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack).value,
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
            content: Text('${goal['title']} hedefini başarıyla satın aldınız!'),
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
          )
        );
      }
    }
  }

  void _showUseSavingsDialog(Map<String, dynamic> goal) {
    final goalCol = _colorMap[goal['color']] ?? Colors.purple;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Varlık Seç', style: DesignSystem.subheading(size: 18, color: DesignSystem.black)),
              ),
              if (savings.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Kullanılabilir varlık yok.', style: DesignSystem.body(color: DesignSystem.gray)),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: savings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final s = savings[i];
                      final currency = s['currency'] ?? 'TRY';
                      final amount = (s['amount'] as num).toDouble();
                      final desc = s['description'] ?? currency;
                      String symbol = currency == 'USD' ? '\$' : currency == 'EUR' ? '€' : currency == 'GOLD' ? 'gr' : '₺';
                      return ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        tileColor: goalCol.withOpacity(0.05),
                        leading: CircleAvatar(
                          backgroundColor: goalCol.withOpacity(0.15),
                          child: Icon(Icons.account_balance_wallet, color: goalCol, size: 20),
                        ),
                        title: Text(desc, style: DesignSystem.subheading(size: 14, color: DesignSystem.black)),
                        subtitle: Text('$symbol${amount.toStringAsFixed(2)}', style: DesignSystem.body(size: 12, color: DesignSystem.gray)),
                        trailing: Icon(Icons.arrow_forward_ios, size: 14, color: goalCol),
                        onTap: () async {
                          Navigator.pop(ctx);
                          try {
                            await ApiService.fundGoalFromSaving(goal['id'], s['id']);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('$desc hedefe uygulandı!'), backgroundColor: Colors.green),
                              );
                            }
                            await _loadData();
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
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
        content: Text('${goal['title']} hedefini silmek istediğinize emin misiniz? Bu işlem geri alınamaz.'),
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
        await ApiService.deleteGoal(goal['id']);
        await _loadData();
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hedef silindi')));
        }
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
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
              color: (isExpense ? DesignSystem.accentCoral : DesignSystem.secondaryGreen).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isExpense ? Icons.arrow_outward : Icons.arrow_downward,
              color: isExpense ? DesignSystem.accentCoral : DesignSystem.secondaryGreen,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: DesignSystem.subheading(size: 13, color: DesignSystem.black)),
                Text(
                  '$category • $date',
                  style: DesignSystem.body(size: 11, color: DesignSystem.gray),
                ),
              ],
            ),
          ),
          Text(
            '${isExpense ? '-' : '+'}₺${amount.toStringAsFixed(2)}',
            style: DesignSystem.subheading(
              size: 13,
              color: isExpense ? DesignSystem.accentCoral : DesignSystem.secondaryGreen,
            ),
          ),
        ],
      ),
    );
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
    final meta = _currencyRegistry.firstWhere((c) => c['key'] == key, orElse: () => _currencyRegistry.first);
    final isCryptoOrCommodity = meta['key'] == 'Gram Altın' || meta['key'] == 'Gümüş' || meta['key'] == 'BTC/TL' || meta['key'] == 'ETH/TL';
    
    double rate = liveMarketRates[key] ?? 0.0;
    String displayRate;
    if (isCryptoOrCommodity) {
      displayRate = '₺${rate > 1000 ? rate.toStringAsFixed(0) : rate.toStringAsFixed(2)}';
    } else {
      displayRate = rate.toStringAsFixed(2);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: DesignSystem.premiumCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(meta['label'], style: DesignSystem.subheading(size: 13, color: DesignSystem.gray), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: DesignSystem.secondaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: DesignSystem.secondaryGreen, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text('Canlı', style: DesignSystem.body(color: DesignSystem.secondaryGreen, weight: FontWeight.w700, size: 10)),
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
                decoration: BoxDecoration(color: meta['color'].withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(meta['iconData'], color: meta['color'], size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(displayRate, style: DesignSystem.heading(size: 18), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ],
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
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 24),
                  Text('Döviz Kurlarını Özelleştir', style: DesignSystem.heading(size: 22)),
                  const SizedBox(height: 8),
                  Text('Ana ekranda görmek istediğiniz kurları seçin. (En az 1, en fazla 6)', style: DesignSystem.body(size: 14)),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _currencyRegistry.length,
                      itemBuilder: (context, index) {
                        final meta = _currencyRegistry[index];
                        final isSelected = tempSelection.contains(meta['key']);
                        
                        return CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Row(
                            children: [
                              Icon(meta['iconData'], color: meta['color'], size: 20),
                              const SizedBox(width: 12),
                              Text(meta['label'], style: DesignSystem.subheading(size: 16)),
                            ],
                          ),
                          activeColor: DesignSystem.primaryIndigo,
                          value: isSelected,
                          onChanged: (bool? val) {
                            setModalState(() {
                              if (val == true) {
                                if (tempSelection.length < 6) {
                                  tempSelection.add(meta['key']);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('En fazla 6 kur seçebilirsiniz.')));
                                }
                              } else {
                                if (tempSelection.length > 1) {
                                  tempSelection.remove(meta['key']);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('En az 1 kur seçmelisiniz.')));
                                }
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedCurrencies = List.from(tempSelection);
                        });
                        _saveSelectedCurrencies();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: DesignSystem.primaryIndigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      child: const Text('Kaydet ve Uygula', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  void _showAllProgressHistory(Map<String, dynamic> goal, Map<String, double> history) {
    Color goalCol = _colorMap[goal['color']] ?? Colors.purple;
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
              Text(goal['title'], style: DesignSystem.subheading(color: goalCol)),
              const SizedBox(height: 20),
              ...history.entries.toList().asMap().entries.map((item) {
                int index = item.key;
                var entry = item.value;
                String month = entry.key;
                double currentValue = entry.value;
                double previousValue = index > 0 ? history.values.toList()[index - 1] : 0;
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
              }).toList().reversed,
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kapat')),
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
        initialName: goal['title'],
        initialAmount: (goal['target_amount'] as num).toDouble(),
        initialColor: _colorMap[goal['color']] ?? Colors.purple,
        initialIcon: goal['icon'] ?? 'stars_rounded',
        onSave: (newName, newAmount, newColor, newIcon) async {
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
  final Function(String, double, Color, String) onSave;

  const _GoalCustomizeDialog({
    required this.initialName,
    required this.initialAmount,
    required this.initialColor,
    required this.initialIcon,
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

  final List<Map<String, dynamic>> _goalIconOptions = [
    {'label': 'Genel', 'iconData': Icons.stars_rounded, 'key': 'stars_rounded'},
    {'label': 'Ev', 'iconData': Icons.home_rounded, 'key': 'home_rounded'},
    {'label': 'Araç', 'iconData': Icons.directions_car_rounded, 'key': 'directions_car_rounded'},
    {'label': 'Eğitim', 'iconData': Icons.school_rounded, 'key': 'school_rounded'},
    {'label': 'Tatil', 'iconData': Icons.flight_takeoff_rounded, 'key': 'flight_takeoff_rounded'},
    {'label': 'Teknoloji', 'iconData': Icons.computer_rounded, 'key': 'computer_rounded'},
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
  }

  @override
  void dispose() {
    nameController.dispose();
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hedef Adı (Max 25 karakter)', style: DesignSystem.body(size: 14, color: DesignSystem.gray, weight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: nameController,
          maxLength: 25,
          style: DesignSystem.body(color: DesignSystem.black, weight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: 'Hedef adı',
            prefixIcon: const Icon(Icons.edit, color: DesignSystem.primaryIndigo),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 16),
        Text('Hedef Tutarı (₺)', style: DesignSystem.body(size: 14, color: DesignSystem.gray, weight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          style: DesignSystem.body(color: DesignSystem.black, weight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: 'Tutar',
            prefixIcon: const Icon(Icons.money, color: DesignSystem.primaryIndigo),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 16),
        Text('İkon Seç', style: DesignSystem.body(size: 14, color: DesignSystem.gray, weight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedIcon,
          items: _goalIconOptions.map((iconMap) => DropdownMenuItem(value: iconMap['key'] as String, child: Row(children: [Icon(iconMap['iconData'] as IconData, size: 20, color: DesignSystem.gray), const SizedBox(width: 8), Text(iconMap['label'] as String)]))).toList(),
          onChanged: (val) => setState(() => selectedIcon = val!),
          decoration: InputDecoration(
            hintText: 'İkon',
            prefixIcon: const Icon(Icons.star_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 20),
        Text('Renk Seç', style: DesignSystem.body(size: 14, color: DesignSystem.gray, weight: FontWeight.w600)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
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
                  border: Border.all(color: isSelected ? DesignSystem.primaryIndigo : Colors.transparent, width: 3),
                  boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))] : null,
                ),
                child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
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
                final newGoal = double.tryParse(amountController.text);
                final newName = nameController.text.trim();
                if (newGoal != null && newGoal > 0 && newName.isNotEmpty) {
                  widget.onSave(newName, newGoal, selectedColor, selectedIcon);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignSystem.primaryIndigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ],
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
      ..shader = SweepGradient(colors: [color.withOpacity(0.4), color], startAngle: -pi/2, endAngle: 3*pi/2).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6;

    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawArc(rect, -pi / 2, 2 * pi * progress.clamp(0.0, 1.0), false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) => oldDelegate.progress != progress || oldDelegate.color != color;
}
