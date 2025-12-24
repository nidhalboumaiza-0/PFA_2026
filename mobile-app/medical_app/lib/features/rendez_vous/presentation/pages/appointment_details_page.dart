import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

import '../../../../core/l10n/translator.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../features/authentication/data/models/user_model.dart';
import '../../../../features/authentication/domain/entities/medecin_entity.dart';
import '../../../../features/authentication/domain/entities/patient_entity.dart';
import '../../../../injection_container.dart' as di;
import '../../../ordonnance/presentation/pages/create_prescription_page.dart';
import '../../../ratings/domain/entities/doctor_rating_entity.dart';
import '../../../ratings/presentation/bloc/rating_bloc.dart';
import '../../domain/entities/rendez_vous_entity.dart';
import '../blocs/rendez-vous BLoC/rendez_vous_bloc.dart';
import '../../../profile/presentation/pages/doctor_profile_page.dart';
import '../../../profile/presentation/pages/patient_profile_page.dart';
import '../../../ordonnance/domain/entities/prescription_entity.dart';
import '../../../ordonnance/presentation/bloc/prescription_bloc.dart';
import '../../../ordonnance/presentation/pages/prescription_details_page.dart';
import '../widgets/reschedule_dialog.dart';

class AppointmentDetailsPage extends StatefulWidget {
  final RendezVousEntity appointment;
  final bool isDoctor;

  const AppointmentDetailsPage({
    Key? key,
    required this.appointment,
    this.isDoctor = false,
  }) : super(key: key);

  @override
  _AppointmentDetailsPageState createState() => _AppointmentDetailsPageState();
}

class _AppointmentDetailsPageState extends State<AppointmentDetailsPage> {
  late RendezVousBloc _rendezVousBloc;
  late RatingBloc _ratingBloc;
  late PrescriptionBloc _prescriptionBloc;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  UserModel? currentUser;
  bool isLoading = true;
  bool isCancelling = false;
  bool isRescheduling = false;
  double _rating = 3.0; // Default rating
  final TextEditingController _commentController = TextEditingController();
  bool hasRatedAppointment = false;
  bool isAppointmentPast = false;

  // Variables to store appointment rating data
  bool _isLoadingRating = false;
  DoctorRatingEntity? _appointmentRating;

  // Add these variables for prescription
  bool _isLoadingPrescription = false;
  PrescriptionEntity? _appointmentPrescription;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR', null);

    _rendezVousBloc = di.sl<RendezVousBloc>();
    _ratingBloc = di.sl<RatingBloc>();
    _prescriptionBloc = di.sl<PrescriptionBloc>();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('CACHED_USER');

