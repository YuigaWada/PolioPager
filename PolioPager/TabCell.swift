//
//  TabCell.swift
//  PolioPager
//
//  Created by Yuiga Wada on 2019/08/22.
//  Copyright © 2019 Yuiga Wada. All rights reserved.
//

import UIKit

// imageが優先される
public struct TabItem {
    var title: String?
    var image: UIImage?
    var font: UIFont
    var cellWidth: CGFloat?
    var backgroundColor: UIColor
    var normalColor: UIColor
    var highlightedColor: UIColor
    
    public init(title: String? = nil,
                image: UIImage? = nil,
                font: UIFont = .systemFont(ofSize: 15),
                cellWidth: CGFloat? = nil,
                backgroundColor: UIColor = .white,
                normalColor: UIColor = .black, // .red, //for debug.
                highlightedColor: UIColor = .black) {
        self.title = title
        self.image = image
        self.font = font
        self.cellWidth = cellWidth
        self.backgroundColor = backgroundColor
        self.normalColor = normalColor
        self.highlightedColor = highlightedColor
    }
}

public protocol TabCellDelegate {
    func moveTo(index: Int)
    var pageViewController: PageViewController { get set }
}

class TabCell: UICollectionViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    public var index: Int = 0
    public var delegate: TabCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        titleLabel.sizeToFit()
        imageView.contentMode = .scaleAspectFill
        
        setupGesture()
    }
    
    override func layoutSubviews() {
        backgroundColor = .clear
        super.layoutSubviews()
    }
    
    private func setupGesture() {
        let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(singleTap(_:)))
        
        addGestureRecognizer(singleTapGesture)
    }
    
    @objc func singleTap(_ gesture: UITapGestureRecognizer) {
        guard let delegate = delegate else { return }
        
        delegate.moveTo(index: index)
    }
}
