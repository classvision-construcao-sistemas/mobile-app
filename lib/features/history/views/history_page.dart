import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../data/repositories/school_repository.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    final allRecords = context.watch<SchoolRepository>().history;
    final records = _selectedDate == null
        ? allRecords
        : allRecords
              .where(
                (record) => DateUtils.isSameDay(record.date, _selectedDate),
              )
              .toList();

    return ListView(
      key: const PageStorageKey('history'),
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
      children: [
        AppPageTitle(
          'Histórico',
          subtitle: 'Acompanhe as chamadas já realizadas.',
          trailing: IconButton.filledTonal(
            tooltip: 'Filtrar por data',
            onPressed: () async {
              final value = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now(),
                firstDate: DateTime(2025),
                lastDate: DateTime(2027),
              );
              if (value != null) setState(() => _selectedDate = value);
            },
            icon: const Icon(Icons.calendar_month_rounded),
          ),
        ),
        if (_selectedDate != null) ...[
          const SizedBox(height: 14),
          InputChip(
            avatar: const Icon(Icons.event_rounded, size: 18),
            label: Text(DateFormat('dd/MM/yyyy').format(_selectedDate!)),
            onDeleted: () => setState(() => _selectedDate = null),
          ),
        ],
        const SizedBox(height: 20),
        if (records.isEmpty)
          const AppCard(
            child: Center(child: Text('Nenhuma chamada nesta data.')),
          )
        else
          for (final record in records) ...[
            AppCard(
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.fact_check_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.className,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat("dd/MM/yyyy 'às' HH:mm")
                              .format(record.date),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${record.present} presentes',
                        style: const TextStyle(
                          color: AppColors.success,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${record.absent} ausentes',
                        style: const TextStyle(
                          color: Color(0xFFC72933),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 11),
          ],
      ],
    );
  }
}