    if (userJson != null) {
      try {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        setState(() {
          currentUser = UserModel.fromJson(userMap);
          isLoading = false;
        });

        // Check and update past appointments
        if (currentUser?.id != null) {
          _rendezVousBloc.add(
            CheckAndUpdatePastAppointments(
              userId: currentUser!.id!,
              userRole: currentUser!.role,
            ),
          );
        }

        // Check if appointment is in the past based on endTime if available
        DateTime appointmentEndTime;
        if (widget.appointment.endDate != null) {
          appointmentEndTime = widget.appointment.endDate;
        } else {
          // Use the doctor's appointment duration when available, otherwise default to 30 minutes
          appointmentEndTime = widget.appointment.startDate.add(
            const Duration(minutes: 30),
          );

          // Try to get more accurate duration from doctor profile
          if (widget.appointment.medecin != null) {
            _fetchDoctorInfo(widget.appointment.medecin!).then((doctor) {
              if (doctor != null && mounted) {
                final moreAccurateEndTime = widget.appointment.startDate.add(
                  Duration(minutes: doctor.appointmentDuration),
                );
                setState(() {
                  // Update past status with more accurate end time
                  isAppointmentPast = DateTime.now().isAfter(
                    moreAccurateEndTime,
                  );
                });
              }
            });
          }
        }

        setState(() {
          isAppointmentPast = DateTime.now().isAfter(appointmentEndTime);
        });

        // Load if user has already rated this appointment
        if (widget.appointment.id != null &&
            currentUser?.id != null &&
            currentUser?.role == 'patient' &&
            widget.appointment.status == 'completed') {
          _checkIfRatedAppointment();
        }

        // If this is a doctor viewing a completed appointment, fetch its rating
        if (widget.appointment.id != null &&
            currentUser?.role == 'medecin' &&
            widget.appointment.status == 'completed') {
          _fetchAppointmentRating();
        }

        // Check if appointment has prescription
        if (widget.appointment.id != null) {
          _fetchAppointmentPrescription();
        }
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        print('Error loading user: $e');
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _checkIfRatedAppointment() {
    if (widget.appointment.id != null &&
        currentUser?.id != null &&
        currentUser?.role == 'patient' &&
        widget.appointment.status == 'completed') {
      _ratingBloc.add(
        CheckPatientRatedAppointment(
          patientId: currentUser!.id!,
          rendezVousId: widget.appointment.id!,
        ),
      );
    }
  }

  // Function to cancel an appointment
  void _cancelAppointment() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              context.tr("confirm_cancellation"),
              style: GoogleFonts.raleway(
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
              ),
            ),
            content: Text(
              context.tr("confirm_cancel_appointment"),
              style: GoogleFonts.raleway(fontSize: 14.sp),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  context.tr("no"),
                  style: GoogleFonts.raleway(
                    fontSize: 14.sp,
                    color: Colors.grey,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  if (widget.appointment.id != null &&
                      widget.appointment.patient != null &&
                      widget.appointment.medecin != null &&
                      widget.appointment.patientName != null &&
                      widget.appointment.medecinName != null) {
                    setState(() {
                      isCancelling = true;
                    });

                    _rendezVousBloc.add(
                      UpdateRendezVousStatus(
                        rendezVousId: widget.appointment.id!,
                        status: "cancelled",
                      ),
                    );
                  }
                  Navigator.pop(context);
                },
                child: Text(
                  context.tr("yes"),
                  style: GoogleFonts.raleway(
                    fontSize: 14.sp,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  // Function to show reschedule dialog (for both doctor and patient)
  void _showRescheduleDialog() {
    final isDoctor = widget.isDoctor || currentUser?.role == 'medecin';
    final currentTime = DateFormat('HH:mm').format(widget.appointment.startDate);

    showDialog(
      context: context,
      builder: (context) => RescheduleDialog(
        appointmentId: widget.appointment.id!,
        currentDate: widget.appointment.startDate,
        currentTime: currentTime,
        isDoctor: isDoctor,
        onConfirm: (newDate, newTime, reason) {
          setState(() {
            isRescheduling = true;
          });

          if (isDoctor) {
            // Doctor reschedules directly
            _rendezVousBloc.add(
              RescheduleAppointment(
                appointmentId: widget.appointment.id!,
                newDate: newDate,
                newTime: newTime,
                reason: reason,
              ),
            );
          } else {
            // Patient requests reschedule
            _rendezVousBloc.add(
              RequestReschedule(
                appointmentId: widget.appointment.id!,
                newDate: newDate,
                newTime: newTime,
                reason: reason,
              ),
            );
          }
        },
      ),
    );
  }

  // Function to approve reschedule request (doctor only)
  void _approveReschedule() {
    setState(() {
      isRescheduling = true;
    });
    _rendezVousBloc.add(ApproveReschedule(widget.appointment.id!));
  }

  // Function to reject reschedule request (doctor only)
  void _rejectReschedule({String? reason}) {
    setState(() {
      isRescheduling = true;
    });
    _rendezVousBloc.add(RejectReschedule(widget.appointment.id!, reason: reason));
  }

  // Function to submit a rating
  void _submitRating() {
    if (currentUser == null ||
        currentUser!.id == null ||
        widget.appointment.medecin == null ||
        widget.appointment.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr('rating.cannot_submit_rating'),
            style: GoogleFonts.raleway(),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    final rating = DoctorRatingEntity.create(
      doctorId: widget.appointment.medecin,
      patientId: currentUser!.id!,
      patientName: currentUser!.name + ' ' + currentUser!.lastName,
      rating: _rating,
      comment:
          _commentController.text.isNotEmpty ? _commentController.text : null,
      rendezVousId: widget.appointment.id!,
    );

    _ratingBloc.add(SubmitDoctorRating(rating));
  }

  String _getStatusText(BuildContext context, String status) {
    switch (status) {
      case "accepted":
        return context.tr("appointment_status_confirmed");
      case "pending":
        return context.tr("appointment_status_pending");
      case "cancelled":
        return context.tr("appointment_status_cancelled");
      case "completed":
        return context.tr("appointment_status_completed");
      default:
        return context.tr("appointment_status_unknown");
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "accepted":
        return Colors.green;
      case "pending":
        return Colors.orange;
      case "cancelled":
        return Colors.red;
      case "completed":
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // Calculate appointment duration in minutes
  String _getAppointmentDuration(BuildContext context) {
    if (widget.appointment.endDate != null) {
      final duration = widget.appointment.endDate.difference(
        widget.appointment.startDate,
      );
      final minutes = duration.inMinutes;
      if (minutes >= 60) {
        final hours = minutes ~/ 60;
        final remainingMinutes = minutes % 60;
        if (remainingMinutes == 0) {
          return "$hours " + (hours > 1 ? context.tr('hours') : context.tr('hour'));
        } else {
          return "$hours " +
              (hours > 1 ? context.tr('hours') : context.tr('hour')) +
              " $remainingMinutes " +
              (remainingMinutes > 1 ? context.tr('minutes') : context.tr('minute'));
        }
      } else {
        return "$minutes " + (minutes > 1 ? context.tr('minutes') : context.tr('minute'));
      }
    } else {
      // If we don't have an end date, we just return the default
      // The component will later be updated if we successfully fetch the doctor info
      if (widget.appointment.medecin != null) {
        // Start an async fetch for the doctor info, but don't wait for result
        _fetchDoctorInfo(widget.appointment.medecin!).then((doctor) {
          if (doctor != null && mounted) {
            // This will update the UI with the correct duration once doctor info is loaded
            setState(() {
              // We're just triggering a rebuild here, not returning anything
            });
          }
        });
      }

      // Default fallback duration if endTime not available
      return "30 " + context.tr('minutes');
    }
  }

  // Fetch doctor info from API
  Future<MedecinEntity?> _fetchDoctorInfo(String doctorId) async {
    try {
      final response = await ApiService.getDoctorById(doctorId);
      
      if (response['doctor'] != null) {
        final doctorData = response['doctor'] as Map<String, dynamic>;
        return MedecinEntity(
          id: doctorData['_id'] ?? doctorId,
          name: doctorData['firstName'] ?? doctorData['name'] ?? '',
          lastName: doctorData['lastName'] ?? '',
          email: doctorData['email'] ?? '',
          speciality: doctorData['specialty'] ?? doctorData['speciality'],
          role: 'doctor',
          gender: doctorData['gender'] ?? 'unknown',
          phoneNumber: doctorData['phone'] ?? doctorData['phoneNumber'] ?? '',
          appointmentDuration: doctorData['appointmentDuration'] as int? ?? 30,
          profilePicture: doctorData['profilePhoto'],
          about: doctorData['about'],
          consultationFee: doctorData['consultationFee']?.toDouble(),
          yearsOfExperience: doctorData['yearsOfExperience'],
          clinicName: doctorData['clinicName'],
          clinicAddress: doctorData['clinicAddress'],
        );
      }
      return null;
    } catch (e) {
      print('Error fetching doctor info: $e');
      return null;
    }
  }

  void _navigateToDoctorProfile() async {
    if (widget.appointment.medecin == null) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryColor),
          ),
    );

    // Try to fetch doctor from Firestore
    MedecinEntity? doctorEntity = await _fetchDoctorInfo(
      widget.appointment.medecin,
    );

    // Dismiss loading indicator
    Navigator.pop(context);

    // If fetch failed, create a basic doctor entity with available info
    if (doctorEntity == null) {
      final doctorName = widget.appointment.medecinName ?? '';
      final nameArray = doctorName.split(' ');
      final firstName = nameArray.isNotEmpty ? nameArray[0] : '';
      final lastName = nameArray.length > 1 ? nameArray[1] : '';

      doctorEntity = MedecinEntity(
        id: widget.appointment.medecin,
        name: firstName,
        lastName: lastName,
        email: "docteur@medical-app.com",
        speciality: widget.appointment.medecinSpeciality,
        role: 'doctor',
        gender: 'unknown',
        phoneNumber: "+212 600000000",
      );
    }

    // Now doctorEntity is guaranteed to be non-null
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => DoctorProfilePage(
              doctor: doctorEntity!,
              canBookAppointment: false,
            ),
      ),
    );
  }

  // Fetch patient info from Firestore
  Future<PatientEntity?> _fetchPatientInfo(String patientId) async {
    try {
      final patientDoc =
          await _firestore.collection('patients').doc(patientId).get();

      if (patientDoc.exists) {
        Map<String, dynamic> patientData =
            patientDoc.data() as Map<String, dynamic>;
        return PatientEntity(
          id: patientId,
          name: patientData['name'] ?? '',
          lastName: patientData['lastName'] ?? '',
          email: patientData['email'] ?? '',
          role: patientData['role'] ?? 'patient',
          gender: patientData['gender'] ?? 'unknown',
          phoneNumber: patientData['phoneNumber'] ?? '',
          dateOfBirth:
              patientData['dateOfBirth'] != null
                  ? (patientData['dateOfBirth'] is Timestamp)
                      ? (patientData['dateOfBirth'] as Timestamp).toDate()
                      : (patientData['dateOfBirth'] is String 
                          ? DateTime.parse(patientData['dateOfBirth']) 
                          : null)
                  : null,
          antecedent: patientData['antecedent'] ?? '',
        );
      }
      return null;
    } catch (e) {
      print('Error fetching patient info: $e');
      return null;
    }
  }

  void _navigateToPatientProfile() async {
    if (widget.appointment.patient == null) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryColor),
          ),
    );

