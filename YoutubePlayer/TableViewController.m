//
//  TableViewController.m
//  YoutubePlayer
//
//  Created by Sergey Mikhno on 29.05.21.
//

#import "TableViewController.h"
#import "ViewController.h"
#import "RootViewController.h"
#import "AppDelegate.h"
#import <CoreData/CoreData.h>



@implementation PlayList

@synthesize key;
@synthesize value;
@synthesize index;
@synthesize name;

@end

@implementation SongTuple

@synthesize videoId, title;

@end

@implementation TableViewController
@synthesize songs;// = _songs;
@synthesize songsMap;// = _songsMap;

- (void)reloadPlaylist: (NSString*) title {
    
    NSManagedObjectContext *context = ((AppDelegate*)[[UIApplication sharedApplication] delegate]).persistentContainer.viewContext;
    
    NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"PlayList"];
    NSError* error;
    NSArray* array =[context executeFetchRequest:request error:&error];
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    NSMutableArray *objects = [[NSMutableArray alloc] init];
    
    for (PlayList *model in array) {
        NSString *k = model.key;
        NSString *v = model.value;
        
        [dict setObject:v forKey:k];
        [objects addObject:model];
    }
    self.songsMap = [NSMutableDictionary dictionaryWithDictionary: dict];
    self.songs = [[NSMutableArray alloc] init];
    
    [objects sortUsingComparator:^NSComparisonResult(PlayList* obj1, PlayList* obj2){
        return [obj1.index compare:obj2.index];
    }];
    
    for (PlayList *p in objects) {
        if ([p.name isEqualToString:title] ) {
            [self.songs addObject:p.key];
        }
    }
    
    [self.tableView reloadData];
}

-(void)checkData {
    NSUserDefaults* userDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.org.youtubeplayer.group" ] ;
    NSString* string = (NSString*)[userDefaults objectForKey:@"mykey"];
    if (string != nil) {
        NSLog(@"string found");
        NSString* videoId;
            
            //"http[s]+://youtu\\.be/(.+)"
            
            NSError *error;
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"http[s]+://youtube\\.com/watch\\?v=(.+)&.+" options:0 error:&error];
            
            NSArray* matches = [regex matchesInString:string options:0 range:NSMakeRange(0, [string length])];
            
            if ([matches count] > 0) {
                NSTextCheckingResult* match = [matches objectAtIndex:0];
                NSRange matchRange = [match rangeAtIndex:1];
                videoId = [string substringWithRange:matchRange];
                [self addSong:videoId];
            }
        
    }
    
    [userDefaults setObject:nil forKey:@"mykey"];
    
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    NSLog(@"added playlist %@", textField.text);
    if (textField.text != nil) {
        self.currentPlaylist = textField.text;
        [self.playlists addObject:textField.text];
        [self reloadPlaylist : textField.text ];
        
        self.picker = [UIAlertController alertControllerWithTitle:@"Choose Playlist" message:@"Choose playlist name" preferredStyle:UIAlertControllerStyleActionSheet];
        for (NSString *title in self.playlists) {
            UIAlertAction* item = [UIAlertAction actionWithTitle:title
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {

                self.currentPlaylist = action.title;
                [self reloadPlaylist: action.title ];
                
                [self.picker dismissViewControllerAnimated:YES completion:nil];
            }];
            
            [self.picker addAction:item];
        }
        
    }
}


