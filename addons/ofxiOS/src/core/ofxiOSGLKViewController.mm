//
//  ofxiOSGLKViewController.mm
//  iPhone+OF Static Library
//
//  Created by Dan Rosser on 7/3/18.
//

#include <TargetConditionals.h>
#if TARGET_OS_IOS || (TARGET_OS_IPHONE && !TARGET_OS_TV)

#import "ofxiOSGLKViewController.h"

#include "ofxiOSGLKView.h"
#import "ofxiOSExtras.h"
#include "ofAppiOSWindow.h"

@interface ofxiOSGLKViewController() <EAGLKViewDelegate, GLKViewControllerDelegate> {
    UIInterfaceOrientation currentInterfaceOrientation;
    UIInterfaceOrientation pendingInterfaceOrientation;
    BOOL bReadyToRotate;
    BOOL bFirstUpdate;
    BOOL bAnimated;
    BOOL bSupportedPortrait;
    BOOL bSupportedPortraitUpsideDown;
    BOOL bSupportedLandscapeLeft;
    BOOL bSupportedLandscapeRight;
}
@end

@implementation ofxiOSGLKViewController

@synthesize glView;

- (id)initWithFrame:(CGRect)frame app:(ofxiOSApp *)app {
    return [self initWithFrame:frame app:app sharegroup:nil];
}

- (id)initWithFrame:(CGRect)frame app:(ofxiOSApp *)app sharegroup:(EAGLSharegroup *)sharegroup{
    currentInterfaceOrientation = pendingInterfaceOrientation = UIInterfaceOrientationPortrait;
    if((self = [super init])) {
        currentInterfaceOrientation = pendingInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        if( [[[UIDevice currentDevice] systemVersion] compare:@"8.0" options:NSNumericSearch] == NSOrderedAscending ) {
            bReadyToRotate  = NO;
        }else{
            bReadyToRotate  = YES;
        }
        bFirstUpdate    = NO;
        bAnimated       = NO;
        
        self.glView = [[[ofxiOSGLKView alloc] initWithFrame:frame andApp:app sharegroup:sharegroup] autorelease];
        self.glView.delegate = self;
        
        NSArray* supportedOrientations = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"UISupportedInterfaceOrientations"];
        if (supportedOrientations != nil)
        {
            for(int i = 0; i < [supportedOrientations count]; i++)
            {
                NSString* orientation = (NSString*)[supportedOrientations objectAtIndex:i];
                if ([orientation isEqualToString:@"UIInterfaceOrientationPortrait"])
                    bSupportedPortrait = true;
                if ([orientation isEqualToString:@"UIInterfaceOrientationPortraitUpsideDown"])
                    bSupportedPortraitUpsideDown = true;
                if ([orientation isEqualToString:@"UIInterfaceOrientationLandscapeLeft"])
                    bSupportedLandscapeLeft = true;
                if ([orientation isEqualToString:@"UIInterfaceOrientationLandscapeRight"])
                    bSupportedLandscapeRight = true;
            }
        }
    }
    
    return self;
}


- (void) dealloc {
    [self.glView removeFromSuperview];
    self.glView.delegate = nil;
    self.glView = nil;
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    GLKView *view = (GLKView *)self.view;
    view.context = [self.glView context];
    self.delegate = self;
    self.preferredFramesPerSecond = 60; //default
    [view setMultipleTouchEnabled:ofxiOSGetOFWindow()->isMultiTouch()];
    [self.glView setup];
}


-(void) checkError
{
    GLenum error = glGetError();
    
    if (error == GL_NO_ERROR)
        return;
    
    switch (error)
    {
        case GL_INVALID_ENUM:
            NSLog(@"Invalid Enum");
            break;
    }
}


- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.glView resetTouches];
    
    [self.parentViewController topLayoutGuide]; // status bar visibility changes.
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
}

- (void)glkViewControllerUpdate:(GLKViewController *)controller {
    [self.glView update];
}

