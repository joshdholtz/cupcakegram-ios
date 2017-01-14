//
//  ViewControllerMakeVideo.swift
//  Transformers
//
//  Created by Josh Holtz on 8/3/16.
//  Copyright © 2016 RokkinCat. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

enum CroppedAsset {
	case image(image: UIImage)
	case video(url: URL)
	case none
}

class CropScrollView: UIScrollView {
	
	var image: UIImage? {
		didSet {
			zoomView = CropScrollView.setImageInScrollView(image, scrollView: self)
		}
	}
	
	var videoUrl: URL? {
		didSet {
			guard let url = videoUrl else {
				videoAsset = nil
				player?.pause()
				return
			}
			
			videoAsset = AVAsset(url: url)
		}
	}
	
	var videoRenderSize: CGSize? {
		didSet {
			guard let renderSize = videoRenderSize else {
				cropper = nil
				return
			}
			
			if let cropper = cropper {
				cropper.renderSize = renderSize
			} else {
				cropper = Crop(renderSize: renderSize)
			}
			
		}
	}
	
	var editLayersBeforeRender: Crop.EditLayers? {
		didSet {
			cropper?.editLayersBeforeRender = editLayersBeforeRender
		}
	}
	
	fileprivate var cropper: Crop? {
		didSet { setupCropper() }
	}
	fileprivate var exportSession: AVAssetExportSession?
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		setup()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		setup()
	}
	
	fileprivate func setup() {
		delegate = self
	}
	
	fileprivate func setupCropper() {
		guard let cropper = cropper else { return }
	
		cropper.makeTransform = { (rotationTransform: CGAffineTransform, orientation: UIImageOrientation, containerSize: CGSize, assetSize: CGSize, cropRect: CGRect) -> Crop.Transform in
			
			let scale =  assetSize.height / cropRect.height
			
			let normalizeScale = containerSize.height / assetSize.height
			
			let xCrop = -cropRect.origin.x
			let yCrop = -cropRect.origin.y
			
			let t = CGAffineTransform.identity
			
			let t2 = t.scaledBy(x: normalizeScale, y: normalizeScale)
			let t3 = t2.scaledBy(x: scale, y: scale)
			let t4 = t3.translatedBy(x: xCrop, y: yCrop)
			
			
			let tr = rotationTransform.concatenating(t4)
			
			return tr
		}
	}
	
	fileprivate var zoomView: UIView? {
		willSet {
			zoomView?.removeFromSuperview()
		}
	}

	var player: AVPlayer? {
		willSet {
			if let player = player {
				NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player.currentItem)
			}
			self.player = nil
			
			if let player = newValue {
				NotificationCenter.default.addObserver(self,
				                                                 selector: #selector(CropScrollView.restartVideoFromBeginning),
				                                                 name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
				                                                 object: player.currentItem)
			}
		}
	}
	
	fileprivate var videoAsset: AVAsset? {
		didSet {
			(zoomView, player) = CropScrollView.setVideoInScrollView(videoAsset, scrollView: self)
		}
	}
	
	@objc fileprivate func restartVideoFromBeginning()  {
		
		//create a CMTime for zero seconds so we can go back to the beginning
		let seconds : Int64 = 0
		let preferredTimeScale : Int32 = 1
		let seekTime : CMTime = CMTimeMake(seconds, preferredTimeScale)
		
		delay(0.1) { [weak self] in
			self?.player?.seek(to: seekTime)
			self?.player?.play()
		}
		
	}
	
	func crop(_ complete: @escaping (_ croppedAsset: CroppedAsset) -> ()) {
		
		exportSession?.cancelExport()
		guard let cropper = cropper else { return }
		
		let cropRect = CropScrollView.cropRectFromScrollView(self)
		
		switch (image, videoUrl) {
		case let (.some(image), nil):
			let image = Crop.crop(image, rect: cropRect)
			complete(.image(image: image))
		case let (nil, .some(videoUrl)):
			exportSession = cropper.cropSquareFromVideo(videoUrl, cropRect: cropRect) { (url) in
				complete(.video(url: url))
			}
		default:
			complete(.none)
			
		}
	}
}

