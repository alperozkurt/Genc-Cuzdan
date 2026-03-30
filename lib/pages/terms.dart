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
      'Hisse Senedi': {
        'basic': 'Bir şirketin sahipliğinin küçük parçaları',
        'advanced':
            'Bir şirketin öz sermayesinin menkul kıymetleştirilmiş pay sertifikaları. Hisse senetleri yatırımcılara şirkette mülkiyet ve oy hakkı sağlar.',
      },
      'Tahvil': {
        'basic': 'Borç senetleri. İhraçcı borcu geri ödemeyi taahhüt eder',
        'advanced':
            'Sabit getirili menkul kıymetler. İhraçcı (devlet veya şirket) belirli tarihlerde sabit faiz öder ve vade sonunda ana parayı geri ödemeyi taahhüt eder.',
      },
      'Portföy': {
        'basic': 'Bir yatırımcının sahip olduğu tüm yatırımları bir arada',
        'advanced':
            'Çeşitli yatırım araçlarından oluşan varlık koleksiyonu. Etkin portföy yönetimi risk azaltma (diversifikasyon) ilkesini takip eder.',
      },
      'Faiz Oranı': {
        'basic': 'Borç para aldığında ödenen ek para miktarının yüzdesi',
        'advanced':
            'Borç verenlerin borç alanlara verdikleri fonlara uyguladığı getiri oranı. Merkez Bankası tarafından belirlenen temel faiz oranı ekonominin temelini oluştur.',
      },
      'Enflasyon': {
        'basic': 'Zaman içinde ürün fiyatlarının artması',
        'advanced':
            'Bir ekonomide mal ve hizmetlerin genel fiyat seviyesinin zamanla artması. Satın alma gücünü azaltır ve reel getirileri etkiler.',
      },
      'Diversifikasyon': {
        'basic': 'Parayla koyduğunuz farklı yatırım türleri',
        'advanced':
            'Yatırım portföyünü farklı varlık sınıflarına dağıtma stratejisi. Risk azaltmak ve potansiyel getiriyi optimize etmek için kullanılır.',
      },
      'Likidite': {
        'basic': 'Yatırımı ne kadar hızlı nakit paraya çevirebileceğiniz',
        'advanced':
            'Varlığın hızlı ve etkisiz bir şekilde nakit paraya dönüştürülebilme kabiliyeti. Yüksek likidite hızlı işlem yapabilmeyi sağlar.',
      },
      'Risk Primi': {
        'basic': 'Riskli yatırımdan daha yüksek bir getiri beklenmesi',
        'advanced':
            'Riskli varlık ile risksiz varlık arasındaki getiri farkı. Yatırımcıyı ek risk almaya teşvik etmek için prim sunulur.',
      },
      'Varlık Sınıfı': {
        'basic': 'Aynı özelliğe sahip yatırımlar (hisse, tahvil, altın vb.)',
        'advanced':
            'Benzer ekonomik özellikler ve davranışları sergileyen menkul kıymetler grubu. Hisse senetleri, tahviller, emtialar, gayrimenkul ana varlık sınıflarıdır.',
      },
      'Volatilite': {
        'basic': 'Yatırımın fiyatının ne kadar çabuk değiştiği',
        'advanced':
            'Varlığın fiyatının hareketlilik derecesi. Yüksek volatilite daha büyük fiyat dalgalanmalarını, dolayısıyla daha yüksek riski gösterir.',
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
