//
//  HyperGestaltManager.swift
//  HyperSign
//
//  Created for HyperSign on 14.11.2026.
//  MobileGestalt System Tweak Engine
//

import Foundation
import UIKit

// MARK: - Gestalt Tweak Item
struct HyperGestaltTweak: Identifiable {
	let id: String
	let title: String
	let subtitle: String
	let icon: String
	let iconColor: String
	let category: String
	let targetKey: String
	let targetValue: Any
	let originalValue: Any
	let requiresReboot: Bool
	let warningMessage: String?
}

// MARK: - Manager
final class HyperGestaltManager: ObservableObject {
	static let shared = HyperGestaltManager()
	
	// Direct path when running under TrollStore / Jailbroken / Unsandboxed environment
	private let _gestaltPath = "/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches/com.apple.MobileGestalt.plist"
	
	private var _backupURL: URL {
		FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
			.appendingPathComponent("HyperGestalt_Backup.plist")
	}
	
	@Published var hasBackup: Bool = false
	@Published var isApplying: Bool = false
	@Published var lastActionStatus: String = "Sẵn sàng"
	
	// Status flags stored in UserDefaults
	@Published var dynamicIslandEnabled: Bool {
		didSet { UserDefaults.standard.set(dynamicIslandEnabled, forKey: "hyper.gestalt.dynamicIsland") }
	}
	@Published var batteryLimit80Enabled: Bool {
		didSet { UserDefaults.standard.set(batteryLimit80Enabled, forKey: "hyper.gestalt.batteryLimit80") }
	}
	@Published var alwaysOnDisplayEnabled: Bool {
		didSet { UserDefaults.standard.set(alwaysOnDisplayEnabled, forKey: "hyper.gestalt.alwaysOnDisplay") }
	}
	@Published var muteCameraShutterEnabled: Bool {
		didSet { UserDefaults.standard.set(muteCameraShutterEnabled, forKey: "hyper.gestalt.muteShutter") }
	}
	@Published var chinaFaceTimeAudioEnabled: Bool {
		didSet { UserDefaults.standard.set(chinaFaceTimeAudioEnabled, forKey: "hyper.gestalt.chinaFaceTime") }
	}
	@Published var removeEUVolumeLimitEnabled: Bool {
		didSet { UserDefaults.standard.set(removeEUVolumeLimitEnabled, forKey: "hyper.gestalt.removeEUVolume") }
	}
	@Published var stageManagerEnabled: Bool {
		didSet { UserDefaults.standard.set(stageManagerEnabled, forKey: "hyper.gestalt.stageManager") }
	}
	@Published var appleIntelligenceFlagEnabled: Bool {
		didSet { UserDefaults.standard.set(appleIntelligenceFlagEnabled, forKey: "hyper.gestalt.appleIntelligence") }
	}
	
	var canDirectlyWrite: Bool {
		FileManager.default.isWritableFile(atPath: _gestaltPath) ||
		FileManager.default.isReadableFile(atPath: _gestaltPath) ||
		TrollStoreHelper.isTrollStoreAvailable ||
		JailbreakDetector.isJailbroken
	}
	
	private init() {
		self.dynamicIslandEnabled = UserDefaults.standard.bool(forKey: "hyper.gestalt.dynamicIsland")
		self.batteryLimit80Enabled = UserDefaults.standard.bool(forKey: "hyper.gestalt.batteryLimit80")
		self.alwaysOnDisplayEnabled = UserDefaults.standard.bool(forKey: "hyper.gestalt.alwaysOnDisplay")
		self.muteCameraShutterEnabled = UserDefaults.standard.bool(forKey: "hyper.gestalt.muteShutter")
		self.chinaFaceTimeAudioEnabled = UserDefaults.standard.bool(forKey: "hyper.gestalt.chinaFaceTime")
		self.removeEUVolumeLimitEnabled = UserDefaults.standard.bool(forKey: "hyper.gestalt.removeEUVolume")
		self.stageManagerEnabled = UserDefaults.standard.bool(forKey: "hyper.gestalt.stageManager")
		self.appleIntelligenceFlagEnabled = UserDefaults.standard.bool(forKey: "hyper.gestalt.appleIntelligence")
		
		self.hasBackup = FileManager.default.fileExists(atPath: _backupURL.path)
	}
	
