# 🎵 qhun22Music - Trình phát nhạc Web (trắng – xanh) + App iOS TrollStore

Hệ thống phát nhạc cá nhân **100% serverless**, không cần backend hay database.
Nhạc được lưu tĩnh trên **GitHub Pages**, quản lý bằng trang web tĩnh **`index.html`**, và
có thêm **app iOS Flutter** đóng gói `.ipa` (unsigned) bằng **Codemagic** để cài qua **TrollStore**.

> Giao diện web đã được **setup lại: nền trắng – xanh dương basic** (thay cho dark theme cũ) và
> bổ sung **đầy đủ bộ tính năng phát nhạc**: chế độ lặp, xáo trộn thông minh, hàng đợi, EQ/DSP,
> hẹn giờ, crossfade, gapless, ghi nhớ phiên nghe…

---

## 🚀 Tính năng nổi bật

### 1. Web app – Trình phát nhạc đầy đủ (`index.html` + `assets/`)

**Chế độ phát (Playback Modes)**
- **Lặp lại:** `Tắt` (hết danh sách thì dừng) → `Lặp toàn bộ` → `Lặp 1 bài` (bấm nút ⟳ để chuyển vòng, hoặc phím `R`).
- **Lặp đoạn A-B:** bấm `A-B` lần 1 đặt điểm A, lần 2 đặt điểm B (lặp liên tục đoạn A→B), lần 3 tắt — rất tiện để học nhạc/ngoại ngữ.
- **Xáo trộn (Shuffle):** bật/tắt (phím `S`), **tự động trộn ngay khi nhấn phát** (tuỳ chọn trong Cài đặt).
- **Xáo trộn thông minh (Smart / True Shuffle):** không phát lại bài vừa nghe cho tới khi hết danh sách, và tránh để 2 bài **cùng ca sĩ** đứng gần nhau (ca sĩ được đoán từ tiêu đề `Tên bài - Ca sĩ`).
- **Trộn bài tương đồng (Radio):** khi hết danh sách, tự chèn thêm tối đa 5 bài cùng thể loại vào cuối hàng đợi.
- **Tự động phát liên tục (Autoplay Next):** hết danh sách vẫn phát tiếp thay vì im lặng.
- **Tự phát khi cắm tai nghe / kết nối Bluetooth** và **tự tạm dừng khi rút tai nghe** (dùng `MediaDevices.devicechange`, chạy trên trình duyệt hỗ trợ).
- **Tự phát lại đúng vị trí cũ khi mở app** (lưu hàng đợi + giây đang nghe vào `localStorage`).

**Bộ điều khiển & cử chỉ**
- Play/Pause, Previous/Next; **Previous khi bài đã phát > 3 giây thì tua về đầu bài hiện tại** (chuẩn quốc tế).
- **Tua nhanh/lùi ±5 / 10 / 15 / 30 giây** (nút ⌃⌃ ⌄⌄ hoặc phím `←` `→`, đổi bước tua trong Cài đặt).
- **Seekbar** kéo thả tự do, hiển thị thời gian đã phát và thời gian còn lại.
- **Tốc độ phát 0.5x → 2.0x giữ nguyên cao độ** (`preservesPitch = true`).
- **Chỉnh cao độ ±12 nửa cung (Key/Pitch)**: dùng chế độ "đổi tông kiểu cassette" (`preservesPitch = false`) nên tempo đổi theo — xem mục *Giới hạn nền tảng*.
- **Cử chỉ:** vuốt ảnh bìa ← → để đổi bài, **chạm 2 lần** nửa trái/phải để tua ±step (có hiệu ứng chớp báo), **lắc máy để đổi bài** (bấm "Cấp quyền chuyển động" trong Cài đặt).
- **Phím tắt:** `Space` play/pause · `←`/`→` tua ±step · `Ctrl+←`/`Ctrl+→` bài trước/sau · `↑`/`↓` âm lượng · `S` xáo trộn · `R` lặp lại · `M` tắt tiếng · `Q` hàng đợi · `E` EQ · `Esc` đóng.

**Hàng đợi (Queue)**
- **Phát ngay** / **Phát tiếp theo** (chèn ngay sau bài đang phát) / **Thêm vào cuối hàng đợi**.
- Xem trước **Up Next** (6 bài kế tiếp, bấm để nhảy tới), panel hàng đợi đầy đủ.
- **Kéo – thả để đổi thứ tự**, xoá từng bài, **chọn nhiều để xoá cùng lúc**, **xoá sạch hàng đợi**.
- **Lưu toàn bộ hàng đợi thành Playlist** (tải về file `.json` đúng schema `{id,title,url}`).

