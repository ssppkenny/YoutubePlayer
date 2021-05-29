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





@end

