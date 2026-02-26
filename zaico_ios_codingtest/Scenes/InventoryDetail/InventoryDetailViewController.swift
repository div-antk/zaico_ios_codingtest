//
//  InventoryDetailViewController.swift
//  zaico_ios_codingtest
//
//  Created by ryo hirota on 2025/03/11.
//

import UIKit

class InventoryDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, InventoryDetailView {
    
    private let inventoryId: Int
    private var inventory: Inventory?
    private let tableView = UITableView()
    private let cellTitles = ["在庫ID", "在庫画像", "物品名", "数量"]
    
    private lazy var presenter = InventoryDetailPresenter(
        view: self,
        inventoryId: inventoryId
    )
    
    // initメソッドでIDを渡す
    init(id: Int) {
        self.inventoryId = id
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "詳細情報"
        view.backgroundColor = .systemBackground
        
        setupTableView()
        
        presenter.viewDidLoad()
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.register(InventoryCell.self, forCellReuseIdentifier: "InventoryCell")
        tableView.register(InventoryImageCell.self, forCellReuseIdentifier: "InventoryImageCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        tableView.dataSource = self
        tableView.delegate = self
        
        // Auto Layoutの制約に基づいてセルの高さを自動計算させる
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
    
    func showInventory(_ inventory: Inventory) {
        self.inventory = inventory
        tableView.reloadData()
    }

    func showError(_ message: String) {
        let alert = UIAlertController(
            title: "エラー",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellTitles.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "InventoryCell", for: indexPath) as! InventoryCell
        switch indexPath.row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "InventoryCell", for: indexPath) as! InventoryCell
            cell.configure(leftText: cellTitles[indexPath.row],
                           rightText: String(inventory?.id ?? 0))
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "InventoryImageCell", for: indexPath) as! InventoryImageCell
            if let imageURL = inventory?.itemImage?.url {
                cell.configure(leftText: cellTitles[indexPath.row],
                               rightImageURLString: imageURL)
            } else {
                // URLが無い場合は空文字を渡して、セル側で「画像なし」状態に切り替える
                cell.configure(leftText: cellTitles[indexPath.row],
                               rightImageURLString: "")
            }
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "InventoryCell", for: indexPath) as! InventoryCell
            cell.configure(leftText: cellTitles[indexPath.row],
                           rightText: inventory?.title ?? "")
            return cell
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: "InventoryCell", for: indexPath) as! InventoryCell
            var quantity = "0"
            if let q = inventory?.quantity {
                quantity = String(q)
            }
            cell.configure(leftText: cellTitles[indexPath.row],
                           rightText: quantity)
            return cell
        default:
            break
        }
        
        return cell
    }
    
}
