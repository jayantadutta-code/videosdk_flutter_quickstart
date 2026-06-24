import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'api_call.dart';
import 'meeting_screen.dart';

class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key});

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final _meetingIdController = TextEditingController();

  Future<void> _requestPermissions() async {
    await Permission.camera.request();
    await Permission.microphone.request();
  }

  void _createMeeting(BuildContext context) async {
    await _requestPermissions();
    await createMeeting().then((meetingId) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Meeting created! ID: $meetingId'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WakelockWrapper(
            child: MeetingScreen(meetingId: meetingId, token: token),
          ),
        ),
      );
    });
  }

  void _joinMeeting(BuildContext context) {
    final id = _meetingIdController.text.trim().toLowerCase();
    final re = RegExp(r'^[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}$');
    if (id.isNotEmpty && re.hasMatch(id)) {
      _requestPermissions();
      _meetingIdController.clear();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WakelockWrapper(
            child: MeetingScreen(meetingId: id, token: token),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid meeting ID format (e.g. aaaa-123f-gggg)'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6C63FF), Color(0xFF3F3D9E)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
                color: Colors.white.withOpacity(0.95),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.video_call,
                          size: 56,
                          color: Color(0xFF6C63FF),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Nest',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3F3D9E),
                        ),
                      ),
                      const Text(
                        'Connect • Share • Grow',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Create Meeting button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _createMeeting(context),
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text(
                            'Create New Meeting',
                            style: TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C63FF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      const Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text('or join with ID'),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Meeting ID input
                      TextField(
                        controller: _meetingIdController,
                        decoration: InputDecoration(
                          hintText: 'Enter meeting ID',
                          prefixIcon: const Icon(Icons.meeting_room),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        onChanged: (v) {
                          if (v != v.toLowerCase()) {
                            _meetingIdController.value = TextEditingValue(
                              text: v.toLowerCase(),
                              selection: _meetingIdController.selection,
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Join button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _joinMeeting(context),
                          icon: const Icon(Icons.login, color: Colors.white),
                          label: const Text(
                            'Join Meeting',
                            style: TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Meeting ID format: aaaa-123f-gggg',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ========== WAKELOCK WRAPPER ==========
class WakelockWrapper extends StatefulWidget {
  final Widget child;
  const WakelockWrapper({super.key, required this.child});

  @override
  State<WakelockWrapper> createState() => _WakelockWrapperState();
}

class _WakelockWrapperState extends State<WakelockWrapper> {
  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}