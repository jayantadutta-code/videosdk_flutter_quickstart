import 'package:flutter/material.dart';
import 'package:videosdk/videosdk.dart';

class ParticipantTile extends StatefulWidget {
  final Participant participant;
  final Participant? localParticipant; // for self‑view overlay
  const ParticipantTile({
    super.key,
    required this.participant,
    this.localParticipant,
  });

  @override
  State<ParticipantTile> createState() => _ParticipantTileState();
}

class _ParticipantTileState extends State<ParticipantTile> {
  Stream? videoStream;

  @override
  void initState() {
    super.initState();
    // Initial video stream
    widget.participant.streams.forEach((key, stream) {
      if (stream.kind == 'video') {
        setState(() => videoStream = stream);
      }
    });
    // Listen for future events
    widget.participant.on(Events.streamEnabled, (Stream stream) {
      if (stream.kind == 'video') {
        setState(() => videoStream = stream);
      }
    });
    widget.participant.on(Events.streamDisabled, (Stream stream) {
      if (stream.kind == 'video') {
        setState(() => videoStream = null);
      }
    });
  }

  void _openFullScreen(BuildContext context) {
    // Get local video stream for PIP
    Stream? localVideoStream;
    if (widget.localParticipant != null) {
      try {
        // Try to find a video stream
        localVideoStream = widget.localParticipant!.streams.values.firstWhere(
              (s) => s.kind == 'video',
        );
      } catch (_) {
        localVideoStream = null; // no video stream found
      }
    }

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.95),
      builder: (_) => Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            // Main video
            Center(
              child: videoStream != null && videoStream?.renderer != null
                  ? RTCVideoView(
                videoStream!.renderer as RTCVideoRenderer,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                mirror: widget.participant.isLocal,
              )
                  : Container(
                color: Colors.grey.shade900,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person, size: 80, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      widget.participant.displayName,
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    if (widget.participant.isLocal)
                      const Text(
                        '(You)',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                  ],
                ),
              ),
            ),
            // Close button
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            // Name overlay
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: Colors.black.withOpacity(0.5),
                child: Text(
                  widget.participant.displayName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
            // Self‑view PIP (only if viewing another participant)
            if (widget.localParticipant != null && !widget.participant.isLocal)
              Positioned(
                bottom: 20,
                right: 20,
                child: GestureDetector(
                  onTap: () {
                    // Optional: close dialog and show self full‑screen
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 120,
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: localVideoStream != null && localVideoStream?.renderer != null
                        ? RTCVideoView(
                      localVideoStream!.renderer as RTCVideoRenderer,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      mirror: true,
                    )
                        : Container(
                      color: Colors.grey.shade800,
                      child: const Center(
                        child: Icon(Icons.person, color: Colors.white, size: 40),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLocal = widget.participant.isLocal;
    return GestureDetector(
      onTap: () => _openFullScreen(context),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            color: Colors.grey.shade900,
            child: videoStream != null && videoStream?.renderer != null
                ? RTCVideoView(
              videoStream!.renderer as RTCVideoRenderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              mirror: isLocal,
            )
                : Stack(
              fit: StackFit.expand,
              children: [
                Container(color: Colors.grey.shade800),
                Center(
                  child: Icon(
                    Icons.person,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.participant.displayName,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                if (isLocal)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'You',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
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