-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSArray *items = [self.extensionContext inputItems];
    NSLog(@"items %d", [items count]);
    

    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.displayLink invalidate];
    self.displayLink = [[UIScreen mainScreen] displayLinkWithTarget:self selector:@selector(checkData)];
    //self.displayLink.frameInterval = 1;
    [self.displayLink addToRunLoop:NSRunLoop.currentRunLoop forMode:NSDefaultRunLoopMode] ;
    
    self.currentPlaylist = @"default";
    
    UIContextMenuInteraction *interaction =  [[UIContextMenuInteraction alloc] initWithDelegate:self];
    [self.tableView addInteraction:interaction];
    
    __weak typeof(self) weakSelf = self;
    self.dialog = [UIAlertController alertControllerWithTitle:@"New Playlist" message:@"Enter playlist name" preferredStyle:UIAlertControllerStyleAlert];
    [self.dialog addTextFieldWithConfigurationHandler:^(UITextField *aTextField) {
        aTextField.delegate = weakSelf;
    }];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
        
    }];
    
    
    [self.dialog addAction:defaultAction];
    
    NSError* error;
    
    NSManagedObjectContext *context = ((AppDelegate*)[[UIApplication sharedApplication] delegate]).persistentContainer.viewContext;
    
    NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"PlayList"];
    
    NSArray* array =[context executeFetchRequest:request error:&error];
    //       for (NSManagedObject* o in array) {
    //           [context deleteObject:o];
    //       }
    //      [context save:&error];
    //        array =[context executeFetchRequest:request error:&error];
    //
    //    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
    //                                                            NSUserDomainMask, YES);
    //    NSString *docsDir = [dirPaths objectAtIndex:0];
    //
    //    NSFileManager *fileMgr = [NSFileManager defaultManager];
    //    NSArray *fileArray = [fileMgr contentsOfDirectoryAtPath:docsDir error:nil];
    //    for (NSString *filename in fileArray)  {
    //        if ([filename containsString:@".mp3"]) {
    //            [fileMgr removeItemAtPath:[docsDir stringByAppendingPathComponent:filename] error:NULL];
    //        }
    //    }
    //
    
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    NSMutableArray *objects = [[NSMutableArray alloc] init];
    
    self.songs = [[NSMutableArray alloc] init];
    self.playlists = [[NSMutableSet alloc] init];
    for (PlayList *model in array) {
        NSString *k = model.key;
        NSString *v = model.value;
        if (model.name == nil) {
            [self.playlists addObject:@"default"];
        } else {
            [self.playlists addObject:model.name];
        }
        
        [dict setObject:v forKey:k];
        [objects addObject:model];
    }
    self.songsMap = [NSMutableDictionary dictionaryWithDictionary: dict];
    
    [objects sortUsingComparator:^NSComparisonResult(PlayList* obj1, PlayList* obj2){
        return [obj1.index compare:obj2.index];
    }];
    
    for (PlayList *p in objects) {
        if ([p.name isEqualToString:@"default"] ) {
            [self.songs addObject:p.key];
        }
    }
    
    self.picker = [UIAlertController alertControllerWithTitle:@"Choose Playlist" message:@"Choose playlist name" preferredStyle:UIAlertControllerStyleActionSheet];
    for (NSString *title in self.playlists) {
        UIAlertAction* item = [UIAlertAction actionWithTitle:title
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action) {
          
            self.currentPlaylist = action.title;
            [self reloadPlaylist: action.title ];
            [self.picker dismissViewControllerAnimated:YES completion:nil];
        }];
        
        [self.picker addAction:item];
    }
    
}

- (NSString *)tableView:(UITableView *)tableView
titleForHeaderInSection:(NSInteger)section {
    NSString *title = [NSString stringWithFormat:@"Playlist %@", self.currentPlaylist];
    return title;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return songs.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    RootViewController *controller = (RootViewController*)[self parentViewController];
    
    NSArray *children = [controller childViewControllers];
    ViewController *viewController = nil;
    for (UIViewController *contrl in children) {
        if ([contrl isKindOfClass:[ViewController class]]) {
            viewController = (ViewController*)contrl;
        }
    }
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    viewController.videoId =cell.detailTextLabel.text;
    viewController.songName =cell.textLabel.text;
    
    BOOL change = [ViewController currentIndex] - [indexPath row] != 0 ? TRUE : FALSE;
    
    [ViewController setCurrentIndex:[indexPath row]];
    viewController.change = change;
    viewController.songs = songs;
    viewController.songsMap = songsMap;
    viewController.songName = [viewController.songsMap valueForKey:[viewController.songs objectAtIndex:[ViewController currentIndex]]];
    viewController.tableViewController = self;
    
    [viewController onLoad];
    [viewController playSong];
    
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"MyIdentifier"];
    NSString *song = [songs objectAtIndex:indexPath.row];
    NSString *title = [songsMap objectForKey:song];
    cell.detailTextLabel.textColor = [UIColor whiteColor];
    cell.detailTextLabel.text = song;
    cell.textLabel.text = title;
    NSFileManager *manager = [NSFileManager defaultManager];
    
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                            NSUserDomainMask, YES);
    NSString *docsDir = [dirPaths objectAtIndex:0];
    NSString* outPath = [NSString stringWithFormat:OUT_FILE_PATH_FORMAT, docsDir, song];
    
    BOOL fileExists = [manager fileExistsAtPath:outPath];
    if (!fileExists) {
        cell.userInteractionEnabled = FALSE;
        cell.contentView.alpha = 0.3;
    }
    
    return cell;
}

