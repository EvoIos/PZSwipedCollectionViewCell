//
//  CustomWithoutNibCollectionViewCell.swift
//  Example
//
//  Created by zhenglanchun on 2017/7/22.
//  Copyright © 2017年 Pace.Z. All rights reserved.
//

import UIKit

class CustomWithoutNibCollectionViewCell: PZSwipedCollectionViewCell {
    
    var nameLabel:UILabel?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupView() {
        self.layer.borderColor = UIColor.black.cgColor
        self.layer.borderWidth = 0.5
        
        nameLabel = UILabel.init(frame: CGRect(x: 18, y: 0, width: 100, height: 50))
        nameLabel?.textColor = UIColor.black
        nameLabel?.font = UIFont.systemFont(ofSize: 15)
        nameLabel?.textAlignment = .left
        nameLabel?.backgroundColor = UIColor.white
        self.addSubview(nameLabel!)
        
        // set revealview
        let deleteButton = UIButton(frame: CGRect(x: self.bounds.height - 55, y: 0, width: 55, height: self.bounds.height))
        deleteButton.backgroundColor = UIColor.init(red: 255/255.0, green: 58/255.0, blue: 58/255.0, alpha: 1)
        deleteButton.setTitle("delete", for: .normal)
        deleteButton.setTitleColor(UIColor.white, for: .normal)
        deleteButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        deleteButton.addTarget(self, action: #selector(deleteSelf), for: .touchUpInside)
        self.revealView = deleteButton
    }
    
    @objc func deleteSelf() {
        self.hideRevealView(withAnimated: true)
        print("custom revealView delete")
    }
}
