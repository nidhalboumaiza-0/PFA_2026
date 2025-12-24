import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medical_app/core/l10n/translator.dart';
import 'package:medical_app/core/widgets/common/common_widgets.dart';
import '../../../../core/utils/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SecoursScreen extends StatefulWidget {
  const SecoursScreen({super.key});

  @override
  State<SecoursScreen> createState() => _SecoursScreenState();
}

class _SecoursScreenState extends State<SecoursScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'all';
  final List<String> _categories = [
    'all',
    'emergency',
    'common',
    'children',
    'elderly',
  ];

  List<Map<String, dynamic>> _getFirstAidItems(BuildContext context) {
    return [
      {
        'title': context.tr('cpr_title'),
        'description': context.tr('cpr_desc'),
        'icon': FontAwesomeIcons.heartPulse,
        'image': 'assets/images/cpr.jpg',
        'category': 'emergency',
        'color': Colors.red,
      },
      {
        'title': context.tr('bleeding_title'),
        'description': context.tr('bleeding_desc'),
        'icon': FontAwesomeIcons.droplet,
        'image': 'assets/images/bleeding.jpg',
        'category': 'common',
        'color': Colors.red[700],
      },
      {
        'title': context.tr('burns_title'),
        'description': context.tr('burns_desc'),
        'icon': FontAwesomeIcons.fire,
        'image': 'assets/images/brulure.jpg',
        'category': 'common',
        'color': Colors.orange,
      },
      {
        'title': context.tr('choking_title'),
        'description': context.tr('choking_desc'),
        'icon': FontAwesomeIcons.lungs,
        'image': 'assets/images/choking.jpg',
        'category': 'emergency',
        'color': Colors.purple,
      },
      {
        'title': context.tr('fractures_title'),
        'description': context.tr('fractures_desc'),
        'icon': FontAwesomeIcons.bone,
        'category': 'common',
        'color': Colors.blue[700],
      },
      {
        'title': context.tr('first_aid.stroke_title'),
        'description': context.tr('first_aid.stroke_desc'),
        'icon': FontAwesomeIcons.brain,
        'category': 'emergency',
        'color': Colors.deepPurple,
      },
      {
        'title': context.tr('first_aid.heart_attack_title'),
        'description': context.tr('first_aid.heart_attack_desc'),
        'icon': FontAwesomeIcons.heart,
        'category': 'emergency',
        'color': Colors.red,
      },
      {
        'title': context.tr('first_aid.allergic_reactions_title'),
        'description': context.tr('first_aid.allergic_reactions_desc'),
        'icon': FontAwesomeIcons.viruses,
        'category': 'common',
        'color': Colors.amber[700],
      },
      {
        'title': context.tr('first_aid.poisoning_title'),
        'description': context.tr('first_aid.poisoning_desc'),
        'icon': FontAwesomeIcons.skullCrossbones,
        'category': 'children',
        'color': Colors.green[800],
      },
      {
        'title': context.tr('first_aid.seizures_title'),
        'description': context.tr('first_aid.seizures_desc'),
        'icon': FontAwesomeIcons.bolt,
        'category': 'common',
        'color': Colors.amber,
      },
      {
        'title': context.tr('first_aid.heat_stroke_title'),
        'description': context.tr('first_aid.heat_stroke_desc'),
        'icon': FontAwesomeIcons.temperatureHigh,
        'category': 'common',
        'color': Colors.deepOrange,
      },
      {
        'title': context.tr('first_aid.diabetes_emergency_title'),
        'description': context.tr('first_aid.diabetes_emergency_desc'),
        'icon': FontAwesomeIcons.fileWaveform,
        'category': 'common',
        'color': Colors.blue,
      },
      {
        'title': context.tr('first_aid.child_cpr_title'),
        'description': context.tr('first_aid.child_cpr_desc'),
        'icon': FontAwesomeIcons.child,
        'category': 'children',
        'color': Colors.lightBlue,
      },
      {
        'title': context.tr('first_aid.elderly_falls_title'),
        'description': context.tr('first_aid.elderly_falls_desc'),
        'icon': FontAwesomeIcons.personWalking,
        'category': 'elderly',
        'color': Colors.grey[700],
      },
    ];
  }

  List<Map<String, dynamic>> _getFilteredItems(BuildContext context) {
    return _getFirstAidItems(context).where((item) {
      final matchesSearch =
          item['title'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item['description'].toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
      final matchesCategory =
          _selectedCategory == 'all' || item['category'] == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _getFilteredItems(context);
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          context.tr("first_aid_title"),
          style: GoogleFonts.raleway(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, size: 24, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchBar(context),
          _buildCategoryFilter(context),
          Expanded(
            child:
                filteredItems.isEmpty
                    ? _buildNoResultsFound(context)
                    : _buildFirstAidGrid(context, filteredItems),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        style: GoogleFonts.raleway(fontSize: 16),
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search, color: Colors.grey[600], size: 20),
          hintText: context.tr('search_condition'),
          hintStyle: GoogleFonts.raleway(color: Colors.grey[400]),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(BuildContext context) {
    return Container(
      height: 50,
      margin: EdgeInsets.only(bottom: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        padding: EdgeInsets.symmetric(horizontal: 12),
        itemBuilder: (ctx, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
            },
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 4),
              padding: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                context.tr(category),
                style: GoogleFonts.raleway(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFirstAidGrid(BuildContext context, List<Map<String, dynamic>> filteredItems) {
    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.8,
      ),
      itemCount: filteredItems.length,
      itemBuilder: (ctx, index) {
        final item = filteredItems[index];
        return _buildFirstAidCard(context, item);
      },
    );
  }

  Widget _buildFirstAidCard(BuildContext context, Map<String, dynamic> item) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          // Navigate to detailed first aid instructions
          _showFirstAidDetails(context, item);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon in colored circle
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (item['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item['icon'] as IconData,
                  size: 24,
                  color: item['color'] as Color,
                ),
              ),
              SizedBox(height: 12),

              // Category badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item['category'],
                  style: GoogleFonts.raleway(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
              SizedBox(height: 10),

              // Title
              Text(
                item['title'],
                style: GoogleFonts.raleway(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8),

              // Description
              Expanded(
                child: Text(
                  item['description'],
                  style: GoogleFonts.raleway(
                    fontSize: 12,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoResultsFound(BuildContext context) {
    return EmptyStateWidget(
      message: context.tr('no_results_found'),
      description: context.tr('try_another_search'),
      useResponsiveSizing: false,
    );
  }

  void _showFirstAidDetails(BuildContext context, Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(
                            item['icon'] as IconData,
                            color: Colors.white,
                            size: 24,
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 24,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          item['title'],
                          style: GoogleFonts.raleway(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('description'),
                          style: GoogleFonts.raleway(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          item['description'],
                          style: GoogleFonts.raleway(
                            fontSize: 15,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),

                        SizedBox(height: 24),
                        Text(
                          context.tr('recommended_first_aid'),
                          style: GoogleFonts.raleway(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 16),

                        // Placeholder content for first aid steps
                        _buildFirstAidStep(
                          1,
                          context.tr('assess_situation'),
                          context.tr('assess_situation_desc'),
                        ),
                        _buildFirstAidStep(
                          2,
                          context.tr('call_for_help'),
                          context.tr('call_for_help_desc'),
                        ),
                        _buildFirstAidStep(
                          3,
                          context.tr('administer_first_aid'),
                          context.tr('administer_first_aid_desc'),
                        ),
                        _buildFirstAidStep(
                          4,
                          context.tr('monitor_condition'),
                          context.tr('monitor_condition_desc'),
                        ),

                        SizedBox(height: 24),
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Launch emergency call
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: Icon(Icons.phone, size: 20),
                            label: Text(
                              context.tr('emergency_call'),
                              style: GoogleFonts.raleway(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildFirstAidStep(int stepNumber, String title, String description) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              stepNumber.toString(),
              style: GoogleFonts.raleway(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.raleway(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.raleway(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
