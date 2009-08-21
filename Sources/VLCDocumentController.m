/*****************************************************************************
 * VLCDocumentController.m: NSDocumentController in customized
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

#import "VLCDocumentController.h"
#import "VLCMediaDocument.h"

@implementation VLCDocumentController

- (BOOL) becomeFirstResponder {
    return YES;
}

- (NSString *)typeForContentsOfURL:(NSURL *)inAbsoluteURL error:(NSError **)outError {
    if( [[inAbsoluteURL scheme] isEqualToString:@"http"] || [[inAbsoluteURL scheme] isEqualToString:@"mms"] || [[inAbsoluteURL scheme] isEqualToString:@"ftp"] || [[inAbsoluteURL scheme] isEqualToString:@"rtsp"] || [[inAbsoluteURL scheme] isEqualToString:@"rtmp"] || [[inAbsoluteURL scheme] isEqualToString:@"udp"] || [[inAbsoluteURL scheme] isEqualToString:@"file"] )
        return @"VLCMediaDocument";

    return nil;
}

- (Class)documentClassForType:(NSString *)typeName {
    return [VLCMediaDocument class];
}

@end
