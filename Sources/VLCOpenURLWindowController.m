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

- (IBAction)openNetworkStream:(id)sender
{
    NSWindow *window = [self window];
    int returnValue = [NSApp runModalForWindow:window];
    [window orderOut:sender];
    if (returnValue) {
        NSDocumentController *documentController = [NSDocumentController sharedDocumentController];
        NSURL *url = [NSURL URLWithString:[_netURLField stringValue]];
        NSDocument *tempDoc = [documentController openDocumentWithContentsOfURL:url display:YES error:nil];
        if (tempDoc) {
            [documentController addDocument:tempDoc];
            [documentController noteNewRecentDocumentURL:url];
        }
    }
}

- (IBAction)networkPanelAction:(id)sender
{
    if ([[sender title] isEqualToString:@"Open"])
        [NSApp stopModalWithCode:1];
    else
        [NSApp stopModalWithCode:0];
}

@end
