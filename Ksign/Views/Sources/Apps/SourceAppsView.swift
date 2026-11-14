//
//  SourceAppsView.swift
//  Feather
//
//  Created by samara on 1.05.2025.
//

import SwiftUI
import AltSourceKit
import NimbleViews
import UIKit

// MARK: - Extension: View (Enil)
extension SourceAppsView {
    enum SortOption: String, CaseIterable {
        case `default` = "default"
        case name
        case date
        
        var displayName: String {
            switch self {
            case .default:  .localized("Default")
            case .name:     .localized("Name")
            case .date:     .localized("Date")
            }
        }
    }
}

// MARK: - View
struct SourceAppsView: View {
    @AppStorage("Feather.sortOptionRawValue") private var _sortOptionRawValue: String = SortOption.default.rawValue
    @AppStorage("Feather.sortAscending") private var _sortAscending: Bool = true
    
    @State private var _sortOption: SortOption = .default
    @State private var _selectedRoute: SourceAppRoute?
    
    @State var isLoading = true
    @State var hasLoadedOnce = false
    @State private var _searchText = ""
    var fromAppStore: Bool = false
    
    private var _navigationTitle: String {
        if fromAppStore {
            return .localized("App Store")
        } else if object.count == 1 {
            return object[0].name ?? .localized("Unknown")
        } else {
            return .localized("%lld Sources", arguments: object.count)
        }
    }
    
    var object: [AltSource]
    @ObservedObject var viewModel: SourcesViewModel
    @State private var _sources: [ASRepository]?
    
