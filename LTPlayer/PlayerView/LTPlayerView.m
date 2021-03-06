//
//  LTPlayerView.m
//  LTPlayer
//
//  Created by Jonny on 16/8/25.
//  Copyright © 2016年 Jonny. All rights reserved.
//

#import "LTPlayerView.h"
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#import "UIView+Layout.h"

#define kScreenWidth [UIScreen mainScreen].bounds.size.width

#define kScreenHeight [UIScreen mainScreen].bounds.size.height

/* 视频高度 */
#define Video_H kScreenWidth * 9 / 16

/* 视频宽度 */
#define Video_W kScreenWidth

typedef enum : NSUInteger {
    LTPlayerStatusStop,         ///< 暂停
    LTPlayerStatusPlayerEnd,    ///< 结束
    LTPlayerStatusPlayer,       ///< 播放中
    LTPlayerStatusLoading,      ///< 加载中
    LTPlayerStatusLoadingError, ///< 加载错误
    LTPlayerStatusLoadingUnkown ///< 未知错误
    
} LTPlayerStatus;               ///< 视频播放状态

@interface LTPlayerView ()
{
    BOOL _isHideActionBar;      /// < 记录是否隐藏
}

@property (nonatomic,strong)UIView *playerView;             ///< 播放器容器
@property (nonatomic,strong)AVPlayer *player;               ///< 播放器
@property (nonatomic,strong)UIButton *stopBtn;              ///< 暂停按钮
@property (nonatomic,strong)AVPlayerItem *playerItem;       ///< 资源管理
@property (nonatomic,strong)AVPlayerLayer *playerLayer;     ///< 播放层
@property (nonatomic,strong)UILabel *videoDurationLabel;    ///< 总的时间
@property (nonatomic,strong)UILabel *videoNowLabel;         ///< 当前时间
@property (nonatomic,copy)NSString *timeNow;                ///< 当前的时间
@property (nonatomic,strong)UISlider *progress;             ///< 滑块
@property (nonatomic,copy)NSString *videoUrl;               ///< 视屏播放URL

@property (nonatomic,strong)UIView *topBarView;              ///< 顶部栏
@property (nonatomic,strong)UIView *actionBarView;          ///< 底部操作栏

@property (nonatomic,strong)UIButton *fullBtn;              ///< 全屏按钮
@property (nonatomic,strong)UIView *transparentView;        ///< 操作层
@property (nonatomic,strong)UIImageView *stopImageView;     ///< 暂停播放图片
@property (nonatomic,strong)UIActivityIndicatorView *loadingView;   ///< 菊花
@property (nonatomic,assign)LTPlayerStatus playerStatus;            ///< 视屏播放状态
@property (nonatomic,strong)UIProgressView *progressView;   ///< 设置缓冲进度
@end

@implementation LTPlayerView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (instancetype)initWithFrame:(CGRect)frame videoURL:(NSString *)URL {
    
    self = [super initWithFrame:frame];
    
    if (self) {
        
        self.backgroundColor = [UIColor whiteColor];
        
        self.videoUrl = URL;
        
        __weak typeof(self) __weakSelf  = self;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [__weakSelf initView];
        });
    }
    
    return self;
}

