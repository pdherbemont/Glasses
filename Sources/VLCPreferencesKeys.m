//
//  VLCPreferencesKeys.m
//  Lunettes
//
//  Created by Pierre d'Herbemont on 12/19/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "VLCPreferencesKeys.h"

#define DEFINE(a) NSString *k##a = @#a;
DEFINE(SelectedSnapshotFolder);
DEFINE(DontRememberMediaPosition);
DEFINE(DontShowSplashScreen);
DEFINE(ControlWithMediaKeys);
DEFINE(ControlWithMediaKeysInBackground);
DEFINE(ControlWithHIDRemote);
DEFINE(UseDeinterlaceFilter);
DEFINE(LastSelectedStyle);
DEFINE(WatchForStyleModification);
DEFINE(StartPlaybackInFullscreen);
DEFINE(RecentNetworkItems);
DEFINE(LastNetworkItems);

DEFINE(UnfinishedMoviesAsArray);

DEFINE(DebugStyledWindow);
DEFINE(DebugFullscreen);
DEFINE(ShowDebugMenu);
