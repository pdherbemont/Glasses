/*****************************************************************************
 * VLCOpenURLWindowController.m: Open dialogues
 *****************************************************************************
 * Copyright (C) 2009 the VideoLAN team
 * $Id:$
 *
 * Authors:Felix Paul Kühne <fkuehne at videolan dot org>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/

#import "VLCOpenURLWindowController.h"
#import "VLCDocumentController.h"

@implementation VLCOpenURLWindowController

- (NSString *)windowNibName
{
    return @"OpenURLWindow";
}

- (void)addItemToRecentList:(NSString *)urlString
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // Save it as the last item added to the list.
    [defaults setValue:urlString forKey:kLastNetworkItems];

    // Now add this item to the recent list
    NSArray *originalRecents = [defaults arrayForKey:kRecentNetworkItems];

    // No previous item
    if (!originalRecents) {
        [defaults setValue:[NSArray arrayWithObject:urlString] forKey:kRecentNetworkItems];
        return;
    }

    NSUInteger count = MIN(10UL, [originalRecents count]);
    NSArray *tenMostRecents = [originalRecents objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, count)]];
    NSMutableArray *recents = [NSMutableArray arrayWithArray:tenMostRecents];

    // Remove the last one, or the current position of read item.
    NSUInteger index = [recents indexOfObjectIdenticalTo:urlString];
    if (index != NSNotFound)
        [recents removeObjectAtIndex:index];
    else if (count >= 10)
        [recents removeLastObject];
    [recents insertObject:urlString atIndex:0];

    // Save it.
    [defaults setValue:recents forKey:kRecentNetworkItems];
}

- (IBAction)openNetworkStream:(id)sender
{
    NSWindow *window = [self window];
    int returnValue = [NSApp runModalForWindow:window];
    [window orderOut:sender];
    if (returnValue) {
        NSURL *url = [NSURL URLWithString:[_netURLField stringValue]];
        [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:url display:YES error:nil];
        [self addItemToRecentList:[url absoluteString]];
    }
}

- (IBAction)clearRecentItems:(NSButton *)sender
{
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    [standardUserDefaults setValue:[NSArray array] forKey:kLastNetworkItems];
    [standardUserDefaults setValue:[NSArray array] forKey:kRecentNetworkItems];
}

- (IBAction)networkPanelAction:(NSButton *)sender
{
    if ([[sender title] isEqualToString: @"Open"])
        [NSApp stopModalWithCode:1];
    else
        [NSApp stopModalWithCode:0];
}

@end
