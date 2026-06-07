import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';

class HkMyRoomsScreen extends StatefulWidget {
  const HkMyRoomsScreen({super.key});

  @override
  State<HkMyRoomsScreen> createState() => _HkMyRoomsScreenState();
}

class _HkMyRoomsScreenState extends State<HkMyRoomsScreen> {
  bool isLoading = true;
  bool isUpdating = false;

  String token = '';
  List rooms = [];
  String selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    loadRooms();
  }

  Future<void> loadRooms() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token') ?? '';

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/hk/my-rooms'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.body.trim().isEmpty) {
        setState(() => isLoading = false);
        showMessage('Server returned empty response.');
        return;
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          rooms = data['data'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        showMessage(data['message'] ?? 'Failed to load rooms');
      }
    } catch (e) {
      setState(() => isLoading = false);
      showMessage('Failed to load rooms.');
    }
  }

  Future<void> updateRoomStatus(int allocationId, String action) async {
    if (isUpdating) return;

    setState(() => isUpdating = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/hk/rooms/$allocationId/$action'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.body.trim().isEmpty) {
        showMessage('Server returned empty response.');
        return;
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        showMessage(data['message'] ?? 'Room updated successfully');
        await loadRooms();
      } else {
        showMessage(data['message'] ?? 'Failed to update room');
      }
    } catch (e) {
      showMessage('Connection error. Please check your server.');
    }

    if (mounted) {
      setState(() => isUpdating = false);
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String normalize(dynamic value) {
    return (value ?? '')
        .toString()
        .toLowerCase()
        .trim()
        .replaceAll(' ', '_')
        .replaceAll('-', '_');
  }

  bool isDepartureGroup(dynamic status) {
    final value = normalize(status);

    return value == 'departure' ||
        value == 'carry_forward' ||
        value == 'room_move';
  }

  bool isStayover(dynamic status) {
    final value = normalize(status);

    return value == 'stay' || value == 'stayover';
  }

  bool isPendingLike(dynamic status) {
    final value = normalize(status);

    return value == 'pending' ||
        value == 'assigned' ||
        value == '' ||
        value == 'null';
  }

  List get filteredRooms {
    if (selectedStatus == 'all') return rooms;

    if (selectedStatus == 'departure') {
      return rooms.where((room) {
        return isDepartureGroup(room['room_status']);
      }).toList();
    }

    if (selectedStatus == 'stayover') {
      return rooms.where((room) {
        return isStayover(room['room_status']);
      }).toList();
    }

    return rooms;
  }

  int roomNumberValue(dynamic room) {
    return int.tryParse((room['room_number'] ?? '0').toString()) ?? 0;
  }

  String floorFromRoom(dynamic room) {
    final roomNumber = (room['room_number'] ?? '-').toString();

    if (roomNumber.length >= 3 && int.tryParse(roomNumber) != null) {
      return roomNumber[0];
    }

    return '-';
  }

  Map<String, List> groupRoomsByFloor(List roomList) {
    final sortedRooms = [...roomList];

    sortedRooms.sort((a, b) {
      return roomNumberValue(a).compareTo(roomNumberValue(b));
    });

    final Map<String, List> grouped = {};

    for (final room in sortedRooms) {
      final floor = floorFromRoom(room);
      grouped.putIfAbsent(floor, () => []);
      grouped[floor]!.add(room);
    }

    return grouped;
  }

  List<Widget> _buildFloorGroupedRooms() {
    final groupedRooms = groupRoomsByFloor(filteredRooms);
    final List<Widget> widgets = [];

    groupedRooms.forEach((floor, floorRooms) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 8),
          child: Text(
            floor == '-' ? 'Other Rooms' : 'Floor $floor',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xff111827),
            ),
          ),
        ),
      );

      for (final room in floorRooms) {
        widgets.add(_buildRoomCard(room));
      }
    });

    return widgets;
  }

  int countByRoomStatus(String status) {
    if (status == 'all') return rooms.length;

    if (status == 'departure') {
      return rooms.where((r) => isDepartureGroup(r['room_status'])).length;
    }

    if (status == 'stayover') {
      return rooms.where((r) => isStayover(r['room_status'])).length;
    }

    return 0;
  }

  int countByCleaningStatus(String status) {
    return rooms.where((r) {
      final value = normalize(r['cleaning_status']);

      if (status == 'pending') {
        return value == 'pending' || value == 'assigned' || value.isEmpty;
      }

      return value == status;
    }).length;
  }

  Color statusColor(String status) {
    final value = normalize(status);

    if (value == 'assigned' || value == 'pending' || value.isEmpty) {
      return const Color(0xfff59e0b);
    }

    switch (value) {
      case 'in_progress':
        return const Color(0xff2563eb);
      case 'cleaned':
        return const Color(0xff16a34a);
      case 'dnd':
        return const Color(0xff7c3aed);
      case 'refused_service':
        return const Color(0xffdc2626);
      case 'inspected':
        return const Color(0xff0f766e);
      default:
        return const Color(0xff6b7280);
    }
  }

  String pretty(dynamic value) {
    final text = (value ?? '').toString();

    if (text.isEmpty || text == 'null') return 'Pending';
    if (normalize(text) == 'assigned') return 'Pending';

    return text
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  String displayRoomGroup(dynamic status) {
    if (isDepartureGroup(status)) return 'Departure';
    if (isStayover(status)) return 'Stayover';

    return pretty(status);
  }

  @override
  Widget build(BuildContext context) {
    final pending = countByCleaningStatus('pending');
    final progress = countByCleaningStatus('in_progress');
    final cleaned = countByCleaningStatus('cleaned');

    return Scaffold(
      backgroundColor: const Color(0xfff3f4f6),
      appBar: AppBar(
        backgroundColor: const Color(0xff111827),
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Housekeeping Rooms',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: loadRooms,
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: loadRooms,
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: _buildHeader(pending, progress, cleaned),
                        ),
                        SliverToBoxAdapter(
                          child: _buildStatusTabs(),
                        ),
                        if (filteredRooms.isEmpty)
                          const SliverFillRemaining(
                            child: Center(
                              child: Text(
                                'No rooms found.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xff6b7280),
                                ),
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            sliver: SliverList(
                              delegate: SliverChildListDelegate(
                                _buildFloorGroupedRooms(),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
            if (isUpdating)
              Container(
                color: Colors.black.withOpacity(0.18),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int pending, int progress, int cleaned) {
    final total = rooms.length;
    final completedPercent = total == 0 ? 0.0 : cleaned / total;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xff111827),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Rooms Today',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Housekeeping task list',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: completedPercent,
              minHeight: 9,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation(Color(0xff22c55e)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _headerStat('Total', total.toString()),
              _headerStat('Pending', pending.toString()),
              _headerStat('Doing', progress.toString()),
              _headerStat('Done', cleaned.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerStat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTabs() {
    final tabs = [
      {'key': 'all', 'label': 'All'},
      {'key': 'departure', 'label': 'Departure'},
      {'key': 'stayover', 'label': 'Stayover'},
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final key = tab['key']!;
          final selected = selectedStatus == key;

          return ChoiceChip(
            selected: selected,
            label: Text('${tab['label']} (${countByRoomStatus(key)})'),
            selectedColor: const Color(0xff14b8a6),
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: selected ? Colors.white : const Color(0xff374151),
              fontWeight: FontWeight.w600,
            ),
            onSelected: (_) {
              setState(() => selectedStatus = key);
            },
          );
        },
      ),
    );
  }

  Widget _buildRoomCard(dynamic room) {
    final int id = int.parse(room['id'].toString());
    final roomNumber = room['room_number']?.toString() ?? '-';
    final roomStatus = room['room_status']?.toString() ?? '';
    final cleaningStatus = room['cleaning_status']?.toString() ?? 'pending';
    final notes = room['notes']?.toString() ?? '';

    final color = statusColor(cleaningStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xff14b8a6).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  roomNumber,
                  style: const TextStyle(
                    color: Color(0xff0f766e),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  displayRoomGroup(roomStatus),
                  style: const TextStyle(
                    color: Color(0xff111827),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _statusBadge(cleaningStatus, color),
            ],
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xfff9fafb),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                notes,
                style: const TextStyle(
                  color: Color(0xff374151),
                  fontSize: 13,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          _buildActions(id, cleaningStatus, roomStatus),
        ],
      ),
    );
  }

  Widget _statusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        pretty(status),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildActions(int id, String cleaningStatus, String roomStatus) {
    final status = normalize(cleaningStatus);
    final stayover = isStayover(roomStatus);

    if (status == 'cleaned' || status == 'inspected') {
      return const Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Waiting for supervisor inspection',
          style: TextStyle(
            color: Color(0xff16a34a),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (isPendingLike(status))
          _actionButton(
            label: 'Start Cleaning',
            icon: Icons.play_arrow_rounded,
            color: const Color(0xff2563eb),
            onTap: () => updateRoomStatus(id, 'start'),
          ),
        if (status == 'in_progress' || isPendingLike(status))
          _actionButton(
            label: 'Mark Cleaned',
            icon: Icons.check_rounded,
            color: const Color(0xff16a34a),
            onTap: () => updateRoomStatus(id, 'cleaned'),
          ),
        if (stayover) ...[
          _actionButton(
            label: 'DND',
            icon: Icons.do_not_disturb_on_outlined,
            color: const Color(0xff7c3aed),
            onTap: () => updateRoomStatus(id, 'dnd'),
          ),
          _actionButton(
            label: 'Refused',
            icon: Icons.close_rounded,
            color: const Color(0xffdc2626),
            onTap: () => updateRoomStatus(id, 'refused'),
          ),
        ],
      ],
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: isUpdating ? null : onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}