/*****************************************************************************
 * VLCExceptionHandler.m: VLCExceptionHandler implementation
 *****************************************************************************
 * Copyright (C) 2007 Pierre d'Herbemont
 * Copyright (C) 2007 the VideoLAN team
 * $Id$
 *
 * Authors: Pierre d'Herbemont <pdherbemont # videolan.org>
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

#import "VLCExceptionHandler.h"
#import <ExceptionHandling/ExceptionHandling.h>

static void VLCUncaughtExceptionHandler(NSException *exception)
{
    [[VLCExceptionHandler sharedHandler] handleUncaughtException:exception];
}

@implementation VLCExceptionHandler
static VLCExceptionHandler *expectionHandlerDelegate = nil;
+ (void)load
{
    expectionHandlerDelegate = [[VLCExceptionHandler alloc] init];
    NSExceptionHandler *handler = [NSExceptionHandler defaultExceptionHandler];
    [handler setDelegate:expectionHandlerDelegate];

    NSUInteger mask = NSLogAndHandleEveryExceptionMask;

    [handler setExceptionHandlingMask:mask];
}

+ (VLCExceptionHandler *)sharedHandler
{
    return expectionHandlerDelegate;
}

- (void)setup
{
    NSSetUncaughtExceptionHandler(VLCUncaughtExceptionHandler);
}

- (void)handleUncaughtException:(NSException *)exception
{
    @try {
        // From now on, just log followin exception
        [[NSExceptionHandler defaultExceptionHandler] setExceptionHandlingMask:0];

        NSLog(@"*** Exception Handled! %@: %@", [exception name], [exception reason]);
        [self printStackTrace:exception];
#ifdef DEBUG
        NSString *continueString = @"Attempt to continue";
#else
        NSString *continueString = nil;
#endif
        int ret = NSRunCriticalAlertPanel(@"Exception not handled!",
                                          [NSString stringWithFormat:@"%@: %@\n\nBack trace has been printed to Console.\n\n",
                                           [exception name], [exception reason]],
                                          @"Quit", continueString, nil);
        if (ret != NSOKButton)
            return;

        abort();
    }
    @catch (NSException *e) {
        abort();
    }
}

/* From Apple's guide on exception */
- (BOOL)exceptionHandler:(NSExceptionHandler *)sender shouldLogException:(NSException *)exception mask:(NSUInteger)aMask
{
    return NO;
}

- (BOOL)exceptionHandler:(NSExceptionHandler *)sender shouldHandleException:(NSException *)exception mask:(NSUInteger)mask
{
#ifdef DEBUG
    [self handleUncaughtException:exception];
#endif
    return NO;
}

- (void)printStackTrace:(NSException *)e
{
    BOOL atosExists = [[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/atos"];
    if (!atosExists)
        return;
    NSString *stack = [[e userInfo] objectForKey:NSStackTraceKey];
    if (!stack) {
        NSLog(@"No stack trace available.");
        return;
    }

    NSTask *ls = [[NSTask alloc] init];
    NSString *pid = [[NSNumber numberWithInt:[[NSProcessInfo processInfo] processIdentifier]] stringValue];
    NSMutableArray *args = [NSMutableArray arrayWithCapacity:20];

    [args addObject:@"-p"];
    [args addObject:pid];
    [args addObjectsFromArray:[stack componentsSeparatedByString:@"  "]];
    /* Note: function addresses are separated by double spaces, not a single space. */

    [ls setLaunchPath:@"/usr/bin/atos"];
    [ls setArguments:args];
    [ls launch];

    [ls release];
}

@end
