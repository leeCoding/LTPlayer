//
//  LTPlayerView.h
//  LTPlayer
//
//  Created by Jonny on 16/8/25.
//  Copyright © 2016年 Jonny. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 *  视频放大或缩小
 */
typedef NS_ENUM(NSInteger , LTZoomInOrZoomOutType) {
    /**
     *  缩小
     */
    LTZoomOutType = 0,
    /**
     *  放大
     */
    LTZoomInType = 1
};

@protocol LTPlayerViewDelegate;

@interface LTPlayerView : UIView

/**
 *  代理
 */
@property (nonatomic,assign)id <LTPlayerViewDelegate> delegate;

/**
 *  初始化 Initialize self
 *
 *  @param frame 位置  Set frame
 *  @param URL   视频链接 Set video url of playerView
 *
 *  @return self
 */
- (instancetype)initWithFrame:(CGRect)frame videoURL:(NSString *)URL;

@end
@protocol LTPlayerViewDelegate <NSObject>

@optional
/**
 *  加载结束回调  Video loading complete delegate
 *
 *  @param playerView self
 */
- (void)loadComplete:(LTPlayerView *)playerView;

/**
 *  播放结束回调  Video play complete delegate
 *
 *  @param playerView self
 */
- (void)playComplete:(LTPlayerView *)playerView;

/**
 *  暂停播放
 *
 *  @param playerView self
 */
- (void)stopPlayVideo:(LTPlayerView *)playerView;

/**
 *  视频放大或缩小回调
 *
 *  @param playerView self
 *  @param zoomType   LTZoomIn > 放大 ，LTZoomOut > 缩小
 */
- (void)zoomInAndZoomOut:(LTPlayerView *)playerView zoomType:(LTZoomInOrZoomOutType)zoomType;

/**
 *  点击返回按钮
 *
 *  @param playerView self
 */
- (void)clickReturnButton:(LTPlayerView *)playerView;

@end
