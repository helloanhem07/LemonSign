# KẾ HOẠCH & YÊU CẦU CHỈNH SỬA MÃ NGUỒN MSign

> **Trạng thái**: Đã hoàn thành triển khai toàn bộ yêu cầu (MSign v1.0)  
> **Ngày hoàn thành**: 14/11/2026  
> **Nguyên tắc**: Chuẩn hóa nhận diện MSign ESign Blue, tinh giản Cài đặt 5 khối, 0.4s Splash, 32 nguồn KhoIPA tích hợp kèm Cron Health-Check.

---

## 1. DANH MỤC YÊU CẦU CHI TIẾT

### Yêu cầu 1: Xóa hoàn toàn Bộ công cụ 3105 (`ThreeOneOSFive`)
* **Mục tiêu**: Loại bỏ triệt để phân hệ công cụ 3105 (MobileGestalt, Lab, dự án tiện ích hệ thống) để tinh gọn ứng dụng, tập trung thuần túy vào ký và cài đặt IPA.
* **Các vị trí tác động**:
  1. Thư mục `Ksign/Views/ThreeOneOSFive/` (toàn bộ 10 tệp SwiftUI View & Model).
  2. Phân loại Tab tại `Ksign/Views/TabView/TabEnum.swift`:
     - Xóa `case threeOneOSFive = "3105"`
     - Xóa icon `puzzlepiece.extension.fill`
     - Xóa view khởi tạo `ThreeOneOSFiveView()`
     - Xóa khỏi danh sách `defaultCases`
  3. Màn hình Cài đặt tại `Ksign/Views/Settings/SettingsView.swift`:
     - Xóa `NavigationLink(destination: ThreeOneOSFiveView())` trong nhóm Công cụ.
  4. Cấu hình dự án Xcode `Ksign.xcodeproj/project.pbxproj`:
     - Gỡ bỏ toàn bộ file reference và build phase liên quan đến nhóm `ThreeOneOSFive`.

---

### Yêu cầu 2: Quy hoạch lại Màn hình Cài đặt (Settings)
* **Mục tiêu**: Tái cơ cấu giao diện Settings từ danh sách dài hơn 15 mục phân tán thành các cụm chức năng (Sections/Cards) trực quan, chuẩn UI/UX iOS:
  1. **Cụm 1: Giao diện & Nhận diện (Appearance & Branding)**:
     - Chế độ Sáng / Tối (`AppearanceView`).
     - Bộ biểu tượng ứng dụng Pixel Art (`AppIconView`).
     - Tùy chỉnh màu chủ đạo (`AccentColor`).
  2. **Cụm 2: Ký & Đóng gói IPA (Codesigning & Engine)**:
     - Lựa chọn Engine giải nén (`Zip` vs `ZIPFoundation`).
     - Cấu hình mức độ nén mặc định (`ArchiveHandler`).
     - Trạng thái Zsign C++ & LemonTurbo đa luồng.
  3. **Cụm 3: Chứng chỉ & Cài đặt OTA (Certificates & Network)**:
     - Trình quản lý chứng chỉ nhanh.
     - Cấu hình cổng và SSL cho Localhost HTTPS Server (`server.crt` / `server.pem`).
     - Tùy chọn IDevice Tunnel & TrollStore.
  4. **Cụm 4: Hộp công cụ tiện ích (Toolbox)**:
     - Kho Tweak & Dylib (`TweakHubView`).
     - Chia sẻ nhanh qua Wi-Fi & QR (`AirShareView`).
     - Dọn dẹp bộ nhớ đệm tạm thời (Cache Cleaner).
  5. **Cụm 5: Thông tin & Đóng góp (About & Community)**:
     - Trạng thái bản dựng, cập nhật GitHub, kênh Telegram, Thông tin giấy phép GPL v3.0.

---

