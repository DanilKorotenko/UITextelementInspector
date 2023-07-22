//
//  AppDelegate.m
//  UITextElementInspector
//
//  Created by Danil Korotenko on 5/20/23.
//

#import "AppDelegate.h"
#import "AOAccessibilityElement.h"

@interface AppDelegate ()

@property (strong) IBOutlet NSWindow *window;
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

    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1f repeats:YES
        block:^(NSTimer * _Nonnull timer)
        {
            [self updateUI];
        }];
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

    if (self.currentElement != focusedElement)
    {
        NSMutableString *textToSet = [NSMutableString string];
        [textToSet appendFormat:@"focused element role: %@\n", focusedElement.role];
        [textToSet appendFormat:@"focused element subrole: %@\n", focusedElement.subrole];
        [textToSet appendFormat:@"focused element isRegularTextField: %@\n",
            focusedElement.isRegularTextField ? @"YES" : @"NO"];
        [textToSet appendFormat:@"focused element isTextArea: %@\n",
            focusedElement.isTextArea ? @"YES" : @"NO"];
        [textToSet appendFormat:@"focused element isSecureTextField: %@\n",
            focusedElement.isSecureTextField ? @"YES" : @"NO"];
        [textToSet appendFormat:@"focused element selected Text range: %@\n",
            [AOAccessibilityElement rangeDescription:focusedElement.selectedTextRange]];
        [textToSet appendFormat:@"focused element current word: %@\n",
            focusedElement.currentWordOrText];
        [textToSet appendFormat:@"focused element string value: %@\n",
            focusedElement.stringValue];

        self.textField.stringValue = textToSet;
    }
}

@end
