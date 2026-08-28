#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IMKClientBridge : NSObject

+ (NSRange)selectedRangeForClient:(id)client;
+ (nullable NSString *)stringForRange:(NSRange)range client:(id)client;
+ (void)insertText:(NSString *)text replacingRange:(NSRange)range client:(id)client;

@end

NS_ASSUME_NONNULL_END
