//
//  ViewModel.swift
//  AHPinterest
//
//  Created by Andy Hurricane on 3/26/17.
//  Copyright © 2017 AndyHurricane. All rights reserved.
//

import UIKit


class ViewModel: NSObject {
    var collectionView: UICollectionView
    var layout: AHLayout?
    weak var headerCell: AHCollectionRefreshHeader?
    var pinVMs: [PinViewModel]? {
        didSet {
            if let pinVMs = pinVMs {
                self.layoutHandler.pinVMs = pinVMs
            }
        }
    }
    var reusablePinCellID: String
    let animator: AHShareAnimator = AHShareAnimator()
    var modalVC: AHShareModalVC = AHShareModalVC()
    var layoutHandler: AHLayoutHandler = AHLayoutHandler()
    weak var mainVC: UIViewController?
    
    init(collectionView: UICollectionView, reusablePinCellID: String) {
        self.collectionView = collectionView
        self.reusablePinCellID = reusablePinCellID
        super.init()
        
        collectionView.contentInset = AHCollectionViewInset
        collectionView.register(AHCollectionRefreshHeader.self, forSupplementaryViewOfKind: AHCollectionRefreshHeaderKind, withReuseIdentifier: AHCollectionRefreshHeaderKind)
        collectionView.dataSource = self
        collectionView.delegate = self
        let layout = AHLayout()
        collectionView.setCollectionViewLayout(layout, animated: false)
        layout.delegate = layoutHandler
        
        collectionView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(longPressHandler(_:))))
    }
    
    func loadNewData(completion: @escaping (_ success: Bool)->Swift.Void) {
        AHNetowrkTool.tool.loadNewData { (pinVMs) in
            self.pinVMs = pinVMs
            self.collectionView.reloadData()
            completion(true)
        }
    }

    
}


// MARK:- Events
extension ViewModel {
    @objc fileprivate func longPressHandler(_ sender: UILongPressGestureRecognizer){
        switch sender.state {
        case .began:
            let pt = sender.location(in: collectionView)
            if let indexPath = collectionView.indexPathForItem(at: pt){
                guard let cell = collectionView.cellForItem(at: indexPath) else{
                    return
                }
                longPressAnimation(cell: cell as! PinCell, startingPoint: pt)
                
            }
        case .changed:
            let point = sender.location(in: modalVC.view)
            modalVC.changed(point: point)
        case .ended, .cancelled, .failed, .possible:
            let point = sender.location(in: modalVC.view)
            modalVC.ended(point: point)
        }
    }
    func longPressAnimation(cell: PinCell,startingPoint: CGPoint) {
        // either self.layer.masksToBounds = false or self.clipsToBounds = false will allow bgView goes out of bounds
        if !cell.isSelected {
            self.modalVC.transitioningDelegate = self.animator
            self.animator.delegate = self.modalVC
            self.animator.preparePresenting(fromView: cell)
            self.modalVC.startingPoint = collectionView.convert(startingPoint, to: self.modalVC.view)
            self.modalVC.modalPresentationStyle = .custom
            self.mainVC?.present(self.modalVC, animated: true, completion: nil)
        }
    }
}






extension ViewModel: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("didSelected")
        collectionView.deselectItem(at: indexPath, animated: false)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let headerCell = headerCell else {
            return
        }
        guard !headerCell.isSpinning else {
            return
        }
        
        let yOffset = scrollView.contentOffset.y
        let topInset = scrollView.contentInset.top
        // the following extra -10 is to make the refreshControl hide "faster"
        if yOffset < -topInset - 10 {
            headerCell.isHidden = false
            showingRefreshControl(yOffset: abs(yOffset), headerCell: headerCell)
        }else{
            headerCell.isHidden = true
        }
    }
    func showingRefreshControl(yOffset: CGFloat, headerCell: AHCollectionRefreshHeader) {
        guard yOffset >= 0.0 else {
            return
        }
        let ratio = yOffset / headerCell.bounds.height * 0.5
        if ratio <= 1.0 {
            headerCell.pulling(ratio: ratio)
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard let headerCell = headerCell else {
            return
        }
        guard !headerCell.isSpinning else {
            return
        }
        if headerCell.ratio >= AHHeaderShouldRefreshRatio {
            headerCell.refresh()
            UIView.animate(withDuration: 0.25) {
                scrollView.contentInset.top = headerCell.bounds.height
            }
        }
        
    }
}

extension ViewModel : UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let pinVMs = pinVMs else {
            return 0
        }
        return pinVMs.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    
        let PinCell = collectionView.dequeueReusableCell(withReuseIdentifier: reusablePinCellID, for: indexPath) as! PinCell
        
        guard let pinVM = pinVMs?[indexPath.item] else {
            fatalError("pinVM is nil!!")
        }
    
        PinCell.mainVC = mainVC
        PinCell.pinVM = pinVM
        return PinCell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: AHCollectionRefreshHeaderKind, withReuseIdentifier: AHCollectionRefreshHeaderKind, for: indexPath) as! AHCollectionRefreshHeader
        header.isHidden = true
        self.headerCell = header
        return header
    }
    
    
}







