//
//  ViewController.m
//  YoutubePlayer
//
//  Created by Sergey Mikhno on 22.05.21.
//

#import "ViewController.h"

@implementation Mapper
@synthesize regex;
@synthesize function;

- (id)initWithregex:(NSRegularExpression *)regex function:(NSString *)function
{
    if (self = [super init]) {
        self.regex = regex;
        self.function = function;
    }
    return self;
}

@end


@interface ViewController ()

@end


void find_function(Mapper* mapper, NSDictionary* dict, NSString* key, NSString* value) {
    NSArray* matches =[mapper.regex matchesInString:value options:0 range:NSMakeRange(0, [value length])];
    for (NSTextCheckingResult *match in matches) {
        [dict setValue:mapper.function forKey:key];
        return;
    }
    return;
}


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle]
                                         pathForResource:@"out"
                                         ofType:@"mp3"]];
    
    NSURL *base_url = [NSURL fileURLWithPath:[[NSBundle mainBundle]
                                              pathForResource:@"base"
                                              ofType:@"js"]];
    
    NSString *fileContents = [NSString stringWithContentsOfFile:[base_url absoluteURL]];
    
    NSError *error;
    _audioPlayer = [[AVAudioPlayer alloc]
                    initWithContentsOfURL:url
                    error:&error];
    
    if (error)
    {
        NSLog(@"Error in audioPlayer: %@",
              [error localizedDescription]);
    } else {
        _audioPlayer.delegate = self;
        [_audioPlayer prepareToPlay];
    }
    
    NSArray *decipherComponents = nil;
    
    Mapper* mapper1 = [[[Mapper alloc] init] initWithregex:[NSRegularExpression regularExpressionWithPattern:@"\\{\\w\\.reverse\\(\\)\\}"
                                                                                                     options:0 error:&error] function:@"reverse" ];
    Mapper* mapper2 = [[[Mapper alloc] init] initWithregex:[NSRegularExpression regularExpressionWithPattern:@"\\{\\w\\.splice\\(0,\\w\\)\\}"
                                                                                                     options:0 error:&error] function:@"splice" ];
    
    Mapper* mapper3 = [[[Mapper alloc] init] initWithregex:[NSRegularExpression regularExpressionWithPattern:@"\\{var\\s\\w=\\w\\[0\\];\\w\\[0\\]=\\w\\[\\w\\%\\w.length\\];\\w\\[\\w\\]=\\w\\}"
                                                                                                     options:0 error:&error] function:@"swap" ];
    
    Mapper* mapper4 = [[[Mapper alloc] init] initWithregex:[NSRegularExpression regularExpressionWithPattern:@"\\{var\\s\\w=\\w\\[0\\];\\w\\[0\\]=\\w\\[\\w\\%\\w.length\\];\\w\\[\\w\\%\\w.length\\]=\\w\\}"
                                                                                                     options:0 error:&error] function:@"swap" ];
    
    NSArray *mappers = @[ mapper1, mapper2, mapper3, mapper4];
    
    
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"(?:\\b|[^a-zA-Z0-9$])([a-zA-Z0-9$]{2})\\s*=\\s*function\\(\\s*a\\s*\\)\\s*\\{\\s*a\\s*=\\s*a\\.split\\(\\s*\"\"\\s*\\)" options:0 error:&error];
    
    NSArray* matches = [regex matchesInString:fileContents options:0 range:NSMakeRange(0, [fileContents length])];
    
    for (NSTextCheckingResult *match in matches)
    {
        NSRange matchRange = [match rangeAtIndex:1];
        NSString *matchString = [fileContents substringWithRange:matchRange];
        
        
        NSString* searchTerm = @"function\\(\\w\\)\\{[a-z=\\.\\(\\\"\\)]*;(.*);(?:.+)\\}";
        
        searchTerm = [NSString stringWithFormat:@"%@=%@", matchString, searchTerm];
        
        regex = [NSRegularExpression regularExpressionWithPattern:searchTerm options:0 error:&error];
        
        NSArray* matches = [regex matchesInString:fileContents options:0 range:NSMakeRange(0, [fileContents length])];
        for (NSTextCheckingResult *match in matches) {
            NSRange matchRange = [match rangeAtIndex:1];
            NSString *matchString = [fileContents substringWithRange:matchRange];
            NSLog(@"%@", matchString);
            decipherComponents = [matchString componentsSeparatedByString:@";"];
            
            regex = [NSRegularExpression regularExpressionWithPattern:@"^\\w+\\W" options:0 error:&error];
            
            NSString* m = [decipherComponents objectAtIndex:0];
            
            NSArray* matches = [regex matchesInString:m options:0 range:NSMakeRange(0, [decipherComponents[0] length])];
            for (NSTextCheckingResult *match in matches) {
                NSRange matchRange = [match rangeAtIndex:0];
                NSString *matchString = [m substringWithRange:matchRange];
                matchString = [matchString substringToIndex:[matchString length] - 1];
                NSLog(@"%@", matchString);
                matchString = [NSString stringWithFormat:@"var %@=\\{(.*?)\\};", matchString];
                
                regex = [NSRegularExpression regularExpressionWithPattern:matchString options:1 << 3 error:&error];
                NSArray* matches = [regex matchesInString:fileContents options:0 range:NSMakeRange(0, [fileContents length])];
                for (NSTextCheckingResult *match in matches) {
                    NSRange matchRange = [match rangeAtIndex:1];
                    NSString *matchString = [fileContents substringWithRange:matchRange];
                    NSLog(@"%@", matchString);
                    
                    matchString =  [matchString stringByReplacingOccurrencesOfString:@"\n"
                                                                          withString:@" "];
                    NSLog(@"%@", matchString);
                    
                    NSArray* components = [matchString componentsSeparatedByString:@", "];
                    
                    NSMutableDictionary *dict = [[NSMutableDictionary alloc]initWithCapacity:10];
                    
                  
                    for (NSString* s in components) {
                        NSArray* mapparts = [s componentsSeparatedByString:@":"];
                        NSString* value = [mapparts objectAtIndex:1];
                        NSString* key = [mapparts objectAtIndex:0];
                        
                        for (Mapper* mapper in mappers) {
                            find_function(mapper, dict, key, value);
                        }
                    }
                    
                }
            }
        }
    }
    
    NSString *yurl = @"https://youtube.com/get_video_info?video_id=Ah392lnFHxM&ps=default&html5=1&eurl=https%3A%2F%2Fyoutube.googleapis.com%2Fv%2FAh392lnFHxM&hl=en_US";
    
    NSString *r = [self getDataFrom:yurl];
    
    NSString *urlString = [r stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSArray *urlComponents = [urlString componentsSeparatedByString:@"&"];
    
    NSDictionary* format = nil;
    
    for (id comp in urlComponents) {
        
        NSString* s = (NSString*)comp;
        if ([s hasPrefix:@"player_response="]) {
            
            
            NSString* player_response =  [s substringFromIndex:16];
            //NSLog(player_response);
            
            NSData *jsonData = [player_response dataUsingEncoding:NSUTF8StringEncoding];
            NSError *error;
            
            //    Note that JSONObjectWithData will return either an NSDictionary or an NSArray, depending whether your JSON string represents an a dictionary or an array.
            id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
            
            if ([jsonObject isKindOfClass:[NSDictionary class]]) {
                NSDictionary *jsonDictionary = (NSDictionary *)jsonObject;
                id streamingData =[jsonDictionary objectForKey:@"streamingData"];
                if ([streamingData isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *jsonDictionary = (NSDictionary*)streamingData;
                    id formats =[jsonDictionary objectForKey:@"formats"];
                    id adaptive_formats =[jsonDictionary objectForKey:@"adaptiveFormats"];
                    
                    if ([formats isKindOfClass:[NSArray class]]) {
                        NSArray* a1 = (NSArray*)formats;
                        for (id e in a1) {
                            NSDictionary* d =  (NSDictionary*)e;
                            NSString* mimeType =[d objectForKey:@"mimeType"];
                            if ([mimeType containsString:@"audio"]) {
                                format = d;
                                break;
                            }
                        }
                    }
                    
                    if ([adaptive_formats isKindOfClass:[NSArray class]]) {
                        NSArray* a1 = (NSArray*)adaptive_formats;
                        for (id e in a1) {
                            NSDictionary* d =  (NSDictionary*)e;
                            NSString* mimeType =[d objectForKey:@"mimeType"];
                            if ([mimeType containsString:@"audio"]) {
                                format = d;
                                break;
                            }
                        }
                    }
                    
                    
                    
                }
            }
            
          
            NSString* signatureCipher = [format objectForKey:@"signatureCipher"];
            
            NSMutableDictionary *queryStringDictionary = [[NSMutableDictionary alloc] init];
            NSArray *urlComponents = [signatureCipher componentsSeparatedByString:@"&"];
            
            for (NSString *keyValuePair in urlComponents) {
                NSArray *pairComponents = [keyValuePair componentsSeparatedByString:@"="];
                NSString *key = [[pairComponents firstObject] stringByRemovingPercentEncoding];
                NSString *value = [[pairComponents lastObject] stringByRemovingPercentEncoding];

                [queryStringDictionary setObject:value forKey:key];
            }
            
            NSLog(format);
            
            
            
        }
        
        
    }
    
}
- (IBAction)onClick:(UIButton *)sender forEvent:(UIEvent *)event {
    
    [_audioPlayer play];
    
}

- (IBAction)onClickStop:(UIButton *)sender forEvent:(UIEvent *)event {
    
    [_audioPlayer stop];
    
}

-(void)audioPlayerDidFinishPlaying:
(AVAudioPlayer *)player successfully:(BOOL)flag
{
}

-(void)audioPlayerDecodeErrorDidOccur:
(AVAudioPlayer *)player error:(NSError *)error
{
}

-(void)audioPlayerBeginInterruption:(AVAudioPlayer *)player
{
}

-(void)audioPlayerEndInterruption:(AVAudioPlayer *)player
{
}

- (NSString *) getDataFrom:(NSString *)url{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"GET"];
    [request setURL:[NSURL URLWithString:url]];
    
    NSError *error = nil;
    NSHTTPURLResponse *responseCode = nil;
    
    NSData *oResponseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&responseCode error:&error];
    
    if([responseCode statusCode] != 200){
        NSLog(@"Error getting %@, HTTP status code %i", url, [responseCode statusCode]);
        return nil;
    }
    
    return [[NSString alloc] initWithData:oResponseData encoding:NSUTF8StringEncoding];
}





@end
