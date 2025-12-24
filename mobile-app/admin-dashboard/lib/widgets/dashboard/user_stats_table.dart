import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../features/dashboard/domain/entities/stats_entity.dart';
import '../../config/theme.dart';

class UserStatsTable<T> extends StatelessWidget {
  final String title;
  final List<T> data;
  final List<DataColumn> columns;
  final List<DataRow> Function(List<T> data) buildRows;
  final bool isLoading;
  final String emptyMessage;
  final Widget? actionButton;

  const UserStatsTable({
    super.key,
    required this.title,
    required this.data,
    required this.columns,
    required this.buildRows,
    this.isLoading = false,
    this.emptyMessage = 'No data available',
    this.actionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
              if (actionButton != null) actionButton!,
            ],
          ),
          SizedBox(height: 16.h),
          Expanded(
            child:
                isLoading
                    ? Center(child: CircularProgressIndicator())
                    : data.isEmpty
                    ? Center(
                      child: Text(
                        emptyMessage,
                        style: TextStyle(fontSize: 16.sp),
                      ),
                    )
                    : DataTable2(
                      columns: columns,
                      rows: buildRows(data),
                      dividerThickness: 1.h,
                      dataRowHeight: 56.h,
                      headingRowHeight: 56.h,
                      columnSpacing: 20.w,
                      fixedLeftColumns: 1,
                      horizontalMargin: 10.w,
                      minWidth: 600.w,
                    ),
          ),
        ],
      ),
    );
  }
}

class DoctorStatsTable extends StatelessWidget {
  final List<DoctorStatistics> doctors;
  final bool isLoading;
  final String emptyMessage;
  final Function(DoctorStatistics)? onRowTap;
  final bool showActions;