#pragma mark - 初始化视图
- (void)initView {
    
    self.playerView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, Video_W, Video_H)];
    self.playerView.backgroundColor = [UIColor blackColor];
    [self addSubview:self.playerView];
    
    // 操作底栏
    self.actionBarView = [[UIView alloc]initWithFrame:CGRectMake(0, Video_H - 40, Video_W, 40)];
    self.actionBarView.backgroundColor = [UIColor whiteColor];
    self.actionBarView.alpha = 0.5;
    [self.playerView addSubview:self.actionBarView];
    
    // 全屏操作
    self.transparentView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, Video_W, Video_H - 40)];
    [self addSubview:self.transparentView];
    
    // 顶部顶栏
    self.topBarView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, Video_W, 40)];
    self.topBarView.backgroundColor = [UIColor whiteColor];
    self.topBarView.alpha = 0.5;
    [self.transparentView addSubview:self.topBarView];
    
    // 返回按钮
    UIButton *returnBtn = [[UIButton alloc]initWithFrame:CGRectMake(8, 5, 40, 30)];
    [returnBtn setImage:[UIImage imageNamed:@"BackBtn"] forState:0];
    [returnBtn addTarget:self action:@selector(returnUpPage) forControlEvents:UIControlEventTouchUpInside];
    [self.topBarView addSubview:returnBtn];
    
    // 点击屏幕暂停
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(stopVideo)];
    [self.transparentView addGestureRecognizer:tap];
    
    // 暂停图片
    self.stopImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 30, 30)];
    self.stopImageView.center = CGPointMake(self.transparentView.center.x, self.transparentView.center.y+15);
    self.stopImageView.image = [UIImage imageNamed:@"icon_play"];
    self.stopImageView.hidden = YES;
    [self.transparentView addSubview:self.stopImageView];
    
    // 菊花
    self.loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.loadingView.center = CGPointMake(self.width / 2, self.height / 2);
    [self addSubview:self.loadingView];
    
    [self.loadingView startAnimating];
    
    // 暂停
    self.stopBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.stopBtn.frame = CGRectMake(0, 5, 40 ,30);
    [self.stopBtn setTitle:@"暂停" forState:UIControlStateNormal];
    [self.stopBtn setTitle:@"开始" forState:UIControlStateSelected];
    self.stopBtn.selected = NO;
    self.stopBtn.titleLabel.font = [UIFont systemFontOfSize:12];
    [self.stopBtn setTitleColor:[UIColor blackColor] forState:0];
    self.stopBtn.alpha = 1;
    self.stopBtn.enabled = NO;
    [self.stopBtn addTarget:self action:@selector(stopPlay:) forControlEvents:UIControlEventTouchUpInside];
    [self.actionBarView addSubview:self.stopBtn];
    
    // 当前的播放的时间
    self.videoNowLabel = [[UILabel alloc]initWithFrame:CGRectMake(self.stopBtn.right + 2, 5,30, 30)];
    self.videoNowLabel.textColor = [UIColor blackColor];
    self.videoNowLabel.font = [UIFont systemFontOfSize:10];
    self.videoNowLabel.text = @"00:00";
    self.videoNowLabel.textAlignment = NSTextAlignmentCenter;
    [self.actionBarView addSubview:self.videoNowLabel];
    
    NSURL *URL = [NSURL URLWithString:self.videoUrl];
    
    // 资源流
    self.playerItem = [AVPlayerItem playerItemWithURL:URL];
    
    // 播放器
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    
    // 播放层
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.frame = CGRectMake(0, 0, Video_W, Video_H);
    [self.playerView.layer insertSublayer:self.playerLayer atIndex:0];
    
//    [self.player play];
    
    // 控制进度
    self.progress = [[UISlider alloc]initWithFrame:CGRectMake(self.videoNowLabel.right + 2, 11, Video_W - 146, 20)];
    self.progress.alpha = 1;
    self.progress.thumbTintColor = [UIColor blackColor];
    self.progress.minimumValue = 0;
    [self.progress addTarget:self action:@selector(forwardAndRefund:) forControlEvents:UIControlEventValueChanged];
    self.progress.minimumTrackTintColor = [UIColor greenColor];
    self.progress.maximumTrackTintColor = [UIColor clearColor];
    self.progress.backgroundColor = [UIColor clearColor];

    
    // 缓冲进度
    self.progressView = [[UIProgressView alloc]initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.progressView.frame = CGRectMake(0, 0, Video_W - 146, self.progress.height);
    self.progressView.center = CGPointMake(self.progress.center.x, self.progress.center.y);
    
    self.progressView.progressTintColor = [UIColor clearColor];
    self.progressView.trackTintColor    = [UIColor lightGrayColor];
    [self.progressView setProgress:0.0 animated:NO];
    [self.actionBarView addSubview:self.progressView];
    [self.actionBarView addSubview:self.progress];

    
//    NSDictionary *opts = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO]
//                                                     forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
//    AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:URL options:opts];
//    float second = 0;
//    second = urlAsset.duration.value/urlAsset.duration.timescale;
//    NSLog(@"movie duration : %f", second);
    
    
    // 视屏的总时间
    self.videoDurationLabel = [[UILabel alloc]initWithFrame:CGRectMake(self.progress.right + 2, 5,30, 30)];
    self.videoDurationLabel.textColor = [UIColor blackColor];
    self.videoDurationLabel.font = [UIFont systemFontOfSize:10];
    self.videoDurationLabel.textAlignment = NSTextAlignmentCenter;
    [self.actionBarView addSubview:self.videoDurationLabel];
    
    // 全屏按钮
    self.fullBtn  = [UIButton buttonWithType:UIButtonTypeCustom];
    self.fullBtn.frame = CGRectMake(self.videoDurationLabel.right + 2, 5, 40, 30);
    [self.fullBtn setTitle:@"全屏" forState:0];
    [self.fullBtn setTitleColor:[UIColor blackColor] forState:0];
    self.fullBtn.titleLabel.font = [UIFont systemFontOfSize:12];
    [self.fullBtn addTarget:self action:@selector(fullEvent:) forControlEvents:UIControlEventTouchUpInside];
    [self.actionBarView addSubview:self.fullBtn];
    
    // 添加监听
    [self addPlayerItemObserver];
    
    // 添加自动隐藏操作栏
    [self hideActionBarView];
}