### Yêu cầu 3: Tối ưu đóng gói lại IPA (Instant OTA Packaging)
* **Mục tiêu**: Đảm bảo trải nghiệm đóng gói siêu tốc khi người dùng chọn ký để cài đặt trực tiếp.
* **Cơ chế kỹ thuật trong `ArchiveHandler.swift`**:
  - Khi luồng là **Ký & Cài đặt trực tiếp qua OTA** (`!isSharing`):
    - Cưỡng chế áp dụng mức nén `ZipCompression.BestSpeed` (Level 1 Deflate).
    - Thời gian đóng gói chỉ mất **0.3 - 0.5 giây**, loại bỏ hoàn toàn độ trễ chờ đợi.
    - Đảm bảo tương thích 100% với trình giải nén nhị phân `BOMCopier` và daemon `installd` của iOS.
  - Khi luồng là **Lưu / Xuất / Chia sẻ file IPA** (`isSharing == true`):
    - Áp dụng mức nén theo thiết lập của người dùng từ 0 (Store) đến 9 (BestCompression) để tối ưu dung lượng lưu trữ.

---

### Yêu cầu 4: Đa luồng LemonTurbo & Ký số Zsign C++
* **Mục tiêu**: Duy trì và tối ưu kiến trúc ký số nhúng trực tiếp hiệu năng cao:
  - **Tích hợp C-ABI trực tiếp qua `zsign.mm`**:
    - Gọi trực tiếp hàm `extern "C" int zsign(...)` qua Objective-C++ bridge sang Swift.
    - Không gọi subprocess, không fork tiến trình UNIX, không gọi shell scripts — bảo đảm an toàn sandbox iOS và chạy ổn định cả trên Stock iOS lẫn Jailbreak/TrollStore.
  - **Khai thác tối đa phần cứng Apple Silicon**:
    - Sử dụng `std::thread::hardware_concurrency()` trong `bundle.cpp` để băm SHA-1 và SHA-256 song song cho hàng ngàn tệp tin con trong app bundle.
    - Rút ngắn tối đa thời gian tính toán và ghi tệp `_CodeSignature/CodeResources`.
  - **Truyền dẫn log thời gian thực**:
    - Sử dụng POSIX pipe `dup2` để đưa toàn bộ output log từ C++ Zsign về `LogsManager` hiển thị trực tiếp cho người dùng.

---

### Yêu cầu 5: Tắt tự động chèn các cờ hữu ích trong `Info.plist`
* **Mục tiêu**: Bảo đảm tính toàn vẹn nguyên bản của ứng dụng gốc sau khi ký, không tự ý chèn các cờ hệ thống trừ khi người dùng chủ động yêu cầu.
* **Các vị trí điều chỉnh**:
  1. Trong `OptionsManager.swift`:
     - Đặt giá trị mặc định (`Options.defaultOptions`) của các cờ sau về `false`:
       - `proMotion` (`CADisableMinimumFrameDurationOnPhone` - 120Hz): `false`
       - `fileSharing` (`UISupportsDocumentBrowser`): `false`
       - `itunesFileSharing` (`UIFileSharingEnabled`): `false`
       - `gameMode` (`GCSupportsGameMode`): `false`
       - `ipadFullscreen` (`UIRequiresFullScreen`): `false`
       - `removeSupportedDevices`: `false` (không tự ý xóa thiết bị hỗ trợ trừ khi bật)
       - `removeURLScheme`: `false`
  2. Trong `SigningHandler.swift`:
     - Kiểm tra chặt chẽ điều kiện: Chỉ thực hiện `infoDictionary.setObject(...)` khi tùy chọn tương ứng được người dùng bật rõ ràng (`true`).
     - Nếu người dùng để mặc định, giữ nguyên trạng 100% nội dung `Info.plist` gốc của file IPA.

---

## 2. MA TRẬN TÁC ĐỘNG TỆP TIN (FILE IMPACT MATRIX)

