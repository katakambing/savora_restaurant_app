import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/booking_model.dart';
import '../data/models/menu_package_model.dart';

/// Holds the booking details temporarily between the form screen
/// and the confirmation screen. Cleared after booking is submitted.
class PendingBookingData {
  final MenuPackageModel package;
  final int numGuests;
  final DateTime eventDate;
  final List<CustomFee> customFees;
  final double totalPrice;

  const PendingBookingData({
    required this.package,
    required this.numGuests,
    required this.eventDate,
    required this.customFees,
    required this.totalPrice,
  });
}

final pendingBookingProvider = StateProvider<PendingBookingData?>((ref) => null);