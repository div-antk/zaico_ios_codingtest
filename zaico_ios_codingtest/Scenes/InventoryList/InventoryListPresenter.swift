//
//  InventoryListPresenter.swift
//  zaico_ios_codingtest
//
//  Created by Takuya Ando on 2026/02/25.
//

import Foundation

protocol InventoryListView: AnyObject {
    func showInventories(_ inventories: [Inventory])
    func showError(_ message: String)
}

protocol InventoryListServicing {
    func fetchInventories() async throws -> [Inventory]
}

final class InventoryListService: InventoryListServicing {
    func fetchInventories() async throws -> [Inventory] {
        try await APIClient.shared.fetchInventories()
    }
}

final class InventoryListPresenter {
    private weak var view: InventoryListView?
    private let service: InventoryListServicing

    init(view: InventoryListView, service: InventoryListServicing = InventoryListService()) {
        self.view = view
        self.service = service
    }

    func viewDidLoad() {
        Task {
            await fetchAndUpdate()
        }
    }

    func didCreateInventory() {
        Task {
            await fetchAndUpdate()
        }
    }

    // 在庫一覧を取得してViewに反映する
    private func fetchAndUpdate() async {
        do {
            let data = try await service.fetchInventories()
            await MainActor.run {
                self.view?.showInventories(data)
            }
        } catch {
            await MainActor.run {
                self.view?.showError(error.localizedDescription)
            }
        }
    }
}
