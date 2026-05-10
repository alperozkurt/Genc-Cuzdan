import 'package:flutter/material.dart';
import '../theme/design_system.dart';

class TermsPage extends StatefulWidget {
  const TermsPage({super.key});

  @override
  State<TermsPage> createState() => _TermsPageState();
}

class _TermsPageState extends State<TermsPage> {
  String _termsLanguageLevel = 'basic';

  @override
  Widget build(BuildContext context) {
    final Map<String, Map<String, String>> terms = {
      'Bütçe': {
        'basic': 'Paranı nasıl harcayacağını ve biriktireceğini önceden planlamaktır.',
        'advanced':
            'Belirli bir dönem (haftalık/aylık) için öngörülen gelir ve giderlerin dengeli bir şekilde dağıtılmasını sağlayan finansal planlama aracıdır.',
      },
      'Gelir (Kazanç)': {
        'basic': 'Cebine giren para. Harçlığın, bayram paran veya bir işten kazandığın paradır.',
        'advanced':
            'Bireyin belirli bir süre içinde elde ettiği toplam parasal değerdir. Düzenli ödenekler veya ticari kazançları kapsar.',
      },
      'Gider (Harcama)': {
        'basic': 'Cebinden çıkan para. Kantinden aldığın tost veya yeni bir oyun için ödediğin paradır.',
        'advanced':
            'Kişisel ihtiyaçların karşılanması amacıyla yapılan mal ve hizmet ödemelerinin genel adıdır.',
      },
      'Birikim': {
        'basic': 'Gelecekte kullanmak üzere sakladığın paradır. Kumbarana attığın paralar birikimdir.',
        'advanced':
            'Elde edilen gelirin harcanmayan ve gelecekteki hedefler veya beklenmedik durumlar için ayrılan kısmıdır.',
      },
      'İstek': {
        'basic': 'Hayatta kalmak için şart olmayan ama sahip olmak istediğin şeyler (yeni bir oyun, oyuncak).',
        'advanced':
            'Temel yaşam gereksinimlerinin ötesinde, kişinin yaşam kalitesini artırmaya yönelik arzu ettiği ancak elzem olmayan şeylerdir.',
      },
      'İhtiyaç': {
        'basic': 'Hayatta kalmak veya okula gitmek için kesinlikle gereken şeyler (yemek, su, kalem, defter).',
        'advanced':
            'Bireyin yaşamını sağlıklı sürdürebilmesi ve temel fonksiyonlarını yerine getirebilmesi için karşılanması zorunlu olan gereksinimlerdir.',
      },
      'Hedef': {
        'basic': 'Almak istediğin büyük bir şey için ne kadar para biriktirmen gerektiğini belirlemektir.',
        'advanced':
            'Belirli bir zaman diliminde ulaşılması planlanan ve eldeki finansal kaynakların bu doğrultuda planlanmasını gerektiren ölçülebilir amaçtır.',
      },
      'Enflasyon': {
        'basic': 'Zaman içinde mağazalardaki ürünlerin fiyatlarının artması, paranla eskisinden daha az şey alabilmen.',
        'advanced':
            'Bir ekonomide mal ve hizmetlerin genel fiyat seviyesinin zamanla artması. Bu durum paranın satın alma gücünü azaltır.',
      },
    };

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
                child: const Icon(Icons.book_rounded, size: 32, color: DesignSystem.primaryIndigo),
              ),
              const SizedBox(width: 16),
              Text('Finans Terimleri', style: DesignSystem.heading()),
            ],
          ),
          const SizedBox(height: 32),
          
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: DesignSystem.lightGray,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildToggleItem(
                    title: 'Temel Seviye',
                    isActive: _termsLanguageLevel == 'basic',
                    onTap: () => setState(() => _termsLanguageLevel = 'basic'),
                  ),
                ),
                Expanded(
                  child: _buildToggleItem(
                    title: 'İleri Seviye',
                    isActive: _termsLanguageLevel == 'advanced',
                    onTap: () => setState(() => _termsLanguageLevel = 'advanced'),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          ...terms.entries.map((entry) {
            final termName = entry.key;
            final definition = entry.value[_termsLanguageLevel] ?? entry.value['basic']!;

            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: DesignSystem.premiumCard(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(termName, style: DesignSystem.subheading(color: DesignSystem.primaryIndigo)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (_termsLanguageLevel == 'basic' ? DesignSystem.secondaryGreen : DesignSystem.warningOrange).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _termsLanguageLevel == 'basic' ? 'Temel' : 'İleri',
                            style: DesignSystem.body(
                              size: 11,
                              weight: FontWeight.w700,
                              color: _termsLanguageLevel == 'basic' ? DesignSystem.secondaryGreen : DesignSystem.warningOrange,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      definition,
                      style: DesignSystem.body(size: 14, color: DesignSystem.black, weight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildToggleItem({required String title, required bool isActive, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isActive ? DesignSystem.primaryIndigo : Colors.transparent,
          boxShadow: isActive ? [
            BoxShadow(
              color: DesignSystem.primaryIndigo.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: DesignSystem.body(
            color: isActive ? DesignSystem.white : DesignSystem.gray,
            weight: isActive ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
