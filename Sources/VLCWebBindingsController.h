//
//  VLCWebBindingsController.h
//  Lunettes
//
//  Created by Pierre d'Herbemont on 10/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <WebKit/WebKit.h>


@interface VLCWebBindingsController : NSObject {
    NSMutableSet *_bindings;
    NSMutableSet *_observers;
}

- (void)bindDOMObject:(DOMObject *)domObject property:(NSString *)property toObject:(id)object withKeyPath:(NSString *)keyPath;
- (void)unbindDOMObject:(DOMObject *)domObject property:(NSString *)property;
- (void)clearBindings;

- (void)observe:(id)object withKeyPath:(NSString *)keyPath observer:(WebScriptObject *)observer;
- (void)unobserve:(id)object withKeyPath:(NSString *)keyPath observer:(WebScriptObject *)observer;

@end
