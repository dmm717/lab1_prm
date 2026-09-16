import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/paper_controller.dart';
import 'core/theme/app_theme.dart';
import 'views/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PaperChatApp());
}

class PaperChatApp extends StatelessWidget {
  const PaperChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PaperController()),
      ],
      child: MaterialApp(
        title: 'PaperChat AI — Academic Paper Dialogue',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const HomeScreen(),
      ),
    );
  }
}
