# LTPlayer
一行代码实现视频播放器，加载网络视频，全屏，快进，实现基本视频播放，后面会不断更新，加入调音量，光线，缓存等功能
# 演示
![] (http://ww4.sinaimg.cn/large/006y8lVagw1f78lwozedgg30ae0j2npf.gif)
# 使用方法
## 初始化传入视频地址，然后设置代理
    LTPlayerView *playerView = [[LTPlayerView alloc]initWithFrame:CGRectMake(0, 20, Video_W, Video_H) videoURL:@"http://183.63.170.167:9000/lms_data/lms/storage/media/fms/ruheyuxiashugoutong_57a2cbfdb8cc9215161964jchce9eitr.mp4"];
    playerView.delegate = self;
    [self.view addSubview:playerView];
## 代理说明

### 加载结束回调 
```
- (void)loadComplete:(LTPlayerView *)playerView;
```
### 播放结束回调  
```
- (void)playComplete:(LTPlayerView *)playerView;
```
### 暂停播放
```
- (void)stopPlayVideo:(LTPlayerView *)playerView;
```
### 视频放大或缩小回调
```
- (void)zoomInAndZoomOut:(LTPlayerView *)playerView zoomType:(LTZoomInOrZoomOutType)zoomType;
```
### 点击返回按钮回调
```
- (void)clickReturnButton:(LTPlayerView *)playerView
```
