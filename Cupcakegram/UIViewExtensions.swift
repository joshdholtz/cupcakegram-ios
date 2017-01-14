//
//  UIViewExtensions.swift
//  Wantable
//
//  Created by Josh Holtz on 10/20/16.
//  Copyright © 2016 Wantable. All rights reserved.
//

import UIKit

extension UIView {
	func show(animated: Bool, show: Bool, duration: TimeInterval = 0.35, after: TimeInterval = 0.0, completion: (() -> Swift.Void)? = nil) {
		if !animated {
			isHidden = !show
			alpha = show ? 1 : 0
			completion?()
		} else {
			if show && alpha <= 0.1 {
				alpha = 0
				isHidden = false
			}
			UIView.animate(withDuration: duration, delay:after, options: [], animations: { [weak self] in
				self?.alpha = show ? 1 : 0
			}, completion: { [weak self] (_) in
				self?.isHidden = !show
				completion?()
			})
		}
	}
}
