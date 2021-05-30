//
//  TableViewController.m
//  YoutubePlayer
//
//  Created by Sergey Mikhno on 29.05.21.
//

#import "TableViewController.h"
#import "ViewController.h"

@implementation TableViewController

@synthesize songs = _songs;

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"Loaded");
    _songs = [NSMutableArray arrayWithArray: @[@"unfzfe8f9NI", @"16y1AkoZkmQ", @"HX_j5Ls0PZA"]];
    
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
    cell.textLabel.text = song;
    return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Assume self.view is the table view
    NSIndexPath *path = [self.tableView indexPathForSelectedRow];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:path];
    NSString *text = [cell text];
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
                    NSString *matchString = [string substringWithRange:matchRange];
                    [self.songs addObject:matchString];
                    [tableView reloadData];
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



@end