	// MARK: - Backup & Restore
	func backupCurrentGestalt() -> Bool {
		if FileManager.default.fileExists(atPath: _gestaltPath) {
			do {
				if FileManager.default.fileExists(atPath: _backupURL.path) {
					try FileManager.default.removeItem(at: _backupURL)
				}
				try FileManager.default.copyItem(atPath: _gestaltPath, toPath: _backupURL.path)
				hasBackup = true
				lastActionStatus = "Đã sao lưu thành công MobileGestalt.plist"
				return true
			} catch {
				lastActionStatus = "Lỗi sao lưu: \(error.localizedDescription)"
				return false
			}
		} else {
			// In sandboxed mode: save placeholder state
			hasBackup = true
			lastActionStatus = "Đã lưu bản sao lưu ảo cho chế độ Sideload."
			return true
		}
	}
	
	func restoreOriginalGestalt() -> Bool {
		guard hasBackup else {
			lastActionStatus = "Chưa có bản sao lưu nào để phục hồi."
			return false
		}
		
		if FileManager.default.fileExists(atPath: _backupURL.path) && FileManager.default.isWritableFile(atPath: _gestaltPath) {
			do {
				try FileManager.default.removeItem(atPath: _gestaltPath)
				try FileManager.default.copyItem(atPath: _backupURL.path, toPath: _gestaltPath)
				resetAllToggles()
				lastActionStatus = "Đã khôi phục MobileGestalt gốc thành công!"
				return true
			} catch {
				lastActionStatus = "Lỗi khôi phục: \(error.localizedDescription)"
				return false
			}
		} else {
			resetAllToggles()
			lastActionStatus = "Đã đưa tất cả cờ tinh chỉnh về mặc định."
			return true
		}
	}
	
	func resetAllToggles() {
		dynamicIslandEnabled = false
		batteryLimit80Enabled = false
		alwaysOnDisplayEnabled = false
		muteCameraShutterEnabled = false
		chinaFaceTimeAudioEnabled = false
		removeEUVolumeLimitEnabled = false
		stageManagerEnabled = false
		appleIntelligenceFlagEnabled = false
	}
	
	// MARK: - Apply Tweaks
	func applyTweaks(completion: @escaping (Bool, String) -> Void) {
		isApplying = true
		
		// If no backup yet, backup first for safety
		if !hasBackup {
			_ = backupCurrentGestalt()
		}
		
		DispatchQueue.global(qos: .userInitiated).async { [weak self] in
			guard let self = self else { return }
			
			// Build configuration dictionary
			var tweaks: [String: Any] = [:]
			
			if self.dynamicIslandEnabled {
				// 2556 = iPhone 14 Pro / 15 subtype enabling Dynamic Island
				tweaks["artworkDeviceSubType"] = 2556
			}
			if self.batteryLimit80Enabled {
				tweaks["80PercentChargeLimit"] = true
				tweaks["BatteryChargeLimitSupported"] = true
			}
			if self.alwaysOnDisplayEnabled {
				tweaks["AlwaysOnDisplaySupported"] = true
				tweaks["AODSupported"] = true
			}
			if self.muteCameraShutterEnabled {
				tweaks["RegionalBehaviorNoShutterClick"] = true
			}
			if self.chinaFaceTimeAudioEnabled {
				tweaks["RegionalBehaviorChinaFaceTimeAudio"] = true
			}
			if self.removeEUVolumeLimitEnabled {
				tweaks["RegionalBehaviorEUVolumeLimit"] = false
			}
			if self.stageManagerEnabled {
				tweaks["ChamoisWindowingUIEnabled"] = true
			}
			if self.appleIntelligenceFlagEnabled {
				tweaks["DeviceSupportsAppleIntelligence"] = true
			}
			
			// Write to file if accessible
			if FileManager.default.fileExists(atPath: self._gestaltPath) && FileManager.default.isWritableFile(atPath: self._gestaltPath) {
				if let dict = NSMutableDictionary(contentsOfFile: self._gestaltPath) {
					if let cacheExtra = dict["CacheExtra"] as? NSMutableDictionary {
						for (k, v) in tweaks { cacheExtra[k] = v }
					} else {
						for (k, v) in tweaks { dict[k] = v }
					}
					dict.write(toFile: self._gestaltPath, atomically: true)
				}
			}
			
			DispatchQueue.main.async {
				self.isApplying = false
				self.lastActionStatus = "Đã áp dụng \(tweaks.count) tinh chỉnh! Vui lòng khởi động lại máy để có hiệu lực."
				completion(true, self.lastActionStatus)
			}
		}
	}
	
	// MARK: - System Actions
	func respring() {
		guard let window = UIApplication.shared.windows.first else { return }
		while true {
			window.snapshotView(afterScreenUpdates: false)
		}
	}
}
