//
//  VLCStyledFullscreenHUDWindowView.m
//  Glasses
//
//  Created by Pierre d'Herbemont on 8/25/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "VLCStyledFullscreenHUDWindowView.h"


@implementation VLCStyledFullscreenHUDWindowView

- (void)awakeFromNib
{
    [self setup];    
}

- (void)setup
{
    [self setDrawsBackground:NO];
    
    [self setFrameLoadDelegate:self];
    [self setUIDelegate:self];
    [self setResourceLoadDelegate:self];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"hud" ofType:@"html"];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:path] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:5.];
    [[self mainFrame] loadRequest:request];    
}


#pragma mark -
#pragma mark WebViewDelegate

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
    //_isFrameLoaded = YES;        
   // [[self window] performSelector:@selector(invalidateShadow) withObject:self afterDelay:0.];
}

@end
