#import "DisplayDepth.h"


@interface DisplayDepth ()

@property (nonatomic, readwrite) NSWindowDepth rawDepth;

@end


@implementation DisplayDepth

-(instancetype)initWithWindowDepth:(NSWindowDepth)depth
{
    self = [super init];
    if(self) {
        _rawDepth = depth;
    }

    return self;
}

-(id)copyWithZone:(NSZone *)zone
{
    return [[[self class] allocWithZone:zone] initWithWindowDepth:self.rawDepth];
}

+(NSArray<DisplayDepth *> *)depthsForScreen:(NSScreen *)screen
{
    size_t i = 0;
    NSWindowDepth depth;
    const NSWindowDepth *depths = screen.supportedWindowDepths;

    NSMutableArray *res = [NSMutableArray new];
    while((depth = depths[i++])) {
        [res addObject:[[self alloc] initWithWindowDepth:depth]];
    }

    return res;
}

-(NSColorSpaceName)colorSpaceName
{
    return NSColorSpaceFromDepth(self.rawDepth);
}

-(NSInteger)bitsPerPixel
{
    return NSBitsPerPixelFromDepth(self.rawDepth);
}

-(NSInteger)bitsPerSample
{
    return NSBitsPerSampleFromDepth(self.rawDepth);
}

-(NSInteger)numberOfColorComponents
{
    return NSNumberOfColorComponents(self.colorSpaceName);
}

-(BOOL)isEqual:(id)object
{
    return [object isKindOfClass:[DisplayDepth class]] && self.rawDepth == ((DisplayDepth *)object).rawDepth;
}

-(NSUInteger)hash
{
    return self.rawDepth;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p (%@, %ld bpp)>", self.class, self, self.colorSpaceName ? self.colorSpaceName : @"unknown color space", self.bitsPerPixel];
}

@end
