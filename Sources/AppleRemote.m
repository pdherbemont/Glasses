/*****************************************************************************
 * AppleRemote.m
 * AppleRemote
 * $Id: 69481842a707cfa929f4e2c8d18f245fd38dd1c4 $
 *
 * Created by Martin Kahr on 11.03.06 under a MIT-style license.
 * Copyright (c) 2006 martinkahr.com. All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 *****************************************************************************
 *
 * Note that changes made by any members or contributors of the VideoLAN team
 * (i.e. changes that were exclusively checked in to one of VideoLAN's source code
 * repositories) are licensed under the GNU General Public License version 2,
 * or (at your option) any later version.
 * Thus, the following statements apply to our changes:
 *
 * Copyright (C) 2006-2009 the VideoLAN team
 * Authors: Eric Petit <titer@m0k.org>
 *          Felix Kühne <fkuehne at videolan dot org>
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

#import "AppleRemote.h"

const char* AppleRemoteDeviceName = "AppleIRController";
const int REMOTE_SWITCH_COOKIE=19;
const NSTimeInterval DEFAULT_MAXIMUM_CLICK_TIME_DIFFERENCE=0.35;
const NSTimeInterval HOLD_RECOGNITION_TIME_INTERVAL=0.4;

#define Log(...) if (0) NSLog(__VA_ARGS__)

@implementation AppleRemote

- (id)init {
    if((self = [super init]))
    {
        _openInExclusiveMode = YES;
        _cookieToButtonMapping = [[NSMutableDictionary alloc] init];
        _maxClickTimeDifference = DEFAULT_MAXIMUM_CLICK_TIME_DIFFERENCE;

        if (NSAppKitVersionNumber < 1038.13) {
            /* Leopard and early Snow Leopard Cookies */
            Log(@"using Leopard AR cookies");
            [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonVolume_Plus]  forKey:@"31_29_28_18_"];
            [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonVolume_Minus] forKey:@"31_30_28_18_"];
            [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonMenu]         forKey:@"31_20_18_31_20_18_"];
            [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonPlay]         forKey:@"31_21_18_31_21_18_"];
            [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonRight]        forKey:@"31_22_18_31_22_18_"];
            [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonLeft]         forKey:@"31_23_18_31_23_18_"];
            [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonRight_Hold]   forKey:@"31_18_4_2_"];
            [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonLeft_Hold]    forKey:@"31_18_3_2_"];
            [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonMenu_Hold]    forKey:@"31_18_31_18_"];
            [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonPlay_Sleep]   forKey:@"35_31_18_35_31_18_"];
            [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteControl_Switched]   forKey:@"19_"];
        }
        else {
            /* current Snow Leopard cookies */
            Log(@"using Snow Leopard AR cookies");
            [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonVolume_Plus]  forKey:@"33_31_30_21_20_2_"];
            [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonVolume_Minus] forKey:@"33_32_30_21_20_2_"];
            [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonMenu]         forKey:@"33_22_21_20_2_33_22_21_20_2_"];
            [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonPlay]         forKey:@"33_23_21_20_2_33_23_21_20_2_"];
            [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonRight]        forKey:@"33_24_21_20_2_33_24_21_20_2_"];
            [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonLeft]         forKey:@"33_25_21_20_2_33_25_21_20_2_"];
            [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonRight_Hold]   forKey:@"33_21_20_14_12_2_"];
            [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonLeft_Hold]    forKey:@"33_21_20_13_12_2_"];
            [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonMenu_Hold]    forKey:@"33_21_20_2_33_21_20_2_"];
            [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonPlay_Sleep]   forKey:@"37_33_21_20_2_37_33_21_20_2_"];
            [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteControl_Switched]   forKey:@"19_"];
            [_cookieToButtonMapping setObject:[NSNumber numberWithInt:k2009RemoteButtonPlay]       forKey:@"33_21_20_8_2_33_21_20_8_2_"];
            [_cookieToButtonMapping setObject:[NSNumber numberWithInt:k2009RemoteButtonMiddlePlay] forKey:@"33_21_20_3_2_33_21_20_3_2_"];
        }
    }

    /* defaults */
    [self setSimulatesPlusMinusHold:YES];

    return self;
}

