import 'package:flutter/material.dart';
import '../../../../../core/widgets/widgets.dart';

/// Holds all signup form data across steps
class SignupData {
  // Role
  UserRoleOption? role;

  // Personal info
  String firstName = '';
  String lastName = '';
  String phone = '';

  // Patient specific
  DateTime? dateOfBirth;
  String? gender;
  String? bloodType;

  // Doctor specific
  String? specialty;
  String licenseNumber = '';
  String clinicName = '';
  String city = '';
  String country = '';
  int? yearsOfExperience;
  double? clinicLatitude;
  double? clinicLongitude;
  double? consultationFee;
  bool acceptsInsurance = false;
  String languages = '';
  String about = '';

  // Account
  String email = '';
  String password = '';
  bool acceptedTerms = false;

  /// Convert to profile data map based on role
  Map<String, dynamic> toProfileData() {
    if (role == UserRoleOption.patient) {
      return {
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'phone': phone.trim(),
        'dateOfBirth': dateOfBirth?.toIso8601String(),
        'gender': gender,
        if (bloodType != null) 'bloodType': bloodType,
      };
    } else {
      return {
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'phone': phone.trim(),
        'specialty': specialty,
        'licenseNumber': licenseNumber.trim(),
        if (clinicName.isNotEmpty) 'clinicName': clinicName.trim(),
        'clinicAddress': {
          'city': city.trim(),
          'country': country.trim(),
          'coordinates': {
            'type': 'Point',
            'coordinates': [clinicLongitude ?? 0.0, clinicLatitude ?? 0.0],
          },
        },
        if (yearsOfExperience != null) 'yearsOfExperience': yearsOfExperience,
        if (consultationFee != null) 'consultationFee': consultationFee,
        'acceptsInsurance': acceptsInsurance,
        if (languages.trim().isNotEmpty) 'languages': languages.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        if (about.trim().isNotEmpty) 'about': about.trim(),
      };
    }
  }

  String get roleString =>
      role == UserRoleOption.patient ? 'patient' : 'doctor';
}

/// Controller for signup screen navigation and state
class SignupController extends ChangeNotifier {
  final PageController pageController = PageController();
  final SignupData data = SignupData();

  int _currentStep = 0;
  int get currentStep => _currentStep;

  int get totalSteps => data.role == null ? 1 : 4;

  bool get isFirstStep => _currentStep == 0;
  bool get isLastStep => _currentStep == totalSteps - 1;

  String get stepTitle {
    switch (_currentStep) {
      case 0:
        return 'Create Account';
      case 1:
        return 'Personal Information';
      case 2:
        return data.role == UserRoleOption.patient
            ? 'Health Information'
            : 'Professional Information';
      case 3:
        return 'Account Details';
      default:
        return 'Sign Up';
    }
  }

  void nextStep() {
    if (_currentStep < totalSteps - 1) {
      _currentStep++;
      pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      notifyListeners();
    }
  }

  void setRole(UserRoleOption role) {
    data.role = role;
    notifyListeners();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}