- (void)saveContext:(NSError **)error title:(NSString *)title videoId:(NSString *)videoId {
    NSManagedObjectContext *context = ((AppDelegate*)[[UIApplication sharedApplication] delegate]).persistentContainer.viewContext;
    
    NSFetchRequest* managedrequest = [NSFetchRequest fetchRequestWithEntityName:@"PlayList"];
    
    int max = 0;
    NSArray* array =[context executeFetchRequest:managedrequest error:error];
    for (PlayList *p in array) {
        if ([p.index intValue] > max) {
            max = p.index.intValue;
        }
    }
    
    PlayList *listModel = (PlayList*)[NSEntityDescription insertNewObjectForEntityForName:@"PlayList" inManagedObjectContext:context];
    
    listModel.key = videoId;
    listModel.value = title;
    listModel.index = [NSNumber numberWithInt:max+1];
    listModel.name = self.currentPlaylist;
    
    [context save:error];
}

-(void)addSong:(NSString*)videoId {
   
    NSString *yurl = [NSString stringWithFormat:@"https://youtube.com/get_video_info?video_id=%@&html5=1&eurl=https://youtube.googleapis.com&c=TVHTML5&cver=6.20180913", videoId];
    
    [self getDataFromUrl:yurl completionHandler:^(NSData * data, NSURLResponse * response, NSError * error) {
        
        NSString *title;
        NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        NSString *urlString = [responseString stringByRemovingPercentEncoding];
        NSArray *origUrlComponents = [urlString componentsSeparatedByString:@"&"];
        
        NSPredicate *bPredicate =
        [NSPredicate predicateWithFormat:@"SELF beginswith 'player_response'"];
        
        NSArray *hasPrefix =
        [origUrlComponents filteredArrayUsingPredicate:bPredicate];
        
        if ([hasPrefix count] > 0) {
            id comp = [hasPrefix objectAtIndex:0];
            NSString* s = (NSString*)comp;
            NSString* player_response =  [s substringFromIndex:16];
            
            NSData *jsonData = [player_response dataUsingEncoding:NSUTF8StringEncoding];
            NSError *error;
            
            id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
            
            if ([jsonObject isKindOfClass:[NSDictionary class]]) {
                NSDictionary *jsonDictionary = (NSDictionary *)jsonObject;
                NSDictionary* videoDetails = [jsonDictionary objectForKey:@"videoDetails"];
                title = [[[videoDetails objectForKey:@"title"] stringByRemovingPercentEncoding]
                         stringByReplacingOccurrencesOfString: @"+" withString:@" "];
                
                [self.songsMap setValue:title forKey:videoId];
                [self.songs addObject:videoId];
                
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    NSIndexPath *ipath = [self.tableView indexPathForSelectedRow];
                    [self.tableView reloadData];
                    [self.tableView selectRowAtIndexPath:ipath animated:NO scrollPosition:UITableViewScrollPositionNone];
                    NSError *error;
                    
                    [self saveContext:&error title:title videoId:videoId];
                    
                }];
                [self loadSong:videoId playerResponse:jsonDictionary];
            }
        }
        
    }];

}

