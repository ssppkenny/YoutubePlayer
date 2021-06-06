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
@property (strong) CADisplayLink* displayLink;
@end

@interface SongTuple : NSObject

 @property (copy) NSString *videoId;
 @property (copy) NSString *title;

@end

@interface PlayList : NSManagedObject
@property  (strong) NSString *key;
@property  (strong) NSString *value;
@property  (strong) NSNumber *index;
@end


#endif /* TableViewController_h */
