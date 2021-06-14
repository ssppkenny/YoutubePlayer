//
//  common.h
//  YoutubePlayer
//
//  Created by Sergey Mikhno on 14.06.21.
//

#ifndef common_h
#define common_h

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

static NSString *const OUT_FILE_PATH_FORMAT = @"%@/%@.mp3";

@interface Mapper : NSObject
@property (nonatomic, strong) NSRegularExpression *regex;;
@property (nonatomic, strong) NSString *function;


- (id)initWithregex:(NSRegularExpression *)regex function:(NSString *)function;

@end



void find_function(Mapper* mapper, NSDictionary* dict, NSString* key, NSString* value);

NSArray* reverse(NSArray* arr, int pos);

NSArray* splice(NSArray*arr, int pos);

NSArray* swap(NSArray* arr, int pos);

NSArray* parse_function(NSString* js_func);

NSMutableString* get_signature(NSArray *a_array);

NSArray* convertToArray(NSString* s);




#endif /* common_h */
