//
//  TakePhotoViewController.swift
//  Cupcakegram
//
//  Created by Josh Holtz on 1/13/17.
//  Copyright © 2017 RokkinCat. All rights reserved.
//

import UIKit

import Cartography
import PKHUD
import RxSwift
import RxCocoa

class TakePhotoViewController: UIViewController {
	
	private let cropScrollView = CropScrollView()
	private let btnTakePhoto = UIButton()
	private let btnPhotoRoll = UIButton()
	private let btnNext = UIButton()
	
	// RxSwift
	private let disposeBag = DisposeBag()
	private let image = Variable<UIImage?>(nil)
	
	private lazy var imagePicker: ImagePicker = { [unowned self] in
		return ImagePicker(viewController: self, mediaPicked: { [weak self] media in
			if case let .photo(photo) = media {
				self?.image.value = photo
			} else {
				self?.image.value = nil
			}
		})
	}()
	
	required init() {
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
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		image.value = nil
	}
	
	private func setupUI() {
		// Add views
		view.addSubview(cropScrollView)
		view.addSubview(btnTakePhoto)
		view.addSubview(btnPhotoRoll)
		view.addSubview(btnNext)
		
		// Crop scroll view
		cropScrollView.videoRenderSize = CGSize(width: 1000, height: 1000)
		cropScrollView.backgroundColor = UIColor.blue
		constrain(cropScrollView, view) { (view, parent) in
			view.top == parent.top + 64 // This is bad... why why why
			view.left == parent.left
			view.right == parent.right
			view.height == view.width
		}
		
		// Take photo button
		btnTakePhoto.setTitle("Take Photo", for: .normal)
		constrain(btnTakePhoto, cropScrollView, view) { (view, top, parent) in
			view.top == top.bottom + 10
			view.left == parent.left
			view.right == parent.centerX
			view.height == 40
		}
		
		// Photo roll button
		btnPhotoRoll.setTitle("Photo Roll", for: .normal)
		constrain(btnPhotoRoll, cropScrollView, view) { (view, top, parent) in
			view.top == top.bottom + 10
			view.left == parent.centerX
			view.right == parent.right
			view.height == 40
		}
		
		// Next button
		btnNext.isHidden = true
		btnNext.setTitle("Next", for: .normal)
		constrain(btnNext, btnTakePhoto, view) { (view, top, parent) in
			view.top == top.bottom + 10
			view.left == parent.left
			view.right == parent.right
			view.height == 40
		}
	}
	
	private func subscribeUI() {
		btnTakePhoto.rx.controlEvent(.touchUpInside).subscribe(onNext: { [weak self] () in
			self?.imagePicker.pickImage(sourceType: .camera, frontFacing: true, mediaTypes: [.photo])
		}).addDisposableTo(disposeBag)
		
		btnPhotoRoll.rx.controlEvent(.touchUpInside).subscribe(onNext: { [weak self] () in
			self?.imagePicker.pickImage(sourceType: .photoLibrary, frontFacing: false, mediaTypes: [.photo])
		}).addDisposableTo(disposeBag)
		
		btnNext.rx.controlEvent(.touchUpInside).subscribe(onNext: { [weak self] () in
			
			HUD.show(.labeledProgress(title: "Cropping :)", subtitle: nil))
			
			self?.cropScrollView.crop({ [weak self] (croppedAsset) in
				HUD.hide()
				if case let .image(image) = croppedAsset {
					let viewController = EditPhotoViewController(image: image)
					self?.navigationController?.pushViewController(viewController, animated: true)
				} else {
					HUD.flash(.labeledError(title: "Could not crop :(", subtitle: nil), delay: 2)
				}
			})
		}).addDisposableTo(disposeBag)
	}
	
	private func subscribeVariables() {
		image.asObservable().subscribe(onNext: { [weak self] (image) in
			self?.cropScrollView.image = image
			self?.btnNext.isHidden = image.isNil
		}).addDisposableTo(disposeBag)
	}
	
}
