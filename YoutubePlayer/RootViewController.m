//
//  RootViewController.m
//  YoutubePlayer
//
//  Created by Sergey Mikhno on 12.06.21.
//

#import "RootViewController.h"

@interface RootViewController ()

@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    UIViewController *dest = [segue destinationViewController];
    
    if ([dest isKindOfClass:[ViewController class]]) {
        self.viewController = dest;
    }
    
    NSLog(@"Test");
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
