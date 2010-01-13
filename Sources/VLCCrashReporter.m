/*****************************************************************************
 * VLCCrashReporter.m: a crash reporting facility sending the logs to jones
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

#import "VLCCrashReporter.h"
#import <AddressBook/AddressBook.h>

@implementation VLCCrashReporter

- (NSString *)windowNibName
{
	return @"CrashReporter";
}

- (void)showUserDialog
{
    [NSApp runModalForWindow:[self window]];
}

- (void)crashReporterAction:(id)sender
{
    if (sender == _theOKButton)
        [self sendCrashLog:[NSString stringWithContentsOfFile:[self latestCrashLogPath] encoding:NSUTF8StringEncoding error:NULL] withUserComment:[_commentField string]];

    [NSApp stopModal];
    [[self window] orderOut:sender];
}

- (void)sendCrashLog:(NSString *)crashLog withUserComment:(NSString *)userComment
{
    NSString *urlStr = @"http://jones.videolan.org/crashlog/sendcrashreport.php";
    NSURL *url = [NSURL URLWithString:urlStr];

    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod:@"POST"];

    NSString * email;
    if ([_checkBox state] == NSOnState) {
        ABPerson * contact = [[ABAddressBook sharedAddressBook] me];
        ABMultiValue *emails = [contact valueForProperty:kABEmailProperty];
        email = [emails valueAtIndex:[emails indexForIdentifier:[emails primaryIdentifier]]];
    }
    else
        email = [NSString string];

    NSString *postBody;
    postBody = [NSString stringWithFormat:@"CrashLog=%@&Comment=%@&Email=%@\r\n",
                [crashLog stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                [userComment stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                [email stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

    [req setHTTPBody:[postBody dataUsingEncoding:NSUTF8StringEncoding]];

    /* Released from delegate */
    _crashLogURLConnection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [_crashLogURLConnection release];
    _crashLogURLConnection = nil;
    [self release];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSRunCriticalAlertPanel(@"Error when sending the Crash Report", [error localizedDescription], @"OK", nil, nil);
    [_crashLogURLConnection release];
    _crashLogURLConnection = nil;
    [self release];
}

- (NSString *)latestCrashLogPathPreviouslySeen:(BOOL)previouslySeen
{
    NSString * crashReporter = [@"~/Library/Logs/CrashReporter" stringByExpandingTildeInPath];
    NSDirectoryEnumerator *direnum = [[NSFileManager defaultManager] enumeratorAtPath:crashReporter];
    NSString *fname;
    NSString * latestLog = nil;
    int year  = !previouslySeen ? [[NSUserDefaults standardUserDefaults] integerForKey:@"LatestCrashReportYear"] : 0;
    int month = !previouslySeen ? [[NSUserDefaults standardUserDefaults] integerForKey:@"LatestCrashReportMonth"]: 0;
    int day   = !previouslySeen ? [[NSUserDefaults standardUserDefaults] integerForKey:@"LatestCrashReportDay"]  : 0;
    int hours = !previouslySeen ? [[NSUserDefaults standardUserDefaults] integerForKey:@"LatestCrashReportHours"]: 0;

    while ((fname = [direnum nextObject])) {
        [direnum skipDescendents];
        if([fname hasPrefix:@"Lunettes"] && [fname hasSuffix:@"crash"]) {
            NSArray * compo = [fname componentsSeparatedByString:@"_"];
            if( [compo count] < 3 ) continue;
            compo = [[compo objectAtIndex:1] componentsSeparatedByString:@"-"];
            if( [compo count] < 4 ) continue;

            // Dooh. ugly.
            if( year < [[compo objectAtIndex:0] intValue] ||
               (year ==[[compo objectAtIndex:0] intValue] &&
                (month < [[compo objectAtIndex:1] intValue] ||
                 (month ==[[compo objectAtIndex:1] intValue] &&
                  (day   < [[compo objectAtIndex:2] intValue] ||
                   (day   ==[[compo objectAtIndex:2] intValue] &&
                    hours < [[compo objectAtIndex:3] intValue] )))))) {
                       year  = [[compo objectAtIndex:0] intValue];
                       month = [[compo objectAtIndex:1] intValue];
                       day   = [[compo objectAtIndex:2] intValue];
                       hours = [[compo objectAtIndex:3] intValue];
                       latestLog = [crashReporter stringByAppendingPathComponent:fname];
                   }
        }
    }

    if(!(latestLog && [[NSFileManager defaultManager] fileExistsAtPath:latestLog]))
        return nil;

    if( !previouslySeen ) {
        [[NSUserDefaults standardUserDefaults] setInteger:year  forKey:@"LatestCrashReportYear"];
        [[NSUserDefaults standardUserDefaults] setInteger:month forKey:@"LatestCrashReportMonth"];
        [[NSUserDefaults standardUserDefaults] setInteger:day   forKey:@"LatestCrashReportDay"];
        [[NSUserDefaults standardUserDefaults] setInteger:hours forKey:@"LatestCrashReportHours"];
    }
    return latestLog;
}

- (NSString *)latestCrashLogPath
{
    return [self latestCrashLogPathPreviouslySeen:YES];
}

@end
