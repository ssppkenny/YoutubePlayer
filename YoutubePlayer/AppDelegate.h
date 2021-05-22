//
//  AppDelegate.h
//  YoutubePlayer
//
//  Created by Sergey Mikhno on 22.05.21.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end

