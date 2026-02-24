//
//  InventoryImageCell.swift
//  zaico_ios_codingtest
//
//  Created by ryo hirota on 2025/03/11.
//

import UIKit

class InventoryImageCell: UITableViewCell {

    let label = UILabel()
    let itemImageView = UIImageView()
    private let noImageLabel = UILabel()
    // 画像ビューの高さ制約を保持するプロパティ。画像あり/なしで constant を変更するため参照を保持
    private var imageHeightConstraint: NSLayoutConstraint?
    private var currentImageURL: URL?
    private var imageTask: URLSessionDataTask?

    // 左側タイトルラベルの設定（テキスト表示部分）
    private func configureLabel() {
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16)
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    // 右側画像ビューの設定（画像表示領域）
    private func configureImageView() {
        itemImageView.translatesAutoresizingMaskIntoConstraints = false
        itemImageView.contentMode = .scaleAspectFit
        itemImageView.clipsToBounds = true
        itemImageView.setContentHuggingPriority(.defaultLow, for: .vertical)
        itemImageView.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    // 画像が存在しない場合に表示するラベルの設定
    private func configureNoImageLabel() {
        noImageLabel.translatesAutoresizingMaskIntoConstraints = false
        noImageLabel.text = "画像がありません"
        noImageLabel.textColor = .secondaryLabel
        noImageLabel.font = .systemFont(ofSize: 16)
        noImageLabel.isHidden = true
    }

    private func addSubviews() {
        contentView.addSubview(label)
        contentView.addSubview(itemImageView)
        contentView.addSubview(noImageLabel)
    }

    // AutoLayout制約の設定（画像の高さは可変で切り替える）
    private func setupConstraints() {
        // 画像の高さ制約（画像あり:160 / 画像なし:0 に切り替えるため保持）
        let imgHeight = itemImageView.heightAnchor.constraint(equalToConstant: 160)
        self.imageHeightConstraint = imgHeight

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            label.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),

            itemImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            itemImageView.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 16),
            itemImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            imgHeight,
            itemImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),

            noImageLabel.leadingAnchor.constraint(equalTo: itemImageView.leadingAnchor),
            noImageLabel.trailingAnchor.constraint(lessThanOrEqualTo: itemImageView.trailingAnchor),
            noImageLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    private func setupUI() {
        configureLabel()
        configureImageView()
        configureNoImageLabel()
        addSubviews()
        setupConstraints()
    }

    // セル再利用時に呼ばれる初期化処理
    // 画像をクリアし、画像表示状態を「通常（高さ160）」に戻す
    private func resetImageState() {
        itemImageView.image = nil
        noImageLabel.isHidden = true
        // 通常時の高さに戻す（画像なし時は0にしてセルを縮める）
        imageHeightConstraint?.constant = 160
    }

    // 画像URLが空・不正、または読み込み失敗時の表示状態
    // 画像の高さを0にしてセルを縮め、「画像がありません」を表示する
    private func applyNoImageState() {
        noImageLabel.isHidden = false
        // 画像領域を潰してセルの高さを縮める
        imageHeightConstraint?.constant = 0
    }

    // 画像読み込み成功時の表示状態
    // 画像を表示し、高さを160に戻す
    private func applyLoadedImageState(_ image: UIImage) {
        itemImageView.image = image
        noImageLabel.isHidden = true
        imageHeightConstraint?.constant = 160
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageTask?.cancel()
        imageTask = nil
        currentImageURL = nil
        resetImageState()
    }

    func configure(leftText: String, rightImageURLString: String) {
        label.text = leftText

        // セルは再利用されるため、前回の表示状態を必ずリセットする
        resetImageState()

        // 再利用時に古いリクエストが残らないよう、進行中の通信をキャンセル
        imageTask?.cancel()
        imageTask = nil
        currentImageURL = nil

        guard let url = URL(string: rightImageURLString), !rightImageURLString.isEmpty else {
            // URLが無い場合は通信せず、即座に画像なし状態へ
            currentImageURL = nil
            imageTask?.cancel()
            imageTask = nil
            applyNoImageState()
            return
        }

        // 現在このセルが表示すべきURLを保持（再利用による取り違え防止）
        currentImageURL = url

        // URLSessionで非同期に画像データを取得する
        // 完了時に currentImageURL と一致するかを確認してからUIを更新する
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            // セルが解放されていれば何もしない
            guard let self else { return }

            // cancel() による終了は正常系なので無視する
            if let nsError = error as NSError?, nsError.code == NSURLErrorCancelled {
                return
            }

            // 非同期完了時点でセルが別データを表示中なら結果を破棄する
            guard self.currentImageURL == url else { return }

            let image = data.flatMap { UIImage(data: $0) }

            // UI更新はメインスレッドで行う
            DispatchQueue.main.async {
                // メインスレッドでも再チェック（タイミング差で入れ替わる可能性があるため）
                guard self.currentImageURL == url else { return }

                if let image {
                    self.applyLoadedImageState(image)
                } else {
                    // 読み込み失敗時は画像なし状態で表示
                    self.applyNoImageState()
                }
            }
        }
        imageTask = task
        task.resume()
    }
}
