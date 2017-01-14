//
//  UIImageViewExtensions.swift
//  Wantable
//
//  Created by Lyzzi Brooks on 11/7/16.
//  Copyright © 2016 Wantable. All rights reserved.
//

import UIKit
import DTPhotoViewerController

extension UIImageView {
	func enableFullScreen() {
		main {
			guard let viewController = UIApplication.topViewController() else {
				return
			}
			if let photoViewController = DTPhotoViewerController(referenceView: self, image: self.image) {
				viewController.present(photoViewController, animated: true, completion: nil)
			}

		}
	}
}
