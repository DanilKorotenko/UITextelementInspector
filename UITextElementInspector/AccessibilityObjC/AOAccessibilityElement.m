//
//  AOAccessibilityElement.m
//  UITextElementInspector
//
//  Created by Danil Korotenko on 5/28/23.
//

#import "AOAccessibilityElement.h"

@implementation AOAccessibilityElement
{
    AXUIElementRef _element;
}

+ (AOAccessibilityElement *)systemElement
{
    static AOAccessibilityElement *result = nil;
    if(nil == result)
    {
        AXUIElementRef systemWide = AXUIElementCreateSystemWide();
        result = [[AOAccessibilityElement alloc] initWithAccessibilityElement:systemWide];
        CFRelease(systemWide);
    }
    return result;
}

- (instancetype)initWithAccessibilityElement:(AXUIElementRef)anElement
{
    self = [super init];
    if (self)
    {
        _element = CFRetain(anElement);
    }
    return self;
}

- (void)dealloc
{
    if (NULL != _element)
    {
        CFRelease(_element);
    }
}

#pragma mark -

@end