#pragma mark - 添加播放监听
- (void)addPlayerItemObserver {
 
    // 监听播放资源的状态
    [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    
    // loadedTimeRanges属性监听
    [self.playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    
    // 监听缓存
    [self.playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    
    // 监听缓存
    [self.playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    
    //播放结束通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
}

#pragma mark - 隐藏底部操作栏
- (void)hideActionBarView {
    
    __weak typeof(self) __weakSelf = self;
    // 等待两秒隐藏
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        [UIView  animateWithDuration:0.5 animations:^{
            
            // 如果选择了全屏按钮
            if (__weakSelf.fullBtn.selected) {
                
                __weakSelf.actionBarView.frame = CGRectMake(0, kScreenWidth, kScreenHeight, 40);
                __weakSelf.topBarView.frame = CGRectMake(kScreenWidth - 40, 0, 40, kScreenHeight);

            } else {
                
                __weakSelf.actionBarView.frame = CGRectMake(0, Video_H, Video_W, 40);
                __weakSelf.topBarView.frame = CGRectMake(0, - 40, Video_W, 30);
            }
            __weakSelf.actionBarView.alpha = 0;
            _isHideActionBar = YES;

        }];;
    });
    
}

#pragma mark - 显示底部操作栏
- (void)showActionBarView {
    
    __weak typeof(self) __weakSelf = self;

    [UIView  animateWithDuration:0.5 animations:^{
        
        // 如果选择了全屏按钮
        if (__weakSelf.fullBtn.selected) {
            
            __weakSelf.actionBarView.frame = CGRectMake(0, kScreenWidth - 40, kScreenHeight, 40);
            __weakSelf.topBarView.frame = CGRectMake(kScreenWidth - 40 - 40, 0, 40, kScreenHeight);
            
        } else {
            
            __weakSelf.actionBarView.frame = CGRectMake(0, Video_H - 40, Video_W, 40);
            __weakSelf.topBarView.frame = CGRectMake(0, 0, Video_W, 40);
        }
        
       __weakSelf.actionBarView.alpha = 0.5;
        
        // 设置不隐藏
        _isHideActionBar = NO;

    }];
    
    [self hideActionBarView];
}

#pragma mark - 快进快退
- (void)forwardAndRefund:(UISlider *)slider {
    
    // 设置当前的进度
    CMTime cmTime = CMTimeMake(slider.value, 1);
    [self.playerLayer.player seekToTime:cmTime];
    
    // 设置当前播放的时间
    self.videoNowLabel.text = [self timeFormatted:(int)(CMTimeGetSeconds(self.playerItem.currentTime))];
}

#pragma mark - 播放结束通知
-  (void)playEnd:(id)send {
    
    self.progress.value = 0.0;
    [self.playerLayer.player seekToTime:kCMTimeZero];
    self.stopBtn.selected = YES;
    
    // 播放结束代理
    if ([self.delegate respondsToSelector:@selector(playComplete:)]) {
        [self.delegate playComplete:self];
    }
}

#pragma mark - 时间转换
- (NSString *)timeFormatted:(int)totalSeconds {
    
    int seconds = totalSeconds % 60;
    int minutes = totalSeconds / 60;
    NSLog(@" 时间 %@", [NSString stringWithFormat:@"%d:%02d", minutes, seconds]);
    
    return [NSString stringWithFormat:@"%d:%02d", minutes, seconds];
}

#pragma mark - 全屏
- (void)fullEvent:(UIButton *)btn {
    
    btn.selected =! btn.selected;
    
    // 缩放回调
    if ([self.delegate respondsToSelector:@selector(zoomInAndZoomOut:zoomType:)]) {
        [self.delegate zoomInAndZoomOut:self zoomType:btn.selected];
    }
    
    __weak typeof(self) __weakSelf = self;

    if (btn.selected) {
        
        [UIView animateWithDuration:0.5 animations:^{
            
            __weakSelf.transform = CGAffineTransformMakeRotation((0.0f * M_PI) / 180.0f);
            __weakSelf.frame = CGRectMake(0, 0, kScreenWidth, kScreenHeight);
            
            __weakSelf.playerView.transform = CGAffineTransformMakeRotation((90.0f * M_PI) / 180.0f);
            __weakSelf.playerView.frame = CGRectMake(0, 0, kScreenWidth, kScreenHeight);
            __weakSelf.playerLayer.frame =  CGRectMake(0, 0, kScreenHeight, kScreenWidth);
            
            // 旋转顶部操作栏
            __weakSelf.topBarView.transform = CGAffineTransformMakeRotation((90.0f * M_PI) / 180.0f);
            __weakSelf.topBarView.frame = CGRectMake(kScreenWidth - 40 - 40, 0, 40, kScreenHeight);
            
            // 旋转底部操作栏
            __weakSelf.actionBarView.transform = CGAffineTransformMakeRotation((0.0f * M_PI) / 180.0f);
            __weakSelf.actionBarView.frame = CGRectMake(0, kScreenWidth - 40, kScreenHeight, 40);
            
            // 透明层
            __weakSelf.transparentView.transform = CGAffineTransformMakeRotation((0.0f * M_PI) / 180.0f);
            __weakSelf.transparentView.frame = CGRectMake(40, 0, kScreenWidth, kScreenHeight);
            
            // 控制进度
            __weakSelf.progress.frame = CGRectMake(__weakSelf.videoNowLabel.right + 2, 10, kScreenHeight - 146, 20);
            __weakSelf.progressView.frame = __weakSelf.progress.frame;
            __weakSelf.progressView.center = CGPointMake(__weakSelf.progress.center.x, __weakSelf.progress.center.y);

            __weakSelf.videoDurationLabel.frame = CGRectMake(__weakSelf.progress.right + 2, 5,30, 30);
            __weakSelf.fullBtn.frame = CGRectMake(__weakSelf.videoDurationLabel.right + 2, 5, 40, 30);
            
            __weakSelf.stopImageView.transform = CGAffineTransformMakeRotation((90.0f * M_PI) / 180.0f);
            __weakSelf.stopImageView.center = __weakSelf.center;
            __weakSelf.loadingView.center = CGPointMake(kScreenWidth/2, kScreenHeight/2);
        }];
        
    } else {
        
        [UIView animateWithDuration:0.5 animations:^{
            
            __weakSelf.transform = CGAffineTransformMakeRotation((0.0f * M_PI) / 180.0f);
            __weakSelf.frame = CGRectMake(0, 20, Video_W,Video_H);
            __weakSelf.playerView.transform = CGAffineTransformMakeRotation((0.0f * M_PI) / 180.0f);
            __weakSelf.playerView.frame = CGRectMake(0, 0, Video_W,Video_H);
            __weakSelf.playerLayer.frame = CGRectMake(0, 0,  Video_W, Video_H);
            
            __weakSelf.topBarView.transform = CGAffineTransformMakeRotation((0.0f * M_PI) / 180.0f);
            __weakSelf.topBarView.frame = CGRectMake(0, 0, Video_W, 40);
            
            __weakSelf.actionBarView.transform = CGAffineTransformMakeRotation((0.0f * M_PI) / 180.0f);
            __weakSelf.actionBarView.frame = CGRectMake(0, Video_H - 40, Video_W, 40);
            
            __weakSelf.transparentView.transform = CGAffineTransformMakeRotation((0.0f * M_PI) / 180.0f);
            __weakSelf.transparentView.frame = CGRectMake(0, 0, Video_W, Video_H - 40);
            
            // 控制返回原来按钮
            __weakSelf.progress.frame = CGRectMake(__weakSelf.videoNowLabel.right + 2, 10, Video_W - 146, 20);
            __weakSelf.progressView.frame = __weakSelf.progress.frame;
            __weakSelf.progressView.center = CGPointMake(__weakSelf.progress.center.x, __weakSelf.progress.center.y);
            
            __weakSelf.videoDurationLabel.frame = CGRectMake(__weakSelf.progress.right + 2, 5,30, 30);
            __weakSelf.fullBtn.frame = CGRectMake(__weakSelf.videoDurationLabel.right + 2, 5, 40, 30);
            
            __weakSelf.stopImageView.transform = CGAffineTransformMakeRotation((0.0f * M_PI) / 180.0f);
            __weakSelf.stopImageView.center = CGPointMake(__weakSelf.transparentView.center.x,__weakSelf.transparentView.center.y + 15);

            __weakSelf.loadingView.center = __weakSelf.center;
        }];
        
    }
}

#pragma mark - 点击屏幕暂停播放
- (void)stopVideo {
    
    if (_isHideActionBar == YES) {
     
        // 显示底部栏
        [self showActionBarView];
        
    } else {
     
        // 在这几种状态时之前返回
        if (self.playerStatus == LTPlayerStatusLoadingUnkown) return;
        if (self.playerStatus == LTPlayerStatusLoadingError) return;
        if (self.playerStatus == LTPlayerStatusLoading) return;
        
        self.stopBtn.selected = ! self.stopBtn.selected;
        
        [self setVideoPlayer:self.stopBtn.selected];
        
        // 显示播放按钮和显示暂停
        self.stopImageView.hidden = ! self.stopImageView.hidden;
    }
}

#pragma mark - 设置播放状态
- (void)setVideoPlayer:(BOOL)isPlayer {
    
    if (isPlayer) {
        
        [self.player pause];
        
        // 暂停播放回调
        if ([self.delegate respondsToSelector:@selector(stopPlayVideo:)]) {
            [self.delegate stopPlayVideo:self];
        }
        
        // 暂停之后置初始状态
        self.playerStatus = LTPlayerStatusStop;
        self.stopBtn.selected = YES;
        
    } else {
     
        [self.player play];
        self.playerStatus = LTPlayerStatusPlayer;
    }
    
}

#pragma mark - 暂停播放按钮
- (void)stopPlay:(UIButton *)btn {
    
    // 在这几种状态时之前返回
    if (self.playerStatus == LTPlayerStatusLoadingUnkown) return;
    if (self.playerStatus == LTPlayerStatusLoadingError) return;
    if (self.playerStatus == LTPlayerStatusLoading) return;
    
    btn.selected =! btn.selected;
    [self setVideoPlayer:btn.selected];
    self.stopImageView.hidden = ! self.stopImageView.hidden;

}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    AVPlayerItem *playerItem = (AVPlayerItem *) object;
    
    if ([keyPath isEqualToString:@"status"]) {
        
        // 1.已经缓存完毕
        if (playerItem.status == AVPlayerItemStatusReadyToPlay) {
            
            [self.loadingView stopAnimating];

            NSLog(@" 加载完毕可以播放");
            
            // 设置滑块最大值
            CMTime duration = self.playerItem.duration;
            CGFloat maxTime = CMTimeGetSeconds(duration);
            self.progress.maximumValue = maxTime;
            
            // 设置播放按钮可点
            self.stopBtn.enabled = YES;
            
            // 视频加载完毕回调
            if ([self.delegate respondsToSelector:@selector(loadComplete:)]) {
                [self.delegate loadComplete:self];
            }
            
            self.playerStatus = LTPlayerStatusPlayerEnd;

        } else if (playerItem.status == AVPlayerItemStatusFailed) {
            
            //2.失败
            [self.loadingView stopAnimating];
            NSLog(@"加载失败");
            
            self.playerStatus = LTPlayerStatusLoadingError;
            
        } else if (playerItem.status == AVPlayerItemStatusUnknown) {
            
            //3.未知状态
            [self.loadingView stopAnimating];
            self.playerStatus = LTPlayerStatusLoadingUnkown;
            NSLog(@"未知状态");
        }
    
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        
        //监听时间
        //加载视屏时间总的时间，
        //CMTime duration = self.playerItem.duration;
        
        // 转换成秒
        CGFloat totalSecond = playerItem.duration.value / playerItem.duration.timescale;
        
        //转换成播放时间位置
        self.timeNow = [self convertTime:totalSecond];
        //NSLog(@"movie total duration:%f",CMTimeGetSeconds(duration));
        //NSLog(@" 时间 ++ %@ ",self.timeNow);
        self.videoDurationLabel.text = self.timeNow;
        [self monitoringPlayback:playerItem];
        
        [self.loadingView stopAnimating];
        
        // 防止在中间网速不好时出现播放状态从正在加载改为加载中时出现暂停的问题
        if (self.playerStatus == LTPlayerStatusLoading) {
            
            [self.player play];
        }
        
        self.playerStatus = LTPlayerStatusPlayer;
        
        // 计算缓冲进度
        NSTimeInterval timeInterval = [self availableDuration];
        CMTime duration             = _playerItem.duration;
        CGFloat totalDuration       = CMTimeGetSeconds(duration);
        
        //缓冲颜色
        self.progressView.progressTintColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.7];
        [self.progressView setProgress:timeInterval / totalDuration animated:NO];
        
        NSLog(@"加载中");
        
    } else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
        
        [self.loadingView startAnimating];
        
        NSLog(@"正在加载");
        
        self.playerStatus = LTPlayerStatusLoading;
        
    } else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {

        [self.loadingView stopAnimating];
        
        NSLog(@"保持加载");
        
    } else if ([keyPath isEqualToString:@"playbackBufferFull"]) {
        
        NSLog(@"加载完成");
        
    }  else  {
        
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (NSTimeInterval)getAvailableDuration {
    
    NSArray *loadedTimeRanges = [_playerItem loadedTimeRanges];
    CMTimeRange timeRange     = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
    float startSeconds        = CMTimeGetSeconds(timeRange.start);
    float durationSeconds     = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result     = startSeconds + durationSeconds;// 计算缓冲总进度
    return result;
}

// 获取总的时间
- (NSTimeInterval)availableDuration {
    
    NSArray *loadedTimeRanges = [[self.playerLayer.player currentItem] loadedTimeRanges];
    
    // 获取缓冲区域
    CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];
    float startSeconds = CMTimeGetSeconds(timeRange.start);
    float durationSeconds = CMTimeGetSeconds(timeRange.duration);
    
    // 计算缓冲总进度
    NSTimeInterval result = startSeconds + durationSeconds;
    return result;
}

