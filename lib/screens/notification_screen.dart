import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/data_manager.dart';
import '../widgets/background.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // Notifications are now managed in DataManager

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("NOTIFICATIONS",
            style: GoogleFonts.blackOpsOne(letterSpacing: 1.5)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: Colors.cyanAccent),
            tooltip: "Mark all as read",
            onPressed: () {
              setState(() {
                DataManager.markAllNotificationsRead();
              });
              DataManager.playSound();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined,
                color: Colors.redAccent),
            tooltip: "Clear all",
            onPressed: () {
              setState(() {
                DataManager.clearNotifications();
              });
              DataManager.playSound();
            },
          ),
        ],
      ),
      body: ModernBackground(
        child: Column(
          children: [
            const SizedBox(height: 100),
            Expanded(
              child: DataManager.notifications.isEmpty
                  ? _emptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      physics: const BouncingScrollPhysics(),
                      itemCount: DataManager.notifications.length,
                      itemBuilder: (context, index) {
                        return _buildNotificationItem(
                            DataManager.notifications[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> note) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: note['isRead']
            ? Colors.white.withOpacity(0.03)
            : Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: note['isRead']
              ? Colors.white10
              : (note['color'] as Color).withOpacity(0.3),
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        onTap: () {
          setState(() {
            note['isRead'] = true;
          });
          DataManager.playSound();
        },
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (note['color'] as Color).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(note['icon'] as IconData,
              color: note['color'] as Color, size: 28),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(note['title'],
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
            if (!note['isRead'])
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: Colors.cyanAccent, shape: BoxShape.circle),
              )
            else
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white24, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  setState(() {
                    DataManager.removeNotification(note['id']);
                  });
                  DataManager.playSound();
                },
              )
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(note['body'],
                style:
                    GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 8),
            Text(note['time'],
                style:
                    GoogleFonts.poppins(color: Colors.white24, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 80, color: Colors.white10),
          const SizedBox(height: 20),
          Text("All clear!",
              style: GoogleFonts.poppins(color: Colors.white38, fontSize: 18)),
          Text("No new notifications",
              style: GoogleFonts.poppins(color: Colors.white24, fontSize: 14)),
        ],
      ),
    );
  }
}
