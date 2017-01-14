//
//  UIImageExtensions.swift
//  Wantable
//
//  Created by Josh Holtz on 10/21/16.
//  Copyright © 2016 Wantable. All rights reserved.
//

import UIKit

extension UIImage {
	
	func fixImageOrientation() -> UIImage {
		
		if imageOrientation == UIImageOrientation.up {
			return self
		}
		
		var transform: CGAffineTransform = CGAffineTransform.identity
		
		switch imageOrientation {
		case UIImageOrientation.down, UIImageOrientation.downMirrored:
			transform = transform.translatedBy(x: size.width, y: size.height)
			transform = transform.rotated(by: CGFloat(M_PI))
			break
		case UIImageOrientation.left, UIImageOrientation.leftMirrored:
			transform = transform.translatedBy(x: size.width, y: 0)
			transform = transform.rotated(by: CGFloat(M_PI_2))
			break
		case UIImageOrientation.right, UIImageOrientation.rightMirrored:
			transform = transform.translatedBy(x: 0, y: size.height)
			transform = transform.rotated(by: CGFloat(-M_PI_2))
			break
		case UIImageOrientation.up, UIImageOrientation.upMirrored:
			break
		}
		
		switch imageOrientation {
		case UIImageOrientation.upMirrored, UIImageOrientation.downMirrored:
			transform.translatedBy(x: size.width, y: 0)
			transform.scaledBy(x: -1, y: 1)
			break
		case UIImageOrientation.leftMirrored, UIImageOrientation.rightMirrored:
			transform.translatedBy(x: size.height, y: 0)
			transform.scaledBy(x: -1, y: 1)
		case UIImageOrientation.up, UIImageOrientation.down, UIImageOrientation.left, UIImageOrientation.right:
			break
		}
		
		let ctx = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
		ctx.concatenate(transform)
		
		switch imageOrientation {
		case UIImageOrientation.left, UIImageOrientation.leftMirrored, UIImageOrientation.right, UIImageOrientation.rightMirrored:
			ctx.draw(cgImage!, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
			break
		default:
			ctx.draw(cgImage!, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
			break
		}
		
		let img: UIImage = UIImage(cgImage: ctx.makeImage()!)
		
		return img
	}
	
	func resize(newWidth: CGFloat) -> UIImage? {
		
		let scale = newWidth / self.size.width
		let newHeight = self.size.height * scale
		
		UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
		self.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
		
		let newImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		
		return newImage
	}
	
}
