# Đặc tả PaperChat Desktop

## Nền tảng và dữ liệu vào

Ứng dụng Flutter Desktop, có runner macOS và Windows. Nguồn tài liệu là tệp PDF khoa học được người dùng chọn từ hệ thống tệp local. File picker chỉ cho chọn `.pdf`; client và backend kiểm tra chữ ký `%PDF-`.

## Xử lý

1. Flutter gửi multipart PDF đến `POST /api/papers/upload` trên Dart Frog.
2. Backend chuyển PDF đến GROBID `POST /api/processFulltextDocument`.
3. TEI parser lấy tiêu đề, tác giả, abstract, ngày công bố, từ khóa metadata và các mục văn bản.
4. Nếu backend được cấu hình Gemini API key qua env, backend tổng hợp thêm nội dung IMGRaD, từ khóa và câu hỏi gợi ý. Nếu Gemini lỗi, nội dung TEI vẫn được trả về.
5. `GET /api/grobid/status` phản ánh trạng thái GROBID thực tế. Khi GROBID lỗi, upload trả lỗi rõ ràng; ứng dụng không tự thay đổi bộ trích xuất.

## Lưu trữ và chat

Bài báo cùng lịch sử chat lưu trên máy bằng SharedPreferences, tối đa 20 tài liệu gần đây. Chat cần backend hoạt động và `GEMINI_API_KEY` được cấu hình ở backend; FE không chứa key. Phân loại IMGRaD suy ra từ tên mục khi chưa có tổng hợp AI, nên chỉ là gợi ý và không được xem như nội dung được xác nhận.

## Giới hạn

Runner Windows đã có nhưng chưa được build và kiểm thử trên Windows; Linux chưa có runner. Chưa có trình xem trang PDF gốc, OCR cho PDF scan hoặc quản lý dung lượng cho tài liệu TEI lớn. Xem `KNOWN_ISSUES.md` ở gốc dự án.
