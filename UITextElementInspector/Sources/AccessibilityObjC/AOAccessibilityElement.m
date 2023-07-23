//
//  AOAccessibilityElement.m
//  UITextElementInspector
//
//  Created by Danil Korotenko on 5/28/23.
//

#import "AOAccessibilityElement.h"

@interface AOAccessibilityElement ()

@property (readonly) AXUIElementRef element;
@property (readonly) NSString *role;
@property (readonly) NSString *subrole;
@property (readonly) NSArray *attributeNames;

@end

@implementation AOAccessibilityElement
{
    AXUIElementRef _element;
}

@synthesize role;
@synthesize subrole;

@synthesize attributeNames;

+ (AOAccessibilityElement *)systemElement
{
    static AOAccessibilityElement *result = nil;
    if(nil == result)
    {
        AXUIElementRef systemWide = AXUIElementCreateSystemWide();
        result = [AOAccessibilityElement elementWithAXUIElement:systemWide];
        CFRelease(systemWide);
    }
    return result;
}

+ (AOAccessibilityElement *)elementForCurrentApplication
{
    static NSMutableDictionary *cachedElements = nil;
    if (nil == cachedElements)
    {
        cachedElements = [NSMutableDictionary dictionary];
    }

    pid_t processID = [NSWorkspace sharedWorkspace].frontmostApplication.processIdentifier;
    NSString *pidKey = [NSString stringWithFormat:@"%d", processID];

    AOAccessibilityElement *result = [cachedElements objectForKey:pidKey];

    if (nil == result)
    {
        AXUIElementRef appElement = AXUIElementCreateApplication(processID);
        result = [AOAccessibilityElement elementWithAXUIElement:appElement];
        [cachedElements setObject:result forKey:pidKey];
        CFRelease(appElement);
    }

    return result;
}

+ (AOAccessibilityElement *)elementWithAXUIElement:(AXUIElementRef)anElement
{
    return [[AOAccessibilityElement alloc] initWithAccessibilityElement:anElement];
}

#pragma mark Private Class

+ (NSString *)errorDescription:(AXError)anError
{
    NSString *result = nil;

    switch (anError)
    {
        case kAXErrorSuccess:                           { result = @"kAXErrorSuccess"; break; }
        case kAXErrorFailure:                           { result = @"kAXErrorFailure"; break; }
        case kAXErrorIllegalArgument:                   { result = @"kAXErrorIllegalArgument"; break; }
        case kAXErrorInvalidUIElement:                  { result = @"kAXErrorInvalidUIElement"; break; }
        case kAXErrorInvalidUIElementObserver:          { result = @"kAXErrorInvalidUIElementObserver"; break; }
        case kAXErrorCannotComplete:                    { result = @"kAXErrorCannotComplete"; break; }
        case kAXErrorAttributeUnsupported:              { result = @"kAXErrorAttributeUnsupported"; break; }
        case kAXErrorActionUnsupported:                 { result = @"kAXErrorActionUnsupported"; break; }
        case kAXErrorNotificationUnsupported:           { result = @"kAXErrorNotificationUnsupported"; break; }
        case kAXErrorNotImplemented:                    { result = @"kAXErrorNotImplemented"; break; }
        case kAXErrorNotificationAlreadyRegistered:     { result = @"kAXErrorNotificationAlreadyRegistered"; break; }
        case kAXErrorNotificationNotRegistered:         { result = @"kAXErrorNotificationNotRegistered"; break; }
        case kAXErrorAPIDisabled:                       { result = @"kAXErrorAPIDisabled"; break; }
        case kAXErrorNoValue:                           { result = @"kAXErrorNoValue"; break; }
        case kAXErrorParameterizedAttributeUnsupported: { result = @"kAXErrorParameterizedAttributeUnsupported"; break; }
        case kAXErrorNotEnoughPrecision:                { result = @"kAXErrorNotEnoughPrecision"; break; }

        default:
            break;
    }

    return result;
}

#pragma mark -

