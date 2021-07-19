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
            
            BOOL videoExists = [self checkVideo:videoId];
            if (!videoExists) {
                
                NSString *title_url = [NSString stringWithFormat:@"https://whispering-ocean-22620.herokuapp.com/title/%@", videoId];
                
                [self getDataFromUrl:title_url completionHandler:^(NSData * data, NSURLResponse * response, NSError * error) {
                    NSString *title = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    [self addSong:videoId with:title];
                }];
                
                
               
            }
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

- (void) getDataFromUrl:(NSString*) url completionHandler:(void (^)(NSData * data, NSURLResponse * response, NSError * error))paramCompletionHandlerBlock{
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"GET"];
    [request setURL:[NSURL URLWithString:url]];
    [request setValue:[NSString stringWithFormat:@"%@=%@", @"CONSENT", @"YES+42"] forHTTPHeaderField:@"Cookie"];
    
    NSURLSession *session = [NSURLSession sharedSession];
    
    NSURLSessionDataTask *task  = [session dataTaskWithRequest:request completionHandler:paramCompletionHandlerBlock];
    
    [task resume];
}

-(void)addSong:(NSString*)videoId with:(NSString*) title {
    
    // add song new code
    
    NSString *audio_url = [NSString stringWithFormat:@"http://whispering-ocean-22620.herokuapp.com/download/%@", videoId];
    
        [self.songsMap setValue:title forKey:videoId];
        [self.songs addObject:videoId];
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            NSIndexPath *ipath = [self.tableView indexPathForSelectedRow];
            [self.tableView reloadData];
            [self.tableView selectRowAtIndexPath:ipath animated:NO scrollPosition:UITableViewScrollPositionNone];
            NSError *error;
            
            [self saveContext:&error title:title videoId:videoId];
            
        }];
        
        
        NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                NSUserDomainMask, YES);
        NSString *docsDir = [dirPaths objectAtIndex:0];
        NSString* outPath = [NSString stringWithFormat:OUT_FILE_PATH_FORMAT, docsDir, videoId];
        
        NSString* command = [NSString stringWithFormat:@"-y -i \"%@\" \"%@\"", audio_url, outPath];
        
        //[MobileFFmpegConfig setLogLevel:-8];
        [MobileFFmpeg executeAsync:command withCallback:self];
    
    
    // add song new code
    
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
                    BOOL videoExists = [self checkVideo:videoId];
                    if (!videoExists) {
                        NSString *title_url = [NSString stringWithFormat:@"https://whispering-ocean-22620.herokuapp.com/title/%@", videoId];
                        
                        [self getDataFromUrl:title_url completionHandler:^(NSData * data, NSURLResponse * response, NSError * error) {
                            NSString *title = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                            [self addSong:videoId with:title];
                        }];
                        
                    }
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


- (NSString *)getOutPath:(NSString *)videoId {
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                            NSUserDomainMask, YES);
    NSString *docsDir = [dirPaths objectAtIndex:0];
    NSString *outPath = [NSString stringWithFormat:@"%@/%@.mp3", docsDir, videoId];
    return outPath;
}

- (BOOL)checkVideo:(NSString *)videoId {
    id object = [self.songsMap objectForKey:videoId];
    return object != nil;
    //  NSString * outPath = [self getOutPath:videoId];
    //  NSFileManager* defaultFileManager = [NSFileManager defaultManager];
    //  return [defaultFileManager fileExistsAtPath:outPath];
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

