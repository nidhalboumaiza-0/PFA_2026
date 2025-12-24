import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medical_app/core/l10n/translator.dart';
import 'package:medical_app/core/utils/app_colors.dart';
import 'package:medical_app/core/widgets/common/common_widgets.dart';
import 'package:medical_app/features/referral/domain/entities/referral_entity.dart';
import 'package:medical_app/features/referral/presentation/bloc/referral_bloc.dart';
import 'package:medical_app/features/referral/presentation/pages/referral_details_page.dart';
import 'package:medical_app/features/referral/presentation/pages/create_referral_page.dart';
import 'package:medical_app/injection_container.dart';
import 'package:intl/intl.dart';

class DoctorReferralsPage extends StatefulWidget {
  const DoctorReferralsPage({super.key});

  @override
  State<DoctorReferralsPage> createState() => _DoctorReferralsPageState();
}

class _DoctorReferralsPageState extends State<DoctorReferralsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _loadReferrals();
    }
  }

  void _loadReferrals() {
    final bloc = context.read<ReferralBloc>();
    if (_tabController.index == 0) {
      bloc.add(LoadSentReferralsEvent(status: _selectedStatus));
    } else {
      bloc.add(LoadReceivedReferralsEvent(status: _selectedStatus));
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ReferralBloc>()..add(const LoadSentReferralsEvent()),
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('referral.title')),
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: context.tr('referral.sent_referrals')),
              Tab(text: context.tr('referral.received_referrals')),
            ],
          ),
          actions: [
            PopupMenuButton<String?>(
              icon: const Icon(Icons.filter_list),
              tooltip: context.tr('referral.filter_by_status'),
              onSelected: (value) {
                setState(() => _selectedStatus = value);
                _loadReferrals();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: null,
                  child: Text(context.tr('referral.all')),
                ),
                PopupMenuItem(
                  value: 'En attente',
                  child: Text(context.tr('referral.pending')),
                ),
                PopupMenuItem(
                  value: 'Accepté',
                  child: Text(context.tr('referral.accepted')),
                ),
                PopupMenuItem(
                  value: 'En cours',
                  child: Text(context.tr('referral.in_progress')),
                ),
                PopupMenuItem(
                  value: 'Terminé',
                  child: Text(context.tr('referral.completed')),
                ),
                PopupMenuItem(
                  value: 'Annulé',
                  child: Text(context.tr('referral.cancelled')),
                ),
              ],
            ),
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _SentReferralsTab(selectedStatus: _selectedStatus),
            _ReceivedReferralsTab(selectedStatus: _selectedStatus),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CreateReferralPage(),
              ),
            ).then((_) => _loadReferrals());
          },
          icon: const Icon(Icons.add),
          label: Text(context.tr('referral.new_referral')),
        ),
      ),
    );
  }
}

class _SentReferralsTab extends StatelessWidget {
  final String? selectedStatus;

  const _SentReferralsTab({this.selectedStatus});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReferralBloc, ReferralState>(
      builder: (context, state) {
        if (state is ReferralLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ReferralError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(state.message),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context
                      .read<ReferralBloc>()
                      .add(LoadSentReferralsEvent(status: selectedStatus)),
                  child: Text(context.tr('common.retry')),
                ),
              ],
            ),
          );
        }

        if (state is SentReferralsLoaded) {
          if (state.referrals.isEmpty) {
            return EmptyStateWidget(
              message: context.tr('referral.no_sent_referrals'),
              useResponsiveSizing: false,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context
                  .read<ReferralBloc>()
                  .add(LoadSentReferralsEvent(status: selectedStatus));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.referrals.length,
              itemBuilder: (context, index) {
                return _ReferralCard(
                  referral: state.referrals[index],
                  isSent: true,
                );
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _ReceivedReferralsTab extends StatelessWidget {
  final String? selectedStatus;

  const _ReceivedReferralsTab({this.selectedStatus});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReferralBloc, ReferralState>(
      builder: (context, state) {
        if (state is ReferralLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ReferralError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(state.message),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context
                      .read<ReferralBloc>()
                      .add(LoadReceivedReferralsEvent(status: selectedStatus)),
                  child: Text(context.tr('common.retry')),
                ),
              ],
            ),
          );
        }

        if (state is ReceivedReferralsLoaded) {
          if (state.referrals.isEmpty) {
            return EmptyStateWidget(
              message: context.tr('referral.no_received_referrals'),
              useResponsiveSizing: false,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context
                  .read<ReferralBloc>()
                  .add(LoadReceivedReferralsEvent(status: selectedStatus));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.referrals.length,
              itemBuilder: (context, index) {
                return _ReferralCard(
                  referral: state.referrals[index],
                  isSent: false,
                );
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _ReferralCard extends StatelessWidget {
  final ReferralEntity referral;
  final bool isSent;

  const _ReferralCard({
    required this.referral,
    required this.isSent,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<ReferralBloc>(),
                child: ReferralDetailsPage(referral: referral, isSent: isSent),
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSent
                              ? referral.targetDoctorName ?? context.tr('referral.target_doctor')
                              : referral.referringDoctorName ?? context.tr('referral.referring_doctor'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          referral.patientName ?? context.tr('referral.patient'),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusChip(status: referral.status),
                ],
              ),
              const SizedBox(height: 12),
              if (referral.specialty != null) ...[
                Row(
                  children: [
                    Icon(Icons.medical_services_outlined,
                        size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      referral.specialty!,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Icon(Icons.description_outlined,
                      size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      referral.reason,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    referral.referralDate != null
                        ? DateFormat('dd/MM/yyyy').format(referral.referralDate!)
                        : '-',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  if (referral.urgency != 'routine') ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: referral.urgency == 'emergency'
                            ? Colors.red[100]
                            : Colors.orange[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        referral.urgency == 'emergency'
                            ? context.tr('referral.emergency')
                            : context.tr('referral.urgent'),
                        style: TextStyle(
                          color: referral.urgency == 'emergency'
                              ? Colors.red[700]
                              : Colors.orange[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'en attente':
      case 'pending':
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[700]!;
        break;
      case 'accepté':
      case 'accepted':
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[700]!;
        break;
      case 'refusé':
      case 'rejected':
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[700]!;
        break;
      case 'en cours':
      case 'in_progress':
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[700]!;
        break;
      case 'terminé':
      case 'completed':
        backgroundColor = AppColors.primaryColor.withOpacity(0.1);
        textColor = AppColors.primaryColor;
        break;
      case 'annulé':
      case 'cancelled':
        backgroundColor = Colors.grey[200]!;
        textColor = Colors.grey[700]!;
        break;
      default:
        backgroundColor = Colors.grey[200]!;
        textColor = Colors.grey[700]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
