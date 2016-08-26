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

@interface LTPlayerView ()

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
@property (nonatomic,strong)UIView *actionBarView;          ///< 底部操作栏
@property (nonatomic,strong)UIButton *fullBtn;              ///< 全屏按钮

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
        
        [self steupUI];
    }
    
    return self;
}

- (void)steupUI {
    
    self.playerView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, Video_W, Video_H)];
    self.playerView.backgroundColor = [UIColor whiteColor];
    [self addSubview:self.playerView];
    
    // 操作底栏
    self.actionBarView = [[UIView alloc]initWithFrame:CGRectMake(0, Video_H - 40, Video_W, 40)];
    self.actionBarView.backgroundColor = [UIColor whiteColor];
    self.actionBarView.alpha = 0.5;
    [self.playerView addSubview:self.actionBarView];
    
    // 暂停
    self.stopBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.stopBtn.frame = CGRectMake(0, 5, 40 ,30);
    [self.stopBtn setTitle:@"暂停" forState:0];
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
    self.videoNowLabel.text = @"1:00";
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
    [self.player play];
    
    // 控制进度
    self.progress = [[UISlider alloc]initWithFrame:CGRectMake(self.videoNowLabel.right + 2, 10, Video_W - 146, 20)];
    self.progress.alpha = 1;
    self.progress.thumbTintColor = [UIColor blackColor];
    self.progress.minimumValue = 0;
    [self.progress addTarget:self action:@selector(forwardAndRefund:) forControlEvents:UIControlEventValueChanged];
    [self.actionBarView addSubview:self.progress];
    
    NSDictionary *opts = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO]
                                                     forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    
    AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:URL options:opts];
    float second = 0;
    second = urlAsset.duration.value/urlAsset.duration.timescale;
    NSLog(@"movie duration : %f", second);
    
    // 监听播放资源的状态
    [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    
    // loadedTimeRanges属性监听
    [self.playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    
    // 视屏的总时间
    self.videoDurationLabel = [[UILabel alloc]initWithFrame:CGRectMake(self.progress.right+2, 5,30, 30)];
    self.videoDurationLabel.textColor = [UIColor blackColor];
    self.videoDurationLabel.font = [UIFont systemFontOfSize:10];
    self.videoDurationLabel.textAlignment = NSTextAlignmentCenter;
    [self.actionBarView addSubview:self.videoDurationLabel];
    
    // 全屏按钮
    self.fullBtn  = [UIButton buttonWithType:UIButtonTypeCustom];
    self.fullBtn.frame = CGRectMake(self.videoDurationLabel.right+2, 5, 40, 30) ;
    [self.fullBtn setTitle:@"全屏" forState:0];
    [self.fullBtn setTitleColor:[UIColor blackColor] forState:0];
    self.fullBtn.titleLabel.font = [UIFont systemFontOfSize:12];
    [self.fullBtn addTarget:self action:@selector(fullEvent:) forControlEvents:UIControlEventTouchUpInside];
    [self.actionBarView addSubview:self.fullBtn];
    
    //播放结束通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
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
    self.stopBtn.selected = NO;
    
    // 播放结束代理
    if ([self.delegate respondsToSelector:@selector(playComplete:)]) {
        [self.delegate playComplete:self];
    }
}

#pragma mark - 时间转换
- (NSString *)timeFormatted:(int)totalSeconds {
    
    int seconds = totalSeconds % 60;
    int minutes = totalSeconds / 60;
    NSLog(@" 时间 %@",[NSString stringWithFormat:@"%d:%02d", minutes, seconds]);
    
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
            
            // 旋转底部操作栏
            __weakSelf.actionBarView.transform = CGAffineTransformMakeRotation((0.0f * M_PI) / 180.0f);
            __weakSelf.actionBarView.frame = CGRectMake(0, kScreenWidth - 40, kScreenHeight, 40);
            
            // 控制进度
            __weakSelf.progress.frame = CGRectMake(__weakSelf.videoNowLabel.right + 2, 10, kScreenHeight - 146, 20);
            __weakSelf.videoDurationLabel.frame = CGRectMake(__weakSelf.progress.right + 2, 5,30, 30);
            __weakSelf.fullBtn.frame = CGRectMake(__weakSelf.videoDurationLabel.right + 2, 5, 40, 30);
        }];
        
    } else {
        
        [UIView animateWithDuration:0.5 animations:^{
            
            __weakSelf.transform = CGAffineTransformMakeRotation((0.0f * M_PI) / 180.0f);
            __weakSelf.frame = CGRectMake(0, 20, Video_W,Video_H);
            __weakSelf.playerView.transform = CGAffineTransformMakeRotation((0.0f * M_PI) / 180.0f);
            __weakSelf.playerView.frame = CGRectMake(0, 0, Video_W,Video_H);
            __weakSelf.playerLayer.frame = CGRectMake(0, 0,  Video_W, Video_H);
            __weakSelf.actionBarView.transform = CGAffineTransformMakeRotation((0.0f * M_PI) / 180.0f);
            __weakSelf.actionBarView.frame = CGRectMake(0, Video_H - 40, Video_W, 40);
            
            // 控制返回原来按钮
            __weakSelf.progress.frame = CGRectMake(__weakSelf.videoNowLabel.right + 2, 10, Video_W - 146, 20);
            __weakSelf.videoDurationLabel.frame = CGRectMake(__weakSelf.progress.right + 2, 5,30, 30);
            __weakSelf.fullBtn.frame = CGRectMake(__weakSelf.videoDurationLabel.right + 2, 5, 40, 30);
            
        }];
        
    }
}

#pragma mark - 暂停播放
- (void)stopPlay:(UIButton *)btn {
    
    btn.selected =! btn.selected;
    
    if (btn.selected) {
        
        [self.player pause];
        
        // 暂停播放回调
        if ([self.delegate respondsToSelector:@selector(stopPlayVideo:)]) {
            [self.delegate stopPlayVideo:self];
        }
        
    } else {
        
        [self.player play];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    AVPlayerItem *playerItem = (AVPlayerItem *) object;
    
    if ([keyPath isEqualToString:@"status"]) {
        
        // 1.已经缓存完毕
        if (playerItem.status == AVPlayerItemStatusReadyToPlay) {
            
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
            
        } else if (playerItem.status == AVPlayerItemStatusFailed) {
            
            //2.失败
            
        } else if (playerItem.status == AVPlayerItemStatusUnknown) {
            
            //3.未知状态
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
        
    }  else  {
        
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
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
    if (second/3600 >= 1) {
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

- (void)dealloc {
    
    // 移除监听
    [self removeObserver:self forKeyPath:@"status"];
    [self removeObserver:self forKeyPath:@"loadedTimeRanges"];
    
}
@end
