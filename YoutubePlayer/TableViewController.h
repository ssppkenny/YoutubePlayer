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
#import <mobileffmpeg/MobileFFmpeg.h>

@interface TableViewController : UITableViewController<UIContextMenuInteractionDelegate,ExecuteDelegate,UITextFieldDelegate>

@property (strong) NSMutableArray *songs;
@property (strong) NSMutableSet *playlists;
@property (strong) NSString *currentPlaylist;
@property (strong) NSMutableDictionary *songsMap;
@property (strong) CADisplayLink* displayLink;
@property (strong) UIAlertController *dialog;
@property (strong) UIAlertController *picker;
@end

@interface SongTuple : NSObject

 @property (copy) NSString *videoId;
 @property (copy) NSString *title;

@end

@interface PlayList : NSManagedObject
@property  (strong) NSString *key;
@property  (strong) NSString *value;
@property  (strong) NSNumber *index;
@property  (strong) NSString *name;
@end


#endif /* TableViewController_h */
