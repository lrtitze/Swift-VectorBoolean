//
// CGPathHelper.m
//
// Written by Zachary Waldowski
// from: https://gist.github.com/zwaldowski/e6aa7f3f81303a688ad4

@import QuartzCore;

typedef void (^ApplierBlock)(const CGPathElement *element);

static void __CGPathApplyToBlock(void *info, const CGPathElement *element) {
    ApplierBlock block = (__bridge ApplierBlock)info;
    block(element);
}

__attribute__((used, visibility("hidden"))) void _CGPathApplyWithBlock(CGPathRef inPath, __attribute__((noescape)) ApplierBlock block) {
    CGPathApply(inPath, (__bridge void *)block, __CGPathApplyToBlock);
}
