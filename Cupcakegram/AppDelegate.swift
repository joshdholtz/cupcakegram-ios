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
		
		window.rootViewController = rootViewController
	}

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
