import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/constants/app_assets.dart';
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
      body: BlocBuilder<DoctorSearchBloc, DoctorSearchState>(
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<DoctorSearchBloc>().add(
                    GetCurrentLocation(specialty: _selectedSpecialty),
                  );
            },
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Search Filters
                SliverToBoxAdapter(
                  child: _buildFilters(),
                ),
                
                // Results
                if (state is DoctorSearchLoading)
                  SliverFillRemaining(
                    child: _buildShimmerLoading(),
                  )
                else if (state is DoctorSearchError)
                  SliverFillRemaining(
                    child: _buildErrorState(state.message),
                  )
                else if (state is DoctorSearchLoaded)
                  ..._buildDoctorSliverList(state)
                else
                  SliverFillRemaining(
                    child: _buildEmptyState(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      margin: EdgeInsets.all(16.r),
      child: Column(
        children: [
          // Search Header Card
          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.search_rounded,
                        color: Colors.white,
                        size: 24.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Find Your Doctor',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Search by specialty or name',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13.sp,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                // Doctor Name Search - Modern style
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _nameController,
                    style: TextStyle(fontSize: 15.sp),
                    decoration: InputDecoration(
                      hintText: 'Search doctor by name...',
                      hintStyle: TextStyle(
                        color: AppColors.grey400,
                        fontSize: 14.sp,
                      ),
                      prefixIcon: Icon(
                        Icons.person_search_rounded,
                        color: AppColors.primary,
                        size: 22.sp,
                      ),
                      suffixIcon: _nameController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.close_rounded,
                                color: AppColors.grey400,
                                size: 20.sp,
                              ),
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
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 14.h,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {});
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
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          
          // Filters Card
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Specialty Dropdown with better styling
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: CustomDropdown<String>(
                    label: '',
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
                ),
                SizedBox(height: 16.h),
                
                // Distance Radius Slider - Modern Design
                _buildRadiusSlider(),
                SizedBox(height: 14.h),
                
                // Location Info Row - Modern style
                BlocBuilder<DoctorSearchBloc, DoctorSearchState>(
                  builder: (context, state) {
                    if (state is DoctorSearchLoaded) {
                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(6.r),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.location_on_rounded,
                                color: AppColors.primary,
                                size: 16.sp,
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${state.totalDoctors} doctors found',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  Text(
                                    'Within ${_selectedRadius.toInt()} km radius',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: AppColors.grey500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    context.read<DoctorSearchBloc>().add(
                                          GetCurrentLocation(specialty: _selectedSpecialty),
                                        );
                                  },
                                  borderRadius: BorderRadius.circular(10.r),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12.w,
                                      vertical: 8.h,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.refresh_rounded,
                                          color: Colors.white,
                                          size: 16.sp,
                                        ),
                                        SizedBox(width: 4.w),
                                        Text(
                                          'Refresh',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w600,
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
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
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
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Icons.radar_rounded,
                    color: Colors.orange,
                    size: 18.sp,
                  ),
                ),
                SizedBox(width: 10.w),
                Text(
                  'Search Radius',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                '${_selectedRadius.toInt()} km',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 14.h),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.grey200,
            thumbColor: Colors.white,
            overlayColor: AppColors.primary.withOpacity(0.15),
            trackHeight: 6.h,
            thumbShape: RoundSliderThumbShape(
              enabledThumbRadius: 10.r,
              elevation: 4,
              pressedElevation: 6,
            ),
            overlayShape: RoundSliderOverlayShape(overlayRadius: 20.r),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.r),
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
                context.read<DoctorSearchBloc>().add(
                      UpdateSearchFilters(
                        specialty: _selectedSpecialty,
                        radius: value,
                      ),
                    );
              },
            ),
          ),
        ),
        SizedBox(height: 4.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildRadiusLabel('1 km'),
            _buildRadiusLabel('50 km'),
            _buildRadiusLabel('100 km'),
          ],
        ),
      ],
    );
  }

  Widget _buildRadiusLabel(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.sp,
          color: AppColors.grey500,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Shimmer loading for doctor list
  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: AppColors.grey200,
      highlightColor: AppColors.grey100,
      child: ListView.builder(
        padding: EdgeInsets.all(16.r),
        itemCount: 5,
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.only(bottom: 14.h),
          child: Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              children: [
                // Avatar placeholder
                Container(
                  width: 72.w,
                  height: 72.w,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18.r),
                  ),
                ),
                SizedBox(width: 14.w),
                // Text placeholders
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 140.w,
                        height: 18.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        width: 100.w,
                        height: 14.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Container(
                            width: 50.w,
                            height: 24.h,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Container(
                            width: 60.w,
                            height: 24.h,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDoctorSliverList(DoctorSearchLoaded state) {
    if (state.doctors.isEmpty) {
      return [
        SliverFillRemaining(
          child: _buildNoResultsState(),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: EdgeInsets.all(16.r),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
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
            childCount: state.doctors.length + (state.isLoadingMore ? 1 : 0),
          ),
        ),
      ),
    ];
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
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              AppAssets.onlineDoctorPanaImage,
              width: 200.w,
              height: 200.h,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 24.h),
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
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              AppAssets.medicalResearchImage,
              width: 160.w,
              height: 160.h,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 20.h),
            AppTitle(
              text: 'No doctors found',
              fontSize: 18.sp,
            ),
            SizedBox(height: 8.h),
            AppSubtitle(
              text: 'Try adjusting your filters or search area',
              fontSize: 14.sp,
            ),
            SizedBox(height: 20.h),
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
