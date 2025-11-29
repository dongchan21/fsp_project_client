import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/portfolio_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
void main() async {
  await dotenv.load(fileName: "assets/.env");
  runApp(MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PortfolioProvider(),
      child: MaterialApp(
        title: 'FSP 클라이언트',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          fontFamily: 'Pretendard', // 사용자 제공 폰트 (pubspec에 추가 및 실제 파일 필요)
          textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Pretendard'),
        ),
        locale: const Locale('ko', 'KR'),
        supportedLocales: const [
          Locale('ko', 'KR'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const HomeScreen(),
      ),
    );
  }
}
