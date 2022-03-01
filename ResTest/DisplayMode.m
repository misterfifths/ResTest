#import "DisplayMode.h"
#import "Display.h"
#import "DisplayDepth.h"


@interface DisplayMode ()

@property (nonatomic, readwrite) CGDisplayModeRef modeRef;
@property (nonatomic, readwrite, copy) Display *display;

@end


@implementation DisplayMode

-(instancetype)initWithCGModeRef:(CGDisplayModeRef)modeRef display:(Display *)display
{
    self = [super init];
    if(self) {
        _modeRef = CGDisplayModeRetain(modeRef);

        // Copying this to avoid retain cycles. Making it weak makes it a little
        // too easy to accidentally lose it.
        _display = [display copy];
    }
    
    return self;
}

-(id)copyWithZone:(NSZone *)zone
{
    return [[[self class] allocWithZone:zone] initWithCGModeRef:self.modeRef display:self.display];
}

-(void)dealloc
{
    CGDisplayModeRelease(_modeRef);
}

-(BOOL)isCurrentDisplayMode
{
    return [self.display.currentDisplayMode isEqual:self];
}

-(BOOL)isDefaultDisplayMode
{
    return (self.ioFlags & kDisplayModeDefaultFlag) == kDisplayModeDefaultFlag;
}

-(size_t)width
{
    return CGDisplayModeGetWidth(self.modeRef);
}

-(size_t)height
{
    return CGDisplayModeGetHeight(self.modeRef);
}

-(size_t)pixelWidth
{
    return CGDisplayModeGetPixelWidth(self.modeRef);
}

-(size_t)pixelHeight
{
    return CGDisplayModeGetPixelHeight(self.modeRef);
}

-(double)aspectRatio
{
    return (double)self.width / self.height;
}

-(double)refreshRate
{
    return CGDisplayModeGetRefreshRate(self.modeRef);
}

-(uint32_t)ioFlags
{
    return CGDisplayModeGetIOFlags(self.modeRef);
}

-(NSString *)ioFlagsDescription
{
    static NSDictionary<NSNumber *, NSString *> *allFlags;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        allFlags = @{
            @(kDisplayModeValidFlag): @"Valid",
            @(kDisplayModeSafeFlag): @"Safe",
            @(kDisplayModeDefaultFlag): @"Default",
            
            @(kDisplayModeAlwaysShowFlag): @"Always Show",
            @(kDisplayModeNeverShowFlag): @"Never Show",
            @(kDisplayModeNotResizeFlag): @"Not Resize",
            @(kDisplayModeRequiresPanFlag): @"Requires Pan",
            
            @(kDisplayModeInterlacedFlag): @"Interlaced",
            
            @(kDisplayModeSimulscanFlag): @"Simulscan",
            @(kDisplayModeBuiltInFlag): @"Built In",
            @(kDisplayModeNotPresetFlag): @"Not Preset",
            @(kDisplayModeStretchedFlag): @"Stretched",
            @(kDisplayModeNotGraphicsQualityFlag): @"Not Graphics Quality",
            @(kDisplayModeValidateAgainstDisplay): @"Validate Against Display",
            @(kDisplayModeTelevisionFlag): @"Television",
            @(kDisplayModeValidForMirroringFlag): @"Valid For Mirroring",
            @(kDisplayModeAcceleratorBackedFlag): @"Accelerator Backed",
            @(kDisplayModeValidForHiResFlag): @"Valid For HiRes",
            @(kDisplayModeValidForAirPlayFlag): @"Valid For AirPlay",
            @(kDisplayModeNativeFlag): @"Native"
        };
    });
    
    NSMutableArray *flagStrs = [NSMutableArray array];
    uint32_t flags = self.ioFlags;
    uint32_t unknownBits = flags;
    for(NSNumber *flagNum in allFlags) {
        uint flag = [flagNum unsignedIntValue];
        if((flags & flag) == flag) {
            [flagStrs addObject:allFlags[flagNum]];
            unknownBits &= ~flag;
        }
    }

    if(unknownBits)
        [flagStrs addObject:[NSString stringWithFormat:@"Unknown (%#x)", unknownBits]];
    
    return [flagStrs componentsJoinedByString:@", "];
}

-(NSString *)pixelEncoding
{
    return (__bridge_transfer NSString *)CGDisplayModeCopyPixelEncoding(self.modeRef);
}

-(NSUInteger)bitsPerPixel
{
    // This is Wine's logic, but CGDisplayModeCopyPixelEncoding doesn't seem to
    // return anything but IO32BitDirectPixels these days.

    static NSDictionary<NSString *, NSNumber *> *bppMap;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        bppMap = @{
            @kIO32BitFloatPixels: @128,
            @kIO16BitFloatPixels: @64,
            @kIO64BitDirectPixels: @64,
            @IO32BitDirectPixels: @32,
            @kIO30BitDirectPixels: @30,
            @IO16BitDirectPixels: @16,
            @IO8BitIndexedPixels: @8,
            @IO4BitIndexedPixels: @4,
            @IO2BitIndexedPixels: @2,
            @IO1BitIndexedPixels: @1
        };
    });

    return bppMap[self.pixelEncoding].unsignedIntegerValue;
}

-(BOOL)isUsableForDesktopGUI
{
    return CGDisplayModeIsUsableForDesktopGUI(self.modeRef);
}

-(CGError)setAndCaptureDisplay:(BOOL)capture
{
    return [self.display setCurrentDisplayMode:self andCapture:capture];
}

-(BOOL)isEqual:(id)object
{
    return [object isKindOfClass:[DisplayMode class]] && CFEqual(self.modeRef, ((DisplayMode *)object).modeRef);
}

-(NSUInteger)hash
{
    return CFHash(self.modeRef);
}

-(NSComparisonResult)compare:(DisplayMode *)other
{
    // Order by bpp descending, then width and height ascending, then refresh
    // rate descending.

    size_t us, them;

    us = self.bitsPerPixel;
    them = other.bitsPerPixel;
    if (us < them) return NSOrderedDescending;
    else if(us > them) return NSOrderedAscending;

    us = self.width;
    them = other.width;
    if (us < them) return NSOrderedAscending;
    else if(us > them) return NSOrderedDescending;

    us = self.height;
    them = other.height;
    if (us < them) return NSOrderedAscending;
    else if(us > them) return NSOrderedDescending;

    us = (size_t)(self.refreshRate * 100);
    them = (size_t)(other.refreshRate * 100);
    if (us < them) return NSOrderedDescending;
    else if(us > them) return NSOrderedAscending;

    return NSOrderedSame;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p (%zu x %zu x %zu bpp @ %.2lf Hz)>", self.class, self, self.width, self.height, self.bitsPerPixel, self.refreshRate];
}

@end
