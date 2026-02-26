//
//  InventoryListViewController.swift
//  zaico_ios_codingtest
//
//  Created by ryo hirota on 2025/03/11.
//

import UIKit

class InventoryListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, InventoryListView {
    private let tableView = UITableView()
    private let refreshControl = UIRefreshControl()
    private var inventories: [Inventory] = []
    private lazy var presenter = InventoryListPresenter(view: self)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "在庫一覧"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(didTapAdd)
        )
        
        setupTableView()
        
        presenter.viewDidLoad()
    }

    private func setupTableView() {
        view.addSubview(tableView)
        tableView.register(InventoryCell.self, forCellReuseIdentifier: "InventoryCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        refreshControl.addTarget(self, action: #selector(didPullToRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }

    func showInventories(_ inventories: [Inventory]) {
        // idの降順（新しいものが上に来る想定）で並び替え
        self.inventories = inventories.sorted { $0.id > $1.id }
        tableView.reloadData()
        refreshControl.endRefreshing()
    }

    func showError(_ message: String) {
        let alert = UIAlertController(
            title: "エラー",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
        refreshControl.endRefreshing()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return inventories.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "InventoryCell", for: indexPath) as! InventoryCell
        cell.configure(leftText: String(inventories[indexPath.row].id),
                       rightText: inventories[indexPath.row].title)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let detailVC = InventoryDetailViewController(id: inventories[indexPath.row].id)
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    // リストを引っ張って更新
    @objc private func didPullToRefresh() {
        presenter.viewDidLoad()
    }
    
    // ヘッダー右上の新規作成ボタン押下時の処理
    @objc private func didTapAdd() {
        let createVC = CreateInventoryViewController()
        
        // 作成完了時のコールバック
        // 作成成功時に一覧データを再取得して画面を更新する
        createVC.onCreated = { [weak self] in
            guard let self else { return }
            self.presenter.didCreateInventory()
        }

        // ナビゲーション付きでモーダル表示
        let nav = UINavigationController(rootViewController: createVC)
        nav.modalPresentationStyle = .formSheet
        present(nav, animated: true)
    }
}
