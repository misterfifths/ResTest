#import <AppKit/AppKit.h>
#import <CoreGraphics/CoreGraphics.h>

#import "DisplayMode.h"
#import "DisplayDepth.h"


NS_ASSUME_NONNULL_BEGIN

@interface Display : NSObject <NSCopying>

+(instancetype)new NS_UNAVAILABLE;
-(instancetype)init NS_UNAVAILABLE;

-(instancetype)initWithDisplayID:(CGDirectDisplayID)displayID;
-(instancetype)initWithScreen:(NSScreen *)screen;

@property (nonatomic, readonly, class) Display *mainDisplay;
@property (nonatomic, readonly, class) NSArray<Display *> *activeDisplays;
@property (nonatomic, readonly, class) NSArray<Display *> *onlineDisplays;

@property (nonatomic, readonly) CGDirectDisplayID displayID;
@property (nonatomic, readonly) NSScreen *screen;

@property (nonatomic, readonly) NSString *name;  // screen.localizedName if available, otherwise vendor + model

@property (nonatomic, readonly) BOOL isMainDisplay;
@property (nonatomic, readonly) BOOL isBuiltIn;

@property (nonatomic, readonly) BOOL isActive;
@property (nonatomic, readonly) BOOL isOnline;
@property (nonatomic, readonly) BOOL isAsleep;

@property (nonatomic, readonly) uint32_t vendorNumber;
@property (nonatomic, readonly) uint32_t modelNumber;

@property (nonatomic, readonly) NSArray<DisplayDepth *> *depths;

// Returned modes are sorted via -[DisplayMode compare:]
-(NSArray<DisplayMode *> *)displayModesIncludingLowRes:(BOOL)includeLowRes;

@property (nonatomic, readonly) DisplayMode *defaultDisplayMode;

@property (nonatomic, readonly) BOOL isCaptured;
-(CGError)capture;
-(CGError)uncapture;

@property (nonatomic, readonly) DisplayMode *currentDisplayMode;
-(CGError)setCurrentDisplayMode:(DisplayMode *)mode andCapture:(BOOL)capture;

// Returns YES if this display is the built-in display on an Apple Silicon
// device and therefore may have a notch.
@property (nonatomic, readonly) BOOL mightHaveNotch;

@end

NS_ASSUME_NONNULL_END
