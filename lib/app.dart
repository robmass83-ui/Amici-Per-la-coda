import 'package:flutter/material.dart';

import 'ui/tokens.dart';

/// Radice dell'applicazione. Routing e tema completo arrivano negli step successivi.
class AmiciPerLaCodaApp extends StatelessWidget {
  const AmiciPerLaCodaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Amici per la Coda',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        visualDensity: VisualDensity.compact,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: AppColor.bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColor.green,
          brightness: Brightness.light,
          primary: AppColor.green,
          surface: AppColor.bg,
        ),
      ),
      home: const EmptyHomePage(),
    );
  }
}

/// Schermata vuota dello Step 1: solo lo sfondo del design system.
class EmptyHomePage extends StatelessWidget {
  const EmptyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColor.bg,
      body: SizedBox.expand(),
    );
  }
}
