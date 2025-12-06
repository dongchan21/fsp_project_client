# 🏗️ System Architecture & Design Decisions

## 1. Overall Architecture (Microservices)

FSP 프로젝트는 확장성과 유지보수성을 위해 **마이크로서비스 아키텍처(MSA)**를 채택했습니다. 클라이언트는 단일 진입점(Gateway)을 통해 통신하며, 각 서비스는 도커 컨테이너로 격리되어 독립적으로 동작합니다.

```mermaid
graph TD
    Client[Flutter Web Client]
    Gateway[API Gateway (Dart Shelf)]

    subgraph "Backend Services (Docker)"
        Market[Market Service]
        Backtest[Backtest Service]
        AI[AI Insight Service]
        Auth[Auth Service]
    end

    External[External APIs\n(Yahoo Finance / OpenAI)]

    Client -->|HTTP/REST| Gateway
    Gateway --> Market
    Gateway --> Backtest
    Gateway --> AI
    Gateway --> Auth

    Market --> External
    AI --> External
```

---

## 2. Key Technical Decisions & Optimizations

### ⚡ Performance Optimization: AI Analysis Prefetching

**문제 상황 (Problem):**

- 백테스트 완료 후 사용자가 "AI 분석" 탭을 클릭하면, 그제서야 AI 모델에 요청을 보냄.
- AI 응답 생성에 약 **5~8초**가 소요되어 사용자 경험(UX)이 저하됨.

**해결 전략 (Solution): Future Prefetching Pattern**

- 백테스트 결과가 산출되는 즉시(사용자가 탭을 누르기 전), 백그라운드 스레드에서 AI 분석 요청을 **미리 시작(Prefetch)**합니다.
- `PortfolioProvider` 내에 `Future<Map>` 객체를 상태로 저장하여, 중복 요청을 방지하고 결과가 준비되는 대로 UI에 반영합니다.

**구현 로직 (Implementation):**

1.  `runBacktest()` 완료 직후 `_startAiAnalysisPrefetch()` 호출.
2.  UI(`AiAnalysisTab`) 진입 시, 새로운 요청을 생성하지 않고 메모리에 저장된 `aiAnalysisFuture`를 `await`.
3.  **결과:** 사용자가 탭을 클릭했을 때 대기 시간 **0초(Zero Latency)**에 가까운 경험 제공.

```dart
// Code Snippet: Prefetching Logic
void _startAiAnalysisPrefetch() {
  // 백그라운드에서 즉시 실행 및 Future 객체 저장
  _aiAnalysisFuture = Future(() async {
    // ... API Call to AI Service ...
    return analysisResult;
  });
}
```

### 🔒 Security & Connectivity

- **Ngrok Tunneling**: 로컬 개발 환경의 도커 컨테이너를 외부(Firebase Hosting된 웹앱)에서 안전하게 접근하기 위해 Ngrok 터널링을 사용.
- **CORS Handling**: 브라우저 보안 정책 준수를 위해 Nginx 및 Dart Shelf 서버에 올바른 CORS 헤더(`Access-Control-Allow-Origin`) 및 Preflight 처리 구현.

---

## 3. Data Flow

1.  **User Input**: 사용자가 종목(Symbol)과 비중(Weight) 입력.
2.  **Backtest Request**: Gateway를 통해 Backtest Service로 전달.
3.  **Data Fetching**: Market Service가 필요한 과거 주가 데이터를 조회 (Redis 캐싱 활용).
4.  **Calculation**: 수익률 계산 엔진이 포트폴리오 성과 산출.
5.  **AI Analysis (Async)**: 결과 산출 즉시 AI Service가 비동기로 분석 시작.
6.  **Rendering**: Flutter 클라이언트가 차트 및 리포트 렌더링.
