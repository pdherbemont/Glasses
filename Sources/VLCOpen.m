/*****************************************************************************
 * VLCOpen.m: Open dialogues
 *****************************************************************************
 * Copyright (C) 2009 the VideoLAN team
 * $Id: $
 *
 * Authors: Felix Paul Kühne <fkuehne at videolan dot org>
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

#import "VLCOpen.h"
#import "VLCDocumentController.h"

@implementation VLCOpen

static VLCOpen *_o_sharedInstance = nil;

+ (VLCOpen *)sharedInstance
{
    return _o_sharedInstance ? _o_sharedInstance : [[self alloc] init];
}

- (id)init
{
    if (_o_sharedInstance) {
        [self dealloc];
    } else {
        _o_sharedInstance = [super init];
        if( !b_nib_loaded )
            b_nib_loaded = [NSBundle loadNibNamed:@"Open" owner:self];
    }

    return _o_sharedInstance;
}

- (IBAction)openNetworkStream:(id)sender {
    int i_returnValue = 0;

    i_returnValue = [NSApp runModalForWindow: o_net_win];
    [o_net_win orderOut: sender];
    if( i_returnValue ) {
        NSDocument *tempDoc = [[VLCDocumentController sharedDocumentController] openDocumentWithContentsOfURL:[NSURL URLWithString: [o_net_url_fld stringValue]] display: YES error: nil];
        if( tempDoc ) {
            [[VLCDocumentController sharedDocumentController] addDocument: tempDoc];
            [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL: [NSURL URLWithString: [o_net_url_fld stringValue]]];
        }
    }
}

- (IBAction)networkPanelAction:(id)sender {
    if( [[sender title] isEqualToString: @"Open"] )
        [NSApp stopModalWithCode: 1];
    else
        [NSApp stopModalWithCode: 0];
}

@end
