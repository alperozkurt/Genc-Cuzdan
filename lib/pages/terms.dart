import 'package:flutter/material.dart';

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
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.book_rounded, size: 32, color: Colors.indigo),
              const SizedBox(width: 12),
              const Text(
                'Finans Terimleri',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade200,
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _termsLanguageLevel = 'basic';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: _termsLanguageLevel == 'basic'
                            ? Colors.indigo
                            : Colors.transparent,
                      ),
                      child: Text(
                        'Temel Seviye',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _termsLanguageLevel == 'basic'
                              ? Colors.white
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _termsLanguageLevel = 'advanced';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: _termsLanguageLevel == 'advanced'
                            ? Colors.indigo
                            : Colors.transparent,
                      ),
                      child: Text(
                        'İleri Seviye',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _termsLanguageLevel == 'advanced'
                              ? Colors.white
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ...terms.entries.map((entry) {
            final termName = entry.key;
            final definition =
                entry.value[_termsLanguageLevel] ?? entry.value['basic']!;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.indigo.shade300, width: 1),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.indigo.withValues(alpha: 0.05),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      termName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      definition,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _termsLanguageLevel == 'basic'
                            ? Colors.green.withValues(alpha: 0.2)
                            : Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _termsLanguageLevel == 'basic'
                            ? 'Temel Seviye'
                            : 'İleri Seviye',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _termsLanguageLevel == 'basic'
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                        ),
                      ),
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
}
