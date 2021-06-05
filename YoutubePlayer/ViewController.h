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

@interface ViewController : UIViewController<AVAudioPlayerDelegate,ExecuteDelegate>

@property (strong, nonatomic) AVAudioPlayer *audioPlayer;
@property (strong, nonatomic) IBOutlet UILabel *songTitle;
@property (strong, nonatomic) IBOutlet UIButton *playButton;
@property (strong, nonatomic) IBOutlet UIButton *forwardButton;
@property (strong, nonatomic) IBOutlet UIProgressView *progressView;
@property (strong, nonatomic) NSString *videoId;
@property (strong, nonatomic) NSString *songName;
@property (strong, nonatomic) NSURL* mp3url;
@property (strong, nonatomic) NSNumber* duration;

@property (strong) NSMutableArray *songs;
@property (strong) NSMutableDictionary *songsMap;
@property  NSInteger currentIndex;

@end


@interface Mapper : NSObject
@property (nonatomic, strong) NSRegularExpression *regex;;
@property (nonatomic, strong) NSString *function;


- (id)initWithregex:(NSRegularExpression *)regex function:(NSString *)function;

@end




struct sMappers
{
  NSRegularExpression *regex;
  NSString *function;
};

typedef struct sMappers MappersDef;

