import 'package:flutter/material.dart';

class GoalPage extends StatefulWidget {
  final double initialGoalAmount;
  final String initialGoalName;
  final Color initialGoalColor;
  final Map<String, double> monthlyGoalProgress;
  final Function(String, double, Color) onGoalUpdated;

  const GoalPage({
    required this.initialGoalAmount,
    required this.initialGoalName,
    required this.initialGoalColor,
    required this.monthlyGoalProgress,
    required this.onGoalUpdated,
    super.key,
  });

  @override
  State<GoalPage> createState() => _GoalPageState();
}

class _GoalPageState extends State<GoalPage> {
  late double goalAmount;
  late String goalName;
  late Color goalColor;
  bool _showGoalDetails = false;

  @override
  void initState() {
    super.initState();
    goalAmount = widget.initialGoalAmount;
    goalName = widget.initialGoalName;
    goalColor = widget.initialGoalColor;
  }

  double _calculateCurrentProgress() {
    if (widget.monthlyGoalProgress.isEmpty) return 0;
    double currentValue = widget.monthlyGoalProgress.values.last;
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
          widget.onGoalUpdated(newName, newAmount, newColor);
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _showGoalDetails = !_showGoalDetails;
              });
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
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
                    '${(_calculateCurrentProgress() * 100).toStringAsFixed(1)}% tamamlandı (₺${widget.monthlyGoalProgress.values.last.toStringAsFixed(0)})',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_showGoalDetails) ...[
            const SizedBox(height: 16),
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
                  ...widget.monthlyGoalProgress.entries
                      .toList()
                      .asMap()
                      .entries
                      .map((entry) {
                        int index = entry.key;
                        String month = entry.value.key;
                        double currentValue = entry.value.value;

                        double previousValue = index > 0
                            ? widget.monthlyGoalProgress.values.toList()[index -
                                  1]
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
                    '${isPositive ? '+' : ''} ₺${monthlyAddition.toStringAsFixed(0)} / ${monthlyPercentage.toStringAsFixed(1)}%',
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
                        color: Colors.grey.shade300,
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
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
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
