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
+ (AOAccessibilityElement *)elementForCurrentApplication;
+ (AOAccessibilityElement *)elementWithAXUIElement:(AXUIElementRef)anElement;

// systemElement
// elementForCurrentApplication
@property (readonly, nullable) AOAccessibilityElement *focusedElement;
////////////////

@property (readonly) pid_t processIdentifier;
@property (readonly) BOOL isOurElement;

@property (readonly) NSString *role;
@property (readonly) NSString *subrole;

#pragma mark textField

@property (readonly) BOOL isTextArea;
@property (readonly) BOOL isRegularTextField;
@property (readonly) BOOL isSecureTextField;

@property (readonly, nullable) NSString *stringValue;

@property (readonly) NSRange selectedTextRange;

@property (readonly, nullable) NSString *currentWordOrText;
@property (readonly) NSRange currentWordOrTextRange;

#pragma mark -

@property (readonly) NSArray *attributeNames;

@end

NS_ASSUME_NONNULL_END
