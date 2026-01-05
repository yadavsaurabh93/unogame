import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firestore_service.dart';
import '../widgets/modern_button.dart';
import '../widgets/background.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ModernBackground(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(children: [
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white)),
                Text("LEADERBOARD",
                    style: GoogleFonts.blackOpsOne(
                        color: Colors.white, fontSize: 28)),
              ]),
              const SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: FirestoreService.getLeaderboard(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError)
                      return const Center(
                          child: Text("Error loading data",
                              style: TextStyle(color: Colors.red)));
                    if (!snapshot.hasData)
                      return const Center(child: CircularProgressIndicator());

                    final users = snapshot.data!;
                    if (users.isEmpty)
                      return const Center(
                          child: Text("No players yet!",
                              style: TextStyle(color: Colors.white54)));

                    return ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (ctx, i) {
                        final user = users[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                  color:
                                      i < 3 ? Colors.amber : Colors.white10)),
                          child: Row(
                            children: [
                              Text("#${i + 1}",
                                  style: GoogleFonts.blackOpsOne(
                                      color:
                                          i < 3 ? Colors.amber : Colors.white,
                                      fontSize: 20)),
                              const SizedBox(width: 15),
                              Icon(Icons.person,
                                  color: Colors.white.withOpacity(0.8)),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: Text(user['displayName'] ?? "Unknown",
                                      style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold))),
                              Text("${user['coins']} 🪙",
                                  style: GoogleFonts.poppins(
                                      color: Colors.yellowAccent,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
