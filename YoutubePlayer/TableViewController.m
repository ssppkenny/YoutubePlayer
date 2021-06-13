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

@end

@implementation SongTuple

@synthesize videoId, title;

@end

@implementation TableViewController

@synthesize songs;// = _songs;
@synthesize songsMap;// = _songsMap;

- (void)viewDidLoad {
    [super viewDidLoad];
    NSError* error;
    
    NSManagedObjectContext *context = ((AppDelegate*)[[UIApplication sharedApplication] delegate]).persistentContainer.viewContext;
    
    NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"PlayList"];
    
    NSArray* array =[context executeFetchRequest:request error:&error];
    //   for (NSManagedObject* o in array) {
    //       [context deleteObject:o];
    //   }
    //  [context save:&error];
    //    array =[context executeFetchRequest:request error:&error];
    
    NSUInteger length = [array count];
    
    if (length > 0) {
        
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        NSMutableArray *objects = [[NSMutableArray alloc] init];
        
        self.songs = [[NSMutableArray alloc] init];
        for (PlayList *model in array) {
            NSString *k = model.key;
            NSString *v = model.value;
            [dict setObject:v forKey:k];
            [objects addObject:model];
        }
        self.songsMap = [NSMutableDictionary dictionaryWithDictionary: dict];
        
        [objects sortUsingComparator:^NSComparisonResult(PlayList* obj1, PlayList* obj2){
            return [obj1.index compare:obj2.index];
        }];
        
        for (PlayList *p in objects) {
            [self.songs addObject:p.key];
        }
        
        
    } else {
        
        self.songs = [NSMutableArray arrayWithArray: @[@"unfzfe8f9NI", @"16y1AkoZkmQ", @"HX_j5Ls0PZA"]];
        NSDictionary *dictionary = [[NSDictionary alloc] initWithObjectsAndKeys:@"ABBA Mamma Mia", @"unfzfe8f9NI", @"Boney M Rasputin", @"16y1AkoZkmQ", @"ЗИМНЯЯ РОЗА", @"HX_j5Ls0PZA", nil];
        self.songsMap = [NSMutableDictionary dictionaryWithDictionary:dictionary];
        
        int i = 1;
        for(NSString* key in self.songsMap) {
            PlayList *listModel = (PlayList*)[NSEntityDescription insertNewObjectForEntityForName:@"PlayList" inManagedObjectContext:context];
            listModel.key = key;
            listModel.value = [self.songsMap objectForKey:key];
            listModel.index = [NSNumber numberWithInt:i] ;
            i++;
        }
        
        [context save:&error];
        
    }
    
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
    [viewController loadSong];
    
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"MyIdentifier"];
    NSString *song = [songs objectAtIndex:indexPath.row];
    NSString *title = [songsMap objectForKey:song];
    cell.detailTextLabel.textColor = [UIColor whiteColor];
    cell.detailTextLabel.text = song;
    cell.textLabel.text = title;
    return cell;
}

- (UIContextMenuConfiguration*)tableView:(UITableView*)tableView contextMenuConfigurationForRowAtIndexPath:(NSIndexPath*)indexPath point:(CGPoint)point {
    
    UIContextMenuConfiguration* config = [UIContextMenuConfiguration configurationWithIdentifier:nil
                                                                                 previewProvider:nil
                                                                                  actionProvider:^UIMenu* _Nullable(NSArray<UIMenuElement*>* _Nonnull suggestedActions) {
        NSMutableArray* actions = [[NSMutableArray alloc] init];
        
        [actions addObject:[UIAction actionWithTitle:@"Paste" image:[UIImage systemImageNamed:@"paste"] identifier:nil handler:^(__kindof UIAction* _Nonnull action) {
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            NSString *string = pasteboard.string;
            if (string!=nil) {
                
                NSError *error;
                NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"http[s]+://youtu\\.be/(.+)" options:0 error:&error];
                
                NSArray* matches = [regex matchesInString:string options:0 range:NSMakeRange(0, [string length])];
                for (NSTextCheckingResult *match in matches) {
                    NSRange matchRange = [match rangeAtIndex:1];
                    NSString *videoId = [string substringWithRange:matchRange];
                    
                    NSString *yurl = [NSString stringWithFormat:@"https://youtube.com/get_video_info?video_id=%@&ps=default&html5=1&eurl=https://youtube.googleapis.com&hl=en_US", videoId];
                    
                    [self getDataFromUrl:yurl completionHandler:^(NSData * data, NSURLResponse * response, NSError * error) {
                        
                        NSString *title;
                        
                        NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                        
                        NSString *urlString = [responseString stringByRemovingPercentEncoding];
                        NSArray *origUrlComponents = [urlString componentsSeparatedByString:@"&"];
                        
                        
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
                                    NSDictionary* videoDetails = [jsonDictionary objectForKey:@"videoDetails"];
                                    title = [[[videoDetails objectForKey:@"title"] stringByRemovingPercentEncoding]
                                             stringByReplacingOccurrencesOfString: @"+" withString:@" "];
                                    
                                    [self.songsMap setValue:title forKey:videoId];
                                    [self.songs addObject:videoId];
                                    
                                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                        [tableView reloadData];
                                        NSError *error;
                                        NSLog(@"title = %@", title);
                                        NSLog(@"videoId = %@", videoId);
                                        
                                        
                                        NSManagedObjectContext *context = ((AppDelegate*)[[UIApplication sharedApplication] delegate]).persistentContainer.viewContext;
                                        
                                        NSFetchRequest* managedrequest = [NSFetchRequest fetchRequestWithEntityName:@"PlayList"];
                                        
                                        int max = 0;
                                        NSArray* array =[context executeFetchRequest:managedrequest error:&error];
                                        for (PlayList *p in array) {
                                            if ([p.index intValue] > max) {
                                                max = p.index.intValue;
                                            }
                                        }
                                        
                                        PlayList *listModel = (PlayList*)[NSEntityDescription insertNewObjectForEntityForName:@"PlayList" inManagedObjectContext:context];
                                        
                                        listModel.key = videoId;
                                        listModel.value = title;
                                        listModel.index = [NSNumber numberWithInt:max+1];
                                        
                                        [context save:&error];
                                        
                                    }];
                                    
                                    break;
                                }
                                
                            }
                            
                        }
                        
                        
                    }];
                    
                    break;
                }
            }
        }]];
        
        [actions addObject:[UIAction actionWithTitle:@"Delete" image:[UIImage systemImageNamed:@"delete"] identifier:nil handler:^(__kindof UIAction* _Nonnull action) {
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            NSString *videoId = cell.detailTextLabel.text;
            
            
            [self.songsMap removeObjectForKey:videoId];
            [self.songs removeObject:videoId];
            [tableView reloadData];
            
            NSError *error;
            NSManagedObjectContext *context = ((AppDelegate*)[[UIApplication sharedApplication] delegate]).persistentContainer.viewContext;
            
            NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"PlayList"];
            
            NSArray* array =[context executeFetchRequest:request error:&error];
            
            for (PlayList *p in array) {
                if ([p.key isEqualToString:videoId]) {
                    [context deleteObject:p];
                }
            }
            
            [context save:&error];
            
            
            
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




@end