- (void)dealloc {
    [self setListeningOnAppActivate:NO]; // This free _appDelegate and set back the old delegate.
    [self stopListening:self];
    [_cookieToButtonMapping release];
    VLCAssert(!_allCookies, @"should be released");

    [super dealloc];
}

- (int)remoteId
{
    return _remoteId;
}

- (BOOL)isRemoteAvailable
{
    io_object_t hidDevice = [self findAppleRemoteDevice];
    if (hidDevice != 0){
        IOObjectRelease(hidDevice);
        return YES;
    } else
        return NO;
}

- (BOOL)isListeningToRemote
{
    return _hidDeviceInterface != NULL && _allCookies != NULL && _queue != NULL;
}

- (void)setListeningToRemote:(BOOL)value
{
    if (value == [self isListeningToRemote])
        return;

    if (value == NO)
        [self stopListening:self];
    else
        [self startListening:self];
}

/* Delegates are not retained!
 * http://developer.apple.com/documentation/Cocoa/Conceptual/CocoaFundamentals/CommunicatingWithObjects/chapter_6_section_4.html
 * Delegating objects do not (and should not) retain their delegates.
 * However, clients of delegating objects (applications, usually) are responsible for ensuring that their delegates are around
 * to receive delegation messages. To do this, they may have to retain the delegate. */
- (void)setDelegate:(id)delegate
{
    if (delegate && ![delegate respondsToSelector:@selector(appleRemoteButton:pressedDown:clickCount:)])
        return;

    _delegate = delegate;
}

- (id)delegate
{
    return _delegate;
}

- (BOOL)isOpenInExclusiveMode
{
    return _openInExclusiveMode;
}
- (void)setOpenInExclusiveMode:(BOOL)value
{
    _openInExclusiveMode = value;
}

- (BOOL)clickCountingEnabled
{
    return _clickCountEnabledButtons != 0;
}

- (void)setClickCountingEnabled:(BOOL)value
{
    unsigned buttons = 0;
    if (value) {
        buttons = kRemoteButtonVolume_Plus | kRemoteButtonVolume_Minus
                | kRemoteButtonPlay | kRemoteButtonLeft | kRemoteButtonRight
                | kRemoteButtonMenu | k2009RemoteButtonPlay
                | k2009RemoteButtonMiddlePlay;
    }
    [self setClickCountEnabledButtons:buttons];
}

- (unsigned)clickCountEnabledButtons
{
    return _clickCountEnabledButtons;
}

- (void)setClickCountEnabledButtons:(unsigned)value
{
    _clickCountEnabledButtons = value;
}

- (NSTimeInterval)maximumClickCountTimeDifference
{
    return _maxClickTimeDifference;
}

- (void)setMaximumClickCountTimeDifference:(NSTimeInterval)timeDiff
{
    _maxClickTimeDifference = timeDiff;
}

- (BOOL)processesBacklog
{
    return _processesBacklog;
}

- (void)setProcessesBacklog:(BOOL)value
{
    _processesBacklog = value;
}

- (BOOL)listeningOnAppActivate
{
    return _listeningOnAppActivate;
}

- (void)setListeningOnAppActivate:(BOOL)value
{
    if (value == _listeningOnAppActivate)
        return;
    _listeningOnAppActivate = value;
    if (value) {
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(applicationDidBecomeActive:)name:NSApplicationDidBecomeActiveNotification object:NSApp];
        [center addObserver:self selector:@selector(applicationWillResignActive:)name:NSApplicationWillResignActiveNotification object:NSApp];
    } else {
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center removeObserver:self name:NSApplicationDidBecomeActiveNotification object:NSApp];
        [center removeObserver:self name:NSApplicationWillResignActiveNotification object:NSApp];
    }
}

- (BOOL)simulatesPlusMinusHold
{
    return _simulatePlusMinusHold;
}

- (void)setSimulatesPlusMinusHold:(BOOL)value
{
    _simulatePlusMinusHold = value;
}

