# KẾ HOẠCH & YÊU CẦU CHỈNH SỬA MÃ NGUỒN LEMONSIGN

> **Trạng thái**: Đã ghi nhận & Lưu trữ (Chưa can thiệp mã nguồn)  
> **Ngày lập**: 14/11/2026  
> **Nguyên tắc**: Giữ nguyên toàn bộ mã nguồn hiện tại cho đến khi có lệnh xác nhận thực hiện.

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
