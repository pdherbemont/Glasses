//
//  VLCWebBindingsController.h
//  Lunettes
//
//  Created by Pierre d'Herbemont on 10/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <WebKit/WebKit.h>


@interface VLCWebBindingsController : NSObject {
    NSMutableArray *_bindings;
    NSMutableArray *_observers;
}

+ (WebScriptObject *)backendObject:(id)object withWebScriptObject:(WebScriptObject *)webScriptObject;

- (void)bindDOMObject:(DOMObject *)domObject property:(NSString *)property toObject:(id)object withKeyPath:(NSString *)keyPath options:(NSDictionary *)dict;
- (void)unbindDOMObject:(DOMObject *)domObject property:(NSString *)property;

- (void)observe:(id)object withKeyPath:(NSString *)keyPath observer:(WebScriptObject *)observer;
- (void)unobserve:(id)object withKeyPath:(NSString *)keyPath observer:(WebScriptObject *)observer;

- (void)clearBindingsAndObservers;
@end
