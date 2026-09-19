# 🎵 Music Hub - Kho Nhạc Cá Nhân & Ứng Dụng iOS TrollStore

Hệ thống phát nhạc cá nhân **100% serverless**, không cần backend hay database. Dữ liệu nhạc được lưu trữ tĩnh qua **GitHub Pages**, quản lý danh sách bằng trang web tĩnh **index.html**, và ứng dụng phát nhạc **Flutter iOS** được tự động đóng gói thành file **`.ipa` unsigned** thông qua GitHub Actions để cài đặt trực tiếp qua **TrollStore**.

---

## 🚀 Tính năng nổi bật

1. **Lưu trữ tĩnh miễn phí & tốc độ cao:**
   - Các file MP3 đặt trong `songs/remix/` và `songs/lofi/`.
   - Hai file metadata `remix.json` và `lofi.json` kiểm soát danh sách bài hát.
   - Truy cập trực tiếp qua CDN của GitHub Pages không lo sập server.

2. **Trang web quản trị & nghe thử (`index.html`):**
   - Giao diện **Dark Theme Glassmorphism** hiện đại.
   - Tự động trích xuất tên bài hát và tạo tên file chuẩn khi chọn file MP3.
   - Tự động sinh URL tĩnh GitHub Pages chuẩn xác.
   - Nghe thử trực tiếp với trình phát audio HTML5.
   - Xuất file `remix.json` và `lofi.json` chỉ với 1 click.

3. **Ứng dụng iOS Flutter (`app/`):**
   - Hỗ trợ **Background Audio (`UIBackgroundModes: audio`)**: Tắt màn hình hoặc thoát ra màn hình chính nhạc vẫn phát liên tục.
   - Cơ chế chống cache CDN thông minh (`?t=timestamp`) giúp cập nhật bài hát tức thì khi có nhạc mới.
   - Thanh điều khiển Mini Player ở đáy màn hình và modal Full Player đĩa xoay sang trọng.
   - Cung cấp ô cấu hình GitHub URL trực tiếp trong app, không cần re-build khi đổi repo.

4. **Tự động build file .ipa qua GitHub Actions (`.github/workflows/build_ipa.yml`):**
   - Build trên máy ảo macOS của GitHub.
   - Lệnh `flutter build ios --release --no-codesign` không cần tài khoản lập trình viên Apple ($99/năm).
   - Đóng gói chuẩn cấu trúc `Payload/Runner.app` tương thích 100% với **TrollStore**.

---

## 📁 Cấu trúc thư mục

```text
appmusic/
├── .github/
│   └── workflows/
│       └── build_ipa.yml      # CI/CD GitHub Actions tự build IPA
├── songs/
│   ├── remix/                 # Thư mục chứa các file .mp3 Remix
│   └── lofi/                  # Thư mục chứa các file .mp3 Lofi
├── remix.json                 # Danh sách nhạc Remix [ {id, title, url} ]
├── lofi.json                  # Danh sách nhạc Lofi [ {id, title, url} ]
├── index.html                 # Trang web quản trị và nghe thử tĩnh
├── README.md                  # Hướng dẫn chi tiết
└── app/                       # Mã nguồn ứng dụng Flutter iOS
    ├── pubspec.yaml
    ├── lib/
    │   ├── main.dart          # Giao diện chính & Audio player
    │   ├── models/song.dart   # Model Song
    │   └── services/audio_manager.dart # Trình điều khiển just_audio + background
    └── ios/
        ├── Runner/Info.plist  # Cấu hình UIBackgroundModes audio
        └── ...
```

---

## 🛠️ Hướng Dẫn Sử Dụng Chi Tiết

### Bước 1: Kích hoạt GitHub Pages cho Repository
1. Đẩy toàn bộ mã nguồn lên repository GitHub của bạn:
   ```bash
   git init
   git add .
   git commit -m "Khởi tạo kho nhạc cá nhân"
   git branch -M main
   git remote add origin https://github.com/<TÊN_GITHUB>/<TÊN_REPO>.git
   git push -u origin main
   ```
2. Trên trang GitHub repo, vào **Settings** ➔ **Pages**.
3. Tại mục **Build and deployment** ➔ **Branch**:
   - Chọn nhánh `main` và thư mục `/(root)`.
   - Bấm **Save**.
4. Sau 1-2 phút, bạn sẽ có URL dạng: `https://<TÊN_GITHUB>.github.io/<TÊN_REPO>/`.

---

### Bước 2: Thêm bài hát mới & Xuất file JSON
1. Mở file `index.html` trực tiếp bằng trình duyệt (hoặc vào link GitHub Pages của bạn).
2. Điền thông tin **GitHub Username** và **Repo Name** ở góc trên bên phải (trang web sẽ tự nhớ cho các lần sau).
3. Copy các file `.mp3` của bạn vào thư mục tương ứng trong máy:
   - Thể loại Remix: `songs/remix/`
   - Thể loại Lofi: `songs/lofi/`
4. Trên giao diện `index.html`:
   - Bấm vào khung chọn file để chọn bài hát MP3 (hệ thống sẽ tự trích tên bài và tên file).
   - Chọn thể loại tương ứng (`Remix` hoặc `Lofi`).
   - Bấm **"Thêm vào danh sách tạm thời"**.
   - Bấm nút **"Tải remix.json"** hoặc **"Tải lofi.json"** để tải file JSON về máy.
5. Chép file JSON vừa tải về ghi đè vào thư mục gốc của dự án và commit lên GitHub:
   ```bash
   git add .
   git commit -m "Thêm bài hát mới"
   git push
   ```

---

### Bước 3: Build file .ipa bằng GitHub Actions
1. Trên GitHub repository của bạn, chọn tab **Actions**.
2. Ở cột bên trái, chọn workflow **Build iOS IPA for TrollStore**.
3. Bấm vào nút **Run workflow** ➔ Chọn nhánh `main` ➔ Bấm **Run workflow**.
4. Chờ khoảng 4 - 6 phút để máy ảo macOS tải Flutter, biên dịch và đóng gói file `.ipa`.
5. Khi workflow hoàn tất (hiện dấu tích xanh ✅), bấm vào bản build vừa chạy và cuộn xuống mục **Artifacts** để tải file `.zip` chứa `MusicPlayer_TrollStore.ipa`.

---

### Bước 4: Cài đặt lên iPhone qua TrollStore
1. Giải nén file `.zip` vừa tải về trên máy tính hoặc gửi thẳng file `MusicPlayer_TrollStore.ipa` sang iPhone (qua AirDrop, iCloud Drive, Telegram hoặc Safari).
2. Mở ứng dụng **TrollStore** trên iPhone:
   - Bấm dấu `+` ở góc trên bên phải ➔ Chọn **Install IPA File** ➔ Chọn file `MusicPlayer_TrollStore.ipa`.
3. Mở ứng dụng **Music Vault** trên màn hình chính:
   - Bấm biểu tượng ⚙️ (Cài đặt) ở góc trên bên phải.
   - Nhập URL GitHub Pages của bạn: `https://<TÊN_GITHUB>.github.io/<TÊN_REPO>`.
   - Bấm **Lưu & Tải lại**.
4. Ứng dụng sẽ lập tức nạp danh sách bài hát và bạn có thể thưởng thức kho nhạc của riêng mình ngay cả khi khóa màn hình!
