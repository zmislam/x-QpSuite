import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../features/page_switcher/providers/managed_pages_provider.dart';
import '../models/content_models.dart';
import '../providers/content_provider.dart';

class ContentCalendarScreen extends StatefulWidget {
  const ContentCalendarScreen({super.key});

  @override
  State<ContentCalendarScreen> createState() => _ContentCalendarScreenState();
}

class _ContentCalendarScreenState extends State<ContentCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMonth());
  }

  void _loadMonth() {
    final pageId = context.read<ManagedPagesProvider>().activePageId;
    if (pageId == null) return;
    final month = DateFormat('yyyy-MM').format(_focusedDay);
    context.read<ContentProvider>().fetchCalendar(pageId, month);
  }

  @override
  Widget build(BuildContext context) {
    final content = context.watch<ContentProvider>();
    final days = content.calendarDays;

    return Scaffold(
      appBar: AppBar(title: const Text('Content Calendar')),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (d) =>
                _selectedDay != null && isSameDay(_selectedDay!, d),
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
            },
            onPageChanged: (focused) {
              _focusedDay = focused;
              _loadMonth();
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (ctx, day, _) {
                final key = DateFormat('yyyy-MM-dd').format(day);
                final dayData = days[key];
                if (dayData == null || dayData.totalCount == 0) return null;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (dayData.published.isNotEmpty)
                      _dot(AppColors.success),
                    if (dayData.scheduled.isNotEmpty)
                      _dot(AppColors.primary),
                  ],
                );
              },
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Divider(),
          // Day detail
          Expanded(child: _dayDetail(days)),
        ],
      ),
    );
  }

  Widget _dot(Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _dayDetail(Map<String, CalendarDay> days) {
    if (_selectedDay == null) {
      return const Center(
        child: Text('Select a day to see content'),
      );
    }

    final key = DateFormat('yyyy-MM-dd').format(_selectedDay!);
    final dayData = days[key];
    if (dayData == null || dayData.totalCount == 0) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('No content for this day'),
            const SizedBox(height: 8),
            Text(
              Formatters.formatDate(_selectedDay!),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    final allItems = [...dayData.published, ...dayData.scheduled];
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allItems.length,
      itemBuilder: (_, i) {
        final item = allItems[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              item.isPublished ? Icons.check_circle : Icons.schedule,
              color: item.isPublished ? AppColors.success : AppColors.primary,
            ),
            title: Text(
              item.displayText.isEmpty ? '(No text)' : item.displayText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              item.isPublished
                  ? 'Published ${Formatters.formatTime(item.createdAt)}'
                  : 'Scheduled ${item.scheduledFor != null ? Formatters.formatTime(item.scheduledFor!) : ''}',
            ),
            trailing: item.media.isNotEmpty
                ? const Icon(Icons.photo, size: 16)
                : null,
          ),
        );
      },
    );
  }
}
