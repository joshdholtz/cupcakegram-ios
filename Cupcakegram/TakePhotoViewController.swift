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
	
	private let imgNoImage = UIImageView()
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
		view.backgroundColor = Colors.sprinkleBlue
		
		setupUI()
		subscribeUI()
		subscribeVariables()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		title = "Step 1: Take & Crop"
		image.value = nil
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		title = ""
		super.viewWillDisappear(animated)
	}
	
	private func setupUI() {
		// Add views
		view.addSubview(imgNoImage)
		view.addSubview(cropScrollView)
		view.addSubview(btnTakePhoto)
		view.addSubview(btnPhotoRoll)
		view.addSubview(btnNext)
		
		// No image image
		imgNoImage.image = #imageLiteral(resourceName: "no_image_image")
		imgNoImage.contentMode = .scaleAspectFit
		constrain(imgNoImage, view) { (view, parent) in
			view.top == parent.top
			view.left == parent.left
			view.right == parent.right
			view.height == view.width
		}
		
		// Crop scroll view
		cropScrollView.videoRenderSize = CGSize(width: 1000, height: 1000)
		cropScrollView.backgroundColor = UIColor.clear
		cropScrollView.bounces = false
		constrain(cropScrollView, view) { (view, parent) in
			view.top == parent.top
			view.left == parent.left
			view.right == parent.right
			view.height == view.width
		}
		
		// Take photo button
		btnTakePhoto.setTitle("Take Photo", for: .normal)
		btnTakePhoto.backgroundColor = Colors.wrapperTeal
		btnTakePhoto.titleLabel?.font = UIFont.systemFont(ofSize: 13)
		btnTakePhoto.setTitleColor(UIColor.white, for: .normal)
		btnTakePhoto.setTitleColor(UIColor.lightText, for: .highlighted)
		constrain(btnTakePhoto, cropScrollView, view) { (view, top, parent) in
			view.top == top.bottom
			view.left == parent.left
			view.right == parent.centerX
			view.height == 40
		}
		
		// Photo roll button
		btnPhotoRoll.setTitle("Photo Roll", for: .normal)
		btnPhotoRoll.backgroundColor = Colors.frostingPink
		btnPhotoRoll.titleLabel?.font = UIFont.systemFont(ofSize: 13)
		btnPhotoRoll.setTitleColor(UIColor.white, for: .normal)
		btnPhotoRoll.setTitleColor(UIColor.lightText, for: .highlighted)
		constrain(btnPhotoRoll, cropScrollView, view) { (view, top, parent) in
			view.top == top.bottom
			view.left == parent.centerX
			view.right == parent.right
			view.height == 40
		}
		
		// Next button
		btnNext.isHidden = true
		btnNext.setTitle("Next", for: .normal)
		btnNext.backgroundColor = Colors.sprinkleGreen
		btnNext.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
		btnNext.setTitleColor(UIColor.white, for: .normal)
		btnNext.setTitleColor(UIColor.lightText, for: .highlighted)
		constrain(btnNext, btnTakePhoto, view) { (view, top, parent) in
			view.top == top.bottom
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
			self?.cropScrollView.backgroundColor = image.isNil ? UIColor.clear : UIColor.white
			self?.btnNext.isHidden = image.isNil
			self?.imgNoImage.isHidden = image.isNonNil
		}).addDisposableTo(disposeBag)
	}
	
}
