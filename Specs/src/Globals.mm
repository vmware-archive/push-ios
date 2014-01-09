#import "OmniaPushDebug.h"
#import "OmniaSpecHelper.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

@interface Globals : NSObject
@end

@implementation Globals

+ (void) beforeEach
{
    [OmniaPushDebug disableLogging:YES];
    setupOmniaSpecHelper();
}

+ (void) afterEach
{
    resetOmniaSpecHelper();
}

@end
