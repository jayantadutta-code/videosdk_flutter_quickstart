import 'package:flutter/material.dart';

class MeetingControls extends StatelessWidget {
  final VoidCallback onToggleMicButtonPressed;
  final VoidCallback onToggleCameraButtonPressed;
  final VoidCallback onLeaveButtonPressed;
  final bool micEnabled;
  final bool camEnabled;

  const MeetingControls({
    super.key,
    required this.onToggleMicButtonPressed,
    required this.onToggleCameraButtonPressed,
    required this.onLeaveButtonPressed,
    required this.micEnabled,
    required this.camEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: micEnabled ? Icons.mic : Icons.mic_off,
            label: micEnabled ? 'Mute' : 'Unmute',
            color: micEnabled ? Colors.blue : Colors.grey,
            onPressed: onToggleMicButtonPressed,
          ),
          _buildControlButton(
            icon: camEnabled ? Icons.videocam : Icons.videocam_off,
            label: camEnabled ? 'Stop' : 'Start',
            color: camEnabled ? Colors.blue : Colors.grey,
            onPressed: onToggleCameraButtonPressed,
          ),
          _buildControlButton(
            icon: Icons.call_end,
            label: 'Leave',
            color: Colors.red,
            onPressed: onLeaveButtonPressed,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              customBorder: const CircleBorder(),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.1),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}