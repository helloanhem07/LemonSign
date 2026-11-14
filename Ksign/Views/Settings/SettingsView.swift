//
//  SettingsView.swift
//  MSign
//
//  Created by samara on 10.04.2025.
//  Refactored for MSign on 14.11.2026.
//

import SwiftUI
import NimbleViews

// MARK: - Icon Badge Helper
struct SettingsIconBadge: View {
	let systemName: String
	let color: Color
	
	var body: some View {
		ZStack {
			RoundedRectangle(cornerRadius: 7, style: .continuous)
				.fill(color)
				.frame(width: 28, height: 28)
			
			Image(systemName: systemName)
				.font(.system(size: 14, weight: .semibold))
				.foregroundColor(.white)
		}
	}
}

// MARK: - View
struct SettingsView: View {
	@Environment(\.dismiss) private var dismiss
	@AppStorage("feather.selectedCert") private var _storedSelectedCert: Int = 0
	@FetchRequest(
		entity: CertificatePair.entity(),
		sortDescriptors: [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)],
		animation: .snappy
	) private var _certificates: FetchedResults<CertificatePair>
	
	private var selectedCertificate: CertificatePair? {
		guard
			_storedSelectedCert >= 0,
			_storedSelectedCert < _certificates.count
		else {
			return nil
		}
		return _certificates[_storedSelectedCert]
	}
	
	// MARK: Body
	var body: some View {
		NBNavigationView(.localized("Settings")) {
			Form {
				// 1. Chứng chỉ
				NBSection(.localized("Certificates")) {
					NavigationLink(destination: CertificatesView()) {
						HStack(spacing: 12) {
							SettingsIconBadge(systemName: "signature", color: .orange)
							Text(.localized("Certificates"))
								.foregroundColor(.primary)
							Spacer()
							Text("\(_certificates.count)")
								.font(.subheadline)
								.foregroundColor(.secondary)
						}
					}
					
					if let cert = selectedCertificate {
						CertificatesCellView(cert: cert)
					} else {
						Text(.localized("No Certificate"))
							.font(.footnote)
							.foregroundColor(.disabled())
					}
				} footer: {
					Text("Thêm và quản lý chứng chỉ ký ứng dụng.")
				}
				
				// 2. Ký & Cài Đặt IPA
				NBSection("Ký & Cài Đặt IPA") {
					NavigationLink(destination: InstallationView()) {
						HStack(spacing: 12) {
							SettingsIconBadge(systemName: "server.rack", color: .teal)
							Text(.localized("Installation"))
								.foregroundColor(.primary)
						}
					}
					NavigationLink(destination: ConfigurationView()) {
						HStack(spacing: 12) {
							SettingsIconBadge(systemName: "gearshape.fill", color: .gray)
							Text(.localized("Signing Options"))
								.foregroundColor(.primary)
						}
					}
					NavigationLink(destination: ArchiveView()) {
						HStack(spacing: 12) {
							SettingsIconBadge(systemName: "archivebox.fill", color: .brown)
							Text(.localized("Archive & Extraction"))
								.foregroundColor(.primary)
						}
					}
					NavigationLink(destination: LogsView(manager: LogsManager.shared)) {
						HStack(spacing: 12) {
							SettingsIconBadge(systemName: "apple.terminal", color: .black)
							Text(.localized("Logs"))
								.foregroundColor(.primary)
						}
					}
					NavigationLink(destination: AppFeaturesView()) {
						HStack(spacing: 12) {
							SettingsIconBadge(systemName: "sparkles", color: .yellow)
							Text(.localized("App Features"))
								.foregroundColor(.primary)
						}
					}
				}
				
				// 3. Công Cụ Mở Rộng
				NBSection("Công Cụ Mở Rộng") {
					NavigationLink(destination: AirShareView()) {
						HStack(spacing: 12) {
							SettingsIconBadge(systemName: "wifi", color: .indigo)
							Text("AirShare WiFi & QR")
								.foregroundColor(.primary)
						}
					}
				} footer: {
					Text("Chia sẻ và nhận file IPA không dây qua mạng WiFi cục bộ.")
				}
				
				// 4. Khác
				NBSection("Khác") {
					Button {
						UIApplication.open(URL.documentsDirectory.toSharedDocumentsURL()!)
					} label: {
						HStack(spacing: 12) {
							SettingsIconBadge(systemName: "folder.fill", color: .blue)
							Text(.localized("Open Documents"))
								.foregroundColor(.primary)
						}
					}
					Button {
						UIApplication.open(FileManager.default.archives.toSharedDocumentsURL()!)
					} label: {
						HStack(spacing: 12) {
							SettingsIconBadge(systemName: "archivebox", color: .cyan)
							Text(.localized("Open Archives"))
								.foregroundColor(.primary)
						}
					}
				} footer: {
					Text("Tất cả các tệp của MSign trừ chứng chỉ được chứa trong thư mục tài liệu.")
				}
				
				// 5. Đặt lại
				Section {
					NavigationLink(destination: ResetView()) {
						HStack(spacing: 12) {
							SettingsIconBadge(systemName: "trash.fill", color: .red)
							Text(.localized("Reset"))
								.foregroundColor(.primary)
						}
					}
				} footer: {
					Text("Đặt lại kho ứng dụng, chứng chỉ, app, và những thứ khác.")
				}
			}
		}
	}
}
