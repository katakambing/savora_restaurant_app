import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/booking_model.dart';
import '../../data/repositories/booking_repository.dart';
import '../../providers/auth_providers.dart';
import '../../providers/pending_booking_provider.dart';
import '../common/widgets/app_button.dart';
import '../common/widgets/error_dialog.dart';

class BookingConfirmationScreen extends ConsumerStatefulWidget {
  const BookingConfirmationScreen({super.key});

  @override
  ConsumerState<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState
    extends ConsumerState<BookingConfirmationScreen> {
  bool _isSubmitting = false;

  Future<void> _confirmAndPay() async {
    if (_isSubmitting) return;

    final data = ref.read(pendingBookingProvider);
    final user = ref.read(authProvider).valueOrNull;
    if (data == null || user == null) return;

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(bookingRepositoryProvider);
      final booking = BookingModel(
        id: '',
        userId: user.uid,
        userName: user.name,
        packageId: data.package.id,
        packageName: data.package.name,
        numGuests: data.numGuests,
        customFees: data.customFees,
        totalPrice: data.totalPrice,
        status: AppConstants.statusUpcoming,
        eventDate: data.eventDate,
        createdAt: DateTime.now(),
      );

      await repo.createBooking(booking);

      // Clear pending data
      ref.read(pendingBookingProvider.notifier).state = null;

      if (mounted) {
        // Pop back to home (past both confirmation and form screens)
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking confirmed successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) showErrorDialog(context, e);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(pendingBookingProvider);

    if (data == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Confirm Booking')),
        body: const Center(child: Text('No booking data found')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Review & Confirm')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            const Icon(Icons.receipt_long, size: 48, color: AppColors.navy),
            const SizedBox(height: 12),
            Text(
              'Booking Summary',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Please review your booking details before confirming',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),

            // Summary card
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.grey200),
              ),
              child: Column(
                children: [
                  // Package name header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: Text(
                      data.package.name,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Details
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _summaryRow(
                          Icons.calendar_today,
                          'Event Date',
                          DateFormat(AppConstants.dateFormatDisplay)
                              .format(data.eventDate),
                        ),
                        const SizedBox(height: 12),
                        _summaryRow(
                          Icons.people,
                          'Guests',
                          '${data.numGuests}',
                        ),
                        const SizedBox(height: 12),
                        _summaryRow(
                          Icons.restaurant,
                          'Base Price',
                          '${AppConstants.currencySymbol} ${data.package.basePrice.toStringAsFixed(2)} per guest',
                        ),

                        // Custom fees
                        if (data.customFees.isNotEmpty) ...[
                          const Divider(height: 24),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Custom Fees',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...data.customFees.map((f) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(f.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium),
                                    Text(
                                      '${AppConstants.currencySymbol} ${f.amount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Price breakdown
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.goldMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _priceLine(
                    'Base (${data.package.basePrice.toStringAsFixed(2)} × ${data.numGuests})',
                    '${AppConstants.currencySymbol} ${(data.package.basePrice * data.numGuests).toStringAsFixed(2)}',
                  ),
                  if (data.customFees.isNotEmpty)
                    _priceLine(
                      'Custom Fees',
                      '${AppConstants.currencySymbol} ${data.customFees.fold<double>(0, (sum, f) => sum + f.amount).toStringAsFixed(2)}',
                    ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navy,
                        ),
                      ),
                      Text(
                        '${AppConstants.currencySymbol} ${data.totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navy,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Confirm & Pay button
            AppButton.primary(
              label: 'Confirm & Pay ${AppConstants.currencySymbol} ${data.totalPrice.toStringAsFixed(2)}',
              onPressed: _isSubmitting ? null : _confirmAndPay,
              loading: _isSubmitting,
              icon: Icons.payment,
            ),
            const SizedBox(height: 12),

            // Back to edit
            AppButton.text(
              label: 'Edit Booking',
              onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
              icon: Icons.arrow_back,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.grey500),
        const SizedBox(width: 10),
        Text('$label: ', style: const TextStyle(color: AppColors.grey600)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _priceLine(String label, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.grey700)),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}