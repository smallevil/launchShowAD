//
//  WWLaunchAd.h
//  showAD
//
//  Created by 思无邪 on 2016/11/25.
//  Copyright © 2016年 思无邪. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XHImageCache.h"
#import "XHSkipButton.h"
#import "XHLaunchImage.h"

typedef void(^clickBlock)();

@interface WWLaunchAd : NSObject
{
    NSInteger showTime;
    NSInteger intervalTime;
    NSInteger blankHeight;
    NSString *imageUrl;
    
    NSInteger initShowTime;
}

@property(nonatomic,copy)clickBlock clickBlock;
@property (nonatomic, strong) UIWindow* window;
@property(nonatomic,strong)XHSkipButton *skipButton;
@property(nonatomic,copy)dispatch_source_t skipButtonTimer;

+(instancetype)shareInstance;
-(void)show:(NSString*)imageUrl showTime:(NSInteger)showTime intervalTime:(NSInteger)it blankHeight:(NSInteger)height click:(clickBlock)click;
-(void)hide;
+(void)clearDiskCache;
+(float)imagesCacheSize;
@end
