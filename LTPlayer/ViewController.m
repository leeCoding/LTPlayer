//
//  ViewController.m
//  LTPlayer
//
//  Created by Jonny on 16/7/14.
//  Copyright © 2016年 Jonny. All rights reserved.
//

#import "ViewController.h"
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#import "UIView+Layout.h"
#import "LTPlayerView.h"

@interface ViewController ()
<

    LTPlayerViewDelegate
>

@property (nonatomic,strong)AVPlayer *player;               ///< 播放器
@property (nonatomic,strong)UIButton *stopBtn;              ///< 暂停按钮
@property (nonatomic,strong)AVPlayerItem *playerItem;       ///< 资源管理
@property (nonatomic,strong)AVPlayerLayer *playerLayer;     ///< 播放层
@property (nonatomic,strong)UILabel *videoDurationLabel;    ///< 总的时间
@property (nonatomic,strong)UILabel *videoNowLabel;         ///< 当前时间
@property (nonatomic,copy)NSString *timeNow;                   ///< 当前的时间
@property (nonatomic,strong)UISlider *progress;             ///< 滑块

@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self initView];
    
    [self initData];
}

#define kScreenWidth [UIScreen mainScreen].bounds.size.width

#define kScreenHeight [UIScreen mainScreen].bounds.size.height

#define Video_H kScreenWidth * 9 / 16

#define Video_W kScreenWidth

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBarHidden = YES;
    
}
- (void)viewDidDisappear:(BOOL)animated {
    
    self.navigationController.navigationBarHidden = NO;
    [super viewDidAppear:animated];
}

#pragma mark - 初始化视图
- (void)initView {
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    /**
     初始化
     */
    LTPlayerView *playerView = [[LTPlayerView alloc]initWithFrame:CGRectMake(0, 20, Video_W, Video_H) videoURL:@"http://flv2.bn.netease.com/tvmrepo/2016/8/6/A/EBUHRFU6A/SD/EBUHRFU6A-mobile.mp4"];
    playerView.delegate = self;
    [self.view addSubview:playerView];
}

#pragma mark - LTPlayerViewDelegate
- (void)loadComplete:(LTPlayerView *)playerView {
    
    NSLog(@" 加载结束回调");
}

- (void)playComplete:(LTPlayerView *)playerView {
    
    NSLog(@" 播放结束回调");
}

- (void)stopPlayVideo:(LTPlayerView *)playerView {
    
    NSLog(@" 暂停回调");
}

- (void)zoomInAndZoomOut:(LTPlayerView *)playerView zoomType:(LTZoomInOrZoomOutType)zoomType {
    
    if (zoomType == LTZoomInType) {
        
        NSLog(@" 放大");
        
    } else {
        
        NSLog(@" 缩小");
    }
}

- (void)initData {
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.

}

@end
