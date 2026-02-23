
//
//  InventoryCell 2.swift
//  zaico_ios_codingtest
//
//  Created by ryo hirota on 2025/03/11.
//

import UIKit

class InventoryImageCell: UITableViewCell {

    let label = UILabel()
    let itemImageView = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        label.translatesAutoresizingMaskIntoConstraints = false
        itemImageView.translatesAutoresizingMaskIntoConstraints = false
        itemImageView.contentMode = .scaleAspectFit

        contentView.addSubview(label)
        contentView.addSubview(itemImageView)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            itemImageView.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 16),
            itemImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            itemImageView.widthAnchor.constraint(equalToConstant: 100),
            itemImageView.heightAnchor.constraint(equalToConstant: 100)
        ])
    }

    func configure(leftText: String, rightImageURLString: String) {
        label.text = leftText

        guard let url = URL(string: rightImageURLString) else {
            itemImageView.image = nil
            return
        }

        DispatchQueue.global().async {
            if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.itemImageView.image = image
                }
            } else {
                DispatchQueue.main.async {
                    self.itemImageView.image = nil
                }
            }
        }
    }
}
