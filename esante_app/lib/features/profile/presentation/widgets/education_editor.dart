import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/doctor_profile_entity.dart';

/// A widget to manage education entries for doctor profiles
class EducationEditor extends StatefulWidget {
  final List<EducationEntity> initialEducation;
  final ValueChanged<List<Map<String, dynamic>>> onChanged;

  const EducationEditor({
    super.key,
    required this.initialEducation,
    required this.onChanged,
  });

  @override
  State<EducationEditor> createState() => _EducationEditorState();
}

class _EducationEditorState extends State<EducationEditor> {
  late List<_EducationEntry> _entries;

  @override
  void initState() {
    super.initState();
    _entries = widget.initialEducation
        .map((e) => _EducationEntry(
              degree: e.degree,
              institution: e.institution,
              year: e.year,
            ))
        .toList();
    
    // Add an empty entry if the list is empty
    if (_entries.isEmpty) {
      _entries.add(_EducationEntry());
    }
  }

  void _addEntry() {
    setState(() {
      _entries.add(_EducationEntry());
    });
    _notifyChange();
  }

  void _removeEntry(int index) {
    if (_entries.length > 1) {
      setState(() {
        _entries.removeAt(index);
      });
      _notifyChange();
    }
  }

  void _updateEntry(int index, _EducationEntry entry) {
    _entries[index] = entry;
    _notifyChange();
  }

  void _notifyChange() {
    final validEntries = _entries
        .where((e) => e.degree.isNotEmpty && e.institution.isNotEmpty)
        .map((e) => {
              'degree': e.degree,
              'institution': e.institution,
              if (e.year != null) 'year': e.year,
            })
        .toList();
    widget.onChanged(validEntries);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Education',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
            ),
            TextButton.icon(
              onPressed: _addEntry,
              icon: Icon(Icons.add_circle_outline, size: 20.sp),
              label: Text('Add', style: TextStyle(fontSize: 14.sp)),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        
        // Education entries list
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _entries.length,
          separatorBuilder: (_, __) => SizedBox(height: 16.h),
          itemBuilder: (context, index) {
            return _EducationEntryCard(
              entry: _entries[index],
              index: index,
              canRemove: _entries.length > 1,
              onChanged: (entry) => _updateEntry(index, entry),
              onRemove: () => _removeEntry(index),
            );
          },
        ),
        
        if (_entries.isEmpty || (_entries.length == 1 && _entries[0].degree.isEmpty))
          Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: Text(
              'Add your educational qualifications to build trust with patients',
              style: TextStyle(
                color: AppColors.textSecondary(context),
                fontSize: 12.sp,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}

class _EducationEntry {
  String degree;
  String institution;
  int? year;

  _EducationEntry({
    this.degree = '',
    this.institution = '',
    this.year,
  });
}

class _EducationEntryCard extends StatefulWidget {
  final _EducationEntry entry;
  final int index;
  final bool canRemove;
  final ValueChanged<_EducationEntry> onChanged;
  final VoidCallback onRemove;

  const _EducationEntryCard({
    required this.entry,
    required this.index,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  State<_EducationEntryCard> createState() => _EducationEntryCardState();
}

class _EducationEntryCardState extends State<_EducationEntryCard> {
  late TextEditingController _degreeController;
  late TextEditingController _institutionController;
  late TextEditingController _yearController;

  @override
  void initState() {
    super.initState();
    _degreeController = TextEditingController(text: widget.entry.degree);
    _institutionController = TextEditingController(text: widget.entry.institution);
    _yearController = TextEditingController(
      text: widget.entry.year?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _degreeController.dispose();
    _institutionController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _notifyChange() {
    widget.onChanged(_EducationEntry(
      degree: _degreeController.text,
      institution: _institutionController.text,
      year: int.tryParse(_yearController.text),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.school_rounded,
                  color: AppColors.primary,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Education ${widget.index + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const Spacer(),
              if (widget.canRemove)
                IconButton(
                  onPressed: widget.onRemove,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                    size: 20.sp,
                  ),
                  tooltip: 'Remove',
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(
                    minWidth: 36.w,
                    minHeight: 36.w,
                  ),
                ),
            ],
          ),
          SizedBox(height: 16.h),
          
          CustomTextField(
            controller: _degreeController,
            hintText: 'e.g., Doctor of Medicine (MD)',
            label: 'Degree / Qualification',
            prefixIcon: Icons.workspace_premium_outlined,
            onChanged: (_) => _notifyChange(),
          ),
          SizedBox(height: 12.h),
          
          CustomTextField(
            controller: _institutionController,
            hintText: 'e.g., Faculty of Medicine of Tunis',
            label: 'Institution',
            prefixIcon: Icons.account_balance_outlined,
            onChanged: (_) => _notifyChange(),
          ),
          SizedBox(height: 12.h),
          
          CustomTextField(
            controller: _yearController,
            hintText: 'e.g., 2015',
            label: 'Year of Completion',
            prefixIcon: Icons.calendar_today_outlined,
            keyboardType: TextInputType.number,
            onChanged: (_) => _notifyChange(),
          ),
        ],
      ),
    );
  }
}