    @FetchRequest(
        entity: AltSource.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \AltSource.name, ascending: true)],
        animation: .snappy
    ) private var _allSources: FetchedResults<AltSource>
    
    // MARK: Body
    var body: some View {
        ZStack {
            if
                let _sources,
                !_sources.isEmpty
            {
                SourceAppsTableRepresentableView(
                    sources: _sources,
                    searchText: $_searchText,
                    sortOption: $_sortOption,
                    sortAscending: $_sortAscending,
                    onSelect: {self._selectedRoute = $0}
                )
                .ignoresSafeArea()
            } else {
                if viewModel.isFetching || isLoading {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0x0A/255, green: 0x84/255, blue: 0xFF/255).opacity(0.25),
                                            Color(red: 0x00/255, green: 0xC6/255, blue: 0xFF/255).opacity(0.12)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: "shippingbox.fill")
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0x0A/255, green: 0x84/255, blue: 0xFF/255),
                                            Color(red: 0x00/255, green: 0xC6/255, blue: 0xFF/255)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        
                        VStack(spacing: 6) {
                            Text("Đang tải dữ liệu kho ứng dụng...")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            if viewModel.totalSourcesCount > 0 {
                                Text("\(viewModel.loadedSourcesCount) / \(viewModel.totalSourcesCount) kho nguồn")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundColor(Color.white.opacity(0.7))
                            } else {
                                Text("Đang kết nối các kho IPA...")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundColor(Color.white.opacity(0.7))
                            }
                        }
                        
                        ProgressView(value: viewModel.totalSourcesCount > 0 ? min(1.0, Double(viewModel.loadedSourcesCount) / Double(max(1, viewModel.totalSourcesCount))) : nil)
                            .progressViewStyle(LinearProgressViewStyle(tint: Color(red: 0x0A/255, green: 0x84/255, blue: 0xFF/255)))
                            .frame(width: 220)
                        
                        if !viewModel.currentLoadingSourceName.isEmpty {
                            Text(viewModel.currentLoadingSourceName)
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(Color.white.opacity(0.6))
                                .lineLimit(1)
                                .frame(maxWidth: 220)
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.vertical, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0x0A/255, green: 0x84/255, blue: 0xFF/255).opacity(0.4),
                                                Color.white.opacity(0.12)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                    )
                    .shadow(color: Color.black.opacity(0.4), radius: 20, x: 0, y: 10)
                } else if #available(iOS 17, *) {
                    ContentUnavailableView {
                        Label(.localized("No Apps Available"), systemImage: "square.stack.3d.up.slash")
                    } description: {
                        Text(.localized("Stuck? Check if you have any sources added."))
                    }
                } else {
                    ProgressView()
                }
            }
        }
        .overlay(alignment: .top) {
            if let sources = _sources, !sources.isEmpty, viewModel.isFetching && viewModel.totalSourcesCount > 0 && viewModel.loadedSourcesCount < viewModel.totalSourcesCount {
                VStack(spacing: 0) {
                    ProgressView(value: Double(viewModel.loadedSourcesCount), total: Double(max(1, viewModel.totalSourcesCount)))
                        .progressViewStyle(LinearProgressViewStyle(tint: Color(red: 0x0A/255, green: 0x84/255, blue: 0xFF/255)))
                        .frame(height: 2.5)
                    
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.65)
                        Text("Đang nạp thêm nguồn IPA...")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(viewModel.loadedSourcesCount)/\(viewModel.totalSourcesCount)")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(Color(red: 0x0A/255, green: 0x84/255, blue: 0xFF/255))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .overlay(
                        Rectangle()
                            .frame(height: 0.5)
                            .foregroundColor(Color.white.opacity(0.1)),
                        alignment: .bottom
                    )
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.isFetching)
        .navigationTitle(_navigationTitle)
        .searchable(text: $_searchText, placement: .platform())
        .toolbarTitleMenu {
            if
                let _sources,
                _sources.count == 1
            {
                if let url = _sources[0].website {
                    Button(.localized("Visit Website"), systemImage: "globe") {
                        UIApplication.open(url)
                    }
                }
                
                if let url = _sources[0].patreonURL {
                    Button(.localized("Visit Patreon"), systemImage: "dollarsign.circle") {
                        UIApplication.open(url)
                    }
                }
            }
            
            Divider()
            
            Button(.localized("Copy"), systemImage: "doc.on.doc") {
                UIPasteboard.general.string = object.map {
                    $0.sourceURL!.absoluteString
                }.joined(separator: "\n")
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
        .toolbar {
            if fromAppStore {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink {
                        SourcesView()
                    } label: {
                        Text(.localized("Sources"))
                    }
                }
            }
            
            NBToolbarButton(
                systemImage: "arrow.trianglehead.2.counterclockwise.rotate.90",
                style: .icon,
                placement: .topBarTrailing
            ) {
                Task {
                    await viewModel.fetchSources(_allSources, refresh: true)
                }
            }
            
            NBToolbarMenu(
                systemImage: "line.3.horizontal.decrease",
                style: .icon,
                placement: .topBarTrailing
            ) {
                _sortActions()
            }
        }
        .onAppear {
            if !hasLoadedOnce, viewModel.isFinished {
                _load()
                hasLoadedOnce = true
            }
            _sortOption = SortOption(rawValue: _sortOptionRawValue) ?? .default
        }
        .onChange(of: viewModel.isFinished) { _ in
            _load()
        }
        .onChange(of: viewModel.loadedSourcesCount) { _ in
            _load()
        }
        .onChange(of: _sortOption) { newValue in
            _sortOptionRawValue = newValue.rawValue
        }
        .navigationDestinationIfAvailable(item: $_selectedRoute) { route in
            SourceAppsDetailView(source: route.source, app: route.app)
        }
        
    }
    
    private func _load() {
        isLoading = true
        
        Task {
            let loadedSources = object.compactMap { viewModel.sources[$0] }
            _sources = loadedSources
            withAnimation(.easeIn(duration: 0.2)) {
                isLoading = false
            }
        }
    }
    
    struct SourceAppRoute: Identifiable, Hashable {
        let source: ASRepository
        let app: ASRepository.App
        let id: String = UUID().uuidString
    }
}

// MARK: - Extension: View (Sort)
extension SourceAppsView {
    @ViewBuilder
    private func _sortActions() -> some View {
        Section(.localized("Filter by")) {
            ForEach(SortOption.allCases, id: \.displayName) { opt in
                _sortButton(for: opt)
            }
        }
    }
    
    private func _sortButton(for option: SortOption) -> some View {
        Button {
            if _sortOption == option {
                _sortAscending.toggle()
            } else {
                _sortOption = option
                _sortAscending = true
            }
        } label: {
            HStack {
                Text(option.displayName)
                Spacer()
                if _sortOption == option {
                    Image(systemName: _sortAscending ? "chevron.up" : "chevron.down")
                }
            }
        }
    }
}

import SwiftUI

extension View {
    @ViewBuilder
    func navigationDestinationIfAvailable<Item: Identifiable & Hashable, Destination: View>(
        item: Binding<Item?>,
        @ViewBuilder destination: @escaping (Item) -> Destination
    ) -> some View {
        if #available(iOS 17, *) {
            self.navigationDestination(item: item, destination: destination)
        } else {
            self
        }
    }
}
