import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const OfflineVaultApp());
}

// ============================================================================
// APP ENTRY POINT & THEME
// ============================================================================
class OfflineVaultApp extends StatelessWidget {
  const OfflineVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OfflineVault',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.deepPurpleAccent,
        scaffoldBackgroundColor: const Color(0xFF121212),
        useMaterial3: true,
      ),
      home: const MainNavigationScreen(),
    );
  }
}

// ============================================================================
// NAVIGATION SHELL (Tabs: Dashboard, Browser, Settings)
// ============================================================================
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  bool isProxyRunning = false;
  int cachedEntries = 134;
  String totalSize = "4.62 MB";

  void toggleProxy() {
    setState(() {
      isProxyRunning = !isProxyRunning;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 3 Tab Screens
    final List<Widget> screens = [
      _buildDashboardTab(),
      const OfflineBrowserScreen(),
      _buildSettingsTab(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1A1A1A),
        selectedItemColor: Colors.deepPurpleAccent,
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.public),
            label: "Browser",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
      ),
    );
  }

  // --- TAB 1: DASHBOARD ---
  Widget _buildDashboardTab() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔒 OfflineVault Mobile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                      isProxyRunning ? "In-App Cache ACTIVE" : "In-App Cache STOPPED",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Sandbox Mode: Embedded Chromium",
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildStatCard("Saved Pages", cachedEntries.toString(), Icons.folder)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard("Storage Used", totalSize, Icons.storage)),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: toggleProxy,
              style: ElevatedButton.styleFrom(
                backgroundColor: isProxyRunning ? Colors.redAccent : Colors.deepPurpleAccent,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                isProxyRunning ? "⏹️ PAUSE CACHING" : "▶️ ENABLE CACHING",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

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
            Text(title, style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // --- TAB 3: SETTINGS PLACEHOLDER ---
  Widget _buildSettingsTab() {
    return Scaffold(
      appBar: AppBar(title: const Text("⚙️ Settings"), backgroundColor: Colors.transparent),
      body: const Center(
        child: Text("Cache Limits & Blacklist configuration coming soon!"),
      ),
    );
  }
}

// ============================================================================
// TAB 2: THE EMBEDDED CHROMIUM BROWSER
// ============================================================================
class OfflineBrowserScreen extends StatefulWidget {
  const OfflineBrowserScreen({super.key});

  @override
  State<OfflineBrowserScreen> createState() => _OfflineBrowserScreenState();
}

class _OfflineBrowserScreenState extends State<OfflineBrowserScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() { _isLoading = true; });
          },
          onPageFinished: (url) {
            setState(() { _isLoading = false; });
          },
        ),
      )
      ..loadRequest(Uri.parse('https://en.wikipedia.org/wiki/Special:Random'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🔍 OfflineVault Browser", style: TextStyle(fontSize: 16)),
        backgroundColor: const Color(0xFF1A1A1A),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
            ),
        ],
      ),
    );
  }
}