- (instancetype)initWithAccessibilityElement:(AXUIElementRef)anElement
{
    self = [super init];
    if (self)
    {
        if (NULL == anElement)
        {
            return nil;
        }

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

- (BOOL)isEqual:(id)other
{
    if([other isKindOfClass:[self class]])
    {
        return CFEqual(self.element, [(AOAccessibilityElement *)other element]) == TRUE;
    }
    return NO;
}

#pragma mark -

- (AOAccessibilityElement * _Nullable)focusedElement
{
    AOAccessibilityElement *result = nil;
//    AXUIElementRef element = [self copyValueOfAttribute:NSAccessibilityFocusedUIElementAttribute];
    AXUIElementRef element = [self copyValueOfAttribute:(NSString *)kAXFocusedUIElementAttribute];
    if (NULL != element)
    {
        result = [[AOAccessibilityElement alloc] initWithAccessibilityElement:element];
        CFRelease(element);
    }
    return result;
}

#pragma mark -

- (pid_t)processIdentifier
{
    pid_t pid = 0;
    if (AXUIElementGetPid (_element, &pid) == kAXErrorSuccess)
    {
        return pid;
    }
    else
    {
        return 0;
    }
}

- (BOOL)isOurElement
{
    return self.processIdentifier == getpid();
}

#pragma mark -

- (BOOL)isTextArea
{
    return [self.role isEqualToString:NSAccessibilityTextAreaRole];
}

- (BOOL)isRegularTextField
{
    return self.subrole == nil && [self.role isEqualToString:NSAccessibilityTextFieldRole];
}

- (BOOL)isSecureTextField
{
    return [self.subrole isEqualToString:NSAccessibilitySecureTextFieldSubrole];
}

#pragma mark -

// if selected text range length > 0, returns selected text
// if selected text range length == 0, calculate current word
- (NSRange)currentWordOrTextRange
{
    NSString *stringValue = self.stringValue;
    NSRange selectedRange = self.selectedTextRange;

    if (nil == stringValue ||
        selectedRange.location == NSNotFound)
    {
        return NSMakeRange(NSNotFound, NSNotFound);
    }

    NSRange result;

    if (selectedRange.length != 0 && selectedRange.length != NSNotFound)
    {
        result = selectedRange;
    }
    else
    {
        NSMutableCharacterSet *wordBoundarySet = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
        [wordBoundarySet formUnionWithCharacterSet:[NSCharacterSet punctuationCharacterSet]];
        [wordBoundarySet formUnionWithCharacterSet:[NSCharacterSet controlCharacterSet]];

        NSRange wordStart = [stringValue rangeOfCharacterFromSet:wordBoundarySet
            options:NSBackwardsSearch range:NSMakeRange(0, selectedRange.location)];

        if (wordStart.location == NSNotFound)
        {
            wordStart.location = 0;
        }
        else
        {
            wordStart.location = wordStart.location + 1;
        }

        NSRange wordEnd = [stringValue rangeOfCharacterFromSet:wordBoundarySet
            options:0
            range:NSMakeRange(selectedRange.location, stringValue.length - selectedRange.location)];

        if (wordEnd.location == NSNotFound)
        {
            wordEnd.location = stringValue.length;
        }

        result = NSMakeRange(wordStart.location, wordEnd.location - wordStart.location);
    }

    return result;
}

- (NSString *)currentWordOrText
{
    NSRange currentRange = self.currentWordOrTextRange;
    NSString *stringValue = self.stringValue;

    if (nil == stringValue || currentRange.location == NSNotFound ||
        currentRange.length == NSNotFound || currentRange.length == 0)
    {
        return nil;
    }

    NSString *result = [stringValue substringWithRange:currentRange];

    return result;
}

//- (BOOL)isPossibleToSetCurrentWordOrText
//{
//
//}

#pragma mark Private

#pragma mark -

- (NSString *)role
{
    if (nil == role)
    {
        CFStringRef roleRef = [self copyValueOfAttribute:NSAccessibilityRoleAttribute];
        if (NULL != roleRef)
        {
            role = CFBridgingRelease(roleRef);
        }
    }
    return role;
}

- (NSString *)subrole
{
    if (nil == subrole)
    {
        CFStringRef subroleRef = [self copyValueOfAttribute:NSAccessibilitySubroleAttribute];
        if (NULL != subroleRef)
        {
            subrole = CFBridgingRelease(subroleRef);
        }
    }
    return subrole;
}

#pragma mark -

- (NSString * _Nullable)stringValue
{
    NSString *result = nil;

    CFTypeRef rawValue = [self copyValueOfAttribute:(NSString *)kAXValueAttribute];
    if (NULL != rawValue)
    {
        if (CFGetTypeID(rawValue) == CFStringGetTypeID())
        {
            CFStringRef stringValueRef = (CFStringRef)rawValue;
            result = CFBridgingRelease(stringValueRef);
        }
        else
        {
            CFRelease(rawValue);
        }
    }
    return result;
}

- (NSRange)selectedTextRange
{
    NSRange result = NSMakeRange(NSNotFound, NSNotFound);
    CFTypeRef rawValue = [self copyValueOfAttribute:(NSString *)kAXSelectedTextRangeAttribute];
    if (NULL != rawValue)
    {
        if (AXValueGetType(rawValue) == kAXValueCFRangeType)
        {
            CFRange range;
            if (AXValueGetValue(rawValue, kAXValueCFRangeType, &range))
            {
                result = NSMakeRange(range.location, range.length);
            }
        }
        CFRelease(rawValue);
    }
    return result;
}

#pragma mark -

- (NSArray *)attributeNames
{
    if (nil == attributeNames)
    {
        CFArrayRef attrNamesRef = NULL;
        AXUIElementCopyAttributeNames(self.element, &attrNamesRef);
        attributeNames = CFBridgingRelease(attrNamesRef);
    }
    return attributeNames;
}

#pragma mark -

- (AXUIElementRef)element
{
    return _element;
}

#pragma mark -

- (CFTypeRef)copyValueOfAttribute:(NSString *)anAttributeName
{
    CFTypeRef resultRef = NULL;
    if ([self.attributeNames containsObject:anAttributeName])
    {
        AXError result = AXUIElementCopyAttributeValue(self.element, (CFStringRef)anAttributeName, &resultRef);
        if (result != kAXErrorSuccess)
        {
            resultRef = NULL;
            NSLog(@"copyValueOfAttribute: %@, error: %@", anAttributeName, [[self class] errorDescription:result]);
        }
    }
    return resultRef;
}

- (BOOL)canSetAttribute:(NSString *)attributeName
{
    Boolean isSettable = false;

    AXUIElementIsAttributeSettable(self.element, (CFStringRef)attributeName, &isSettable);

    return (BOOL)isSettable;
}

/*

+ (NSArray *)actionNamesOfUIElement:(AXUIElementRef)element
{
    CFArrayRef actionNamesRef = NULL;
    AXUIElementCopyActionNames(element, &actionNamesRef);
    NSArray *actionNames = CFBridgingRelease(actionNamesRef);
    return actionNames;
}

+ (NSString *)descriptionOfAction:(NSString *)actionName ofUIElement:(AXUIElementRef)element
{
    CFStringRef actionDescriptionRef = NULL;
    AXUIElementCopyActionDescription(element, (CFStringRef)actionName, &actionDescriptionRef);
    NSString *actionDescription = CFBridgingRelease(actionDescriptionRef);
    return actionDescription;
}

+ (void)performAction:(NSString *)actionName ofUIElement:(AXUIElementRef)element
{
    AXUIElementPerformAction( element, (CFStringRef)actionName);
}

+ (BOOL)canSetAttribute:(NSString *)attributeName ofUIElement:(AXUIElementRef)element
{
    Boolean isSettable = false;

    AXUIElementIsAttributeSettable(element, (CFStringRef)attributeName, &isSettable);

    return (BOOL)isSettable;
}

+ (void)setStringValue:(NSString *)stringValue forAttribute:(NSString *)attributeName ofUIElement:(AXUIElementRef)element;
{
    CFTypeRef theCurrentValueRef = NULL;

    // First, found out what type of value it is.
    if ( attributeName
        && AXUIElementCopyAttributeValue( element, (CFStringRef)attributeName, &theCurrentValueRef ) == kAXErrorSuccess
        && theCurrentValueRef)
    {
        CFTypeRef	valueRef = NULL;

        // Set the value using based on the type
        if (AXValueGetType(theCurrentValueRef) == kAXValueCGPointType)
        {
            // CGPoint
            float x, y;
            sscanf( [stringValue UTF8String], "x=%g y=%g", &x, &y );
            CGPoint point = CGPointMake(x, y);
            valueRef = AXValueCreate( kAXValueCGPointType, (const void *)&point );
            if (valueRef)
            {
                AXUIElementSetAttributeValue( element, (CFStringRef)attributeName, valueRef );
                CFRelease( valueRef );
            }
        }
        else if (AXValueGetType(theCurrentValueRef) == kAXValueCGSizeType)
        {
            // CGSize
            float w, h;
            sscanf( [stringValue UTF8String], "w=%g h=%g", &w, &h );
            CGSize size = CGSizeMake(w, h);
            valueRef = AXValueCreate( kAXValueCGSizeType, (const void *)&size );
            if (valueRef)
            {
                AXUIElementSetAttributeValue( element, (CFStringRef)attributeName, valueRef );
                CFRelease( valueRef );
            }
        }
        else if (AXValueGetType(theCurrentValueRef) == kAXValueCGRectType)
        {
            // CGRect
            float x, y, w, h;
            sscanf( [stringValue UTF8String], "x=%g y=%g w=%g h=%g", &x, &y, &w, &h );
            CGRect rect = CGRectMake(x, y, w, h);
            valueRef = AXValueCreate( kAXValueCGRectType, (const void *)&rect );
            if (valueRef)
            {
                AXUIElementSetAttributeValue( element, (CFStringRef)attributeName, valueRef );
                CFRelease( valueRef );
            }
        }
        else if (AXValueGetType(theCurrentValueRef) == kAXValueCFRangeType)
        {
            // CFRange
            CFRange range;
            sscanf( [stringValue UTF8String], "pos=%ld len=%ld", &(range.location), &(range.length) );
            valueRef = AXValueCreate( kAXValueCFRangeType, (const void *)&range );
            if (valueRef)
            {
                AXUIElementSetAttributeValue( element, (CFStringRef)attributeName, valueRef );
                CFRelease( valueRef );
            }
        }
        else if ([(__bridge id)theCurrentValueRef isKindOfClass:[NSString class]])
        {
            // NSString
            AXUIElementSetAttributeValue( element, (CFStringRef)attributeName, (__bridge CFTypeRef _Nonnull)(stringValue) );
        }
        else if ([(__bridge id)theCurrentValueRef isKindOfClass:[NSValue class]])
        {
            // NSValue
            AXUIElementSetAttributeValue( element, (CFStringRef)attributeName, (__bridge CFTypeRef _Nonnull)([NSNumber numberWithFloat:[stringValue floatValue]]) );
        }
    }
}

+ (AXUIElementRef)parentOfUIElement:(AXUIElementRef)element
{
    return (__bridge AXUIElementRef)[UIElementUtilities valueOfAttribute:NSAccessibilityParentAttribute ofUIElement:element];
}

+ (NSString *)titleOfUIElement:(AXUIElementRef)element
{
    return (NSString *)[UIElementUtilities valueOfAttribute:NSAccessibilityTitleAttribute ofUIElement:element];
}

+ (BOOL)isApplicationUIElement:(AXUIElementRef)element
{
    return [[UIElementUtilities roleOfUIElement:element] isEqualToString:NSAccessibilityApplicationRole];
}

#pragma mark -
#pragma mark String Descriptions

// -------------------------------------------------------------------------------
//	stringDescriptionOfAXValue:valueRef:beVerbose
//
//	Returns a descriptive string according to the values' structure type.
// -------------------------------------------------------------------------------
+ (NSString *)stringDescriptionOfAXValue:(CFTypeRef)valueRef beingVerbose:(BOOL)beVerbose
{
    NSString *result = @"AXValue???";

    switch (AXValueGetType(valueRef))
    {
        case kAXValueCGPointType:
        {
            CGPoint point;
            if (AXValueGetValue(valueRef, kAXValueCGPointType, &point))
            {
                if (beVerbose)
                {
                    result = [NSString stringWithFormat:@"<AXPointValue x=%g y=%g>", point.x, point.y];
                }
                else
                {
                    result = [NSString stringWithFormat:@"x=%g y=%g", point.x, point.y];
                }
            }
            break;
        }
        case kAXValueCGSizeType:
        {
            CGSize size;
            if (AXValueGetValue(valueRef, kAXValueCGSizeType, &size))
            {
                if (beVerbose)
                {
                    result = [NSString stringWithFormat:@"<AXSizeValue w=%g h=%g>", size.width, size.height];
                }
                else
                {
                    result = [NSString stringWithFormat:@"w=%g h=%g", size.width, size.height];
                }
            }
            break;
        }
        case kAXValueCGRectType:
        {
            CGRect rect;
            if (AXValueGetValue(valueRef, kAXValueCGRectType, &rect))
            {
                if (beVerbose)
                {
                    result = [NSString stringWithFormat:@"<AXRectValue  x=%g y=%g w=%g h=%g>", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height];
                }
                else
                {
                    result = [NSString stringWithFormat:@"x=%g y=%g w=%g h=%g", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height];
                }
            }
            break;
        }
        case kAXValueCFRangeType:
        {
            CFRange range;
            if (AXValueGetValue(valueRef, kAXValueCFRangeType, &range))
            {
                if (beVerbose)
                {
                    result = [NSString stringWithFormat:@"<AXRangeValue pos=%ld len=%ld>", range.location, range.length];
                }
                else
                {
                    result = [NSString stringWithFormat:@"pos=%ld len=%ld", range.location, range.length];
                }
            }
            break;
        }
        default:
            break;
    }
    return result;
}

// -------------------------------------------------------------------------------
//	descriptionOfValue:theValue:beVerbose
//
//	Called from "descriptionForUIElement", return a descripting string (role and title)
//	of the given value (AXUIElementRef).
// -------------------------------------------------------------------------------
+ (NSString *)descriptionOfValue:(CFTypeRef)theValue beingVerbose:(BOOL)beVerbose
{
    NSString *theValueDescString = NULL;

    if (theValue)
    {
        if (AXValueGetType(theValue) != kAXValueIllegalType)
        {
            theValueDescString = [self stringDescriptionOfAXValue:theValue beingVerbose:beVerbose];
        }
        else if (CFGetTypeID(theValue) == CFArrayGetTypeID())
        {
            theValueDescString = [NSString stringWithFormat:@"<array of size %lu>", (unsigned long)[(__bridge NSArray *)theValue count]];
        }
        else if (CFGetTypeID(theValue) == AXUIElementGetTypeID())
        {
            CFTypeRef uiElementRoleRef = NULL;

            if (AXUIElementCopyAttributeValue((AXUIElementRef)theValue, kAXRoleAttribute, &uiElementRoleRef) == kAXErrorSuccess)
            {
                NSString *uiElementTitle = [self valueOfAttribute:
                    NSAccessibilityTitleAttribute ofUIElement:(AXUIElementRef)theValue];

                #if 0
                // hack to work around cocoa app objects not having titles yet
                if (uiElementTitle == nil && [uiElementRole isEqualToString:(NSString *)kAXApplicationRole])
                {
                    pid_t				theAppPID = 0;
                    ProcessSerialNumber	theAppPSN = {0,0};
                    NSString *			theAppName = NULL;

                    if (AXUIElementGetPid( (AXUIElementRef)theValue, &theAppPID ) == kAXErrorSuccess
                        && GetProcessForPID( theAppPID, &theAppPSN ) == noErr
                        && CopyProcessName( &theAppPSN, (CFStringRef *)&theAppName ) == noErr )
                    {
                        uiElementTitle = theAppName;
                    }
                }
                #endif

                NSString *uiElementRole = CFBridgingRelease(uiElementRoleRef);
                if (uiElementTitle != nil)
                {
                    theValueDescString = [NSString stringWithFormat:@"<%@: “%@”>", uiElementRole, uiElementTitle];
                }
                else
                {
                    theValueDescString = [NSString stringWithFormat:@"<%@>", uiElementRole];
                }
            }
            else
            {
                theValueDescString = [(__bridge id)theValue description];
            }
        }
        else
        {
            theValueDescString = [(__bridge id)theValue description];
        }
    }

    return theValueDescString;
}

// -------------------------------------------------------------------------------
//	lineageOfUIElement:element
//
//	Return the lineage array or inheritance of a given uiElement.
// -------------------------------------------------------------------------------
+ (NSArray *)lineageOfUIElement:(AXUIElementRef)element
{
    NSArray *lineage = [NSArray array];
    NSString *elementDescr = [self descriptionOfValue:element beingVerbose:NO];
    AXUIElementRef parent = (__bridge AXUIElementRef)[self valueOfAttribute:NSAccessibilityParentAttribute ofUIElement:element];

    if (parent != NULL)
    {
        lineage = [self lineageOfUIElement:parent];
    }
    return [lineage arrayByAddingObject:elementDescr];
}

// -------------------------------------------------------------------------------
//	lineageDescriptionOfUIElement:element
//
//	Return the descriptive string of a uiElement's lineage.
// -------------------------------------------------------------------------------
+ (NSString *)lineageDescriptionOfUIElement:(AXUIElementRef)element
{
    NSMutableString *result = [NSMutableString string];
    NSMutableString *indent = [NSMutableString string];
    NSArray *lineage = [self lineageOfUIElement:element];
    NSString *ancestor;
    NSEnumerator *e = [lineage objectEnumerator];
    while (ancestor = [e nextObject])
    {
        [result appendFormat:@"%@%@\n", indent, ancestor];
        [indent appendString:@" "];
    }
    return result;
}

// -------------------------------------------------------------------------------
//	stringDescriptionOfUIElement:inElement
//
//	Return a descriptive string of attributes and actions of a given uiElement.
// -------------------------------------------------------------------------------
+ (NSString *)stringDescriptionOfUIElement:(AXUIElementRef)element
{
    NSMutableString *theDescriptionStr = [NSMutableString string];
    CFIndex			nameIndex;
    CFIndex			numOfNames;

    [theDescriptionStr appendFormat:@"%@", [self lineageDescriptionOfUIElement:element]];

    // display attributes
    NSArray *theNames = [UIElementUtilities attributeNamesOfUIElement:element];
    if (theNames)
    {
        numOfNames = [theNames count];

        if (numOfNames)
        {
            [theDescriptionStr appendString:@"\nAttributes:\n"];
        }

        for( nameIndex = 0; nameIndex < numOfNames; nameIndex++ )
        {
            Boolean	theSettableFlag = false;

            // Grab name
            NSString *theName = [theNames objectAtIndex:nameIndex];

            // Grab settable field
            AXUIElementIsAttributeSettable( element, (CFStringRef)theName, &theSettableFlag );

            // Add string
            [theDescriptionStr appendFormat:@"   %@%@:  “%@”\n", theName, (theSettableFlag?@" (W)":@""),
                [self descriptionForUIElement:element attribute:theName beingVerbose:false]];
        }
    }

    // display actions
    theNames = [UIElementUtilities actionNamesOfUIElement:element];
    if (theNames)
    {
        numOfNames = [theNames count];

        if (numOfNames)
        {
            [theDescriptionStr appendString:@"\nActions:\n"];
        }

        for( nameIndex = 0; nameIndex < numOfNames; nameIndex++ )
        {
            // Grab name
            NSString *theName = [theNames objectAtIndex:nameIndex];

            // Grab description
            NSString *theDesc = [self descriptionOfAction:theName ofUIElement:element];

            // Add string
            [theDescriptionStr appendFormat:@"   %@ - %@\n", theName, theDesc];
        }
    }

    return theDescriptionStr;
}

// -------------------------------------------------------------------------------
//	descriptionForUIElement:uiElement:beingVerbose
//
//	Return a descripting string (role and title) of the given uiElement (AXUIElementRef).
// -------------------------------------------------------------------------------
+ (NSString *)descriptionForUIElement:(AXUIElementRef)uiElement
    attribute:(NSString *)name beingVerbose:(BOOL)beVerbose
{
    NSString *	theValueDescString	= NULL;
    CFTypeRef	theValue;
    CFIndex	count;
    if (([name isEqualToString:NSAccessibilityChildrenAttribute] ||
            [name isEqualToString:NSAccessibilityRowsAttribute])
        &&
            AXUIElementGetAttributeValueCount(uiElement, (CFStringRef)name, &count) == kAXErrorSuccess)
    {
        // No need to get the value of large arrays - we just display their size.
        // We don't want to do this with every attribute because AXUIElementGetAttributeValueCount on non-array valued
        // attributes will cause debug spewage.
        theValueDescString = [NSString stringWithFormat:@"<array of size %ld>", (long)count];
    }
    else if (AXUIElementCopyAttributeValue ( uiElement, (CFStringRef)name, &theValue ) == kAXErrorSuccess && theValue)
    {
        theValueDescString = [self descriptionOfValue:theValue beingVerbose:beVerbose];
    }
    return theValueDescString;
}

// This method returns a 'no description' string by default
+ (NSString *)descriptionOfAXDescriptionOfUIElement:(AXUIElementRef)element
{
    NSString *result = (NSString *)[self valueOfAttribute:
        NSAccessibilityDescriptionAttribute ofUIElement:element];
    return (result.length == 0) ? UIElementUtilitiesNoDescription: [result description];
}

*/

@end
