import 'package:flutter/material.dart';
import 'package:medical_app/core/l10n/translator.dart';

// Translation keys for specialties
const List<String> specialtyKeys = [
  'dentist',
  'pulmonologist',
  'dermatologist',
  'nutritionist',
  'cardiologist',
  'psychologist',
  'general_practitioner',
  'neurologist',
  'orthopedic',
  'gynecologist',
  'ophthalmologist',
  'aesthetic_doctor',
];

// Get translated specialties list
List<String> getTranslatedSpecialties(BuildContext context) {
  return specialtyKeys.map((key) => context.tr(key)).toList();
}

// Get specialties with images
List<Map<String, dynamic>> getSpecialtiesWithImages(BuildContext context) {
  return [
    {'image': 'assets/images/dentiste.png', 'text': context.tr('dentist')},
    {'image': 'assets/images/bebe.png', 'text': context.tr('pediatrician')},
    {'image': 'assets/images/generaliste.png', 'text': context.tr('generalist')},
    {'image': 'assets/images/pnmeulogue.png', 'text': context.tr('pulmonologist')},
    {'image': 'assets/images/dermatologue.png', 'text': context.tr('dermatologist')},
    {'image': 'assets/images/diet.png', 'text': context.tr('nutritionist')},
    {'image': 'assets/images/cardio.png', 'text': context.tr('cardiologist')},
    {'image': 'assets/images/psy.png', 'text': context.tr('psychologist')},
    {'image': 'assets/images/neurologue.png', 'text': context.tr('neurologist')},
    {'image': 'assets/images/orthopediste.png', 'text': context.tr('orthopedic')},
    {'image': 'assets/images/gyneco.png', 'text': context.tr('gynecologist')},
    {'image': 'assets/images/ophtalmo.png', 'text': context.tr('ophthalmologist')},
    {'image': 'assets/images/botox.png', 'text': context.tr('aesthetic_doctor')},
  ];
}