**Chuyển bài mượt mà**
- **Crossfade 1 → 12 giây** (hai "bo" audio độc lập, bài trước nhỏ dần khi bài sau to dần).
- **Gapless:** chuẩn bị sẵn bài kế tiếp và bắt đầu trước khi bài hiện tại kết thúc để giảm tối đa khoảng lặng.
- **Fade in / fade out 0 → 1 giây khi bấm Play/Pause** (tránh tiếng "bụp" ở loa).

**EQ & xử lý âm thanh (Web Audio API)**
- **EQ 10 dải** 31Hz → 16kHz, kéo từng dải ±12 dB.
- **12 preset:** Flat, Pop, Rock, Jazz, Classic, Electronic, Dance, Acoustic, Hip-hop, Vocal Boost, Bass Boost, Treble Boost.
- **Lưu nhiều preset riêng** (đặt tên, xoá) — lưu trong máy.
- **Bass Boost / Treble Boost** (lowshelf 120Hz, highshelf 8kHz).
- **Âm trường 3D (Stereo Widening)** bằng crossfeed âm, **cân bằng L/R** (Trái/Phải %), **Mono** (gộp L+R cho người nghe một bên tai).
- **Cân bằng độ lớn (ReplayGain ~):** đo RMS 8 giây đầu của mỗi bài rồi tự bù gain ±6 dB, lưu lại cho từng URL.

**Hệ thống & khác**
- **Hẹn giờ tắt nhạc:** 15/30/45/60 phút hoặc tuỳ chỉnh 1–180 phút, tuỳ chọn **phát hết bài hiện tại mới tắt**, **tự nhỏ dần âm lượng trong 1 phút cuối**.
- **MediaSession:** tiêu đề/nút điều khiển trên màn hình khoá, tai nghe, Control Center.
- **Ghi nhớ phiên nghe:** mở lại trang là sẵn sàng đúng giây của bài nghe dở (tuỳ chọn tự phát luôn).
- **Toast thông báo** mọi thao tác + thanh thống kê (thể loại, tổng bài, vị trí bài, hẹn giờ).

### 2. Thư viện & trang Quản trị tĩnh
- Tab **Thư viện:** tìm kiếm **không dấu** (`vet` → `Vết Thương`), phát tất cả / phát ngẫu nhiên, mỗi bài có nút *Phát ngay, Phát tiếp theo, + Hàng đợi, Copy link, Xoá*.
- Tab **Quản trị:** chọn file MP3 → **tự trích tên bài + giữ nguyên tên file thật** (giữ cả dấu cách để URL khớp chính xác file trên repo), **gợi ý tên bài** khi gõ (không phân biệt dấu, có badge thể loại & `#id`), **cảnh báo trùng tên** ngay dưới ô nhập.
- **Import JSON:** chọn cả `remix.json` và `lofi.json` cùng lúc, tự nhận diện thể loại, chế độ *Ghi đè* / *Thêm vào* (tự bỏ qua bài trùng), **tự sửa link hỏng dạng `.../D:/songs/lofi/...`** theo GitHub User/Repo đang cấu hình.
- **Export JSON:** 1 click tải `remix.json` / `lofi.json` để commit lên GitHub.

### 3. App iOS Flutter (`app/`)
- Giao diện **trắng – xanh dương basic** đồng bộ với web, có mini player + full player.
- Phát ngầm (`UIBackgroundModes: audio`), khoá màn hình / Control Center / Dynamic Island qua `just_audio_background`.
- **Chế độ lặp lại Off / All / One** (nút ⟳ trên AppBar và trong màn hình phát).
- **Xáo trộn + xáo trộn thông minh** (không lặp bài vừa nghe, tránh 2 bài cùng ca sĩ gần nhau).
- **Lặp đoạn A-B** (bấm 1 lần đặt A, lần 2 đặt B, lần 3 tắt) — học nhạc/ngoại ngữ.
- **Tua ±5/10/15/30 giây**; **Previous khi đã phát > 3 giây thì về đầu bài**.
- **Tốc độ 0.5x → 2.0x giữ nguyên giọng**, có cả điều chỉnh **Cao độ (nửa cung)** (tuỳ nền tảng hỗ trợ).
- **Hàng đợi:** xem/chọn bài, **kéo-thả đổi thứ tự**, xoá từng bài, **xoá sạch**, **copy playlist JSON**;
  long-press vào bài hát trong Thư viện để **Phát ngay / Phát tiếp theo / Thêm vào cuối hàng đợi / Copy link**.
- **Hẹn giờ tắt nhạc** 15/30/45/60 phút hoặc tuỳ chỉnh 1–180 phút, tuỳ chọn **phát hết bài hiện tại mới tắt**,
  **tự nhỏ dần âm lượng trong 1 phút cuối**.
