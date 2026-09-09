# PaperChat AI — Desktop Application

> An intelligent desktop application for academic researchers to analyze, extract, and converse with scientific papers using **GROBID** and **Google Gemini** (Gemini 2.0 Flash / 1.5 Pro).

---

## 📁 Project Architecture & File Tree

```
d:/FPT/SEM_8/PRM393/LAB1/
├── docker-compose.yml             # Local GROBID Docker service configuration
├── pubspec.yaml                   # Flutter dependencies & environment setup
├── SPECIFICATION.md               # Complete System Requirements & Architecture Specification
├── README.md                      # Quickstart and setup guide
└── lib/
    ├── main.dart                  # Application entry point with MultiProvider
    ├── core/
    │   ├── constants/
    │   │   └── app_constants.dart # Endpoints, models, and JSON schema prompts
    │   └── theme/
    │       └── app_theme.dart     # Slate dark-mode theme & academic styling
    ├── models/
    │   ├── chat_message.dart      # Chat messages with streaming state & citations
    │   ├── keyword_model.dart     # Categorized keywords and contextual usage
    │   └── paper_model.dart       # Structured paper model with sections and outline
    ├── services/
    │   ├── arxiv_service.dart     # ArXiv ID extractor & binary PDF stream downloader
    │   ├── grobid_service.dart    # REST client for local Dockerized GROBID container
    │   ├── tei_parser_service.dart# TEI-XML parser extracting sections, title, authors
    │   └── gemini_service.dart    # Gemini 2.0/1.5 API integration (synthesis & streaming chat)
    ├── controllers/
    │   └── paper_controller.dart  # Pipeline orchestrator & reactive state management
    └── views/
        ├── home/
        │   └── home_screen.dart   # Main Dual-Pane layout (Overview + Chat)
        └── widgets/
            ├── arxiv_input_bar.dart        # URL input, sample papers & progress bar
            ├── chat_panel.dart             # Markdown chat, LaTeX math, suggested prompts
            ├── grobid_status_badge.dart    # Real-time GROBID Docker status badge
            ├── keyword_chips_panel.dart    # Interactive category-colored keyword chips
            ├── paper_overview_panel.dart   # Paper metadata, summary, and sections tree
            └── settings_dialog.dart        # API Key, Model selector, and GROBID endpoint
```

---

## 🚀 Quick Start Guide

### Step 1: Start the Local GROBID Server (Docker)

Make sure Docker Desktop is running on your machine, then run:

```powershell
docker compose up -d
```
*Or run directly with docker:*
```powershell
docker run -t --rm --init -p 8070:8070 grobid/grobid:0.8.1
```

To verify GROBID is running:
- Open your browser or terminal and check: `http://localhost:8070/api/isalive` (should return `true`).

---

### Step 2: Install Flutter (When Ready)

If you haven't installed Flutter yet:
1. Download Flutter SDK for Windows from [flutter.dev](https://docs.flutter.dev/get-started/install/windows).
2. Extract the zip to a path like `C:\src\flutter`.
3. Add `C:\src\flutter\bin` to your System `PATH` environment variable.
4. Run `flutter doctor` to ensure the Windows desktop toolchain is ready.

---

### Step 3: Run the PaperChat AI Desktop App

Inside this project directory (`d:\FPT\SEM_8\PRM393\LAB1`):

```powershell
# 1. Fetch dependencies
flutter pub get

# 2. Run the application on Windows Desktop
flutter run -d windows
```

---

### Step 4: Configure Your Gemini API Key

1. Click the **Settings (gear icon)** on the top right corner of the app.
2. Enter your free Google Gemini API Key from [Google AI Studio](https://aistudio.google.com/).
3. Choose your preferred model tier:
   - **Gemini 2.0 Flash**: Ultra-fast, responsive, and cost-effective (Default).
   - **Gemini 1.5 Pro**: Maximum academic reasoning and deep equation derivation.
4. Click **Save Changes**.

---

### Step 5: Ingest & Chat with Papers

1. Paste any ArXiv URL into the top search bar:
   - Example: `https://arxiv.org/abs/2312.00752` (Mamba: Linear-Time Sequence Modeling)
   - Or click one of the quick sample chips (*Transformer*, *GPT-3*, *Mamba*).
2. Click **Analyze Paper**:
   - The app will stream the PDF from ArXiv.
   - Send the PDF to your local GROBID container to extract structured TEI-XML.
   - Parse the sections, abstract, authors, and document hierarchy.
   - Call Gemini to extract an Executive Summary and categorized **Interactive Keyword Chips**.
3. **Chat & Explore**:
   - Click any keyword chip to ask Gemini about that specific concept in the paper.
   - Ask custom questions about methodologies, compare theorems, or request code implementations.
