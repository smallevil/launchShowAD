//
//  WWLaunchAd.m
//  showAD
//
//  Created by 思无邪 on 2016/11/25.
//  Copyright © 2016年 思无邪. All rights reserved.
//

#import "WWLaunchAd.h"

@implementation WWLaunchAd

/*
+ (void)load
{
    //[self shareInstance];
    NSLog(@"WWLaunchAd load");
}
*/
+ (instancetype)shareInstance
{
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        /*
        ///如果是没啥经验的开发，请不要在初始化的代码里面做别的事，防止对主线程的卡顿，和 其他情况
        
        ///应用启动, 首次开屏广告
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            ///要等DidFinished方法结束后才能初始化UIWindow，不然会检测是否有rootViewController
            [self checkAD];
        }];
        ///进入后台
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            //[self request];
        }];
        ///后台启动,二次开屏广告
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            [self checkAD];
        }];
         */
    }
    
    return self;
}

-(void)show:(NSString*)url showTime:(NSInteger)st intervalTime:(NSInteger)it blankHeight:(NSInteger)height click:(clickBlock)click
{
    if(url == nil || [url isEqualToString:@""])
    {
        return;
    }
    
    initShowTime = st;
    intervalTime = it;
    imageUrl = url;
    blankHeight = height;
    _clickBlock = [click copy];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        ///要等DidFinished方法结束后才能初始化UIWindow，不然会检测是否有rootViewController
        [self checkAD];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        [self checkAD];
    }];
    
    /*
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        [self setCloseAppTime];
    }];
     */
}

-(void)setCloseAppTime
{
    NSString *currentTime = [NSString stringWithFormat:@"%llu",[[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]] longLongValue]];
    [[NSUserDefaults standardUserDefaults] setObject:currentTime forKey:@"WW_LAUNCH_AD_SHOW_TIME"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)checkAD
{
    NSLog(@"checkAD");
    UIImage *cacheImage = [XHImageCache xh_getCacheImageWithURL:[NSURL URLWithString:imageUrl]];
    
    if(cacheImage == nil)
    {
        [[UIImageView new] xh_setImageWithURL:[NSURL URLWithString:imageUrl] placeholderImage:nil options:XHWebImageCacheInBackground completed:nil];
        return;
    }
    
    [self showAD];
}

- (void)showAD
{
    NSString *preTime = [[NSUserDefaults standardUserDefaults] stringForKey:@"WW_LAUNCH_AD_SHOW_TIME"];
    NSString *currentTime = [NSString stringWithFormat:@"%llu",[[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]] longLongValue]];
    if([preTime length])
    {
        if([currentTime integerValue] - [preTime integerValue] < intervalTime)
        {
            return;
        }
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:currentTime forKey:@"WW_LAUNCH_AD_SHOW_TIME"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSLog(@"开始显示广告");
    showTime = initShowTime;
    ///初始化一个Window， 做到对业务视图无干扰。
    //UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - blankHeight / [[UIScreen mainScreen] scale])];
    UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    window.rootViewController = [UIViewController new];
    window.rootViewController.view.backgroundColor = [UIColor clearColor];
    window.rootViewController.view.userInteractionEnabled = NO;
    ///广告布局
    [self setupSubviews:window];
    
    ///设置为最顶层，防止 AlertView 等弹窗的覆盖
    window.windowLevel = UIWindowLevelStatusBar + 1;
    
    ///默认为YES，当你设置为NO时，这个Window就会显示了
    window.hidden = NO;
    window.alpha = 1;
    
    ///防止释放，显示完后  要手动设置为 nil
    self.window = window;
}

- (void)hide
{
    if (_skipButtonTimer) dispatch_source_cancel(_skipButtonTimer);
    _skipButton = nil;
    
    ///来个渐显动画
    [UIView animateWithDuration:0.3 animations:^{
        self.window.alpha = 0;
    } completion:^(BOOL finished) {
        [self.window.subviews.copy enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj removeFromSuperview];
        }];
        self.window.hidden = YES;
        self.window = nil;
    }];
}

- (void)setupSubviews:(UIWindow*)window
{
    ///随便写写
    UIImageView *bgimageView = [[UIImageView alloc] initWithFrame:window.bounds];
    bgimageView.image = [XHLaunchImage launchImage];
    [window addSubview:bgimageView];
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - blankHeight / [[UIScreen mainScreen] scale])];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    [imageView xh_setImageWithURL:[NSURL URLWithString:imageUrl] placeholderImage:nil options:XHWebImageCacheInBackground completed:nil];
    imageView.userInteractionEnabled = YES;
    
    ///给非UIControl的子类，增加点击事件
    UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickAD)];
    [imageView addGestureRecognizer:tap];
    
    [window addSubview:imageView];
    [window addSubview:[self skipButton]];
}

-(void)clickAD
{
    if(_clickBlock)
    {
        _clickBlock();
        //[self hide];
    }
}

-(XHSkipButton *)skipButton
{
    if(_skipButton == nil)
    {
        _skipButton = [[XHSkipButton alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 70, 25, 70, 40)];
        [_skipButton addTarget:self action:@selector(hide) forControlEvents:UIControlEventTouchUpInside];
        _skipButton.leftRightSpace = 5;
        _skipButton.topBottomSpace = 5;
        [_skipButton xh_stateWithskipType:SkipTypeTimeText andDuration:showTime];
        [self startSkipButtonTimer];
    }
    return _skipButton;
}

-(void)startSkipButtonTimer
{
    NSTimeInterval period = 1.0;
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    _skipButtonTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    dispatch_source_set_timer(_skipButtonTimer, dispatch_walltime(NULL, 0), period * NSEC_PER_SEC, 0);
    
    dispatch_source_set_event_handler(_skipButtonTimer, ^{
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [_skipButton xh_stateWithskipType:SkipTypeTimeText andDuration:showTime];
            if(showTime == 0)
            {
                [self hide];
            }
            showTime--;
        });
    });
    dispatch_resume(_skipButtonTimer);
}

+(void)clearDiskCache
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *path = [XHImageCache xh_cacheImagePath];
        [fileManager removeItemAtPath:path error:nil];
        [XHImageCache xh_checkDirectory:[XHImageCache xh_cacheImagePath]];
        
    });
}

+(float)imagesCacheSize {
    NSString *directoryPath = [XHImageCache xh_cacheImagePath];
    BOOL isDir = NO;
    unsigned long long total = 0;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:directoryPath isDirectory:&isDir]) {
        if (isDir) {
            NSError *error = nil;
            NSArray *array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryPath error:&error];
            
            if (error == nil) {
                for (NSString *subpath in array) {
                    NSString *path = [directoryPath stringByAppendingPathComponent:subpath];
                    NSDictionary *dict = [[NSFileManager defaultManager] attributesOfItemAtPath:path
                                                                                          error:&error];
                    if (!error) {
                        total += [dict[NSFileSize] unsignedIntegerValue];
                    }
                }
            }
        }
    }
    return total/(1024.0*1024.0);
}

@end
