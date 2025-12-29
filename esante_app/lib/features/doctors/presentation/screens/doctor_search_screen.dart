import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../injection_container.dart';
import '../bloc/doctor_search/doctor_search_bloc.dart';
import '../widgets/doctor_card.dart';
import 'doctor_detail_screen.dart';

class DoctorSearchScreen extends StatelessWidget {
  final bool showBackButton;
  
  const DoctorSearchScreen({
    super.key,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DoctorSearchBloc>()..add(const GetCurrentLocation()),
      child: _DoctorSearchView(showBackButton: showBackButton),
    );
  }
}

class _DoctorSearchView extends StatefulWidget {
  final bool showBackButton;
  
  const _DoctorSearchView({
    this.showBackButton = true,
  });

  @override
  State<_DoctorSearchView> createState() => _DoctorSearchViewState();
}

class _DoctorSearchViewState extends State<_DoctorSearchView> {
  String? _selectedSpecialty;
  double _selectedRadius = 10.0; // Default 10km
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _nameController = TextEditingController();
  Timer? _debounce;

  // Common medical specialties
  static const List<String> _specialties = [
    'All Specialties',
    'General Practice',
    'Cardiology',
    'Dermatology',
    'Endocrinology',
    'Gastroenterology',
    'Gynecology',
    'Neurology',
    'Oncology',
    'Ophthalmology',
    'Orthopedics',
    'Pediatrics',
    'Psychiatry',
    'Pulmonology',
    'Rheumatology',
    'Urology',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<DoctorSearchBloc>().add(const LoadMoreDoctors());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Find a Doctor',
        showBackButton: widget.showBackButton,
      ),
      body: Column(
        children: [
          // Search Filters using CustomDropdown
          _buildFilters(),
          
          // Results
          Expanded(
            child: BlocBuilder<DoctorSearchBloc, DoctorSearchState>(
              builder: (context, state) {
                if (state is DoctorSearchLoading) {
                  return _buildShimmerLoading();
                }

                if (state is DoctorSearchError) {
                  return _buildErrorState(state.message);
                }

                if (state is DoctorSearchLoaded) {
                  return _buildDoctorList(state);
                }

                return _buildEmptyState();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Using CustomDropdown from core/widgets
          CustomDropdown<String>(
            label: 'Specialty',
            value: _selectedSpecialty,
            items: _specialties,
            onChanged: (specialty) {
              setState(() {
                _selectedSpecialty = specialty == 'All Specialties' ? null : specialty;
              });
              context.read<DoctorSearchBloc>().add(
                    UpdateSearchFilters(
                      specialty: specialty == 'All Specialties' ? null : specialty,
                      name: _nameController.text.isEmpty ? null : _nameController.text,
                    ),
                  );
            },
            itemLabelBuilder: (specialty) => specialty,
            hintText: 'Select a specialty',
            prefixIcon: Icons.medical_services_outlined,
            isSearchable: true,
          ),
          SizedBox(height: 12.h),
          
          // Doctor Name Search
          CustomTextField(
            label: 'Doctor Name',
            controller: _nameController,
            hintText: 'Search by doctor name',
            prefixIcon: Icons.search,
            suffix: _nameController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _nameController.clear();
                      setState(() {});
                      context.read<DoctorSearchBloc>().add(
                            UpdateSearchFilters(
                              specialty: _selectedSpecialty,
                              name: null,
                            ),
                          );
                    },
                  )
                : null,
            onChanged: (value) {
              setState(() {}); // Update clear button visibility
              // Debounce search to avoid too many API calls
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 500), () {
                context.read<DoctorSearchBloc>().add(
                      UpdateSearchFilters(
                        specialty: _selectedSpecialty,
                        name: value.isEmpty ? null : value,
                      ),
                    );
              });
            },
          ),
          SizedBox(height: 16.h),
          
          // Distance Radius Slider
          _buildRadiusSlider(),
          SizedBox(height: 12.h),
          
          // Location Info Row
          BlocBuilder<DoctorSearchBloc, DoctorSearchState>(
            builder: (context, state) {
              if (state is DoctorSearchLoaded) {
                return Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: AppColors.primary,
                      size: 18.sp,
                    ),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        'Showing ${state.totalDoctors} doctors within ${_selectedRadius.toInt()} km',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: AppColors.grey400,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        context.read<DoctorSearchBloc>().add(
                              GetCurrentLocation(specialty: _selectedSpecialty),
                            );
                      },
                      icon: Icon(Icons.refresh, size: 16.sp),
                      label: const Text('Refresh'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRadiusSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.radar,
                  color: AppColors.primary,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Search Radius',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Text(
                '${_selectedRadius.toInt()} km',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.grey300,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withValues(alpha: 0.2),
            trackHeight: 4.h,
          ),
          child: Slider(
            value: _selectedRadius,
            min: 1,
            max: 100,
            divisions: 99,
            onChanged: (value) {
              setState(() {
                _selectedRadius = value;
              });
            },
            onChangeEnd: (value) {
              // Trigger search when user finishes sliding
              context.read<DoctorSearchBloc>().add(
                    UpdateSearchFilters(
                      specialty: _selectedSpecialty,
                      radius: value,
                    ),
                  );
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('1 km', style: TextStyle(fontSize: 11.sp, color: AppColors.grey400)),
            Text('50 km', style: TextStyle(fontSize: 11.sp, color: AppColors.grey400)),
            Text('100 km', style: TextStyle(fontSize: 11.sp, color: AppColors.grey400)),
          ],
        ),
      ],
    );
  }

  /// Shimmer loading for doctor list
  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: AppColors.grey300,
      highlightColor: Colors.grey.shade200,
      child: ListView.builder(
        padding: EdgeInsets.all(16.r),
        itemCount: 5,
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: Container(
            height: 100.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorList(DoctorSearchLoaded state) {
    if (state.doctors.isEmpty) {
      return _buildNoResultsState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<DoctorSearchBloc>().add(
              GetCurrentLocation(specialty: _selectedSpecialty),
            );
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.all(16.r),
        itemCount: state.doctors.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.doctors.length) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(16.r),
                child: const CircularProgressIndicator(),
              ),
            );
          }

          final doctor = state.doctors[index];
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: DoctorCard(
              doctor: doctor,
              onTap: () => _navigateToDetail(doctor.id),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64.sp,
            color: AppColors.grey300,
          ),
          SizedBox(height: 16.h),
          AppTitle(
            text: 'Search for doctors',
            fontSize: 18.sp,
          ),
          SizedBox(height: 8.h),
          AppSubtitle(
            text: 'Find doctors near you by specialty',
            fontSize: 14.sp,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search,
            size: 64.sp,
            color: AppColors.grey300,
          ),
          SizedBox(height: 16.h),
          AppTitle(
            text: 'No doctors found',
            fontSize: 18.sp,
          ),
          SizedBox(height: 8.h),
          AppSubtitle(
            text: 'Try adjusting your filters or search area',
            fontSize: 14.sp,
          ),
          SizedBox(height: 24.h),
          CustomButton(
            text: 'Clear Filters',
            onPressed: () {
              setState(() {
                _selectedSpecialty = null;
                _selectedRadius = 10.0;
                _nameController.clear();
              });
              context.read<DoctorSearchBloc>().add(const GetCurrentLocation());
            },
            isOutlined: true,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64.sp,
              color: AppColors.error,
            ),
            SizedBox(height: 16.h),
            AppTitle(
              text: 'Something went wrong',
              fontSize: 18.sp,
            ),
            SizedBox(height: 8.h),
            AppSubtitle(
              text: message,
              fontSize: 14.sp,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            CustomButton(
              text: 'Try Again',
              onPressed: () {
                context.read<DoctorSearchBloc>().add(
                      GetCurrentLocation(specialty: _selectedSpecialty),
                    );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(String doctorId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DoctorDetailScreen(doctorId: doctorId),
      ),
    );
  }
}
