#import "NSScreen+CGHelpers.h"


@implementation NSScreen (CGHelpers)

+(NSScreen *)screenWithDisplayID:(CGDirectDisplayID)displayID
{
    for(NSScreen *screen in [NSScreen screens]) {
        if(screen.displayID == displayID)
            return screen;
    }

    return nil;
}

-(CGDirectDisplayID)displayID
{
    // This dictionary key is documented with deviceDescription.
    // Don't know why it doesn't have a NSDeviceDescriptionKey constant.
    return [self.deviceDescription[@"NSScreenNumber"] unsignedIntValue];
}

@end
