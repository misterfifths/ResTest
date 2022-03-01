#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@class Display;


NS_ASSUME_NONNULL_BEGIN

@interface DisplayMode : NSObject <NSCopying>

+(instancetype)new NS_UNAVAILABLE;
-(instancetype)init NS_UNAVAILABLE;

-(instancetype)initWithCGModeRef:(CGDisplayModeRef)modeRef display:(Display *)display;

@property (nonatomic, readonly) CGDisplayModeRef modeRef;

@property (nonatomic, readonly, copy) Display *display;
@property (nonatomic, readonly) BOOL isCurrentDisplayMode;
@property (nonatomic, readonly) BOOL isDefaultDisplayMode;

@property (nonatomic, readonly) size_t width;  // In points
@property (nonatomic, readonly) size_t height;  // In points

@property (nonatomic, readonly) size_t pixelWidth;
@property (nonatomic, readonly) size_t pixelHeight;

@property (nonatomic, readonly) double aspectRatio;

@property (nonatomic, readonly) double refreshRate;

@property (nonatomic, readonly) uint32_t ioFlags;
@property (nonatomic, readonly) NSString *ioFlagsDescription;

@property (nonatomic, readonly, nullable) NSString *pixelEncoding;
@property (nonatomic, readonly) NSUInteger bitsPerPixel;

@property (nonatomic, readonly) BOOL isUsableForDesktopGUI;

// Equivalent to [self.display setCurrentDisplayMode:self andCapture:capture]
-(CGError)setAndCaptureDisplay:(BOOL)capture;

// Compares based on bit depth, point size, and refresh rate.
// May return NSOrderedSame for DisplayModes that are not strictly identical;
// use isEqual: or compare modeRefs for that.
-(NSComparisonResult)compare:(DisplayMode *)other;

@end

NS_ASSUME_NONNULL_END