    // Try to fetch patient from Firestore
    PatientEntity? patientEntity = await _fetchPatientInfo(
      widget.appointment.patient,
    );

    // Dismiss loading indicator
    Navigator.pop(context);

    // If fetch failed, create a basic patient entity with available info
    if (patientEntity == null) {
      final patientName = widget.appointment.patientName ?? '';
      final nameArray = patientName.split(' ');
      final firstName = nameArray.isNotEmpty ? nameArray[0] : '';
      final lastName = nameArray.length > 1 ? nameArray[1] : '';

      patientEntity = PatientEntity(
        id: widget.appointment.patient,
        name: firstName,
        lastName: lastName,
        email: "patient@medical-app.com",
        role: 'patient',
        gender: 'unknown',
        phoneNumber: "+212 600000000",
        antecedent: "",
      );
    }

    // Now patientEntity is guaranteed to be non-null
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientProfilePage(patient: patientEntity!),
      ),
    );
  }

  void _createPrescription() async {
    if (widget.appointment.patient == null) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryColor),
          ),
    );

    // Try to fetch patient from Firestore for medical history
    PatientEntity? patientEntity = await _fetchPatientInfo(
      widget.appointment.patient,
    );

    // Dismiss loading indicator
    Navigator.pop(context);

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => CreatePrescriptionPage(
              appointment: widget.appointment,
              patient: patientEntity,
            ),
      ),
    );

    // If prescription was created successfully, refresh the prescription data
    if (result == true && widget.appointment.id != null) {
      // Fetch the updated prescription
      _fetchAppointmentPrescription();

      // Also refresh the appointment status
      _rendezVousBloc.add(
        FetchRendezVous(patientId: widget.appointment.patient),
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr('prescription.created_successfully'),
            style: GoogleFonts.raleway(),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // Fetch appointment rating and comment
  void _fetchAppointmentRating() {
    if (widget.appointment.id == null || widget.appointment.medecin == null)
      return;

    setState(() {
      _isLoadingRating = true;
    });

    // Fetch all ratings for the doctor
    _ratingBloc.add(GetDoctorRatings(widget.appointment.medecin!));
  }

  // Add this method to fetch prescription
  void _fetchAppointmentPrescription() {
    if (widget.appointment.id == null) return;

    setState(() {
      _isLoadingPrescription = true;
    });

    _prescriptionBloc.add(
      GetPrescriptionByConsultationId(consultationId: widget.appointment.id!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<RendezVousBloc>(create: (context) => _rendezVousBloc),
        BlocProvider<RatingBloc>(create: (context) => _ratingBloc),
        BlocProvider<PrescriptionBloc>(create: (context) => _prescriptionBloc),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<RendezVousBloc, RendezVousState>(
            listener: (context, state) {
              if (state is RendezVousStatusUpdated) {
                setState(() {
                  isCancelling = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      context.tr('appointments.appointment_cancelled'),
                      style: GoogleFonts.raleway(),
                    ),
                    backgroundColor: AppColors.primaryColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
                Navigator.pop(
                  context,
                  true,
                ); // Return true to indicate cancellation
              } else if (state is RendezVousError) {
                setState(() {
                  isCancelling = false;
                  isRescheduling = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message, style: GoogleFonts.raleway()),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
              // Reschedule states
              else if (state is AppointmentRescheduled) {
                setState(() {
                  isRescheduling = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      context.tr('reschedule.appointment_rescheduled_success'),
                      style: GoogleFonts.raleway(),
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
                Navigator.pop(context, true); // Return to refresh list
              } else if (state is RescheduleRequested) {
                setState(() {
                  isRescheduling = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      context.tr('reschedule.reschedule_request_sent'),
                      style: GoogleFonts.raleway(),
                    ),
                    backgroundColor: AppColors.primaryColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
                Navigator.pop(context, true);
              } else if (state is RescheduleApproved) {
                setState(() {
                  isRescheduling = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      context.tr('reschedule.reschedule_approved'),
                      style: GoogleFonts.raleway(),
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
                Navigator.pop(context, true);
              } else if (state is RescheduleRejected) {
                setState(() {
                  isRescheduling = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      context.tr('reschedule.reschedule_rejected'),
                      style: GoogleFonts.raleway(),
                    ),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
                Navigator.pop(context, true);
              } else if (state is RescheduleError) {
                setState(() {
                  isRescheduling = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message, style: GoogleFonts.raleway()),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
          ),
          BlocListener<RatingBloc, RatingState>(
            listener: (context, state) {
              if (state is PatientRatingChecked) {
                setState(() {
                  hasRatedAppointment = state.hasRated;
                });
              } else if (state is RatingSubmitted) {
                setState(() {
                  hasRatedAppointment = true;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      context.tr('rating.rating_submitted_successfully'),
                      style: GoogleFonts.raleway(),
                    ),
                    backgroundColor: AppColors.primaryColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              } else if (state is DoctorRatingState) {
                setState(() {
                  _isLoadingRating = false;
                  // Find the rating for this specific appointment
                  if (widget.appointment.id != null) {
                    _appointmentRating = state.ratings.firstWhere(
                      (rating) => rating.rendezVousId == widget.appointment.id,
                      orElse:
                          () => DoctorRatingEntity.create(
                            doctorId: '',
                            patientId: '',
                            rating: 0,
                            rendezVousId: '',
                          ),
                    );
                  }
                });
              } else if (state is RatingError) {
                setState(() {
                  _isLoadingRating = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message, style: GoogleFonts.raleway()),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
          ),
          // Add PrescriptionBloc listener
          BlocListener<PrescriptionBloc, PrescriptionState>(
            listener: (context, state) {
              if (state is PrescriptionLoaded) {
                setState(() {
                  _appointmentPrescription = state.prescription;
                  _isLoadingPrescription = false;
                });
              } else if (state is PrescriptionNotFound) {
                setState(() {
                  _appointmentPrescription = null;
                  _isLoadingPrescription = false;
                });
              } else if (state is PrescriptionError) {
                setState(() {
                  _isLoadingPrescription = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message, style: GoogleFonts.raleway()),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
          ),
        ],
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              context.tr("appointment_details"),
              style: GoogleFonts.raleway(
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
                color: Colors.white,
              ),
            ),
            backgroundColor: AppColors.primaryColor,
            elevation: 2,
            leading: IconButton(
              icon: const Icon(
                Icons.chevron_left,
                size: 28,
                color: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          floatingActionButton: null,
          body:
              isLoading
                  ? Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryColor,
                    ),
                  )
                  : SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Appointment card
                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                            child: Padding(
                              padding: EdgeInsets.all(20.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Status badge
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        context.tr("status") + ":",
                                        style: GoogleFonts.raleway(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16.w,
                                          vertical: 8.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(
                                            widget.appointment.status,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                        ),
                                        child: Text(
                                          _getStatusText(
                                            context,
                                            widget.appointment.status,
                                          ),
                                          style: GoogleFonts.raleway(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  Divider(height: 30.h, thickness: 1),

                                  // Doctor info
                                  Text(
                                    context.tr("doctor") + ":",
                                    style: GoogleFonts.raleway(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  SizedBox(height: 12.h),
                                  Row(
                                    children: [
                                      Container(
                                        height: 60.h,
                                        width: 60.w,
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryColor,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.primaryColor
                                                  .withOpacity(0.3),
                                              blurRadius: 10,
                                              offset: Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: InkWell(
                                          onTap:
                                              widget.appointment.medecin != null
                                                  ? _navigateToDoctorProfile
                                                  : null,
                                          child: Icon(
                                            Icons.person,
                                            color: Colors.white,
                                            size: 36.sp,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 16.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            InkWell(
                                              onTap:
                                                  widget.appointment.medecin !=
                                                          null
                                                      ? _navigateToDoctorProfile
                                                      : null,
                                              child: Text(
                                                widget
                                                            .appointment
                                                            .medecinName !=
                                                        null
                                                    ? "Dr. ${widget.appointment.medecinName}"
                                                    : context.tr('appointments.doctor_to_assign'),
                                                style: GoogleFonts.raleway(
                                                  fontSize: 18.sp,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ),
                                            SizedBox(height: 4.h),
                                            Text(
                                              widget
                                                      .appointment
                                                      .medecinSpeciality ??
                                                  context.tr('appointments.specialty_not_specified'),
                                              style: GoogleFonts.raleway(
                                                fontSize: 16.sp,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  Divider(height: 30.h, thickness: 1),

                                  // Patient info (shown only for doctors)
                                  if (currentUser?.role == 'medecin')
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              context.tr("patient") + ":",
                                              style: GoogleFonts.raleway(
                                                fontSize: 16.sp,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                            TextButton.icon(
                                              onPressed:
                                                  _navigateToPatientProfile,
                                              icon: Icon(
                                                Icons.person,
                                                size: 18.sp,
                                                color: AppColors.primaryColor,
                                              ),
                                              label: Text(
                                                context.tr('profile.view_profile'),
                                                style: GoogleFonts.raleway(
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.primaryColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 8.h),
                                        Text(
                                          widget.appointment.patientName ??
                                              context.tr('common.unknown_patient'),
                                          style: GoogleFonts.raleway(
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        SizedBox(height: 16.h),
                                      ],
                                    ),

                                  // Date and time information with better layout
                                  Text(
                                    context.tr("appointment_info") + ":",
                                    style: GoogleFonts.raleway(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  SizedBox(height: 12.h),
                                  Container(
                                    padding: EdgeInsets.all(16.w),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey[200]!,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today,
                                              color: AppColors.primaryColor,
                                              size: 24.sp,
                                            ),
                                            SizedBox(width: 12.w),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  context.tr('date'),
                                                  style: GoogleFonts.raleway(
                                                    fontSize: 14.sp,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                                Text(
                                                  DateFormat(
                                                    'EEEE d MMMM yyyy',
                                                    'fr_FR',
                                                  ).format(
                                                    widget
                                                        .appointment
                                                        .startDate,
                                                  ),
                                                  style: GoogleFonts.raleway(
                                                    fontSize: 16.sp,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 16.h),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.access_time,
                                              color: AppColors.primaryColor,
                                              size: 24.sp,
                                            ),
                                            SizedBox(width: 12.w),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  context.tr('time'),
                                                  style: GoogleFonts.raleway(
                                                    fontSize: 14.sp,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                                Text(
                                                  DateFormat('HH:mm').format(
                                                    widget
                                                        .appointment
                                                        .startDate,
                                                  ),
                                                  style: GoogleFonts.raleway(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16.sp,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                SizedBox(height: 4.h),
                                                Text(
                                                  context.tr("duration") +
                                                      ": ${_getAppointmentDuration(context)}",
                                                  style: GoogleFonts.raleway(
                                                    fontSize: 14.sp,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),

                                        // Add reason if available
                                        if (widget.appointment.motif != null &&
                                            widget
                                                .appointment
                                                .motif!
                                                .isNotEmpty) ...[
                                          SizedBox(height: 16.h),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Icon(
                                                Icons.subject,
                                                color: AppColors.primaryColor,
                                                size: 24.sp,
                                              ),
                                              SizedBox(width: 12.w),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      context.tr('reason'),
                                                      style:
                                                          GoogleFonts.raleway(
                                                            fontSize: 14.sp,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color:
                                                                Colors
                                                                    .grey[700],
                                                          ),
                                                    ),
                                                    Text(
                                                      widget.appointment.motif!,
                                                      style:
                                                          GoogleFonts.raleway(
                                                            fontSize: 16.sp,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],

                                        // Add notes if available
                                        if (widget.appointment.notes != null &&
                                            widget
                                                .appointment
                                                .notes!
                                                .isNotEmpty) ...[
                                          SizedBox(height: 16.h),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Icon(
                                                Icons.note,
                                                color: AppColors.primaryColor,
                                                size: 24.sp,
                                              ),
                                              SizedBox(width: 12.w),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      context.tr('notes'),
                                                      style:
                                                          GoogleFonts.raleway(
                                                            fontSize: 14.sp,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color:
                                                                Colors
                                                                    .grey[700],
                                                          ),
                                                    ),
                                                    Text(
                                                      widget.appointment.notes!,
                                                      style:
                                                          GoogleFonts.raleway(
                                                            fontSize: 16.sp,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],

                                        // Add consultation fee if available
                                        /* if (widget
                                                .appointment
                                                .consultationFee !=
                                            null) ...[
                                          SizedBox(height: 16.h),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.attach_money,
                                                color: AppColors.primaryColor,
                                                size: 24.sp,
                                              ),
                                              SizedBox(width: 12.w),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    context.tr('consultation_fee'),
                                                    style: GoogleFonts.raleway(
                                                      fontSize: 14.sp,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.grey[700],
                                                    ),
                                                  ),
                                                  Text(
                                                    widget
                                                        .appointment
                                                        .consultationFee
                                                        .toString(),
                                                    style: GoogleFonts.raleway(
                                                      fontSize: 16.sp,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ], */
                                      ],
                                    ),
                                  ),

                                  // Cancel button (only show if not cancelled and not in the past)
                                  if (widget.appointment.status !=
                                          "cancelled" &&
                                      !isAppointmentPast)
                                    Padding(
                                      padding: EdgeInsets.only(top: 24.h),
                                      child: Column(
                                        children: [
                                          // Reschedule button
                                          if (widget.appointment.status == "pending" ||
                                              widget.appointment.status == "accepted")
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton.icon(
                                                onPressed: isRescheduling
                                                    ? null
                                                    : _showRescheduleDialog,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppColors.primaryColor,
                                                  padding: EdgeInsets.symmetric(
                                                    vertical: 14.h,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(12),
                                                  ),
                                                  disabledBackgroundColor:
                                                      AppColors.primaryColor
                                                          .withOpacity(0.6),
                                                  elevation: 2,
                                                ),
                                                icon: isRescheduling
                                                    ? SizedBox(
                                                        height: 20.sp,
                                                        width: 20.sp,
                                                        child:
                                                            CircularProgressIndicator(
                                                          color: Colors.white,
                                                          strokeWidth: 2.w,
                                                        ),
                                                      )
                                                    : Icon(
                                                        Icons.schedule,
                                                        color: Colors.white,
                                                        size: 22.sp,
                                                      ),
                                                label: Text(
                                                  isRescheduling
                                                      ? context.tr('reschedule.processing')
                                                      : (widget.isDoctor ||
                                                              currentUser?.role ==
                                                                  'medecin')
                                                          ? context.tr('reschedule.reschedule_appointment')
                                                          : context.tr('reschedule.request_reschedule'),
                                                  style: GoogleFonts.raleway(
                                                    color: Colors.white,
                                                    fontSize: 16.sp,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          SizedBox(height: 12.h),
                                          // Cancel button
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton.icon(
                                              onPressed:
                                                  isCancelling
                                                      ? null
                                                      : _cancelAppointment,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                padding: EdgeInsets.symmetric(
                                                  vertical: 14.h,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                disabledBackgroundColor: Colors.red
                                                    .withOpacity(0.6),
                                                elevation: 2,
                                              ),
                                              icon:
                                                  isCancelling
                                                      ? SizedBox(
                                                        height: 20.sp,
                                                        width: 20.sp,
                                                        child:
                                                            CircularProgressIndicator(
                                                              color: Colors.white,
                                                              strokeWidth: 2.w,
                                                            ),
                                                      )
                                                      : Icon(
                                                        Icons.cancel_outlined,
                                                        color: Colors.white,
                                                        size: 22.sp,
                                                      ),
                                              label: Text(
                                                isCancelling
                                                    ? context.tr("cancelling")
                                                    : context.tr("cancel_appointment"),
                                                style: GoogleFonts.raleway(
                                                  color: Colors.white,
                                                  fontSize: 16.sp,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),

                          // Always show prescription section for doctors, or show only for completed/past appointments for patients
                          if (currentUser?.role == 'medecin' ||
                              widget.appointment.status == 'completed' ||
                              (widget.appointment.status == 'accepted' &&
                                  isAppointmentPast))
                            _buildPrescriptionSection(),

                          // Only show rating section when it's not a doctor view and appointment is completed
                          if (!widget.isDoctor &&
                              widget.appointment.status == 'completed' &&
                              isAppointmentPast &&
                              currentUser?.role == 'patient')
                            _buildRatingSection(),

                          // Show rating from patient when doctor is viewing a completed appointment
                          if (widget.isDoctor &&
                              widget.appointment.status == 'completed' &&
                              isAppointmentPast &&
                              currentUser?.role == 'medecin')
                            _buildDoctorViewRatingSection(),

                          // Add a prominent Add Prescription button for doctors
                          _buildAddPrescriptionButton(),
                        ],
                      ),
                    ),
                  ),
        ),
      ),
    );
  }

  // Extract rating section to a separate method
  Widget _buildRatingSection() {
    return Container(
      // Rating container implementation
      margin: EdgeInsets.only(top: 24.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('rating.rate_doctor'),
            style: GoogleFonts.raleway(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16.h),
          Center(
            child: RatingBar.builder(
              initialRating: _rating,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemSize: 36.sp,
              itemPadding: EdgeInsets.symmetric(horizontal: 4.w),
              itemBuilder:
                  (context, _) => Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: (rating) {
                setState(() {
                  _rating = rating;
                });
              },
            ),
          ),
          SizedBox(height: 16.h),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: context.tr('rating.add_comment_optional'),
              hintStyle: GoogleFonts.raleway(color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.primaryColor),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Center(
            child: ElevatedButton(
              onPressed: hasRatedAppointment ? null : _submitRating,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    hasRatedAppointment ? Colors.grey : AppColors.primaryColor,
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                hasRatedAppointment ? context.tr('rating.already_rated') : context.tr('rating.submit_rating'),
                style: GoogleFonts.raleway(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Section for doctors to view ratings left by patients
  Widget _buildDoctorViewRatingSection() {
    if (_isLoadingRating) {
      return Container(
        margin: EdgeInsets.only(top: 24.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(color: AppColors.primaryColor),
              SizedBox(height: 12.h),
              Text(
                context.tr('rating.loading_rating'),
                style: GoogleFonts.raleway(
                  fontSize: 14.sp,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.only(top: 24.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('rating.patient_rating'),
            style: GoogleFonts.raleway(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16.h),

          if (_appointmentRating != null) ...[
            Row(
              children: [
                Icon(Icons.person, size: 18.sp, color: Colors.grey[600]),
                SizedBox(width: 8.w),
                Text(
                  _appointmentRating!.patientName ?? context.tr('common.patient'),
                  style: GoogleFonts.raleway(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                ...List.generate(5, (index) {
                  return Icon(
                    index < _appointmentRating!.rating.floor()
                        ? Icons.star
                        : (index < _appointmentRating!.rating
                            ? Icons.star_half
                            : Icons.star_border),
                    color: Colors.amber,
                    size: 24.sp,
                  );
                }),
                SizedBox(width: 8.w),
                Text(
                  _appointmentRating!.rating.toString(),
                  style: GoogleFonts.raleway(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            if (_appointmentRating!.comment != null &&
                _appointmentRating!.comment!.isNotEmpty) ...[
              SizedBox(height: 16.h),
              Text(
                context.tr('rating.comment'),
                style: GoogleFonts.raleway(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Text(
                  _appointmentRating!.comment!,
                  style: GoogleFonts.raleway(
                    fontSize: 14.sp,
                    fontStyle: FontStyle.italic,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
            SizedBox(height: 8.h),
            Text(
              '${context.tr('rating.rated_on')} ${DateFormat('dd/MM/yyyy').format(_appointmentRating!.createdAt)}',
              style: GoogleFonts.raleway(
                fontSize: 12.sp,
                color: Colors.grey[600],
              ),
            ),
          ] else ...[
            Center(
              child: Column(
                children: [
                  Icon(Icons.star_border, size: 48.sp, color: Colors.grey[400]),
                  SizedBox(height: 16.h),
                  Text(
                    context.tr('rating.no_rating_yet'),
                    style: GoogleFonts.raleway(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    context.tr('rating.patient_not_rated_yet'),
                    style: GoogleFonts.raleway(
                      fontSize: 14.sp,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Add the prescription section widget
  Widget _buildPrescriptionSection() {
    return Container(
      margin: EdgeInsets.only(top: 24.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
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
                context.tr('prescription.title'),
                style: GoogleFonts.raleway(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          if (_isLoadingPrescription)
            Center(
              child: Column(
                children: [
                  CircularProgressIndicator(color: AppColors.primaryColor),
                  SizedBox(height: 8.h),
                  Text(
                    context.tr('common.loading'),
                    style: GoogleFonts.raleway(
                      fontSize: 14.sp,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            )
          else if (_appointmentPrescription != null)
            // Prescription exists
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => BlocProvider<PrescriptionBloc>.value(
                                value: _prescriptionBloc,
                                child: PrescriptionDetailsPage(
                                  prescription: _appointmentPrescription!,
                                  isDoctor: currentUser?.role == 'medecin',
                                ),
                              ),
                        ),
                      ).then((_) {
                        // Refresh prescription data when returning
                        _fetchAppointmentPrescription();
                      });
                    },
                    borderRadius: BorderRadius.circular(8.r),
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.medical_services,
                                color: AppColors.primaryColor,
                                size: 24.sp,
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Text(
                                  '${context.tr('prescription.prescription_from')} ${DateFormat('dd/MM/yyyy').format(_appointmentPrescription!.prescriptionDate)}',
                                  style: GoogleFonts.raleway(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Row(
                            children: [
                              Icon(
                                Icons.medication,
                                color: Colors.grey[600],
                                size: 16.sp,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                '${_appointmentPrescription!.medications.length} ${context.tr('prescription.medications').toLowerCase()}',
                                style: GoogleFonts.raleway(
                                  fontSize: 14.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          Divider(height: 16.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                context.tr('medical_records.view_details'),
                                style: GoogleFonts.raleway(
                                  fontSize: 14.sp,
                                  color: AppColors.primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: AppColors.primaryColor,
                                size: 20.sp,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            // No prescription
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.medical_information_outlined,
                    size: 48.sp,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    currentUser?.role == 'medecin'
                        ? context.tr('prescription.no_prescription_created')
                        : context.tr('prescription.no_prescription_available'),
                    style: GoogleFonts.raleway(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Add a prominent Add Prescription button for doctors
  Widget _buildAddPrescriptionButton() {
    // Only show for doctors and only for accepted or completed appointments
    if (currentUser?.role != 'medecin' ||
        (widget.appointment.status != "accepted" &&
            widget.appointment.status != "completed")) {
      return SizedBox.shrink();
    }

    // Check if current time is before the appointment time
    final now = DateTime.now();
    final isBeforeAppointment = now.isBefore(widget.appointment.startDate);

    return Container(
      margin: EdgeInsets.only(top: 24.h, bottom: 24.h),
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed:
            isBeforeAppointment
                ? null // Button is disabled if before appointment
                : (_appointmentPrescription == null
                    ? _createPrescription
                    : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => CreatePrescriptionPage(
                                appointment: widget.appointment,
                                existingPrescription: _appointmentPrescription,
                              ),
                        ),
                      ).then((result) {
                        if (result == true) {
                          // Refresh the prescription data
                          _fetchAppointmentPrescription();

                          // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                context.tr('prescription.updated_successfully'),
                                style: GoogleFonts.raleway(),
                              ),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        }
                      });
                    }),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isBeforeAppointment ? Colors.grey[300] : AppColors.primaryColor,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: isBeforeAppointment ? 0 : 2,
        ),
        icon: Icon(
          isBeforeAppointment
              ? Icons.access_time
              : (_appointmentPrescription == null ? Icons.add : Icons.edit),
          color: isBeforeAppointment ? Colors.grey[700] : Colors.white,
          size: 24.sp,
        ),
        label: Text(
          isBeforeAppointment
              ? context.tr('prescription.wait_until_appointment_ends')
              : (_appointmentPrescription == null
                  ? context.tr('prescription.create_prescription')
                  : context.tr('prescription.edit_prescription')),
          style: GoogleFonts.raleway(
            color: isBeforeAppointment ? Colors.grey[700] : Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
