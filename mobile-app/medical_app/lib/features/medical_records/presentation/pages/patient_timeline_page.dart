import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:medical_app/core/l10n/translator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:medical_app/core/utils/app_colors.dart';
import 'package:medical_app/core/widgets/common/common_widgets.dart';
import 'package:medical_app/features/medical_records/domain/entities/consultation_entity.dart';
import 'package:medical_app/features/medical_records/presentation/bloc/medical_records_bloc.dart';
import 'package:medical_app/features/medical_records/presentation/pages/consultation_details_page.dart';
import 'package:medical_app/features/ordonnance/domain/entities/prescription_entity.dart';
import 'package:medical_app/features/ordonnance/presentation/bloc/prescription_bloc.dart';
import 'package:medical_app/features/ordonnance/presentation/pages/prescription_details_page.dart';
import 'package:medical_app/injection_container.dart';

/// Page for doctors to view a patient's complete medical history from all doctors
class PatientTimelinePage extends StatefulWidget {
  final String patientId;
  final String patientName;

  const PatientTimelinePage({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<PatientTimelinePage> createState() => _PatientTimelinePageState();
}

class _PatientTimelinePageState extends State<PatientTimelinePage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSearching = false;
  String? _filterDoctorId;
  String? _filterDoctorName;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<MedicalRecordsBloc>()
            ..add(GetPatientTimelineEvent(patientId: widget.patientId)),
        ),
        BlocProvider(
          create: (_) => sl<PrescriptionBloc>()
            ..add(GetPatientPrescriptions(patientId: widget.patientId)),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('medical_records.patient_history'),
                style: GoogleFonts.raleway(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                widget.patientName,
                style: GoogleFonts.raleway(
                  fontSize: 12.sp,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.primaryColor,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: GoogleFonts.raleway(
              fontWeight: FontWeight.w600,
              fontSize: 14.sp,
            ),
            tabs: [
              Tab(
                icon: Icon(Icons.history, size: 20.sp),
                text: context.tr('medical_records.consultations'),
              ),
              Tab(
                icon: Icon(Icons.medication, size: 20.sp),
                text: context.tr('medical_records.prescriptions'),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(
                _isSearching ? Icons.close : Icons.search,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) {
                    _searchController.clear();
                    _loadTimeline(context);
                  }
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.date_range, color: Colors.white),
              onPressed: () => _showDateRangeFilter(context),
            ),
            IconButton(
              icon: Icon(
                Icons.person_search,
                color: _filterDoctorId != null ? Colors.amber : Colors.white,
              ),
              onPressed: () => _showDoctorFilter(context),
            ),
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Consultations Timeline
            _buildConsultationsTab(),
            // Tab 2: Prescriptions
            _buildPrescriptionsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildConsultationsTab() {
    return Column(
      children: [
        // Search bar
        if (_isSearching)
          Container(
            padding: EdgeInsets.all(16.w),
            color: Colors.grey.shade100,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: context.tr('medical_records.search_diagnosis'),
                hintStyle: GoogleFonts.raleway(fontSize: 14.sp),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _searchHistory(context),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.r),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20.w,
                  vertical: 12.h,
                ),
              ),
              onSubmitted: (_) => _searchHistory(context),
            ),
          ),

        // Date filter indicator
        if (_startDate != null && _endDate != null)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            color: AppColors.primaryColor.withValues(alpha: 0.1),
            child: Row(
              children: [
                Icon(
                  Icons.filter_list,
                  size: 16.sp,
                  color: AppColors.primaryColor,
                ),
                SizedBox(width: 8.w),
                Text(
                  '${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}',
                  style: GoogleFonts.raleway(
                    fontSize: 12.sp,
                    color: AppColors.primaryColor,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _startDate = null;
                      _endDate = null;
                    });
                    _loadTimeline(context);
                  },
                  child: Icon(
                    Icons.close,
                    size: 16.sp,
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
          ),

        // Doctor filter indicator
        if (_filterDoctorId != null)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            color: Colors.amber.withValues(alpha: 0.1),
            child: Row(
              children: [
                Icon(
                  Icons.person_search,
                  size: 16.sp,
                  color: Colors.amber.shade700,
                ),
                SizedBox(width: 8.w),
                Text(
                  '${context.tr('medical_records.filter_by_doctor')}: $_filterDoctorName',
                  style: GoogleFonts.raleway(
                    fontSize: 12.sp,
                    color: Colors.amber.shade700,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _filterDoctorId = null;
                      _filterDoctorName = null;
                    });
                    _loadTimeline(context);
                  },
                  child: Icon(
                    Icons.close,
                    size: 16.sp,
                    color: Colors.amber.shade700,
                  ),
                ),
              ],
            ),
          ),

