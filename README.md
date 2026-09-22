# PaperChat — ứng dụng desktop đọc bài báo khoa học

PaperChat là ứng dụng Flutter Desktop. Người dùng chọn PDF local; backend Dart Frog gửi tài liệu tới GROBID để trích xuất TEI-XML. Khi backend có `GEMINI_API_KEY`, backend tổng hợp nội dung và trả lời câu hỏi. FE không giữ API key.

## Chuẩn bị chung

- Cài Flutter, Dart SDK, [Dart Frog CLI](https://dart-frog.dev/getting-started/), Docker Desktop.
- Tạo `backend/.env` từ [backend/.env.example](backend/.env.example). Các biến được backend dùng: `GEMINI_API_KEY`, `DEFAULT_GEMINI_MODEL`, `GROBID_URL`, `PORT`. `PORT` mặc định là `8080`, GROBID mặc định dùng cổng `8070`.
- Các script FE chỉ đọc `PORT` để đặt URL backend lúc chạy/build. Nếu đổi `PORT`, hãy chạy hoặc build lại FE. Thay đổi key/model/GROBID URL cần khởi động lại BE.

## macOS

Cần Xcode đầy đủ. Xem [hướng dẫn Flutter cho macOS](https://docs.flutter.dev/platform-integration/macos/setup). Trên máy phát triển hiện tại, `frontend/desktop.sh` đặt `DEVELOPER_DIR` tới `/Applications/Xcode.app/Contents/Developer` cho lệnh Flutter.

Chạy một lần tại thư mục gốc repo:

```bash
(cd backend && dart pub get)
(cd frontend && flutter pub get)
```

Mở **ba terminal** tại thư mục gốc:

```bash
# Terminal 1 — GROBID
docker compose up -d
```

```bash
# Terminal 2 — backend
./backend/start.sh
```

```bash
# Terminal 3 — Flutter desktop
./frontend/desktop.sh run
```

Build bản release trên **macOS**:

```bash
./frontend/desktop.sh build
```

Kết quả: `frontend/build/macos/Build/Products/Release/paper_chat_ai.app`.

Build backend để triển khai production:

```bash
(cd backend && dart_frog build)
```

Kết quả: `backend/build/`. Lệnh chạy phát triển ở trên (`./backend/start.sh`) là cách nhanh nhất để chạy BE trên máy cá nhân.

## Windows (PowerShell)

Cần Visual Studio với workload **Desktop development with C++** và Flutter nhận diện được Windows qua `flutter doctor -v`. Visual Studio Code riêng lẻ không thay thế Visual Studio cho bước build này. Xem [hướng dẫn Flutter cho Windows](https://docs.flutter.dev/platform-integration/windows/setup).

Chạy một lần tại thư mục gốc repo:

```powershell
Push-Location backend; dart pub get; Pop-Location
Push-Location frontend; flutter pub get; Pop-Location
```

Mở **ba cửa sổ PowerShell** tại thư mục gốc:

```powershell
# Terminal 1 — GROBID
docker compose up -d
```

```powershell
# Terminal 2 — backend
.\backend\start.ps1
```

```powershell
# Terminal 3 — Flutter desktop
.\frontend\desktop.ps1 run
```

Build bản release trên **Windows**:

```powershell
.\frontend\desktop.ps1 build
```

Kết quả nằm trong `frontend\build\windows\<architecture>\runner\Release\` (thường là `x64`), gồm `paper_chat_ai.exe`, các DLL và thư mục `data`. Khi chép ứng dụng sang máy khác, giữ **toàn bộ thư mục Release** thay vì chỉ lấy file `.exe`. Xem [hướng dẫn đóng gói Windows của Flutter](https://docs.flutter.dev/platform-integration/windows/building).

Build backend để triển khai production:

```powershell
Push-Location backend; dart_frog build; Pop-Location
```

Kết quả: `backend\build\`.

Nếu PowerShell chặn chạy script trên máy của bạn, chỉ mở quyền cho **phiên terminal hiện tại** rồi chạy lại:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
```

## Lưu ý khi chạy

- macOS build file `.app` trên macOS; Windows build file `.exe` trên Windows. Repo đã có runner cho cả hai nền tảng, nhưng bản Windows chưa được build thử trên máy Windows.
- Ứng dụng desktop vẫn cần backend và GROBID Docker chạy trên máy sử dụng. Backend đọc API key từ `backend/.env` hoặc biến môi trường; thiếu key vẫn đọc được phần GROBID nhưng không chat AI.
- Kiểm tra GROBID: `http://localhost:8070/api/isalive`; kiểm tra backend qua `http://localhost:<PORT>/api/grobid/status`.
- Nếu log báo `gemini-2.0-flash is no longer available`, đặt `DEFAULT_GEMINI_MODEL=gemini-3.6-flash` trong `backend/.env` (hoặc biến môi trường BE), rồi khởi động lại BE. File mẫu và giá trị mặc định trong mã nguồn đã dùng model này.

Xem [đặc tả](frontend/SPECIFICATION.md), [quy trình](frontend/BUSINESS_WORKFLOW.md) và [lỗi còn tồn tại](KNOWN_ISSUES.md).
