import 'package:flutter/material.dart';

import '../ui.dart';

/// First run: set up the shop, or explore the sample register.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _shop = TextEditingController();
  final _owner = TextEditingController();
  final _upi = TextEditingController();
  String lang = 'hi';
  String? _error;

  bool get en => lang == 'en';

  @override
  void dispose() {
    _shop.dispose();
    _owner.dispose();
    _upi.dispose();
    super.dispose();
  }

  void _create() {
    final shop = _shop.text.trim();
    final upi = _upi.text.trim();
    if (shop.isEmpty) {
      setState(() => _error = en ? 'Write your shop\'s name.' : 'अपनी दुकान का नाम लिखें।');
      return;
    }
    if (upi.isNotEmpty && !upi.contains('@')) {
      setState(() => _error = en ? 'A UPI ID looks like name@bank.' : 'UPI ID ऐसी होती है: name@bank');
      return;
    }
    StoreScope.read(context).createShop(name: shop, owner: _owner.text.trim(), upi: upi, lang: lang);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const ValueKey('onb-lang'),
                onPressed: () => setState(() => lang = en ? 'hi' : 'en'),
                child: Text(en ? 'हिंदी' : 'English'),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(color: brandRed, borderRadius: BorderRadius.circular(18)),
              child: Stack(
                children: [
                  Positioned(right: 10, top: 0, bottom: 0, child: Container(width: 4, color: turmeric)),
                  const Center(child: Icon(Icons.menu_book, color: Colors.white, size: 32)),
                ],
              ),
            ),
            ),
            const SizedBox(height: 20),
            Text(en ? 'Bahi' : 'बही', style: tt.headlineLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              en
                  ? 'The udhaar register in your pocket. Write credit by typing or speaking, see who to collect from first, and send polite WhatsApp reminders with your UPI ID.'
                  : 'जेब में उधार का रजिस्टर। बोलकर या लिखकर उधार लिखें, देखें पहले किससे लेना है, और UPI ID के साथ विनम्र WhatsApp रिमाइंडर भेजें।',
              style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 28),
            TextField(
              key: const ValueKey('onb-shop'),
              controller: _shop,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: en ? 'Shop name' : 'दुकान का नाम', hintText: 'Gupta General Store'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('onb-owner'),
              controller: _owner,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: en ? 'Your name' : 'आपका नाम'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('onb-upi'),
              controller: _upi,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: en ? 'Shop UPI ID (optional)' : 'दुकान की UPI ID (ज़रूरी नहीं)',
                hintText: 'guptastore@okaxis',
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: TextStyle(color: cs.error)),
              ),
            const SizedBox(height: 20),
            FilledButton(
              key: const ValueKey('onb-start'),
              onPressed: _create,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: Text(en ? 'Start my khata' : 'मेरा खाता शुरू करें'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              key: const ValueKey('onb-sample'),
              onPressed: () => StoreScope.read(context).loadSample(lang: lang),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: Text(en ? 'Explore with sample data' : 'नमूना डेटा के साथ देखें'),
            ),
            const SizedBox(height: 16),
            Text(
              en ? 'Everything is saved on this phone. No sign-up, no ads.' : 'सब कुछ इसी फ़ोन में सेव होता है। न साइन-अप, न विज्ञापन।',
              textAlign: TextAlign.center,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
