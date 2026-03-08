import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  final String savedName;
  final TextEditingController nameController;
  final Function(String) onNameSaved;
  final VoidCallback onLogout;

  const ProfilePage({
    required this.savedName,
    required this.nameController,
    required this.onNameSaved,
    required this.onLogout,
    super.key,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_3_rounded, size: 32, color: Colors.purple),
              const SizedBox(width: 12),
              const Text(
                'Profil',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Adınız',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: widget.nameController,
            decoration: InputDecoration(
              hintText: 'Adınızı girin',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.person),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              widget.onNameSaved(widget.nameController.text);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Adınız kaydedildi!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightBlue,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Kaydet'),
          ),
          const SizedBox(height: 16),
          if (widget.savedName.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Kaydedilen ad: ${widget.savedName}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.purple,
                ),
              ),
            ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'Hesap',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) => AlertDialog(
                    title: const Text('Çıkış Yap'),
                    content: const Text(
                      'Hesaptan çıkış yapmak istediğinize emin misiniz?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('İptal'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onLogout();
                        },
                        child: const Text('Çıkış Yap'),
                      ),
                    ],
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Çıkış Yap'),
            ),
          ),
        ],
      ),
    );
  }
}
