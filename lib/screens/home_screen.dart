import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'backtest_result_screen.dart';
import 'backtest_history_screen.dart';
import 'login_screen.dart';
import 'board/board_list_screen.dart';
import '../widgets/home/portfolio_card.dart';
import '../widgets/home/date_card.dart';
import '../widgets/home/capital_card.dart';
import '../widgets/home/run_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showBacktestResult = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().checkLoginStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Tooltip(
                message: '첫 화면으로 돌아가기',
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _showBacktestResult = false;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/logo.png',
                          height: 24,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.bar_chart_rounded),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'AI 기반 백테스트 플랫폼',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: const TabBar(
                    tabs: [
                      Tab(text: '백테스트'),
                      Tab(text: '공유 게시판'),
                    ],
                    labelColor: Colors.black87,
                    unselectedLabelColor: Colors.grey,
                    indicatorSize: TabBarIndicatorSize.label,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            if (authProvider.isLoggedIn) ...[
              IconButton(
                icon: const Icon(Icons.history),
                tooltip: '백테스트 히스토리',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BacktestHistoryScreen()),
                  );
                },
              ),
              Center(
                child: Text(
                  '${authProvider.user?['nickname'] ?? '사용자'}님',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: '로그아웃',
                onPressed: () {
                  authProvider.logout();
                },
              ),
            ] else
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                icon: const Icon(Icons.login),
                label: const Text('로그인'),
              ),
            const SizedBox(width: 8),
          ],
        ),
        body: TabBarView(
          children: [
            _buildBacktestTab(),
            const BoardListScreen(showAppBar: false),
          ],
        ),
      ),
    );
  }

  Widget _buildBacktestTab() {
    if (_showBacktestResult) {
      return BacktestResultScreen(
        onBack: () {
          setState(() {
            _showBacktestResult = false;
          });
        },
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          const PortfolioCard(),
          const SizedBox(height: 24),
          const DateCard(),
          const SizedBox(height: 24),
          const CapitalCard(),
          const SizedBox(height: 32),
          RunButton(
            onResult: () {
              setState(() {
                _showBacktestResult = true;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.bar_chart_rounded, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('백테스트 설정', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('종목과 투자 조건을 설정하세요', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
            ],
          ),
        ),
      ],
    );
  }
}
