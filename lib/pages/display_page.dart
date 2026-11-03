import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';
import 'package:webview_windows/webview_windows.dart';

import '../services/display_service.dart';
import '../services/database_service.dart';

class DisplayPage extends StatefulWidget {
  const DisplayPage({super.key});

  @override
  State<DisplayPage> createState() => _DisplayPageState();
}

// WebViewPage implemented as a StatefulWidget.
class WebViewPage extends StatefulWidget {
  final double width;
  final double height;
  final WebviewController controller;
  final Future<void> Function() onAutoClick;

  const WebViewPage({
    super.key,
    required this.width,
    required this.height,
    required this.controller,
    required this.onAutoClick,
  });

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  @override
  void initState() {
    super.initState();
    initPlatformState();
    initWindowManager();
  }

  Future<void> initWindowManager() async {
    await windowManager.ensureInitialized();
    // await windowManager.setFullScreen(true);
    WindowOptions windowOptions = const WindowOptions(
      // center: true,
      skipTaskbar: false,
      title: "Display Monitoring Bed",
      titleBarStyle: TitleBarStyle.normal,
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      // await windowManager.setFullScreen(true);
      // await windowManager.show();
      // await windowManager.focus();
      // await windowManager.maximize(vertically: true);
      await windowManager.setSize(Size(widget.width, widget.height));
    });
  }

  Future<void> initPlatformState() async {
    await widget.controller.initialize();
    // await _controller.loadUrl(
    //   'http://192.168.11.100/livebridging/queueing/displayreg?qlocation=01&qcounter=2',
    // ); // Loket Rajal
    // await _controller.loadUrl(
    //   'http://192.168.11.100/live/module/kiosk/OTMonitoringDisplayV3.aspx',
    // ); // RUANG OPERASI
    await widget.controller.loadUrl(
      'http://rsudzus.simrsaviat.com:3030/queue/display?template=lab-rad',
    ); // bed monitoring
    // await _controller.loadUrl(
    //   'http://192.168.11.100/live/module/kiosk/PrescQueueDisplay6Col.aspx?suid=D5.0.A07',
    // ); // resep apotek
    // await _controller.loadUrl(
    //   'http://192.168.11.100/livebridging/queueing/displaypoli?qlocation=02&qcounter=1',
    // ); // Antrian Dokter
    setState(() {});
    widget.onAutoClick();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text('Flutter Desktop WebView')),
      body: Webview(widget.controller),
    );
  }
}

class _DisplayPageState extends State<DisplayPage> {
  final displayService = DisplayService();
  final _controller = WebviewController();
  final TextEditingController _selectorCtrl = TextEditingController();
  final TextEditingController _textCtrl = TextEditingController();

  List<Display> displays = [];

  String? selectedDisplay;
  bool fullscreen = false;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    displays = await displayService.getDisplays();

    var config = await DatabaseService.instance.loadConfig();

    if (config != null) {
      selectedDisplay = config['display_id']?.toString();
      fullscreen = config['fullscreen'] == 1;
    }

    setState(() {});
  }

  Future<void> _runAutoClick() async {
    final selector = jsonEncode(_selectorCtrl.text.trim());
    final text = jsonEncode(_textCtrl.text.trim());

    final script =
        '''
(function () {
  const selector = $selector;
  const text = $text.toLowerCase();
  let tries = 0;

  function find() {
    let el = selector ? document.querySelector(selector) : null;
    if (!el && text) {
      const all = document.querySelectorAll(
        'button, a, input[type=button], input[type=submit], [role=button]'
      );
      el = Array.from(all).find(function (e) {
        const label = (e.innerText || e.value || '').trim().toLowerCase();
        return label.includes(text);
      });
    }
    return el;
  }

  const timer = setInterval(function () {
    tries++;
    const el = find();
    if (el) {
      clearInterval(timer);
      el.scrollIntoView({ block: 'center' });
      el.click();
      window.chrome.webview.postMessage('Tombol berhasil diklik');
    } else if (tries >= 60) {
      clearInterval(timer);
      window.chrome.webview.postMessage('Tombol tidak ditemukan');
    }
  }, 500);
})();
''';

    if (!mounted) return;
    await _controller.executeScript(script);
  }

  Future<void> saveConfig() async {
    await DatabaseService.instance.saveConfig(selectedDisplay!, fullscreen);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Konfigurasi disimpan")));
  }

  Future<void> moveToDisplay(Display display) async {
    await windowManager.setBounds(display.visiblePosition! & display.size);
    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          // appBar: AppBar(title: Text("Monitor")),
          body: WebViewPage(
            width: display.size.width,
            height: display.size.height,
            controller: _controller,
            onAutoClick: _runAutoClick,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pilih Display")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...displays.asMap().entries.map((entry) {
            final display = entry.value;
            return RadioListTile<String>(
              value: display.id.toString(),
              groupValue: selectedDisplay,
              title: Text("Monitor ${entry.key + 1}"),
              subtitle: Text("${display.size.width} x ${display.size.height}"),
              onChanged: (v) {
                setState(() {
                  selectedDisplay = v;
                });
              },
            );
          }),

          const SizedBox(height: 20),

          SwitchListTile(
            title: const Text("Fullscreen"),
            value: fullscreen,
            onChanged: (v) {
              setState(() {
                fullscreen = v;
              });
            },
          ),

          ElevatedButton(onPressed: saveConfig, child: const Text("Simpan")),

          ElevatedButton(
            onPressed: () {
              var display = displays.firstWhere(
                (e) => e.id.toString() == selectedDisplay,
              );

              moveToDisplay(display);
            },
            child: const Text("Pindahkan ke Monitor"),
          ),
        ],
      ),
    );
  }
}
