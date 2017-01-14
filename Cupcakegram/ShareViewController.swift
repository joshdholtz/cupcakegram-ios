//
//  ShareViewController.swift
//  Cupcakegram
//
//  Created by Josh Holtz on 1/13/17.
//  Copyright © 2017 RokkinCat. All rights reserved.
//

import UIKit

import Photos

import Cartography
import PKHUD
import RxSwift
import RxCocoa

class ShareViewController: UIViewController {
	
	fileprivate let imageView = UIImageView()
	fileprivate let btnShare = UIButton()
	fileprivate let btnSave = UIButton()
	fileprivate let btnStartOver = UIButton()
	
	private var customPhotoAlbum: CustomPhotoAlbum? = nil
	
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
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		customPhotoAlbum = CustomPhotoAlbum()
	}
	
	private func setupUI() {
		// Add views
		view.addSubview(imageView)
		view.addSubview(btnShare)
		view.addSubview(btnSave)
		view.addSubview(btnStartOver)
		
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
			view.right == parent.centerX
			view.height == 40
		}
		
		// Save button
		btnSave.setTitle("Save", for: .normal)
		constrain(btnSave, imageView, view) { (view, top, parent) in
			view.top == top.bottom
			view.left == parent.centerX
			view.right == parent.right
			view.height == 40
		}
		
		// Start over button
		btnStartOver.setTitle("Start Over?", for: .normal)
		constrain(btnStartOver, btnShare, view) { (view, top, parent) in
			view.top == top.bottom
			view.left == parent.left
			view.right == parent.right
			view.height == 40
		}
	}
	
	private func subscribeUI() {
		btnSave.rx.controlEvent(.touchUpInside).subscribe(onNext: { [weak self] () in
			guard let strongSelf = self else { return }
			strongSelf.customPhotoAlbum?.save(image: strongSelf.image.value)
			
			// TODO: Make sure it was actually saved?
			HUD.flash(.labeledSuccess(title: "Saved :D", subtitle: nil), delay: 2)
		}).addDisposableTo(disposeBag)
		
		btnShare.rx.controlEvent(.touchUpInside).subscribe(onNext: { [weak self] () in
			guard let strongSelf = self else { return }
			
			// set up activity view controller
			let imageToShare = [ strongSelf.image.value ]
			let activityViewController = UIActivityViewController(activityItems: imageToShare, applicationActivities: nil)
			activityViewController.popoverPresentationController?.sourceView = strongSelf.view // so that iPads won't crash
			
			// exclude some activity types from the list (optional)
			activityViewController.excludedActivityTypes = [ UIActivityType.airDrop, UIActivityType.postToFacebook ]
			
			// present the view controller
			strongSelf.present(activityViewController, animated: true, completion: nil)
		}).addDisposableTo(disposeBag)
		
		btnStartOver.rx.controlEvent(.touchUpInside).subscribe(onNext: { [weak self] () in
			guard let strongSelf = self else { return }
			strongSelf.navigationController?.popToRootViewController(animated: true)
		}).addDisposableTo(disposeBag)
	}
	
	private func subscribeVariables() {
		image.asObservable().subscribe(onNext: { [weak self] (image) in
			self?.imageView.image = image
		}).addDisposableTo(disposeBag)
	}
	
}

private class CustomPhotoAlbum: NSObject {
	static let albumName = "Cupcakegram"
	static let sharedInstance = CustomPhotoAlbum()
	
	var assetCollection: PHAssetCollection!
	
	override init() {
		super.init()
		
		if let assetCollection = fetchAssetCollectionForAlbum() {
			self.assetCollection = assetCollection
			return
		}
		
		if PHPhotoLibrary.authorizationStatus() != PHAuthorizationStatus.authorized {
			PHPhotoLibrary.requestAuthorization({ (status: PHAuthorizationStatus) -> Void in
				()
			})
		}
		
		if PHPhotoLibrary.authorizationStatus() == PHAuthorizationStatus.authorized {
			self.createAlbum()
		} else {
			PHPhotoLibrary.requestAuthorization(requestAuthorizationHandler)
		}
	}
	
	func requestAuthorizationHandler(status: PHAuthorizationStatus) {
		if PHPhotoLibrary.authorizationStatus() == PHAuthorizationStatus.authorized {
			// ideally this ensures the creation of the photo album even if authorization wasn't prompted till after init was done
			print("trying again to create the album")
			self.createAlbum()
		} else {
			print("should really prompt the user to let them know it's failed")
		}
	}
	
	func createAlbum() {
		PHPhotoLibrary.shared().performChanges({
			PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: CustomPhotoAlbum.albumName)   // create an asset collection with the album name
		}) { success, error in
			if success {
				self.assetCollection = self.fetchAssetCollectionForAlbum()
			} else {
				print("error \(error)")
			}
		}
	}
	
	func fetchAssetCollectionForAlbum() -> PHAssetCollection? {
		let fetchOptions = PHFetchOptions()
		fetchOptions.predicate = NSPredicate(format: "title = %@", CustomPhotoAlbum.albumName)
		let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
		
		if let _: AnyObject = collection.firstObject {
			return collection.firstObject
		}
		return nil
	}
	
	func save(image: UIImage) {
		if assetCollection == nil {
			return                          // if there was an error upstream, skip the save
		}
		
		PHPhotoLibrary.shared().performChanges({
			let assetChangeRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
			let assetPlaceHolder = assetChangeRequest.placeholderForCreatedAsset
			let albumChangeRequest = PHAssetCollectionChangeRequest(for: self.assetCollection)
			let enumeration: NSArray = [assetPlaceHolder!]
			albumChangeRequest!.addAssets(enumeration)
			
		}, completionHandler: nil)
	}
}
