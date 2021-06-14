//
//  ViewController.m
//  YoutubePlayer
//
//  Created by Sergey Mikhno on 22.05.21.
//

#import "ViewController.h"



NSString *const WATCH_URL_FORMAT = @"https://www.youtube.com/watch?v=%@";




@interface ViewController ()

@end


@implementation ViewController

static AVAudioPlayer* audioPlayer;

+(AVAudioPlayer*)audioPlayer:(NSURL *)url {
    @synchronized (self) {
        NSError *error;
        audioPlayer = [[AVAudioPlayer alloc]
                       initWithContentsOfURL:url
                       error:&error];
    }
    return audioPlayer;
}

+(AVAudioPlayer*)audioPlayer {
    return audioPlayer;
}

static long currentIndex = -1L;
+(long)currentIndex {
    @synchronized (self) {
        return currentIndex;
    }
}
+(void)setCurrentIndex:(long)val {
    @synchronized (self) {
        currentIndex = val;
    }
}
static NSString* currentTitle;
+(NSString*)currentTitle {
    @synchronized (self) {
        return currentTitle;
    }
}

+(void)setCurrentTitle:(NSString*)val {
    @synchronized (self) {
        currentTitle = val;
    }
}


- (void)playMusic {
    
    audioPlayer = [ViewController audioPlayer:self.mp3url];
    
    MPNowPlayingInfoCenter *center = [MPNowPlayingInfoCenter defaultCenter];
    NSDictionary* info = [[NSMutableDictionary alloc] init];
    
    AudioFileID fileID;
    OSStatus result = AudioFileOpenURL((__bridge CFURLRef)self.mp3url, kAudioFileReadPermission, 0, &fileID);
    Float64 outDataSize = 0;
    UInt32 thePropSize = sizeof(Float64);
    result = AudioFileGetProperty(fileID, kAudioFilePropertyEstimatedDuration, &thePropSize, &outDataSize);
    AudioFileClose(fileID);
    
    self.duration = [NSNumber numberWithFloat:outDataSize];
    
    
    [info setValue:self.songName forKey:MPMediaItemPropertyTitle];
    
    
    [info setValue:[NSNumber numberWithFloat:0.0] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
    [info setValue:[NSNumber numberWithFloat:outDataSize] forKey:MPMediaItemPropertyPlaybackDuration];
    [info setValue:[NSNumber numberWithFloat:1.0] forKey:MPNowPlayingInfoPropertyPlaybackRate];
    [info setValue:[NSNumber numberWithFloat:1.0] forKey:MPNowPlayingInfoPropertyDefaultPlaybackRate];
    
    
    [center setNowPlayingInfo:info];
    
    NSLog(@"duration %f", outDataSize);
    
    MPRemoteCommandCenter* sharedCommandCenter = [MPRemoteCommandCenter sharedCommandCenter];
    MPRemoteCommand *playCommand = [sharedCommandCenter playCommand];
    [playCommand addTarget:self action: @selector(onClick:forEvent:)];
    
    MPRemoteCommand *pauseCommand = [sharedCommandCenter pauseCommand];
    [pauseCommand addTarget:self action: @selector(onClick:forEvent:)];
    
    MPRemoteCommand *nextTackCommand = [sharedCommandCenter nextTrackCommand];
    [nextTackCommand addTarget:self action:@selector(onClickStop:forEvent:)];
    
    [playCommand setEnabled:YES];
    [pauseCommand setEnabled:YES];
    [nextTackCommand setEnabled:YES];
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.playButton setEnabled:TRUE] ;
        [self.forwardButton setEnabled:TRUE] ;
        [self.playButton setAlpha: 1.0];
        [self.forwardButton setAlpha: 1.0];
        if ([ViewController currentIndex]  == [self.songs count] - 1) {
            [self.forwardButton setEnabled:FALSE];
            [self.forwardButton setAlpha: 0.5];
        }
    }];
    
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    [session setActive: YES error: nil];
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    }];
    
    
    audioPlayer.delegate = self;
    [audioPlayer prepareToPlay];
    [audioPlayer play];
}

