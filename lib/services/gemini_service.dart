import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

class GeminiService {
  final String apiKey;

  GeminiService({required this.apiKey});

  Future<List<String>> listModels() async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> models = data['models'];
        return models
            .where((model) =>
                model['supportedGenerationMethods'].contains('generateContent'))
            .map((model) => (model['name'] as String).replaceFirst('models/', ''))
            .toList();
      } else {
        developer.log(
          'Error fetching models: ${response.statusCode}',
          name: 'myapp.gemini_service',
          level: 1000, // SEVERE
          error: response.body,
        );
        return [];
      }
    } catch (e, s) {
      developer.log(
        'An unexpected error occurred while fetching models',
        name: 'myapp.gemini_service',
        level: 1000, // SEVERE
        error: e,
        stackTrace: s,
      );
      return [];
    }
  }

  String _processText(String text) {
    // Optimized single-pass approach using a combined RegExp.
    // The order of alternatives in the regex is crucial to ensure correct parsing:
    // 1. '***' (separator) must be checked before '**' and '*'.
    // 2. '**bold**' must be checked before '*italic*'.
    // 3. '*' (single) is the last fallback for cleanup.
    final pattern = RegExp(r'(\*{3})|(\*\*([^\*]+?)\*\*)|(\*([^\*]+?)\*)|(\*)');

    String processedText = text.replaceAllMapped(pattern, (match) {
      // Case 1: '***' separator found.
      if (match.group(1) != null) {
        return '\n\n'; // Replace with a significant pause.
      }
      // Case 2: '**bold**' text found.
      if (match.group(2) != null) {
        return match.group(3) ?? ''; // Return only the content inside.
      }
      // Case 3: '*italic*' text found.
      if (match.group(4) != null) {
        return match.group(5) ?? ''; // Return only the content inside.
      }
      // Case 4: A single, unmatched '*' found.
      if (match.group(6) != null) {
        return ' '; // Replace with a space to avoid joining words.
      }
      // This fallback should not be reached with the current regex.
      return '';
    });

    // Convert all-caps words to capitalized form to improve TTS pronunciation.
    // For example, "HOLA" becomes "Hola".
    processedText = processedText.replaceAllMapped(
      RegExp(r'\b(\p{Lu}{2,})\b', unicode: true), // Matches words with 2 or more uppercase letters.
      (match) {
        final word = match.group(1)!;
        // Capitalize the first letter and make the rest lowercase.
        return '${word[0]}${word.substring(1).toLowerCase()}';
      },
    );

    // Finally, normalize multiple whitespace characters into a single space and trim.
    return processedText.replaceAll(RegExp(r'\s+'), ' ').trim();
  }


  Future<String> generateText(String prompt,
      {required String modelName}) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$apiKey');

    final headers = {
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ]
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawText = data['candidates'][0]['content']['parts'][0]['text'] ??
            'No valid text found in response.';
        return _processText(rawText);
      } else {
        String errorMessage = response.body;
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['error']?['message'] ?? response.body;
        } catch (e) {
          // Ignore if the body is not JSON
        }

        developer.log(
          'Error generating text: ${response.statusCode}',
          name: 'myapp.gemini_service',
          level: 1000, // SEVERE
          error: response.body, // Log the full, raw error response
        );

        return 'Error: ${response.statusCode}\nMessage: $errorMessage';
      }
    } catch (e, s) {
      developer.log(
        'An unexpected error occurred while generating text',
        name: 'myapp.gemini_service',
        level: 1000, // SEVERE
        error: e,
        stackTrace: s,
      );
      return 'An unexpected error occurred: $e';
    }
  }
}