        // Content
        Expanded(
          child: BlocBuilder<MedicalRecordsBloc, MedicalRecordsState>(
            builder: (context, state) {
              if (state is MedicalRecordsLoading) {
                return LoadingStateWidget(
                  message: context.tr('medical_records.loading_history'),
                );
              }

              if (state is MedicalRecordsError) {
                return ErrorStateWidget(
                  message: state.message,
                  onRetry: () => _loadTimeline(context),
                  retryText: context.tr('medical_records.retry'),
                );
              }

              if (state is PatientTimelineLoaded) {
                if (state.timeline.isEmpty) {
                  return EmptyStateWidget(
                    message: context.tr('medical_records.no_history'),
                    description: context.tr('medical_records.no_history_desc'),
                  );
                }
                return _buildTimelineList(context, state.timeline);
              }

              if (state is PatientHistorySearched) {
                if (state.consultations.isEmpty) {
                  return EmptyStateWidget(
                    message: context.tr('medical_records.no_results'),
                    description: context.tr('medical_records.try_different_search'),
                  );
                }
                return _buildSearchResults(context, state.consultations);
              }

              return LoadingStateWidget(
                message: context.tr('medical_records.loading_history'),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPrescriptionsTab() {
    return BlocBuilder<PrescriptionBloc, PrescriptionState>(
      builder: (context, state) {
        if (state is PrescriptionLoading) {
          return LoadingStateWidget(
            message: context.tr('medical_records.loading_prescriptions'),
          );
        }

        if (state is PrescriptionError) {
          return ErrorStateWidget(
            message: state.message,
            onRetry: () {
              context.read<PrescriptionBloc>().add(
                    GetPatientPrescriptions(patientId: widget.patientId),
                  );
            },
            retryText: context.tr('medical_records.retry'),
          );
        }

        if (state is PatientPrescriptionsLoaded) {
          if (state.prescriptions.isEmpty) {
            return EmptyStateWidget(
              message: context.tr('medical_records.no_prescriptions'),
              description: context.tr('medical_records.no_prescriptions_desc'),
            );
          }
          return _buildPrescriptionsList(context, state.prescriptions);
        }

        return LoadingStateWidget(
          message: context.tr('medical_records.loading_prescriptions'),
        );
      },
    );
  }

  Widget _buildPrescriptionsList(
      BuildContext context, List<PrescriptionEntity> prescriptions) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<PrescriptionBloc>().add(
              GetPatientPrescriptions(patientId: widget.patientId),
            );
      },
      color: AppColors.primaryColor,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: prescriptions.length,
        itemBuilder: (context, index) {
          final prescription = prescriptions[index];
          return _buildPrescriptionCard(context, prescription);
        },
      ),
    );
  }

  Widget _buildPrescriptionCard(
      BuildContext context, PrescriptionEntity prescription) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PrescriptionDetailsPage(
                prescription: prescription,
                isDoctor: true,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with date and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.medication,
                        size: 20.sp,
                        color: AppColors.primaryColor,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        DateFormat('dd MMM yyyy').format(
                            prescription.prescriptionDate),
                        style: GoogleFonts.raleway(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  _buildPrescriptionStatusChip(prescription.status),
                ],
              ),

              SizedBox(height: 12.h),

