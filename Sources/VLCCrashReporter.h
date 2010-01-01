/*****************************************************************************
 * VLCCrashReporter.h: a crash reporting facility sending the logs to jones
 *****************************************************************************
 * Copyright (C) 2009-2010 the VideoLAN team
 * $Id:$
 *
 * Authors: Pierre d'Herbemont <pdherbemont at videolan dot org>
 *          Felix Paul Kühne <fkuehne at videolan dot org>
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

#import <Cocoa/Cocoa.h>


@interface VLCCrashReporter : NSWindowController {
    IBOutlet NSButton *_theOKButton;
    IBOutlet NSButton *_checkBox;
    IBOutlet NSTextView *_commentField;

    NSURLConnection *_crashLogURLConnection;
}
- (void)crashReporterAction:(id)sender;

- (void)sendCrashLog:(NSString *)crashLog withUserComment:(NSString *)userComment;
- (NSString *)latestCrashLogPathPreviouslySeen:(BOOL)value;
- (NSString *)latestCrashLogPath;
- (void)showUserDialog;

@end
