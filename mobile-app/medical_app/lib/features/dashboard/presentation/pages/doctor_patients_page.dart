import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medical_app/core/l10n/translator.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../authentication/data/models/user_model.dart';
import '../../../authentication/domain/entities/patient_entity.dart';
import '../../../profile/presentation/pages/patient_profile_page.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../../../injection_container.dart' as di;

class DoctorPatientsPage extends StatefulWidget {
  const DoctorPatientsPage({Key? key}) : super(key: key);

  @override
  State<DoctorPatientsPage> createState() => _DoctorPatientsPageState();
}

class _DoctorPatientsPageState extends State<DoctorPatientsPage> {
  final DashboardRepository _dashboardRepository = di.sl<DashboardRepository>();
  UserModel? currentUser;
  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMore = true;
  String? nextPatientId;

  List<Map<String, dynamic>> patients = [];
  String? searchQuery;
  final TextEditingController _searchController = TextEditingController();
  final int patientsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Helper method to get headers with auth token
  Future<Map<String, String>> _getHeaders() async {
    final headers = {'Content-Type': 'application/json'};
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('TOKEN');
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }
    } catch (e) {
      print('Error getting auth token: $e');
    }
    return headers;
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('CACHED_USER');

      if (userJson != null) {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        setState(() {
          currentUser = UserModel.fromJson(userMap);
        });

        if (currentUser?.id != null) {
          _loadPatients();
        } else {
          setState(() {
            isLoading = false;
          });
        }
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorSnackBar("${context.tr('errors.error_loading_user_data')}: $e");
    }
  }

  Future<void> _loadPatients({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        isLoading = true;
        patients = [];
        nextPatientId = null;
        hasMore = true;
      });
    }

    if (currentUser?.id == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      setState(() {
        if (!refresh) isLoadingMore = true;
      });

      // Use the repository to fetch patients
      final result = await _dashboardRepository.getDoctorPatients(
        currentUser!.id!,
        limit: patientsPerPage,
        lastPatientId: nextPatientId,
      );

      result.fold(
        (failure) {
          _showErrorSnackBar("${context.tr('dashboard.failed_to_load_patients')}: ${failure.message}");
          setState(() {
            isLoading = false;
            isLoadingMore = false;
          });
        },
        (data) {
          final newPatients = List<Map<String, dynamic>>.from(data['patients']);

          // Apply search filter if query exists
          if (searchQuery != null && searchQuery!.isNotEmpty) {
            final query = searchQuery!.toLowerCase();
            final filteredPatients =
                newPatients.where((patient) {
                  final name =
                      ((patient['name'] ?? '') as String).toLowerCase();
                  final lastName =
                      ((patient['lastName'] ?? '') as String).toLowerCase();
                  final fullName = '$name $lastName';
                  return fullName.contains(query);
                }).toList();

            setState(() {
              if (refresh || nextPatientId == null) {
                patients = filteredPatients;
              } else {
                patients.addAll(filteredPatients);
              }
              hasMore = data['hasMore'] ?? false;
              nextPatientId = data['nextPatientId'];
              isLoading = false;
              isLoadingMore = false;
            });
          } else {
            setState(() {
              if (refresh || nextPatientId == null) {
                patients = newPatients;
              } else {
                patients.addAll(newPatients);
              }
              hasMore = data['hasMore'] ?? false;
              nextPatientId = data['nextPatientId'];
              isLoading = false;
              isLoadingMore = false;
            });
          }
        },
      );
    } catch (e) {
      print('Error loading patients: $e');
      _showErrorSnackBar("${context.tr('dashboard.error_loading_patients')}: $e");
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.raleway()),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr("my_patients"),
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 2,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: EdgeInsets.all(16.w),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: context.tr('search_patient'),
                hintStyle: GoogleFonts.raleway(color: Colors.grey),
                prefixIcon: Icon(Icons.search, color: AppColors.primaryColor),
                suffixIcon:
                    searchQuery != null && searchQuery!.isNotEmpty
                        ? IconButton(
                          icon: Icon(Icons.close, color: Colors.grey),
                          onPressed: _clearSearch,
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: AppColors.primaryColor),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                filled: true,
                fillColor: Colors.white,
              ),
              style: GoogleFonts.raleway(fontSize: 14.sp),
              onChanged: _searchPatients,
            ),
          ),

          // Patients list
          Expanded(
            child:
                isLoading
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: AppColors.primaryColor,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            context.tr("loading_patients"),
                            style: GoogleFonts.raleway(
                              fontSize: 16.sp,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    )
                    : patients.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(24.w),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.people,
                              size: 64.sp,
                              color: Colors.grey.withOpacity(0.7),
                            ),
                          ),
                          SizedBox(height: 24.h),
                          Text(
                            searchQuery != null && searchQuery!.isNotEmpty
                                ? context.tr("no_patients_found_for_search")
                                : context.tr("no_patients_yet"),
                            style: GoogleFonts.raleway(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            searchQuery != null && searchQuery!.isNotEmpty
                                ? context.tr("try_different_search")
                                : context.tr("patients_will_appear_here"),
                            style: GoogleFonts.raleway(
                              fontSize: 14.sp,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (searchQuery != null && searchQuery!.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(top: 16.h),
                              child: ElevatedButton.icon(
                                onPressed: _clearSearch,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryColor,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20.w,
                                    vertical: 12.h,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: Icon(Icons.clear, size: 20.sp),
                                label: Text(
                                  context.tr("clear_search"),
                                  style: GoogleFonts.raleway(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: () => _loadPatients(refresh: true),
                      color: AppColors.primaryColor,
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (ScrollNotification scrollInfo) {
                          if (scrollInfo.metrics.pixels ==
                                  scrollInfo.metrics.maxScrollExtent &&
                              hasMore &&
                              !isLoadingMore) {
                            _loadMorePatients();
                          }
                          return false;
                        },
                        child: ListView.builder(
                          padding: EdgeInsets.all(16.w),
                          itemCount: patients.length + (hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == patients.length) {
                              return Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16.h),
                                  child: CircularProgressIndicator(
                                    color: AppColors.primaryColor,
                                    strokeWidth: 3.w,
                                  ),
                                ),
                              );
                            }

                            final patient = patients[index];
                            final String fullName =
                                '${patient['name'] ?? ''} ${patient['lastName'] ?? ''}'
                                    .trim();
                            final String lastAppointmentDate =
                                patient['lastAppointment'] != null
                                    ? DateFormat('dd/MM/yyyy').format(
                                      DateTime.parse(
                                        patient['lastAppointment'],
                                      ),
                                    )
                                    : 'N/A';

                            return Card(
                              margin: EdgeInsets.only(bottom: 12.h),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: InkWell(
                                onTap: () => _navigateToPatientProfile(patient),
                                borderRadius: BorderRadius.circular(12.r),
                                child: Padding(
                                  padding: EdgeInsets.all(16.w),
                                  child: Row(
                                    children: [
                                      Container(
                                        height: 50.h,
                                        width: 50.w,
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryColor,
                                          borderRadius: BorderRadius.circular(
                                            25.r,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            fullName.isNotEmpty
                                                ? fullName
                                                    .substring(0, 1)
                                                    .toUpperCase()
                                                : 'P',
                                            style: GoogleFonts.poppins(
                                              fontSize: 20.sp,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 16.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              fullName.isEmpty
                                                  ? context.tr('unknown_patient')
                                                  : fullName,
                                              style: GoogleFonts.raleway(
                                                fontSize: 16.sp,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            SizedBox(height: 4.h),
                                            Text(
                                              context.tr("last_consultation") +
                                                  ": $lastAppointmentDate",
                                              style: GoogleFonts.raleway(
                                                fontSize: 14.sp,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            if (patient['lastAppointmentStatus'] !=
                                                null)
                                              Padding(
                                                padding: EdgeInsets.only(
                                                  top: 6.h,
                                                ),
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 10.w,
                                                    vertical: 4.h,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: _getStatusColor(
                                                      patient['lastAppointmentStatus'],
                                                    ).withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20.r,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    _getStatusText(
                                                      context,
                                                      patient['lastAppointmentStatus'],
                                                    ),
                                                    style: GoogleFonts.raleway(
                                                      fontSize: 12.sp,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: _getStatusColor(
                                                        patient['lastAppointmentStatus'],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_right,
                                        color: Colors.grey,
                                        size: 24.sp,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(BuildContext context, String status) {
    switch (status) {
      case 'pending':
        return context.tr('status_pending');
      case 'accepted':
        return context.tr('status_confirmed');
      case 'cancelled':
        return context.tr('status_cancelled');
      case 'completed':
        return context.tr('status_completed');
      default:
        return context.tr('status_unknown');
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _searchPatients(String query) {
    setState(() {
      searchQuery = query;
    });
    _loadPatients(refresh: true);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      searchQuery = null;
    });
    _loadPatients(refresh: true);
  }

  void _navigateToPatientProfile(Map<String, dynamic> patientData) {
    if (patientData['id'] == null) return;

    final patientEntity = PatientEntity(
      id: patientData['id'] as String,
      name: patientData['name'] as String? ?? '',
      lastName: patientData['lastName'] as String? ?? '',
      email: patientData['email'] as String? ?? '',
      role: 'patient',
      gender: patientData['gender'] as String? ?? 'unknown',
      phoneNumber: patientData['phoneNumber'] as String? ?? '',
      dateOfBirth:
          patientData['dateOfBirth'] != null
              ? DateTime.tryParse(patientData['dateOfBirth'].toString())
              : null,
      antecedent: patientData['antecedent'] as String? ?? '',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientProfilePage(patient: patientEntity),
      ),
    );
  }

  Future<void> _loadMorePatients() async {
    if (!hasMore || isLoadingMore) return;

    setState(() {
      isLoadingMore = true;
    });

    try {
      await _loadPatients(refresh: false);
    } catch (e) {
      setState(() {
        isLoadingMore = false;
      });
      _showErrorSnackBar("${context.tr('dashboard.error_loading_patients')}: $e");
      print("Error loading more patients: $e");
    }
  }
}
