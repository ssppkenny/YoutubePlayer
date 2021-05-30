//
//  TableViewController.h
//  YoutubePlayer
//
//  Created by Sergey Mikhno on 29.05.21.
//

#ifndef TableViewController_h
#define TableViewController_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface TableViewController : UITableViewController<UIContextMenuInteractionDelegate>
@property (strong) NSMutableArray *songs;
@end

#endif /* TableViewController_h */