              // Doctor info
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16.r,
                      backgroundColor: AppColors.primaryColor.withValues(alpha: 0.2),
                      child: Icon(
                        Icons.medical_services,
                        size: 16.sp,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prescription.doctorName ?? context.tr('medical_records.unknown_doctor'),
                            style: GoogleFonts.raleway(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12.h),

              // Medications count
              Row(
                children: [
                  Icon(
                    Icons.local_pharmacy,
                    size: 16.sp,
                    color: Colors.grey.shade600,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '${prescription.medications.length} ${context.tr('medical_records.medications')}',
                    style: GoogleFonts.raleway(
                      fontSize: 13.sp,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 8.h),

              // List first 2-3 medications
              ...prescription.medications.take(3).map((med) => Padding(
                    padding: EdgeInsets.only(left: 24.w, top: 4.h),
                    child: Row(
                      children: [
                        Container(
                          width: 6.w,
                          height: 6.w,
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            '${med.medicationName} - ${med.dosage}',
                            style: GoogleFonts.raleway(
                              fontSize: 12.sp,
                              color: Colors.grey.shade700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )),

              if (prescription.medications.length > 3) ...[
                Padding(
                  padding: EdgeInsets.only(left: 24.w, top: 4.h),
                  child: Text(
                    '+${prescription.medications.length - 3} ${context.tr('medical_records.more_medications')}',
                    style: GoogleFonts.raleway(
                      fontSize: 12.sp,
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],

              SizedBox(height: 12.h),

              // View details button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PrescriptionDetailsPage(
                          prescription: prescription,
                          isDoctor: true,
                        ),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.visibility,
                    size: 16.sp,
                    color: AppColors.primaryColor,
                  ),
                  label: Text(
                    context.tr('medical_records.view_details'),
                    style: GoogleFonts.raleway(
                      fontSize: 12.sp,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrescriptionStatusChip(String status) {
    Color color;
    IconData icon;
    switch (status.toLowerCase()) {
      case 'active':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'completed':
        color = Colors.blue;
        icon = Icons.done_all;
        break;
      case 'cancelled':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            status,
            style: GoogleFonts.raleway(
              fontSize: 10.sp,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _loadTimeline(BuildContext context) {
    context.read<MedicalRecordsBloc>().add(
          GetPatientTimelineEvent(
            patientId: widget.patientId,
            startDate: _startDate,
            endDate: _endDate,
            filterDoctorId: _filterDoctorId,
          ),
        );
  }

  void _showDoctorFilter(BuildContext context) {
    // Show a dialog to input doctor ID or clear filter
    showDialog(
      context: context,
      builder: (dialogContext) {
        final TextEditingController doctorController = TextEditingController(
          text: _filterDoctorId ?? '',
        );
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            context.tr('medical_records.filter_by_doctor'),
            style: GoogleFonts.raleway(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: doctorController,
                decoration: InputDecoration(
                  labelText: context.tr('medical_records.doctor_id'),
                  hintText: context.tr('medical_records.enter_doctor_id'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              if (_filterDoctorId != null) ...[
                SizedBox(height: 16.h),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _filterDoctorId = null;
                      _filterDoctorName = null;
                    });
                    Navigator.pop(dialogContext);
                    _loadTimeline(context);
                  },
                  icon: const Icon(Icons.clear, color: Colors.red),
                  label: Text(
                    context.tr('medical_records.clear_filter'),
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.tr('common.cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                final doctorId = doctorController.text.trim();
                if (doctorId.isNotEmpty) {
                  setState(() {
                    _filterDoctorId = doctorId;
                    _filterDoctorName = doctorId; // Could be name if we had lookup
                  });
                  Navigator.pop(dialogContext);
                  _loadTimeline(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
              ),
              child: Text(context.tr('common.ok')),
            ),
          ],
        );
      },
    );
  }

  void _searchHistory(BuildContext context) {
    if (_searchController.text.trim().isNotEmpty) {
      context.read<MedicalRecordsBloc>().add(
            SearchPatientHistoryEvent(
              patientId: widget.patientId,
              query: _searchController.text.trim(),
              startDate: _startDate,
              endDate: _endDate,
            ),
          );
    }
  }

  void _showDateRangeFilter(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      if (mounted) {
        _loadTimeline(context);
      }
    }
  }

  Widget _buildTimelineList(BuildContext context, List<TimelineEventEntity> timeline) {
    return RefreshIndicator(
      onRefresh: () async => _loadTimeline(context),
      color: AppColors.primaryColor,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: timeline.length,
        itemBuilder: (context, index) {
          final event = timeline[index];
          final isFirst = index == 0;
          final isLast = index == timeline.length - 1;

          return _buildTimelineItem(context, event, isFirst, isLast);
        },
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    TimelineEventEntity event,
    bool isFirst,
    bool isLast,
  ) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line and dot
          SizedBox(
            width: 40.w,
            child: Column(
              children: [
                if (!isFirst)
                  Container(
                    width: 2,
                    height: 20.h,
                    color: AppColors.primaryColor.withValues(alpha: 0.3),
                  ),
                Container(
                  width: 16.w,
                  height: 16.w,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
              ],
            ),
          ),

          SizedBox(width: 12.w),

          // Content card
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ConsultationDetailsPage(
                      consultationId: event.consultationId,
                    ),
                  ),
                );
              },
              child: Card(
                margin: EdgeInsets.only(bottom: 16.h),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date and type
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('dd MMM yyyy').format(event.date),
                            style: GoogleFonts.raleway(
                              fontSize: 12.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          _buildTypeChip(event.type),
                        ],
                      ),

                      SizedBox(height: 12.h),

                      // Doctor name
                      Row(
                        children: [
                          Icon(
                            Icons.medical_services,
                            size: 16.sp,
                            color: AppColors.primaryColor,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              event.doctorName ?? context.tr('medical_records.unknown_doctor'),
                              style: GoogleFonts.raleway(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (event.specialty != null) ...[
                        SizedBox(height: 4.h),
                        Padding(
                          padding: EdgeInsets.only(left: 24.w),
                          child: Text(
                            event.specialty!,
                            style: GoogleFonts.raleway(
                              fontSize: 12.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],

                      SizedBox(height: 12.h),

                      // Diagnosis
                      if (event.diagnosis != null && event.diagnosis!.isNotEmpty)
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.assignment,
                                size: 16.sp,
                                color: Colors.grey.shade600,
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  event.diagnosis!,
                                  style: GoogleFonts.raleway(
                                    fontSize: 13.sp,
                                    color: Colors.grey.shade800,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                      SizedBox(height: 12.h),

                      // View details button
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ConsultationDetailsPage(
                                  consultationId: event.consultationId,
                                ),
                              ),
                            );
                          },
                          icon: Icon(
                            Icons.visibility,
                            size: 16.sp,
                            color: AppColors.primaryColor,
                          ),
                          label: Text(
                            context.tr('medical_records.view_details'),
                            style: GoogleFonts.raleway(
                              fontSize: 12.sp,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context, List<ConsultationEntity> consultations) {
    return RefreshIndicator(
      onRefresh: () async => _searchHistory(context),
      color: AppColors.primaryColor,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: consultations.length,
        itemBuilder: (context, index) {
          final consultation = consultations[index];
          return _buildConsultationCard(context, consultation);
        },
      ),
    );
  }

  Widget _buildConsultationCard(BuildContext context, ConsultationEntity consultation) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ConsultationDetailsPage(
                consultationId: consultation.id!,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('dd/MM/yyyy').format(consultation.consultationDate),
                    style: GoogleFonts.raleway(
                      fontSize: 12.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  _buildStatusChip(consultation.status),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                consultation.doctorName ?? 'Dr. Unknown',
                style: GoogleFonts.raleway(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (consultation.doctorSpecialty != null)
                Text(
                  consultation.doctorSpecialty!,
                  style: GoogleFonts.raleway(
                    fontSize: 12.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              SizedBox(height: 8.h),
              Text(
                consultation.medicalNote.diagnosis ?? consultation.chiefComplaint,
                style: GoogleFonts.raleway(
                  fontSize: 13.sp,
                  color: Colors.grey.shade800,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String type) {
    Color color;
    IconData icon;

    switch (type.toLowerCase()) {
      case 'consultation':
        color = AppColors.primaryColor;
        icon = Icons.medical_services;
        break;
      case 'follow-up':
        color = Colors.orange;
        icon = Icons.repeat;
        break;
      case 'referral':
        color = Colors.purple;
        icon = Icons.swap_horiz;
        break;
      default:
        color = Colors.grey;
        icon = Icons.event;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            type,
            style: GoogleFonts.raleway(
              fontSize: 10.sp,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'completed':
        color = Colors.green;
        break;
      case 'draft':
        color = Colors.orange;
        break;
      case 'archived':
        color = Colors.grey;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        status,
        style: GoogleFonts.raleway(
          fontSize: 10.sp,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
