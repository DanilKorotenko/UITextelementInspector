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

#pragma mark -

@property (readonly) pid_t processIdentifier;
@property (readonly) BOOL isOurElement;

#pragma mark -

@property (readonly) BOOL isTextArea;
@property (readonly) BOOL isRegularTextField;
@property (readonly) BOOL isSecureTextField;

#pragma mark -

@property (readonly, nullable) NSString *currentWordOrText;
@property (readonly) NSRange currentWordOrTextRange;

@end

NS_ASSUME_NONNULL_END
