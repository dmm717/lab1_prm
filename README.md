# PaperChat AI — Academic Research Paper Dialogue System

> **PRM393 — Lab 1 Project**  
> An intelligent academic paper analysis and conversational dialogue desktop platform powered by **GROBID (TEI-XML)**, **Google Gemini (2.0 Flash / 1.5 Pro)**, **Dart Frog**, and **Flutter Desktop**.

---

## 📌 Tổng Quan Dự Án (Project Overview)

**PaperChat AI** giải quyết bài toán đọc và thấu hiểu các bài báo khoa học dài và phức tạp bằng cách kết hợp:
1. **GROBID Server (Docker)**: Bóc tách cấu trúc tài liệu PDF thành định dạng chuẩn hóa TEI-XML (tiêu đề, tác giả, tóm tắt, dàn ý các mục, trích dẫn).
2. **Gemini Multimodal Fallback**: Tự động chuyển sang chế độ AI đọc trực tiếp file PDF nếu server GROBID chưa được khởi chạy hoặc gặp lỗi.
3. **Google Gemini AI (1M+ Token Context)**: Đọc hiểu sâu toàn bộ bài báo, tự động trích xuất Tóm tắt điều hành (Executive Summary), Đóng góp cốt lõi (Contributions), Từ khóa tương tác (Interactive Keywords) và giải đáp thắc mắc với Streaming Markdown & LaTeX equations.
4. **Offline Persistence**: Tự động lưu trữ thư viện bài báo và lịch sử trò chuyện cục bộ trên máy tính.

---

## 🏛️ Kiến Trúc Hệ Thống (System Architecture)

```
                       +-------------------------------+
                       |   Flutter Desktop (Frontend)  |
                       |       Port: Native App        |
                       +---------------+---------------+
                                       |
                                       | HTTP REST & Streaming
                                       v
                       +---------------+---------------+
                       |    Dart Frog Backend API      |
                       |          Port: 8080           |
                       +-------+---------------+-------+
                               |               |
               PDF Multipart   |               | Structured Context
                     v         |               | + Prompt
        +----------------------+               +-----------------------+
        |                                                              |
        v                                                              v
+-------------------------------+                     +-------------------------------+
|     GROBID Docker Server      |                     |      Google Gemini 2.0/1.5    |
|          Port: 8070           |                     |          Cloud REST API       |
+-------------------------------+                     +-------------------------------+
```

---

## ✅ Bảng Tính Năng Hoàn Thiện (Checklist Compliance)

| Thành phần | Tính năng | Trạng thái | Mô tả |
| :--- | :--- | :---: | :--- |
| **Frontend** | **Dual-Pane Layout** | ✅ Done | Chia đôi màn hình chuẩn Desktop: Tổng quan/Dàn ý bên trái, Khung Chat bên phải |
| **Frontend** | **ArXiv & File Upload** | ✅ Done | Tự động tải từ link ArXiv hoặc chọn file PDF từ máy tính |
| **Frontend** | **Interactive Keywords** | ✅ Done | Chip từ khóa phân loại theo màu, click để AI tự động giải thích chuyên sâu |
| **Frontend** | **Streaming Chat & Math** | ✅ Done | Trả lời thời gian thực, render Markdown, bảng biểu và công thức toán LaTeX |
| **Frontend** | **Offline Library (Storage)**| ✅ Done | Lưu danh sách bài báo đã parse, mở lại tức thì không cần tải lại |
| **Frontend** | **Persistent Chat History** | ✅ Done | Lưu và phục hồi lịch sử trò chuyện theo từng bài báo; hỗ trợ Export Markdown |
| **Frontend** | **Granular Progress Bar** | ✅ Done | Hiển thị phần trăm (%) và thông số dung lượng MB chi tiết theo từng công đoạn |
| **Backend** | **API Server (Dart Frog)** | ✅ Done | REST API server chạy tại cổng 8080 |
| **Backend** | **GROBID Integration** | ✅ Done | Gửi PDF sang GROBID Docker (port 8070) bóc tách TEI-XML |
| **Backend** | **Gemini Synthesis & Chat** | ✅ Done | Tự động phân tích đóng góp/từ khóa và stream câu trả lời chat |
| **Backend** | **Multimodal Fallback** | ✅ Done | Tự động chuyển sang Gemini PDF direct ingestion nếu GROBID offline |
| **Backend** | **In-Memory & File Cache** | ✅ Done | Cache kết quả phân tích theo SHA-256 / ID, trả kết quả < 1s cho file trùng |
| **Backend** | **Structured Errors** | ✅ Done | Trả mã lỗi và thông báo chi tiết (401 Invalid Key, 429 Quota Exceeded,...) |

---

## 🚀 Hướng Dẫn Cài Đặt & Chạy Ứng Dụng (Quickstart)