extension CropScrollView: UIScrollViewDelegate {
	func viewForZooming(in scrollView: UIScrollView) -> UIView? {
		return zoomView
	}
}

extension CropScrollView {
	fileprivate class func cropRectFromScrollView(_ scrollView: UIScrollView) -> CGRect {
		let sizeOfSquare = scrollView.frame.size.width / scrollView.zoomScale
		
		let x = scrollView.contentOffset.x  / scrollView.zoomScale
		let y = scrollView.contentOffset.y  / scrollView.zoomScale
		
		return CGRect(x: x, y: y, width: sizeOfSquare, height: sizeOfSquare)
	}
	
	fileprivate class func setScrollContentView(_ view: UIView, scrollView: UIScrollView) {
		scrollView.contentSize.width = view.frame.size.width
		scrollView.contentSize.height = view.frame.size.height
		
		var minZoomScale: CGFloat = 1.0
		var maxZoomScale: CGFloat = 1.0
		
		if (view.frame.size.width > view.frame.size.height) {
			minZoomScale = scrollView.frame.size.height / view.frame.size.height
		} else {
			minZoomScale = scrollView.frame.size.width / view.frame.size.width
		}
		
		if (minZoomScale > 1.0) {
			maxZoomScale = minZoomScale
			minZoomScale = 1.0
		}
		
		maxZoomScale *= 3.0
		
		delay(0.15) {
			scrollView.minimumZoomScale = minZoomScale
			scrollView.maximumZoomScale = maxZoomScale
			delay(0.15) {
				scrollView.zoomScale = minZoomScale
				
				let offsetX = ( scrollView.contentSize.width / 2 ) - ( scrollView.bounds.size.width / 2 )
				let offsetY = ( scrollView.contentSize.height / 2 ) - ( scrollView.bounds.size.height / 2 )
				
				scrollView.contentOffset.x = max(0, offsetX)
				scrollView.contentOffset.y = max(0, offsetY)
				
				view.isHidden = false
				
				scrollView.setNeedsLayout()
				scrollView.layoutIfNeeded()
			}
		}
	}
	
}

extension CropScrollView {
	fileprivate class func setImageInScrollView(_ image: UIImage?, scrollView: UIScrollView?) -> UIImageView? {
		
		guard let image = image else { return nil }
		
		guard let scrollView = scrollView else { return nil }
		for view in scrollView.subviews { view.removeFromSuperview() }
		
		// Sets up scroll view stuff
		let imgCaptured = UIImageView(image: image)
		imgCaptured.frame.origin.x = 0
		imgCaptured.frame.origin.y = 0
		imgCaptured.isHidden = true
		scrollView.addSubview(imgCaptured)
		
		setScrollContentView(imgCaptured, scrollView: scrollView)
		
		return imgCaptured
	}
}

extension CropScrollView {
	
	fileprivate class func setVideoInScrollView(_ asset: AVAsset?, scrollView: UIScrollView?) -> (UIView?, AVPlayer?) {
		guard let scrollView = scrollView else { return (nil, nil) }
		
		guard let asset = asset else {
			return (nil, nil)
		}
		
		guard let size = asset.actualVideoSize else {
			assertionFailure("No size for asset")
			return (nil, nil)
		}
		
		let view = UIView()
		view.backgroundColor = UIColor.clear
		view.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
		
		let item = AVPlayerItem(asset: asset)
		
		let player = AVPlayer(playerItem: item)
		let playerLayer = AVPlayerLayer(player: player)
		
		playerLayer.frame = view.bounds
		view.layer.addSublayer(playerLayer)
		
		player.play()
		
		scrollView.addSubview(view)
		
		setScrollContentView(view, scrollView: scrollView)
		
		
		return (view, player)
	}
}

