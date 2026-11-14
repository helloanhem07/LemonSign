//
//  SettingsView.swift
//  2809
//
//  Created by samara on 10.04.2025.
//  Refactored for 2809 on 14.11.2026.
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
	
	private let _donationsUrl = "https://github.com/sponsors/Kasumi-dta"
	
	// MARK: Body
	var body: some View {
		NBNavigationView(.localized("Settings")) {
			Form {
				// Header Card
				SettingsDonationCellView(site: _donationsUrl)
				
				// Giới thiệu
				Section {
					NavigationLink(destination: AboutNyaView()) {
						HStack(spacing: 12) {
							SettingsIconBadge(systemName: "info", color: .blue)
							Text("Giới thiệu")
								.foregroundColor(.primary)
						}
					}
				}
				
				// Giao diện
				Section {
					NavigationLink(destination: AppearanceView()) {
						HStack(spacing: 12) {
							SettingsIconBadge(systemName: "paintbrush.fill", color: .purple)
							Text(.localized("Appearance"))
								.foregroundColor(.primary)
						}
					}
				}
				
				// Chứng chỉ
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
					Text(.localized("Add and manage certificates used for signing applications."))
				}
				
				// Ký & Cài đặt
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
				
				// Tiện ích mạng & Tệp
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
				
				_directories()
				
				// Đặt lại
				Section {
					NavigationLink(destination: ResetView()) {
						HStack(spacing: 12) {
							SettingsIconBadge(systemName: "trash.fill", color: .red)
							Text(.localized("Reset"))
								.foregroundColor(.primary)
						}
					}
				} footer: {
					Text("Reset the applications sources, certificates, apps, and general contents.")
				}
			}
		}
	}
}

// MARK: - View extension
extension SettingsView {
	@ViewBuilder
	private func _directories() -> some View {
		NBSection(.localized("Misc")) {
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
			Text("Tất cả các tệp của 2809 trừ chứng chỉ được chứa trong thư mục tài liệu.")
		}
	}
}