- **Fade in/out khi Play/Pause** và **chuyển bài mượt** (small fade-out → bài mới), **gapless** dựa trên AVQueuePlayer.
- **Tạm dừng khi rút tai nghe / ngắt Bluetooth**; **tự giảm âm khi có thông báo (Audio Ducking)** và tự hồi phục;
  tự tạm dừng khi có cuộc gọi.
- **Ghi nhớ phiên nghe** (`shared_preferences`): mở app là sẵn sàng đúng giây của bài nghe dở (tuỳ chọn tự phát luôn).
- Cài đặt phát nhạc lưu trong máy: nút **tune** trên AppBar mở bảng Điều khiển nhanh (lặp, xáo trộn, A-B,
  tốc độ, hẹn giờ, hàng đợi, DSP, cài đặt chi tiết).
- Chống cache CDN `?t=timestamp` để cập nhật danh sách bài hát tức thì; đổi GitHub Pages URL ngay trong app.
- Đóng gói `.ipa` unsigned bằng **Codemagic** (`codemagic.yaml`) → cài qua **TrollStore**.

> ℹ️ **EQ nhiều dải / âm thanh vòm / pitch shift chất lượng cao** cần Audio Unit native (AVAudioEngine) nên
> bản iOS hiện dùng những gì iOS xử lý sẵn (ducking, gapless, fade, tốc độ). Bản web đã có EQ 10 dải đầy đủ.
> Mã Dart chưa thể build thử trên máy Windows (không có Flutter SDK) — hãy chạy 1 build Codemagic để xác nhận.


---

## 📁 Cấu trúc thư mục

```text
appmusic/
├── index.html                 # Trang web: Trình phát + Thư viện + Quản trị (theme trắng–xanh)
├── assets/
│   ├── css/app.css            # Theme trắng + xanh dương basic (responsive mobile)
│   └── js/
│       ├── audio-engine.js    # Engine Web Audio: repeat/shuffle/queue/crossfade/EQ/sleep timer…
│       └── app.js             # UI: render thư viện, hàng đợi, EQ, cử chỉ, quản trị JSON
├── songs/
│   ├── remix/                 # File .mp3 Remix
│   └── lofi/                  # File .mp3 Lofi
├── remix.json                 # [{ "id": 1, "title": "…", "url": "…" }]
├── lofi.json                  # [{ "id": 1, "title": "…", "url": "…" }]
├── var.jpg                    # Ảnh bìa / favicon (dùng cho MediaSession)
├── codemagic.yaml             # CI build .ipa unsigned cho TrollStore
├── README.md
└── app/                       # Mã nguồn app iOS Flutter
    ├── pubspec.yaml
    ├── lib/
    │   ├── main.dart                       # Danh sách nhạc, mini player, full player, điều khiển nhanh
    │   ├── models/song.dart                # Model Song (+ đoán ca sĩ từ tiêu đề)
    │   ├── services/
    │   │   ├── audio_manager.dart          # Engine: repeat/shuffle/A-B/queue/sleep timer/session/fade
    │   │   └── playback_settings.dart      # Cài đặt hành vi phát (lưu bằng SharedPreferences)
    │   └── widgets/player_sheets.dart      # Các bottom sheet: hàng đợi, hẹn giờ, tốc độ, DSP, cài đặt
    └── ios/
```

---

## 🛠️ Hướng dẫn sử dụng

### Bước 1: Bật GitHub Pages
1. Đẩy mã nguồn lên repo:
   ```bash
   git add .
   git commit -m "Thêm bài hát mới"
   git push
   ```
2. Trên GitHub: **Settings** ➔ **Pages** ➔ **Build and deployment** ➔ chọn nhánh `main` + thư mục `/(root)` ➔ **Save**.
3. Sau 1–2 phút, trang web chạy tại `https://<TÊN_GITHUB>.github.io/<TÊN_REPO>/`.

> ⚠️ **Nên mở web qua `https://` của GitHub Pages**, không mở bằng `file://` — vì EQ/crossfade dùng Web Audio API
> và cần CORS (`Access-Control-Allow-Origin: *`) mà GitHub Pages luôn cung cấp sẵn.

### Bước 2: Thêm bài hát mới & cập nhật JSON
1. Copy file `.mp3` vào `songs/remix/` hoặc `songs/lofi/` (giữ **nguyên tên file**, kể cả dấu cách).
2. Mở web → tab **Quản trị**:
   - Chọn file MP3 → web tự điền **tên bài hát** và **tên file trên repo** (đúng như file thật).
   - Chọn thể loại, bấm **“Thêm vào danh sách tạm thời”**.
   - Gõ tên bài: nếu đã có trong kho sẽ hiện **gợi ý + cảnh báo trùng**.