- (UIContextMenuConfiguration *)contextMenuInteraction:(UIContextMenuInteraction *)interaction configurationForMenuAtLocation:(CGPoint)location {
    UIContextMenuConfiguration* config = [UIContextMenuConfiguration configurationWithIdentifier:nil
                                                                                 previewProvider:nil
                                                                                  actionProvider:^UIMenu* _Nullable(NSArray<UIMenuElement*>* _Nonnull suggestedActions) {
        NSMutableArray* actions = [[NSMutableArray alloc] init];
        
        [actions addObject:[UIAction actionWithTitle:@"Paste" image:[UIImage systemImageNamed:@"paste"] identifier:nil handler:^(__kindof UIAction* _Nonnull action) {
            
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            NSString *string = pasteboard.string;
            NSString* videoId;
            if (string!=nil) {
                
                NSError *error;
                NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"http[s]+://youtu\\.be/(.+)" options:0 error:&error];
                
                NSArray* matches = [regex matchesInString:string options:0 range:NSMakeRange(0, [string length])];
                
                if ([matches count] > 0) {
                    NSTextCheckingResult* match = [matches objectAtIndex:0];
                    NSRange matchRange = [match rangeAtIndex:1];
                    videoId = [string substringWithRange:matchRange];
                    [self addSong:videoId];
                }}
        }]];
        
        
        [actions addObject:[UIAction actionWithTitle:@"New Playlist" image:[UIImage systemImageNamed:@"playlist"] identifier:nil handler:^(__kindof UIAction* _Nonnull action) {
            [self presentViewController:self.dialog animated:TRUE completion:nil];
            
        }]];
        
        [actions addObject:[UIAction actionWithTitle:@"Choose Playlist" image:[UIImage systemImageNamed:@"playlist"] identifier:nil handler:^(__kindof UIAction* _Nonnull action) {
            //[self presentViewController:self.dialog animated:TRUE completion:nil];
            [self presentViewController:self.picker animated:TRUE completion:nil];
            
        }]];
        
        UIMenu* menu = [UIMenu menuWithTitle:@"" children:actions];
        return menu;
        
    }];
    
    
    return config;
}

- (UIContextMenuConfiguration*)tableView:(UITableView*)tableView contextMenuConfigurationForRowAtIndexPath:(NSIndexPath*)indexPath point:(CGPoint)point {
    
    UIContextMenuConfiguration* config = [UIContextMenuConfiguration configurationWithIdentifier:nil
                                                                                 previewProvider:nil
                                                                                  actionProvider:^UIMenu* _Nullable(NSArray<UIMenuElement*>* _Nonnull suggestedActions) {
        NSMutableArray* actions = [[NSMutableArray alloc] init];
        
        [actions addObject:[UIAction actionWithTitle:@"Delete" image:[UIImage systemImageNamed:@"delete"] identifier:nil handler:^(__kindof UIAction* _Nonnull action) {
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            NSString *videoId = cell.detailTextLabel.text;
            
            
            [self.songsMap removeObjectForKey:videoId];
            [self.songs removeObject:videoId];
            NSIndexPath *ipath = [self.tableView indexPathForSelectedRow];
            [tableView reloadData];
            [self.tableView selectRowAtIndexPath:ipath animated:NO scrollPosition:UITableViewScrollPositionNone];
            
            NSError *error;
            NSManagedObjectContext *context = ((AppDelegate*)[[UIApplication sharedApplication] delegate]).persistentContainer.viewContext;
            
            NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"PlayList"];
            
            NSArray* array =[context executeFetchRequest:request error:&error];
            
            NSMutableDictionary *counts = [[NSMutableDictionary alloc] init];
            
            for (PlayList *p in array) {
                id count = [counts objectForKey:p.key];
                if (count) {
                    NSNumber *number = (NSNumber*)count;
                    [counts setObject:[NSNumber numberWithInt:[number intValue] + 1] forKey:p.key];
                } else {
                    [counts setObject:[NSNumber numberWithInt:1] forKey:p.key];
                }
                
                if ([p.key isEqualToString:videoId] && [self.currentPlaylist isEqualToString:p.name]) {
                    [context deleteObject:p];
                }
            }
            
            [context save:&error];
            
            NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                    NSUserDomainMask, YES);
            NSString *docsDir = [dirPaths objectAtIndex:0];
            NSString* outPath = [NSString stringWithFormat:OUT_FILE_PATH_FORMAT, docsDir, videoId];
            
            if ([[counts objectForKey:videoId] intValue] == 1) {
                [[NSFileManager defaultManager] removeItemAtPath:outPath error:&error];
            }
           
        }]];
        
        UIMenu* menu = [UIMenu menuWithTitle:@"" children:actions];
        return menu;
        
    }];
    
    
    return config;
    
}

