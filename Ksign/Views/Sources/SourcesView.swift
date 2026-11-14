//
//  SourcesView.swift
//  MSign
//
//  Created by samara on 10.04.2025.
//  Refactored for MSign with Delete, Edit, and Cron Health-Check on 14.11.2026.
//

import CoreData
import AltSourceKit
import SwiftUI
import NimbleViews

// MARK: - View
struct SourcesView: View {
	@StateObject var viewModel = SourcesViewModel.shared
	@State private var _isAddingPresenting = false
	@State private var _addingSourceLoading = false
	@State private var _searchText = ""
	
	// Edit Source state
	@State private var _sourceToEdit: AltSource?
	@State private var _editingURL: String = ""
	@State private var _isEditPresenting = false
	
	private var _filteredSources: [AltSource] {
		_sources.filter { source in
			let matchesSearch = _searchText.isEmpty || (source.name?.localizedCaseInsensitiveContains(_searchText) ?? false)
			let isHealthy = !viewModel.failedSourceURLs.contains(source.sourceURL?.absoluteString ?? "")
			return matchesSearch && isHealthy
		}
	}
	
	@FetchRequest(
		entity: AltSource.entity(),
		sortDescriptors: [NSSortDescriptor(keyPath: \AltSource.name, ascending: true)],
		animation: .snappy
	) private var _sources: FetchedResults<AltSource>
	
	// MARK: Body
	var body: some View {
		NBNavigationView(.localized("Sources")) {
			NBListAdaptable {
				NBSection(
					.localized("Repositories"),
					secondary: _filteredSources.count.description
				) {
					ForEach(_filteredSources) { source in
						NavigationLink {
							SourceAppsView(object: [source], viewModel: viewModel)
						} label: {
							SourcesCellView(source: source)
						}
						.buttonStyle(.plain)
						.swipeActions(edge: .trailing, allowsFullSwipe: true) {
							Button(role: .destructive) {
								Storage.shared.deleteSource(for: source)
							} label: {
								Label("Xóa", systemImage: "trash.fill")
							}
						}
						.swipeActions(edge: .leading) {
							Button {
								_sourceToEdit = source
								_editingURL = source.sourceURL?.absoluteString ?? ""
								_isEditPresenting = true
							} label: {
								Label("Sửa", systemImage: "pencil")
							}
							.tint(.blue)
						}
						.contextMenu {
							Button {
								UIPasteboard.general.string = source.sourceURL?.absoluteString
							} label: {
								Label("Sao chép liên kết", systemImage: "doc.on.clipboard")
							}
							
							Button {
								_sourceToEdit = source
								_editingURL = source.sourceURL?.absoluteString ?? ""
								_isEditPresenting = true
							} label: {
								Label("Sửa nguồn", systemImage: "pencil")
							}
							
							Divider()
							
							Button(role: .destructive) {
								Storage.shared.deleteSource(for: source)
							} label: {
								Label("Xóa nguồn", systemImage: "trash.fill")
							}
						}
					}
				}
			}
			.searchable(text: $_searchText, placement: .platform())
			.overlay {
				if _filteredSources.isEmpty {
					if #available(iOS 17, *) {
						ContentUnavailableView {
							Label(.localized("No Repositories"), systemImage: "globe.desk.fill")
						} description: {
							Text(.localized("Get started by adding your first repository."))
						} actions: {
							Button {
								_isAddingPresenting = true
							} label: {
								Text("Add Source").bg()
							}
						}
					}
				}
			}
			.toolbar {
				NBToolbarButton(
					systemImage: "plus",
					style: .icon,
					placement: .topBarTrailing,
					isDisabled: _addingSourceLoading
				) {
					_isAddingPresenting = true
				}
			}
			.sheet(isPresented: $_isAddingPresenting) {
				SourcesAddView()
					.presentationDetents([.medium])
			}
			.alert("Sửa URL nguồn", isPresented: $_isEditPresenting) {
				TextField("URL nguồn", text: $_editingURL)
					.textInputAutocapitalization(.never)
					.autocorrectionDisabled()
				Button("Lưu") {
					if let source = _sourceToEdit, let newURL = URL(string: _editingURL.trimmingCharacters(in: .whitespacesAndNewlines)) {
						source.sourceURL = newURL
						Storage.shared.saveContext()
						Task {
							await viewModel.fetchSources(_sources, refresh: true)
						}
					}
				}
				Button("Hủy", role: .cancel) { }
			} message: {
				Text("Nhập địa chỉ URL mới cho kho nguồn:")
			}
			.refreshable {
				await viewModel.fetchSources(_sources, refresh: true)
			}
		}
		.task(id: Array(_sources)) {
			await viewModel.fetchSources(_sources)
		}
	}
}
