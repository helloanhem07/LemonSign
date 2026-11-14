//
//  SettingsView.swift
//  MSign - Liquid Glass Redesign
//
//  Created by samara on 10.04.2025.
//  Redesigned with Liquid Glass on 14.11.2026.
//

import SwiftUI
import NimbleViews

// MARK: - Liquid Glass Card Container
struct LiquidGlassCard<Content: View>: View {
	let title: String?
	let footer: String?
	let content: Content
	
	init(_ title: String? = nil, footer: String? = nil, @ViewBuilder content: () -> Content) {
		self.title = title
		self.footer = footer
		self.content = content()
	}
	
	var body: some View {
		VStack(alignment: .leading, spacing: 6) {
			if let title {
				Text(title)
					.font(.system(size: 13, weight: .semibold))
					.foregroundColor(.secondary)
					.padding(.horizontal, 16)
			}
			
			VStack(spacing: 0) {
				content
			}
			.background(.ultraThinMaterial)
			.clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
			.overlay(
				RoundedRectangle(cornerRadius: 20, style: .continuous)
					.stroke(
						LinearGradient(
							colors: [
								Color.white.opacity(0.22),
								Color.white.opacity(0.06)
							],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						),
						lineWidth: 0.6
					)
			)
			.shadow(color: Color.black.opacity(0.35), radius: 14, x: 0, y: 6)
			
			if let footer {
				Text(footer)
					.font(.system(size: 12))
					.foregroundColor(Color.secondary.opacity(0.85))
					.padding(.horizontal, 16)
					.padding(.top, 2)
			}
		}
	}
}

// MARK: - Liquid Glass Navigation Row
struct LiquidGlassRow<Destination: View>: View {
	let icon: String
	let iconColor: Color
	let title: String
	var badge: String? = nil
	let destination: Destination
	
	var body: some View {
		NavigationLink(destination: destination) {
			HStack(spacing: 14) {
				ZStack {
					RoundedRectangle(cornerRadius: 8, style: .continuous)
						.fill(iconColor)
						.frame(width: 30, height: 30)
						.shadow(color: iconColor.opacity(0.4), radius: 6, x: 0, y: 2)
					
					Image(systemName: icon)
						.font(.system(size: 15, weight: .semibold))
						.foregroundColor(.white)
				}
				
				Text(title)
					.font(.system(size: 16, weight: .regular))
					.foregroundColor(.primary)
				
				Spacer()
				
				if let badge {
					Text(badge)
						.font(.system(size: 15, weight: .regular))
						.foregroundColor(.secondary)
				}
				
				Image(systemName: "chevron.right")
					.font(.system(size: 13, weight: .semibold))
					.foregroundColor(Color.secondary.opacity(0.45))
			}
			.padding(.horizontal, 16)
			.padding(.vertical, 12)
			.contentShape(Rectangle())
		}
		.buttonStyle(.plain)
	}
}

// MARK: - Liquid Glass Button Row
struct LiquidGlassButtonRow: View {
	let icon: String
	let iconColor: Color
	let title: String
	let action: () -> Void
	
	var body: some View {
		Button(action: action) {
			HStack(spacing: 14) {
				ZStack {
					RoundedRectangle(cornerRadius: 8, style: .continuous)
						.fill(iconColor)
						.frame(width: 30, height: 30)
						.shadow(color: iconColor.opacity(0.4), radius: 6, x: 0, y: 2)
					
					Image(systemName: icon)
						.font(.system(size: 15, weight: .semibold))
						.foregroundColor(.white)
				}
				
				Text(title)
					.font(.system(size: 16, weight: .regular))
					.foregroundColor(.primary)
				
				Spacer()
				
				Image(systemName: "arrow.up.right")
					.font(.system(size: 12, weight: .semibold))
					.foregroundColor(Color.secondary.opacity(0.45))
			}
			.padding(.horizontal, 16)
			.padding(.vertical, 12)
			.contentShape(Rectangle())
		}
		.buttonStyle(.plain)
	}
}

