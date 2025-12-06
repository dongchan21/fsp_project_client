# 📈 FSP (Financial Strategy Portfolio) Platform

**AI 기반 주식 포트폴리오 백테스팅 및 투자 전략 분석 플랫폼**

FSP는 사용자가 구성한 주식 포트폴리오의 과거 성과를 분석(Backtesting)하고, 생성형 AI를 통해 심층적인 투자 인사이트를 제공하는 웹 애플리케이션입니다.

---

## 🛠 Tech Stack

### Frontend

- **Framework**: Flutter (Web)
- **State Management**: Provider Pattern
- **Hosting**: Firebase Hosting
- **Key Libraries**: `fl_chart` (차트), `http` (통신), `provider`

### Backend (Microservices)

- **Gateway**: Dart Shelf (API Gateway)
- **Services**:
  - **Market Service**: 주가 데이터 수집 및 가공 (Dart)
  - **Backtest Service**: 포트폴리오 수익률 계산 엔진 (Dart)
  - **AI Service**: 투자 전략 분석 및 조언 생성 (Dart/Python)
  - **Price Fetcher**: 외부 금융 데이터 연동 (Python/FastAPI)
- **Infrastructure**: Docker, Docker Compose
- **Connectivity**: Ngrok (Secure Tunneling for Public Access)

---

## ✨ Key Features

1.  **실시간 백테스팅 (Real-time Backtesting)**

    - 미국 주식(AAPL, TSLA 등) 포트폴리오 구성
    - 기간별 수익률, 변동성, MDD(최대 낙폭), 샤프 지수 자동 계산
    - 적립식 투자(DCA) 시뮬레이션 지원

2.  **AI 투자 인사이트 (AI Investment Insights)**

    - 백테스트 결과를 바탕으로 AI가 포트폴리오의 장단점 분석
    - 투자 성향 점수(Score) 산출 및 리밸런싱 제안
    - **Zero-Latency UX**: 백그라운드 프리페칭(Prefetching) 기술로 대기 시간 없는 결과 확인

3.  **데이터 시각화 (Interactive Visualization)**
    - 자산 성장 추이 그래프
    - 포트폴리오 비중 파이 차트
    - 연도별 수익률 히트맵

---

## 🚀 Quick Start

### 1. Backend Setup (Server)

```bash
cd fsp_server
docker compose up -d
# Start Ngrok for public access
ngrok http 8080
```

### 2. Frontend Setup (Client)

```bash
cd fsp_client
flutter pub get
flutter run -d chrome
```

---

## 📂 Project Structure

```
fsp/
├── fsp_client/          # Flutter Web Application
│   ├── lib/
│   │   ├── providers/   # State Management
│   │   ├── services/    # API Clients
│   │   └── screens/     # UI Screens
│   └── web/             # Web Assets
│
└── fsp_server/          # Backend Microservices
    ├── bin/             # Service Entrypoints
    ├── lib/             # Shared Logic
    ├── services/        # Individual Microservices
    │   ├── ai_service/
    │   ├── backtest_service/
    │   └── market_service/
    └── docker-compose.yml
```
