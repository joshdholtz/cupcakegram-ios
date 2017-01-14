//
//  EditPhotoViewController.swift
//  Cupcakegram
//
//  Created by Josh Holtz on 1/13/17.
//  Copyright © 2017 RokkinCat. All rights reserved.
//

import UIKit

import Cartography
import RxSwift
import RxCocoa

class EditPhotoViewController: UIViewController {
	
	fileprivate let overlayImages = [
		#imageLiteral(resourceName: "trex"), #imageLiteral(resourceName: "longneck")
	]
	
	fileprivate let imageView = UIImageView()
	fileprivate lazy var collectionView: UICollectionView = {
		let layout = UICollectionViewFlowLayout()
		layout.scrollDirection = .horizontal
		layout.estimatedItemSize = CGSize(width: 100, height: 100)
		
		let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
		return collectionView
	}()
	fileprivate let btnNext = UIButton()
	
	fileprivate var overlays = [OverlayView]()
	
	// RxSwift
	private let disposeBag = DisposeBag()
	private let image: Variable<UIImage>
	
	required init(image: UIImage) {
		self.image = Variable(image)
		super.init(nibName: nil, bundle: nil)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = UIColor.orange
		
		setupUI()
		subscribeUI()
		subscribeVariables()
	}
	
	private func setupUI() {
		// Add views
		view.addSubview(imageView)
		view.addSubview(collectionView)
		view.addSubview(btnNext)
		
		// Crop scroll view
		imageView.isUserInteractionEnabled = true
		imageView.clipsToBounds = true
		constrain(imageView, view) { (view, parent) in
			view.top == parent.top + 64 // This is bad... why why why
			view.left == parent.left
			view.right == parent.right
			view.height == view.width
		}
		
		// Collection view
		OverlayCell.register(withCollectionView: collectionView)
		collectionView.dataSource = self
		collectionView.delegate = self
		collectionView.allowsSelection = true
		collectionView.bounces = true
		constrain(collectionView, imageView, view) { (view, top, parent) in
			view.top == top.bottom
			view.left == parent.left
			view.right == parent.right
			view.height == 110
		}
		
		// Next button
		btnNext.setTitle("Next", for: .normal)
		constrain(btnNext, collectionView, view) { (view, top, parent) in
			view.top == top.bottom
			view.left == parent.left
			view.right == parent.right
			view.height == 40
		}
	}
	
	private func subscribeUI() {
		btnNext.rx.controlEvent(.touchUpInside).subscribe(onNext: { [weak self] () in
			guard let strongSelf = self else { return }
			
			guard let mergedImage = OverlayView.mergeImages(strongSelf.overlays, image: strongSelf.image.value, imgStill: strongSelf.imageView) else {
				return
			}
			
			let viewController = ShareViewController(image: mergedImage)
			strongSelf.navigationController?.pushViewController(viewController, animated: true)
			
		}).addDisposableTo(disposeBag)
	}
	
	private func subscribeVariables() {
		image.asObservable().subscribe(onNext: { [weak self] (image) in
			self?.imageView.image = image
		}).addDisposableTo(disposeBag)
	}
	
}

extension EditPhotoViewController: OverlayViewDelegate {
	func overlayViewPan(_ overlayView: OverlayView!) {
		
	}
	
	func overlayViewPanEnd(_ overlayView: OverlayView!) {
		
	}
	
	func overlayViewPanEndOffView(_ overlayView: OverlayView!) {
		overlayView.removeFromSuperview()
		overlays = overlays.filter({ $0 != overlayView })
	}
}

extension EditPhotoViewController: UICollectionViewDataSource {
	func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 1
	}
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return overlayImages.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OverlayCell.reuseID, for: indexPath) as? OverlayCell else {
			fatalError("No cell, bruh")
		}
		
		cell.image.value = overlayImages[indexPath.row]
		
		return cell
	}
}

extension EditPhotoViewController: UICollectionViewDelegate {
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		let image = overlayImages[indexPath.row]
		
		guard let overlay = OverlayView(image: image, in: imageView.frame) else {
			return
		}
		overlay.delegate = self
		
		overlays.append(overlay)
		imageView.addSubview(overlay)
	}
}

private class OverlayCell: BaseCollectionViewCell {
		
	// RxSwift
	let image = Variable<UIImage?>(nil)
	private let disposeBag = DisposeBag()
	
	private let imageView = UIImageView()
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		setupUI()
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	func setupUI() {
		
		// View
		contentView.addSubview(imageView)
		
		// Image
		imageView.contentMode = .scaleAspectFit
		constrain(imageView, contentView) { (view, parent) in
			view.edges == parent.edges
			view.width == 100
			view.height == view.width
		}
		
		// Rx the things
		subscribeUIEvents()
		subscribeViewModelEvents()
	}
	
	private func subscribeUIEvents() {
		
	}
	
	private func subscribeViewModelEvents() {
		image.asObservable().subscribe(onNext: { [weak self] (image) in
			self?.imageView.image = image
		}).addDisposableTo(disposeBag)
	}
}
