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
#import <CoreData/CoreData.h>

@interface TableViewController : UITableViewController<UIContextMenuInteractionDelegate>
@property (strong) NSMutableArray *songs;
@property (strong) NSMutableDictionary *songsMap;
@end

@interface SongTuple : NSObject

 @property (copy) NSString *videoId;
 @property (copy) NSString *title;

@end

@interface ListModel : NSManagedObject
@property (strong) NSData *data;
@end

#endif /* TableViewController_h */