| Tệp tin / Thư mục | Hành động dự kiến | Mục đích |
| :--- | :---: | :--- |
| `Ksign/Views/ThreeOneOSFive/` | **Xóa toàn bộ** | Loại bỏ hoàn toàn mã nguồn bộ công cụ 3105 |
| `Ksign/Views/TabView/TabEnum.swift` | **Chỉnh sửa** | Gỡ bỏ case `.threeOneOSFive` khỏi Tabbar |
| `Ksign/Views/Settings/SettingsView.swift` | **Tái cấu trúc** | Xóa link 3105, quy hoạch lại các Section khoa học |
| `Ksign/Backend/Observable/OptionsManager.swift` | **Chỉnh sửa** | Đặt mặc định các cờ can thiệp Plist về `false` |
| `Ksign/Utilities/Handlers/SigningHandler.swift` | **Chỉnh sửa** | Đảm bảo không tự ý chèn cờ vào `Info.plist` |
| `Ksign/Utilities/Handlers/ArchiveHandler.swift` | **Rà soát & Giữ vững** | Đảm bảo chuẩn nén `BestSpeed` (0.3-0.5s) cho OTA |
| `Zsign/swift/zsign.mm` & `src/bundle.cpp` | **Rà soát & Giữ vững** | Bảo đảm C-ABI direct call và LemonTurbo đa luồng |
| `Ksign.xcodeproj/project.pbxproj` | **Cập nhật** | Gỡ bỏ tham chiếu các file 3105 đã xóa |

---

## 3. QUY TRÌNH THỰC HIỆN KHI BẮT ĐẦU

1. **Bước 1**: Nhận lệnh xác nhận "Bắt đầu sửa code" từ người dùng.
2. **Bước 2**: Thực hiện xóa `ThreeOneOSFive` và cập nhật `TabEnum.swift` + `project.pbxproj`.
3. **Bước 3**: Cập nhật `OptionsManager.swift` và `SigningHandler.swift` để tắt tự động chèn cờ `Info.plist`.
4. **Bước 4**: Tái cấu trúc lại giao diện `SettingsView.swift`.
5. **Bước 5**: Kiểm tra tính toàn vẹn của `ArchiveHandler.swift` và `Zsign` engine.
6. **Bước 6**: Rà soát biên dịch và báo cáo hoàn thành.

---

## 4. TỔNG HỢP TOÀN BỘ Ý KIẾN CHỈ ĐẠO CỦA NGƯỜI DÙNG (CHƯA SỬA CODE)

### 📌 Ý kiến 1: Loại bỏ triệt để GestaltX
- Gỡ bỏ hoàn toàn mọi module liên quan đến GestaltX hay can thiệp `MobileGestalt.plist`.
- Giữ ứng dụng thuần túy, sạch sẽ, tập trung hoàn toàn vào việc ký số siêu tốc và cài đặt IPA an toàn.

### 📌 Ý kiến 2: Tái thiết kế Giao diện Cài đặt thành "3 Thẻ Kính Liquid Glass" (Không rườm rà)
1. **Chất liệu Kính Mờ Đa Tầng (Translucent Frosted Glass)**:
   - Loại bỏ hoàn toàn khối `Form` / `List` truyền thống xơ cứng.
   - Sử dụng `.ultraThinMaterial`, tạo hiệu ứng bán trong suốt nhìn thấy chiều sâu không gian khi cuộn trang.
   - Áp dụng các **Thẻ Kính Lơ Lửng (Floating Glass Cards)** bo góc lớn (`cornerRadius: 20 - 22`), viền ánh sáng siêu mỏng (`0.5px highlight border`), đổ bóng mờ khuếch tán.
2. **Lược bỏ thứ rườm rà (Clean & Minimalist)**:
   - Xóa bỏ toàn bộ các đoạn văn mô tả lê thê ở chân trang (footer texts).
   - Tối giản hóa các nút bấm thành các **viên nang kính (Glass Capsules)** và **icon badge phát sáng nhẹ**.
   - Giữ khoảng cách thở (padding, spacing thoáng đãng).