- (IBAction)startListening:(id)sender
{
    if ([self isListeningToRemote])
        return;

    io_object_t hidDevice = [self findAppleRemoteDevice];
    if (!hidDevice)
        return;

    if (![self createInterfaceForDevice:hidDevice])
        goto error;

    if (![self initializeCookies])
        goto error;

    if (![self openDevice])
        goto error;

    IOObjectRelease(hidDevice);
    return;

error:
    [self stopListening:self];
    IOObjectRelease(hidDevice);
}

- (IBAction)stopListening:(id)sender
{
    if (_eventSource != NULL) {
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), _eventSource, kCFRunLoopDefaultMode);
        CFRelease(_eventSource);
        _eventSource = NULL;
    }
    if (_queue != NULL) {
        (*_queue)->stop(_queue);

        //dispose of queue
        (*_queue)->dispose(_queue);

        //release the queue we allocated
        (*_queue)->Release(_queue);

        _queue = NULL;
    }

    if (_allCookies != nil) {
        [_allCookies release];
        _allCookies = nil;
    }

    if (_hidDeviceInterface != NULL) {
        //close the device
        (*_hidDeviceInterface)->close(_hidDeviceInterface);

        //release the interface
        (*_hidDeviceInterface)->Release(_hidDeviceInterface);

        _hidDeviceInterface = NULL;
    }
}

@end

@implementation AppleRemote (Singleton)

static AppleRemote *sharedInstance = nil;

+ (AppleRemote*)sharedRemote
{
    @synchronized(self) {
        if (!sharedInstance)
            sharedInstance = [[self alloc] init];
    }
    return sharedInstance;
}

+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized(self) {
        if (!sharedInstance)
            return [super allocWithZone:zone];
    }
    return sharedInstance;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain
{
    return self;
}

- (NSUInteger)retainCount
{
    return UINT_MAX;  //denotes an object that cannot be released
}

- (void)release
{
    //do nothing
}

- (id)autorelease
{
    return self;
}

@end

@implementation AppleRemote (PrivateMethods)

- (void)setRemoteId:(int)value
{
    _remoteId = value;
}

- (IOHIDQueueInterface**)queue
{
    return _queue;
}

- (IOHIDDeviceInterface**)hidDeviceInterface
{
    return _hidDeviceInterface;
}


- (NSDictionary*)cookieToButtonMapping
{
    return _cookieToButtonMapping;
}

- (NSString*)validCookieSubstring:(NSString*)cookieString
{
    if (!cookieString || ![cookieString length])
        return nil;

    NSEnumerator* keyEnum = [[self cookieToButtonMapping] keyEnumerator];
    NSString* key;
    while((key = [keyEnum nextObject])) {
        NSRange range = [cookieString rangeOfString:key];
        if (range.location == 0)
            return key;
    }
    return nil;
}

- (void)sendSimulatedPlusMinusEvent:(id)time
{
    BOOL startSimulateHold = NO;
    AppleRemoteEventIdentifier event = _lastPlusMinusEvent;
    @synchronized(self) {
        startSimulateHold = _lastPlusMinusEvent > 0 && _lastPlusMinusEventTime == [time doubleValue];
    }
    if (startSimulateHold) {
        _lastEventSimulatedHold = YES;
        event = (event == kRemoteButtonVolume_Plus) ? kRemoteButtonVolume_Plus_Hold : kRemoteButtonVolume_Minus_Hold;
        [_delegate appleRemoteButton:event pressedDown:YES clickCount:1];
    }
}

