//
//  SettingsView.swift
//  Feather
//
//  Created by samara on 10.04.2025.
//  Refactored for LemonSign on 14.11.2026.
//

import SwiftUI
import NimbleViews

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
	private let _githubUrl = "https://github.com/Kasumi-dta"
    private let _telegramUrl = "https://t.me/applep12vnn"
    
	// MARK: Body
    var body: some View {
		NBNavigationView(.localized("Settings")) {
			Form {
				SettingsDonationCellView(site: _donationsUrl)
				
				_feedback()
				
				Section {
					NavigationLink(destination: AppearanceView()) {
                        Label(.localized("Appearance"), systemImage: "paintbrush")
                    }
					NavigationLink(destination: AppIconView()) {
                        Label("Biểu tượng Ứng dụng", systemImage: "app.dashed")
                    }
				}
                
                NBSection("Công Cụ Mở Rộng") {
                    NavigationLink(destination: AirShareView()) {
                        Label("AirShare WiFi & QR", systemImage: "wifi.circle.fill")
                    }
                } footer: {
                    Text("Chia sẻ và nhận file IPA không dây qua mạng WiFi cục bộ.")
                }
                
                NBSection(.localized("Certificates")) {
                    NavigationLink(destination: CertificatesView()) {
                        HStack {
                            Label(.localized("Certificates"), systemImage: "signature")
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
				
				NBSection("Ký & Cài Đặt IPA") {
					NavigationLink(destination: InstallationView()) {
                        Label(.localized("Installation"), systemImage: "server.rack")
                    }
					NavigationLink(destination: ConfigurationView()) {
                        Label(.localized("Signing Options"), systemImage: "gear")
                    }
					NavigationLink(destination: ArchiveView()) {
                        Label(.localized("Archive & Extraction"), systemImage: "archivebox")
                    }
                    NavigationLink(destination: LogsView(manager: LogsManager.shared)) {
                        Label(.localized("Logs"), systemImage: "apple.terminal")
                    }
					NavigationLink(destination: AppFeaturesView()) {
                        Label(.localized("App Features"), systemImage: "sparkles")
                    }
				}
				
				_directories()
                
                Section {
                    NavigationLink(destination: ResetView()) {
                        Label(.localized("Reset"), systemImage: "trash")
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
	private func _feedback() -> some View {
		Section {
			NavigationLink(destination: AboutNyaView()) {
                Label("Giới thiệu", systemImage: "info.circle")
            }
			Button {
				UpdateManager.shared.checkForUpdates(isManualCheck: true)
			} label: {
                Label("Kiểm tra bản cập nhật", systemImage: "arrow.triangle.2.circlepath.circle")
            }
			Button {
				UIApplication.open(_telegramUrl)
			} label: {
                Label("Telegram Channel", systemImage: "paperplane.circle")
            }
			Button {
				UIApplication.open(_githubUrl)
			} label: {
                Label("Kho lưu trữ GitHub", systemImage: "safari")
            }
		}
	}
	
	@ViewBuilder
	private func _directories() -> some View {
		NBSection(.localized("Misc")) {
			Button(.localized("Open Documents"), systemImage: "folder") {
				UIApplication.open(URL.documentsDirectory.toSharedDocumentsURL()!)
			}
			Button(.localized("Open Archives"), systemImage: "folder") {
				UIApplication.open(FileManager.default.archives.toSharedDocumentsURL()!)
			}
		} footer: {
			Text(.localized("All of LemonSign files except certificates are contained in the documents directory, here are some quick links to these."))
		}
	}
}
