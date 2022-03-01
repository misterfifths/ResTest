#import <AppKit/AppKit.h>


NS_ASSUME_NONNULL_BEGIN

@interface DisplayDepth : NSObject <NSCopying>

+(instancetype)new NS_UNAVAILABLE;
-(instancetype)init NS_UNAVAILABLE;

-(instancetype)initWithWindowDepth:(NSWindowDepth)depth;

+(NSArray<DisplayDepth *> *)depthsForScreen:(NSScreen *)screen;

@property (nonatomic, readonly) NSWindowDepth rawDepth;

@property (nonatomic, readonly, nullable) NSColorSpaceName colorSpaceName;
@property (nonatomic, readonly) NSInteger bitsPerPixel;

@property (nonatomic, readonly) NSInteger numberOfColorComponents;
@property (nonatomic, readonly) NSInteger bitsPerSample;

@end

NS_ASSUME_NONNULL_END
