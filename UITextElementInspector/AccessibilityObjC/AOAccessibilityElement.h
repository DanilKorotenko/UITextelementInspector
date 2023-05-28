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

- (instancetype)initWithAccessibilityElement:(AXUIElementRef)anElement;

@property (readonly) NSArray *attributeNames;

@end

NS_ASSUME_NONNULL_END