- (NSString *)getSongPath {
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                            NSUserDomainMask, YES);
    NSString *docsDir = [dirPaths objectAtIndex:0];
    NSString* outPath = [NSString stringWithFormat:OUT_FILE_PATH_FORMAT, docsDir, self.videoId];
    return outPath;
}

- (void)playSong {
    
    AVAudioPlayer* player = [ViewController audioPlayer];
    if (player != nil) {
        [player stop];
        [player setCurrentTime:0];
    }
    
    self.songName = [self.songsMap valueForKey:[self.songs objectAtIndex:[ViewController currentIndex]]];
    NSString * outPath = [self getSongPath];
    
    self.mp3url = [NSURL URLWithString: outPath];
    
    [self playMusic];
    
    
}

- (void)onLoad {
    UIImage* stopImage = [UIImage systemImageNamed:@"stop.fill"];
    [self.playButton setImage:stopImage forState:UIControlStateNormal];
    
    self.songName = [self.songsMap valueForKey:[self.songs objectAtIndex:[ViewController currentIndex]]];
    
    if ([ViewController currentIndex]  == [self.songs count]) {
        [self.forwardButton setEnabled:FALSE];
    }
    
    if ([self change]) {
        NSLog(@"loading in viewDidLoad");
        
        [self.playButton setEnabled:FALSE];
        [self.forwardButton setEnabled:FALSE];
        [self.playButton setAlpha: 0.5];
        [self.forwardButton setAlpha: 0.5];
    } else {
        AVAudioPlayer *player = [ViewController audioPlayer];
        if ([player isPlaying]) {
            UIImage* stopImage = [UIImage systemImageNamed:@"stop.fill"];
            [self.playButton setImage:stopImage forState:UIControlStateNormal];
        } else {
            UIImage* playImage = [UIImage systemImageNamed:@"play.fill"];
            [self.playButton setImage:playImage forState:UIControlStateNormal];
        }
        
    }
    
    [self.displayLink invalidate];
    self.displayLink = [[UIScreen mainScreen] displayLinkWithTarget:self selector:@selector(updateProgress)];
    //self.displayLink.frameInterval = 1;
    [self.displayLink addToRunLoop:NSRunLoop.currentRunLoop forMode:NSDefaultRunLoopMode] ;
    
    
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self onLoad];
    
    
}

