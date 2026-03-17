import 'package:flutter/material.dart';
import 'dart:async';
import 'terms.dart';
import 'wallet.dart';
import 'profile.dart';
import '../services/api_service.dart';
import '../services/market_service.dart';
import 'package:confetti/confetti.dart';

// --- DESIGN SYSTEM CONSTANTS (Mapped from wallet.dart) ---
class AppColors {
  static const Color teal = Color(0xFF17A2A2);
  static const Color darkTeal = Color(0xFF0D8B8F);
  static const Color lightTeal = Color(0xFF4ECDC1);
  static const Color softGreen = Color(0xFF2ECC71);
  static const Color darkGreen = Color(0xFF27AE60);
  static const Color coral = Color(0xFFFF6B6B);
  static const Color orange = Color(0xFFF39C12);
  static const Color purple = Color(0xFF9B59B6);
  static const Color background = Color(0xFFF5F5F5);
  static const Color white = Color(0xFFFFFFFF);
  static const Color darkGray = Color(0xFF666666);
  static const Color black = Color(0xFF1A1A1A);
  static const Color mediumGray = Color(0xFFCCCCCC);
}

class AppStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.black,
    height: 1.2,
    fontFamily: 'Inter',
  );
  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.black,
    height: 1.2,
  );
  static const TextStyle subheading = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.darkGray,
    height: 1.3,
  );
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.darkGray,
    height: 1.5,
  );
  static const BoxShadow cardShadow = BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.12),
    blurRadius: 12,
    offset: Offset(0, 4),
  );
  static const BoxShadow subtleShadow = BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.08),
    blurRadius: 4,
    offset: Offset(0, 2),
  );
  static final BorderRadius cardRadius = BorderRadius.circular(16);
  static final BorderRadius buttonRadius = BorderRadius.circular(12);
}

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

  // Goal tracking state
  List<Map<String, dynamic>> goals = [];
  Map<int, bool> _expandedGoals = {}; 

  // Market Rates Data
  Map<String, double> liveMarketRates = {
    'USD/TL': 34.52,
    'EUR/TL': 37.89,
    'Gram Altın': 2445.75,
    'BTC/TL': 1352450.0,
  };

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

  // Investment test variables
  String? investmentProfile;
  Timer? _marketTimer;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _nameController.text = savedName;
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
        setState(() {
          goals = List<Map<String, dynamic>>.from(goalsData);
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'GençCüzdan',
          style: TextStyle(color: AppColors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.black),
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
        selectedItemColor: Colors.blue.shade700,
        unselectedItemColor: Colors.grey.shade400,
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
            style: AppStyles.heading2,
          ),
          const SizedBox(height: 24),

          // Aktif ve Eski Hedefler Section
          if (goals.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hedeflerim (${goals.length})',
                  style: AppStyles.subheading,
                ),
                if (goals.length > 1)
                  Text(
                    'Kaydır →',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: _expandedGoals.values.contains(true) ? 600 : 150,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                scrollDirection: Axis.horizontal,
                itemCount: goals.length,
                itemBuilder: (context, index) {
                  final goal = goals[index];
                  bool isSmall = goals.length > 1;
                  return Container(
                    width: MediaQuery.of(context).size.width * (isSmall ? 0.85 : 0.92),
                    padding: const EdgeInsets.only(right: 12.0),
                    child: _buildGoalCard(goal),
                  );
                },
              ),
            ),
          ] else
             const Padding(
               padding: EdgeInsets.symmetric(vertical: 24),
               child: Center(child: Text('Aktif hedefiniz bulunmamaktadır', style: TextStyle(color: Colors.grey))),
             ),

          const SizedBox(height: 24),
          // Action Cards
          const Text('Hızlı İşlemler', style: AppStyles.subheading),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  title: 'Gelir/Gider Ekle',
                  icon: Icons.add_chart_rounded,
                  color: AppColors.teal,
                  onTap: _showAddTransactionDialog,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  title: 'Yeni Hedef',
                  icon: Icons.track_changes_rounded,
                  color: AppColors.purple,
                  onTap: _showAddGoalDialog,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Calendar Section
          _buildActivityCalendar(),
          const SizedBox(height: 32),

          // Exchange Rates Section
          const Text('Döviz Kurları', style: AppStyles.subheading),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildExchangeRateCard(
                  title: 'USD/TL',
                  rate: (liveMarketRates['USD/TL'] ?? 34.52).toStringAsFixed(2),
                  change: 'Canlı',
                  isPositive: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildExchangeRateCard(
                  title: 'EUR/TL',
                  rate: (liveMarketRates['EUR/TL'] ?? 37.89).toStringAsFixed(2),
                  change: 'Canlı',
                  isPositive: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildCommodityCard(
                  title: 'Gram Altın',
                  value: '₺${(liveMarketRates['Gram Altın'] ?? 2445.75).toStringAsFixed(2)}',
                  icon: Icons.monetization_on,
                  color: Colors.amber,
                  isPositive: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCommodityCard(
                  title: 'BTC/TL',
                  value: '₺${(liveMarketRates['BTC/TL'] ?? 1352450.0).toStringAsFixed(0)}',
                  icon: Icons.currency_bitcoin_rounded,
                  color: Colors.orange,
                  isPositive: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Recent Transactions
          const Text('Son İşlemler', style: AppStyles.subheading),
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
                  ? AppColors.softGreen
                  : AppColors.coral;
              final icon = activity['type'] == 'gelir'
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded;
              final sign = activity['type'] == 'gelir' ? '+' : '-';
              final parsedDate = DateTime.tryParse(activity['date'].toString());
              final formattedDate = parsedDate != null
                  ? '${parsedDate.day}/${parsedDate.month}/${parsedDate.year}'
                  : activity['date'].toString();

              return _buildTransactionItem(
                '${activity['description']} ($formattedDate)',
                '$sign₺${activity['amount'].toStringAsFixed(2)}',
                color,
                icon,
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
        color: AppColors.white,
        borderRadius: AppStyles.cardRadius,
        boxShadow: [AppStyles.subtleShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${monthNames[selectedCalendarDate.month - 1]} ${selectedCalendarDate.year}',
                style: AppStyles.subheading.copyWith(
                  color: AppColors.teal,
                  fontSize: 18,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _changeCalendarMonth(-1),
                    icon: const Icon(Icons.chevron_left, color: AppColors.teal),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: () => _changeCalendarMonth(1),
                    icon: const Icon(Icons.chevron_right, color: AppColors.teal),
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
                      ? AppColors.teal
                      : hasActivity
                      ? AppColors.orange.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isToday
                      ? Border.all(color: AppColors.teal, width: 2)
                      : hasActivity
                      ? Border.all(color: AppColors.orange.withValues(alpha: 0.3), width: 1.5)
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
                          ? AppColors.orange
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
                  color: AppColors.teal,
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
      borderRadius: AppStyles.cardRadius,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: AppStyles.cardRadius,
          boxShadow: [AppStyles.subtleShadow],
        ),
        child: Column(
          children: [
            _buildIconContainer(icon, color),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppStyles.body.copyWith(
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
    String selectedType = 'gelir'; // default
    String selectedCategory = 'Diğer';
    bool isRecurring = false;
    int? selectedGoalId;
    
    if (goals.isNotEmpty && _currentGoalIndex < goals.length) {
      final g = goals[_currentGoalIndex];
      if (g['is_completed'] != true && g['is_completed'] != 1) {
        selectedGoalId = g['id'];
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('İşlem Ekle', style: AppStyles.subheading),
            shape: RoundedRectangleBorder(borderRadius: AppStyles.cardRadius),
            backgroundColor: AppColors.white,
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'gelir',
                        label: Text('Gelir'),
                        icon: Icon(Icons.arrow_upward_rounded),
                      ),
                      ButtonSegment(
                        value: 'gider',
                        label: Text('Gider'),
                        icon: Icon(Icons.arrow_downward_rounded),
                      ),
                    ],
                    selected: {selectedType},
                    onSelectionChanged: (Set<String> newSelection) {
                      setDialogState(() {
                        selectedType = newSelection.first;
                      });
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith<Color>((
                        states,
                      ) {
                        if (states.contains(WidgetState.selected)) {
                          return selectedType == 'gelir'
                              ? AppColors.softGreen.withValues(alpha: 0.2)
                              : AppColors.coral.withValues(alpha: 0.2);
                        }
                        return Colors.transparent;
                      }),
                      foregroundColor: WidgetStateProperty.resolveWith<Color>((
                        states,
                      ) {
                        if (states.contains(WidgetState.selected)) {
                          return selectedType == 'gelir'
                              ? AppColors.darkGreen
                              : AppColors.coral;
                        }
                        return AppColors.darkGray;
                      }),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Miktar (₺)',
                      prefixIcon: const Icon(Icons.money),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      hintText: 'Açıklama (opsiyonel)',
                      prefixIcon: const Icon(Icons.description),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    isExpanded: true,
                    value: selectedGoalId,
                    hint: const Text('İlişkili Hedef (opsiyonel)'),
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text('Yok'),
                      ),
                      ...goals.where((g) => g['is_completed'] != true && g['is_completed'] != 1).map((goal) {
                        return DropdownMenuItem<int>(
                          value: goal['id'],
                          child: Text(goal['title']),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedGoalId = value;
                      });
                    },
                    decoration: InputDecoration(
                       prefixIcon: const Icon(Icons.track_changes),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: selectedCategory,
                    items: _categories.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat,
                        child: Text(cat),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedCategory = value ?? 'Diğer';
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Kategori',
                      prefixIcon: const Icon(Icons.category),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Aylık Düzenli (Abonelik vb.)', style: TextStyle(fontSize: 14)),
                    secondary: const Icon(Icons.repeat),
                    value: isRecurring,
                    onChanged: (bool value) {
                      setDialogState(() {
                        isRecurring = value;
                        if (value) selectedCategory = 'Abonelik';
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'İptal',
                  style: TextStyle(color: AppColors.darkGray),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(amountController.text);
                  if (amount != null && amount > 0) {
                    Navigator.pop(context);
                    try {
                      await ApiService.addTransaction(
                        amount: amount,
                        description: descriptionController.text.isEmpty
                            ? (selectedType == 'gelir' ? 'Gelir' : 'Gider')
                            : descriptionController.text,
                        type: selectedType,
                        date: DateTime.now().toIso8601String().substring(0, 10),
                        goalId: selectedGoalId,
                        category: selectedCategory,
                        isRecurring: isRecurring,
                      );
                      await _loadData(); // reload from server
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '₺${amount.toStringAsFixed(0)} ${selectedType == 'gelir' ? 'gelir' : 'gider'} eklendi',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Hata: $e'),
                            backgroundColor: AppColors.coral,
                          ),
                        );
                      }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppStyles.buttonRadius,
                  ),
                ),
                child: const Text('Ekle'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddGoalDialog() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    String selectedColor = 'purple';
    String selectedCategory = 'Diğer';

    showDialog(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Yeni Hedef Oluştur', style: AppStyles.subheading),
            shape: RoundedRectangleBorder(borderRadius: AppStyles.cardRadius),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Hedef Adı (örn: Tablet)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Hedef Miktar (₺)'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: selectedCategory,
                    items: _categories.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat,
                        child: Text(cat),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedCategory = value ?? 'Diğer';
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Kategori',
                      prefixIcon: const Icon(Icons.category),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Renk Seçimi', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: _colorMap.keys.map((colorName) {
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            selectedColor = colorName;
                          });
                        },
                        child: Container(
                          width: 30,
                          height: 30,
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
                       if (mounted) {
                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
                       }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal, foregroundColor: Colors.white),
                child: const Text('Ekle'),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildGoalCard(Map<String, dynamic> goal) {
    bool isCompleted = goal['is_completed'] == true || goal['is_completed'] == 1;
    bool showDetails = _expandedGoals[goal['id']] ?? false;
    Color goalCol = _colorMap[goal['color']] ?? Colors.purple;
    double amount = (goal['target_amount'] as num).toDouble();
    double currentProgress = _calculateCurrentProgressForGoal(goal['id'], amount);
    Map<String, double> progressHistory = _getMonthlyProgressForGoal(goal['id'], amount);
    double savedSoFar = progressHistory.values.isNotEmpty ? progressHistory.values.last : 0.0;
    
    final List<String> monthNames = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
    ];
    String targetMonthKey = '${monthNames[selectedCalendarDate.month - 1]} ${selectedCalendarDate.year}';

    return SingleChildScrollView(
      physics: showDetails ? const ClampingScrollPhysics() : const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _expandedGoals[goal['id']] = !showDetails;
              });
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    goalCol.withValues(alpha: isCompleted ? 0.4 : 0.8),
                    goalCol.withValues(alpha: isCompleted ? 0.6 : 1.0),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: goalCol.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  goal['title'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (isCompleted) ...[
                                  const SizedBox(width: 8),
                                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                                ]
                              ]
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₺${amount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Icon(
                            showDetails
                                ? Icons.expand_less
                                : Icons.expand_more,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 28,
                            child: TextButton(
                              onPressed: () => _showGoalCustomizeDialog(goal),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.white.withValues(alpha: 0.2),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'Düzenle',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (showDetails) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: goalCol.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: goalCol.withValues(alpha: 0.3), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       Text(
                        'İlerleme',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: goalCol,
                        ),
                      ),
                      Text(
                        '${(currentProgress * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: goalCol,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _deleteGoalConfirm(goal),
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: 'Hedefi Sil',
                      ),
                    ]
                   ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: currentProgress,
                      minHeight: 12,
                      backgroundColor: goalCol.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(goalCol),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Purchase Button Logic
                  if (!isCompleted && currentProgress >= 1.0)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _purchaseGoalAction(goal),
                        icon: const Icon(Icons.shopping_cart_checkout),
                        label: const Text('Satın Al / Hedefi Tamamla'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  if (isCompleted)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green)
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                           Icon(Icons.check_circle, color: Colors.green),
                           SizedBox(width: 8),
                           Text('Bu hedef tamamlandı/satın alındı!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  Text(
                    'Şimdiye kadar ₺${savedSoFar.toStringAsFixed(0)} biriktirdiniz.',
                    style: TextStyle(color: goalCol.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Aylık İlerleme',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: goalCol,
                    ),
                  ),
                  ...progressHistory.entries.toList().reversed.take(5).toList().reversed.toList().asMap().entries.map((
                    entry,
                  ) {
                    int index = entry.key;
                    // Find correct index in original history for previousValue calculation
                    int originalIndex = progressHistory.length - progressHistory.entries.toList().reversed.take(5).length + index;
                    
                    String month = entry.value.key;
                    double currentValue = entry.value.value;

                    // Calculate monthly addition
                    double previousValue = originalIndex > 0
                        ? progressHistory.values.toList()[originalIndex - 1]
                        : 0;
                    double monthlyAddition = currentValue - previousValue;

                    double percentage = (currentValue / amount) * 100;
                    double monthlyPercentage =
                        (monthlyAddition / amount) * 100;
                    bool isPositive = monthlyAddition > 0;

                    return _buildGoalProgressItem(
                      month,
                      monthlyAddition,
                      currentValue,
                      monthlyPercentage,
                      percentage,
                      isPositive,
                      goalCol,
                      amount,
                    );
                  }),
                  if (progressHistory.length > 5) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: () => _showAllProgressHistory(goal, progressHistory),
                        child: Text(
                          'Tümünü Gör (${progressHistory.length})',
                          style: TextStyle(color: goalCol, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ]
      )
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

  Future<void> _deleteGoalConfirm(Map<String, dynamic> goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hedefi Sil?'),
        content: Text('${goal['title']} hedefini silmek istediğinize emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
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
    String amount,
    Color color, [
    IconData? icon,
  ]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                if (icon != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Icon(icon, color: color, size: 18),
                  ),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amount,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExchangeRateCard({
    required String title,
    required String rate,
    required String change,
    required bool isPositive,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppStyles.cardRadius,
        boxShadow: [AppStyles.subtleShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppStyles.body.copyWith(fontWeight: FontWeight.bold)),
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                size: 16,
                color: isPositive ? AppColors.softGreen : AppColors.coral,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(rate, style: AppStyles.heading2.copyWith(fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            change,
            style: TextStyle(
              fontSize: 12,
              color: isPositive ? AppColors.softGreen : AppColors.coral,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommodityCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isPositive,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppStyles.cardRadius,
        boxShadow: [AppStyles.subtleShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildIconContainer(icon, color),
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                size: 16,
                color: isPositive ? AppColors.softGreen : AppColors.coral,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: AppStyles.body.copyWith(fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: AppStyles.heading2.copyWith(fontSize: 16)),
        ],
      ),
    );
  }

  void _showAllProgressHistory(Map<String, dynamic> goal, Map<String, double> history) {
    Color goalCol = _colorMap[goal['color']] ?? Colors.purple;
    double amount = (goal['target_amount'] as num).toDouble();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${goal['title']} - Tüm Geçmiş', style: TextStyle(color: goalCol, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: history.entries.toList().asMap().entries.map((item) {
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
                bool isPositive = monthlyAddition > 0;

                return _buildGoalProgressItem(
                  month,
                  monthlyAddition,
                  currentValue,
                  monthlyPercentage,
                  percentage,
                  isPositive,
                  goalCol,
                  amount,
                );
              }).toList().reversed.toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
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
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
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
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: goalColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Stacked progress bar: Purple for cumulative, Green/Red for monthly addition
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
                      // Background
                      Container(
                        width: double.infinity,
                        color: Colors.grey.shade300,
                      ),
                      // Previous cumulative progress (Goal Color)
                      Positioned(
                        left: 0,
                        top: 0,
                        width: previousPercentage * constraints.maxWidth,
                        height: 8,
                        child: Container(
                          color: goalColor.withValues(alpha: 0.5),
                        ),
                      ),
                      // Monthly addition (Goal Color)
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
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showGoalCustomizeDialog(Map<String, dynamic> goal) {
    showDialog(
      context: context,
      builder: (BuildContext context) => _GoalCustomizeDialog(
        initialName: goal['title'],
        initialAmount: (goal['target_amount'] as num).toDouble(),
        initialColor: _colorMap[goal['color']] ?? Colors.purple,
        onSave: (newName, newAmount, newColor) async {
          // Find color string name
          String colorString = 'purple';
          _colorMap.forEach((key, value) {
            if (value.value == newColor.value) colorString = key;
          });

          try {
            await ApiService.updateGoal(goal['id'], {
              'title': newName,
              'target_amount': newAmount,
              'color': colorString,
            });
            await _loadData();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '$newName - ₺${newAmount.toStringAsFixed(0)} olarak güncellendi!',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
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
          final navigatorContext = context; // Store context before async
          try {
            await ApiService.saveInvestmentProfile(profile);
            setState(() {
              investmentProfile = profile;
            });
          } catch (e) {
            // Handle error - still update locally for now
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
  final Function(String, double, Color) onSave;

  const _GoalCustomizeDialog({
    required this.initialName,
    required this.initialAmount,
    required this.initialColor,
    required this.onSave,
  });

  @override
  State<_GoalCustomizeDialog> createState() => _GoalCustomizeDialogState();
}

class _GoalCustomizeDialogState extends State<_GoalCustomizeDialog> {
  late TextEditingController nameController;
  late TextEditingController amountController;
  late Color selectedColor;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.initialName);
    amountController = TextEditingController(
      text: widget.initialAmount.toStringAsFixed(0),
    );
    selectedColor = widget.initialColor;
  }

  @override
  void dispose() {
    nameController.dispose();
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Hedefi Özelleştir'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hedef Adı (Max 25 karakter)'),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              maxLength: 25,
              decoration: InputDecoration(
                hintText: 'Hedef adı',
                prefixIcon: const Icon(Icons.edit),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Hedef Tutarı (₺)'),
            const SizedBox(height: 8),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Tutar',
                prefixIcon: const Icon(Icons.money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Renk Seç'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children:
                  [
                    Colors.purple,
                    Colors.blue,
                    Colors.orange,
                    Colors.pink,
                    Colors.teal,
                    Colors.indigo,
                  ].map((color) {
                    bool isSelected = selectedColor == color;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedColor = color;
                        });
                      },
                      child: Container(
                        width: 35,
                        height: 35,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Colors.black
                                : Colors.transparent,
                            width: 2.5,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ] : null,
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: () {
            final newGoal = double.tryParse(amountController.text);
            final newName = nameController.text.trim();

            if (newGoal != null && newGoal > 0 && newName.isNotEmpty) {
              widget.onSave(newName, newGoal, selectedColor);
              Navigator.pop(context);
            }
          },
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}
