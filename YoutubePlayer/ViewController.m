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

NSArray* convertToArray(NSString* s)
{
    NSMutableArray *arr = [[NSMutableArray alloc]init];
    for (int i=0; i < s.length; i++) {
        NSString *tmp_str = [s substringWithRange:NSMakeRange(i, 1)];
        [arr addObject:[tmp_str stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    }
    return arr;
}


void find_function(Mapper* mapper, NSDictionary* dict, NSString* key, NSString* value) {
    NSArray* matches =[mapper.regex matchesInString:value options:0 range:NSMakeRange(0, [value length])];
    for (NSTextCheckingResult *match in matches) {
        [dict setValue:mapper.function forKey:key];
        return;
    }
    return;
}

NSArray* reverse(NSArray* arr, int pos) {
    NSArray *reversedArray = [[arr reverseObjectEnumerator] allObjects];
    return reversedArray;
}

NSArray* splice(NSArray*arr, int pos) {
    NSUInteger length = [arr count];
    NSArray* result = [arr subarrayWithRange:NSMakeRange(pos, length - pos)];
    return result;
}

NSArray* swap(NSArray* arr, int pos) {
    NSMutableArray *ar1update = [arr mutableCopy];
    NSUInteger r =  pos % [arr count];
    id obj1 = [arr objectAtIndex:0];
    id obj2 = [arr objectAtIndex:r];
    id temp = obj1;
    ar1update[0] = obj2;
    ar1update[pos] = temp;
    arr = [NSArray arrayWithArray:ar1update];
    return arr;
}

NSArray* parse_function(NSString* js_func) {
    NSError *error;
    NSRegularExpression* expr1 = [NSRegularExpression regularExpressionWithPattern:@"\\w+\\.(\\w+)\\(\\w,(\\d+)\\)" options:0 error:&error];
    NSRegularExpression* expr2 = [NSRegularExpression regularExpressionWithPattern:@"\\w+\\[(\\\"\\w+\\\")\\]\\(\\w,(\\d+)\\)" options:0 error:&error];
    NSArray* js_func_patterns = @[expr1, expr2];
    
    for (NSRegularExpression* expr in js_func_patterns) {
        NSArray* matches = [expr matchesInString:js_func options:0 range:NSMakeRange(0, [js_func length])];
        if ([matches count] > 0) {
            NSTextCheckingResult *match1 = [matches objectAtIndex:0];
            NSRange matchRange = [match1 rangeAtIndex:1];
            NSString *func= [js_func substringWithRange:matchRange];
            matchRange = [match1 rangeAtIndex:2];
            NSString *arg= [js_func substringWithRange:matchRange];
            return @[func, arg];
        }
    }
    
    return @[];
    
    
}

NSMutableString* get_signature(NSArray *a_array)
{
    NSUInteger count = [a_array count];
    NSMutableString *mutableString = [NSMutableString stringWithCapacity:count];
    
    for (unsigned i = 0; i < count; i++)
    {
        [mutableString appendString:[a_array objectAtIndex:i]] ;
    }
    
    return mutableString;
    
}


@implementation ViewController
- (void)executeCallback:(long)executionId :(int)rc {
    if (rc == RETURN_CODE_SUCCESS) {
        NSError *error;
        NSLog(@"Async command execution completed successfully.\n");
        _audioPlayer = [[AVAudioPlayer alloc]
                        initWithContentsOfURL:self.mp3url
                        error:&error];
      
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
        [pauseCommand addTarget:self action: @selector(onClickStop:forEvent:)];
        
        
       
        if (error)
        {
            NSLog(@"Error in audioPlayer: %@",
                  [error localizedDescription]);
        } else {
            
            _audioPlayer.delegate = self;
            [_audioPlayer prepareToPlay];
        }
        
        
    } else if (rc == RETURN_CODE_CANCEL) {
        NSLog(@"Async command execution cancelled by user.\n");
    } else {
        NSLog(@"Async command execution failed with rc=%d.\n", rc);
    }
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                            NSUserDomainMask, YES);
    
    NSString *docsDir = [dirPaths objectAtIndex:0];
    NSString* outPath = [NSString stringWithFormat:@"%@/out.mp3", docsDir];
    NSString* base_js_path = [NSString stringWithFormat:@"%@/base.js", docsDir];
    

    NSError* error;
    
    NSString* watch_url = [NSString stringWithFormat:@"https://www.youtube.com/watch?v=%@", self.videoId];
    NSString *html= [self getDataFrom:watch_url];
    
    NSRegularExpression *base_js_regex = [NSRegularExpression regularExpressionWithPattern:@"(/s/player/[\\w\\d]+/[\\w\\d\\_\\-\\.]+/base\\.js)" options:1 << 3 error:&error];
    

    NSArray* base_url_matches = [base_js_regex matchesInString:html options:0 range:NSMakeRange(0, [html length])];
    for (NSTextCheckingResult *match in base_url_matches) {
        NSRange matchRange = [match rangeAtIndex:1];
        NSString *matchString = [html substringWithRange:matchRange];
        NSString* my_base_url = [NSString stringWithFormat:@"https://www.youtube.com%@", matchString];
        [self downloadFrom:my_base_url toFile:base_js_path];
        break;
    }
    
    NSString *fileContents = [NSString stringWithContentsOfFile:base_js_path encoding:NSUTF8StringEncoding error:&error];
    
   
    NSArray *transform_plan = nil;
    
    Mapper* mapper1 = [[[Mapper alloc] init] initWithregex:[NSRegularExpression regularExpressionWithPattern:@"\\{\\w\\.reverse\\(\\)\\}"
                                                                                                     options:0 error:&error] function:@"reverse" ];
    Mapper* mapper2 = [[[Mapper alloc] init] initWithregex:[NSRegularExpression regularExpressionWithPattern:@"\\{\\w\\.splice\\(0,\\w\\)\\}"
                                                                                                     options:0 error:&error] function:@"splice" ];
    
    Mapper* mapper3 = [[[Mapper alloc] init] initWithregex:[NSRegularExpression regularExpressionWithPattern:@"\\{var\\s\\w=\\w\\[0\\];\\w\\[0\\]=\\w\\[\\w\\%\\w.length\\];\\w\\[\\w\\]=\\w\\}"
                                                                                                     options:0 error:&error] function:@"swap" ];
    
    Mapper* mapper4 = [[[Mapper alloc] init] initWithregex:[NSRegularExpression regularExpressionWithPattern:@"\\{var\\s\\w=\\w\\[0\\];\\w\\[0\\]=\\w\\[\\w\\%\\w.length\\];\\w\\[\\w\\%\\w.length\\]=\\w\\}"
                                                                                                     options:0 error:&error] function:@"swap" ];
    
    NSArray *mappers = @[ mapper1, mapper2, mapper3, mapper4];
    
    NSMutableDictionary *transform_map = [[NSMutableDictionary alloc]initWithCapacity:10];
    
    
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
            transform_plan = [matchString componentsSeparatedByString:@";"];
            
            regex = [NSRegularExpression regularExpressionWithPattern:@"^\\w+\\W" options:0 error:&error];
            
            NSString* m = [transform_plan objectAtIndex:0];
            
            NSArray* matches = [regex matchesInString:m options:0 range:NSMakeRange(0, [transform_plan[0] length])];
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
                    
                    for (NSString* s in components) {
                        NSArray* mapparts = [s componentsSeparatedByString:@":"];
                        NSString* value = [mapparts objectAtIndex:1];
                        NSString* key = [mapparts objectAtIndex:0];
                        
                        for (Mapper* mapper in mappers) {
                            find_function(mapper, transform_map, key, value);
                        }
                    }
                    
                }
            }
        }
    }
    
    
    
    NSString *yurl = [NSString stringWithFormat:@"https://youtube.com/get_video_info?video_id=%@&ps=default&html5=1&eurl=https://youtube.googleapis.com&hl=en_US", self.videoId];
    
    NSString *request = [self getDataFrom:yurl];
    NSString *urlString = [request stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSArray *origUrlComponents = [urlString componentsSeparatedByString:@"&"];
    
    NSDictionary* format = nil;
    
    for (id comp in origUrlComponents) {
        
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
                NSDictionary* videoDetails = [jsonDictionary objectForKey:@"videoDetails"];
                _songTitle.text = [[videoDetails objectForKey:@"title"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                _songName = _songTitle.text;
                _songTitle.lineBreakMode = NSLineBreakByWordWrapping;
                _songTitle.numberOfLines = 0;
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
            
            NSString* s = [queryStringDictionary objectForKey:@"s"];
            
            NSArray* signature = convertToArray(s);
            
            signatureCipher = [signatureCipher stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            queryStringDictionary = [[NSMutableDictionary alloc] init];
            urlComponents = [signatureCipher componentsSeparatedByString:@"&"];
            
            for (NSString *keyValuePair in urlComponents) {
                NSArray *pairComponents = [keyValuePair componentsSeparatedByString:@"="];
                
                NSMutableString *mutableString = [NSMutableString stringWithCapacity:100];
                NSUInteger size =[pairComponents count];
                for (int i=1; i<size; i++) {
                    NSString* part = [pairComponents objectAtIndex:i];
                    if (i<size-1) {
                        NSString* s = [NSString stringWithFormat:@"%@=", part];
                        [mutableString appendString:s];
                    } else {
                        NSString* s = [NSString stringWithFormat:@"%@", part];
                        [mutableString appendString:s];
                    }
                    
                }
                
                NSString *key = [[pairComponents firstObject] stringByRemovingPercentEncoding];
                NSString *value = [mutableString stringByRemovingPercentEncoding];
                
                [queryStringDictionary setObject:value forKey:key];
            }
            
            for (NSString* js_func in transform_plan) {
                NSArray* farr = parse_function(js_func);
                NSString* name = [farr objectAtIndex:0];
                int arg = [[farr objectAtIndex:1] intValue];
                NSString* transform_key = [transform_map objectForKey:name];
                
                if ([transform_key isEqualToString:@"reverse"]) {
                    signature = reverse(signature, arg);
                } else if ([transform_key isEqualToString:@"swap"]) {
                    signature = swap(signature, arg);
                } else if ([transform_key isEqualToString:@"splice"]) {
                    signature = splice(signature, arg);
                }
            }

            
            NSMutableString* sig = get_signature(signature);
            
            NSMutableString *mutableString = [NSMutableString stringWithCapacity:[sig length]];
            
            NSString *new_url = nil;
            
            NSEnumerator *enumerator = [queryStringDictionary keyEnumerator];
            id key;
            // extra parens to suppress warning about using = instead of ==
            while((key = [enumerator nextObject])) {
                NSString* value = [queryStringDictionary objectForKey:key];
                if ([key isEqualToString:@"url"]) {
                    new_url = value;
                } else if(![key isEqualToString:@"url"] && ![key isEqualToString:@"s"]) {
                    NSString* c = [NSString stringWithFormat:@"&%@=%@", key, value];
                    [mutableString appendString:c];
                }
            }
            
            
            NSString* new_query = [NSString stringWithFormat:@"%@&sig=%@&%@", new_url, sig, mutableString];
            NSString* command = [NSString stringWithFormat:@"-y -flush_packets 1 -packetsize 512k  -i \"%@\" \"%@\"", new_query, outPath];
            
            [MobileFFmpeg executeAsync:command withCallback:self];
            
           
            self.mp3url = [NSURL URLWithString:outPath];
            
            AVAudioSession *session = [AVAudioSession sharedInstance];
            [session setCategory:AVAudioSessionCategoryPlayback error:nil];
            [session setActive: YES error: nil];
            [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
            
         
            
        }
        
        
    }
    
}
- (IBAction)onClick:(UIButton *)sender forEvent:(UIEvent *)event {
    
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

- (IBAction)onClickStop:(UIButton *)sender forEvent:(UIEvent *)event {
    
    [_audioPlayer stop];
    MPNowPlayingInfoCenter *center = [MPNowPlayingInfoCenter defaultCenter];
    NSDictionary* info = [[NSMutableDictionary alloc] init];
    
    double currentTime = [_audioPlayer currentTime];
    
    [info setValue:self.songName forKey:MPMediaItemPropertyTitle];
    [info setValue:[NSNumber numberWithDouble:currentTime] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
    [info setValue:[NSNumber numberWithFloat:0.0] forKey:MPNowPlayingInfoPropertyPlaybackRate];
    [info setValue:[NSNumber numberWithFloat:0.0] forKey:MPNowPlayingInfoPropertyDefaultPlaybackRate];
    [info setValue:self.duration forKey:MPMediaItemPropertyPlaybackDuration];
    
    [center setNowPlayingInfo:info];
    
    MPRemoteCommandCenter* sharedCommandCenter = [MPRemoteCommandCenter sharedCommandCenter];
   
    MPRemoteCommand *pauseCommand = [sharedCommandCenter pauseCommand];
    [pauseCommand setEnabled:NO];
    MPRemoteCommand *playCommand = [sharedCommandCenter playCommand];
    [playCommand setEnabled:YES];
    
    
}

-(void)audioPlayerDidFinishPlaying:
(AVAudioPlayer *)player successfully:(BOOL)flag
{
    NSLog(@"finished playing");
}

-(void)audioPlayerDecodeErrorDidOccur:
(AVAudioPlayer *)player error:(NSError *)error
{
}

-(void)audioPlayerBeginInterruption:(AVAudioPlayer *)player
{
    NSLog(@"begin interruption");
}

-(void)audioPlayerEndInterruption:(AVAudioPlayer *)player
{
    NSLog(@"end interruption");
}

- (NSString *) getDataFrom:(NSString *)url{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"GET"];
    [request setURL:[NSURL URLWithString:url]];
    
    
    [request setValue:[NSString stringWithFormat:@"%@=%@", @"CONSENT", @"YES+42"] forHTTPHeaderField:@"Cookie"];
    
    NSError *error = nil;
    NSHTTPURLResponse *responseCode = nil;

    NSData *oResponseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&responseCode error:&error];
    
    if([responseCode statusCode] != 200){
        NSLog(@"Error getting %@, HTTP status code %i", url, [responseCode statusCode]);
        return nil;
    }
    return [[NSString alloc] initWithData:oResponseData encoding:NSUTF8StringEncoding];
}

- (void) downloadFrom:(NSString *)url toFile:(NSString*)path {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"GET"];
    [request setURL:[NSURL URLWithString:url]];
    
    
    [request setValue:[NSString stringWithFormat:@"%@=%@", @"CONSENT", @"YES+42"] forHTTPHeaderField:@"Cookie"];
    
    NSError *error = nil;
    NSHTTPURLResponse *responseCode = nil;

    NSData *oResponseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&responseCode error:&error];
    [oResponseData writeToFile:path atomically:TRUE];
    
}




@end
