#import <AppKit/AppKit.h>
#import <CoreGraphics/CoreGraphics.h>


NS_ASSUME_NONNULL_BEGIN

@interface NSScreen (CGHelpers)

+(NSScreen * _Nullable)screenWithDisplayID:(CGDirectDisplayID)displayID;

@property (nonatomic, readonly) CGDirectDisplayID displayID;

@end

NS_ASSUME_NONNULL_END