  const DoctorStatsTable({
    super.key,
    required this.doctors,
    this.isLoading = false,
    this.emptyMessage = 'No doctors found',
    this.onRowTap,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return UserStatsTable<DoctorStatistics>(
      title: 'Doctor Statistics',
      data: doctors,
      isLoading: isLoading,
      emptyMessage: emptyMessage,
      columns: [
        DataColumn(
          label: Text(
            'Name',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
          ),
        ),
        DataColumn(
          label: Text(
            'Email',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
          ),
        ),
        DataColumn(
          label: Text(
            'Appointments',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
          ),
          numeric: true,
        ),
        DataColumn(
          label: Text(
            'Completion Rate',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
          ),
          numeric: true,
        ),
        DataColumn(
          label: Text(
            'Actions',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
          ),
        ),
      ],
      buildRows:
          (data) =>
              data
                  .map(
                    (doctor) => DataRow(
                      cells: [
                        DataCell(
                          Text(doctor.name, style: TextStyle(fontSize: 14.sp)),
                        ),
                        DataCell(
                          Text(doctor.email, style: TextStyle(fontSize: 14.sp)),
                        ),
                        DataCell(
                          Text(
                            doctor.appointmentCount.toString(),
                            style: TextStyle(fontSize: 14.sp),
                          ),
                        ),
                        DataCell(
                          Text(
                            '${(doctor.completionRate * 100).toStringAsFixed(0)}%',
                            style: TextStyle(fontSize: 14.sp),
                          ),
                        ),
                        DataCell(
                          showActions
                              ? Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.info_outline, size: 20.sp),
                                    onPressed: () {
                                      if (onRowTap != null) {
                                        onRowTap!(doctor);
                                      }
                                    },
                                    tooltip: 'View details',
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.block,
                                      color: Colors.red,
                                      size: 20.sp,
                                    ),
                                    onPressed: () {
                                      // Show confirmation dialog for banning
                                      showDialog(
                                        context: context,
                                        builder:
                                            (context) => AlertDialog(
                                              title: Text(
                                                'Ban Doctor',
                                                style: TextStyle(
                                                  fontSize: 18.sp,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              content: Text(
                                                'Are you sure you want to ban ${doctor.name}?',
                                                style: TextStyle(
                                                  fontSize: 16.sp,
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed:
                                                      () =>
                                                          Navigator.of(
                                                            context,
                                                          ).pop(),
                                                  child: Text(
                                                    'Cancel',
                                                    style: TextStyle(
                                                      fontSize: 14.sp,
                                                    ),
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    // TODO: Implement ban functionality
                                                    Navigator.of(context).pop();
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          '${doctor.name} has been banned',
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  child: Text(
                                                    'Ban',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                      fontSize: 14.sp,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                      );
                                    },
                                    tooltip: 'Ban doctor',
                                  ),
                                ],
                              )
                              : Text('', style: TextStyle(fontSize: 14.sp)),
                        ),
                      ],
                      onSelectChanged:
                          onRowTap != null
                              ? (_) {
                                onRowTap!(doctor);
                              }
                              : null,
                    ),
                  )
                  .toList(),
    );
  }
}

class PatientStatsTable extends StatelessWidget {
  final List<PatientStatistics> patients;
  final bool isLoading;
  final String emptyMessage;
  final Function(PatientStatistics)? onRowTap;
  final bool showActions;

  const PatientStatsTable({
    super.key,
    required this.patients,
    this.isLoading = false,
    this.emptyMessage = 'No patients found',
    this.onRowTap,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return UserStatsTable<PatientStatistics>(
      title: 'Patient Cancellation Statistics',
      data: patients,
      isLoading: isLoading,
      emptyMessage: emptyMessage,
      columns: [
        DataColumn(
          label: Text(
            'Name',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
          ),
        ),
        DataColumn(
          label: Text(
            'Email',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
          ),
        ),
        DataColumn(
          label: Text(
            'Cancelled',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
          ),
          numeric: true,
        ),
        DataColumn(
          label: Text(
            'Total',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
          ),
          numeric: true,
        ),
        DataColumn(
          label: Text(
            'Cancellation Rate',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
          ),
          numeric: true,
        ),
        DataColumn(
          label: Text(
            'Actions',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
          ),
        ),
      ],
      buildRows:
          (data) =>
              data
                  .map(
                    (patient) => DataRow(
                      cells: [
                        DataCell(
                          Text(patient.name, style: TextStyle(fontSize: 14.sp)),
                        ),
                        DataCell(
                          Text(
                            patient.email,
                            style: TextStyle(fontSize: 14.sp),
                          ),
                        ),
                        DataCell(
                          Text(
                            patient.cancelledAppointments.toString(),
                            style: TextStyle(fontSize: 14.sp),
                          ),
                        ),
                        DataCell(
                          Text(
                            patient.totalAppointments.toString(),
                            style: TextStyle(fontSize: 14.sp),
                          ),
                        ),
                        DataCell(
                          Text(
                            '${(patient.cancellationRate * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color:
                                  patient.cancellationRate > 0.3
                                      ? Colors.red
                                      : null,
                            ),
                          ),
                        ),
                        DataCell(
                          showActions
                              ? Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.info_outline, size: 20.sp),
                                    onPressed: () {
                                      if (onRowTap != null) {
                                        onRowTap!(patient);
                                      }
                                    },
                                    tooltip: 'View details',
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.flag,
                                      color: Colors.orange,
                                      size: 20.sp,
                                    ),
                                    onPressed: () {
                                      // Show confirmation dialog for banning
                                      showDialog(
                                        context: context,
                                        builder:
                                            (context) => AlertDialog(
                                              title: Text(
                                                'Flag Patient',
                                                style: TextStyle(
                                                  fontSize: 18.sp,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              content: Text(
                                                'Are you sure you want to flag ${patient.name}?',
                                                style: TextStyle(
                                                  fontSize: 16.sp,
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed:
                                                      () =>
                                                          Navigator.of(
                                                            context,
                                                          ).pop(),
                                                  child: Text(
                                                    'Cancel',
                                                    style: TextStyle(
                                                      fontSize: 14.sp,
                                                    ),
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    // TODO: Implement flag functionality
                                                    Navigator.of(context).pop();
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          '${patient.name} has been flagged',
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  child: Text(
                                                    'Flag',
                                                    style: TextStyle(
                                                      color: Colors.orange,
                                                      fontSize: 14.sp,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                      );
                                    },
                                    tooltip: 'Flag patient',
                                  ),
                                ],
                              )
                              : Text('', style: TextStyle(fontSize: 14.sp)),
                        ),
                      ],
                      onSelectChanged:
                          onRowTap != null
                              ? (_) {
                                onRowTap!(patient);
                              }
                              : null,
                    ),
                  )
                  .toList(),
    );
  }
}