- (void)sendRemoteButtonEvent:(AppleRemoteEventIdentifier)event pressedDown:(BOOL)pressedDown
{
    if (!_delegate)
        return;
    if (_simulatePlusMinusHold) {
        if (event == kRemoteButtonVolume_Plus || event == kRemoteButtonVolume_Minus) {
            if (pressedDown) {
                _lastPlusMinusEvent = event;
                _lastPlusMinusEventTime = [NSDate timeIntervalSinceReferenceDate];
                [self performSelector:@selector(sendSimulatedPlusMinusEvent:)
                           withObject:[NSNumber numberWithDouble:_lastPlusMinusEventTime]
                           afterDelay:HOLD_RECOGNITION_TIME_INTERVAL];
                return;
            } else {
                if (_lastEventSimulatedHold) {
                    event = (event==kRemoteButtonVolume_Plus) ? kRemoteButtonVolume_Plus_Hold : kRemoteButtonVolume_Minus_Hold;
                    _lastPlusMinusEvent = 0;
                    _lastEventSimulatedHold = NO;
                } else {
                    @synchronized(self) {
                        _lastPlusMinusEvent = 0;
                    }
                    pressedDown = YES;
                }
            }
        }
    }

    if (([self clickCountEnabledButtons] & event) == event) {
        if (!pressedDown && (event == kRemoteButtonVolume_Minus || event == kRemoteButtonVolume_Plus))
            return; // this one is triggered automatically by the handler

        NSNumber *eventNumber;
        NSNumber *timeNumber;
        @synchronized(self) {
            _lastClickCountEventTime = [NSDate timeIntervalSinceReferenceDate];
            if (_lastClickCountEvent == event)
                _eventClickCount++;
            else
                _eventClickCount = 1;
            _lastClickCountEvent = event;
            timeNumber = [NSNumber numberWithDouble:_lastClickCountEventTime];
            eventNumber= [NSNumber numberWithUnsignedInt:event];
        }
        [self performSelector:@selector(executeClickCountEvent:)
                   withObject:[NSArray arrayWithObjects:eventNumber, timeNumber, nil]
                   afterDelay:_maxClickTimeDifference];
    } else
        [_delegate appleRemoteButton:event pressedDown:pressedDown clickCount:1];
}

