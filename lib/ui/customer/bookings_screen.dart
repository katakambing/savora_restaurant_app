import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/booking_model.dart';
import '../../providers/booking_providers.dart';

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'Past'),
              Tab(text: 'Cancelled'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _BookingList(provider: upcomingBookingsProvider, emptyLabel: 'No upcoming bookings'),
                _BookingList(provider: pastBookingsProvider, emptyLabel: 'No past bookings'),
                _BookingList(provider: cancelledBookingsProvider, emptyLabel: 'No cancelled bookings'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingList extends ConsumerWidget {
  final ProviderBase<AsyncValue<List<BookingModel>>> provider;
  final String emptyLabel;

  const _BookingList({required this.provider, required this.emptyLabel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(provider);

    return bookingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.navy)),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (bookings) {
        if (bookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(emptyLabel, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: bookings.length,
          itemBuilder: (context, index) => _BookingCard(booking: bookings[index]),
        );
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;

  const _BookingCard({required this.booking});

  Color get _statusColor {
    switch (booking.status) {
      case 'upcoming':
        return AppColors.info;
      case 'past':
        return AppColors.grey500;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.grey500;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/customer/bookings/${booking.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      booking.packageName,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      booking.status[0].toUpperCase() + booking.status.substring(1),
                      style: TextStyle(color: _statusColor, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: AppColors.grey500),
                  const SizedBox(width: 6),
                  Text(DateFormat(AppConstants.dateFormatDisplay).format(booking.eventDate)),
                  const SizedBox(width: 16),
                  const Icon(Icons.people, size: 16, color: AppColors.grey500),
                  const SizedBox(width: 6),
                  Text('${booking.numGuests} guests'),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${AppConstants.currencySymbol} ${booking.totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}