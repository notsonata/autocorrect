#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IMKClientBridge : NSObject

+ (NSRange)selectedRangeForClient:(id)client
    NS_SWIFT_NAME(selectedRange(client:));

+ (nullable NSString *)stringForRange:(NSRange)range client:(id)client
    NS_SWIFT_NAME(string(range:client:));

+ (void)insertText:(NSString *)text replacingRange:(NSRange)range client:(id)client
    NS_SWIFT_NAME(insert(text:replacing:client:));

@end

NS_ASSUME_NONNULL_END
