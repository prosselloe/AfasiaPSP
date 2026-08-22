import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logopeda/services/gemini_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:developer' as developer;
import 'package:intl/intl.dart';
import 'visualizer_screen.dart';
import 'info_screen.dart';
import 'sessions_visualizer_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Make status bar transparent and draw app underneath
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setSystemTheme() {
    _themeMode = ThemeMode.system;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primarySeedColor = Colors.deepPurple;

    final TextTheme appTextTheme = TextTheme(
      displayLarge:
          GoogleFonts.oswald(fontSize: 57, fontWeight: FontWeight.bold),
      titleLarge: GoogleFonts.roboto(fontSize: 22, fontWeight: FontWeight.w500),
      bodyMedium: GoogleFonts.openSans(fontSize: 14),
    );

    final ColorScheme lightColorScheme = ColorScheme.fromSeed(
      seedColor: primarySeedColor,
      brightness: Brightness.light,
    );

    final ThemeData lightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: lightColorScheme,
      textTheme: appTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: lightColorScheme.primary,
        foregroundColor: lightColorScheme.onPrimary,
        titleTextStyle:
            GoogleFonts.oswald(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: lightColorScheme.onPrimary,
          backgroundColor: lightColorScheme.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle:
              GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );

    final ColorScheme darkColorScheme = ColorScheme.fromSeed(
      seedColor: primarySeedColor,
      brightness: Brightness.dark,
    );

    final ThemeData darkTheme = ThemeData(
      useMaterial3: true,
      colorScheme: darkColorScheme,
      textTheme: appTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: darkColorScheme.inversePrimary,
        foregroundColor: darkColorScheme.onInverseSurface,
        titleTextStyle:
            GoogleFonts.oswald(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: darkColorScheme.onPrimaryContainer,
          backgroundColor: darkColorScheme.primaryContainer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle:
              GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Afàsia PSP',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeProvider.themeMode,
          home: const MyHomePage(),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final TextEditingController _apiKeyController;
  late final TextEditingController _promptController;
  final ValueNotifier<String> _response = ValueNotifier('');
  final ValueNotifier<bool> _isLoading = ValueNotifier(false);
  String? _logopedaPrompt;
  String? _comunicadorPrompt;

  List<String> _models = [];
  String? _selectedModel;

  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _speechEnabled = false;
  String _lastWords = '';

  List<String> _conversationHistory = [];
  DateTime? _sessionStartTime; // Per guardar l'inici de la sessió

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController(
        text: 'AQ.Ab8RN6KWsz6N8nvx_gD0FGw0TMSSItUGwLPddZbqrC6Mzj5ISg');
    _promptController = TextEditingController(
        text: "Bon dia, soc n'Aina i estic preparada per la següent sessió!");
    _loadSystemPrompts();
    if (_apiKeyController.text.isNotEmpty) {
      _loadModels();
    }
    _initSpeech();
    _loadConversationHistory();
  }

  void _initSpeech() async {
    if (kIsWeb) {
      _speechEnabled = false;
      if (mounted) {
        setState(() {});
      }
      return;
    }
    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (error) => developer.log('Speech recognition error',
            name: 'speech.error', error: error),
        onStatus: (status) => developer
            .log('Speech recognition status: $status', name: 'speech.status'),
      );
    } catch (e, stackTrace) {
      developer.log(
        'Could not initialize speech recognition',
        name: 'speech.init.error',
        error: e,
        stackTrace: stackTrace,
      );
      _speechEnabled = false;
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _startListening() async {
    await _stopSpeaking();
    await _speechToText.listen(
        onResult: _onSpeechResult, pauseFor: const Duration(minutes: 5));
    setState(() {});
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  void _onSpeechResult(result) {
    setState(() {
      _lastWords = result.recognizedWords;
      _promptController.text = _lastWords;
    });
  }

  Future<void> _speak(String text) async {
    await _flutterTts.setLanguage("ca-ES");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.speak(text);
  }

  Future<void> _stopSpeaking() async {
    await _flutterTts.stop();
  }

  Future<void> _loadSystemPrompts() async {
    try {
      final logopeda = await rootBundle.loadString('assets/txt/logopeda.txt');
      final comunicador =
          await rootBundle.loadString('assets/data/comunicador.json');
      setState(() {
        _logopedaPrompt = logopeda;
        _comunicadorPrompt = comunicador;
      });
    } catch (e) {
      developer.log('Error loading system prompts',
          name: 'prompt.error', error: e);
      setState(() {
        _logopedaPrompt =
            "Error: No s'ha pogut carregar el prompt del sistema.";
        _comunicadorPrompt = "Error: No s'ha pogut carregar el comunicador.";
      });
    }
  }

  Future<void> _loadConversationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('conversationHistory') ?? [];
    final startTimeString = prefs.getString('sessionStartTime');

    setState(() {
      _conversationHistory = history;
      if (history.isEmpty || startTimeString == null) {
        _sessionStartTime = DateTime.now();
        prefs.setString('sessionStartTime', _sessionStartTime!.toIso8601String());
      } else {
        _sessionStartTime = DateTime.tryParse(startTimeString);
        if (_sessionStartTime == null) {
          // Si no es pot parsejar la data, començam una nova sessió
          _sessionStartTime = DateTime.now();
          prefs.setString('sessionStartTime', _sessionStartTime!.toIso8601String());
        } else if (history.isNotEmpty) {
          final lastMessage = history.last;
          final parts = lastMessage.split('|');
          if (parts.length > 1) {
            final lastTimestampString = parts[1];
            final format = DateFormat('dd/MM/yyyy HH:mm');
            try {
              final lastTimestamp = format.parse(lastTimestampString);
              // Si han passat més de 2 hores, es una nova sessió.
              if (DateTime.now().difference(lastTimestamp).inHours > 2) {
                _sessionStartTime = DateTime.now();
                prefs.setString(
                    'sessionStartTime', _sessionStartTime!.toIso8601String());
              }
            } catch (e, stackTrace) {
              developer.log(
                'Could not parse timestamp from history message',
                name: 'history.timestamp.error',
                error: e,
                stackTrace: stackTrace,
              );
              // Fallback: si no podem parsejar, iniciam una nova sessió per seguretat
              _sessionStartTime = DateTime.now();
              prefs.setString(
                  'sessionStartTime', _sessionStartTime!.toIso8601String());
            }
          }
        }
      }
    });
  }

  Future<void> _saveConversationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('conversationHistory', _conversationHistory);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _promptController.dispose();
    _response.dispose();
    _isLoading.dispose();
    _speechToText.stop();
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _generateText() async {
    await _stopSpeaking();
    if (_speechToText.isListening) {
      _stopListening();
    }

    if (!_validateInputs()) return;
    final promptText = _promptController.text;
    _isLoading.value = true;
    _response.value = '';

    final geminiService = GeminiService(apiKey: _apiKeyController.text);

    final history = _conversationHistory.map((msg) {
      if (msg.contains('|') && msg.indexOf('|') < 25) {
        return msg.substring(msg.indexOf('|', msg.indexOf('|') + 1) + 1).trim();
      }
      return msg;
    }).join('');

    String durationContext = '';
    if (_sessionStartTime != null) {
      final duration = DateTime.now().difference(_sessionStartTime!);
      final minutes = duration.inMinutes;
      final seconds = duration.inSeconds % 60;
      durationContext =
          "\n\nInformació de context per la IA: Han passat $minutes minuts i $seconds segons des de l'inici de la sessió.";
    }

    // CORREGIT: Ús de StringBuffer per a una construcció segura de la cadena.
    final promptBuffer = StringBuffer();
    promptBuffer.writeln(_logopedaPrompt ?? '');
    promptBuffer.writeln();
    promptBuffer.writeln(_comunicadorPrompt ?? '');
    promptBuffer.writeln();
    promptBuffer.writeln(history);
    promptBuffer.writeln();
    promptBuffer.writeln(promptText);
    promptBuffer.writeln(durationContext);

    final fullPrompt = promptBuffer.toString();

    final result = await geminiService.generateText(fullPrompt,
        modelName: _selectedModel!);

    _response.value = result;
    _isLoading.value = false;
    _speak(result);

    final timestamp = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    setState(() {
      _conversationHistory.add("User: |$timestamp| $promptText");
      _conversationHistory.add("AI: |$timestamp| $result");
    });
    _promptController.clear();
    await _saveConversationHistory();
  }

  Future<void> _loadModels() async {
    if (_apiKeyController.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Si us plau, introdueix una API Key per carregar models.')),
      );
      return;
    }
    _isLoading.value = true;
    final geminiService = GeminiService(apiKey: _apiKeyController.text);
    final models = await geminiService.listModels();
    setState(() {
      _models = models;
      if (_models.isNotEmpty) {
        const preferredModel = 'gemini-flash-lite-latest';
        if (_models.contains(preferredModel)) {
          _selectedModel = preferredModel;
        } else {
          _selectedModel = _models.firstWhere((m) => m.contains('flash'),
              orElse: () => _models.first);
        }
      } else {
        _selectedModel = null;
      }
    });
    _isLoading.value = false;

    if (!mounted) return;

    if (_models.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'No s\'han trobat models de generació de text per a aquesta API Key.')),
      );
    }
  }

  bool _validateInputs() {
    if (_apiKeyController.text.isEmpty) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Si us plau, introdueix una API Key.')),
      );
      return false;
    }
    if (_selectedModel == null) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Si us plau, carrega i selecciona un model.')),
      );
      return false;
    }

    if (_promptController.text.isEmpty) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Si us plau, escriu una petició.')),
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Afàsia PSP'),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const InfoScreen()),
                );
              },
              tooltip: 'Informació',
            ),
            IconButton(
              icon: Icon(themeProvider.themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode),
              onPressed: () => themeProvider.toggleTheme(),
              tooltip: 'Toggle Theme',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('conversationHistory');
                await prefs.remove('sessionStartTime');
                _loadConversationHistory(); 
              },
              tooltip: 'Clear History',
            ),
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SessionsVisualizerScreen()),
                );
              },
              tooltip: 'Historial de Sessions',
            ),
            IconButton(
              icon: const Icon(Icons.grid_on),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const VisualizerScreen()),
                );
              },
              tooltip: 'Visualizador',
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text('Configuració del Model',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextField(
                  controller: _apiKeyController,
                  decoration: InputDecoration(
                    labelText: 'API Key de Google AI Studio',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    filled: true,
                  ),
                  obscureText: true,
                  onSubmitted: (_) => _loadModels(),
                ),
                const SizedBox(height: 16),
                if (_models.isNotEmpty)
                  DropdownButtonFormField<String>(
                    key: ValueKey(_selectedModel),
                    initialValue: _selectedModel,
                    items: _models.map((String model) {
                      return DropdownMenuItem<String>(
                        value: model,
                        child: Text(model),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedModel = newValue;
                      });
                    },
                    decoration: InputDecoration(
                        labelText: 'Selecciona un Model',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        filled: true),
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: _promptController,
                  decoration: InputDecoration(
                    labelText: _speechToText.isListening
                        ? 'Escoltant...'
                        : (_speechEnabled
                            ? 'Escriu o parla...'
                            : 'Escriu... (veu no disponible)'),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    filled: true,
                  ),
                  onSubmitted: (_) => _generateText(),
                  maxLines: 5,
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<bool>(
                  valueListenable: _isLoading,
                  builder: (context, isLoading, child) {
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: isLoading ? null : _loadModels,
                          icon: const Icon(Icons.memory),
                          label: const Text(''),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey),
                        ),
                        ElevatedButton.icon(
                          onPressed: isLoading ? null : _generateText,
                          icon: isLoading && _selectedModel != null
                              ? const SizedBox.shrink()
                              : const Icon(Icons.psychology_alt),
                          label: isLoading && _selectedModel != null
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text('Enviar'),
                        ),
                        if (_speechEnabled)
                          ElevatedButton.icon(
                            onPressed: isLoading
                                ? null
                                : (!_speechToText.isListening
                                    ? _startListening
                                    : _stopListening),
                            icon: Icon(_speechToText.isListening
                                ? Icons.mic
                                : Icons.mic_off),
                            label: Text(_speechToText.isListening
                                ? 'Aturar'
                                : 'Dictar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _speechToText.isListening
                                  ? Colors.red
                                  : Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                ValueListenableBuilder<String>(
                  valueListenable: _response,
                  builder: (context, response, child) {
                    if (response.isEmpty) {
                      return const Text(
                          'Aquí apareixerà la resposta del model.');
                    }
                    return SelectableText(response);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
