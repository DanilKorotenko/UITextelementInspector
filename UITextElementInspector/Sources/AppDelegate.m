//
//  AppDelegate.m
//  UITextElementInspector
//
//  Created by Danil Korotenko on 5/20/23.
//

#import "AppDelegate.h"
#import "AOAccessibilityElement.h"
#import "HotKeyController.h"

@interface AppDelegate ()

@property (strong) IBOutlet NSPanel *panel;
@property (strong) IBOutlet NSTextField *textField;

@property (strong) NSTimer *timer;

@property (strong) AOAccessibilityElement *currentElement;

@end

@implementation AppDelegate

#pragma mark -

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    if (!AXIsProcessTrusted())
    {
        NSLog(@"Accessibility is not granted. Go to settings and grant accessibility to this application.");
        [NSApp terminate:self];
    }

    self.panel.level = NSMainMenuWindowLevel;

    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1f repeats:YES
        block:^(NSTimer * _Nonnull timer)
        {
            [self updateUI];
        }];

    RegisterLockUIElementHotKey(
        ^{
            AOAccessibilityElement *focusedElement = [[AOAccessibilityElement systemElement] focusedElement];
            if (focusedElement.isPossibleToSetCurrentWordOrText)
            {
                [focusedElement setCurrentWordOrText:@"привет"];
            }
        });
}

- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app
{
    return YES;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

#pragma mark -

- (void)updateUI
{
    AOAccessibilityElement *focusedElement = [[AOAccessibilityElement systemElement] focusedElement];

    if (self.currentElement != focusedElement && !focusedElement.isOurElement &&
        (focusedElement.isRegularTextField || focusedElement.isTextArea))
    {
        NSMutableString *textToSet = [NSMutableString string];

//        [textToSet appendFormat:@"word on cursor: %@\n",
//            focusedElement.currentWordOrText];
        NSRange selectedRange = focusedElement.selectedTextRange;
        [textToSet appendFormat:@"cursor location: %lu\n",
            (unsigned long)selectedRange.location];


        self.textField.stringValue = textToSet;
    }
}

@end
