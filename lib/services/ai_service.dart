import 'dart:convert';
import 'package:http/http.dart' as http;

/// Gemini 기반 AI 인사이트 생성 서비스
Future<Map<String, dynamic>> generateAiInsight(Map<String, dynamic> body) async {
  final portfolio = body['portfolio'] ?? {};
  final metrics = body['metrics'] ?? {};

  // ---------- 포트폴리오 구성 텍스트 ----------
  final symbols = (portfolio['symbols'] as List?)?.join(', ') ?? '미제공';
  final weights = (portfolio['weights'] as List?)
          ?.map((w) => '${(w * 100).toStringAsFixed(0)}%')
          .join(', ') ??
      '';

  String symbolWeightText = '포트폴리오 구성 정보 없음';
  if (portfolio['symbols'] != null && portfolio['weights'] != null) {
    final s = portfolio['symbols'] as List;
    final w = portfolio['weights'] as List;
    if (s.length == w.length) {
      symbolWeightText = List.generate(
          s.length,
          (i) => "${s[i]}: ${(w[i] * 100).toStringAsFixed(0)}%"
      ).join(', ');
    }
  }

  // ---------- 성과 지표 텍스트 ----------
  final totalReturn = metrics['totalReturn'] ?? 0.0;
  final annualizedReturn = metrics['annualizedReturn'] ?? 0.0;
  final volatility = metrics['volatility'] ?? 0.0;
  final sharpeRatio = metrics['sharpeRatio'] ?? 0.0;
  final maxDrawdown = metrics['maxDrawdown'] ?? 0.0;

  // ---------- Gemini용 프롬프트 ----------
  final prompt = """
당신은 전문 투자 어드바이저입니다.
아래는 사용자의 포트폴리오 구성 및 백테스트 성과 요약입니다.

[포트폴리오 구성]
$symbolWeightText

[성과 요약]
- 총 수익률: ${(totalReturn * 100).toStringAsFixed(2)}%
- 연 환산 수익률: ${(annualizedReturn * 100).toStringAsFixed(2)}%
- 변동성: ${(volatility * 100).toStringAsFixed(2)}%
- 샤프 지수: ${sharpeRatio.toStringAsFixed(2)}
- 최대 낙폭: ${(maxDrawdown * 100).toStringAsFixed(2)}%

이 데이터를 바탕으로 다음 형식(JSON)으로 작성하세요:

{
  "summary": "포트폴리오 성향 요약 (예: 성장형, 균형형 등)",
  "evaluation": "전반적 평가 (100자 내외)",
  "analysis": "성과의 원인 분석 (200자 내외)",
  "suggestion": "개선 및 보완 제안 (200자 내외)",
  "investorType": "추천 투자자 유형 (예: 위험 감수형, 안정추구형 등)"
}
""";

  // ---------- Gemini API 호출 ----------
  final apiKey = 'AIzaSyCaS0EJ_mKJzqrilCMj10wEzc_f6FG3j7Q'; // ✅ API 키 입력
  final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey');

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt}
            ]
          }
        ]
      }),
    );

    if (response.statusCode != 200) {
      return {
        "error": "Gemini API 요청 실패",
        "status": response.statusCode,
        "response": response.body
      };
    }

    final result = jsonDecode(response.body);

    // Gemini는 응답이 nested 구조로 들어옵니다.
    final aiText = result['candidates']?[0]?['content']?['parts']?[0]?['text'];

    if (aiText == null) {
       return {"error": "AI 응답이 비어있습니다."};
    }

    // ---------- JSON 파싱 시도 ----------
    // 마크다운 코드 블록 제거 (```json ... ```)
    String cleanText = aiText.replaceAll(RegExp(r'^```json\s*|\s*```$'), '').trim();
    // 혹시 ``` 만 있는 경우도 처리
    cleanText = cleanText.replaceAll(RegExp(r'^```\s*|\s*```$'), '').trim();

    Map<String, dynamic>? parsed;
    try {
      parsed = jsonDecode(cleanText);
    } catch (e) {
      parsed = {"rawText": aiText};
    }

    return {
      "aiInsight": parsed,
      "promptUsed": prompt,
    };
  } catch (e) {
    return {
      "error": "API 호출 중 오류 발생: $e"
    };
  }
}