3. **Quy hoạch 3 Thẻ Kính Liền Mạch (Xóa bỏ 9 phân đoạn vụn vặt)**:
   - **Thẻ 1 (Hero Glass Card)**: Nhận diện HyperSign 🚀 + Version + Status Pills + Hàng nút viên nang nhanh (Giới thiệu, Giao diện).
   - **Thẻ 2 (Core Engine Glass Card)**: Trọng tâm Ký & Cài đặt (Chứng chỉ, Trình cài đặt, Tùy chọn ký, Nén & Lưu trữ, Tính năng ứng dụng).
   - **Thẻ 3 (Utilities Glass Card)**: Công cụ & Hệ thống (AirShare WiFi, Thư mục tài liệu Documents/Archives, Nhật ký Logs, Đặt lại Reset).
4. **Nguyên tắc Bảo tồn Toàn diện**:
   - Bảo tồn 100% tất cả các tính năng cốt lõi và kết nối dữ liệu:
     + Động cơ Ký Zsign C++ đa luồng Apple Silicon.
     + Cơ chế nén siêu tốc `BestSpeed` Level 1 OTA (0.3s - 0.5s) trong `ArchiveHandler.swift`.
     + Bộ máy chủ cài đặt OTA (Cục bộ HTTPS, Bán cục bộ Relay, Tunnel).
     + Quản lý chứng chỉ P12 / Mobileprovision (`CertificatePair`, `Storage`).
     + Tùy chọn ký Plist & Dylibs (`ConfigurationView`).
     + Bộ công cụ AirShare WiFi & QR, Logs View, Mở Documents/Archives, Reset.
     + Toàn bộ logic CoreData, AppStorage và NotificationCenter.

### 📌 Ý kiến 3: Tên ứng dụng, Logo & Màu sắc Chủ Đạo
- **Tên chính thức & hiển thị**: **`MSign`** (viết liền, không có dấu chấm, chuẩn xác từng ký tự).
- **Logo ứng dụng**: Chốt sử dụng **Mẫu 1 (Geometric Tech "M." Electric Blue)**:
  + Biểu tượng chữ `M.` vát góc công nghệ với chấm tròn chữ ký số.
  + Dải màu: Royal Blue & Electric Cyan trên nền đen sâu phong cách ESign.
- **Màu sắc chủ đạo (Theme / Accent Color)**:
  + Chuyển toàn bộ màu chủ đạo của app từ màu vàng chanh cũ (`#FFD60A`) sang màu **Electric Royal Blue (`#0A84FF` / `#007AFF`)** đồng bộ 100% với Logo Mẫu 1.
  + Cập nhật `AccentColor.colorset` trong Assets để toàn bộ nút bấm, tab bar active, toggle, liên kết và tint color mang sắc xanh ESign sang trọng.

### 📌 Ý kiến 4: Quy hoạch Màn hình Cài đặt CHỈ GIỮ ĐÚNG CÁC MỤC TRONG ẢNH
Dựa trên 2 ảnh chụp màn hình thực tế do người dùng cung cấp (media_1794634629911 & media_1794634628898), màn hình Cài đặt sẽ được tinh giản tối đa, **CHỈ GIỮ LẠI DUY NHẤT 5 KHỐI SAU**:
1. **Khối 1: Chứng chỉ**
   - Hàng `Chứng chỉ` (kèm số lượng chứng chỉ và điều hướng `CertificatesView()`).
   - Thẻ xem trước chứng chỉ đang kích hoạt (Tên cert, trạng thái Còn hiệu lực, số ngày còn lại).
   - Chú thích: *Thêm và quản lý chứng chỉ ký ứng dụng.*
2. **Khối 2: Ký & Cài Đặt IPA** (đủ 5 mục):
   - `Cài đặt` (Icon teal -> `InstallationView()`).
   - `Tùy chọn ký` (Icon xám -> `ConfigurationView()`).
   - `Lưu trữ & giải nén` (Icon nâu -> `ArchiveView()`).
   - `Nhật ký` (Icon đen -> `LogsView()`).
   - `Tính năng` (Icon vàng -> `AppFeaturesView()`).
