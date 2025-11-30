import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mooves/constants/colors.dart';
import 'package:mooves/models/training_entry.dart';
import 'package:qr_flutter/qr_flutter.dart';

class RewardQrScreen extends StatelessWidget {
  const RewardQrScreen({super.key, required this.entry});

  final TrainingEntry entry;

  @override
  Widget build(BuildContext context) {
    final payload = entry.toQrPayload();
    final formattedDate = DateFormat.yMMMMd().format(entry.date);

    return Scaffold(
      backgroundColor: AppColors.backgroundPink, // Pink background
      appBar: AppBar(
        backgroundColor: AppColors.pinkCard, // Pink app bar
        elevation: 0,
        title: const Text(
          'QR Reward',
          style: TextStyle(
            color: AppColors.textOnPink,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textOnPink),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.pinkCard, // Pink card background
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.accentCoral.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: const Text(
                'Goal reached! Show this QR code to claim your reward.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textOnPink,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white, // White for QR code contrast
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentCoral.withOpacity(0.2),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: payload,
                  version: QrVersions.auto,
                  size: 240,
                  gapless: false,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.pinkCard, // Pink card for details
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textOnPink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (entry.durationMinutes != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${entry.durationMinutes} minutes',
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      entry.notes!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textOnPink,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: payload));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reward payload copied')),
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy reward data'),
            ),
          ],
        ),
      ),
    );
  }
}
