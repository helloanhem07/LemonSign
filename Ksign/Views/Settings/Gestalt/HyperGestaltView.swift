//
//  HyperGestaltView.swift
//  HyperSign
//
//  Created for HyperSign on 14.11.2026.
//  Phân vùng Tinh chỉnh MobileGestalt với cảnh báo an toàn
//

import SwiftUI
import NimbleViews

struct HyperGestaltView: View {
	@StateObject private var manager = HyperGestaltManager.shared
	@State private var showingApplyAlert = false
	@State private var showingBackupAlert = false
	@State private var showingRestoreAlert = false
	@State private var alertMessage = ""
	
	var body: some View {
		NBList("HyperGestalt") {
			// Cảnh báo an toàn bắt buộc
			_warningCard()
			
			// Thẻ trạng thái môi trường
			_environmentStatusCard()
			
			// Nhóm 1: Tính năng iPhone mới
			NBSection("Mở Khóa Tính Năng iPhone Mới") {
				Toggle(isOn: $manager.dynamicIslandEnabled) {
					HStack(spacing: 12) {
						SettingsIconBadge(systemName: "platter.filled.top.iphone", color: .black)
						VStack(alignment: .leading, spacing: 2) {
							Text("Đảo động Dynamic Island")
								.font(.body)
							Text("Kích hoạt Dynamic Island trên các dòng iPhone tai thỏ (11/12/13/14)")
								.font(.caption)
								.foregroundColor(.secondary)
						}
					}
				}
				
				Toggle(isOn: $manager.batteryLimit80Enabled) {
					HStack(spacing: 12) {
						SettingsIconBadge(systemName: "battery.100.bolt", color: .green)
						VStack(alignment: .leading, spacing: 2) {
							Text("Giới hạn sạc pin 80%")
								.font(.body)
							Text("Tính năng bảo vệ tuổi thọ pin của iPhone 15/16 cho máy đời cũ")
								.font(.caption)
								.foregroundColor(.secondary)
						}
					}
				}
				
				Toggle(isOn: $manager.alwaysOnDisplayEnabled) {
					HStack(spacing: 12) {
						SettingsIconBadge(systemName: "sun.max.fill", color: .indigo)
						VStack(alignment: .leading, spacing: 2) {
							Text("Màn hình luôn sáng (AOD)")
								.font(.body)
							Text("Bật tùy chọn Always-On Display trên các dòng iPhone thường")
								.font(.caption)
								.foregroundColor(.secondary)
						}
					}
				}
				
				Toggle(isOn: $manager.appleIntelligenceFlagEnabled) {
					HStack(spacing: 12) {
						SettingsIconBadge(systemName: "sparkles", color: .purple)
						VStack(alignment: .leading, spacing: 2) {
							Text("Cờ Apple Intelligence (iOS 18+)")
								.font(.body)
							Text("Bật cờ trải nghiệm hiệu ứng và giao diện Apple Intelligence")
								.font(.caption)
								.foregroundColor(.secondary)
						}
					}
				}
			} footer: {
				Text("Các tính năng này mô phỏng phần cứng đời mới bằng cách nạp mã subtype tương ứng vào bộ nhớ đệm MobileGestalt.")
			}
			
			// Nhóm 2: Gỡ bỏ giới hạn vùng
			NBSection("Gỡ Bỏ Giới Hạn Khu Vực (Region Unlock)") {
				Toggle(isOn: $manager.muteCameraShutterEnabled) {
					HStack(spacing: 12) {
						SettingsIconBadge(systemName: "speaker.slash.fill", color: .orange)
						VStack(alignment: .leading, spacing: 2) {
							Text("Tắt âm thanh chụp ảnh camera")
								.font(.body)
							Text("Dành riêng cho máy xách tay Nhật Bản (J/A) và Hàn Quốc (KH/A)")
								.font(.caption)
								.foregroundColor(.secondary)
						}
					}
				}
				
				Toggle(isOn: $manager.chinaFaceTimeAudioEnabled) {
					HStack(spacing: 12) {
						SettingsIconBadge(systemName: "phone.fill", color: .teal)
						VStack(alignment: .leading, spacing: 2) {
							Text("Mở khóa FaceTime thoại")
								.font(.body)
							Text("Cho phép gọi FaceTime Audio trên máy thị trường Trung Quốc (CH/A)")
								.font(.caption)
								.foregroundColor(.secondary)
						}
					}
				}
				
				Toggle(isOn: $manager.removeEUVolumeLimitEnabled) {
					HStack(spacing: 12) {
						SettingsIconBadge(systemName: "waveform", color: .blue)
						VStack(alignment: .leading, spacing: 2) {
							Text("Gỡ giới hạn âm lượng tai nghe EU")
								.font(.body)
							Text("Loại bỏ cảnh báo âm thanh và mức trần âm lượng chuẩn châu Âu")
								.font(.caption)
								.foregroundColor(.secondary)
						}
					}
				}
			}
			
			// Nhóm 3: iPadOS
			NBSection("Tính Năng Dành Cho iPadOS") {
				Toggle(isOn: $manager.stageManagerEnabled) {
					HStack(spacing: 12) {
						SettingsIconBadge(systemName: "rectangle.split.2x2.fill", color: .cyan)
						VStack(alignment: .leading, spacing: 2) {
							Text("Đa nhiệm Stage Manager")
								.font(.body)
							Text("Mở khóa quản lý cửa sổ Stage Manager trên mọi đời iPad")
								.font(.caption)
								.foregroundColor(.secondary)
						}
					}
				}
			}
			
			// Nhóm 4: Bấm Áp dụng & Cứu hộ
			Section {
				Button {
					manager.applyTweaks { success, message in
						alertMessage = message
						showingApplyAlert = true
					}
				} label: {
					HStack {
						Spacer()
						Image(systemName: "rocket.fill")
							.font(.headline)
						Text(manager.isApplying ? "Đang xử lý..." : "Áp Dụng Tinh Chỉnh Ngay")
							.font(.headline.bold())
						Spacer()
					}
					.foregroundColor(.white)
					.frame(height: 44)
					.background(LinearGradient(colors: [Color.red, Color.orange], startPoint: .leading, endPoint: .trailing))
					.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
				}
				.listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
				.listRowBackground(EmptyView())
				
				Button {
					if manager.backupCurrentGestalt() {
						alertMessage = "Đã sao lưu file MobileGestalt gốc vào bộ nhớ an toàn của HyperSign."
					} else {
						alertMessage = "Không thể tạo bản sao lưu. Vui lòng kiểm tra quyền truy cập."
					}
					showingBackupAlert = true
				} label: {
					HStack(spacing: 12) {
						SettingsIconBadge(systemName: "arrow.down.doc.fill", color: .blue)
						Text("Sao lưu MobileGestalt gốc")
							.foregroundColor(.primary)
						Spacer()
						if manager.hasBackup {
							Text("Đã có bản lưu")
								.font(.caption)
								.foregroundColor(.green)
						}
					}
				}
				
				Button {
					if manager.restoreOriginalGestalt() {
						alertMessage = "Đã khôi phục hoàn toàn cấu hình MobileGestalt gốc! Hãy khởi động lại thiết bị."
					} else {
						alertMessage = "Không có bản sao lưu nào để khôi phục."
					}
					showingRestoreAlert = true
				} label: {
					HStack(spacing: 12) {
						SettingsIconBadge(systemName: "arrow.counterclockwise.circle.fill", color: .red)
						Text("Khôi phục mặc định ban đầu")
							.foregroundColor(.red)
					}
				}
			}
		}
		.alert("HyperGestalt", isPresented: $showingApplyAlert) {
			Button("Đã hiểu", role: .cancel) {}
		} message: {
			Text(alertMessage)
		}
		.alert("Sao lưu MobileGestalt", isPresented: $showingBackupAlert) {
			Button("OK", role: .cancel) {}
		} message: {
			Text(alertMessage)
		}
		.alert("Khôi phục MobileGestalt", isPresented: $showingRestoreAlert) {
			Button("OK", role: .cancel) {}
		} message: {
			Text(alertMessage)
		}
	}
	
