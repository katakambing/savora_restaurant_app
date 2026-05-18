import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a customer's booking for a menu package.
/// Stored in Firestore under `bookings/{bookingId}`.
///
/// Price formula: totalPrice = (basePrice × numGuests) + sum(customFees)
///
/// Status lifecycle: upcoming → past (auto when eventDate passes)
///                   upcoming → cancelled (user action)
class BookingModel {
  final String id;
  final String userId;
  final String userName;
  final String packageId;
  final String packageName;
  final int numGuests;
  final List<CustomFee> customFees;
  final double totalPrice;
  final String status; // upcoming, past, cancelled
  final DateTime eventDate;
  final DateTime createdAt;

  const BookingModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.packageId,
    required this.packageName,
    required this.numGuests,
    this.customFees = const [],
    required this.totalPrice,
    required this.status,
    required this.eventDate,
    required this.createdAt,
  });

  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BookingModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? '',
      packageId: data['packageId'] as String? ?? '',
      packageName: data['packageName'] as String? ?? '',
      numGuests: data['numGuests'] as int? ?? 1,
      customFees: (data['customFees'] as List<dynamic>?)
              ?.map((f) => CustomFee.fromJson(f as Map<String, dynamic>))
              .toList() ??
          [],
      totalPrice: (data['totalPrice'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] as String? ?? 'upcoming',
      eventDate: _parseTimestamp(data['eventDate']),
      createdAt: _parseTimestamp(data['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'packageId': packageId,
      'packageName': packageName,
      'numGuests': numGuests,
      'customFees': customFees.map((f) => f.toJson()).toList(),
      'totalPrice': totalPrice,
      'status': status,
      'eventDate': Timestamp.fromDate(eventDate),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  BookingModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? packageId,
    String? packageName,
    int? numGuests,
    List<CustomFee>? customFees,
    double? totalPrice,
    String? status,
    DateTime? eventDate,
    DateTime? createdAt,
  }) {
    return BookingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      packageId: packageId ?? this.packageId,
      packageName: packageName ?? this.packageName,
      numGuests: numGuests ?? this.numGuests,
      customFees: customFees ?? this.customFees,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      eventDate: eventDate ?? this.eventDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  @override
  String toString() =>
      'BookingModel(id: $id, package: $packageName, guests: $numGuests, total: $totalPrice)';
}

/// A custom fee attached to a booking (e.g., "Service charge", "Decoration fee").
class CustomFee {
  final String name;
  final double amount;

  const CustomFee({required this.name, required this.amount});

  factory CustomFee.fromJson(Map<String, dynamic> json) {
    return CustomFee(
      name: json['name'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'amount': amount};

  @override
  String toString() => 'CustomFee($name: $amount)';
}