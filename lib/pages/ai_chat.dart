import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../theme/design_system.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> with TickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<_ChatMessage> _messages = [];
  bool _isTyping = false;

  static const String _prefsKey = 'ai_chat_history';

  static const List<String> _suggestions = [
    '💡 Tasarruf nasıl yapılır?',
    '📈 Enflasyondan nasıl korunurum?',
    '💳 Kredi kartı borçlarını nasıl yönetirim?',
    '🏦 Yatırım araçları nelerdir?',
    '📊 Bütçe planı nasıl oluştururum?',
    '🎯 Finansal hedef nasıl belirlenir?',
  ];

  static final List<_QA> _knowledgeBase = [
    _QA(
      keywords: ['tasarruf', 'biriktir', 'birikiyor', 'birikim'],
      answer:
          '💰 **Tasarruf için altın kurallar:**\n\n'
          '• Gelirinizin en az **%10–20**\'sini her ay düzenli olarak biriktirin.\n'
          '• "Önce kendinize ödeyin" yöntemini uygulayın: maaş gelir gelmez tasarrufu ayırın.\n'
          '• Gereksiz abonelikleri iptal ederek aylık harcamalarınızı düşürün.\n'
          '• Acil durum fonu olarak en az **3–6 aylık gider** tutarında birikim hedefleyin.\n\n'
          'GençCüzdan\'daki **Hedefler** bölümünü kullanarak tasarruf hedefi oluşturabilirsiniz! 🎯',
    ),
    _QA(
      keywords: ['enflasyon', 'paranın değeri', 'fiyat artış', 'korunmak'],
      answer:
          '📈 **Enflasyona karşı korunma yolları:**\n\n'
          '• **Altın** ve **döviz** gibi değer saklayan araçlara yönelin.\n'
          '• **Hisse senedi** ve **endeks fonları** uzun vadede enflasyonu genellikle geçer.\n'
          '• Tasarruflarınızı enflasyon oranının üzerinde faiz veren araçlarda değerlendirin.\n'
          '• Vadeli mevduat yerine **daha likit alternatifleri** araştırın.\n\n'
          'GençCüzdan döviz kurlarını anlık takip etmenizi sağlar! 💹',
    ),
    _QA(
      keywords: ['kredi kartı', 'borç', 'taksit'],
      answer:
          '💳 **Kredi kartı borcunu yönetme:**\n\n'
          '• Her ay **minimum ödeme** değil, **tam borcu** ödemeye çalışın.\n'
          '• Birden fazla kartınız varsa **en yüksek faizliden** başlayarak kapatın (Çığ Yöntemi).\n'
          '• Harcama limitinizi gelirinizin **%30**\'u ile sınırlı tutun.\n'
          '• Taksitli alışverişlerde toplam maliyeti hesaplayın.\n\n'
          'GençCüzdan\'da harcamalarınızı kategorilere göre takip edin! 📊',
    ),
    _QA(
      keywords: ['yatırım', 'portföy', 'nereye yatırım'],
      answer:
          '🏦 **Temel yatırım araçları:**\n\n'
          '• **Mevduat / Vadeli Hesap** — Düşük risk, belirli getiri.\n'
          '• **Devlet Tahvili / Bono** — Güvenli, sabit getiri.\n'
          '• **Hisse Senedi** — Yüksek potansiyel, yüksek risk.\n'
          '• **Altın** — Enflasyona karşı güvenli liman.\n'
          '• **Kripto Para** — Çok yüksek risk; dikkatli olun.\n\n'
          '⚠️ Yatırım kararları almadan önce lisanslı bir finansal danışmana başvurun.',
    ),
    _QA(
      keywords: ['bütçe', 'plan', 'planlama', 'harcama planı'],
      answer:
          '📊 **50/30/20 Bütçe Kuralı:**\n\n'
          '• **%50** → İhtiyaçlar (kira, fatura, market)\n'
          '• **%30** → İstekler (eğlence, restoran, alışveriş)\n'
          '• **%20** → Tasarruf ve borç ödemesi\n\n'
          'GençCüzdan\'a gelir/gider girerek takip edin! 🎯',
    ),
    _QA(
      keywords: ['hedef', 'hedef belirle', 'nasıl hedef'],
      answer:
          '🎯 **SMART Hedef belirleme:**\n\n'
          '• **S**pecific: "6 ayda 5.000 ₺ biriktireceğim".\n'
          '• **M**easurable: İlerlemeyi sayılarla takip edin.\n'
          '• **A**chievable: Gelirinize göre gerçekçi seçin.\n'
          '• **R**elevant: Size özel bir motivasyon seçin.\n'
          '• **T**ime-bound: Kesin bir bitiş tarihi koyun.\n\n'
          'GençCüzdan\'daki **Hedefler** sekmesinde hemen başlayın! 🚀',
    ),
    _QA(
      keywords: ['faiz', 'bileşik faiz'],
      answer:
          '🔢 **Faiz ve Bileşik Faiz:**\n\n'
          '**Basit faiz:** Ana para × Faiz oranı × Süre\n'
          '**Bileşik faiz:** Kazandığınız faiz de faiz kazanır — kartopu etkisi!\n\n'
          '💡 10.000 ₺\'yi %10 yıllık bileşik faizle 10 yıl tutarsanız ~**25.937 ₺** olur.\n\n'
          'Bu yüzden erken yaşta tasarrufa başlamak kritik öneme sahiptir!',
    ),
    _QA(
      keywords: ['merhaba', 'selam', 'hello', 'hi', 'nasılsın'],
      answer:
          '👋 Merhaba! Ben GençCüzdan\'ın AI finans asistanıyım.\n\n'
          'Size şu konularda yardımcı olabilirim:\n'
          '• 💰 Tasarruf ve birikim stratejileri\n'
          '• 📈 Yatırım araçları hakkında bilgi\n'
          '• 📊 Bütçe planlaması\n'
          '• 💳 Borç yönetimi\n'
          '• 🎯 Finansal hedef belirleme\n\n'
          'Ne öğrenmek istersiniz?',
    ),
  ];

  static const _welcomeText =
      '👋 Merhaba! Ben **Finans Asistanın**.\n\n'
      'Finansal sorularınızı yanıtlamak, bütçe planlamanıza yardımcı olmak ve para yönetimi konusunda rehberlik etmek için buradayım.\n\n'
      'Aşağıdaki konulardan birini seçebilir veya kendi sorunuzu yazabilirsiniz! 💬';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  // ── Persistence ─────────────────────────────────────────────────────────

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      final list = json.decode(raw) as List<dynamic>;
      setState(() {
        _messages.addAll(list.map((e) => _ChatMessage.fromJson(e)));
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } else {
      // First launch — show welcome
      setState(() {
        _messages.add(_ChatMessage(
          text: _welcomeText,
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      _saveHistory();
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      json.encode(_messages.map((m) => m.toJson()).toList()),
    );
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    setState(() {
      _messages.clear();
      _messages.add(_ChatMessage(
        text: _welcomeText,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
    _saveHistory();
  }

  // ── Logic ───────────────────────────────────────────────────────────────

  bool get _showSuggestions =>
      _messages.length == 1 && !_messages.first.isUser;

  String _generateResponse(String userInput) {
    final lower = userInput.toLowerCase();
    for (final qa in _knowledgeBase) {
      for (final kw in qa.keywords) {
        if (lower.contains(kw)) return qa.answer;
      }
    }
    return '🤔 Bu konuda size daha spesifik bir yanıt verebilmem için sorunuzu biraz daha açabilir misiniz?\n\n'
        'Şu konularda yardımcı olabilirim:\n'
        '• Tasarruf ve birikim\n'
        '• Yatırım araçları\n'
        '• Bütçe planlaması\n'
        '• Kredi/borç yönetimi\n'
        '• Finansal hedef belirleme';
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(
          text: text.trim(), isUser: true, timestamp: DateTime.now()));
      _isTyping = true;
    });
    _inputController.clear();
    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 900));

    setState(() {
      _isTyping = false;
      _messages.add(_ChatMessage(
          text: _generateResponse(text),
          isUser: false,
          timestamp: DateTime.now()));
    });

    _saveHistory();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: _messages.length +
                (_isTyping ? 1 : 0) +
                (_showSuggestions ? 1 : 0),
            itemBuilder: (context, index) {
              if (_showSuggestions && index == 1) {
                return _buildSuggestionChips();
              }
              final msgIndex = (_showSuggestions && index > 1) ? index - 1 : index;
              if (msgIndex == _messages.length) return _buildTypingIndicator();
              return _buildMessageBubble(_messages[msgIndex]);
            },
          ),
        ),
        _buildInputBar(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        color: DesignSystem.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [DesignSystem.primaryIndigo, DesignSystem.darkIndigo],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: DesignSystem.primaryIndigo.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Finans Asistanı',
                    style: DesignSystem.subheading(size: 16)),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: DesignSystem.secondaryGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text('Çevrimiçi',
                        style: DesignSystem.body(
                            size: 12, color: DesignSystem.secondaryGreen)),
                  ],
                ),
              ],
            ),
          ),
          // Clear chat button
          GestureDetector(
            onTap: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                backgroundColor: DesignSystem.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                title: Text('Sohbeti Temizle',
                    style: DesignSystem.subheading(size: 18)),
                content: Text(
                    'Tüm sohbet geçmişi silinecek. Emin misiniz?',
                    style: DesignSystem.body()),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('İptal',
                        style: DesignSystem.body(
                            color: DesignSystem.gray,
                            weight: FontWeight.w600)),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _clearHistory();
                    },
                    child: Text('Temizle',
                        style: DesignSystem.body(
                            color: DesignSystem.accentCoral,
                            weight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DesignSystem.lightGray,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete_sweep_rounded,
                  color: DesignSystem.gray, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChips() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text('Önerilen Sorular',
                style: DesignSystem.body(
                    size: 12,
                    color: DesignSystem.gray,
                    weight: FontWeight.w600)),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions.map(_buildChip).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return GestureDetector(
      onTap: () => _sendMessage(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: DesignSystem.primaryIndigo.withOpacity(0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: DesignSystem.primaryIndigo.withOpacity(0.2), width: 1),
        ),
        child: Text(label,
            style: DesignSystem.body(
                size: 13,
                color: DesignSystem.primaryIndigo,
                weight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage message) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [DesignSystem.primaryIndigo, DesignSystem.darkIndigo],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75),
              decoration: BoxDecoration(
                color:
                    isUser ? DesignSystem.primaryIndigo : DesignSystem.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: _buildRichText(message.text, isUser: isUser),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: DesignSystem.primaryIndigo.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.person_rounded,
                  color: DesignSystem.primaryIndigo, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRichText(String text, {required bool isUser}) {
    final baseColor = isUser ? Colors.white : DesignSystem.black;
    final spans = <InlineSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*');
    int lastEnd = 0;
    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
            text: text.substring(lastEnd, match.start),
            style: DesignSystem.body(size: 14, color: baseColor)));
      }
      spans.add(TextSpan(
          text: match.group(1),
          style: DesignSystem.body(
              size: 14, color: baseColor, weight: FontWeight.w700)));
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(
          text: text.substring(lastEnd),
          style: DesignSystem.body(size: 14, color: baseColor)));
    }
    return RichText(text: TextSpan(children: spans));
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [DesignSystem.primaryIndigo, DesignSystem.darkIndigo],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: DesignSystem.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: _TypingDots(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: DesignSystem.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: DesignSystem.lightGray,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _inputController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.send,
                onSubmitted: _sendMessage,
                style: DesignSystem.body(size: 14, color: DesignSystem.black),
                decoration: InputDecoration(
                  hintText: 'Finansal sorunuzu yazın...',
                  hintStyle: DesignSystem.body(size: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _sendMessage(_inputController.text),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [DesignSystem.primaryIndigo, DesignSystem.darkIndigo],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: DesignSystem.primaryIndigo.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data models ─────────────────────────────────────────────────────────────

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  _ChatMessage(
      {required this.text, required this.isUser, required this.timestamp});

  factory _ChatMessage.fromJson(Map<String, dynamic> j) => _ChatMessage(
        text: j['text'] as String,
        isUser: j['isUser'] as bool,
        timestamp: DateTime.parse(j['timestamp'] as String),
      );

  Map<String, dynamic> toJson() => {
        'text': text,
        'isUser': isUser,
        'timestamp': timestamp.toIso8601String(),
      };
}

class _QA {
  final List<String> keywords;
  final String answer;
  const _QA({required this.keywords, required this.answer});
}

// ── Typing animation ─────────────────────────────────────────────────────────

class _TypingDots extends StatefulWidget {
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
          vsync: this, duration: const Duration(milliseconds: 500))
        ..repeat(reverse: true),
    );
    _animations = _controllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeInOut))
        .toList();
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _animations[i],
          builder: (_, __) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: DesignSystem.primaryIndigo
                  .withOpacity(0.3 + 0.7 * _animations[i].value),
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    );
  }
}
