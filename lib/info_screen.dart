import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Informació'),
      ),
      body: FutureBuilder<String>(
        future: rootBundle.loadString('README.md'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error carregant la informació: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          } else {
            return Markdown(
              data: snapshot.data ?? '',
              padding: const EdgeInsets.all(16.0),
              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                p: GoogleFonts.openSans(),
                listBullet: GoogleFonts.openSans(),
              ),
            );
          }
        },
      ),
    );
  }
}