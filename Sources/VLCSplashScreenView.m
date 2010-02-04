//
//  VLCSplashScreenView.m
//  Lunettes
//
//  Created by Pierre d'Herbemont on 2/1/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "VLCSplashScreenView.h"


@implementation VLCSplashScreenView
- (NSString *)pageName
{
    return @"splash-screen";
}

- (NSURL *)urlForPluginName:(NSString *)pluginName
{
    NSAssert(pluginName, @"pluginName shouldn't be null.");
    NSString *pluginFilename = [pluginName stringByAppendingPathExtension:@"lunettesstyle"];
    NSString *pluginPath = [[[NSBundle mainBundle] builtInPlugInsPath] stringByAppendingPathComponent:pluginFilename];
    NSAssert(pluginPath, @"Can't find the plugin path, this is bad");
    NSBundle *plugin = [NSBundle bundleWithPath:pluginPath];
    if (!plugin)
        return nil;
    NSString *path = [plugin pathForResource:[self pageName] ofType:@"html"];
    if (!path)
        return nil;
    return [NSURL fileURLWithPath:path];
}

- (NSURL *)url
{
    NSLog(@"loading %@", [self urlForPluginName:@"Default"]);
    return [self urlForPluginName:@"Default"];
}

- (void)setup
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[self url]];
    [[self mainFrame] loadRequest:request];
}

- (void)awakeFromNib
{
    [self setup];
}


@end
