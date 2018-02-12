//
//  VideoCamera.m
//  CoolPig
//
//  Created by Netease_Victor on 2018/2/9.
//  Copyright © 2018年 VictorQi. All rights reserved.
//

#import "VideoCamera.h"

@interface VideoCamera ()

@property (nonatomic, strong) CALayer *customPreviewLayer;

@end

@implementation VideoCamera

@synthesize customPreviewLayer = _customPreviewLayer;

- (int)imageWidth {
    AVCaptureVideoDataOutput *output = [self.captureSession.outputs lastObject];
    NSDictionary *videoSettings = [output videoSettings];
    int videoWidth = [videoSettings[AVVideoWidthKey] intValue];
    return videoWidth;
}

- (int)imageHeight {
    AVCaptureVideoDataOutput *output = [self.captureSession.outputs lastObject];
    NSDictionary *videoSettings = [output videoSettings];
    int videoHeight = [videoSettings[AVVideoHeightKey] intValue];
    return videoHeight;
}

- (void)layoutPreviewLayer {
    if (!self.parentView) {
        return;
    }
    
    CGRect parentFrame = self.parentView.frame;
    
    // 先居中
    self.customPreviewLayer.position = CGPointMake(CGRectGetMidX(parentFrame), CGRectGetMidY(parentFrame));
    
    // 然后确定长宽比
    CGFloat videoAspectRatio = self.imageWidth / (CGFloat)self.imageHeight;
    
    CGFloat boundsW, boundsH;
    if (self.imageHeight > self.imageWidth) {
        if (self.letterboxPreview) {
            boundsH = CGRectGetHeight(parentFrame);
            boundsW = boundsH * videoAspectRatio;
        } else {
            boundsW = CGRectGetWidth(parentFrame);
            boundsH = boundsW / videoAspectRatio;
        }
    } else {
        if (self.letterboxPreview) {
            boundsW = CGRectGetWidth(parentFrame);
            boundsH = boundsW / videoAspectRatio;
        } else {
            boundsH = CGRectGetHeight(parentFrame);
            boundsW = boundsH * videoAspectRatio;
        }
    }
    
    self.customPreviewLayer.bounds = CGRectMake(0, 0, boundsW, boundsH);
}

- (void)setPointOfInterestInParentViewSpace:(CGPoint)parentViewPoint {
    if (!self.running) { return; }
    
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:self.defaultAVCaptureDevicePosition];
    
    if (!captureDevice) { return; }
    
    BOOL canSetFocus = [captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus] && captureDevice.isFocusPointOfInterestSupported;
    
    BOOL canSetExposure = [captureDevice isExposureModeSupported:AVCaptureExposureModeAutoExpose] && captureDevice.isExposurePointOfInterestSupported;
    
    if (!canSetFocus && !canSetExposure) { return; }
    
    NSError *lockConfigurationError = nil;
    if (![captureDevice lockForConfiguration:&lockConfigurationError]) {
        NSLog(@"lock configuration failed for capture device: %@, error: %zd, %@", captureDevice, lockConfigurationError.code, lockConfigurationError.userInfo);
        return;
    }
    
    CGFloat offsetX = 0.5 * (CGRectGetWidth(self.parentView.bounds) - CGRectGetWidth(self.customPreviewLayer.bounds));
    CGFloat offsetY = 0.5 * (CGRectGetHeight(self.parentView.bounds) - CGRectGetHeight(self.customPreviewLayer.bounds));
    
    CGFloat focusX = (parentViewPoint.x - offsetX) / CGRectGetWidth(self.customPreviewLayer.bounds);
    CGFloat focusY = (parentViewPoint.y - offsetY) / CGRectGetHeight(self.customPreviewLayer.bounds);
    
    if (focusX < 0.0 || focusX > 1.0 || focusY < 0.0 || focusY > 1.0) { return; }
    
    switch (self.defaultAVCaptureVideoOrientation) {
        case AVCaptureVideoOrientationPortraitUpsideDown: {
            CGFloat oldFocusX = focusX;
            focusX = 1.0 - focusX;
            focusY = oldFocusX;
        }
            break;
        case AVCaptureVideoOrientationLandscapeLeft:
            focusX = 1.0 - focusX;
            focusY = 1.0 - focusY;
            break;
        case AVCaptureVideoOrientationLandscapeRight:
            // 什么都不需要做
            break;
        case AVCaptureVideoOrientationPortrait: {
            CGFloat oldFocusX = focusX;
            focusX = focusY;
            focusY = 1.0 - oldFocusX;
        }
            break;
    }
    
    CGPoint focusPoint = CGPointMake(focusX, focusY);
    
    if (canSetFocus) {
        captureDevice.focusMode = AVCaptureFocusModeAutoFocus;
        captureDevice.focusPointOfInterest = focusPoint;
    }
    
    if (canSetExposure) {
        captureDevice.exposureMode = AVCaptureExposureModeAutoExpose;
        captureDevice.exposurePointOfInterest = focusPoint;
    }
    
    [captureDevice unlockForConfiguration];
}

@end
