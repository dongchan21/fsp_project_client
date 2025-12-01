import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/board_client_service.dart';
import '../../providers/auth_provider.dart';
import 'post_detail_screen.dart';
import 'create_post_screen.dart';
import '../login_screen.dart';

class BoardListScreen extends StatefulWidget {
  final bool showAppBar;
  const BoardListScreen({super.key, this.showAppBar = true});

  @override
  State<BoardListScreen> createState() => _BoardListScreenState();
}

class _BoardListScreenState extends State<BoardListScreen> {
  late Future<List<dynamic>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _refreshPosts();
  }

  void _refreshPosts() {
    setState(() {
      _postsFuture = BoardClientService.getPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('포트폴리오 공유 게시판'),
            )
          : null,
      body: FutureBuilder<List<dynamic>>(
        future: _postsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('오류 발생: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('게시글이 없습니다.'));
          }

          final posts = snapshot.data!;
          return ListView.separated(
            itemCount: posts.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final post = posts[index];
              final date = DateTime.parse(post['created_at']).toLocal();
              final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(date);
              
              // 포트폴리오 데이터 파싱
              final portfolioData = post['portfolio_data'] as Map<String, dynamic>?;
              String portfolioSummary = '';
              String aiScoreText = '';

              if (portfolioData != null) {
                // 종목 및 비중 요약
                if (portfolioData['symbols'] != null && portfolioData['weights'] != null) {
                  final symbols = List<String>.from(portfolioData['symbols']);
                  final weights = List<dynamic>.from(portfolioData['weights']);
                  final summaryList = <String>[];
                  for (int i = 0; i < symbols.length; i++) {
                    if (i < weights.length) {
                      final weight = (weights[i] as num).toDouble();
                      summaryList.add('${symbols[i]}(${(weight * 100).toStringAsFixed(0)}%)');
                    }
                  }
                  portfolioSummary = summaryList.join(', ');
                }

                // AI 점수 확인
                if (portfolioData['aiScore'] != null) {
                  final score = portfolioData['aiScore']['total'];
                  if (score != null) {
                    aiScoreText = 'AI 점수: ${score}점';
                  }
                }
              }

              return ListTile(
                title: Text(
                  post['title'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      post['content'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // 포트폴리오 요약 및 AI 점수 표시
                    if (portfolioSummary.isNotEmpty)
                      Text(
                        '📊 $portfolioSummary',
                        style: TextStyle(fontSize: 12, color: Colors.blue[700], fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (aiScoreText.isNotEmpty)
                      Text(
                        '🤖 $aiScoreText',
                        style: TextStyle(fontSize: 12, color: Colors.purple[700], fontWeight: FontWeight.bold),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      '작성자: ${post['author_name']} | $formattedDate',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PostDetailScreen(postId: post['id']),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      // 글쓰기 버튼 제거됨 (백테스트 결과 페이지에서만 작성 가능)
    );
  }
}
