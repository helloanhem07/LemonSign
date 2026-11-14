//
//  UpdateManager.swift
//  MSign
//
//  Created by samara on 2026.
//  Updated for MSign on 14.11.2026.
//

import UIKit

final class UpdateManager: NSObject {
	static let shared = UpdateManager()

	static let currentAppVersion = "1.1"
	static let currentAppBuild = 2
	static let currentAppTag = "v1.1"

	private let _repoJsonUrl = "https://raw.githubusercontent.com/helloanhem07/MSign/refs/heads/main/repo.json"
	private let _releasesApiUrl = "https://api.github.com/repos/helloanhem07/MSign/releases?per_page=5"
	private var _isChecking = false

	private override init() {
		super.init()
	}

	func checkOnLaunch() {
		// Delay slightly so UI hierarchy is completely loaded
		DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
			self?.checkForUpdates(isManualCheck: false)
		}
	}

	func checkForUpdates(isManualCheck: Bool = false) {
		guard !_isChecking else { return }
		_isChecking = true

		// Check repo.json first with cache buster
		let timestamp = Int(Date().timeIntervalSince1970)
		guard let url = URL(string: "\(_repoJsonUrl)?t=\(timestamp)") else {
			_isChecking = false
			return
		}

		var request = URLRequest(url: url)
		request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
		request.timeoutInterval = 10

		let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
			if let data = data,
			   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
			   let apps = json["apps"] as? [[String: Any]],
			   let msignApp = apps.first(where: {
				   ($0["bundleIdentifier"] as? String)?.contains("msign") == true ||
				   ($0["name"] as? String)?.contains("MSign") == true
			   }) {
				let remoteVersion = msignApp["version"] as? String ?? "1.0"
				let remoteBuildStr = (msignApp["buildVersion"] as? String) ?? "\(msignApp["buildVersion"] as? Int ?? 1)"
				let remoteBuild = Int(remoteBuildStr) ?? 1
				let downloadURL = msignApp["downloadURL"] as? String ?? "https://github.com/helloanhem07/LemonSign/releases/download/v1.1/msign1.1.ipa"
				let desc = msignApp["localizedDescription"] as? String ?? ""

				DispatchQueue.main.async {
					self?._isChecking = false
					self?._processRelease(
						version: remoteVersion,
						build: remoteBuild,
						tag: "v\(remoteVersion)",
						name: "MSign v\(remoteVersion)",
						body: desc,
						downloadURL: downloadURL,
						isManualCheck: isManualCheck
					)
				}
			} else {
				// Fallback to GitHub Releases API
				self?._checkGitHubReleases(isManualCheck: isManualCheck)
			}
		}
		task.resume()
	}

	private func _checkGitHubReleases(isManualCheck: Bool) {
		guard let url = URL(string: _releasesApiUrl) else {
			_isChecking = false
			return
		}

		var request = URLRequest(url: url)
		request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
		request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
		request.setValue("MSign-iOS-Client", forHTTPHeaderField: "User-Agent")
		request.timeoutInterval = 10

		let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
			defer { self?._isChecking = false }

			if let data = data,
			   let releases = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
			   let firstRelease = releases.first,
			   let tagName = firstRelease["tag_name"] as? String {

				let releaseName = firstRelease["name"] as? String ?? tagName
				let body = firstRelease["body"] as? String ?? ""

				var parsedVersion = ""
				if let regex = try? NSRegularExpression(pattern: #"v?([0-9]+\.[0-9]+(?:\.[0-9]+)*)"#) {
					let searchString = "\(releaseName) \(tagName)"
					let nsString = searchString as NSString
					if let match = regex.firstMatch(in: searchString, range: NSRange(location: 0, length: nsString.length)) {
						parsedVersion = nsString.substring(with: match.range(at: 1))
					}
				}
				if parsedVersion.isEmpty {
					parsedVersion = tagName
				}

				var downloadURLString = "https://github.com/helloanhem07/LemonSign/releases/download/\(tagName)/MSign.ipa"
				if let assets = firstRelease["assets"] as? [[String: Any]] {
					for asset in assets {
						if let name = asset["name"] as? String, name.hasSuffix(".ipa"),
						   let browserURL = asset["browser_download_url"] as? String {
							downloadURLString = browserURL
							break
						}
					}
				}

				DispatchQueue.main.async {
					self?._processRelease(
						version: parsedVersion,
						build: 1,
						tag: tagName,
						name: releaseName,
						body: body,
						downloadURL: downloadURLString,
						isManualCheck: isManualCheck
					)
				}
			} else if isManualCheck {
				DispatchQueue.main.async {
					UIAlertController.showAlertWithOk(
						title: String.localized("Error"),
						message: String.localized("Failed to check for updates.")
					)
				}
			}
		}
		task.resume()
	}

	private func _isRemoteNewer(remoteVersion: String, remoteBuild: Int, remoteTag: String) -> Bool {
		let cleanRemote = remoteVersion.trimmingCharacters(in: CharacterSet(charactersIn: "vV "))
		let cleanCurrent = Self.currentAppVersion.trimmingCharacters(in: CharacterSet(charactersIn: "vV "))

		let remoteParts = cleanRemote.split(separator: ".").compactMap { Int($0) }
		let currentParts = cleanCurrent.split(separator: ".").compactMap { Int($0) }

		let maxCount = max(remoteParts.count, currentParts.count)
		for i in 0..<maxCount {
			let r = i < remoteParts.count ? remoteParts[i] : 0
			let c = i < currentParts.count ? currentParts[i] : 0
			if r > c { return true }
			if r < c { return false }
		}

		if remoteBuild > Self.currentAppBuild {
			return true
		}

		let cleanTag = remoteTag.trimmingCharacters(in: CharacterSet(charactersIn: "vV "))
		if cleanTag != cleanCurrent && !cleanTag.isEmpty {
			let tagParts = cleanTag.split(separator: ".").compactMap { Int($0) }
			let maxTagCount = max(tagParts.count, currentParts.count)
			for i in 0..<maxTagCount {
				let t = i < tagParts.count ? tagParts[i] : 0
				let c = i < currentParts.count ? currentParts[i] : 0
				if t > c { return true }
				if t < c { return false }
			}
		}

		return false
	}

	private func _processRelease(
		version: String,
		build: Int,
		tag: String,
		name: String,
		body: String,
		downloadURL: String,
		isManualCheck: Bool
	) {
		let isNewer = _isRemoteNewer(remoteVersion: version, remoteBuild: build, remoteTag: tag)

		if isNewer {
			let updateTitle = String.localized("Update Available")
			let message = "Đã có bản cập nhật mới cho MSign (v\(version)). Bạn có muốn cập nhật không?"

			let downloadAction = UIAlertAction(title: "Cập nhật ngay", style: .default) { _ in
				if let dlUrl = URL(string: downloadURL) {
					_ = DownloadManager.shared.startDownload(from: dlUrl, id: "MSign_Update_\(UUID().uuidString)")
					UIAlertController.showAlertWithOk(
						title: "Đang tải bản cập nhật",
						message: "MSign đang tải bản cập nhật về máy. Bạn có thể theo dõi tiến trình trong mục Tải về để ký và cài đặt đè."
					)
				}
			}

			let cancelAction = UIAlertAction(title: "Để sau", style: .cancel, handler: nil)

			UIAlertController.showAlert(
				title: updateTitle,
				message: message,
				actions: [downloadAction, cancelAction]
			)
		} else if isManualCheck {
			let title = "Kiểm tra cập nhật"
			let message = "MSign đang ở phiên bản mới nhất."
			UIAlertController.showAlertWithOk(
				title: title,
				message: message
			)
		}
	}
}
