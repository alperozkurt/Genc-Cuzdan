import 'package:flutter/material.dart';
import 'terms.dart';
import 'wallet.dart';
import 'profile.dart';
import '../services/api_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String savedName = '';
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

  // Goal tracking variables
  double goalAmount = 10000;
  String goalName = '🎯 Hedef';
  Color goalColor = Colors.purple;
  DateTime selectedCalendarDate = DateTime.now();
  final Map<String, double> monthlyGoalProgress = {
    'Ocak': 500,
    'Şubat': 950,
    'Mart': 1350,
    'Nisan': 1200,
    'Mayıs': 2150,
    'Haziran': 2625,
  };

  // Investment test variables
  String? investmentProfile;

  @override
  void initState() {
    super.initState();
    _nameController.text = savedName;
    _loadData();
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

      // Load transactions
      final transactionsData = await ApiService.getTransactions();
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

      // Load user profile
      final userData = await ApiService.getUserProfile();
      setState(() {
        savedName = userData['name'] ?? '';
        _nameController.text = savedName;
      });
    } catch (e) {
      // Handle error - for now, keep default values
      print('Error loading data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('GençCüzdan')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
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
          monthlyIncome: monthlyIncome,
          monthlyExpense: monthlyExpense,
          monthlySavings: monthlySavings,
          investmentProfile: investmentProfile,
          onStartInvestmentTest: (_) {
            _startInvestmentTest();
          },
          onRetakeInvestmentTest: _startInvestmentTest,
        );
      case 2:
        return const TermsPage();
      case 3:
        return ProfilePage(
          savedName: savedName,
          nameController: _nameController,
          onNameSaved: (name) async {
            try {
              await ApiService.updateUserProfile({'name': name});
              setState(() {
                savedName = name;
              });
            } catch (e) {
              // Handle error - still update locally for now
              print('Error saving user profile: $e');
              setState(() {
                savedName = name;
              });
            }
          },
          onLogout: () {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/login', (route) => false);
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
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Mali Hedef Section - Clickable
          GestureDetector(
            onTap: () {
              setState(() {
                _showGoalDetails = !_showGoalDetails;
              });
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    goalColor.withValues(alpha: 0.8),
                    goalColor.withValues(alpha: 1.0),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: goalColor.withValues(alpha: 0.3),
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
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goalName,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _showGoalCustomizeDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: goalColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                            ),
                            child: const Text(
                              'Özelleştir',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        _showGoalDetails
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: Colors.white,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '₺${goalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _calculateCurrentProgress(),
                      minHeight: 10,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(_calculateCurrentProgress() * 100).toStringAsFixed(1)}% tamamlandı (₺${monthlyGoalProgress.values.last.toStringAsFixed(0)})',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          if (_showGoalDetails) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: goalColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: goalColor, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aylık İlerleme',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: goalColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...monthlyGoalProgress.entries.toList().asMap().entries.map((
                    entry,
                  ) {
                    int index = entry.key;
                    String month = entry.value.key;
                    double currentValue = entry.value.value;

                    // Calculate monthly addition
                    double previousValue = index > 0
                        ? monthlyGoalProgress.values.toList()[index - 1]
                        : 0;
                    double monthlyAddition = currentValue - previousValue;

                    double percentage = (currentValue / goalAmount) * 100;
                    double monthlyPercentage =
                        (monthlyAddition / goalAmount) * 100;
                    bool isPositive = monthlyAddition > 0;

                    return _buildGoalProgressItem(
                      month,
                      monthlyAddition,
                      currentValue,
                      monthlyPercentage,
                      percentage,
                      isPositive,
                    );
                  }),
                ],
              ),
            ),
          ],

          // Financial Summary Cardsr
          const SizedBox(height: 12),
          _buildFinancialSummaryCard(
            title: 'Tasarruf',
            amount: monthlySavings,
            icon: Icons.savings,
            color: Colors.orange,
            buttonLabel: null,
            showActionButtons: true,
            onIncomePressed: _showAddIncomeDialog,
            onExpensePressed: _showAddExpenseDialog,
          ),
          const SizedBox(height: 12),

          // Calendar Section
          _buildActivityCalendar(),
          const SizedBox(height: 24),

          // Exchange Rates Section
          const Text(
            'Döviz Kurları',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildExchangeRateCard(
                  title: 'USD/TL',
                  rate: '34.52',
                  change: '+0.25%',
                  isPositive: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildExchangeRateCard(
                  title: 'EUR/TL',
                  rate: '37.89',
                  change: '-0.15%',
                  isPositive: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildCommodityCard(
                  title: 'Gram Altın',
                  value: '₺2,445.75',
                  icon: Icons.trending_up,
                  color: Colors.amber,
                  isPositive: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCommodityCard(
                  title: 'BTC/TL',
                  value: '₺1,352,450',
                  icon: Icons.trending_up,
                  color: Colors.orange,
                  isPositive: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Recent Transactions
          const Text(
            'Son İşlemler',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
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
                  ? Colors.green
                  : Colors.red;
              final icon = activity['type'] == 'gelir'
                  ? Icons.trending_up
                  : Icons.trending_down;
              final sign = activity['type'] == 'gelir' ? '+' : '-';
              final formattedDate =
                  '${activity['date'].day}/${activity['date'].month}/${activity['date'].year}';

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
    DateTime today = DateTime.now();
    int daysInMonth = DateTime(today.year, today.month + 1, 0).day;
    int firstDayOfMonth = DateTime(today.year, today.month, 1).weekday;

    // Get dates with activities
    Set<int> activeDates = {};
    for (var activity in activities) {
      if (activity['date'].month == today.month &&
          activity['date'].year == today.year) {
        activeDates.add(activity['date'].day);
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
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${monthNames[today.month - 1]} ${today.year}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
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
              bool isToday = day == today.day;
              bool hasActivity = activeDates.contains(day);

              return Container(
                decoration: BoxDecoration(
                  color: isToday
                      ? Colors.blue
                      : hasActivity
                      ? Colors.orange.withValues(alpha: 0.3)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isToday
                      ? Border.all(color: Colors.blue, width: 2)
                      : hasActivity
                      ? Border.all(color: Colors.orange, width: 1.5)
                      : null,
                ),
                child: Center(
                  child: Text(
                    day.toString(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isToday
                          ? Colors.white
                          : hasActivity
                          ? Colors.orange.shade700
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
                  color: Colors.blue,
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

  Widget _buildFinancialSummaryCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    String? buttonLabel,
    bool showActionButtons = false,
    VoidCallback? onIncomePressed,
    VoidCallback? onExpensePressed,
  }) {
    bool isTasarruf = title == 'Tasarruf';

    return GestureDetector(
      onTap: () {
        if (title == 'Gelir') {
          _showAddIncomeDialog();
        } else if (title == 'Gider') {
          _showAddExpenseDialog();
        } else if (title == 'Tasarruf') {
          _showSavingsDetailsDialog();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.15),
              color.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: isTasarruf ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (isTasarruf)
              // Tasarruf Card: Expanded Layout
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '₺${amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: 36),
                      ),
                    ],
                  ),
                  if (showActionButtons) ...[
                    const SizedBox(height: 20),
                    // Income and Expense Buttons Row
                    Row(
                      children: [
                        // Gelir Ekle Button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: onIncomePressed,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: const Text(
                              'Gelir',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Gider Ekle Button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: onExpensePressed,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: const Text(
                              'Gider',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              )
            else
              // Default Card: Compact Layout
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '₺${amount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            // Button if available
            if (buttonLabel != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 32,
                child: ElevatedButton(
                  onPressed: () {
                    if (title == 'Gelir') {
                      _showAddIncomeDialog();
                    } else if (title == 'Gider') {
                      _showAddExpenseDialog();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(
                    buttonLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddIncomeDialog() {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Gelir Ekle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0) {
                setState(() {
                  monthlyIncome += amount;
                  monthlySavings += amount;
                  activities.insert(0, {
                    'date': DateTime.now(),
                    'type': 'gelir',
                    'amount': amount,
                    'description': descriptionController.text.isEmpty
                        ? 'Gelir'
                        : descriptionController.text,
                  });
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '₺${amount.toStringAsFixed(0)} gelir eklendi',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseDialog() {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Gider Ekle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0) {
                setState(() {
                  monthlyExpense += amount;
                  monthlySavings -= amount;
                  activities.insert(0, {
                    'date': DateTime.now(),
                    'type': 'gider',
                    'amount': amount,
                    'description': descriptionController.text.isEmpty
                        ? 'Gider'
                        : descriptionController.text,
                  });
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '₺${amount.toStringAsFixed(0)} gider eklendi',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  void _showSavingsDetailsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Tasarruf Detayları'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Toplam Tasarruf: ₺${monthlySavings.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Aylık Ayrıntı',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              ...monthlyGoalProgress.entries.map((entry) {
                int index = monthlyGoalProgress.keys.toList().indexOf(
                  entry.key,
                );
                double previousValue = index > 0
                    ? monthlyGoalProgress.values.toList()[index - 1]
                    : 0;
                double monthlyAddition = entry.value - previousValue;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key),
                      Text(
                        '+ ₺${monthlyAddition.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
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
        color: isPositive
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPositive ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            rate,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                color: isPositive ? Colors.green : Colors.red,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                change,
                style: TextStyle(
                  fontSize: 12,
                  color: isPositive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Icon(icon, color: color, size: 20),
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

  double _calculateCurrentProgress() {
    if (monthlyGoalProgress.isEmpty) return 0;
    double currentValue = monthlyGoalProgress.values.last;
    return (currentValue / goalAmount).clamp(0.0, 1.0);
  }

  void _showGoalCustomizeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => _GoalCustomizeDialog(
        initialName: goalName,
        initialAmount: goalAmount,
        initialColor: goalColor,
        onSave: (newName, newAmount, newColor) {
          setState(() {
            goalName = newName;
            goalAmount = newAmount;
            goalColor = newColor;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$newName - ₺${newAmount.toStringAsFixed(0)} olarak güncellendi!',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
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
            Wrap(
              spacing: 8,
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
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? Colors.black
                                : Colors.transparent,
                            width: 3,
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