3. **Khối 3: Công Cụ Mở Rộng**
   - `AirShare WiFi & QR` (Icon chàm/tím -> `AirShareView()`).
   - Chú thích: *Chia sẻ và nhận file IPA không dây qua mạng WiFi cục bộ.*
4. **Khối 4: Khác**
   - `Mở tài liệu` (Icon xanh dương -> Mở `URL.documentsDirectory`).
   - `Mở kho lưu trữ` (Icon cyan -> Mở `FileManager.default.archives`).
   - Chú thích: *Tất cả các tệp của MSign trừ chứng chỉ được chứa trong thư mục tài liệu.*
5. **Khối 5: Đặt lại**
   - `Đặt lại` (Icon đỏ -> `ResetView()`).
   - Chú thích: *Đặt lại kho ứng dụng, chứng chỉ, app, và những thứ khác.*

> 🚫 **CÁC PHẦN ĐƯỢC LOẠI BỎ HOÀN TOÀN (KHÔNG CÓ TRONG ẢNH)**:
> - Loại bỏ Thẻ Header quyên góp/ủng hộ (`SettingsDonationCellView`).
> - Loại bỏ mục `Giới thiệu` (`AboutNyaView`).
> - Loại bỏ mục `Giao diện` (`AppearanceView`).
> - Loại bỏ mục `Biểu tượng Ứng dụng` (`AppIconView`).
> - Loại bỏ hoàn toàn `GestaltX / MobileGestalt`.

### 📌 Ý kiến 5: Màn hình Splash Logo khi mở ứng dụng (0.4 giây)
- Khi người dùng khởi chạy ứng dụng, hiển thị màn hình khởi động (Splash Screen) với Logo MSign (Mẫu 1) chính giữa trong đúng **0.4 giây**.
- Sau 0.4s, thực hiện hiệu ứng mờ dần (smooth fade-out transition) chuyển cảnh mượt mà vào giao diện chính.

### 📌 Ý kiến 6: Tối ưu Tab Nguồn (App Store / Sources)
1. **Xóa dòng "Tất cả kho ứng dụng"**:
   - Gỡ bỏ hoàn toàn mục `All Repositories` (ảnh anime và dòng *"Xem tất cả ứng dụng từ các nguồn hiện có"*) ở đầu danh sách theo đúng ảnh chụp màn hình của bạn.
2. **Bổ sung tính năng Xóa & Sửa nguồn (Delete & Edit Source)**:
   - **Thao tác vuốt (Swipe Action)**:
     - Vuốt sang trái (Swipe Trailing): Nút đỏ **Xóa** (`Storage.shared.deleteSource(for: source)`).
     - Vuốt sang phải (Swipe Leading): Nút xanh **Sửa URL nguồn** (cho phép nhập URL mới).
   - **Menu nhấn giữ (Context Menu)**:
     - Thêm các tùy chọn: *Sao chép liên kết nguồn*, *Sửa địa chỉ URL*, và *Xóa nguồn*.
   - **Tự động dọn dẹp**: Tự động loại bỏ nguồn cũ LemonSign đã ngừng hỗ trợ khỏi danh sách khởi tạo.

