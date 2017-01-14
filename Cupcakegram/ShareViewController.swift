//
//  ShareViewController.swift
//  Cupcakegram
//
//  Created by Josh Holtz on 1/13/17.
//  Copyright © 2017 RokkinCat. All rights reserved.
//

import UIKit

import Cartography
import RxSwift
import RxCocoa

class ShareViewController: UIViewController {
	
	fileprivate let imageView = UIImageView()
	fileprivate let btnShare = UIButton()
	
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
		view.addSubview(btnShare)
		
		// Crop scroll view
		imageView.isUserInteractionEnabled = true
		imageView.clipsToBounds = true
		constrain(imageView, view) { (view, parent) in
			view.top == parent.top + 64 // This is bad... why why why
			view.left == parent.left
			view.right == parent.right
			view.height == view.width
		}
		
		// Share button
		btnShare.setTitle("Share", for: .normal)
		constrain(btnShare, imageView, view) { (view, top, parent) in
			view.top == top.bottom
			view.left == parent.left
			view.right == parent.right
			view.height == 40
		}
	}
	
	private func subscribeUI() {
		btnShare.rx.controlEvent(.touchUpInside).subscribe(onNext: { [weak self] () in

		}).addDisposableTo(disposeBag)
	}
	
	private func subscribeVariables() {
		image.asObservable().subscribe(onNext: { [weak self] (image) in
			self?.imageView.image = image
		}).addDisposableTo(disposeBag)
	}
	
}
