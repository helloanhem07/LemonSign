//
//  Storage+Sources.swift
//  Feather
//
//  Created by samara on 12.04.2025.
//

import CoreData
import AltSourceKit

// MARK: - Class extension: Sources
extension Storage {
	/// Retrieve sources in an array, we don't normally need this in swiftUI but we have it for the copy sources action
	func getSources() -> [AltSource] {
		let request: NSFetchRequest<AltSource> = AltSource.fetchRequest()
		return (try? context.fetch(request)) ?? []
	}
	
	func addSource(
		_ url: URL,
		name: String? = "Unknown",
		identifier: String,
		iconURL: URL? = nil,
		deferSave: Bool = false,
		isBuiltIn: Bool = false,
		completion: @escaping (Error?) -> Void
	) {
		if sourceExists(identifier) {
			completion(nil)
			print("ignoring \(identifier)")
			return
		}
		
		let new = AltSource(context: context)
		new.name = name
		new.date = Date()
		new.identifier = identifier
		new.sourceURL = url
		new.iconURL = iconURL
		new.setValue(isBuiltIn, forKey: "isBuiltIn")
		
		do {
			if !deferSave {
				try context.save()
			}
			completion(nil)
		} catch {
			completion(error)
		}
	}
	
	func addSource(
		_ url: URL,
		repository: ASRepository,
		id: String = "",
		deferSave: Bool = false,
		isBuiltIn: Bool = false,
		completion: @escaping (Error?) -> Void
	) {
		addSource(
			url,
			name: repository.name,
			identifier: !id.isEmpty
						? id
						: (repository.id ?? url.absoluteString),
			iconURL: repository.currentIconURL,
			deferSave: deferSave,
			isBuiltIn: isBuiltIn,
			completion: completion
		)
	}

	func addSources(
		repos: [URL: ASRepository],
		completion: @escaping (Error?) -> Void
	) {
		for (url, repo) in repos {
			addSource(
				url,
				repository: repo,
				deferSave: true,
				completion: { error in
					if let error {
						completion(error)
					}
				}
			)
		}
		
        saveContext()
        completion(nil)
	}


	func cleanupOldSources() {
		let fetchRequest: NSFetchRequest<AltSource> = AltSource.fetchRequest()
		if let sources = try? context.fetch(fetchRequest) {
			for source in sources {
				let urlString = source.sourceURL?.absoluteString ?? ""
				let name = source.name ?? ""
				if urlString.contains("Nyasami/Ksign") || urlString.contains("Kasumi-dta/LemonSign") || name.contains("ĐÃ NGỪNG HỖ TRỢ") {
					context.delete(source)
				}
			}
			try? context.save()
		}
	}

	func addBuiltInSources() {
		cleanupOldSources()
		let builtInSourceURLs = [
			"https://fastsign.dev/repo.json",
			"https://fastsign.dev/repo.lite.altstore.json",
			"https://raw.githubusercontent.com/drphe/KhoIPA/main/upload/repo.favorite.json",
			"https://repository.apptesters.org",
			"https://raw.githubusercontent.com/drphe/KhoIPA/main/upload/repo.buildstore.json",
			"https://raw.githubusercontent.com/drphe/KhoIPA/main/upload/repo.thuthuatjb.json",
			"https://raw.githubusercontent.com/drphe/KhoIPA/main/upload/repo.game.json",
			"https://raw.githubusercontent.com/drphe/KhoIPA/main/upload/repo.game2.json",
			"https://raw.githubusercontent.com/drphe/KhoIPA/main/upload/repo.tiptip.json",
			"https://raw.githubusercontent.com/drphe/KhoIPA/main/upload/repo.unkeyapp.json",
			"https://stikdebug.xyz/index.json",
			"https://raw.githubusercontent.com/drphe/KhoIPA/main/upload/EpicGamesIPASource.json",
			"https://raw.githubusercontent.com/drphe/KhoIPA/main/upload/repo.cypwn.json",
			"https://raw.githubusercontent.com/drphe/KhoIPA/main/upload/repo.cypwn_ts.json",
			"https://alt.getutm.app",
			"https://quarksources.github.io/dist/quantumsource.min.json",
			"https://quarksources.github.io/dist/quantumsource%2B%2B.min.json",
			"https://community-apps.sidestore.io/sidecommunity.json",
			"https://driftywinds.github.io/AltStore/apps.json",
			"https://wuxu1.github.io/wuxu-complete-plus.json",
			"https://wuxu1.github.io/wuxu-complete.json",
			"https://raw.githubusercontent.com/WhySooooFurious/Ultimate-Sideloading-Guide/refs/heads/main/raw-files/app-repo.json",
			"https://raw.githubusercontent.com/Neoncat-OG/TrollStore-IPAs/main/apps_esign.json?moduleError=1",
			"https://cdn.dbservices.to/repo-jsons/2c61e8984f400fbe2c28d620494b9efee8621930.json",
			"https://cdn.dbservices.to/repo-jsons/0852d7254534240c8fa12f3ed082c44c0023ad08.json",
			"https://cdn.dbservices.to/repo-jsons/1ae857434ef5533ecf3a5ed64c3a8a7096dc3573.json",
			"https://repo.owo.network",
			"https://altstore.fouadraheb.com/",
			"https://raw.githubusercontent.com/yodaluca23/SpotC-AltStore-Repo/main/AltStore%20Repo.json",
			"https://apps.sidestore.io/",
			"https://raw.githubusercontent.com/royilkom-alt/EthSign/refs/heads/main/EthSign.json",
			"https://github.com/LiveContainer/LiveContainer/releases/download/1.0/apps.json"
		]
		
		for urlString in builtInSourceURLs {
			FR.handleSource(urlString, silent: true) { }
		}
	}

	func deleteSource(for source: AltSource) {
		context.delete(source)
		saveContext()
	}

	func sourceExists(_ identifier: String) -> Bool {
		let fetchRequest: NSFetchRequest<AltSource> = AltSource.fetchRequest()
		fetchRequest.predicate = NSPredicate(format: "identifier == %@", identifier)

		do {
			let count = try context.count(for: fetchRequest)
			return count > 0
		} catch {
			print("Error checking if repository exists: \(error)")
			return false
		}
	}
}