- (void)glkViewController:(GLKViewController *)controller willPause:(BOOL)pause {
    
}

- (void) glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    [view bindDrawable];
    [self.glView draw];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // rotation of the glView only works properly after viewDidAppear.
    // this is something to do with either the bounds, center or transform properties not being initialised earlier.
    // so now that glView is ready, we rotate it to the pendingInterfaceOrientation.
    if( [[[UIDevice currentDevice] systemVersion] compare:@"8.0" options:NSNumericSearch] == NSOrderedAscending ) {
        bReadyToRotate  = YES;
        bFirstUpdate    = YES;
        [self rotateToInterfaceOrientation:pendingInterfaceOrientation animated:NO];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if(self.glView != nil)
        [self.glView touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if(self.glView != nil)
        [self.glView touchesMoved:touches withEvent:event];
}
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if(self.glView != nil)
        [self.glView touchesEnded:touches withEvent:event];
}
- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if(self.glView != nil)
        [self.glView touchesCancelled:touches withEvent:event];
}
#ifdef __IPHONE_9_1
- (void)touchesEstimatedPropertiesUpdated:(NSSet<UITouch *> *)touches {
    if(self.glView != nil)
        [self.glView touchesEstimatedPropertiesUpdated:touches];
}
#endif

- (EAGLSharegroup *)getSharegroup {
    if(self.glView != nil) {
        EAGLContext * context = [self.glView context];
        if(context)
            return [context sharegroup];
    }
    return nil;
}


//-------------------------------------------------------------- glView callbacks.
- (void)glViewAnimationStarted {
    //
}

- (void)glViewAnimationStopped {
    //
}

- (void)glViewDraw {
    //
}

- (void)glViewResized {
    //
}

//-------------------------------------------------------------- orientation.
- (UIInterfaceOrientation)currentInterfaceOrientation {
    return currentInterfaceOrientation;
}

//-------------------------------------------------------------- orientation.
- (void)setCurrentInterfaceOrientation:(UIInterfaceOrientation) orient {
    currentInterfaceOrientation = pendingInterfaceOrientation = orient;
}

- (float)rotationForOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if (interfaceOrientation == UIInterfaceOrientationPortrait) {
        return 0;           // 0 degrees.
    } else if (interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
        return M_PI * 0.5;  // 90 degrees.
    } else if (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
        return M_PI;        // 180 degrees.
    } else if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
        return M_PI * 1.5;  // 270 degrees.
    } else {
        return 0;
    }
}

// iOS8+ version of willAnimateRotationToInterfaceOrientation
//NOTE: Only called if actually resizing and not masked
//http://stackoverflow.com/questions/25935006/ios8-interface-rotation-methods-not-called

//borg
#ifdef __IPHONE_8_0
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    CGPoint center;
    
    center.x = size.width * 0.5;
    center.y = size.height * 0.5;
    
    
    if(bAnimated) {
        NSTimeInterval duration = 0.3;
        [self.glView.layer removeAllAnimations];
        [UIView animateWithDuration:duration animations:^{
            self.glView.center = center;
            self.glView.transform = CGAffineTransformMakeRotation(0);
            self.glView.frame = CGRectMake(0, 0, size.width,size.height);
        }];
    } else {
        self.glView.center = center;
        self.glView.transform = CGAffineTransformMakeRotation(0);
        self.glView.frame = CGRectMake(0, 0, size.width,size.height);
    }
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        
        // Place code here to perform animations during the rotation.
        // You can pass nil or leave this block empty if not necessary.
        
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        
        // Code here will execute after the rotation has finished.
        // Equivalent to placing it in the deprecated method -[didRotateFromInterfaceOrientation:]
        
    }];
}
#endif


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    
    // CALLBACK 4.
    // This action marks the end of the rotation process.
    // You can use this method to show views, change the layout of views, or make other changes to your app.
}

