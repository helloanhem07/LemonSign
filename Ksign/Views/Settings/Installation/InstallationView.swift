//
//  InstallationView.swift
//  Feather
//
//  Created by samara on 3.06.2025.
//

import SwiftUI
import NimbleViews

// MARK: - View
struct InstallationView: View {
    @AppStorage("Feather.installationMethod") private var _installationMethod: Int = 0
    @State private var _showMethodChangedAlert = false

    private var _installationMethods: [String] {
        var methods = [
            String.localized("Server"),
            String.localized("idevice")
        ]
        if TrollStoreHelper.isTrollStoreAvailable {
            methods.append("TrollStore")
        }
        return methods
    }
    
    // MARK: Body
    var body: some View {
        NBList("Trình cài đặt") {
            Section {
                Picker("Kiểu cài đặt", systemImage: "arrow.down.app", selection: $_installationMethod) {
                    ForEach(_installationMethods.indices, id: \.description) { index in
                        Text(_installationMethods[index]).tag(index)
                    }
                }
            } footer: {
                Text("Máy chủ (Khuyến nghị):\nSử dụng máy chủ lưu trữ cục bộ và itms-services:// để cài đặt ứng dụng.\n\nIDevice (nâng cao):\nSử dụng VPN và tệp ghép nối. Ghi vào AFC và gọi installd theo cách thủ công, đồng thời theo dõi tiến trình cài đặt bằng cách sử dụng lệnh gọi lại\nƯu điểm: Rất đáng tin cậy, không cần chứng chỉ SSL hoặc máy chủ lưu trữ bên ngoài. Thay vào đó, hoạt động tương tự như máy tính.")
            }
            
            if _installationMethod == 0 {
                ServerView()
            } else if _installationMethod == 1 {
                TunnelView()
            }
        }
        .onChange(of: _installationMethod) { newValue in
            guard newValue == 1 else { return }
            _showMethodChangedAlert = true
        }
        .alert(.localized("Advanced Installation Method"), isPresented: $_showMethodChangedAlert) {
            Button(.localized("Switch Back"), role: .destructive) {
                _installationMethod = 0
            }
            Button(.localized("OK"), role: .cancel) {}
        } message: {
            Text(.localized("idevice warning"))
        }

        .animation(.default, value: _installationMethod)
    }
}
