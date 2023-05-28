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

@end

@implementation AppDelegate

#pragma mark -

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    if (!AXIsProcessTrusted())
    {
        NSLog(@"Activate accessibility.");
        [NSApp terminate:self];
    }

    [AOAccessibilityElement systemElement];

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



@end
