import 'package:flutter/material.dart';

// --- DESIGN SYSTEM CONSTANTS (Mapped from financial_design_system.json) ---

class AppColors {
  // Primary
  static const Color teal = Color(0xFF17A2A2);
  static const Color darkTeal = Color(0xFF0D8B8F);
  static const Color lightTeal = Color(0xFF4ECDC1);

  // Secondary
  static const Color softGreen = Color(0xFF2ECC71);
  static const Color darkGreen = Color(0xFF27AE60);

  // Accent
  static const Color coral = Color(0xFFFF6B6B);
  static const Color orange = Color(0xFFF39C12);
  static const Color purple = Color(0xFF9B59B6);

  // Neutral
  static const Color background = Color(
    0xFFF5F5F5,
  ); // Using lightGray for better contrast
  static const Color white = Color(0xFFFFFFFF);
  static const Color darkGray = Color(0xFF666666);
  static const Color black = Color(0xFF1A1A1A);
  static const Color mediumGray = Color(0xFFCCCCCC);
}

class AppStyles {
  // Typography
  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.black,
    height: 1.2,
    fontFamily: 'Inter', // Assumed font family
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

  // Shadows
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

  // Radii
  static final BorderRadius cardRadius = BorderRadius.circular(16);
  static final BorderRadius buttonRadius = BorderRadius.circular(12);
}

// --- MAIN WIDGET ---

class WalletPage extends StatefulWidget {
  final double monthlyIncome;
  final double monthlyExpense;
  final double monthlySavings;
  final String? investmentProfile;
  final Function(String) onStartInvestmentTest;
  final Function() onRetakeInvestmentTest;

  const WalletPage({
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.monthlySavings,
    required this.investmentProfile,
    required this.onStartInvestmentTest,
    required this.onRetakeInvestmentTest,
    super.key,
  });

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  @override
  Widget build(BuildContext context) {
    // Logic: Calculate Total Balance (Savings represents the net balance)
    final double totalBalance = widget.monthlySavings;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER SECTION: Avatar + Greeting + Balance (Component Pattern)
              _buildHeaderSection(totalBalance),

              const SizedBox(height: 24),

              // STATS AREA (Refactored to Card Grid)
              const Text('Finansal Özet', style: AppStyles.subheading),
              const SizedBox(height: 16),
              _buildStatsGrid(),

              const SizedBox(height: 32),

              // INVESTMENT SECTION
              const Text('Yatırım Stratejisi', style: AppStyles.subheading),
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
    );
  }

  Widget _buildHeaderSection(double balance) {
    return Column(
      children: [
        // Top Row: Avatar and Greeting
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.mediumGray.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: AppColors.darkGray),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Hoşgeldiniz,',
                      style: TextStyle(fontSize: 14, color: AppColors.darkGray),
                    ),
                    Text(
                      'Kullanıcı',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.notifications_outlined,
                color: AppColors.darkGray,
                size: 28,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Balance Card: Gradient Style (Green to Teal)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.softGreen, AppColors.teal],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: AppStyles.cardRadius,
            boxShadow: [AppStyles.cardShadow],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Toplam Varlıklar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '+2.4%',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '₺${balance.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      children: [
        // Income & Expense Row
        Row(
          children: [
            Expanded(
              child: _buildTransactionCard(
                title: 'Gelir',
                amount: widget.monthlyIncome,
                icon: Icons.arrow_upward_rounded,
                iconColor: AppColors.softGreen,
                bgColor: AppColors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTransactionCard(
                title: 'Gider',
                amount: widget.monthlyExpense,
                icon: Icons.arrow_downward_rounded,
                iconColor: AppColors.coral, // Using Coral for negative/expense
                bgColor: AppColors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Savings Row (Full width)
        _buildTransactionCard(
          title: 'Tasarruf (Aylık)',
          amount: widget.monthlySavings,
          icon: Icons.savings_outlined,
          iconColor: AppColors.orange,
          bgColor: AppColors.white,
          isHorizontal: true,
        ),
      ],
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
        borderRadius: AppStyles.cardRadius,
        boxShadow: [AppStyles.subtleShadow],
      ),
      child: isHorizontal
          ? Row(
              children: [
                _buildIconContainer(icon, iconColor),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppStyles.body.copyWith(fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      '₺${amount.toStringAsFixed(2)}',
                      style: AppStyles.heading2.copyWith(fontSize: 20),
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
                Text(title, style: AppStyles.body.copyWith(fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  '₺${amount.toStringAsFixed(0)}',
                  style: AppStyles.heading2.copyWith(fontSize: 18),
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
        color: AppColors.white,
        borderRadius: AppStyles.cardRadius,
        boxShadow: [AppStyles.cardShadow],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.quiz_outlined,
              color: AppColors.teal,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Yatırım Profilinizi Belirleyin',
            style: AppStyles.subheading,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Risk toleransınızı ölçmek ve size özel portföy önerileri almak için testi tamamlayın.',
            textAlign: TextAlign.center,
            style: AppStyles.body,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onStartInvestmentTest(''),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: AppStyles.buttonRadius,
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
      profileColor = AppColors.teal; // Conservative matches Primary
      profileName = 'Korumacı';
      description = 'Düşük risk, sabit getiri odaklı strateji.';
    } else if (profile == 'dengeli') {
      profileColor = AppColors.orange; // Balanced
      profileName = 'Dengeli';
      description = 'Orta risk ve büyüme dengesi.';
    } else {
      profileColor = AppColors.coral; // Aggressive
      profileName = 'Agresif';
      description = 'Yüksek büyüme potansiyeli için yüksek risk.';
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: AppStyles.cardRadius,
            boxShadow: [AppStyles.cardShadow],
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
                    Text(description, style: AppStyles.body),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 10),
                    const Text(
                      'Önerilen Dağılım',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkGray,
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
          style: TextButton.styleFrom(foregroundColor: AppColors.darkGray),
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
              Icon(item['icon'], size: 16, color: AppColors.darkGray),
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
                        backgroundColor: AppColors.background,
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
      shape: RoundedRectangleBorder(borderRadius: AppStyles.cardRadius),
      backgroundColor: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Yatırım Testi', style: AppStyles.subheading),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${currentQuestion + 1}/${questions.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.teal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: (currentQuestion + 1) / questions.length,
              backgroundColor: AppColors.background,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.teal),
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
                      color: AppColors.background,
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
                            color: AppColors.black,
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: AppColors.mediumGray,
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