- (void)executeClickCountEvent:(NSArray*)values {
    AppleRemoteEventIdentifier event = [[values objectAtIndex:0] unsignedIntValue];
    NSTimeInterval eventTimePoint = [[values objectAtIndex:1] doubleValue];

    BOOL finishedClicking = NO;
    int finalClickCount = _eventClickCount;

    @synchronized(self) {
        finishedClicking = (event != _lastClickCountEvent || eventTimePoint == _lastClickCountEventTime);
        if (finishedClicking)
            _eventClickCount = 0;
    }

    if (finishedClicking) {
        [_delegate appleRemoteButton:event pressedDown:YES clickCount:finalClickCount];
        if (![self simulatesPlusMinusHold] && (event == kRemoteButtonVolume_Minus || event == kRemoteButtonVolume_Plus)) {
            // trigger a button release event, too
            [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
            [_delegate appleRemoteButton:event pressedDown:NO clickCount:finalClickCount];
        }
    }

}

- (void)handleEventWithCookieString:(NSString*)cookieString sumOfValues:(SInt32)sumOfValues
{
    if (!cookieString || ![cookieString length])
        return;
    NSNumber *buttonId = [[self cookieToButtonMapping] objectForKey:cookieString];

    if (buttonId != nil) {
        switch ([buttonId intValue]) {
            case k2009RemoteButtonPlay:
            case k2009RemoteButtonMiddlePlay:
                buttonId = [NSNumber numberWithInt:kRemoteButtonPlay];
                break;
            default:
                break;
        }
        [self sendRemoteButtonEvent:[buttonId intValue] pressedDown:(sumOfValues>0)];
    } else {
        // let's see if a number of events are stored in the cookie string. this does
        // happen when the main thread is too busy to handle all incoming events in time.
        NSString *subCookieString;
        NSString *lastSubCookieString=nil;
        while((subCookieString = [self validCookieSubstring:cookieString])) {
            cookieString = [cookieString substringFromIndex:[subCookieString length]];
            lastSubCookieString = subCookieString;
            if (_processesBacklog)
                [self handleEventWithCookieString:subCookieString sumOfValues:sumOfValues];
        }
        if (!_processesBacklog && lastSubCookieString) {
            // process the last event of the backlog and assume that the button is not pressed down any longer.
            // The events in the backlog do not seem to be in order and therefore (in rare cases) the last event might be
            // a button pressed down event while in reality the user has released it.
            // Log(@"processing last event of backlog");
            [self handleEventWithCookieString:lastSubCookieString sumOfValues:0];
        }
        if ([cookieString length] > 0)
            Log(@"Warning: Unknown AR button for cookiestring %@", cookieString);
    }
}

@end

/*  Callback method for the device queue
Will be called for any event of any type (cookie) to which we subscribe
*/
static void QueueCallbackFunction(void* target,  IOReturn result, void* refcon, void* sender) {
    AppleRemote* remote = (AppleRemote*)target;

    IOHIDEventStruct event;
    AbsoluteTime     zeroTime = {0,0};
    NSMutableString* cookieString = [NSMutableString string];
    SInt32           sumOfValues = 0;
    while (result == kIOReturnSuccess)
    {
        result = (*[remote queue])->getNextEvent([remote queue], &event, zeroTime, 0);
        if ( result != kIOReturnSuccess )
            continue;

        //printf("%d %d %d\n", event.elementCookie, event.value, event.longValue);

        if (REMOTE_SWITCH_COOKIE == (int)event.elementCookie) {
            [remote setRemoteId:event.value];
            [remote handleEventWithCookieString:@"19_" sumOfValues:0];
        } else {
            if (((int)event.elementCookie)!=5) {
                sumOfValues+=event.value;
                [cookieString appendString:[NSString stringWithFormat:@"%d_", event.elementCookie]];
            }
        }
    }

    [remote handleEventWithCookieString:cookieString sumOfValues:sumOfValues];
}

@implementation AppleRemote (IOKitMethods)

- (IOHIDDeviceInterface**) createInterfaceForDevice:(io_object_t)hidDevice {
    io_name_t               className;
    IOCFPlugInInterface**   plugInInterface = NULL;
    HRESULT                 plugInResult = S_OK;
    SInt32                  score = 0;
    IOReturn                ioReturnValue = kIOReturnSuccess;

    VLCAssert(!_hidDeviceInterface, @"Should be NULL or we leak");

    ioReturnValue = IOObjectGetClass(hidDevice, className);

    VLCAssert(ioReturnValue == kIOReturnSuccess, @"Error: Failed to get IOKit class name.");

    ioReturnValue = IOCreatePlugInInterfaceForService(hidDevice,
                                                      kIOHIDDeviceUserClientTypeID,
                                                      kIOCFPlugInInterfaceID,
                                                      &plugInInterface,
                                                      &score);
    if (ioReturnValue == kIOReturnSuccess)
    {
        //Call a method of the intermediate plug-in to create the device interface
        plugInResult = (*plugInInterface)->QueryInterface(plugInInterface, CFUUIDGetUUIDBytes(kIOHIDDeviceInterfaceID), (LPVOID) &_hidDeviceInterface);

        VLCAssert(plugInResult == S_OK, @"Error: Couldn't create HID class device interface");

        // Release
        if (plugInInterface)
            (*plugInInterface)->Release(plugInInterface);
    }
    return _hidDeviceInterface;
}

- (io_object_t)findAppleRemoteDevice {
    CFMutableDictionaryRef hidMatchDictionary = NULL;
    IOReturn ioReturnValue = kIOReturnSuccess;
    io_iterator_t hidObjectIterator = 0;
    io_object_t hidDevice = 0;

    // Set up a matching dictionary to search the I/O Registry by class
    // name for all HID class devices
    hidMatchDictionary = IOServiceMatching(AppleRemoteDeviceName);

    // Now search I/O Registry for matching devices.
    ioReturnValue = IOServiceGetMatchingServices(kIOMasterPortDefault, hidMatchDictionary, &hidObjectIterator);

    if ((ioReturnValue == kIOReturnSuccess) && (hidObjectIterator != 0)) {
        hidDevice = IOIteratorNext(hidObjectIterator);
    }

    // release the iterator
    IOObjectRelease(hidObjectIterator);

    return hidDevice;
}

- (BOOL)initializeCookies
{
    /* Already initialized */
    if (_allCookies)
        return YES;

    IOHIDDeviceInterface122** handle = (IOHIDDeviceInterface122**)_hidDeviceInterface;
    if (!handle || !(*handle))
        return NO;

    /* Copy all elements, since we're grabbing most of the elements
     * for this device anyway, and thus, it's faster to iterate them
     * ourselves. When grabbing only one or two elements, a matching
     * dictionary should be passed in here instead of NULL. */
    CFArrayRef elements;
    IOReturn success = (*handle)->copyMatchingElements(handle, NULL, &elements);
    if (success != kIOReturnSuccess)
        return NO;

    /*
     cookies = calloc(NUMBER_OF_APPLE_REMOTE_ACTIONS, sizeof(IOHIDElementCookie));
     memset(cookies, 0, sizeof(IOHIDElementCookie) * NUMBER_OF_APPLE_REMOTE_ACTIONS);
     */
    VLCAssert(!_allCookies, @"We would be leaking _allCookies");
    _allCookies = [[NSMutableArray alloc] init];
    for (CFIndex i = 0; i < CFArrayGetCount(elements); i++) {
        NSDictionary *element = (id)CFArrayGetValueAtIndex(elements, i);

        //Get cookie
        id object = [element valueForKey:(NSString*)CFSTR(kIOHIDElementCookieKey)];
        if (!object || ![object isKindOfClass:[NSNumber class]])
            continue;

        IOHIDElementCookie cookie = (IOHIDElementCookie) [object pointerValue];

#if 0
        // Left over for documentation purpose.
        //Get usage
        object = [element valueForKey:(NSString*)CFSTR(kIOHIDElementUsageKey)];
        if (object == nil || ![object isKindOfClass:[NSNumber class]])
            continue;
        long usage = [object longValue];

        //Get usage page
        object = [element valueForKey:(NSString*)CFSTR(kIOHIDElementUsagePageKey)];
        if (object == nil || ![object isKindOfClass:[NSNumber class]])
            continue;
        long usagePage = [object longValue];
#endif
        [_allCookies addObject:[NSNumber numberWithInt:(int)cookie]];
    }
    CFRelease(elements);
    return YES;
}

- (BOOL)openDevice {
    HRESULT  result;

    IOHIDOptionsType openMode = kIOHIDOptionsTypeNone;
    if ([self isOpenInExclusiveMode])
        openMode = kIOHIDOptionsTypeSeizeDevice;
    IOReturn ioReturnValue = (*_hidDeviceInterface)->open(_hidDeviceInterface, openMode);

    if (ioReturnValue != KERN_SUCCESS) {
        NSLog(@"Can't open the Remote Control %s", [self isOpenInExclusiveMode] ? "In exclusive mode" : "");
        return FALSE;
    }
    //VLCAssert(ioReturnValue == KERN_SUCCESS, @"Error when opening HUD device");

    VLCAssert(!_queue, @"We are going to leak _queue");
    _queue = (*_hidDeviceInterface)->allocQueue(_hidDeviceInterface);
    VLCAssert(_queue, @"Error when creating async event source");
    result = (*_queue)->create(_queue, 0, 12);    //depth: maximum number of elements in queue before oldest elements in queue begin to be lost.
    VLCAssert(result == kIOReturnSuccess, @"Can't init the remote");

    for(NSUInteger i = 0; i < [_allCookies count]; i++) {
        IOHIDElementCookie cookie = (IOHIDElementCookie)[[_allCookies objectAtIndex:i] intValue];
        (*_queue)->addElement(_queue, cookie, 0);
    }

    // add callback for async events
    ioReturnValue = (*_queue)->createAsyncEventSource(_queue, &_eventSource);
    VLCAssert(ioReturnValue == KERN_SUCCESS, @"Error when creating async event source");
    ioReturnValue = (*_queue)->setEventCallout(_queue, QueueCallbackFunction, self, NULL);
    VLCAssert(ioReturnValue == KERN_SUCCESS, @"Error when setting event callout");
    CFRunLoopAddSource(CFRunLoopGetCurrent(), _eventSource, kCFRunLoopDefaultMode);
    //start data delivery to queue
    (*_queue)->start(_queue);
    return YES;
}

@end

@implementation AppleRemote (NSAppObserver)


- (void)applicationDidBecomeActive:(NSNotification *)aNotification {
    [self setListeningToRemote:YES];
}

- (void)applicationWillResignActive:(NSNotification *)aNotification {
    [self setListeningToRemote:NO];
}

@end
