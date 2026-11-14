//
//  ServerView.swift
//  Feather
//
//  Created by samara on 6.05.2025.
//

import SwiftUI
import NimbleJSON
import NimbleViews

struct ServerView: View {
	@AppStorage("Feather.ipFix") private var _ipFix: Bool = false
	@AppStorage("Feather.serverMethod") private var _serverMethod: Int = 0
	@State private var _isUpdatingSSL: Bool = false
	
	private let _serverMethods: [String] = [
		"Cục bộ hoàn toàn", 
		"Bán cục bộ"
	]
	
	private let _serverPackUrl = "https://backloop.dev/pack.json"
	
	var body: some View {
		Group {
			Section {
				Picker("Loại máy chủ", systemImage: "server.rack", selection: $_serverMethod) {
					ForEach(_serverMethods.indices, id: \.self) { index in
						Text(_serverMethods[index]).tag(index)
					}
				}
				Toggle("Chỉ sử dụng địa chỉ localhost", systemImage: "network", isOn: $_ipFix)
					.disabled(_serverMethod != 1)
			}
			
			Section {
				Button {
					_updateSSL()
				} label: {
					HStack {
						Label("Cập nhật chứng chỉ SSL", systemImage: "doc.text")
						if _isUpdatingSSL {
							Spacer()
							ProgressView()
						}
					}
				}
				.disabled(_isUpdatingSSL)
			}
		}
		.onChange(of: _serverMethod) { _ in
			UIAlertController.showAlertWithRestart(
				title: .localized("Restart Required"),
				message: .localized("These changes require a restart of the app")
			)
		}
	}
	
	private func _updateSSL() {
		_isUpdatingSSL = true
		FR.downloadSSLCertificates(from: _serverPackUrl) { success in
			DispatchQueue.main.async {
				_isUpdatingSSL = false
				if success {
					UIAlertController.showAlertWithOk(
						title: "Chứng chỉ SSL",
						message: "Cập nhật chứng chỉ SSL thành công! Vui lòng khởi động lại ứng dụng hoặc thử cài đặt lại."
					)
				} else {
					UIAlertController.showAlertWithOk(
						title: "Chứng chỉ SSL",
						message: "Tải chứng chỉ SSL thất bại, vui lòng kiểm tra kết nối mạng và thử lại."
					)
				}
			}
		}
	}
}
