//
//  ImagePickerExtensions.swift
//  SnapifeyePro
//
//  Created by Josh Holtz on 1/27/16.
//  Copyright © 2016 Snapifeye. All rights reserved.
//

import UIKit

import MobileCoreServices
import PhotosUI

private let photoType = kUTTypeImage as String
private let videoType = kUTTypeMovie as String

enum Media {
	case photo(image: UIImage)
	case video(mediaURL: NSURL)
	
	init?(object: AnyObject?, mediaType: MediaType? = nil) {
		switch object {
		case let object as UIImage where mediaType == .photo || mediaType == nil:
			self = .photo(image: object)
		case let object as NSURL where mediaType == .video || mediaType == nil:
			self = .video(mediaURL: object)
		default:
			return nil
		}
	}
}

enum MediaType: RawRepresentable {
	
	typealias RawValue = String
	
	case photo, video
	
	init?(rawValue: MediaType.RawValue) {
		switch rawValue {
		case photoType: self = .photo
		case videoType: self = .video
		default: return nil
		}
	}
	
	var rawValue: MediaType.RawValue {
		switch self {
		case .photo: return photoType
		case .video: return videoType
		}
	}
}

class ImagePicker: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
	
	let viewController: UIViewController
	let mediaPicked: (Media) -> ()
	
	init(viewController: UIViewController, mediaPicked: @escaping (Media) -> ()) {
		self.viewController = viewController
		self.mediaPicked = mediaPicked
	}
	
	func pickImage(sourceType: UIImagePickerControllerSourceType, frontFacing: Bool, mediaTypes: [MediaType]) {
		
        let picker = UIImagePickerController()
        picker.delegate = self
		picker.videoQuality = .typeHigh
		picker.mediaTypes = mediaTypes.map({$0.rawValue})
		
		if TARGET_OS_SIMULATOR != 0 {
			picker.sourceType = .photoLibrary
		} else {
			picker.sourceType = sourceType
			if case .camera = sourceType {
				picker.cameraDevice = frontFacing ? .front : .rear
			}
		}
		
        viewController.present(picker, animated: true, completion: nil)
	}
	
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
		// Get image
		let mediaTypeString = info[UIImagePickerControllerMediaType] as? String
		let image = info[UIImagePickerControllerOriginalImage] as? UIImage
		let mediaURL = info[UIImagePickerControllerMediaURL] as? NSURL
		
		// Checking media type because yolo
		guard let mediaType = MediaType(rawValue: mediaTypeString ?? "") else {
			assertionFailure("Could not get a valid media type")
			return
		}
		guard let media = Media(object: image ?? mediaURL, mediaType: mediaType) else {
			assertionFailure("Could not create a media")
			return
		}
		
		self.saveMediaIfNeeded(media: media, picker: picker)
		
		// Dismiss picker
        picker.dismiss(animated: true, completion: { () -> Void in
			self.mediaPicked(media)
        })
	}
	
	private func saveMediaIfNeeded(media: Media?, picker: UIImagePickerController) {
		guard let media = media, picker.sourceType == UIImagePickerControllerSourceType.camera else { return }
		
		switch media {
		case let .photo(image):
			UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
		case let .video(url):
			PHPhotoLibrary.shared().performChanges({ 
				PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url as URL)
			}, completionHandler: { (success, error) in
				if !success {
					assertionFailure("Failed to save video - \(error)")
				}
			})
		}
	}
}
