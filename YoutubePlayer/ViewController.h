//
//  ViewController.h
//  YoutubePlayer
//
//  Created by Sergey Mikhno on 22.05.21.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <mobileffmpeg/MobileFFmpeg.h>
#import <MediaPlayer/MediaPlayer.h>
#import "TableViewController.h"
#include "common.h"

@interface ViewController : UIViewController<AVAudioPlayerDelegate>

//@property (strong, nonatomic) AVAudioPlayer *audioPlayer;
@property (strong, nonatomic) IBOutlet UIButton *playButton;
@property (strong, nonatomic) IBOutlet UIButton *forwardButton;
@property (strong, nonatomic) IBOutlet UILabel *progressLabel;
@property (strong, nonatomic) IBOutlet UILabel *durationLabel;
@property (strong, nonatomic) IBOutlet UIProgressView *progressView;
@property (strong, nonatomic) NSString *videoId;
@property (strong, nonatomic) NSString *songName;
@property (strong, nonatomic) NSURL* mp3url;
@property (strong, nonatomic) NSNumber* duration;
@property BOOL change;
@property (strong) NSMutableArray *songs;
@property (strong) NSMutableDictionary *songsMap;
@property (strong) CADisplayLink* displayLink;
@property (strong) TableViewController* tableViewController;

+(AVAudioPlayer*)audioPlayer;
+(AVAudioPlayer*)audioPlayer:(NSURL*)url;
+(long)currentIndex;
+(void)setCurrentIndex:(long)val;
+(NSString*)currentTitle;
+(void)setCurrentTitle:(NSString*)val;
-(void)updateProgress;
-(void)playSong;
-(void)onLoad;

@end


struct sMappers
{
  NSRegularExpression *regex;
  NSString *function;
};

typedef struct sMappers MappersDef;

