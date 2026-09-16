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

**Còn lại cần làm (To-Do):**
- [ ] **Lưu trữ Offline (Local Storage)**: Tích hợp `Hive` hoặc `sqflite` để lưu lại danh sách các bài báo đã parse, cho phép người dùng mở lại bài cũ mà không cần gọi mạng hoặc upload lại.
- [ ] **Lưu lịch sử Chat**: Cho phép xem lại lịch sử trò chuyện của các bài báo trước đó.
- [ ] **Thanh tiến trình (Progress Bar)**: Cải thiện hiển thị chi tiết phần trăm (%) tải file PDF hoặc phần trăm phân tích của AI.

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

**Còn lại cần làm (To-Do):**
- [ ] **Fallback Mechanism (Kế hoạch dự phòng)**: Nếu GROBID Docker chưa được bật hoặc bị lỗi, tự động chuyển sang chế độ đẩy thẳng file PDF lên Gemini Multimodal để nó tự đọc (để không bị chặn luồng của user).
- [ ] **Bộ nhớ đệm (Caching)**: Lưu kết quả phân tích TEI-XML hoặc Synthesis của một `sourceId` vào RAM hoặc Redis để lần sau upload lại đúng file đó thì trả kết quả luôn (giúp tiết kiệm tiền gọi Gemini API).
- [ ] **Xử lý lỗi (Error Handling)**: Bắt lỗi chi tiết hơn khi Gemini bị quá tải (Rate limit), hoặc user nhập sai/API key hết hạn để trả về mã lỗi rõ ràng cho Frontend hiển thị.

---

## 3. Deployment / Khác
**Đã hoàn thiện (Done):**
- [x] Cấu hình file `docker-compose.yml` để chạy GROBID chuẩn xác.
- [x] Gộp chung vào 1 Git Repo (Monorepo) để dễ quản lý và nộp bài.
- [x] Hoàn thiện các file tài liệu đặc tả nghiệp vụ (`BUSINESS_WORKFLOW.md`, `SPECIFICATION.md`).

**Còn lại cần làm (To-Do):**
- [ ] Viết `README.md` (ở thư mục gốc) hướng dẫn nộp bài cụ thể (Cách bật Docker, cấu hình API Key, lệnh chạy FE, lệnh chạy BE).
