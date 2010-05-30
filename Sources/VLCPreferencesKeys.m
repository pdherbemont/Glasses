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
DEFINE(DontRememberUnfinishedMovies);
DEFINE(ScannedFolders);
DEFINE(DisableFolderScanning);

DEFINE(LastTVDBUpdateServerTime);

DEFINE(SuppressShareOnLANReminder);
DEFINE(DebugStyledWindow);
DEFINE(DebugFullscreen);
DEFINE(ShowDebugMenu);

DEFINE(LastFMEnabled);
DEFINE(lastFMUsername);
DEFINE(lastFMPassword);
