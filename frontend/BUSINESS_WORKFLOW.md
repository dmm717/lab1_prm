# Tài liệu Nghiệp vụ & Luồng Hoạt động (Business Workflow) — PaperChat AI

Dự án **PaperChat AI** là một phần mềm trên máy tính giúp bạn đọc và trò chuyện với các bài báo khoa học một cách dễ dàng. Phần mềm này dùng **GROBID** để đọc file PDF và **Google Gemini AI** để hiểu sâu nội dung, tóm tắt và trả lời các câu hỏi của bạn.

---

## 1. Hệ thống hoạt động như thế nào? (Kiến trúc tổng quan)

Hệ thống có 4 phần chính cùng làm việc với nhau:

1. **Giao diện người dùng (Frontend - Flutter)**: Nơi bạn thao tác, tải bài báo lên và chat với AI.
2. **Máy chủ xử lý (Backend API)**: Đứng ở giữa, nhận file PDF từ bạn, gửi đi phân tích và trả kết quả về màn hình.
3. **Bộ đọc PDF (GROBID)**: Giống như một chuyên gia bóc tách tài liệu, nó chuyển đổi file PDF thành văn bản có cấu trúc rõ ràng (nhận diện được tiêu đề, tác giả, các chương mục).
4. **Trí tuệ nhân tạo (Google Gemini AI)**: "Bộ não" chính giúp đọc toàn bộ bài báo, tóm tắt ý chính và trả lời câu hỏi của bạn.

---

## 2. Chi tiết Luồng Nghiệp vụ (Các bước hoạt động)

### 📥 Bước 1: Đưa bài báo vào hệ thống
Có 2 cách để bạn tải một bài báo khoa học vào ứng dụng:
- **Dán link từ ArXiv**: Bạn copy một đường link bài báo trên trang ArXiv (ví dụ: `https://arxiv.org/abs/2312.00752`) và dán vào thanh tìm kiếm. Ứng dụng sẽ tự động tải file PDF đó về.
- **Tải file từ máy tính**: Bạn bấm nút "Upload PDF" và chọn một file bài báo bất kỳ có sẵn trên máy tính của bạn (có thể tải từ IEEE, Springer, Nature, ACM,...).

### ⚙️ Bước 2: Phân tích bài báo
Sau khi nhận được file PDF, hệ thống sẽ làm 3 việc tự động:
1. **Bóc tách nội dung**: File PDF được gửi cho phần mềm GROBID để "đọc" và trích xuất ra văn bản, nhận diện đâu là phần tóm tắt (abstract), đâu là từng chương của bài báo.
2. **Sắp xếp dữ liệu**: Hệ thống gom các thông tin vừa đọc được thành một bộ hồ sơ gọn gàng (bao gồm tên bài, tác giả, dàn ý).
3. **AI Tổng hợp**: Hệ thống gửi bộ hồ sơ này cho Gemini AI. AI sẽ đọc lướt thật nhanh và trả về cho bạn:
   - Một đoạn tóm tắt tổng quan bài báo.
   - Các đóng góp hay phát hiện nổi bật nhất.
   - Các từ khóa chuyên môn quan trọng.
   - Một số câu hỏi gợi ý hay để bạn có thể bắt đầu hỏi AI.

### 🖥️ Bước 3: Hiển thị kết quả trên màn hình
Sau khi phân tích xong, màn hình sẽ chia làm 2 phần rất dễ nhìn:
- **Cột bên trái (Tổng quan bài báo)**: Hiển thị thông tin chung, tóm tắt, từ khóa chính và dàn ý của bài báo.
- **Cột bên phải (Khung Chat)**: Trợ lý AI sẽ xuất hiện, gửi lời chào và chờ bạn đặt câu hỏi.

### 💬 Bước 4: Trò chuyện và Đào sâu kiến thức
1. **Hỏi đáp**: Bạn có thể gõ câu hỏi bất kỳ về bài báo, hoặc bấm thẳng vào các từ khóa (Keyword) ở cột bên trái để hỏi nhanh mà không cần gõ.
2. **AI Trả lời**: Câu hỏi của bạn cùng với nội dung bài báo sẽ được chuyển cho Gemini AI để tìm câu trả lời chính xác nhất.
3. **Hiển thị trực tiếp**: AI sẽ vừa suy nghĩ vừa in câu trả lời ra màn hình ngay lập tức giống như đang gõ chữ (hiệu ứng streaming), hỗ trợ hiển thị cả công thức toán học và bảng biểu cực kỳ rõ ràng.

---

## 3. Bảng tra cứu các thư mục/file quan trọng dành cho Lập trình viên

Dưới đây là các file mã nguồn đảm nhận các chức năng trên (dành cho lập trình viên muốn tìm hiểu sâu):

| Thành phần | Đường dẫn File | Mô tả Chức năng |
| :--- | :--- | :--- |
| **Đặc tả dự án** | [SPECIFICATION.md](SPECIFICATION.md) | Tài liệu mô tả yêu cầu chức năng, kiến trúc và thiết kế prompt |
| **Docker Config** | [docker-compose.yml](docker-compose.yml) | Cấu hình chạy container GROBID Server (Port 8070) |
| **Controller chính** | [paper_controller.dart](lib/controllers/paper_controller.dart) | Quản lý trạng thái ứng dụng (Giao diện, API key, Lịch sử chat) |
| **ArXiv Service** | [arxiv_service.dart](lib/services/arxiv_service.dart) | Trích xuất ID và tải file PDF từ ArXiv |
| **Backend Client** | [backend_service.dart](lib/services/backend_service.dart) | Gọi API gửi PDF và chat tới Backend |
| **Route Upload** | [upload.dart](../backend/routes/api/papers/upload.dart) | API tiếp nhận PDF, phối hợp GROBID + TEI Parser + Gemini Synthesis |
| **Route Chat** | [chat.dart](../backend/routes/api/chat.dart) | API nhận câu hỏi, stream câu trả lời từ Gemini AI |
| **GROBID Service** | [grobid_service.dart](../backend/lib/services/grobid_service.dart) | Gửi PDF tới bộ bóc tách tài liệu GROBID |
| **TEI XML Parser** | [tei_parser_service.dart](../backend/lib/services/tei_parser_service.dart) | Dịch file XML từ GROBID ra dữ liệu Dart `PaperModel` |
| **Gemini Service** | [gemini_service.dart](../backend/lib/services/gemini_service.dart) | Giao tiếp với AI của Google để tóm tắt và chat |
