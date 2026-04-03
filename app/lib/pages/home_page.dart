import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_constants.dart';
import '../features/rooms/presentation/providers/rooms_provider.dart';
import '../features/rooms/presentation/widgets/rooms_list.dart';
import '../features/voice_control/presentation/pages/voice_control_page.dart';
import '../features/voice_control/presentation/providers/voice_control_provider.dart';
import '../core/config/app_config.dart';
import '../di/injection.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool _showSettings = false;
  late final TextEditingController _n8nController;
  late final TextEditingController _flaskController;
  final _settingsFormKey = GlobalKey<FormState>();

  AppConfig _activeConfig = Injection.config;

  bool get _hasConfigChanges {
    return _n8nController.text.trim() != _activeConfig.n8nBaseUrl ||
        _flaskController.text.trim() != _activeConfig.flaskBaseUrl;
  }

  @override
  void initState() {
    super.initState();
    _n8nController = TextEditingController(text: _activeConfig.n8nBaseUrl);
    _flaskController = TextEditingController(text: _activeConfig.flaskBaseUrl);

    _n8nController.addListener(_onSettingsChanged);
    _flaskController.addListener(_onSettingsChanged);

    // Load rooms when app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoomsProvider>().loadRooms();
    });
  }

  @override
  void dispose() {
    _n8nController.removeListener(_onSettingsChanged);
    _flaskController.removeListener(_onSettingsChanged);
    _n8nController.dispose();
    _flaskController.dispose();
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  String? _validateUrl(String? value, String label) {
    final url = value?.trim() ?? '';
    if (url.isEmpty) {
      return '$label is required';
    }

    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme.isEmpty || uri.host.isEmpty) {
      return 'Enter a valid URL (example: http://localhost:5000)';
    }

    return null;
  }

  Future<void> _applySettings() async {
    final isValid = _settingsFormKey.currentState?.validate() ?? false;
    if (!isValid || !_hasConfigChanges) {
      return;
    }

    final updatedConfig = AppConfig(
      n8nBaseUrl: _n8nController.text.trim(),
      flaskBaseUrl: _flaskController.text.trim(),
    );

    Injection.reset();
    Injection.init(updatedConfig);

    context.read<RoomsProvider>().updateDependency(Injection.getRooms);
    context.read<VoiceControlProvider>().updateDependencies(
      Injection.recordAndSendCommand,
      Injection.stopRecording,
    );

    setState(() {
      _activeConfig = updatedConfig;
    });

    await context.read<RoomsProvider>().loadRooms();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuration applied successfully')),
    );
  }

  void _resetSettingsToDefault() {
    setState(() {
      _n8nController.text = AppConfig.defaultConfig.n8nBaseUrl;
      _flaskController.text = AppConfig.defaultConfig.flaskBaseUrl;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lumos'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              setState(() => _showSettings = !_showSettings);
            },
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _showSettings
            ? _buildSettings()
            : _selectedIndex == 0
            ? const VoiceControlPage()
            : const RoomsList(),
      ),
      bottomNavigationBar: _showSettings
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.mic_outlined),
                  selectedIcon: Icon(Icons.mic),
                  label: 'Voice Control',
                ),
                NavigationDestination(
                  icon: Icon(Icons.lightbulb_outlined),
                  selectedIcon: Icon(Icons.lightbulb),
                  label: 'Rooms',
                ),
              ],
            ),
    );
  }

  Widget _buildSettings() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _settingsFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Server Configuration',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Update backend endpoints and apply without restarting the app.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _n8nController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'N8N Base URL',
                      hintText: 'http://localhost:5678',
                      prefixIcon: Icon(Icons.webhook),
                    ),
                    validator: (value) => _validateUrl(value, 'N8N Base URL'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _flaskController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Flask Bridge URL',
                      hintText: 'http://localhost:5000',
                      prefixIcon: Icon(Icons.router),
                    ),
                    validator: (value) =>
                        _validateUrl(value, 'Flask Bridge URL'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _hasConfigChanges ? _applySettings : null,
                          icon: const Icon(Icons.save),
                          label: const Text('Apply'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _resetSettingsToDefault,
                          icon: const Icon(Icons.restore),
                          label: const Text('Defaults'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('About', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Version'),
                  subtitle: const Text(AppConstants.appVersion),
                  contentPadding: EdgeInsets.zero,
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Description'),
                  subtitle: const Text('Voice-controlled light system'),
                  contentPadding: EdgeInsets.zero,
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.link),
                  title: const Text('Active N8N URL'),
                  subtitle: Text(_activeConfig.n8nBaseUrl),
                  contentPadding: EdgeInsets.zero,
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.link_outlined),
                  title: const Text('Active Flask URL'),
                  subtitle: Text(_activeConfig.flaskBaseUrl),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {
            setState(() => _showSettings = false);
          },
          icon: const Icon(Icons.close),
          label: const Text('Close Settings'),
        ),
      ],
    );
  }
}
