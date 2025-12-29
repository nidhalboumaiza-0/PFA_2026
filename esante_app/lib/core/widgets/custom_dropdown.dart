import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';

class CustomDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final String Function(T) itemLabelBuilder;
  final String? hintText;
  final String? errorText;
  final bool isRequired;
  final IconData? prefixIcon;
  final bool isEnabled;
  final bool isSearchable;

  const CustomDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.itemLabelBuilder,
    this.hintText,
    this.errorText,
    this.isRequired = false,
    this.prefixIcon,
    this.isEnabled = true,
    this.isSearchable = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        if (label.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: RichText(
              text: TextSpan(
                text: label,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: context.textPrimaryColor,
                ),
                children: isRequired
                    ? const [
                        TextSpan(
                          text: ' *',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        // Dropdown
        Container(
          decoration: BoxDecoration(
            color: isEnabled ? context.inputFillColor : context.inputFillColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: hasError
                  ? AppColors.error
                  : value != null
                      ? AppColors.primary.withValues(alpha: 0.3)
                      : context.inputBorderColor,
              width: hasError ? 1.5.w : 1.w,
            ),
          ),
          child: isSearchable
              ? _buildSearchableDropdown(context)
              : _buildStandardDropdown(context),
        ),
        // Error text
        if (hasError)
          Padding(
            padding: EdgeInsets.only(top: 6.h, left: 4.w),
            child: Text(
              errorText!,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.error,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStandardDropdown(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: Padding(
        padding: EdgeInsets.only(
          left: prefixIcon != null ? 8.w : 16.w,
          right: 8.w,
        ),
        child: Row(
          children: [
            if (prefixIcon != null) ...[
              Icon(
                prefixIcon,
                color: value != null ? AppColors.primary : context.textSecondaryColor,
                size: 22.sp,
              ),
              SizedBox(width: 12.w),
            ],
            Expanded(
              child: DropdownButton<T>(
                value: value,
                hint: Text(
                  hintText ?? 'Select an option',
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 16.sp,
                  ),
                ),
                isExpanded: true,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: value != null ? AppColors.primary : context.textSecondaryColor,
                ),
                items: items.map((item) {
                  return DropdownMenuItem<T>(
                    value: item,
                    child: Text(
                      itemLabelBuilder(item),
                      style: TextStyle(
                        color: context.textPrimaryColor,
                        fontSize: 16.sp,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: isEnabled ? onChanged : null,
                style: TextStyle(
                  color: context.textPrimaryColor,
                  fontSize: 16.sp,
                ),
                dropdownColor: context.surfaceColor,
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchableDropdown(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? () => _showSearchDialog(context) : null,
      child: Container(
        height: 56.h,
        padding: EdgeInsets.only(
          left: prefixIcon != null ? 16.w : 16.w,
          right: 16.w,
        ),
        child: Row(
          children: [
            if (prefixIcon != null) ...[
              Icon(
                prefixIcon,
                color: value != null ? AppColors.primary : context.textSecondaryColor,
                size: 22.sp,
              ),
              SizedBox(width: 12.w),
            ],
            Expanded(
              child: Text(
                value != null ? itemLabelBuilder(value as T) : (hintText ?? 'Select an option'),
                style: TextStyle(
                  color: value != null ? context.textPrimaryColor : context.textSecondaryColor,
                  fontSize: 16.sp,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: value != null ? AppColors.primary : context.textSecondaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSearchDialog(BuildContext context) async {
    final result = await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SearchableDropdownSheet<T>(
        items: items,
        itemLabelBuilder: itemLabelBuilder,
        selectedValue: value,
        title: label,
      ),
    );

    if (result != null) {
      onChanged(result);
    }
  }
}

class _SearchableDropdownSheet<T> extends StatefulWidget {
  final List<T> items;
  final String Function(T) itemLabelBuilder;
  final T? selectedValue;
  final String title;

  const _SearchableDropdownSheet({
    required this.items,
    required this.itemLabelBuilder,
    required this.selectedValue,
    required this.title,
  });

  @override
  State<_SearchableDropdownSheet<T>> createState() =>
      _SearchableDropdownSheetState<T>();
}

class _SearchableDropdownSheetState<T>
    extends State<_SearchableDropdownSheet<T>> {
  late TextEditingController _searchController;
  late List<T> _filteredItems;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredItems = widget.items;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items.where((item) {
          return widget
              .itemLabelBuilder(item)
              .toLowerCase()
              .contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40.w,
            height: 4.h,
            margin: EdgeInsets.symmetric(vertical: 12.h),
            decoration: BoxDecoration(
              color: context.dividerColor,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          // Title
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Text(
              widget.title,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: context.textPrimaryColor,
              ),
            ),
          ),
          SizedBox(height: 16.h),
          // Search field
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: TextField(
              controller: _searchController,
              onChanged: _filterItems,
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: context.inputFillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 12.h,
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          // Items list
          Expanded(
            child: ListView.builder(
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                final item = _filteredItems[index];
                final isSelected = item == widget.selectedValue;

                return ListTile(
                  onTap: () => Navigator.pop(context, item),
                  title: Text(
                    widget.itemLabelBuilder(item),
                    style: TextStyle(
                      color:
                          isSelected ? AppColors.primary : context.textPrimaryColor,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle,
                          color: AppColors.primary,
                        )
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Preset dropdown for gender selection
class GenderDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final String? errorText;

  const GenderDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  static const List<String> genders = ['male', 'female', 'other'];

  @override
  Widget build(BuildContext context) {
    return CustomDropdown<String>(
      label: 'Gender',
      value: value,
      items: genders,
      onChanged: onChanged,
      itemLabelBuilder: (gender) => gender[0].toUpperCase() + gender.substring(1),
      hintText: 'Select your gender',
      errorText: errorText,
      isRequired: true,
      prefixIcon: Icons.person_outline,
    );
  }
}

/// Preset dropdown for blood type selection
class BloodTypeDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final String? errorText;

  const BloodTypeDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  static const List<String> bloodTypes = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-'
  ];

  @override
  Widget build(BuildContext context) {
    return CustomDropdown<String>(
      label: 'Blood Type',
      value: value,
      items: bloodTypes,
      onChanged: onChanged,
      itemLabelBuilder: (type) => type,
      hintText: 'Select blood type (optional)',
      errorText: errorText,
      isRequired: false,
      prefixIcon: Icons.bloodtype_outlined,
    );
  }
}
