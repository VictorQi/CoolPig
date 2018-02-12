//
//  CameraViewController.m
//  CoolPig
//
//  Created by Netease_Victor on 2018/2/12.
//  Copyright © 2018年 VictorQi. All rights reserved.
//

#import "CameraViewController.h"
#import <opencv2/core.hpp>
#import <opencv2/imgcodecs.hpp>
#import <opencv2/imgcodecs/ios.h>
#import <opencv2/imgproc.hpp>
#import <opencv2/videoio/cap_ios.h>
#import "VideoCamera.h"

#ifdef WITH_OPENCV_CONTRIB
#import <opencv2/xphoto.hpp>
#endif

@interface CameraViewController () <CvVideoCameraDelegate> {
    cv::Mat originalStillMat;
    cv::Mat updatedStillMatGray;
    cv::Mat updatedStillMatRGBA;
    cv::Mat updatedVideoMatGray;
    cv::Mat updatedVideoMatRGBA;
}
@property (nonatomic, strong) VideoCamera *videoCamera;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UIToolbar *toolbar;
@property (nonatomic, assign) BOOL saveNextFrame;
@end

@implementation CameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSString *originalPath = [NSBundle.mainBundle pathForResource:@"Fleur" ofType:@"jpg"];
    UIImage *originalStillImage = [UIImage imageWithContentsOfFile:originalPath];
    UIImageToMat(originalStillImage, originalStillMat);
    
    self.videoCamera = [[VideoCamera alloc] initWithParentView:self.imageView];
    self.videoCamera.delegate = self;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPresetHigh;
    self.videoCamera.defaultFPS = 30;
    self.videoCamera.letterboxPreview = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Layout

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    switch (UIDevice.currentDevice.orientation) {
        case UIDeviceOrientationPortraitUpsideDown:
            self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
            break;
        case UIDeviceOrientationLandscapeLeft:
            self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationLandscapeLeft;
            break;
        case UIDeviceOrientationLandscapeRight:
            self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationLandscapeRight;
            break;
        default:
            self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
            break;
    }
    
    [self p_refresh];
}

#pragma mark - Private Method

- (void)p_refresh {
    if (self.videoCamera.running) {
        self.imageView.image = nil;
        
        [self.videoCamera stop];
        [self.videoCamera start];
    } else {
        UIImage *image;
        if (self.videoCamera.grayscaleMode) {
            cv::cvtColor(originalStillMat, updatedStillMatGray, cv::COLOR_RGBA2GRAY);
            [self processImage:updatedStillMatGray];
            image = MatToUIImage(updatedStillMatGray);
        } else {
            cv::cvtColor(originalStillMat, updatedStillMatRGBA, cv::COLOR_RGBA2BGRA);
            [self processImage:updatedStillMatRGBA];
            cv::cvtColor(updatedStillMatRGBA, updatedStillMatRGBA, cv::COLOR_BGRA2RGBA);
            image = MatToUIImage(updatedStillMatRGBA);
        }
        self.imageView.image = image;
    }
}

- (void)p_processImageHelper:(cv::Mat &)mat {
    
}

- (void)p_saveImage:(UIImage *)image {
    
}

#pragma mark - Button Event

- (IBAction)onColorModeSelected:(UISegmentedControl *)sender {
    switch (sender.selectedSegmentIndex) {
        case 0:
            self.videoCamera.grayscaleMode = NO;
            break;
        default:
            self.videoCamera.grayscaleMode = YES;
            break;
    }
    
    [self p_refresh];
}

- (IBAction)onSwitchCameraButtonPressed:(UIBarButtonItem *)sender {
    if (!self.videoCamera.running) {
        self.imageView.image = nil;
        self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionFront;
        [self.videoCamera start];
        return;
    }
    switch (self.videoCamera.defaultAVCaptureDevicePosition) {
        case AVCaptureDevicePositionFront:
            self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
            [self p_refresh];
            break;
            
        default:
            [self.videoCamera stop];
            [self p_refresh];
            break;
    }
}

- (IBAction)onSaveButtonPressed:(UIBarButtonItem *)sender {
    
}

- (IBAction)onTapToSetPointOfInterest:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        if (self.videoCamera.running) {
            CGPoint tapPoint = [sender locationInView:self.imageView];
            [self.videoCamera setPointOfInterestInParentViewSpace:tapPoint];
        }
    }
}

#pragma mark - CvVideoCameraDelegate

- (void)processImage:(cv::Mat &)mat {
    if (!self.videoCamera.running) { return; }
    
    switch (self.videoCamera.defaultAVCaptureVideoOrientation) {
        case AVCaptureVideoOrientationLandscapeLeft:
        case AVCaptureVideoOrientationLandscapeRight:
            // 横屏的视频被捕获的时候是上下颠倒的，旋转180°
            cv::flip(mat, mat, -1);
            break;
            
        default:
            break;
    }
    
    [self processImage:mat];
    
    if (self.saveNextFrame) {
        UIImage *image;
        if (self.videoCamera.grayscaleMode) {
            mat.copyTo(updatedVideoMatGray);
            image = MatToUIImage(updatedVideoMatGray);
        } else {
            cv::cvtColor(mat, updatedVideoMatRGBA, cv::COLOR_BGRA2RGBA);
            image = MatToUIImage(updatedVideoMatRGBA);
        }
        [self p_saveImage:image];
        self.saveNextFrame = NO;
    }
}


@end