// 格式化时间
- (NSString *)convertTime:(CGFloat)second {
    
    NSDate *d = [NSDate dateWithTimeIntervalSince1970:second];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    
    if (second / 3600 >= 1) {
        [formatter setDateFormat:@"HH:mm:ss"];
    } else {
        [formatter setDateFormat:@"mm:ss"];
    }
    NSString *showtimeNew = [formatter stringFromDate:d];
    return showtimeNew;
}

// 实时更新当前时间
- (void)monitoringPlayback:(AVPlayerItem *)playerItem {
    
    __weak typeof(self) __weakSelf = self;
    [self.playerLayer.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:NULL usingBlock:^(CMTime time) {
        CGFloat currentSecond = playerItem.currentTime.value/playerItem.currentTime.timescale;// 计算当前在第几秒
        
        NSString *timeString = [__weakSelf convertTime:currentSecond];
        __weakSelf.videoNowLabel.text = [NSString stringWithFormat:@"%@",timeString];
        __weakSelf.progress.value = currentSecond;
    }];
}

#pragma mark - EventMoth
// 开始点击
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    [super touchesBegan:touches withEvent:event];
    
}

// 手指移动
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    
    CGPoint secondPoint;
    
    for(UITouch *touch in event.allTouches) {
         secondPoint = [touch locationInView:self];
    }
    
    CGFloat verValue = fabs(12 - secondPoint.y);
    
    NSLog(@" X轴 %d Y轴%f ver%F",12,secondPoint.y,verValue);
}

#pragma mark - 返回上一页
- (void)returnUpPage {
    
    if ([self.delegate respondsToSelector:@selector(clickReturnButton:)]) {
        [self.delegate clickReturnButton:self];
    }
}

- (void)willRemoveSubview:(UIView *)subview {
    
    NSLog(@"将要从移除父视图");
    
}

- (void)dealloc {
    
    [self.player pause];

    // 移除监听
    [self.player.currentItem cancelPendingSeeks];
    [self.player.currentItem.asset cancelLoading];
    
    [self.playerLayer removeFromSuperlayer];
    
    [self.playerItem removeObserver:self forKeyPath:@"status"];
    [self.playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [self.playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [self.playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    [self.player replaceCurrentItemWithPlayerItem:nil];
    
    NSLog(@" LTPlayerDealloc");

}
@end
