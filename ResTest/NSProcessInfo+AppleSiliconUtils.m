#import "NSProcessInfo+AppleSiliconUtils.h"

#include <sys/types.h>
#include <sys/sysctl.h>
#include <sys/utsname.h>


@implementation NSProcessInfo (AppleSiliconUtils)

+(BOOL)isRunningInRosetta
{
    static BOOL inRosetta = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        int ret = 0;
        size_t size = sizeof(ret);
        if (sysctlbyname("sysctl.proc_translated", &ret, &size, NULL, 0) == -1) {
            // ENOENT means we're on a version of macOS without this sysctl, and
            // so definitely not in Rosetta.
            // Any other error... I guess we can assume is a no?
            if (errno != ENOENT)
                NSLog(@"sysctl.proc_translated error: %d", errno);
        }
        else
            inRosetta = ret == 1;
    });

    return inRosetta;
}

+(BOOL)isRunningOnAppleSilicon
{
    if([self isRunningInRosetta])
        return YES;

    // If we're not in Rosetta 2, check for native ARM via uname.
    static BOOL onAppleSilicon = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        struct utsname name;
        if(uname(&name) == -1)
            NSLog(@"uname error: %d", errno);
        else
            onAppleSilicon = !strcmp(name.machine, "arm64");
    });

    return onAppleSilicon;
}

@end
