import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../models/booking_model.dart';

class BookingRepository {
  final FirebaseFirestore _firestore;

  BookingRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _bookingsRef =>
      _firestore.collection(AppConstants.bookingsCollection);

  // ── Create ──

  Future<String> createBooking(BookingModel booking) async {
    try {
      final docRef = await _bookingsRef.add(booking.toJson());
      return docRef.id;
    } on FirebaseException catch (e) {
      throw _mapError(e);
    }
  }

  // ── Read ──

  /// All bookings for a specific user.
  Stream<List<BookingModel>> watchUserBookings(String userId) {
    return _bookingsRef
        .where('userId', isEqualTo: userId)
        .orderBy('eventDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BookingModel.fromFirestore(doc))
            .toList());
  }

  /// All bookings (admin view).
  Stream<List<BookingModel>> watchAllBookings() {
    return _bookingsRef
        .orderBy('eventDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BookingModel.fromFirestore(doc))
            .toList());
  }

  Future<BookingModel?> getBooking(String id) async {
    try {
      final doc = await _bookingsRef.doc(id).get();
      if (!doc.exists) return null;
      return BookingModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw _mapError(e);
    }
  }

  // ── Update ──

  /// Update guest count (recalculate price in caller, then pass updated model).
  Future<void> updateBooking(BookingModel booking) async {
    try {
      await _bookingsRef.doc(booking.id).update(booking.toJson());
    } on FirebaseException catch (e) {
      throw _mapError(e);
    }
  }

  /// Cancel a booking — only allowed if status is "upcoming".
  Future<void> cancelBooking(String id) async {
    try {
      await _bookingsRef.doc(id).update({'status': 'cancelled'});
    } on FirebaseException catch (e) {
      throw _mapError(e);
    }
  }

  /// Admin: update booking status directly.
  Future<void> updateStatus(String id, String status) async {
    try {
      await _bookingsRef.doc(id).update({'status': status});
    } on FirebaseException catch (e) {
      throw _mapError(e);
    }
  }

  /// Price calculator: basePrice × numGuests + sum(customFees)
  static double calculateTotal(
      double basePrice, int numGuests, List<CustomFee> fees) {
    final feeTotal = fees.fold<double>(0, (subtotal, f) => subtotal + f.amount);
    return (basePrice * numGuests) + feeTotal;
  }

  AppException _mapError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return AppException.permissionDenied();
      default:
        return AppException.unknown(e);
    }
  }
}

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository();
});