//-------------------------------------------------------------- iOS5 and earlier.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return (toInterfaceOrientation == currentInterfaceOrientation);
}

- (BOOL)supportsOrientation:(UIInterfaceOrientation)orientation
{
    if(glView && glView.hardwareRotation == NO) {
        
        if(currentInterfaceOrientation == orientation)
            return YES;
        else
            return NO;
    }
    if(orientation == UIInterfaceOrientationPortrait && bSupportedPortrait)
        return YES;
    else if(orientation == UIInterfaceOrientationPortraitUpsideDown && bSupportedPortraitUpsideDown)
        return YES;
    else if(orientation == UIInterfaceOrientationLandscapeLeft && bSupportedLandscapeLeft)
        return YES;
    else if(orientation == UIInterfaceOrientationLandscapeRight && bSupportedLandscapeRight)
        return YES;
    else
        return NO;
}

//-------------------------------------------------------------- iOS6.
#ifdef __IPHONE_6_0
#if __IPHONE_OS_VERSION_MAX_ALLOWED < 90000
- (NSUInteger)supportedInterfaceOrientations
#else
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
#endif
{
    if(glView && glView.hardwareRotation == NO) {
        switch (currentInterfaceOrientation) {
            case UIInterfaceOrientationPortrait:
                return UIInterfaceOrientationMaskPortrait;
                break;
            case UIInterfaceOrientationPortraitUpsideDown:
                return UIInterfaceOrientationMaskPortraitUpsideDown;
                break;
            case UIInterfaceOrientationLandscapeLeft:
                return UIInterfaceOrientationMaskLandscapeLeft;
                break;
            case UIInterfaceOrientationLandscapeRight:
                return UIInterfaceOrientationMaskLandscapeRight;
                break;
            default:
                break;
        }
    }
   
    NSUInteger ret = 0;
    if ([self supportsOrientation:UIInterfaceOrientationPortrait]) {
        ret = ret | (1 << UIInterfaceOrientationPortrait);
    }
    if ([self supportsOrientation:UIInterfaceOrientationPortraitUpsideDown]) {
        ret = ret | (1 << UIInterfaceOrientationPortraitUpsideDown);
    }
    if ([self supportsOrientation:UIInterfaceOrientationLandscapeRight]) {
        ret = ret | (1 << UIInterfaceOrientationLandscapeRight);
    }
    if ([self supportsOrientation:UIInterfaceOrientationLandscapeLeft]) {
        ret = ret | (1 << UIInterfaceOrientationLandscapeLeft);
    }
    
    return ret;
}