class Crop {
	
	typealias Transform = CGAffineTransform
	
	typealias MakeTransform = (_ rotationTransform: CGAffineTransform, _ orientation: UIImageOrientation, _ containerSize: CGSize, _ assetSize: CGSize, _ cropRect: CGRect) -> Transform
	typealias EditLayers = (_ parentLayer: CALayer, _ videoLayer: CALayer) -> Void
	
	var makeTransform: MakeTransform?
	var editLayersBeforeRender: EditLayers?
	var renderSize: CGSize
	
	init(renderSize: CGSize) {
		self.renderSize = renderSize
	}
	
	func cropSquareFromVideo(_ assetURL: URL, cropRect: CGRect, complete: @escaping (_ url: URL) -> ()) -> AVAssetExportSession? {
		let asset = AVURLAsset(url: assetURL)
		
		let start = CMTime(seconds: 0, preferredTimescale: 1)
		let duration = asset.duration
		
		return completeWithVideoAtURL(asset, rect: cropRect, timeRange: CMTimeRange(start: start, duration: duration), complete: complete)
	}
	
	fileprivate func completeWithVideoAtURL(_ asset: AVURLAsset, rect: CGRect, timeRange: CMTimeRange? = nil, complete: @escaping (_ url: URL) -> ()) -> AVAssetExportSession?
	{
		guard let outputPath = FileManager.default
			.urls(for: .documentDirectory, in: .userDomainMask)
			.first?.appendingPathComponent("square_video.mp4") else {
				
				assertionFailure("Could not find documents directory")
				return nil
		}
		
		let _ = try? FileManager.default.removeItem(at: outputPath)
		
		print("Output path: \(outputPath)")
		
		let output = outputPath
		
		let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPreset1280x720)!
		session.videoComposition = cropVideo(asset, rect: rect, timeRange: timeRange)
		session.outputURL = output
		session.outputFileType = AVFileTypeMPEG4
		session.shouldOptimizeForNetworkUse = true
		session.timeRange = timeRange ?? CMTimeRangeMake(kCMTimeZero, kCMTimePositiveInfinity)
		
		session.exportAsynchronously(completionHandler: { [weak session] () -> Void in
			guard let session = session else { return }
			
			switch session.status {
			case .failed:
				print("Export failed: \(session.error)")
			case .cancelled:
				print("Export cancelled")
			default: ()
			}
			
			
			DispatchQueue.main.async(execute: { () -> Void in
				print("Done?")
				complete(output)
			})
			})
		
