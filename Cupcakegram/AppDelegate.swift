//
//  AppDelegate.swift
//  Cupcakegram
//
//  Created by Josh Holtz on 1/13/17.
//  Copyright © 2017 RokkinCat. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?


	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		
		window = {
			let window = UIWindow(frame: UIScreen.main.bounds)
			window.makeKeyAndVisible()
			return window
		}()
		
		setupUI()
		
		return true
	}
	
	func setupUI() {
		guard let window = window else { return }
		
		let viewController = TakePhotoViewController()
		let rootViewController = UINavigationController(rootViewController: viewController)
		rootViewController.navigationBar.isTranslucent = false
		
		UINavigationBar.appearance().barTintColor = Colors.cherryRed
		UINavigationBar.appearance().tintColor = UIColor.white
		UINavigationBar.appearance().titleTextAttributes = [
			NSForegroundColorAttributeName: UIColor.white,
			NSFontAttributeName: UIFont.systemFont(ofSize: 14)
		]
		UIBarButtonItem.appearance().setTitleTextAttributes([
			NSForegroundColorAttributeName: UIColor.white,
			NSFontAttributeName: UIFont.systemFont(ofSize: 14)
		], for: .normal)
		
		window.rootViewController = rootViewController
	}

}

struct Colors {
	private static func rgb(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat) -> UIColor {
		return UIColor(red: red/255.0, green: green/255.0, blue: blue/255.0, alpha: 1.0)
	}
	
	static let cherryRed = rgb(241, 107, 98)
	static let wrapperTeal = rgb(114, 170, 157)
	static let frostingPink = rgb(224, 162, 173)
	static let sprinkleBlue = rgb(115, 151, 177)
	static let sprinkleGreen = rgb(143, 178, 112)
	static let lightGray = rgb(245, 245, 245)
}

func delay(_ delay:Double, closure:@escaping ()->()) {
	DispatchQueue.main.asyncAfter(
		deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}

func main(_ closure:@escaping ()->()) {
	DispatchQueue.main.async(execute: {
		closure()
	})
}

func assertMain() {
	assert(Thread.isMainThread, "Is not main thread")
}

func background(_ closure:@escaping ()->()) {
	DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async(execute: {
		closure()
	})
}
