//
//  common.m
//  YoutubePlayer
//
//  Created by Sergey Mikhno on 14.06.21.
//

#import <Foundation/Foundation.h>
#import "common.h"


void find_function(Mapper* mapper, NSDictionary* dict, NSString* key, NSString* value) {
    NSArray* matches =[mapper.regex matchesInString:value options:0 range:NSMakeRange(0, [value length])];
    for (NSTextCheckingResult *match in matches) {
        [dict setValue:mapper.function forKey:key];
        return;
    }
    return;
}

NSArray* reverse(NSArray* arr, int pos) {
    NSArray *reversedArray = [[arr reverseObjectEnumerator] allObjects];
    return reversedArray;
}

NSArray* splice(NSArray*arr, int pos) {
    NSUInteger length = [arr count];
    NSArray* result = [arr subarrayWithRange:NSMakeRange(pos, length - pos)];
    return result;
}

NSArray* swap(NSArray* arr, int pos) {
    NSMutableArray *ar1update = [arr mutableCopy];
    NSUInteger r =  pos % [arr count];
    id obj1 = [arr objectAtIndex:0];
    id obj2 = [arr objectAtIndex:r];
    id temp = obj1;
    ar1update[0] = obj2;
    ar1update[pos] = temp;
    arr = [NSArray arrayWithArray:ar1update];
    return arr;
}

NSArray* parse_function(NSString* js_func) {
    NSError *error;
    NSRegularExpression* expr1 = [NSRegularExpression regularExpressionWithPattern:@"\\w+\\.(\\w+)\\(\\w,(\\d+)\\)" options:0 error:&error];
    NSRegularExpression* expr2 = [NSRegularExpression regularExpressionWithPattern:@"\\w+\\[(\\\"\\w+\\\")\\]\\(\\w,(\\d+)\\)" options:0 error:&error];
    NSArray* js_func_patterns = @[expr1, expr2];
    
    for (NSRegularExpression* expr in js_func_patterns) {
        NSArray* matches = [expr matchesInString:js_func options:0 range:NSMakeRange(0, [js_func length])];
        if ([matches count] > 0) {
            NSTextCheckingResult *match1 = [matches objectAtIndex:0];
            NSRange matchRange = [match1 rangeAtIndex:1];
            NSString *func= [js_func substringWithRange:matchRange];
            matchRange = [match1 rangeAtIndex:2];
            NSString *arg= [js_func substringWithRange:matchRange];
            return @[func, arg];
        }
    }
    
    return @[];
    
    
}

NSMutableString* get_signature(NSArray *a_array)
{
    NSUInteger count = [a_array count];
    NSMutableString *mutableString = [NSMutableString stringWithCapacity:count];
    
    for (unsigned i = 0; i < count; i++)
    {
        [mutableString appendString:[a_array objectAtIndex:i]] ;
    }
    
    return mutableString;
    
}

NSArray* convertToArray(NSString* s)
{
    NSMutableArray *arr = [[NSMutableArray alloc]init];
    for (int i=0; i < s.length; i++) {
        NSString *tmp_str = [s substringWithRange:NSMakeRange(i, 1)];
        //[arr addObject:[tmp_str  stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        
        [arr addObject:[tmp_str stringByRemovingPercentEncoding]];
    }
    return arr;
}




@implementation Mapper
@synthesize regex;
@synthesize function;

- (id)initWithregex:(NSRegularExpression *)regex function:(NSString *)function
{
    if (self = [super init]) {
        self.regex = regex;
        self.function = function;
    }
    return self;
}



@end