		return session
	}
	
	fileprivate func cropVideo(_ asset: AVAsset, rect: CGRect, timeRange: CMTimeRange? = nil) -> AVVideoComposition? {
		
		// Doing video stuff
		guard let assetTrack = asset.tracks(withMediaType: AVMediaTypeVideo).first else {
			assertionFailure("Could not find an asset track")
			return nil
		}
		
		var rotationTransform = asset.preferredTransform
		
		let cropOffX: CGFloat = 0
		let cropOffY: CGFloat = 0
		
		let videoOrientation = getVideoOrientation(assetTrack)
		
		switch (videoOrientation) {
		case .up:
			rotationTransform = CGAffineTransform(translationX: assetTrack.naturalSize.height - cropOffX, y: 0 - cropOffY )
			rotationTransform = rotationTransform.rotated(by: CGFloat(M_PI_2) )
			break
		case .down:
			rotationTransform = CGAffineTransform(translationX: 0 - cropOffX, y: assetTrack.naturalSize.width - cropOffY ) // not fixed width is the real height in upside down
			rotationTransform = rotationTransform.rotated(by: CGFloat(-M_PI_2) )
			break
		case .right:
			rotationTransform = CGAffineTransform(translationX: 0 - cropOffX, y: 0 - cropOffY )
			rotationTransform = rotationTransform.rotated(by: 0 )
			break
		case .left:
			rotationTransform = CGAffineTransform(translationX: assetTrack.naturalSize.width - cropOffX, y: assetTrack.naturalSize.height - cropOffY )
			rotationTransform = rotationTransform.rotated(by: CGFloat(M_PI)  )
			break
		default:
			break
		}
		
		let assetSize = asset.tracks(withMediaType: AVMediaTypeVideo).first!.naturalSize
		let transform = makeTransform?(rotationTransform, videoOrientation, renderSize, assetSize, rect) ?? CGAffineTransform.identity
		
		let transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: assetTrack)
		transformer.setTransform(transform, at: kCMTimeZero)
		
		let instruction = AVMutableVideoCompositionInstruction()
		instruction.timeRange = CMTimeRangeMake(kCMTimeZero, kCMTimePositiveInfinity)
		instruction.layerInstructions = [transformer]
		
		let composition = AVMutableVideoComposition()	
		
		let parentLayer = CALayer()
		let videoLayer = CALayer()
		if let editLayersBeforeRender = editLayersBeforeRender {
			editLayersBeforeRender(parentLayer, videoLayer)
		} else {
			parentLayer.frame = CGRect(x: 0, y: 0, width: renderSize.width, height: renderSize.height)
			videoLayer.frame = CGRect(x: 0, y: 0, width: renderSize.width, height: renderSize.height)
			parentLayer.addSublayer(videoLayer)
		}
		
		composition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
		
		// Video stuff
		composition.frameDuration = CMTimeMake(1, 30)
		composition.renderSize = renderSize
		composition.instructions = [instruction]
		
		return composition
	}
	
	func imageWithColor(_ color: UIColor, rect: CGRect) -> UIImage? {
		UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
		color.setFill()
		UIRectFill(rect)   // Fill it with your color
		let image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
	 
		return image
	}
	
	func getVideoOrientation(_ assetTrack: AVAssetTrack) -> UIImageOrientation {
		let size = assetTrack.naturalSize
		let txf = assetTrack.preferredTransform
		
		if size.width == txf.tx && size.height == txf.ty {
			return .left
		} else if txf.tx == 0 && txf.ty == 0 {
			return .right
		} else if txf.tx == 0 && txf.ty == size.width {
			return .down
		} else {
			return .up
		}
	}
}

extension Crop {
	class func crop(_ image: UIImage, rect: CGRect) -> UIImage {
		
		UIGraphicsBeginImageContextWithOptions(rect.size,
		                                       /* opaque */ false,
		                                                    /* scaling factor */ 0.0)
		
		image.draw(at: CGPoint(x: -rect.origin.x, y: -rect.origin.y))
		
		let result = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		
		return result!
	}
}

extension UIImageOrientation {
	var xOriginOffsetFactor: CGFloat {
		switch self {
		case .left: return 0
		case .up: return 0
		default: return 1
		}
	}
	
	var yOriginOffsetFactor: CGFloat {
		switch self {
		case .left: return 0
		case .up: return 0
		default: return 1
		}
	}
}

extension AVAsset {
	var videoTrack: AVAssetTrack? {
		return tracks(withMediaType: AVMediaTypeVideo).first
	}
	
	var videoOrientation: UIImageOrientation? {
		guard let assetTrack = videoTrack else {
			return nil
		}
		
		let size = assetTrack.naturalSize
		let txf = assetTrack.preferredTransform
		
		if size.width == txf.tx && size.height == txf.ty {
			return .left
		} else if txf.tx == 0 && txf.ty == 0 {
			return .right
		} else if txf.tx == 0 && txf.ty == size.width {
			return .down
		} else {
			return .up
		}
	}
	
	var actualVideoSize: CGSize? {
		guard let assetTrack = videoTrack, let orientation = videoOrientation else {
			return nil
		}
		
		let size = assetTrack.naturalSize
		
		switch orientation {
		case .left, .right: return size
		case .up, .down: return CGSize(width: size.height, height: size.width)
		default: return nil
		}
	}
}
