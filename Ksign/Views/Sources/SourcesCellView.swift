//
//  SourcesCellView.swift
//  MSign
//
//  Created by samara on 1.05.2025.
//  Refactored for MSign on 14.11.2026.
//

import SwiftUI
import NimbleViews
import NukeUI
import AltSourceKit

// MARK: - View
struct SourcesCellView: View {
	var source: AltSource
	
	// MARK: Body
	var body: some View {
		FRIconCellView(
			title: source.name ?? .localized("Unknown"),
			subtitle: source.sourceURL?.absoluteString ?? "",
			iconUrl: source.iconURL
		)
	}
}
