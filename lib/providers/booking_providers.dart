import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../data/models/booking_model.dart';
import '../data/repositories/booking_repository.dart';
import 'auth_providers.dart';

/// All bookings for the current user, split by status.
final userBookingsProvider = StreamProvider<List<BookingModel>>((ref) {
  final user = ref.watch(authProvider).valueOrNull;
  if (user == null) return const Stream.empty();

  final repo = ref.read(bookingRepositoryProvider);
  return repo.watchUserBookings(user.uid);
});

/// Upcoming bookings (eventDate in the future, status == 'upcoming').
final upcomingBookingsProvider = Provider<AsyncValue<List<BookingModel>>>((ref) {
  return ref.watch(userBookingsProvider).whenData((bookings) {
    final now = DateTime.now();
    return bookings.where((b) =>
        b.status == AppConstants.statusUpcoming &&
        b.eventDate.isAfter(now)).toList();
  });
});

/// Past bookings (status == 'past' OR eventDate has passed with status 'upcoming').
final pastBookingsProvider = Provider<AsyncValue<List<BookingModel>>>((ref) {
  return ref.watch(userBookingsProvider).whenData((bookings) {
    final now = DateTime.now();
    return bookings.where((b) =>
        b.status == AppConstants.statusPast ||
        (b.status == AppConstants.statusUpcoming && b.eventDate.isBefore(now))).toList();
  });
});

/// Cancelled bookings.
final cancelledBookingsProvider = Provider<AsyncValue<List<BookingModel>>>((ref) {
  return ref.watch(userBookingsProvider).whenData((bookings) {
    return bookings.where((b) => b.status == AppConstants.statusCancelled).toList();
  });
});

/// All bookings for admin view.
final allBookingsProvider = StreamProvider<List<BookingModel>>((ref) {
  final repo = ref.read(bookingRepositoryProvider);
  return repo.watchAllBookings();
});