- (void) getDataFromUrl:(NSString*) url completionHandler:(void (^)(NSData * data, NSURLResponse * response, NSError * error))paramCompletionHandlerBlock{
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"GET"];
    [request setURL:[NSURL URLWithString:url]];
    [request setValue:[NSString stringWithFormat:@"%@=%@", @"CONSENT", @"YES+42"] forHTTPHeaderField:@"Cookie"];
    
    NSURLSession *session = [NSURLSession sharedSession];
    
    NSURLSessionDataTask *task  = [session dataTaskWithRequest:request completionHandler:paramCompletionHandlerBlock];
    
    [task resume];
}


- (void)loadSong:(NSString*) videoId playerResponse: (NSDictionary *) jsonDictionary {
    
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                            NSUserDomainMask, YES);
    NSString *docsDir = [dirPaths objectAtIndex:0];
    NSString* outPath = [NSString stringWithFormat:@"%@/%@.mp3", docsDir, videoId];
    
    NSFileManager* defaultFileManager = [NSFileManager defaultManager];
    BOOL videoExists = [defaultFileManager fileExistsAtPath:outPath];
    
    NSString* watch_url = [NSString stringWithFormat:@"https://www.youtube.com/watch?v=%@", videoId];
    [self getDataFromUrl:watch_url completionHandler:^(NSData * data, NSURLResponse * response, NSError * error) {
        NSString *html = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSRegularExpression *base_js_regex = [NSRegularExpression regularExpressionWithPattern:@"(/s/player/[\\w\\d]+/[\\w\\d\\_\\-\\.]+/base\\.js)" options:1 << 3 error:&error];
        
        
        NSArray* base_url_matches = [base_js_regex matchesInString:html options:0 range:NSMakeRange(0, [html length])];
        for (NSTextCheckingResult *match in base_url_matches) {
            NSRange matchRange = [match rangeAtIndex:1];
            NSString *matchString = [html substringWithRange:matchRange];
            NSString* my_base_url = [NSString stringWithFormat:@"https://www.youtube.com%@", matchString];
            
            
            [self getDataFromUrl:my_base_url completionHandler:^(NSData * data, NSURLResponse * response, NSError * error) {
                
                NSString *fileContents = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                
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
                
                for (NSTextCheckingResult *match in matches) {
                    NSRange matchRange = [match rangeAtIndex:1];
                    NSString *matchString = [fileContents substringWithRange:matchRange];
                    
                    
                    NSString* searchTerm = @"function\\(\\w\\)\\{[a-z=\\.\\(\\\"\\)]*;(.*);(?:.+)\\}";
                    searchTerm = [NSString stringWithFormat:@"%@=%@", matchString, searchTerm];
                    regex = [NSRegularExpression regularExpressionWithPattern:searchTerm options:0 error:&error];
                    
                    NSArray* matches = [regex matchesInString:fileContents options:0 range:NSMakeRange(0, [fileContents length])];
                    for (NSTextCheckingResult *match in matches) {
                        NSRange matchRange = [match rangeAtIndex:1];
                        NSString *matchString = [fileContents substringWithRange:matchRange];
                        //NSLog(@"%@", matchString);
                        transform_plan = [matchString componentsSeparatedByString:@";"];
                        
                        regex = [NSRegularExpression regularExpressionWithPattern:@"^\\w+\\W" options:0 error:&error];
                        
                        NSString* m = [transform_plan objectAtIndex:0];
                        
                        NSArray* matches = [regex matchesInString:m options:0 range:NSMakeRange(0, [transform_plan[0] length])];
                        for (NSTextCheckingResult *match in matches) {
                            NSRange matchRange = [match rangeAtIndex:0];
                            NSString *matchString = [m substringWithRange:matchRange];
                            matchString = [matchString substringToIndex:[matchString length] - 1];
                            matchString = [NSString stringWithFormat:@"var %@=\\{(.*?)\\};", matchString];
                            
                            regex = [NSRegularExpression regularExpressionWithPattern:matchString options:1 << 3 error:&error];
                            NSArray* matches = [regex matchesInString:fileContents options:0 range:NSMakeRange(0, [fileContents length])];
                            for (NSTextCheckingResult *match in matches) {
                                NSRange matchRange = [match rangeAtIndex:1];
                                NSString *matchString = [fileContents substringWithRange:matchRange];
                                
                                matchString =  [matchString stringByReplacingOccurrencesOfString:@"\n"
                                                                                      withString:@" "];
                                
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
                if (!videoExists) {
                    [self songFromPlayerResponse:jsonDictionary transform_map:transform_map transform_plan:transform_plan outpath:outPath];
                }
            }];
            
            break;
        }
        
        
    }];
    
}

- (void)find_format:(NSDictionary **)audio_format formats:(id)formats key:(NSString*)name {
    if ([formats isKindOfClass:[NSArray class]]) {
        NSArray* a1 = (NSArray*)formats;
        for (id e in a1) {
            NSDictionary* d =  (NSDictionary*)e;
            NSString* mimeType =[d objectForKey:@"mimeType"];
            if ([mimeType containsString:name]) {
                *audio_format = d;
                return;
            }
        }
    }
}

- (void)decrypt_url:(NSString **)audio_url signatureCipher:(NSString **)signatureCipher transform_map:(NSMutableDictionary *)transform_map transform_plan:(NSArray *)transform_plan {
    NSMutableDictionary *queryStringDictionary = [[NSMutableDictionary alloc] init];
    NSArray *urlComponents = [*signatureCipher componentsSeparatedByString:@"&"];
    
    for (NSString *keyValuePair in urlComponents) {
        NSArray *pairComponents = [keyValuePair componentsSeparatedByString:@"="];
        NSString *key = [[pairComponents firstObject] stringByRemovingPercentEncoding];
        NSString *value = [[pairComponents lastObject] stringByRemovingPercentEncoding];
        
        [queryStringDictionary setObject:value forKey:key];
    }
    
    NSString* s = [queryStringDictionary objectForKey:@"s"];
    
    NSArray* signature = convertToArray(s);
    
    *signatureCipher = [*signatureCipher stringByRemovingPercentEncoding];
    queryStringDictionary = [[NSMutableDictionary alloc] init];
    urlComponents = [*signatureCipher componentsSeparatedByString:@"&"];
    
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
    *audio_url = [NSString stringWithFormat:@"%@&sig=%@&%@", new_url, sig, mutableString];
}


-(void)songFromPlayerResponse: (NSDictionary*) jsonDictionary transform_map: (NSMutableDictionary *) transform_map transform_plan: (NSArray *) transform_plan outpath: (NSString*) outPath {
    
    id streamingData =[jsonDictionary objectForKey:@"streamingData"];
    NSDictionary* audio_format = nil;
    
    if ([streamingData isKindOfClass:[NSDictionary class]]) {
        NSDictionary *jsonDictionary = (NSDictionary*)streamingData;
        id formats =[jsonDictionary objectForKey:@"formats"];
        id adaptive_formats =[jsonDictionary objectForKey:@"adaptiveFormats"];
        
        [self find_format:&audio_format formats:formats key:@"audio"];
        
        [self find_format:&audio_format formats:adaptive_formats key:@"audio"];
    }
    
    NSString* audio_url;
    
    NSString* signatureCipher = [audio_format objectForKey:@"signatureCipher"];
    
    if (signatureCipher != nil) {
        [self decrypt_url:&audio_url signatureCipher:&signatureCipher transform_map:transform_map transform_plan:transform_plan];
        
    } else {
        audio_url =  [audio_format objectForKey:@"url"];
    }
    
    
    NSString* command = [NSString stringWithFormat:@"-y -i \"%@\" \"%@\"", audio_url, outPath];
    
    //[MobileFFmpegConfig setLogLevel:-8];
    [MobileFFmpeg executeAsync:command withCallback:self];
    
}

- (void)executeCallback:(long)executionId :(int)rc {
    if (rc == RETURN_CODE_SUCCESS) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            NSIndexPath *ipath = [self.tableView indexPathForSelectedRow];
            [self.tableView reloadData];
            [self.tableView selectRowAtIndexPath:ipath animated:NO scrollPosition:UITableViewScrollPositionNone];
            NSInteger rows =[self.tableView numberOfRowsInSection:0];
            
            for (NSInteger i=0; i<rows; i++) {
                NSIndexPath* selectedCellIndexPath= [NSIndexPath indexPathForRow:i inSection:0];
                
                UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:selectedCellIndexPath];
                cell.userInteractionEnabled = TRUE;
                cell.contentView.alpha = 1.0;
                
            }
        }];
    } else {
        NSLog(@"Error converting file");
    }
    
}



@end

