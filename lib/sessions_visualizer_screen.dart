import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class SessionsVisualizerScreen extends StatefulWidget {
  const SessionsVisualizerScreen({super.key});

  @override
  State<SessionsVisualizerScreen> createState() => _SessionsVisualizerScreenState();
}

class _SessionsVisualizerScreenState extends State<SessionsVisualizerScreen> {
  final PageController _pageController = PageController();
  List<Map<String, dynamic>> _sessions = [];
  bool _isLoading = true;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page?.round() ?? 0;
      });
    });
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final conversationHistory = prefs.getStringList('conversationHistory') ?? [];
    
    _sessions = [];
    if (conversationHistory.isNotEmpty) {
      List<List<String>> sessionBlocks = [];
      List<String> currentBlock = [];
      List<String?> sessionStoredDates = [];
      String? currentSessionStoredDate;

      const sessionStartMarker = "Bon dia, soc n'Aina i estic preparada per la següent sessió!";

      for (var message in conversationHistory) {
        // Detectar si el missatge té el format nou amb timestamp |...|
        // Fix: escaped the pipes and backslashes in the regex
        final timestampMatch = RegExp(r'\|(\d{2}/\d{2}/\d{4} \d{2}:\d{2})\|').firstMatch(message);
        String? messageTimestamp = timestampMatch?.group(1);
        
        // Netejar el missatge de la marca de temps per a la detecció
        String cleanMessage = message.replaceAll(RegExp(r'\|.*?\|\s*'), '');

        if (cleanMessage.startsWith("User: $sessionStartMarker")) {
          if (currentBlock.isNotEmpty) {
            sessionBlocks.add(currentBlock);
            sessionStoredDates.add(currentSessionStoredDate);
          }
          currentBlock = [message]; // Guardem el missatge original (amb |ts| si en té)
          currentSessionStoredDate = messageTimestamp;
        } else {
          currentBlock.add(message);
        }
      }
      if (currentBlock.isNotEmpty) {
        sessionBlocks.add(currentBlock);
        sessionStoredDates.add(currentSessionStoredDate);
      }

      DateTime today = DateTime.now();
      for (int i = 0; i < sessionBlocks.length; i++) {
        String? displayDate;
        
        if (sessionStoredDates[i] != null) {
          displayDate = sessionStoredDates[i];
        } else {
          // Reconstrucció històrica si no hi ha data guardada
          int daysBack = (sessionBlocks.length - 1) - i;
          DateTime sessionDateTime = today.subtract(Duration(days: daysBack));
          displayDate = DateFormat('dd/MM/yyyy').format(sessionDateTime);
        }
        
        _sessions.add({
          'date': displayDate,
          'messages': sessionBlocks[i],
        });
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Sessions'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : PageView.builder(
              controller: _pageController,
              itemCount: _sessions.length,
              itemBuilder: (context, index) {
                final session = _sessions[index];
                final sessionDate = session['date'] as String?;
                final messages = session['messages'] as List<String>;

                return Column(
                  children: [
                    if (sessionDate != null)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Sessió del $sessionDate',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: messages.length,
                        itemBuilder: (context, messageIndex) {
                          final message = messages[messageIndex];
                          final isUser = message.contains('User:');
                          return Align(
                            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.all(12.0),
                              margin: const EdgeInsets.symmetric(vertical: 4.0),
                              decoration: BoxDecoration(
                                color: isUser ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Text(
                                message
                                    .replaceFirst(isUser ? 'User: ' : 'AI: ', '')
                                    .replaceAll(RegExp(r'\|.*?\|\s*'), ''), // Remove timestamp from UI
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
      bottomNavigationBar: _sessions.length > 1
          ? BottomAppBar(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _currentPage == 0
                        ? null
                        : () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                  ),
                  Text('Sessió ${_currentPage + 1}/${_sessions.length}'),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: _currentPage == _sessions.length - 1
                        ? null
                        : () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                  ),
                ],
              ),
            )
          : null,
    );
  }
}