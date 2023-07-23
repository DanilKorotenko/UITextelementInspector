//
//  HotKeyController.m
//  UIElementInspector
//
//  Created by Danil Korotenko on 5/20/23.
//

#import "HotKeyController.h"
#import <Carbon/Carbon.h>
#import "AppDelegate.h"

EventHotKeyRef gMyHotKeyRef = NULL;
void (^callbackBlock)(void) = NULL;

// -------------------------------------------------------------------------------
//    LockUIElementHotKeyHandler:
//
//    We only register for one hotkey, so if we get here we know the hotkey combo was pressed
//    and we should go ahead and lock/unlock the current UIElement as needed
// -------------------------------------------------------------------------------
OSStatus LockUIElementHotKeyHandler(EventHandlerCallRef nextHandler,EventRef theEvent, void *userData)
{
    if (callbackBlock != NULL)
    {
        callbackBlock();
    }
    return noErr;
}

// -------------------------------------------------------------------------------
//    RegisterLockUIElementHotKey:
//
//    Encapsulate registering a hot key in one location
//    and we should go ahead and lock/unlock the current UIElement as needed
// -------------------------------------------------------------------------------
OSStatus RegisterLockUIElementHotKey(void (^aCallBackBlock)(void))
{
    callbackBlock = aCallBackBlock;

    EventTypeSpec eventType = { kEventClassKeyboard, kEventHotKeyReleased };
    InstallApplicationEventHandler(NewEventHandlerUPP(LockUIElementHotKeyHandler), 1, &eventType, NULL, NULL);

    EventHotKeyID hotKeyID = { 'lUIk', 1 }; // we make up the ID
    return RegisterEventHotKey(kVK_F7, cmdKey, hotKeyID, GetApplicationEventTarget(), 0, &gMyHotKeyRef); // Cmd-F7 will be the key to hit
}
