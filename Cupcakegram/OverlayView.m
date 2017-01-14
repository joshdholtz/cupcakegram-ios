//
//  OverlayView.m
//  Picter
//
//  Created by Josh Holtz on 7/27/13.
//  Copyright (c) 2013 Picter. All rights reserved.
//

#define RADIANS_TO_DEGREES(radians) ((radians) * (180.0 / M_PI))

#import "OverlayView.h"
#import "UIImage+Rotation.h"

@interface OverlayView()<UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIButton *overlayButton;
@property (nonatomic, strong) UIView *viewTouchGuy;

@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;

@property (nonatomic, strong) UIPinchGestureRecognizer *pinchGestureRecognizer;
@property (nonatomic, assign) CGPoint pointTouched;

@property (nonatomic, strong) UIRotationGestureRecognizer *rotationGestureRecognizer;
@property (nonatomic, assign) float mCurrentScale;
@property (nonatomic, assign) float mLastScale;
@property (nonatomic, assign) float lastRotation;

@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;

@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGestureRecognizer;

@end

@implementation OverlayView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        //        [self setup:nil];
    }
    return self;
}

- (id)initWithImage:(UIImage *)image inRect:(CGRect)rect {
    self = [super init];
    if (self) {
        [self setup:image rect:rect];
    }
    return self;
}

- (void)setup:(UIImage*)image rect:(CGRect)rect {
    _image = image;
    
    [self setBackgroundColor:[UIColor clearColor]];
    
    float newWidth = 0;
    float newHeight = 0;
    if (image.size.width > image.size.height) {
        newWidth = rect.size.width*0.8;
        newHeight = (image.size.height / image.size.width) * newWidth;
    } else {
        newHeight = rect.size.height*0.8;
        newWidth = (image.size.width / image.size.height) * newHeight;
    }
    
    [self setFrame:CGRectMake(0, 0, newWidth, newHeight)];
    
    _overlayButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_overlayButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [_overlayButton setClipsToBounds:YES];
    [_overlayButton setFrame:CGRectMake(0, 0, newWidth, newHeight)];
    
    [_overlayButton setImage:_image forState:UIControlStateNormal];
    [self addSubview:_overlayButton];
    
    _viewTouchGuy = [[UIView alloc] initWithFrame:self.frame];
    [_viewTouchGuy setBackgroundColor:[UIColor clearColor]];
    [self addSubview:_viewTouchGuy];
    
    //    [self.imageView setContentMode:UIViewContentModeScaleAspectFit];
    //    [self setClipsToBounds:YES];
    
    //    [self setImage:image forState:UIControlStateNormal];
    
    _viewTouchGuy.userInteractionEnabled = YES;
    self.userInteractionEnabled = YES;
    
    // Pan Gesture
    self.panGestureRecognizer = [[UIPanGestureRecognizer alloc]
                                 initWithTarget:self
                                 action:@selector(handlePan:)];
    [self addGestureRecognizer:self.panGestureRecognizer];
    
    _rotationGestureRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotate:)];
    [_rotationGestureRecognizer setDelegate:self];
    [_viewTouchGuy addGestureRecognizer:_rotationGestureRecognizer];
    
    // Pinch Gesture
    _pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    [_pinchGestureRecognizer setDelegate:self];
    [_viewTouchGuy addGestureRecognizer:_pinchGestureRecognizer];
    
    // Tap Gesture
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [_tapGestureRecognizer setDelegate: self];
    [_tapGestureRecognizer setNumberOfTapsRequired:2];
    [_viewTouchGuy addGestureRecognizer:_tapGestureRecognizer];
    
    // Long Press Gesture
    
    _longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [_longPressGestureRecognizer setMinimumPressDuration:1.0f];
    [_viewTouchGuy addGestureRecognizer:_longPressGestureRecognizer];
    
}