### 1. Yêu Cầu Môi Trường (Prerequisites)
- [Docker & Docker Desktop](https://www.docker.com/) (Dùng để chạy GROBID)
- [Dart SDK](https://dart.dev/get-dart) (`>= 3.0.0`)
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (`>= 3.10.0`)
- [Dart Frog CLI](https://dart-frog.dev/docs/overview) (Cài qua: `dart pub global activate dart_frog_cli`)

---

### 2. Bước 1: Khởi Chạy GROBID Server (Docker)
Tại thư mục gốc của dự án, chạy lệnh:

```bash
docker compose up -d
```
*Hoặc khởi chạy trực tiếp bằng Docker:*
```bash
docker run -t --rm --init -p 8070:8070 grobid/grobid:0.8.1
```

> **Kiểm tra trạng thái:** Mở trình duyệt truy cập `http://localhost:8070/api/isalive` -> Trả về `true` là thành công.  
> *(Lưu ý: Nếu không bật Docker, hệ thống vẫn hoạt động bình thường nhờ cơ chế Gemini Multimodal Fallback).*

---

### 3. Bước 2: Khởi Chạy Backend (Dart Frog)
Mở một cửa sổ Terminal mới:

```bash
cd backend
dart pub get
dart_frog dev
```
Backend sẽ khởi chạy tại: `http://localhost:8080`.

---

### 4. Bước 3: Khởi Chạy Frontend (Flutter Desktop)
Mở một cửa sổ Terminal khác:

```bash
cd frontend
flutter pub get

# Chạy trên macOS
flutter run -d macos

# Hoặc chạy trên Windows
flutter run -d windows
```

---

## 🔑 Hướng Dẫn Cấu Hình API Key & Sử Dụng

1. **Nhập Google Gemini API Key**:
   - Bấm vào biểu tượng **Cài đặt (bánh răng)** ở góc trên bên phải ứng dụng.
   - Nhập Gemini API Key miễn phí lấy từ [Google AI Studio](https://aistudio.google.com/).
   - Chọn Model:
     - `Gemini 2.0 Flash`: Tốc độ cực nhanh, tối ưu chi phí (Mặc định).
     - `Gemini 1.5 Pro`: Suy luận học thuật chuyên sâu và suy diễn công thức toán học.
   - Bấm **Save Changes**.

2. **Phân Tích Bài Báo Khoa Học**:
   - **Cách 1 (ArXiv Link)**: Dán link bài báo vào thanh tìm kiếm hoặc bấm các link mẫu có sẵn:
     - *Transformer*: `https://arxiv.org/abs/1706.03762`
     - *GPT-3*: `https://arxiv.org/abs/2005.14165`
     - *Mamba (SSM)*: `https://arxiv.org/abs/2312.00752`
   - **Cách 2 (File PDF)**: Bấm nút **Upload PDF** và chọn file bài báo có sẵn trong máy tính.

3. **Tương Tác & Hỏi Đáp AI**:
   - Bấm trực tiếp vào các **Keyword Chips** màu sắc để hỏi AI phân tích khái niệm đó trong ngữ cảnh bài báo.
   - Gõ câu hỏi tự do vào khung chat bên phải để yêu cầu tóm tắt mục, giải thích công thức, hoặc so sánh với các nghiên cứu khác.
   - Bấm biểu tượng **Export (Tải xuống)** trong khung chat để sao chép toàn bộ hội thoại ra file Markdown.

4. **Quản Lý Thư Viện Offline**:
   - Bấm biểu tượng **Thư viện (Bookmark)** trên thanh tiêu đề để xem lại các bài báo đã đọc trước đó mà không cần kết nối mạng hay tải lại.

---

## 📂 Cấu Trúc Thư Mục Dự Án (Monorepo Tree)

```
.
├── docker-compose.yml              # Cấu hình GROBID Docker (Port 8070)
├── CHECKLIST.md                    # Danh sách kiểm tra tiến độ Lab 1
├── README.md                       # Tài liệu hướng dẫn nộp bài & khởi chạy
│
├── backend/                        # Dart Frog Backend Server (Port 8080)
│   ├── routes/
│   │   ├── index.dart              # Healthcheck endpoint
│   │   └── api/
│   │       ├── papers/upload.dart  # Upload PDF -> Caching -> GROBID / Gemini Fallback
│   │       └── chat.dart           # Streaming AI Chat grounded in paper context
│   ├── lib/
│   │   ├── services/
│   │   │   ├── grobid_service.dart # Giao tiếp container GROBID
│   │   │   ├── tei_parser_service.dart # Bóc tách cấu trúc TEI-XML
│   │   │   ├── gemini_service.dart # Gemini synthesis, chat & multimodal fallback
│   │   │   └── cache_service.dart  # In-memory & local file cache (SHA-256)
│   │   └── models/                 # PaperModel, ChatMessage, KeywordModel
│   └── pubspec.yaml
│
└── frontend/                       # Flutter Desktop Application
    ├── BUSINESS_WORKFLOW.md        # Đặc tả chi tiết nghiệp vụ luồng hoạt động
    ├── SPECIFICATION.md            # Tài liệu đặc tả kỹ thuật hệ thống
    ├── lib/
    │   ├── main.dart               # Entry point
    │   ├── controllers/
    │   │   └── paper_controller.dart # Quản lý trạng thái, thư viện & chat history
    │   ├── services/
    │   │   ├── arxiv_service.dart  # Tải PDF từ ArXiv CDN
    │   │   ├── backend_service.dart# Giao tiếp Dart Frog Backend
    │   │   └── paper_storage_service.dart # Lưu trữ offline (SharedPreferences)
    │   └── views/
    │       ├── home/home_screen.dart # Giao diện chính Dual-Pane
    │       └── widgets/            # Overview, Chat, Keywords, Progress, Library
    └── pubspec.yaml
```
