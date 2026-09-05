import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'app/env.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize env non-blockingly so initial frame paints immediately
  Env.init().catchError((_) {});

  runApp(
    const ProviderScope(
      child: RyzonApp(),
    ),
  );
}
