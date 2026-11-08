import 'package:flutter/material.dart';

void main() {
  runApp(const OfflineVaultApp());
}

// ============================================================================
// THE ROOT APP (Theme Settings)
// ============================================================================
class OfflineVaultApp extends StatelessWidget {
  const OfflineVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OfflineVault',
      debugShowCheckedModeBanner: false, // Hides the red "DEBUG" banner
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.deepPurpleAccent,
        scaffoldBackgroundColor: const Color(0xFF121212), // Deep dark mode background
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}

// ============================================================================
// THE DASHBOARD SCREEN (Stateful = it can change and update!)
// ============================================================================
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // These are our variables holding the state of the app
  bool isProxyRunning = false;
  int cachedEntries = 999;
  String totalSize = "4.62 MB";

  // This function runs when we tap the giant start button
  void toggleProxy() {
    setState(() {
      isProxyRunning = !isProxyRunning;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔥 My Super Vault', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            
            // --- 1. THE STATUS CARD ---
            Card(
              color: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(
                      isProxyRunning ? Icons.security : Icons.gpp_bad,
                      size: 72,
                      color: isProxyRunning ? Colors.greenAccent : Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isProxyRunning ? "Proxy is ACTIVE" : "Proxy is STOPPED",
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Port: 8081 | Local Interface",
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // --- 2. THE STATS ROW ---
            Row(
              children: [
                Expanded(child: _buildStatCard("Entries", cachedEntries.toString(), Icons.folder)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard("Size", totalSize, Icons.storage)),
              ],
            ),
            
            const Spacer(), // Pushes the button to the bottom of the screen
            
            // --- 3. THE GIANT TOGGLE BUTTON ---
            ElevatedButton(
              onPressed: toggleProxy,
              style: ElevatedButton.styleFrom(
                backgroundColor: isProxyRunning ? Colors.redAccent : Colors.deepPurpleAccent,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                isProxyRunning ? "⏹️ STOP PROXY" : "▶️ START PROXY",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
      
      // --- 4. THE BOTTOM NAVIGATION BAR ---
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1A1A1A),
        selectedItemColor: Colors.deepPurpleAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.library_books), label: "Library"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }

  // A helper function to draw the little statistics boxes
  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.deepPurpleAccent, size: 28),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(title, style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}