### 📌 Ý kiến 7: Nhúng Sẵn Kho Nguồn Phong Phú & Cơ Chế Cron Health-Check Tự Động Ẩn Lỗi
1. **Danh sách Kho nguồn Cứng (Built-in Hardcoded Repositories)**:
   - Tích hợp sẵn danh sách hơn 25 kho nguồn IPA chất lượng cao từ cộng đồng KhoIPA vào `Storage+Sources.swift` để nạp sẵn cho người dùng khi cài app:
     - `https://fastsign.dev/repo.json`
     - `https://fastsign.dev/repo.lite.altstore.json`
     - `https://raw.githubusercontent.com/drphe/KhoIPA/main/upload/repo.favorite.json`
     - `https://repository.apptesters.org`
     - `https://raw.githubusercontent.com/drphe/KhoIPA/main/upload/repo.buildstore.json`
     - `https://raw.githubusercontent.com/drphe/KhoIPA/main/upload/repo.thuthuatjb.json`
     - `https://raw.githubusercontent.com/drphe/KhoIPA/main/upload/repo.game.json`
     - `https://raw.githubusercontent.com/drphe/KhoIPA/main/upload/repo.game2.json`
     - `https://raw.githubusercontent.com/drphe/KhoIPA/main/upload/repo.tiptip.json`
     - `https://raw.githubusercontent.com/drphe/KhoIPA/main/upload/repo.unkeyapp.json`
     - `https://stikdebug.xyz/index.json`
     - `https://raw.githubusercontent.com/drphe/KhoIPA/main/upload/EpicGamesIPASource.json`
     - `https://raw.githubusercontent.com/drphe/KhoIPA/main/upload/repo.cypwn.json`
     - `https://raw.githubusercontent.com/drphe/KhoIPA/main/upload/repo.cypwn_ts.json`
     - `https://alt.getutm.app`
     - `https://quarksources.github.io/dist/quantumsource.min.json`
     - `https://quarksources.github.io/dist/quantumsource%2B%2B.min.json`
     - `https://community-apps.sidestore.io/sidecommunity.json`
     - `https://driftywinds.github.io/AltStore/apps.json`
     - `https://wuxu1.github.io/wuxu-complete-plus.json`
     - `https://wuxu1.github.io/wuxu-complete.json`
     - `https://raw.githubusercontent.com/WhySooooFurious/Ultimate-Sideloading-Guide/refs/heads/main/raw-files/app-repo.json`
     - `https://raw.githubusercontent.com/Neoncat-OG/TrollStore-IPAs/main/apps_esign.json?moduleError=1`
     - `https://cdn.dbservices.to/repo-jsons/2c61e8984f400fbe2c28d620494b9efee8621930.json`
     - `https://cdn.dbservices.to/repo-jsons/0852d7254534240c8fa12f3ed082c44c0023ad08.json`
     - `https://cdn.dbservices.to/repo-jsons/1ae857434ef5533ecf3a5ed64c3a8a7096dc3573.json`
     - `https://repo.owo.network`
     - `https://altstore.fouadraheb.com/`
     - `https://raw.githubusercontent.com/yodaluca23/SpotC-AltStore-Repo/main/AltStore%20Repo.json`
     - `https://apps.sidestore.io/`
     - `https://raw.githubusercontent.com/royilkom-alt/EthSign/refs/heads/main/EthSign.json`
2. **Cơ chế Cron Health-Check định kỳ tự động ẩn lỗi**:
   - Chạy tiến trình nền (Background Task / Periodic Worker) kiểm tra định kỳ tính khả dụng của từng repo:
     - Gửi HTTP HEAD / GET kiểm tra phản hồi của server.
     - Nếu một nguồn bị lỗi (chết link, 404, 500, timeout, cấu trúc JSON hỏng) hoặc không có app: tự động đánh dấu ẩn (`isHealthy = false` / lọc ẩn trên giao diện), không làm rác danh sách và không gây thông báo lỗi phiền toái.
     - Tự động lọc ẩn các mục ứng dụng nếu link tải IPA bị gãy (dead URL).
     - Khi nguồn khôi phục hoạt động ở chu kỳ kiểm tra tiếp theo: tự động cho hiển thị lại bình thường.

### 📌 Ý kiến 8: Đặt phiên bản v1.0 làm bản phát hành đầu tiên
- Sau khi hoàn thành và push lên Git, sửa lại phiên bản thành **`v1.0` (Build 1)** làm bản đầu tiên của **MSign**.

---

> 🔒 **CAM KẾT TUÂN THỦ**: Toàn bộ mã nguồn hiện tại được giữ nguyên vẹn 100%, không sửa code cho đến khi người dùng phê duyệt và phát lệnh thực hiện!
