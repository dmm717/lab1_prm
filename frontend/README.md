# PaperChat Flutter Desktop

Ứng dụng Flutter desktop đọc PDF local và hiển thị nội dung do GROBID trích xuất. Hướng dẫn đầy đủ cho **macOS** và **Windows PowerShell** nằm trong [README gốc](../README.md).

| Nền tảng | Chạy FE | Build release |
|---|---|---|
| macOS | `./frontend/desktop.sh run` | `./frontend/desktop.sh build` |
| Windows PowerShell | `.\frontend\desktop.ps1 run` | `.\frontend\desktop.ps1 build` |

Chạy các lệnh từ thư mục gốc repo sau khi đã khởi động GROBID và backend. FE không lưu Gemini API key; các script chỉ đọc `PORT` trong `backend/.env` để nối đúng backend.
