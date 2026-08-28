#import "IMKClientBridge.h"
#import <InputMethodKit/InputMethodKit.h>

@implementation IMKClientBridge

+ (NSRange)selectedRangeForClient:(id)client {
    id<IMKTextInput> typedClient = (id<IMKTextInput>)client;
    return [typedClient selectedRange];
}

+ (NSString *)stringForRange:(NSRange)range client:(id)client {
    id<IMKTextInput> typedClient = (id<IMKTextInput>)client;
    NSAttributedString *substring = [typedClient attributedSubstringFromRange:range];
    return substring.string;
}

+ (void)insertText:(NSString *)text replacingRange:(NSRange)range client:(id)client {
    id<IMKTextInput> typedClient = (id<IMKTextInput>)client;
    [typedClient insertText:text replacementRange:range];
}

@end