3. Bấm **“Tải remix.json” / “Tải lofi.json”** → ghi đè file JSON tương ứng ở thư mục gốc dự án → `git add/commit/push`.
4. Muốn gộp danh sách cũ: dùng **Import JSON** (chọn 1 hoặc cả 2 file, chế độ *Thêm vào*).
5. Trong web bấm **“Tải lại”** ở góc phải để nạp lại danh sách mới nhất.

### Bước 3: Build file `.ipa` bằng Codemagic (để cài TrollStore)
Repo đã có sẵn `codemagic.yaml` (workflow `ios-trollstore-release`, `working_directory: app`).
1. Vào [codemagic.io](https://codemagic.io/) ➔ **Add application** ➔ chọn repo GitHub này.
2. Chọn workflow **`Build qhun22Music IPA (TrollStore)`** ➔ **Start new build** (instance `mac_mini_m2`).
3. Codemagic sẽ tự: `flutter create --platforms=ios`, thêm `UIBackgroundModes: audio`, `flutter pub get`,
   `pod install`, `flutter build ios --release --no-codesign`, rồi đóng gói `Payload/` → `qhun22Music_TrollStore.ipa`.
4. Tải file `.ipa` từ mục **Artifacts** của build.

### Bước 4: Cài lên iPhone qua TrollStore
1. Gửi file `.ipa` sang iPhone (AirDrop / iCloud Drive / Telegram / Safari).
2. Mở **TrollStore** ➔ `+` ➔ **Install IPA File** ➔ chọn `qhun22Music_TrollStore.ipa`.
3. Mở app **qhun22Music** ➔ ⚙️ ➔ nhập `https://qhun22.github.io/AppMusic` ➔ **Lưu & Tải lại**.

---

## ⌨️ Bảng phím tắt (web)

| Phím | Tác dụng |
| --- | --- |
| `Space` | Phát / Tạm dừng |
| `←` / `→` | Tua lùi / tới theo bước tua đã chọn (5/10/15/30s) |
| `Ctrl` + `←` / `→` | Bài trước / bài sau |
| `↑` / `↓` | Tăng / giảm âm lượng 5% |
| `S` | Bật/tắt xáo trộn |
| `R` | Chuyển chế độ lặp (Tắt → Toàn bộ → 1 bài) |
| `M` | Tắt/bật tiếng |
| `Q` / `E` | Mở panel Hàng đợi / EQ & DSP |
| `Esc` | Đóng panel |

---

## ⚠️ Giới hạn nền tảng (web vs. native iOS)

| Tính năng | Web (trang này) | Ghi chú |
| --- | --- | --- |
| Repeat Off/All/One, A-B | ✅ | Web Audio + vòng lặp JS |
| Xáo trộn thông minh, Radio | ✅ | Dựa trên tiêu đề / thể loại |
| Tốc độ giữ nguyên giọng | ✅ | `playbackRate` + `preservesPitch` |
| Cao độ (Key) độc lập | ⚠️ | Đổi tông kèm đổi tempo; muốn tách rời hoàn toàn cần DSP/Audio Unit native |
| Queue, kéo-thả, lưu playlist | ✅ | |
| Crossfade, gapless, fade in/out | ✅ (gapless ở mức gần liền mạch) | Không thể mẫu-chính-xác 100% như native |
| EQ 10 dải + preset + custom | ✅ | Web Audio BiquadFilter |
| Bass/Treble, widening, balance, mono | ✅ | Ma trận kênh L/R |
| ReplayGain / cân bằng độ lớn | ⚠️ ước lượng | Đo RMS 8s đầu rồi bù gain ±6 dB |
| Hẹn giờ tắt nhạc + fade cuối | ✅ | |
| Ghi nhớ vị trí khi mở app | ✅ | `localStorage` |
| Khoá màn hình / tai nghe | ✅ nếu trình duyệt hỗ trợ | MediaSession API |
| Pause on unplug, autoplay khi cắm tai nghe | ⚠️ tuỳ trình duyệt | `MediaDevices.devicechange` |
| Lắc máy đổi bài | ⚠️ cần cấp quyền cảm biến | iOS Safari yêu cầu bấm nút xin quyền |
| Ducking khi có thông báo/cuộc gọi | ❌ | Chỉ app native (iOS tự lo qua `audio_session`) |
| Dolby Atmos / Spatial / Head Tracking | ❌ | Cần Audio Unit native |
| EQ ở tầng hệ điều hành (cho mọi app) | ❌ | Ngoài phạm vi trang web |
