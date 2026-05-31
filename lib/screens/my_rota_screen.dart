import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../core/app_colors.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';



class MyRotaScreen extends StatefulWidget {
  const MyRotaScreen({super.key});

  @override
  State<MyRotaScreen> createState() => _MyRotaScreenState();
}

class _MyRotaScreenState extends State<MyRotaScreen> {
  CalendarFormat calendarFormat = CalendarFormat.month;
  bool isLoading = true;
  List shifts = [];
  DateTime focusedDay = DateTime.now();
  DateTime selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    fetchRota();
  }

  Future<void> fetchRota() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/my-rota'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          shifts = data['shifts'];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  List getShiftsForDay(DateTime day) {
    return shifts.where((shift) {
      final shiftDate = DateTime.parse(shift['shift_date']);
      return shiftDate.year == day.year &&
          shiftDate.month == day.month &&
          shiftDate.day == day.day;
    }).toList();
  }

  Color shiftColor(String type) {
    switch (type) {
      case 'morning':
        return Colors.blue;
      case 'evening':
        return Colors.orange;
      case 'night':
        return Colors.purple;
      case 'split':
        return Colors.pink;
      case 'holiday':
        return AppColors.success;
      case 'sick':
        return AppColors.danger;
      case 'day_off':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedShifts = getShiftsForDay(selectedDay);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Rota'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2024, 1, 1),
                    lastDay: DateTime.utc(2035, 12, 31),
                    focusedDay: focusedDay,
                    calendarFormat: calendarFormat,
                    availableCalendarFormats: const {
                      CalendarFormat.month: 'Month',
                    },
                    rowHeight: MediaQuery.of(context).size.width < 400 ? 44 : 54,
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                    ),
                    selectedDayPredicate: (day) => isSameDay(selectedDay, day),
                    onDaySelected: (selected, focused) {
                      setState(() {
                        selectedDay = selected;
                        focusedDay = focused;
                      });
                    },
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    eventLoader: (day) => getShiftsForDay(day),
                  ),
                ),
                Expanded(
                  child: selectedShifts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_available, size: 56, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                'No shifts for selected date',
                                style: TextStyle(color: AppColors.grey, fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: selectedShifts.length,
                          itemBuilder: (context, index) {
                            final shift = selectedShifts[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: shiftColor(shift['shift_type']).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.schedule,
                                      color: shiftColor(shift['shift_type']),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          (shift['shift_type'] ?? '').replaceAll('_', ' ').toUpperCase(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: shiftColor(shift['shift_type']),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          shift['start_time'] != null
                                              ? '${shift['start_time']} - ${shift['end_time']}'
                                              : 'No shift time',
                                          style: TextStyle(color: AppColors.grey),
                                        ),
                                        if (shift['notes'] != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            shift['notes'],
                                            style: TextStyle(color: AppColors.grey, fontSize: 12),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}