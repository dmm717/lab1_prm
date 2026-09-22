# Phân tích lỗi và giới hạn

## Đã xử lý trong lần chỉnh sửa này

| Vấn đề | Tác động | Cách xử lý |
|---|---|---|
| Luồng URL/arXiv và tin báo chí vẫn tồn tại trong app | Lệch yêu cầu PDF khoa học local | Loại bỏ UI, controller, service và route URL |
| Badge “GROBID Online” chỉ kiểm tra trang chủ backend | Báo online sai khi Docker GROBID tắt | Thêm endpoint kiểm tra GROBID thực |
| Lỗi Gemini bị coi là lỗi GROBID và tự chuyển sang Gemini đọc PDF | Không đảm bảo dữ liệu được trích xuất bằng GROBID | Tách hai bước; GROBID lỗi thì báo lỗi, Gemini lỗi thì giữ TEI |
| Thiếu API key chặn cả việc đọc PDF | Không thể dùng GROBID độc lập | Chỉ yêu cầu key cho tổng hợp và chat |
| PDF khác nhau trùng tên dùng chung ID thư viện | Ghi đè tài liệu và chat | ID lấy từ tên cùng chữ ký nội dung cache |
| File đổi đuôi `.pdf` nhưng không phải PDF | Lỗi khó hiểu trong GROBID | Kiểm tra chữ ký PDF ở cả hai phía |
| Cache kết quả chưa tổng hợp khi thêm API key | Không thể bổ sung tổng hợp cho PDF đã nạp | Thử tổng hợp lại từ TEI trong cache |
| Gợi ý IMGRaD mặc định chứa nhận định không có trong bài | Nguy cơ làm sai nội dung khoa học | Bỏ các key point giả, ghi rõ khi chưa xác định được mục |
| Chat không tự cuộn khi câu trả lời stream; Markdown hiện đường kẻ đen và công thức `$...$` dạng chữ | Phần kết quả mới nằm ngoài vùng nhìn, khó đọc | Theo dõi nội dung stream để cuộn khi đang ở cuối; chỉnh kiểu đường kẻ và render công thức TeX |
| FE cho nhập/lưu Gemini API key, model và backend URL | Cấu hình phân tán và key nằm trên máy client | Backend đọc env/`.env`; xóa cài đặt FE và dọn giá trị cũ trong SharedPreferences |

## Còn tồn tại / cần kiểm chứng

| Vấn đề | Mức độ | Hướng xử lý |
|---|---|---|
| Đã thêm runner Windows nhưng chưa build/thử trên Windows; Linux chưa có runner | Trung bình | Build bằng Visual Studio trên máy Windows và kiểm thử import PDF/chat |
| Chưa kiểm chứng `dart_frog build` trong môi trường hiện tại vì dependency của hook build cần tải từ pub.dev nhưng mạng bị hạn chế | Thấp | Chạy lệnh build trong README trên máy có mạng và kiểm tra thư mục `backend/build/` |
| `xcode-select` đang trỏ tới Command Line Tools thay vì Xcode.app | Thấp | Đặt `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` cho lệnh Flutter; bản debug và release đã build thành công |
| PDF scan dạng ảnh không có text | Cao với tài liệu scan | Thêm OCR trước khi gửi GROBID hoặc thông báo riêng |
| SharedPreferences lưu TEI và chat lớn; lỗi ghi bị nuốt | Trung bình | Chuyển sang SQLite/file cục bộ, báo lỗi lưu cho người dùng |
| Hash cache FNV lấy mẫu byte, có xác suất va chạm | Trung bình | Chuyển SHA-256 toàn bộ tệp và migration cache |
| Bộ phân tích TEI chưa lấy bảng, hình, chú thích và liên kết citation | Trung bình | Mở rộng parser theo cấu trúc TEI của GROBID |
| `dart analyze` backend còn nhiều lint kiểu tài liệu/định dạng; không có error hoặc warning | Thấp | Dọn lint khi ổn định nghiệp vụ |
| PDF mẫu 2,1 MB chưa hoàn tất qua GROBID trong 180 giây dù health endpoint báo online; container dùng 3,83/4 GiB RAM | Cao | Tăng giới hạn RAM, kiểm tra log GROBID và đo thời gian trên tài liệu nhỏ hơn; trạng thái online chỉ xác nhận dịch vụ phản hồi |
| Chưa xác nhận E2E thành công và chat với Gemini key trên máy này | Trung bình | Thử lại khi GROBID xử lý ổn định và có key thử nghiệm |
