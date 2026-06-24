import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:videosdk/videosdk.dart';
import 'package:permission_handler/permission_handler.dart';
import 'participant_tile.dart';
import 'meeting_controls.dart';
import 'join_screen.dart';

class MeetingScreen extends StatefulWidget {
  final String meetingId;
  final String token;

  const MeetingScreen({super.key, required this.meetingId, required this.token});

  @override
  State<MeetingScreen> createState() => _MeetingScreenState();
}

class _MeetingScreenState extends State<MeetingScreen> {
  late Room _room;
  var micEnabled = true;
  var camEnabled = true;
  bool _isLeaving = false;
  Map<String, Participant> participants = {};
  Timer? _cleanupTimer;

  @override
  void initState() {
    super.initState();

    _room = VideoSDK.createRoom(
      roomId: widget.meetingId,
      token: widget.token,
      displayName: "Your Screen",
      micEnabled: micEnabled,
      camEnabled: camEnabled,
      defaultCameraIndex: kIsWeb ? 0 : 1,
    );

    setMeetingEventListener();
    _room.join();

    _cleanupTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _cleanupStaleParticipants();
    });
  }

  @override
  void dispose() {
    _cleanupTimer?.cancel();
    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  // ---------- Cleanup stale participants ----------
  void _cleanupStaleParticipants() {
    if (_isLeaving) return;
    try {
      final roomParticipants = _room.participants;
      final List<String> toRemove = [];
      participants.forEach((id, participant) {
        if (!roomParticipants.containsKey(id)) {
          toRemove.add(id);
        }
      });
      if (toRemove.isNotEmpty) {
        setState(() {
          for (var id in toRemove) {
            print('🧹 Cleanup: Removing stale participant $id');
            participants.remove(id);
          }
        });
      }
    } catch (e) {
      print('Cleanup error: $e');
    }
  }

  void _showToast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(milliseconds: 1200),
        backgroundColor: Colors.grey.shade800,
      ),
    );
  }

  // ---------- Meeting Events ----------
  void setMeetingEventListener() {
    _room.on(Events.roomJoined, () {
      final local = _room.localParticipant;
      setState(() {
        if (!participants.containsKey(local.id)) {
          participants[local.id] = local;
        }
      });
      print('✅ Room joined, participants: ${participants.length}');

      local.on(Events.streamEnabled, (Stream stream) {
        if (stream.kind == 'video') {
          setState(() {});
          print('📹 Local video stream enabled');
        }
      });
      local.on(Events.streamDisabled, (Stream stream) {
        if (stream.kind == 'video') {
          setState(() {});
          print('📹 Local video stream disabled');
        }
      });
    });

    _room.on(Events.participantJoined, (Participant p) {
      setState(() {
        if (!participants.containsKey(p.id)) {
          participants[p.id] = p;
        }
      });
      print('👤 Participant joined: ${p.displayName}, total: ${participants.length}');
    });

    _room.on(Events.participantLeft, (String id, Map<String, dynamic> reason) {
      if (_isLeaving) return;
      print('🚪 Participant left: $id, reason: $reason');
      if (participants.containsKey(id)) {
        setState(() {
          participants.remove(id);
        });
        if (participants.length <= 1) {
          _isLeaving = true;
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              print('⏳ Closing meeting – only local remains.');
              Navigator.of(context, rootNavigator: true).pop();
            }
          });
        }
      }
    });

    _room.on(Events.roomLeft, () {
      if (_isLeaving) return;
      _isLeaving = true;
      participants.clear();
      print('🏁 Room left – navigating back.');
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const JoinScreen()),
              (route) => false,
        );
      }
    });
  }

  Future<bool> _onWillPop() async {
    _room.leave();
    return true;
  }

  Future<void> _copyMeetingId() async {
    await Clipboard.setData(ClipboardData(text: widget.meetingId));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Meeting ID copied'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Nest', style: TextStyle(fontWeight: FontWeight.w600)),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.deepPurple,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: Colors.grey.shade200, height: 1),
          ),
        ),
        body: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Colors.grey.shade50],
              ),
            ),
            child: Column(
              children: [
                // Meeting ID card
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.deepPurple.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.meeting_room, size: 18, color: Colors.deepPurple.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Meeting ID', style: TextStyle(color: Colors.deepPurple.shade700, fontSize: 12, fontWeight: FontWeight.w500)),
                            Text(widget.meetingId, style: TextStyle(color: Colors.deepPurple.shade700, fontWeight: FontWeight.w600, letterSpacing: 1, fontSize: 16)),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.deepPurple.shade200),
                        ),
                        child: InkWell(
                          onTap: _copyMeetingId,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.copy, size: 16, color: Colors.deepPurple.shade700),
                                const SizedBox(width: 4),
                                Text('Copy', style: TextStyle(color: Colors.deepPurple.shade700, fontWeight: FontWeight.w500, fontSize: 14)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Participants grid
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: participants.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.deepPurple),
                          const SizedBox(height: 16),
                          Text('Waiting for participants...', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                        ],
                      ),
                    )
                        : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        mainAxisExtent: 260,
                      ),
                      itemBuilder: (context, index) {
                        final p = participants.values.elementAt(index);
                        final local = _room.localParticipant;
                        return ParticipantTile(
                          participant: p,
                          localParticipant: local,
                        );
                      },
                      itemCount: participants.length,
                    ),
                  ),
                ),

                // Controls
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 2, blurRadius: 10, offset: const Offset(0, -2)),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomPadding * 0.2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.people, size: 14, color: Colors.grey.shade700),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${participants.length} participant${participants.length != 1 ? 's' : ''}',
                                      style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        MeetingControls(
                          onToggleMicButtonPressed: () {
                            setState(() {
                              if (micEnabled) _room.muteMic();
                              else _room.unmuteMic();
                              micEnabled = !micEnabled;
                            });
                          },
                          onToggleCameraButtonPressed: () {
                            setState(() {
                              if (camEnabled) _room.disableCam();
                              else _room.enableCam();
                              camEnabled = !camEnabled;
                            });
                          },
                          onLeaveButtonPressed: () => _room.leave(),
                          micEnabled: micEnabled,
                          camEnabled: camEnabled,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}