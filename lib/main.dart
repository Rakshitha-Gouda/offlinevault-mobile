import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'services/db_helper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
  bool isProxyRunning = true;
  int cachedEntries = 0;
  String totalSize = "0.00 MB";

  @override
  void initState() {
    super.initState();
    _refreshStats();
  }

  Future<void> _refreshStats() async {
    final stats = await MobileVaultDatabase.instance.getStats();
    if (mounted) {
      setState(() {
        cachedEntries = stats['count'] as int;
        totalSize = stats['size_mb'] as String;
      });
    }
  }

  void toggleProxy() {
    setState(() {
      isProxyRunning = !isProxyRunning;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _buildDashboardTab(),
      OfflineBrowserScreen(
        isCachingEnabled: isProxyRunning,
        onPageCached: _refreshStats,
      ),
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
          _refreshStats();
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.public), label: "Browser"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
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
                      isProxyRunning ? "In-App Cache ACTIVE" : "In-App Cache PAUSED",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Storage: Native SQLite (sqflite)",
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

  // --- TAB 3: SETTINGS ---
  Widget _buildSettingsTab() {
    return Scaffold(
      appBar: AppBar(title: const Text("⚙️ Settings"), backgroundColor: Colors.transparent),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: () async {
            await MobileVaultDatabase.instance.clearAll();
            await _refreshStats();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("🗑️ SQLite Cache Cleared Successfully")),
              );
            }
          },
          icon: const Icon(Icons.delete_forever, color: Colors.white),
          label: const Text("Clear Mobile Cache", style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
        ),
      ),
    );
  }
}

// ============================================================================
// TAB 2: OFFLINE BROWSER WITH AUTO-CACHING
// ============================================================================
class OfflineBrowserScreen extends StatefulWidget {
  final bool isCachingEnabled;
  final VoidCallback onPageCached;

  const OfflineBrowserScreen({
    super.key,
    required this.isCachingEnabled,
    required this.onPageCached,
  });

  @override
  State<OfflineBrowserScreen> createState() => _OfflineBrowserScreenState();
}

class _OfflineBrowserScreenState extends State<OfflineBrowserScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String _currentUrl = 'https://en.wikipedia.org/wiki/Special:Random';
  final TextEditingController _urlBarController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _urlBarController.text = _currentUrl;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'OfflineVaultBridge',
        onMessageReceived: (JavaScriptMessage message) async {
          final rawHtml = message.message;
          if (rawHtml.isNotEmpty && widget.isCachingEnabled) {
            await MobileVaultDatabase.instance.savePage(_currentUrl, rawHtml);
            widget.onPageCached();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("💾 Page saved to offline SQLite cache!"),
                  duration: Duration(seconds: 1),
                  backgroundColor: Colors.deepPurple,
                ),
              );
            }
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _currentUrl = url;
                _urlBarController.text = url;
              });
            }
          },
          onPageFinished: (url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }

            // Extract clean, unescaped HTML via Native JS Channel
            if (widget.isCachingEnabled) {
              _controller.runJavaScript(
                'OfflineVaultBridge.postMessage(document.documentElement.outerHTML);',
              );
            }
          },
          onWebResourceError: (WebResourceError error) async {
            // ✅ FIX 1: Ignore missing sub-resources (icons, styles, ads)
            if (error.isForMainFrame != true) {
              return;
            }

            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }

            // Fallback to SQLite cache for main page failure
            await _loadOfflineFromDatabase();
          },
        ),
      )
      ..loadRequest(Uri.parse(_currentUrl));
  }

  /// Loads cached page directly from local SQLite
   /// Injects built-in Reader Mode CSS and clean typography into offline HTML
  String _formatReaderModeHtml(String rawHtml) {
    const readerStyles = '''
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          body {
            background-color: #121212 !important;
            color: #E0E0E0 !important;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif !important;
            line-height: 1.7 !important;
            padding: 16px 20px !important;
            margin: 0 !important;
            font-size: 16px !important;
          }
          /* Headings */
          h1, h2, h3, h4 {
            color: #FFFFFF !important;
            font-weight: 700 !important;
            margin-top: 28px !important;
            border-bottom: 1px solid #2C2C2C !important;
            padding-bottom: 6px !important;
          }
          h1 { font-size: 26px !important; }
          h2 { font-size: 20px !important; }
          /* Links styled with OfflineVault accent purple */
          a {
            color: #BB86FC !important;
            text-decoration: underline !important;
          }
          /* Code blocks and syntax */
          code, pre {
            background-color: #1E1E1E !important;
            color: #03DAC6 !important;
            padding: 4px 8px !important;
            border-radius: 6px !important;
            font-family: monospace !important;
            font-size: 14px !important;
          }
          pre {
            padding: 12px !important;
            overflow-x: auto !important;
          }
          /* Tables */
          table {
            width: 100% !important;
            border-collapse: collapse !important;
            margin: 16px 0 !important;
            display: block !important;
            overflow-x: auto !important;
          }
          th, td {
            border: 1px solid #333333 !important;
            padding: 8px 12px !important;
          }
          th { background-color: #1E1E1E !important; color: #FFFFFF !important; }
          /* Graceful handling of missing offline images */
          img {
            max-width: 100% !important;
            height: auto !important;
            border-radius: 8px !important;
            margin: 12px 0 !important;
            background-color: #1E1E1E !important;
            min-height: 40px !important;
            border: 1px dashed #444444 !important;
          }
          /* Clean up Wikipedia noise (navigation bars, search boxes, footer links) */
          .mw-header, .header-container, #mw-navigation, .vector-menu, 
          .mw-editsection, .noprint, nav, footer, .catlinks {
            display: none !important;
          }
        </style>
      </head>
    ''';

    // Inject our reader styles right at the start of the document
    if (rawHtml.contains('<head>')) {
      return rawHtml.replaceFirst('<head>', readerStyles);
    } else {
      return '<html>$readerStyles<body>$rawHtml</body></html>';
    }
  }

  /// Loads cached page directly from local SQLite with Reader Mode formatting
  Future<void> _loadOfflineFromDatabase() async {
    final cached = await MobileVaultDatabase.instance.getPage(_currentUrl);
    if (cached != null) {
      final rawHtml = cached['html'] as String;

      // ✅ Transform raw text into formatted Reader Mode
      final formattedHtml = _formatReaderModeHtml(rawHtml);

      await Future.delayed(const Duration(milliseconds: 150));
      await _controller.loadHtmlString(formattedHtml);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("⚡ Offline Reader Mode: Formatted from SQLite Vault!"),
            backgroundColor: Colors.deepPurple,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
  void _navigateToUrl() {
    String input = _urlBarController.text.trim();
    if (!input.startsWith('http://') && !input.startsWith('https://')) {
      input = 'https://$input';
    }
    _controller.loadRequest(Uri.parse(input));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: TextField(
          controller: _urlBarController,
          decoration: const InputDecoration(
            hintText: "Enter URL...",
            border: InputBorder.none,
            isDense: true,
          ),
          style: const TextStyle(fontSize: 14, color: Colors.white),
          onSubmitted: (_) => _navigateToUrl(),
        ),
        actions: [
          // ✅ FIX 4: Dedicated button to force-load offline version anytime
          IconButton(
            icon: const Icon(Icons.offline_bolt, color: Colors.greenAccent),
            tooltip: "Load Cached Version",
            onPressed: _loadOfflineFromDatabase,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: _navigateToUrl,
          ),
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