-(void)updateProgress {
    AVAudioPlayer *_audioPlayer = [ViewController audioPlayer];
    float progress = _audioPlayer.currentTime / _audioPlayer.duration;
    _progressView.progress = progress;
    int minutes = progress*_audioPlayer.duration / 60;
    int seconds = progress*_audioPlayer.duration - 60 * minutes;
    NSString *progressText = [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
    self.progressLabel.text = progressText;
    minutes = _audioPlayer.duration / 60;
    seconds = _audioPlayer.duration - 60 * minutes;
    NSString *durationText = [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
    self.durationLabel.text = durationText;
    //NSLog(@"%d:%d:%f", minutes, seconds, progress);
    
}
- (IBAction)onClick:(UIButton *)sender forEvent:(UIEvent *)event {
    
    
    UIImage* stopImage = [UIImage systemImageNamed:@"stop.fill"];
    
    UIImage* playImage = [UIImage systemImageNamed:@"play.fill"];
    
    AVAudioPlayer *_audioPlayer = [ViewController audioPlayer];
    BOOL playing = [_audioPlayer isPlaying];
    
    MPNowPlayingInfoCenter *center = [MPNowPlayingInfoCenter defaultCenter];
    MPRemoteCommandCenter* sharedCommandCenter = [MPRemoteCommandCenter sharedCommandCenter];
    
    if (playing) {
        if ([sender isKindOfClass:[UIButton class]]) {
            [sender setImage:playImage forState:UIControlStateNormal];
        }
        
        [_audioPlayer stop];
        
        NSDictionary* info = [[NSMutableDictionary alloc] init];
        
        double currentTime = [_audioPlayer currentTime];
        
        [info setValue:self.songName forKey:MPMediaItemPropertyTitle];
        [info setValue:[NSNumber numberWithDouble:currentTime] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
        [info setValue:[NSNumber numberWithFloat:0.0] forKey:MPNowPlayingInfoPropertyPlaybackRate];
        [info setValue:[NSNumber numberWithFloat:0.0] forKey:MPNowPlayingInfoPropertyDefaultPlaybackRate];
        [info setValue:self.duration forKey:MPMediaItemPropertyPlaybackDuration];
        
        [center setNowPlayingInfo:info];
        
        
        MPRemoteCommand *pauseCommand = [sharedCommandCenter pauseCommand];
        [pauseCommand setEnabled:NO];
        MPRemoteCommand *playCommand = [sharedCommandCenter playCommand];
        [playCommand setEnabled:YES];
        
    } else {
        if ([sender isKindOfClass:[UIButton class]]) {
            [sender setImage:stopImage forState:UIControlStateNormal];
        }
        
        [_audioPlayer play];
        MPNowPlayingInfoCenter *center = [MPNowPlayingInfoCenter defaultCenter];
        NSDictionary* info = [[NSMutableDictionary alloc] init];
        [info setValue:self.songName forKey:MPMediaItemPropertyTitle];
        
        double currentTime = [_audioPlayer currentTime];
        
        [info setValue:[NSNumber numberWithDouble:currentTime] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
        [info setValue:[NSNumber numberWithFloat:1.0] forKey:MPNowPlayingInfoPropertyPlaybackRate];
        [info setValue:[NSNumber numberWithFloat:1.0] forKey:MPNowPlayingInfoPropertyDefaultPlaybackRate];
        [info setValue:self.duration forKey:MPMediaItemPropertyPlaybackDuration];
        
        [center setNowPlayingInfo:info];
        
        MPRemoteCommandCenter* sharedCommandCenter = [MPRemoteCommandCenter sharedCommandCenter];
        
        MPRemoteCommand *pauseCommand = [sharedCommandCenter pauseCommand];
        [pauseCommand setEnabled:YES];
        MPRemoteCommand *playCommand = [sharedCommandCenter playCommand];
        [playCommand setEnabled:NO];
    }
    
    MPRemoteCommand *nextTackCommand = [sharedCommandCenter nextTrackCommand];
    [nextTackCommand setEnabled:YES];
    
}

- (IBAction)onClickStop:(UIButton *)sender forEvent:(UIEvent *)event {
    
    
    AVAudioPlayer *_audioPlayer = [ViewController audioPlayer];
    [_audioPlayer stop];
    [ViewController setCurrentIndex:([ViewController currentIndex] + 1)];
    long _currentIndex = ViewController.currentIndex;
    NSUInteger len = [_songs count];
    if (_currentIndex < len) {
        
        NSIndexPath* selectedCellIndexPath= [NSIndexPath indexPathForRow:ViewController.currentIndex inSection:0];
        
        [[self.tableViewController tableView] selectRowAtIndexPath:selectedCellIndexPath animated:TRUE scrollPosition:0];
        long _currentIndex = ViewController.currentIndex;
        self.videoId = _songs[_currentIndex];
        [self.playButton setEnabled:FALSE];
        [self.playButton setAlpha: 0.5];
        [self playSong];
        
    }
    
}

-(void)audioPlayerDidFinishPlaying:
(AVAudioPlayer *)player successfully:(BOOL)flag
{
    
    [ViewController setCurrentIndex:([ViewController currentIndex] + 1)];
    NSIndexPath* selectedCellIndexPath= [NSIndexPath indexPathForRow:ViewController.currentIndex inSection:0];
    
    NSUInteger count = self.tableViewController.songs.count;
    
    if ([ViewController currentIndex] < count) {
        [self.playButton setEnabled:FALSE];
        [self.playButton setAlpha: 0.5];
        [[self.tableViewController tableView] selectRowAtIndexPath:selectedCellIndexPath animated:TRUE scrollPosition:0];
        long _currentIndex = ViewController.currentIndex;
        self.videoId = _songs[_currentIndex];
        [self playSong];
    }
    
}

-(void)audioPlayerDecodeErrorDidOccur:
(AVAudioPlayer *)player error:(NSError *)error
{
    NSLog(@"decode error");
}


@end
