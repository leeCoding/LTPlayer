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

- (void)initView {
    
    LTPlayerView *playerView = [[LTPlayerView alloc]initWithFrame:CGRectMake(0, 20, Video_W, Video_H) videoURL:@"http://zyvideo1.oss-cn-qingdao.aliyuncs.com/zyvd/7c/de/04ec95f4fd42d9d01f63b9683ad0"];
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
