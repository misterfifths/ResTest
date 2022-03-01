#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

@interface NSProcessInfo (AppleSiliconUtils)

@property (nonatomic, readonly, class) BOOL isRunningOnAppleSilicon;
@property (nonatomic, readonly, class) BOOL isRunningInRosetta;

@end

NS_ASSUME_NONNULL_END
