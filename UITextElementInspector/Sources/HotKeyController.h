//
//  HotKeyController.h
//  UIElementInspector
//
//  Created by Danil Korotenko on 5/20/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

OSStatus RegisterLockUIElementHotKey(void (^aCallBackBlock)(void));

NS_ASSUME_NONNULL_END
