import 'package:flutter/material.dart';
import 'package:medical_app/core/l10n/translator.dart';

import '../../../../core/utils/navigation_with_transition.dart';
import '../../../rendez_vous/presentation/pages/RendezVousPatient.dart';
import '../../../../core/utils/app_colors.dart';

class AllSpecialtiesPage extends StatefulWidget {
  final List<Map<String, dynamic>> specialties;

  const AllSpecialtiesPage({Key? key, required this.specialties})
    : super(key: key);

  @override
  _AllSpecialtiesPageState createState() => _AllSpecialtiesPageState();
}

class _AllSpecialtiesPageState extends State<AllSpecialtiesPage> {
  List<Map<String, dynamic>> _filteredSpecialties = [];

  @override
  void initState() {
    super.initState();
    // Initially, the filtered list is the same as the full list
    _filteredSpecialties = widget.specialties;
  }

  void _filterSpecialties(String query) {
    setState(() {
      if (query.isEmpty) {
        // If the search query is empty, show all specialties
        _filteredSpecialties = widget.specialties;
      } else {
        // Filter specialties based on the query (case-insensitive)
        _filteredSpecialties =
            widget.specialties.where((specialty) {
              final specialtyName =
                  specialty['text']?.toString().toLowerCase() ?? '';
              return specialtyName.contains(query.toLowerCase());
            }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(context.tr("specialties")),
        backgroundColor: AppColors.primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 30),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: isDarkMode ? theme.cardColor : Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: AppColors.primaryColor.withOpacity(0.3),
                ),
              ),
              child: TextField(
                style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                decoration: InputDecoration(
                  hintText: context.tr("find_doctor_specialty"),
                  hintStyle: TextStyle(
                    color:
                        isDarkMode
                            ? AppColors.primaryColor.withOpacity(0.7)
                            : AppColors.primaryColor,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.primaryColor,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 20,
                  ),
                ),
                onChanged: (value) {
                  _filterSpecialties(value);
                },
              ),
            ),
            const SizedBox(height: 16),
            // Grid of Specialties
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // Modifié de 4 à 3 par ligne
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                itemCount: _filteredSpecialties.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      navigateToAnotherScreenWithSlideTransitionFromRightToLeft(
                        context,
                        RendezVousPatient(
                          selectedSpecialty:
                              _filteredSpecialties[index]['text'],
                        ),
                      );
                    },
                    child: Card(
                      elevation: 3,
                      color: theme.cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                AppColors.primaryColor,
                                BlendMode.srcATop,
                              ),
                              child: Image.asset(
                                _filteredSpecialties[index]['image']!,
                                width: 50,
                                height: 50,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _filteredSpecialties[index]['text']!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