	// MARK: - Subviews
	@ViewBuilder
	private func _warningCard() -> some View {
		Section {
			VStack(alignment: .leading, spacing: 10) {
				HStack(spacing: 8) {
					Image(systemName: "exclamationmark.triangle.fill")
						.font(.headline)
						.foregroundColor(.orange)
					Text("CẢNH BÁO AN TOÀN")
						.font(.headline.bold())
						.foregroundColor(.orange)
				}
				
				Text("Các tùy chọn này can thiệp vào file cấu hình phần cứng `MobileGestalt.plist` của iOS. Một số tính năng như Đảo Dynamic Island có thể làm che một phần thanh hiển thị pin/sóng trên các dòng máy có tai thỏ vật lý. Bạn luôn có thể bấm **'Khôi phục mặc định ban đầu'** bất kỳ lúc nào nếu gặp lỗi hiển thị.")
					.font(.footnote)
					.foregroundColor(.secondary)
					.lineSpacing(3)
			}
			.padding(.vertical, 8)
		}
	}
	
	@ViewBuilder
	private func _environmentStatusCard() -> some View {
		Section {
			HStack {
				VStack(alignment: .leading, spacing: 4) {
					Text("Môi trường thực thi")
						.font(.subheadline.bold())
					Text(manager.canDirectlyWrite ? "⚡ Quyền truy cập trực tiếp (TrollStore / JB)" : "🔒 Chế độ Sandbox Sideload (Profile / IDevice)")
						.font(.caption)
						.foregroundColor(manager.canDirectlyWrite ? .green : .secondary)
				}
				Spacer()
				Image(systemName: manager.canDirectlyWrite ? "checkmark.circle.fill" : "shield.checkered")
					.foregroundColor(manager.canDirectlyWrite ? .green : .orange)
					.font(.title2)
			}
		}
	}
}
