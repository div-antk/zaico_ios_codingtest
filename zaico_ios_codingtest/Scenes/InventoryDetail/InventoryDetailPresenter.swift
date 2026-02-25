//
//  InventoryDetailPresenter.swift
//  zaico_ios_codingtest
//
//  Created by Takuya Ando on 2026/02/25.
//

import Foundation

protocol InventoryDetailView: AnyObject {
    func showInventory(_ inventory: Inventory)
    func showError(_ message: String)
}

protocol InventoryDetailServicing {
    func fetchInventory(id: Int) async throws -> Inventory
}

final class InventoryDetailService: InventoryDetailServicing {
    func fetchInventory(id: Int) async throws -> Inventory {
        try await APIClient.shared.fetchInventory(id: id)
    }
}

final class InventoryDetailPresenter {
    private weak var view: InventoryDetailView?
    private let service: InventoryDetailServicing
    private let inventoryId: Int

    init(
        view: InventoryDetailView,
        inventoryId: Int,
        service: InventoryDetailServicing = InventoryDetailService()
    ) {
        self.view = view
        self.inventoryId = inventoryId
        self.service = service
    }

    func viewDidLoad() {
        Task { await fetch() }
    }

    private func fetch() async {
        do {
            let data = try await service.fetchInventory(id: inventoryId)
            await MainActor.run {
                self.view?.showInventory(data)
            }
        } catch {
            await MainActor.run {
                self.view?.showError("\(error.localizedDescription)")
            }
        }
    }
}
