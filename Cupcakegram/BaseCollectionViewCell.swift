//
//  BaseCollectionViewCell.swift
//  Wantable
//
//  Created by Josh Holtz on 10/24/16.
//  Copyright © 2016 Wantable. All rights reserved.
//

import UIKit

class BaseCollectionViewCell: UICollectionViewCell {
	
	// Easy registration of cells
	class var reuseID: String { return NSStringFromClass(self) }
	static func register(withCollectionView: UICollectionView) {
		withCollectionView.register(self, forCellWithReuseIdentifier: self.reuseID)
	}
	
}