// MARK: - Main Settings View
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
			ScrollView {
				VStack(spacing: 22) {
					// 1. CHỨNG CHỈ (Liquid Glass Card)
					LiquidGlassCard("Chứng chỉ", footer: "Thêm và quản lý chứng chỉ ký ứng dụng.") {
						LiquidGlassRow(
							icon: "signature",
							iconColor: .orange,
							title: .localized("Certificates"),
							badge: "\(_certificates.count)",
							destination: CertificatesView()
						)
						
						Divider()
							.background(Color.white.opacity(0.08))
							.padding(.leading, 60)
						
						if let cert = selectedCertificate {
							VStack(alignment: .leading, spacing: 0) {
								CertificatesCellView(cert: cert)
									.padding(.horizontal, 16)
									.padding(.vertical, 8)
							}
						} else {
							HStack {
								Text(.localized("No Certificate"))
									.font(.subheadline)
									.foregroundColor(.secondary)
								Spacer()
							}
							.padding(.horizontal, 16)
							.padding(.vertical, 12)
						}
					}
					
					// 2. KÝ & CÀI ĐẶT IPA (Liquid Glass Card)
					LiquidGlassCard("Ký & Cài Đặt IPA") {
						LiquidGlassRow(
							icon: "server.rack",
							iconColor: .teal,
							title: .localized("Installation"),
							destination: InstallationView()
						)
						
						Divider()
							.background(Color.white.opacity(0.08))
							.padding(.leading, 60)
						
						LiquidGlassRow(
							icon: "gearshape.fill",
							iconColor: .gray,
							title: .localized("Signing Options"),
							destination: ConfigurationView()
						)
						
						Divider()
							.background(Color.white.opacity(0.08))
							.padding(.leading, 60)
						
						LiquidGlassRow(
							icon: "archivebox.fill",
							iconColor: .brown,
							title: .localized("Archive & Extraction"),
							destination: ArchiveView()
						)
						
						Divider()
							.background(Color.white.opacity(0.08))
							.padding(.leading, 60)
						
						LiquidGlassRow(
							icon: "apple.terminal",
							iconColor: Color(white: 0.15),
							title: .localized("Logs"),
							destination: LogsView(manager: LogsManager.shared)
						)
						
						Divider()
							.background(Color.white.opacity(0.08))
							.padding(.leading, 60)
						
						LiquidGlassRow(
							icon: "sparkles",
							iconColor: .yellow,
							title: .localized("App Features"),
							destination: AppFeaturesView()
						)
					}
					
					// 3. CÔNG CỤ MỞ RỘNG (Liquid Glass Card)
					LiquidGlassCard("Công Cụ Mở Rộng", footer: "Chia sẻ và nhận file IPA không dây qua mạng WiFi cục bộ.") {
						LiquidGlassRow(
							icon: "wifi",
							iconColor: .indigo,
							title: "AirShare WiFi & QR",
							destination: AirShareView()
						)
					}
					
					// 4. KHÁC (Liquid Glass Card)
					LiquidGlassCard("Khác", footer: "Tất cả các tệp của MSign trừ chứng chỉ được chứa trong thư mục tài liệu.") {
						LiquidGlassButtonRow(
							icon: "folder.fill",
							iconColor: .blue,
							title: .localized("Open Documents")
						) {
							UIApplication.open(URL.documentsDirectory.toSharedDocumentsURL()!)
						}
						
						Divider()
							.background(Color.white.opacity(0.08))
							.padding(.leading, 60)
						
						LiquidGlassButtonRow(
							icon: "archivebox",
							iconColor: .cyan,
							title: .localized("Open Archives")
						) {
							UIApplication.open(FileManager.default.archives.toSharedDocumentsURL()!)
						}
					}
					
					// 5. ĐẶT LẠI (Liquid Glass Card)
					LiquidGlassCard(footer: "Đặt lại kho ứng dụng, chứng chỉ, app, và những thứ khác.") {
						LiquidGlassRow(
							icon: "trash.fill",
							iconColor: .red,
							title: .localized("Reset"),
							destination: ResetView()
						)
					}
				}
				.padding(.horizontal, 16)
				.padding(.top, 12)
				.padding(.bottom, 36)
			}
			.background(
				LinearGradient(
					colors: [
						Color(red: 0x08/255, green: 0x0A/255, blue: 0x10/255),
						Color(red: 0x0E/255, green: 0x12/255, blue: 0x1D/255)
					],
					startPoint: .top,
					endPoint: .bottom
				)
				.ignoresSafeArea()
			)
		}
	}
}