- (void)handlePan:(UIPanGestureRecognizer*)pgr {
	
    if (pgr.state == UIGestureRecognizerStateChanged) {
        CGPoint center = pgr.view.center;
        CGPoint translation = [pgr translationInView:pgr.view.superview];
        center = CGPointMake(center.x + translation.x,
                             center.y + translation.y);
        pgr.view.center = center;
        [pgr setTranslation:CGPointZero inView:pgr.view.superview];
        
        CGPoint topLeft = pgr.view.frame.origin;
        topLeft = CGPointMake(topLeft.x + translation.x,
                              topLeft.y + translation.y);
        
        if (topLeft.y >= CGRectGetHeight(pgr.view.superview.frame)) {
            if ([_delegate respondsToSelector:@selector(overlayViewPan:)]) {
                [_delegate overlayViewPan:self];
            }
        } else {
            if ([_delegate respondsToSelector:@selector(overlayViewPanEnd:)]) {
                [_delegate overlayViewPan:self];
            }
        }
        
    } else if (pgr.state == UIGestureRecognizerStateEnded) {
        
        if (self.frame.origin.y >= CGRectGetHeight(self.superview.frame)) {
            if ([_delegate respondsToSelector:@selector(overlayViewPanEndOffView:)]) {
                [_delegate overlayViewPanEndOffView:self];
            }
        } else {
            if ([_delegate respondsToSelector:@selector(overlayViewPanEnd:)]) {
                [_delegate overlayViewPanEnd:self];
            }
        }
    }
    
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    
    return YES;
}

-(void)handleTap:(UITapGestureRecognizer*)sender {
    _flipped = !_flipped;
    
    CGAffineTransform transform = _overlayButton.transform;
    transform = CGAffineTransformScale(transform, -1, 1);
    [_overlayButton setTransform:transform];
}

-(void)handleLongPress:(UILongPressGestureRecognizer*)sender {
    [self.superview bringSubviewToFront:self];
}

-(void)handlePinch:(UIPinchGestureRecognizer*)sender {
	
    CGFloat scale = sender.scale;
    self.transform = CGAffineTransformScale(self.transform, scale, scale);
    _mCurrentScale = scale;
    sender.scale = 1.0;
}

- (void)handleRotate:(UIRotationGestureRecognizer*)sender {
    if([(UIRotationGestureRecognizer*)sender state] == UIGestureRecognizerStateEnded) {
        //        if (_flipped == YES) {
        //            _lastRotation = -_lastRotation;
        //        }
        
        _currentRotation = _currentRotation + _lastRotation;
        
        _lastRotation = 0.0;
        return;
    }
    
    float theRotaton = [(UIRotationGestureRecognizer*)sender rotation];
    //    if (_flipped == YES) {
    //        theRotaton = -theRotaton;
    //    }
    
    CGFloat rotation = 0.0 - (_lastRotation - theRotaton);
    
    CGAffineTransform currentTransform = self.transform;
    CGAffineTransform newTransform = CGAffineTransformRotate(currentTransform,rotation);
    
    [self setTransform:newTransform];
    
    _lastRotation = theRotaton;
    //    [self showOverlayWithFrame:_overlayButton.frame];
}

+ (UIImage*)mergeImages:(NSArray*)overlayImages image:(UIImage*)image imgStill:(UIImageView*)imgStill {
	UIImage *bottomImage = image;
	
	CGSize newSize = [bottomImage size];
	UIGraphicsBeginImageContext( newSize );
	
	// Use existing opacity as is
	[bottomImage drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
	
	for (OverlayView *overlayView in overlayImages) {
		NSLog(@"Adding dino - Start");
		UIImage *image = overlayView.image;
		
		if (overlayView.flipped == YES) {
			image = [image fixOrientation:UIImageOrientationUpMirrored];
		}
		
		NSLog(@"To rotation - %f", RADIANS_TO_DEGREES(overlayView.currentRotation));
		image = [image imageRotatedByDegrees:RADIANS_TO_DEGREES(overlayView.currentRotation)];
		
		// Use existing opacity as is
		float x = (overlayView.frame.origin.x / imgStill.frame.size.width) * [imgStill image].size.width;
		float y = (overlayView.frame.origin.y / imgStill.frame.size.height) * [imgStill image].size.width;
		float width = (overlayView.frame.size.width / imgStill.frame.size.width * [imgStill image].size.width);
		float height = (overlayView.frame.size.height / imgStill.frame.size.height * [imgStill image].size.width);
		
		// Apply supplied opacity if applicable
		[image drawInRect:CGRectMake(x,y,width,height) blendMode:kCGBlendModeNormal alpha:1.0];
		
		NSLog(@"Adding dino - End");
	}
	
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	
	UIGraphicsEndImageContext();
	
	return newImage;
}

@end
