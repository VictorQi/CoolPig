//
//  VideoCamera.h
//  CoolPig
//
//  Created by Netease_Victor on 2018/2/9.
//  Copyright © 2018年 VictorQi. All rights reserved.
//

#import <opencv2/videoio/cap_ios.h>
#import <AVFoundation/AVFoundation.h>

@interface VideoCamera : CvVideoCamera

@property (nonatomic, assign) BOOL letterboxPreview;

- (void)setPointOfInterestInParentViewSpace:(CGPoint)point;

@end
