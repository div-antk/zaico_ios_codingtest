//
//  CreateInventoryViewController.swift
//  zaico_ios_codingtest
//
//  Created by Takuya Ando on 2026/02/23.
//

import UIKit

final class CreateInventoryViewController: UIViewController, CreateInventoryView {
    
    // 作成成功を呼び出し元に通知して在庫一覧を更新させる
    var onCreated: (() -> Void)?

    private let titleField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "タイトル"
        tf.borderStyle = .roundedRect
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.clearButtonMode = .whileEditing
        return tf
    }()

    private let createButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("作成", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 16)
        button.isEnabled = false
        return button
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 13)
        return label
    }()

    private lazy var presenter = CreateInventoryPresenter(view: self)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "新規作成"

        // キャンセルボタン
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(didTapCancel)
        )

        createButton.addTarget(self, action: #selector(didTapCreate), for: .touchUpInside)
        titleField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)

        setupLayout()
    }

    private func setupLayout() {
        let stack = UIStackView(arrangedSubviews: [titleField, createButton, statusLabel])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }

    @objc private func textDidChange() {
        // 空タイトル送信を防ぐ
        let text = titleField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        createButton.isEnabled = !text.isEmpty
        // エラー表示後、入力が変わったらエラーメッセージを消す
        statusLabel.text = ""
    }

    func setCreateButtonEnabled(_ isEnabled: Bool) {
        createButton.isEnabled = isEnabled
    }

    func showStatus(_ message: String) {
        statusLabel.text = message
    }

    func dismissScreen() {
        // 一覧更新通知
        onCreated?()
        dismiss(animated: true)
    }

    @objc private func didTapCancel() {
        dismiss(animated: true)
    }

    @objc private func didTapCreate() {
        presenter.didTapCreate(title: titleField.text ?? "")
    }
}
