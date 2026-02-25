//
//  CreateInventoryPresenter.swift
//  zaico_ios_codingtest
//
//  Created by Takuya Ando on 2026/02/25.
//

import Foundation

protocol CreateInventoryView: AnyObject {
    func setCreateButtonEnabled(_ isEnabled: Bool)
    func showStatus(_ message: String)
    func dismissScreen()
}

protocol CreateInventoryServicing {
    func createInventory(title: String) async throws
}

final class CreateInventoryService: CreateInventoryServicing {
    func createInventory(title: String) async throws {
        _ = try await APIClient.shared.createInventory(
            CreateInventoryRequest(title: title)
        )
    }
}

final class CreateInventoryPresenter {

    private weak var view: CreateInventoryView?
    private let service: CreateInventoryServicing

    init(
        view: CreateInventoryView,
        service: CreateInventoryServicing = CreateInventoryService()
    ) {
        self.view = view
        self.service = service
    }

    func didTapCreate(title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        view?.setCreateButtonEnabled(false)
        view?.showStatus("作成中…")

        Task {
            do {
                try await service.createInventory(title: trimmed)
                await MainActor.run {
                    self.view?.showStatus("作成しました")
                    self.view?.dismissScreen()
                }
            } catch {
                await MainActor.run {
                    self.view?.showStatus("作成に失敗しました: \(error.localizedDescription)")
                    self.view?.setCreateButtonEnabled(true)
                }
            }
        }
    }
}
