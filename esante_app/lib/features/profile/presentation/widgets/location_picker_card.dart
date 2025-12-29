import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import 'map_location_picker.dart';

/// A card widget that displays a map preview and allows picking a location.
class LocationPickerCard extends StatelessWidget {
  final double? latitude;
  final double? longitude;
  final ValueChanged<LatLng> onLocationSelected;

  const LocationPickerCard({
    super.key,
    this.latitude,
    this.longitude,
    required this.onLocationSelected,
  });

  bool get hasLocation => latitude != null && longitude != null;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openLocationPicker(context),
      child: Container(
        height: 180.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: hasLocation ? AppColors.primary.withOpacity(0.3) : AppColors.grey300,
            width: 2,
          ),
          color: context.surfaceColor,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14.r),
          child: Stack(
            children: [
              // Map preview or placeholder
              if (hasLocation)
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(latitude!, longitude!),
                    zoom: 15,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('clinic'),
                      position: LatLng(latitude!, longitude!),
                    ),
                  },
                  zoomControlsEnabled: false,
                  scrollGesturesEnabled: false,
                  rotateGesturesEnabled: false,
                  tiltGesturesEnabled: false,
                  zoomGesturesEnabled: false,
                  myLocationButtonEnabled: false,
                  mapToolbarEnabled: false,
                  liteModeEnabled: true,
                )
              else
                Container(
                  color: Colors.grey.shade100,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.map_outlined,
                          size: 48.sp,
                          color: AppColors.grey400,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Tap to set location',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Overlay with tap indicator
              Positioned(
                bottom: 12.h,
                left: 12.w,
                right: 12.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        hasLocation ? Icons.edit_location_alt_rounded : Icons.add_location_alt_rounded,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        hasLocation ? 'Change Clinic Location' : 'Set Clinic Location',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openLocationPicker(BuildContext context) async {
    final LatLng? initialLocation = hasLocation
        ? LatLng(latitude!, longitude!)
        : null;

    final LatLng? result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => MapLocationPickerScreen(initialLocation: initialLocation),
      ),
    );

    if (result != null) {
      onLocationSelected(result);
    }
  }
}
