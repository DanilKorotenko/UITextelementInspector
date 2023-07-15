//
//  AOAccessibilityElement.h
//  UITextElementInspector
//
//  Created by Danil Korotenko on 5/28/23.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AOAccessibilityElement : NSObject

+ (AOAccessibilityElement *)systemElement;
+ (AOAccessibilityElement *)elementWithAXUIElement:(AXUIElementRef)anElement;

// systemElement attirbutes
@property (readonly) AOAccessibilityElement *focusedElement;
////////////////

@property (readonly) NSString *role;
@property (readonly) NSString *subrole;

#pragma mark textField

@property (readonly) BOOL isTextArea;
@property (readonly) BOOL isRegularTextField;
@property (readonly) BOOL isSecureTextField;

@property (readonly) NSString *stringValue;

#pragma mark -

@property (readonly) NSArray *attributeNames;

@end

NS_ASSUME_NONNULL_END
