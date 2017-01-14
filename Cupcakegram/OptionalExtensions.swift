//
//  OptionalExtensions.swift
//  SnapifeyePro
//
//  Created by Josh Holtz on 1/14/16.
//  Copyright © 2016 Snapifeye. All rights reserved.
//

import Foundation

extension Optional {
	var isNil: Bool {
		return self == nil
	}
	var isNonNil: Bool {
		return !isNil
	}
}