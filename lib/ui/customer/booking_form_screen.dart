import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/booking_model.dart';
import '../../data/models/menu_package_model.dart';
import '../../data/repositories/booking_repository.dart';
import '../../providers/auth_providers.dart';
import '../../providers/menu_providers.dart';
import '../common/widgets/app_button.dart';
import '../common/widgets/error_dialog.dart';

class BookingFormScreen extends ConsumerStatefulWidget {
  final String packageId;

  const BookingFormScreen({super.key, required this.packageId});

  @override
  ConsumerState<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends ConsumerState<BookingFormScreen> {
  int _numGuests = 1;
  DateTime _eventDate = DateTime.now().add(const Duration(days: 1));
  final List<CustomFee> _customFees = [];
  bool _isLoading = false;

  // Controllers for adding new custom fee
  final _feeNameController = TextEditingController();
  final _feeAmountController = TextEditingController();

  @override
  void dispose() {
    _feeNameController.dispose();
    _feeAmountController.dispose();
    super.dispose();
  }

  double _calculateTotal(MenuPackageModel package) {
    return BookingRepository.calculateTotal(
      package.basePrice, _numGuests, _customFees);
  }

  void _addCustomFee() {
    final name = _feeNameController.text.trim();
    final amount = double.tryParse(_feeAmountController.text) ?? 0;
    if (name.isEmpty || amount <= 0) return;

    setState(() {
      _customFees.add(CustomFee(name: name, amount: amount));
      _feeNameController.clear();
      _feeAmountController.clear();
    });
  }

  Future<void> _submit(MenuPackageModel package) async {
    if (_isLoading) return; // prevent double-tap race condition
    final user = ref.read(authProvider).valueOrNull;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(bookingRepositoryProvider);
      final booking = BookingModel(
        id: '',
        userId: user.uid,
        userName: user.name,
        packageId: package.id,
        packageName: package.name,
        numGuests: _numGuests,
        customFees: _customFees,
        totalPrice: _calculateTotal(package),
        status: AppConstants.statusUpcoming,
        eventDate: _eventDate,
        createdAt: DateTime.now(),
      );

      await repo.createBooking(booking);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking confirmed!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) showErrorDialog(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final packageAsync = ref.watch(menuPackageByIdProvider(widget.packageId));

    return Scaffold(
      appBar: AppBar(title: const Text('Book Package')),
      body: packageAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.navy)),
        error: (error, stack) => const Center(child: Text('Package not found')),
        data: (package) {
          if (package == null) {
            return const Center(child: Text('Package not found'));
          }

          final total = _calculateTotal(package);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Package summary card
                Card(
                  color: AppColors.goldMuted,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(package.name, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text(
                          '${AppConstants.currencySymbol} ${package.basePrice.toStringAsFixed(2)} per guest',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Event date
                Text('Event Date', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _eventDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setState(() => _eventDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.grey300),
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.white,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: AppColors.grey500),
                        const SizedBox(width: 12),
                        Text(DateFormat(AppConstants.dateFormatDisplay).format(_eventDate)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Guest count
                Text('Number of Guests', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.grey300),
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.white,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: _numGuests > 1
                            ? () => setState(() => _numGuests--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text(
                        '$_numGuests',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      IconButton(
                        onPressed: () => setState(() => _numGuests++),
                        icon: const Icon(Icons.add_circle_outline, color: AppColors.navy),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Custom fees
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Custom Fees', style: Theme.of(context).textTheme.titleMedium),
                    Text('(optional)', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 8),

                // List of added fees
                ..._customFees.asMap().entries.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(child: Text(entry.value.name)),
                          Text(
                            '${AppConstants.currencySymbol} ${entry.value.amount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18, color: AppColors.error),
                            onPressed: () => setState(() => _customFees.removeAt(entry.key)),
                          ),
                        ],
                      ),
                    )),

                // Add fee row
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _feeNameController,
                        decoration: const InputDecoration(
                          hintText: 'Fee name',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _feeAmountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'Amount',
                          isDense: true,
                          prefixText: '${AppConstants.currencySymbol} ',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: AppColors.gold),
                      onPressed: _addCustomFee,
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Price breakdown
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _priceRow('Base price × $_numGuests guests',
                          '${AppConstants.currencySymbol} ${(package.basePrice * _numGuests).toStringAsFixed(2)}'),
                      if (_customFees.isNotEmpty) ...[
                        const Divider(color: AppColors.navyLight, height: 16),
                        ..._customFees.map((f) => _priceRow(
                            f.name,
                            '${AppConstants.currencySymbol} ${f.amount.toStringAsFixed(2)}')),
                      ],
                      const Divider(color: AppColors.navyLight, height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total', style: TextStyle(
                            color: AppColors.gold, fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(
                            '${AppConstants.currencySymbol} ${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: AppColors.gold, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Confirm button
                AppButton.primary(
                  label: 'Confirm Booking',
                  onPressed: _isLoading ? null : () => _submit(package),
                  loading: _isLoading,
                  icon: Icons.check_circle,
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _priceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.grey300, fontSize: 13)),
          Text(value, style: const TextStyle(color: AppColors.white, fontSize: 13)),
        ],
      ),
    );
  }
}