//
//  TableViewController.m
//  YoutubePlayer
//
//  Created by Sergey Mikhno on 29.05.21.
//

#import "TableViewController.h"
#import "ViewController.h"
#import "AppDelegate.h"
#import <CoreData/CoreData.h>

@implementation ListModel
@synthesize data;
@end

@implementation SongTuple

 @synthesize videoId, title;

@end

@implementation TableViewController

@synthesize songs = _songs;

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"Loaded");
    NSError* error;
    
    NSManagedObjectContext *context = ((AppDelegate*)[[UIApplication sharedApplication] delegate]).persistentContainer.viewContext;
    
    NSEntityDescription* description = [NSEntityDescription entityForName:@"ListModel" inManagedObjectContext:context];
    NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"ListModel"];
    
    NSArray* array =[context executeFetchRequest:request error:&error];
    //for (NSManagedObject* o in array) {
    //    [context deleteObject:o];
    //}
    //[context save:&error];
    
    int length = [array count];
    
    if (length > 0) {
        
        ListModel* listModel = (ListModel*)[array objectAtIndex:0];
        NSData* data = listModel.data;
        _songsMap = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSMutableDictionary class] fromData:data error:&error];
        _songs=  [NSMutableArray arrayWithArray:[_songsMap allKeys]];
        
    } else {
       
    _songs = [NSMutableArray arrayWithArray: @[@"unfzfe8f9NI", @"16y1AkoZkmQ", @"HX_j5Ls0PZA"]];
    NSDictionary *dictionary = [[NSDictionary alloc] initWithObjectsAndKeys:@"ABBA Song", @"unfzfe8f9NI", @"Boney M Rasputin", @"16y1AkoZkmQ", @"Winter Rose Aquarium", @"HX_j5Ls0PZA", nil];
    _songsMap = [NSMutableDictionary dictionaryWithDictionary:dictionary];
        
      
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:_songsMap];
        ListModel *listModel = (ListModel*)[NSEntityDescription insertNewObjectForEntityForName:@"ListModel" inManagedObjectContext:context];
        listModel.data = data;
        
        [context save:&error];
        
        
    }
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _songs.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"Player" sender:self];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"MyIdentifier"];
    NSString *song = [_songs objectAtIndex:indexPath.row];
    NSString *title = [_songsMap objectForKey:song];
    cell.detailTextLabel.text = song;
    cell.textLabel.text = title;
    return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Assume self.view is the table view
    NSIndexPath *path = [self.tableView indexPathForSelectedRow];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:path];
    NSString *text = cell.detailTextLabel.text;
    ViewController *vc = (ViewController*)[segue destinationViewController];
    vc.videoId = text;
    NSLog(@"seque");
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
                    
                    //
                    
                    NSError* error;
                    NSString*title;
                    
                    NSString *yurl = [NSString stringWithFormat:@"https://youtube.com/get_video_info?video_id=%@&ps=default&html5=1&eurl=https://youtube.googleapis.com&hl=en_US", videoId];
                    
                    NSString *request = [self getDataFrom:yurl];
                    NSString *urlString = [request stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
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
                                title = [[videoDetails objectForKey:@"title"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                                break;
                            }
                            
                        }
                        
                    }
                    

                    
                    [self.songsMap setValue:title forKey:videoId];
                    [self.songs addObject:videoId];
                    [tableView reloadData];
                    
                    
                    NSManagedObjectContext *context = ((AppDelegate*)[[UIApplication sharedApplication] delegate]).persistentContainer.viewContext;
                    
                    NSEntityDescription* description = [NSEntityDescription entityForName:@"ListModel" inManagedObjectContext:context];
                    NSFetchRequest* managedrequest = [NSFetchRequest fetchRequestWithEntityName:@"ListModel"];
                    
                    NSArray* array =[context executeFetchRequest:managedrequest error:&error];
                    
                    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:_songsMap];
                    ListModel *listModel = [array objectAtIndex:0];
                    listModel.data = data;
                    [context save:&error];
                        
                    //
                    
                    break;
                }
            }
        }]];
        
        [actions addObject:[UIAction actionWithTitle:@"Delete" image:[UIImage systemImageNamed:@"delete"] identifier:nil handler:^(__kindof UIAction* _Nonnull action) {
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            NSString *cellText = cell.text;
            [self.songs removeObject:cellText];
            [tableView reloadData];
        }]];
        
        UIMenu* menu = [UIMenu menuWithTitle:@"" children:actions];
                return menu;
        
    }];
    
    
    return config;
    
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



@end

