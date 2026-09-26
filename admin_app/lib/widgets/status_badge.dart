import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool isPayment;

  const StatusBadge({
    super.key,
    required this.status,
    this.isPayment = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label = status.toUpperCase();

    if (isPayment) {
      if (status == 'pagado') {
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF047857);
        label = 'PAGADO';
      } else {
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        label = 'PENDIENTE';
      }
    } else {
      switch (status) {
        case 'confirmada':
          bg = const Color(0xFFD1FAE5);
          fg = const Color(0xFF047857);
          label = 'CONFIRMADA';
          break;
        case 'completada':
          bg = const Color(0xFFEFF6FF);
          fg = const Color(0xFF1D4ED8);
          label = 'COMPLETADA';
          break;
        case 'cancelada':
          bg = const Color(0xFFFFE4E6);
          fg = const Color(0xFFBE123C);
          label = 'CANCELADA';
          break;
        case 'pendiente':
        default:
          bg = const Color(0xFFFEF3C7);
          fg = const Color(0xFFB45309);
          label = 'PENDIENTE';
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
