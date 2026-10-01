import 'package:flutter/material.dart';
import '../models/ticket_model.dart';
import '../utils/responsive.dart';

/// Shown when a ticket has more than 1 visitor and is Valid or
/// Partially Used. Staff enters how many people are entering RIGHT
/// NOW — this supports the case where a 7-person booking arrives as
/// two separate groups (e.g. 4 now, 3 later that day).
///
/// Returns the count via Navigator.pop(count), or null if cancelled.
class VisitorCountScreen extends StatefulWidget {
  final Ticket ticket;
  const VisitorCountScreen({super.key, required this.ticket});

  @override
  State<VisitorCountScreen> createState() => _VisitorCountScreenState();
}

class _VisitorCountScreenState extends State<VisitorCountScreen> {
  late int _count;

  @override
  void initState() {
    super.initState();
    // Default to the full remaining count — staff only needs to
    // change this when the group is splitting up.
    _count = widget.ticket.visitorsRemaining;
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final t = widget.ticket;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm visitor count'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: r.contentMaxWidth),
          child: Padding(
            padding: EdgeInsets.all(r.horizontalPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.ticketId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(t.ticketType, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _statBox('Total', '${t.totalVisitors}'),
                          _statBox('Already in', '${t.visitorsUsed}'),
                          _statBox('Remaining', '${t.visitorsRemaining}', highlight: true),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Text('How many are entering now?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.filled(
                      onPressed: _count > 1 ? () => setState(() => _count--) : null,
                      icon: const Icon(Icons.remove),
                    ),
                    Container(
                      width: 80,
                      alignment: Alignment.center,
                      child: Text('$_count',
                          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
                    ),
                    IconButton.filled(
                      onPressed: _count < t.visitorsRemaining ? () => setState(() => _count++) : null,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Maximum ${t.visitorsRemaining} can enter on this ticket right now',
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, _count),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('Admit $_count ${_count == 1 ? "visitor" : "visitors"}'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statBox(String label, String value, {bool highlight = false}) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
              fontSize: 22, 
              fontWeight: FontWeight.bold,
              color: highlight ? Colors.indigo : Colors.black87,
            )),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ],
    );
  }
}