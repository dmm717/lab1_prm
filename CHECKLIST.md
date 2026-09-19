# PaperChat AI - Implementation Checklist

Dựa trên tài liệu `BUSINESS_WORKFLOW.md` và `SPECIFICATION.md`, dưới đây là danh sách những tính năng đã hoàn thiện ở Frontend, Backend và những gì còn lại cần làm cho bài Lab1:

## 1. Frontend (Thư mục `frontend`)
**Đã hoàn thiện (Done):**
- [x] **Giao diện chính (Dual-Pane UI)**: Chia đôi màn hình chuẩn Desktop (Bên trái: Tổng quan bài báo, Bên phải: Khung Chat).
- [x] **Tiếp nhận bài báo**: Hỗ trợ dán link ArXiv (`ArxivService`) hoặc tải File PDF từ máy tính bằng nút "Upload PDF".
- [x] **Trích xuất thông tin**: Giao diện hiển thị chi tiết Tóm tắt (Summary), Đóng góp (Contributions) và Cấu trúc bài báo.
- [x] **Interactive Keywords**: Hiển thị các Keyword Chips, click vào sẽ tự động gửi câu hỏi chuyên sâu sang khung chat.
- [x] **Khung Chat AI**: Render văn bản theo thời gian thực (Streaming), hỗ trợ định dạng Markdown và công thức toán học LaTeX cực kỳ đẹp mắt.
- [x] **Settings Dialog**: Hộp thoại cấu hình để người dùng nhập/đổi Gemini API Key.
- [x] **Quản lý State**: Sử dụng kiến trúc `Provider` thông qua `PaperController`.

**Đã hoàn thiện (100% Done):**
- [x] **Lưu trữ Offline (Local Storage)**: Đã tích hợp `PaperStorageService` (lưu trữ bằng `SharedPreferences` dưới dạng JSON), hiển thị qua `RecentPapersDialog` kèm badge số lượng bài báo trên AppBar, cho phép mở lại bài cũ lập tức mà không cần mạng hay upload lại.
- [x] **Lưu lịch sử Chat**: Tự động lưu trữ và phục hồi toàn bộ lịch sử tin nhắn trò chuyện của từng bài báo riêng biệt trong `PaperStorageService`; hỗ trợ xuất hội thoại ra định dạng Markdown qua nút Export.
- [x] **Thanh tiến trình (Progress Bar)**: Đã nâng cấp thanh tiến trình hiển thị rõ phần trăm (0% - 100%), thông số dung lượng tải/gửi (MB / MB) và từng giai đoạn xử lý (Downloading -> Uploading -> Parsing & Synthesizing).

---

## 2. Backend (Thư mục `backend`)
**Đã hoàn thiện (Done):**
- [x] **API Server**: Xây dựng thành công bằng Dart Frog chạy tại cổng 8080.
- [x] **Luồng Upload (`/api/papers/upload`)**: 
  - Tiếp nhận file PDF multipart và metadata.
  - Chuyển tiếp PDF sang server GROBID (Docker port 8070).
  - Dịch dữ liệu XML trả về sang cấu trúc Dart (`TeiParserService`).
  - Gọi Gemini API để tự động tổng hợp (Synthesis) ra Summary, Keywords, và Contributions.
- [x] **Luồng Chat (`/api/chat`)**: Nhận câu hỏi và bối cảnh (context) bài báo, mở kết nối stream với Gemini để trả chữ về Frontend theo cơ chế thời gian thực (chunked).
- [x] **Hỗ trợ đa nguồn PDF**: Đã fix luồng để backend hỗ trợ mọi file PDF chứ không chỉ riêng ArXiv (`sourceId`, `sourceUrl`).

**Đã hoàn thiện (100% Done):**
- [x] **Fallback Mechanism (Kế hoạch dự phòng)**: Tích hợp phương thức `parseAndSynthesizePdfDirectly` trong `GeminiService`. Nếu GROBID container bị tắt hoặc gặp lỗi, hệ thống tự động fallback dùng Gemini Multimodal (`DataPart('application/pdf', bytes)`) để đọc trực tiếp file PDF và gắn cờ `isFallback: true`.
- [x] **Bộ nhớ đệm (Caching)**: Đã xây dựng `CacheService` quản lý in-memory RAM cache và file persistence (`.cache/papers/{key}.json`). Phân loại theo ID và mã hash FNV-1a, trả kết quả tức thì (<1s) kèm header `X-Cache: HIT` giúp tiết kiệm chi phí Gemini API.
- [x] **Xử lý lỗi (Error Handling)**: Bắt lỗi chi tiết và trả về các mã HTTP chuẩn (400, 401 cho Invalid Key, 429 cho Rate Limit, 503 cho Service Unavailable) kèm JSON schema `{'error': '...', 'code': '...'}` rõ ràng cho Frontend.

---

## 3. Deployment / Khác
**Đã hoàn thiện (Done):**
- [x] Cấu hình file `docker-compose.yml` để chạy GROBID chuẩn xác (đã có ở cả root và frontend).
- [x] Gộp chung vào 1 Git Repo (Monorepo) để dễ quản lý và nộp bài.
- [x] Hoàn thiện các file tài liệu đặc tả nghiệp vụ (`BUSINESS_WORKFLOW.md`, `SPECIFICATION.md`).
- [x] **Tài liệu nộp bài (`README.md` tại gốc)**: Đã viết file `README.md` toàn diện tại thư mục gốc với sơ đồ kiến trúc, bảng đối chiếu tính năng, hướng dẫn chạy Docker GROBID, lệnh chạy Dart Frog Backend, lệnh chạy Flutter Frontend và danh sách link test.

