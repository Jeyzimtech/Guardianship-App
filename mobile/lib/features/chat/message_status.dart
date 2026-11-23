import 'package:flutter/material.dart';

/// Receipts are permanent: going offline never turns delivered back into sent.
class MessageStatus extends StatelessWidget {
  final Map message;
  final bool onDark;
  const MessageStatus({super.key, required this.message, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    final read = message['read_at'] != null;
    final delivered = read || message['delivered_at'] != null;
    final label = read
        ? 'Read'
        : delivered
        ? 'Delivered'
        : 'Sent';
    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        child: Icon(
          delivered ? Icons.done_all : Icons.done,
          size: 17,
          color: read
              ? (onDark ? const Color(0xFF70CDFF) : const Color(0xFF168BEE))
              : (onDark ? const Color(0xFFBDC3CC) : const Color(0xFF7B8290)),
        ),
      ),
    );
  }
}
