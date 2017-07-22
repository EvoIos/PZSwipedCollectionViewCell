//
//  PZSwipedCollectionViewCell.swift
//  PZSwipedCollectionViewCell
//
//  Created by Pace.Z on 2017/7/18.
//  Copyright © 2017年 Pace.Z. All rights reserved.
//

import UIKit

fileprivate extension UIView {
    func superView<T>(of type: T.Type) -> T? {
        return superview as? T ?? superview.flatMap { $0.superView(of: T.self) }
    }
}

// MARK: -
fileprivate extension UICollectionView {
    struct AssociatedKeys {
        static var currentcell = "pz_currentCell"
    }
    var openingCell: PZSwipedCollectionViewCell? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.currentcell) as? PZSwipedCollectionViewCell
        }
        set {
            if let newValue = newValue {
                objc_setAssociatedObject(
                    self,
                    &AssociatedKeys.currentcell,
                    newValue as PZSwipedCollectionViewCell?,
                    .OBJC_ASSOCIATION_ASSIGN
                )
            }
        }
    }
}

// MARK: -
class PZSwipedCollectionViewCell: UICollectionViewCell,UIGestureRecognizerDelegate {
    
    typealias delete = (_ sender: UIButton) -> ()
    
    // MARK: - public
    var revealView: UIView?
    
    func hideRevealView(withAnimated isAnimated:Bool) {
        UIView.animate(withDuration: isAnimated ? 0.1 : 0 ,
                       delay: 0,
                       options: .curveEaseOut,
                       animations: {
                        self.snapShotView?.center = CGPoint(x: self.frame.width / 2, y: self.snapShotView!.center.y)
        }, completion: { (finished: Bool) in
            self.snapShotView?.removeFromSuperview()
            self.snapShotView = nil
            self.revealView?.removeFromSuperview()
        })
    }
    
    /// only when you use the default reveal, you can use this method
    var delete: delete?
    
    // MARK: - private
    private var panGesture:UIPanGestureRecognizer!
    fileprivate var snapShotView:UIView?
    
    // MARK: life cycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureGestureRecognizer()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureGestureRecognizer()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.snapShotView?.removeFromSuperview()
        self.snapShotView = nil
        self.revealView?.removeFromSuperview()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard let revealView = revealView else {
            return
        }
        revealView.frame = CGRect(origin: CGPoint(x: self.frame.width - revealView.frame.width, y: 0) , size: revealView.frame.size)
    }
    
    private func configureGestureRecognizer() {
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(pzPanAction(panGestureRecognizer:)))
        panGesture.delegate = self
        self.addGestureRecognizer(panGesture)
    }
    
    // MARK: - UIGestureRecognizerDelegate
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.isMember(of: UIPanGestureRecognizer.self) {
            let gesture:UIPanGestureRecognizer = gestureRecognizer as! UIPanGestureRecognizer
            let velocity = gesture.velocity(in: self)
            if fabs(velocity.x) > fabs(velocity.y) {
                return true
            }
        }
        return false
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return otherGestureRecognizer != self.superView(of: UICollectionView.self)
    }
    
    // MARK: - event response
    @objc private func pzPanAction(panGestureRecognizer: UIPanGestureRecognizer) {
        switch panGestureRecognizer.state {
        case .began:
            if  self.revealView == nil {
                self._createDefaultRevealView()
            }
            if  self.snapShotView == nil {
                self.snapShotView = self.snapshotView(afterScreenUpdates: false)
                if  self.snapShotView?.backgroundColor == UIColor.clear || self.snapShotView?.backgroundColor == nil {
                    self.snapShotView?.backgroundColor = UIColor.white
                }
            }
            guard let snapShotView = self.snapShotView else {
                return
            }
            self._closeOtherOpeningCell()
            self.addSubview(self.revealView!)
            self.addSubview(snapShotView)
        case .changed:
            let translationPoint = panGestureRecognizer.translation(in: self)
            var centerPoint = CGPoint(x: 0, y: self.snapShotView!.center.y)
            centerPoint.x = min( self.frame.width / 2, max(self.snapShotView!.center.x + translationPoint.x, self.frame.width/2 - self.revealView!.frame.width))
            panGestureRecognizer.setTranslation(CGPoint.zero, in: self)
            self.snapShotView!.center = centerPoint
        case .ended,
             .cancelled:
            let velocity = panGestureRecognizer.velocity(in: self)
            if  _bigThenRevealViewHalfWidth() || _shouldShowRevealView(forVelocity: velocity) {
                showRevealView(withAnimated: true)
            }
            if _lessThenRevealViewHalfWidth() || _shouldHideRevealView(forVelocity: velocity) {
                hideRevealView(withAnimated: true)
            }
        default: break
        }
    }
    
    private func _shouldHideRevealView(forVelocity velocity: CGPoint) -> Bool {
        guard let revealView = self.revealView else {
            return false
        }
        return fabs(velocity.x) > revealView.frame.width / 2 && velocity.x > 0
    }
    
    private func _shouldShowRevealView(forVelocity velocity: CGPoint) -> Bool {
        guard let revealView = self.revealView else {
            return false
        }
        return fabs(velocity.x) > revealView.frame.width / 2 && velocity.x < 0;
    }
    
    private func _bigThenRevealViewHalfWidth() -> Bool {
        guard let revealView = self.revealView,
            let snapShotView = self.snapShotView else {
                return false
        }
        return fabs(snapShotView.frame.width) >= revealView.frame.width / 2
    }
    
    private func _lessThenRevealViewHalfWidth() -> Bool {
        guard let revealView = self.revealView,
            let snapShotView = self.snapShotView else {
                return false
        }
        return fabs(snapShotView.frame.width) < revealView.frame.width / 2
    }
    
    private func _closeOtherOpeningCell() {
        guard let superCollectionView = self.superView(of: UICollectionView.self) else {
            return
        }
        if superCollectionView.openingCell != self {
            if  superCollectionView.openingCell != nil {
                superCollectionView.openingCell!.hideRevealView(withAnimated: true)
            }
            superCollectionView.openingCell = self
        }
    }
    
    private func _createDefaultRevealView() {
        let deleteButton = UIButton(frame: CGRect(x: self.bounds.height - 55, y: 0, width: 55, height: self.bounds.height))
        deleteButton.backgroundColor = UIColor.init(red: 255/255.0, green: 58/255.0, blue: 58/255.0, alpha: 1)
        deleteButton.setTitle("delete", for: .normal)
        deleteButton.setTitleColor(UIColor.white, for: .normal)
        deleteButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        deleteButton.addTarget(self, action: #selector(_deleteButtonTapped(sender:)), for: .touchUpInside)
        self.revealView = deleteButton
    }
    
    @objc private func _deleteButtonTapped(sender: UIButton) {
        self.hideRevealView(withAnimated: true)
        self.delete?(sender)
    }
    
    func showRevealView(withAnimated isAnimated:Bool) {
        UIView.animate(withDuration: isAnimated ? 0.1 : 0 ,
                       delay: 0,
                       options: .curveEaseOut,
                       animations: {
                        self.snapShotView?.center = CGPoint(x: self.frame.width / 2 - self.revealView!.frame.width , y: self.snapShotView!.center.y)
        }, completion: { (finished: Bool) in
            
        })
    }
}
