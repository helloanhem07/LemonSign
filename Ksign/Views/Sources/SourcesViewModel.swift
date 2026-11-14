//
//  SourcesViewModel.swift
//  MSign
//
//  Created by samara on 30.04.2025.
//  Updated for MSign with Cron Health-Check on 14.11.2026.
//

import Foundation
import AltSourceKit
import SwiftUI
import NimbleJSON

// MARK: - Class
final class SourcesViewModel: ObservableObject {
	static let shared = SourcesViewModel()
	
	typealias RepositoryDataHandler = Result<ASRepository, Error>
	
	private let _dataService = NBFetchService()
	private var _cronTimer: Timer?
	
	var isFinished = true
	@Published var sources: [AltSource: ASRepository] = [:]
	@Published var failedSourceURLs: Set<String> = []
	
	init() {
		_startCronHealthCheck()
	}
	
	deinit {
		_cronTimer?.invalidate()
	}
	
	/// Starts background periodic cron to health-check repositories every 10 minutes
	private func _startCronHealthCheck() {
		_cronTimer = Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { [weak self] _ in
			Task { @MainActor [weak self] in
				guard let self = self, self.isFinished else { return }
				let allSources = Storage.shared.getSources()
				await self._validateSourcesHealth(allSources)
			}
		}
	}
	
	private func _validateSourcesHealth(_ sources: [AltSource]) async {
		for source in sources {
			guard let url = source.sourceURL else { continue }
			var request = URLRequest(url: url)
			request.httpMethod = "HEAD"
			request.timeoutInterval = 8
			
			do {
				let (_, response) = try await URLSession.shared.data(for: request)
				if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
					await MainActor.run {
						self.failedSourceURLs.remove(url.absoluteString)
					}
				} else {
					await MainActor.run {
						self.failedSourceURLs.insert(url.absoluteString)
					}
				}
			} catch {
				await MainActor.run {
					self.failedSourceURLs.insert(url.absoluteString)
				}
			}
		}
	}
	
	func fetchSources(_ sources: FetchedResults<AltSource>, refresh: Bool = false, batchSize: Int = 4) async {
		guard isFinished else { return }
		
		// check if sources to be fetched are the same as before, if yes, return
		// also skip check if refresh is true
		if !refresh, sources.allSatisfy({ self.sources[$0] != nil }) { return }
		
		// isfinished is used to prevent multiple fetches at the same time
		isFinished = false
		defer { isFinished = true }
		
		await MainActor.run {
			self.sources = [:]
		}
		
		let sourcesArray = Array(sources)
		
		for startIndex in stride(from: 0, to: sourcesArray.count, by: batchSize) {
			let endIndex = min(startIndex + batchSize, sourcesArray.count)
			let batch = sourcesArray[startIndex..<endIndex]
			
			let batchResults = await withTaskGroup(of: (AltSource, ASRepository?, Bool).self, returning: [AltSource: ASRepository].self) { group in
				for source in batch {
					group.addTask {
						guard let url = source.sourceURL else {
							return (source, nil, true)
						}
						
						return await withCheckedContinuation { continuation in
							self._dataService.fetch(from: url) { (result: RepositoryDataHandler) in
								switch result {
								case .success(let repo):
									continuation.resume(returning: (source, repo, false))
								case .failure(_):
									continuation.resume(returning: (source, nil, true))
								}
							}
						}
					}
				}
				
				var results = [AltSource: ASRepository]()
				for await (source, repo, isFailed) in group {
					let urlStr = source.sourceURL?.absoluteString ?? ""
					if isFailed || repo == nil {
						Task { @MainActor in
							self.failedSourceURLs.insert(urlStr)
						}
					} else if let repo {
						results[source] = repo
						Task { @MainActor in
							self.failedSourceURLs.remove(urlStr)
						}
					}
				}
				return results
			}
			
			await MainActor.run {
				for (source, repo) in batchResults {
					self.sources[source] = repo
				}
			}
		}
	}
}
