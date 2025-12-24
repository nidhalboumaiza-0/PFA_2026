import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:medical_app/core/l10n/translator.dart';
import 'package:medical_app/core/widgets/common/common_widgets.dart';
import 'package:medical_app/features/profile/presentation/widgets/profile_widgets.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../authentication/domain/entities/medecin_entity.dart';
import '../../../ratings/domain/entities/doctor_rating_entity.dart';
import '../../../ratings/presentation/bloc/rating_bloc.dart';

class DoctorProfilePage extends StatefulWidget {
  final MedecinEntity doctor;
  final bool canBookAppointment;
  final VoidCallback? onBookAppointment;

  const DoctorProfilePage({
    Key? key,
    required this.doctor,
    this.canBookAppointment = false,
    this.onBookAppointment,
  }) : super(key: key);

  @override
  State<DoctorProfilePage> createState() => _DoctorProfilePageState();
}

class _DoctorProfilePageState extends State<DoctorProfilePage> {
  late RatingBloc _ratingBloc;
  double _averageRating = 0.0;
  int _ratingCount = 0;
  bool _isLoading = true;
  List<DoctorRatingEntity> _ratings = [];

  @override
  void initState() {
    super.initState();
    _ratingBloc = BlocProvider.of<RatingBloc>(context);
    if (widget.doctor.id != null) {
      _loadDoctorRatings();
    }
  }

  void _loadDoctorRatings() {
    if (widget.doctor.id == null) return;

    setState(() {
      _isLoading = true;
    });

    _ratingBloc.add(GetDoctorRatings(widget.doctor.id!));
    _ratingBloc.add(GetDoctorAverageRating(widget.doctor.id!));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          context.tr("doctor_profile"),
          style: GoogleFonts.raleway(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 28, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocListener<RatingBloc, RatingState>(
        listener: (context, state) {
          if (state is DoctorRatingState) {
            setState(() {
              _ratings = state.ratings;
              _averageRating = state.averageRating;
              _ratingCount = state.ratings.length;
              _isLoading = false;
            });
          } else if (state is RatingError) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Doctor header card with basic info
              _buildDoctorHeaderCard(),

              // Ratings section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Text(
                  context.tr("reviews"),
                  style: GoogleFonts.raleway(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleLarge?.color,
                  ),
                ),
              ),

              // Rating summary
              _isLoading
                  ? Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      child: CircularProgressIndicator(
                        color: AppColors.primaryColor,
                      ),
                    ),
                  )
                  : _buildRatingSummary(_averageRating, _ratingCount),

              // Patient comments
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                child: Text(
                  context.tr('rating.comments'),
                  style: GoogleFonts.raleway(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleLarge?.color,
                  ),
                ),
              ),

              // Comments list
              _isLoading
                  ? Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      child: CircularProgressIndicator(
                        color: AppColors.primaryColor,
                      ),
                    ),
                  )
                  : _ratings.isEmpty
                  ? Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Center(
                      child: Text(
                        context.tr("no_reviews_available"),
                        style: GoogleFonts.raleway(
                          fontSize: 16.sp,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  )
                  : ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    itemCount: _ratings.length,
                    itemBuilder: (context, index) {
                      return _buildRatingItem(_ratings[index]);
                    },
                  ),

              SizedBox(height: 100.h), // Extra space at bottom for FAB
            ],
          ),
        ),
      ),
      floatingActionButton:
          widget.canBookAppointment
              ? FloatingActionButton.extended(
                onPressed: widget.onBookAppointment,
                icon: Icon(Icons.calendar_today),
                label: Text(context.tr("book_appointment")),
                backgroundColor: AppColors.primaryColor,
              )
              : null,
    );
  }

  Widget _buildDoctorHeaderCard() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Card(
      margin: EdgeInsets.all(16.w),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 80.h,
                  width: 80.w,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Icon(Icons.person, color: Colors.white, size: 40.sp),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Dr. ${widget.doctor.name} ${widget.doctor.lastName}",
                        style: GoogleFonts.raleway(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.titleLarge?.color,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        widget.doctor.speciality ??
                            context.tr("specialty_not_specified"),
                        style: GoogleFonts.raleway(
                          fontSize: 16.sp,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            Divider(height: 24.h),

            // Contact info
            _buildInfoRow(
              Icons.phone,
              widget.doctor.phoneNumber ?? context.tr("not_specified"),
            ),
            _buildInfoRow(
              Icons.mail,
              widget.doctor.email ?? context.tr("not_specified"),
            ),
            _buildInfoRow(
              Icons.location_on,
              widget.doctor.address != null
                  ? "${widget.doctor.address!['street']}, ${widget.doctor.address!['city']}"
                  : context.tr("address_not_specified"),
            ),

            // New fields
            _buildInfoRow(
              Icons.timer,
              "${widget.doctor.appointmentDuration} ${context.tr("minutes")}",
            ),
            if (widget.doctor.consultationFee != null)
              _buildInfoRow(
                Icons.attach_money,
                "${widget.doctor.consultationFee} ${context.tr("consultation_fee_label")}",
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Icon(icon, size: 18.sp, color: AppColors.primaryColor),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.raleway(
                fontSize: 14.sp,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSummary(double averageRating, int ratingCount) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(16.w),
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: isDarkMode ? theme.colorScheme.surface : Colors.grey[100],
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                averageRating.toStringAsFixed(1),
                style: GoogleFonts.poppins(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
              RatingBar.builder(
                initialRating: averageRating,
                minRating: 0,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemSize: 20.sp,
                ignoreGestures: true,
                unratedColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                itemBuilder:
                    (context, _) => Icon(Icons.star, color: Colors.amber),
                onRatingUpdate: (_) {},
              ),
              SizedBox(height: 4.h),
              Text(
                "$ratingCount ${context.tr("evaluations")}",
                style: GoogleFonts.raleway(
                  fontSize: 14.sp,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
          Spacer(),
          CircleAvatar(
            radius: 26.r,
            backgroundColor: AppColors.primaryColor,
            child: Icon(Icons.star, color: Colors.white, size: 24.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingItem(DoctorRatingEntity rating) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      isDarkMode ? theme.colorScheme.surface : Colors.grey[200],
                  radius: 20.r,
                  child: Text(
                    (rating.patientName != null &&
                            rating.patientName!.isNotEmpty)
                        ? rating.patientName![0].toUpperCase()
                        : "?",
                    style: GoogleFonts.raleway(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.titleMedium?.color,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rating.patientName ?? "",
                        style: GoogleFonts.raleway(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.titleMedium?.color,
                        ),
                      ),
                      Text(
                        DateFormat('dd/MM/yyyy').format(rating.createdAt),
                        style: GoogleFonts.raleway(
                          fontSize: 12.sp,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 16.sp),
                    SizedBox(width: 4.w),
                    Text(
                      rating.rating.toString(),
                      style: GoogleFonts.raleway(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (rating.comment != null && rating.comment!.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Text(
                rating.comment!,
                style: GoogleFonts.raleway(
                  fontSize: 14.sp,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