- (void)rotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
                            animated:(BOOL)animated {
    bAnimated = animated;
    
    if(bReadyToRotate == NO) {
        pendingInterfaceOrientation = interfaceOrientation;
        
        NSLog(@"bReadyToRotate = NO");
        
        // we need to update the dimensions here, so if ofSetOrientation is called in setup,
        // then it will return the correct width and height
        CGSize screenSize = [UIScreen mainScreen].bounds.size;
        CGRect bounds = CGRectMake(0, 0, screenSize.width, screenSize.height);
        if(UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
            bounds.size.width   = screenSize.height;
            bounds.size.height  = screenSize.width;
        }
        self.glView.bounds = bounds;
        [self.glView updateDimensions];
        
        return;
    }
    
    
    if(currentInterfaceOrientation == interfaceOrientation && !bFirstUpdate) {
        CGSize screenSize = [UIScreen mainScreen].bounds.size;
        CGRect bounds = CGRectMake(0, 0, screenSize.width, screenSize.height);
        if(UIInterfaceOrientationIsLandscape(currentInterfaceOrientation)) {
            if(screenSize.width > screenSize.height) {
                NSLog(@"currentInterfaceOrientation == interfaceOrientation 1");
                return;
            }
        } else {
            if(screenSize.height > screenSize.width) {
                NSLog(@"currentInterfaceOrientation == interfaceOrientation 2");
                return;
            }
        }
    }
    
    if(pendingInterfaceOrientation != interfaceOrientation) {
        CGSize screenSize = [UIScreen mainScreen].bounds.size;
        CGRect bounds = CGRectMake(0, 0, screenSize.width, screenSize.height);
        if(UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
            bounds.size.width   = screenSize.height;
            bounds.size.height  = screenSize.width;
        }
        self.glView.bounds = bounds;
        [self.glView updateDimensions];
    }
    
    currentInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    UIInterfaceOrientation origin = currentInterfaceOrientation;
    
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    CGPoint center;
    CGRect bounds = CGRectMake(0, 0, screenSize.width, screenSize.height);
    
     if(glView && glView.hardwareRotation == NO) {
         origin =interfaceOrientation;
     }
    
    if(UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
        center.x = screenSize.height * 0.5;
        center.y = screenSize.width * 0.5;
    } else {
        center.x = screenSize.width * 0.5;
        center.y = screenSize.height * 0.5;
    }
    
    // Is the iOS version less than 8?
    if( [[[UIDevice currentDevice] systemVersion] compare:@"8.0" options:NSNumericSearch] == NSOrderedAscending ) {
        if(UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
            bounds.size.width = screenSize.height;
            bounds.size.height = screenSize.width;
        }
    } else {
        // Fixes for iOS 8 Portrait to Landscape issues
        if((UIInterfaceOrientationIsPortrait(interfaceOrientation) && screenSize.width >= screenSize.height) ||
           (UIInterfaceOrientationIsLandscape(interfaceOrientation) && screenSize.height >= screenSize.width)) {
            bounds.size.width = screenSize.height;
            bounds.size.height = screenSize.width;
        } else {
            bounds.size.width = screenSize.width;
            bounds.size.height = screenSize.height;
        }
        //assumes Portrait orientation
        if(screenSize.width>screenSize.height){
            center.x = screenSize.height * 0.5;
            center.y = screenSize.width * 0.5;
        }else{
            center.x = screenSize.width * 0.5;
            center.y = screenSize.height * 0.5;
        }
    }
    
    float rot1 = [self rotationForOrientation:currentInterfaceOrientation];
    float rot2 = [self rotationForOrientation:interfaceOrientation];
    float rot3 = rot2 - rot1;
    CGAffineTransform rotate = CGAffineTransformMakeRotation(rot3);
    rotate = CGAffineTransformConcat(rotate, self.glView.transform);
    
    if(animated) {
        NSTimeInterval duration = 0.3;
        if((UIInterfaceOrientationIsLandscape(currentInterfaceOrientation) && UIInterfaceOrientationIsLandscape(interfaceOrientation)) ||
           (UIInterfaceOrientationIsPortrait(currentInterfaceOrientation) && UIInterfaceOrientationIsPortrait(interfaceOrientation))) {
            duration = 0.6;
        }
        [self.glView.layer removeAllAnimations];
        [UIView animateWithDuration:duration animations:^{
            self.glView.center = center;
            self.glView.transform = rotate;
            self.glView.bounds = bounds;
        }];
    } else {
        self.glView.center = center;
        self.glView.transform = rotate;
        self.glView.bounds = bounds;
    }
    
    currentInterfaceOrientation = interfaceOrientation;
    bFirstUpdate = NO;
    
    [self.glView updateDimensions];
}
#endif

#ifdef __IPHONE_6_0
- (BOOL)shouldAutorotate {
    return YES;
}
#endif

#ifdef __IPHONE_7_0
-(BOOL)prefersStatusBarHidden{
    return YES;
}
#endif

- (BOOL)isReadyToRotate {
    return bReadyToRotate;
}

- (void)setPreferredFPS:(int)fps {
    if(self.glView != nil) {
        self.preferredFramesPerSecond = fps;
    }
}

- (void)setMSAA:(bool)value {
    if(self.glView != nil) {
        [self.glView setMSAA:value];
    }
}

@end

#endif
