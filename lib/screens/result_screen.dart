import 'package:flutter/material.dart';
import '../models/ticket_model.dart';
import '../utils/responsive.dart';

class ResultScreen extends StatelessWidget {
  final VerifyResult result;
  const ResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    late Color color;
    late IconData icon;
    late String title;
    late String subtitle;

    switch (result.status) {
      case VerifyStatus.valid:
        color = Colors.green;
        icon = Icons.check_circle;
        title = 'Entry allowed';
        subtitle = result.visitorsEnteredThisScan != null
            ? '${result.visitorsEnteredThisScan} visitor(s) admitted — ticket fully used'
            : 'Ticket verified';
        break;
      case VerifyStatus.partiallyUsed:
        color = Colors.blue;
        icon = Icons.groups;
        title = 'Partial entry recorded';
        subtitle = result.ticket != null
            ? '${result.visitorsEnteredThisScan} admitted now — ${result.ticket!.visitorsRemaining} of ${result.ticket!.totalVisitors} remaining'
            : 'Some visitors admitted';
        break;
      case VerifyStatus.alreadyUsed:
        color = Colors.orange;
        icon = Icons.error;
        title = 'Already fully used';
        subtitle = 'All ${result.ticket?.totalVisitors ?? "-"} visitors on this ticket have entered';
        break;
      case VerifyStatus.invalid:
        color = Colors.red;
        icon = Icons.cancel;
        title = 'Invalid ticket';
        subtitle = 'This ticket id was not found or is cancelled';
        break;
      case VerifyStatus.error:
        color = Colors.red;
        icon = Icons.warning;
        title = 'Verification error';
        subtitle = 'Please try scanning again';
        break;
    }

    final r = Responsive(context);

    return Scaffold(
      backgroundColor: color.withOpacity(0.08),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: r.contentMaxWidth),
            child: Padding(
              padding: EdgeInsets.all(r.isPhone ? 24 : 36),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: r.isPhone ? 90 : 110),
                  const SizedBox(height: 20),
                  Text(title,
                      style: TextStyle(fontSize: 22 * r.baseFontScale, fontWeight: FontWeight.bold, color: color),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(subtitle,
                      style: TextStyle(fontSize: 14 * r.baseFontScale, color: Colors.black54),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text(
                    result.wasOffline ? 'Verified offline' : 'Verified online',
                    style: const TextStyle(fontSize: 11, color: Colors.black38),
                  ),
                  const SizedBox(height: 28),
                  if (result.ticket != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _row('Ticket id', result.ticket!.ticketId),
                          _row('Type', result.ticket!.ticketType),
                          _row('Valid date', result.ticket!.validDate),
                          _row('Total visitors', '${result.ticket!.totalVisitors}'),
                          _row('Entered so far', '${result.ticket!.visitorsUsed}'),
                        ],
                      ),
                    ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Scan next'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }
}