#import "Display.h"
#import "NSScreen+CGHelpers.h"
#import "NSProcessInfo+AppleSiliconUtils.h"


@interface Display ()

@property (nonatomic, readwrite) CGDirectDisplayID displayID;
@property (nonatomic, readwrite) NSScreen *screen;
@property (nonatomic, readwrite) NSArray<DisplayDepth *> *depths;

@end


@implementation Display

-(instancetype)initWithDisplayID:(CGDirectDisplayID)displayID
{
    self = [super init];
    if(self) {
        _displayID = displayID;
        _screen = [NSScreen screenWithDisplayID:displayID];
        _depths = [DisplayDepth depthsForScreen:_screen];
    }

    return self;
}

-(instancetype)initWithScreen:(NSScreen *)screen
{
    self = [self initWithDisplayID:screen.displayID];
    NSAssert([self.screen isEqual:screen], @"Expected display ID lookup to find the same screen!");
    return self;
}

-(id)copyWithZone:(NSZone *)zone
{
    return [[[self class] allocWithZone:zone] initWithDisplayID:self.displayID];
}

+(Display *)mainDisplay
{
    return [[self alloc] initWithDisplayID:CGMainDisplayID()];
}

+(NSArray<Display *> *)getDisplays:(BOOL)online
{
    CGError (*getFunc)(uint32_t, CGDirectDisplayID *, uint32_t *);
    if(online) getFunc = CGGetOnlineDisplayList;
    else getFunc = CGGetActiveDisplayList;

    uint32_t idCount;
    CGError err = getFunc(0, NULL, &idCount);
    if(err != kCGErrorSuccess) {
        NSLog(@"Error getting displays: %d", err);
        return @[];
    }

    CGDirectDisplayID *ids = calloc(idCount, sizeof(CGDirectDisplayID));
    err = getFunc(idCount, ids, &idCount);
    if(err != kCGErrorSuccess) {
        NSLog(@"Error getting displays: %d", err);
        free(ids);
        return @[];
    }

    NSMutableArray *res = [NSMutableArray arrayWithCapacity:idCount];

    for(size_t i = 0; i < idCount; i++) {
        CGDirectDisplayID dispid = ids[i];
        [res addObject:[[self alloc] initWithDisplayID:dispid]];
    }

    free(ids);

    return res;
}

+(NSArray<Display *> *)activeDisplays
{
    return [self getDisplays:NO];
}

+(NSArray<Display *> *)onlineDisplays
{
    return [self getDisplays:YES];
}

-(NSArray<DisplayMode *> *)displayModesIncludingLowRes:(BOOL)includeLowRes
{
    NSDictionary *options = nil;
    if(includeLowRes)
        options = @{ (NSString *)kCGDisplayShowDuplicateLowResolutionModes: @YES };

    NSArray *modes = (__bridge_transfer NSArray *)CGDisplayCopyAllDisplayModes(self.displayID, (__bridge CFDictionaryRef)options);

    NSMutableArray *res = [NSMutableArray arrayWithCapacity:modes.count];
    for(id modeObj in modes) {
        CGDisplayModeRef mode = (__bridge CGDisplayModeRef)modeObj;
        [res addObject:[[DisplayMode alloc] initWithCGModeRef:mode display:self]];
    }

    [res sortUsingSelector:@selector(compare:)];

    return res;
}

-(DisplayMode *)defaultDisplayMode
{
    NSArray<DisplayMode *> *modes = [self displayModesIncludingLowRes:NO];
    for(DisplayMode *mode in modes) {
        if(mode.isDefaultDisplayMode)
            return mode;
    }

    // Should never happen, but just in case...
    return modes[0];
}

-(DisplayMode *)currentDisplayMode
{
    CGDisplayModeRef cgMode = CGDisplayCopyDisplayMode(self.displayID);
    DisplayMode *mode = [[DisplayMode alloc] initWithCGModeRef:cgMode display:self];
    CGDisplayModeRelease(cgMode);
    return mode;
}

-(CGError)setCurrentDisplayMode:(DisplayMode *)mode andCapture:(BOOL)capture
{
    NSAssert([mode.display isEqual:self], @"Mode must belong to the display it is being set on.");

    if(capture) {
        CGError err = [self capture];
        if(err != kCGErrorSuccess) return err;
    }

    return CGDisplaySetDisplayMode(self.displayID, mode.modeRef, NULL);
}

-(NSString *)name
{
    if (@available(macOS 10.15, *))
        return self.screen.localizedName;
    else
        return [NSString stringWithFormat:@"Vendor %x, Model %x", self.vendorNumber, self.modelNumber];
}

-(BOOL)isBuiltIn
{
    return CGDisplayIsBuiltin(self.displayID);
}

-(BOOL)isMainDisplay
{
    return CGDisplayIsMain(self.displayID);
}

-(BOOL)isActive
{
    return CGDisplayIsActive(self.displayID);
}

-(BOOL)isOnline
{
    return CGDisplayIsOnline(self.displayID);
}

-(BOOL)isAsleep
{
    return CGDisplayIsAsleep(self.displayID);
}

-(uint32_t)vendorNumber
{
    return CGDisplayVendorNumber(self.displayID);
}

-(uint32_t)modelNumber
{
    return CGDisplayModelNumber(self.displayID);
}

-(BOOL)mightHaveNotch
{
    return self.isBuiltIn &&
           [NSProcessInfo isRunningOnAppleSilicon] &&
           [NSScreen instancesRespondToSelector:@selector(safeAreaInsets)];
}

-(BOOL)isCaptured
{
    return CGDisplayIsCaptured(self.displayID);
}

-(CGError)capture
{
    return CGDisplayCapture(self.displayID);
}

-(CGError)uncapture
{
    return CGDisplayRelease(self.displayID);
}

-(BOOL)isEqual:(id)object
{
    return [object isKindOfClass:[Display class]] && self.displayID == ((Display *)object).displayID;
}

-(NSUInteger)hash
{
    return self.displayID;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p ('%@', ID %u)>", self.class, self, self.name, self.displayID];
}

@end
