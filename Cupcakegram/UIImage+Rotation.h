//
//  UIImage+Rotation.h
//  Dinogram
//
//  Created by Josh Holtz on 2/14/13.
//  Copyright (c) 2013 RokkinCat. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Rotation)

- (UIImage *)imageRotatedByDegrees:(CGFloat)degrees;
- (UIImage *)fixOrientation:(UIImageOrientation)orientation;

@end
