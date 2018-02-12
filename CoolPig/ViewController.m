//
//  ViewController.m
//  CoolPig
//
//  Created by Netease_Victor on 2018/2/8.
//  Copyright © 2018年 VictorQi. All rights reserved.
//

#import "ViewController.h"
#import <opencv2/core.hpp>
#import <opencv2/imgcodecs.hpp>
#import <opencv2/imgcodecs/ios.h>
#import <opencv2/imgproc.hpp>
#import <opencv2/videoio/cap_ios.h>

#ifdef WITH_OPENCV_CONTRIB
#import <opencv2/xphoto.hpp>
#endif

#define RAND_0_1() ((double)arc4random() / 0x100000000)

@interface ViewController () <CvVideoCameraDelegate> {
    cv::Mat originalMat;
    cv::Mat updatedMat;
    cv::Mat originalStillMat;
    cv::Mat updatedStillMatGray;
    cv::Mat updatedStillMatRGB;
    cv::Mat updatedVideoMatGray;
    cv::Mat updatedVideoMatRGB;
}
@property (weak, nonatomic) IBOutlet UIImageView *mainImageView;
@property (nonatomic, strong) NSTimer *timer;
@end

@implementation ViewController

#pragma mark - View Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UIImage *originalImage = [UIImage imageNamed:@"doge.jpeg"];
    // 将UIImage转成cv::Mat
    UIImageToMat(originalImage, originalMat);
    
#ifdef WITH_OPENCV_CONTRIB
    cv::Ptr<cv::xphoto::WhiteBalancer> wb = cv::xphoto::createSimpleWB();
#endif
    
    switch (originalMat.type()) {
        case CV_8UC1: // cv::Mat是灰度图 转成rgb格式
            cv::cvtColor(originalMat, originalMat, cv::COLOR_GRAY2RGB);
            break;
        case CV_8UC4: // cv::Mat是RGBA格式 转成rgb格式
            cv::cvtColor(originalMat, originalMat, cv::COLOR_RGBA2RGB);
#ifdef WITH_OPENCV_CONTRIB
            wb->balanceWhite(originalMat, originalMat);
#endif
            break;
        case CV_8UC3: // cg::Mat是RGB格式
#ifdef WITH_OPENCV_CONTRIB
            wb->balanceWhite(originalMat, originalMat);
#endif
            break;
        default:
            break;
    }
    
    __weak typeof(self) weakSelf = self;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:2.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf.viewLoaded || !strongSelf.view.window) { return; }
        
        [strongSelf p_updateImage];
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Private Method

- (void)p_updateImage {
    double r = 0.5 + RAND_0_1() * 1.0;
    double g = 0.6 + RAND_0_1() * 0.8;
    double b = 0.4 + RAND_0_1() * 1.2;
    
    cv::Scalar randomColor(r, g, b);
    
    cv::multiply(originalMat, randomColor, updatedMat);
    
    self.mainImageView.image = MatToUIImage(updatedMat);
}

@end
