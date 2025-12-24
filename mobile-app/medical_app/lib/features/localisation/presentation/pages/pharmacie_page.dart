import 'package:flutter/material.dart';
import 'package:medical_app/core/l10n/translator.dart';

class PharmaciePage extends StatefulWidget {
  const PharmaciePage({super.key});

  @override
  State<PharmaciePage> createState() => _PharmaciePageState();
}

class _PharmaciePageState extends State<PharmaciePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('dashboard.pharmacies')),
        backgroundColor: Color(0xFF2FA7BB),
        leading: IconButton(
          icon: Icon(
            Icons.chevron_left,
            size: 30,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
