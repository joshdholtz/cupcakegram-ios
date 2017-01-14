//
//  OverlayView.h
//  Picter
//
//  Created by Josh Holtz on 7/27/13.
//  Copyright (c) 2013 Picter. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OverlayViewDelegate;

@interface OverlayView : UIView

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, assign) float currentRotation;
@property (nonatomic, assign) BOOL flipped;

@property (nonatomic, assign) id<OverlayViewDelegate> delegate;

- (id)initWithImage:(UIImage *)image inRect:(CGRect)rect;

+ (UIImage*)mergeImages:(NSArray*)overlayImages image:(UIImage*)image imgStill:(UIImageView*)imgStill;

@end

@protocol OverlayViewDelegate <NSObject>

- (void)overlayViewPan:(OverlayView*)overlayView;
- (void)overlayViewPanEnd:(OverlayView*)overlayView;
- (void)overlayViewPanEndOffView:(OverlayView*)overlayView;

@end
