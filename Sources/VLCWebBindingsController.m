//
//  VLCWebBindingsController.m
//  Lunettes
//
//  Created by Pierre d'Herbemont on 10/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "VLCWebBindingsController.h"

@interface VLCWebBindingsController (DOMEventListener) <DOMEventListener>
@end

@implementation VLCWebBindingsController
- (id)init
{
    self = [super init];
    if (!self)
        return nil;
    _bindings = [[NSMutableSet alloc] init];
    _observers = [[NSMutableSet alloc] init];
    return self;
}

- (void)dealloc
{
    NSAssert([_bindings anyObject] == nil, @"Bindings should be empty");
    [_bindings release];
    NSAssert([_observers anyObject] == nil, @"Observers should be empty");
    [_observers release];
    [super dealloc];
}

#pragma mark -
#pragma mark Observers private getters

- (NSSet *)observersDictsForObject:(id)object andKeypath:(NSString *)keyPath
{
    NSMutableSet *set = [NSMutableSet set];
    for (NSDictionary *dict in _observers) {
        if ([[dict objectForKey:@"object"] isEqual:object] &&
            [[dict objectForKey:@"keyPath"] isEqualToString:keyPath])
            [set addObject:dict];
    }
    return set;
}

- (NSDictionary *)observerDictForObserver:(WebScriptObject *)observer withObject:(id)object andKeypath:(NSString *)keyPath
{
    for (NSDictionary *dict in _observers) {
        if ([[dict objectForKey:@"object"] isEqual:object] &&
            [[dict objectForKey:@"observer"] isEqual:observer] &&
            [[dict objectForKey:@"keyPath"] isEqualToString:keyPath] )
            return [[dict retain] autorelease];
    }
    return nil;
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSDictionary *dict = context;
    if (dict) {
        WebScriptObject *observer = [dict objectForKey:@"observer"];
        
        NSInteger kind = [[change objectForKey:NSKeyValueChangeKindKey] intValue];
        id new = [change objectForKey:NSKeyValueChangeNewKey];

        // Get all modified indexes.
        NSMutableArray *setAsArray = nil;
        NSIndexSet *set = [change objectForKey:NSKeyValueChangeIndexesKey];
        if (set) {
            NSUInteger bufSize = [set count];
            setAsArray = [NSMutableArray arrayWithCapacity:bufSize];
            NSUInteger buf[bufSize];
            NSRange range = NSMakeRange([set firstIndex], [set lastIndex]);
            [set getIndexes:buf maxCount:bufSize inIndexRange:&range];
            for(NSUInteger i = 0; i < bufSize; i++) {
                NSUInteger index = buf[i];
                [setAsArray addObject:[NSNumber numberWithInt:index]];
            }            
        }

        switch (kind) {
            case NSKeyValueChangeSetting:
                [observer callWebScriptMethod:@"removeAllInsertedCocoaObjects" withArguments:[NSArray array]];
                
                // I sometimes get NSNull value during setting but [object valueForKeyPath:keyPath]
                // returns a better results, so use it. This happen with NSArrayController arrangedObjects.
                new = [object valueForKeyPath:keyPath];

                if ([new isKindOfClass:[NSNull class]])
                    break;

                NSAssert([new isKindOfClass:[NSArray class]], @"Only support array");
                for (NSUInteger i = 0; i < [new count]; i++) {
                    id object = [new objectAtIndex:i];
                    WebScriptObject *child = [observer callWebScriptMethod:@"createCocoaObject" withArguments:[NSArray arrayWithObject:observer]];
                    NSAssert(child, @"createCocoaObject() should return something"); 
                    [child setValue:object forKey:@"backendObject"];
                    [observer callWebScriptMethod:@"insertCocoaObject" withArguments:[NSArray arrayWithObjects:child, [setAsArray objectAtIndex:i], nil]];
                }                
                break;
            case NSKeyValueChangeInsertion:
                for (NSUInteger i = 0; i < [new count]; i++) {
                    id object = [new objectAtIndex:i];
                    WebScriptObject *child = [observer callWebScriptMethod:@"createCocoaObject" withArguments:[NSArray arrayWithObject:observer]];
                    NSAssert(child, @"createCocoaObject() should return something"); 
                    [child setValue:object forKey:@"backendObject"];
                    [observer callWebScriptMethod:@"insertCocoaObject" withArguments:[NSArray arrayWithObjects:child, [setAsArray objectAtIndex:i], nil]];
                }                
                break;
            case NSKeyValueChangeRemoval:
                for (NSUInteger i = 0; i < [setAsArray count]; i++)
                    [observer callWebScriptMethod:@"removeCocoaObjectAtIndex" withArguments:[NSArray arrayWithObject:[setAsArray objectAtIndex:i]]];
                break;
            case NSKeyValueChangeReplacement:
            default:
                NSAssert(0, @"Should not be reached");
                break;
        }
        return;
        
    }
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)_removeObserverWithDict:(NSDictionary *)dict
{
    id object = [dict objectForKey:@"object"];
    NSString *keyPath = [dict objectForKey:@"keyPath"];
        
    [object removeObserver:self forKeyPath:keyPath];
    [_observers removeObject:dict];
}

#pragma mark -
#pragma mark Public observer functions

- (void)observe:(id)object withKeyPath:(NSString *)keyPath observer:(WebScriptObject *)observer
{
    NSDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                          object, @"object",
                          observer, @"observer",
                          keyPath, @"keyPath", nil];
    [_observers addObject:dict];
    [object addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:dict];
}

- (void)unobserve:(id)object withKeyPath:(NSString *)keyPath observer:(WebScriptObject *)observer
{
    NSDictionary *dict = [self observerDictForObserver:observer withObject:object andKeypath:keyPath];
    NSAssert(dict, @"No registered observer");
    [self _removeObserverWithDict:dict];
}

#pragma mark -
#pragma mark Bindings private getters

- (NSDictionary *)bindingForDOMObject:(DOMObject *)domObject property:(NSString *)property
{
    for (NSDictionary *dict in _bindings) {
        if ([[dict objectForKey:@"domObject"] isEqual:domObject] &&
            [[dict objectForKey:@"property"] isEqualToString:property])
            return [[dict retain] autorelease];
    }
    return nil;
}

- (NSSet *)bindingsForDOMObject:(DOMObject *)domObject
{
    NSMutableSet *set = [NSMutableSet set];
    for (NSDictionary *dict in _bindings) {
        if ([[dict objectForKey:@"domObject"] isEqual:domObject])
            [set addObject:dict];
    }
    return set;
}

- (void)_removeBindingWithDict:(NSDictionary *)dict
{
    DOMObject *domObject = [dict objectForKey:@"domObject"];
    if ([domObject isKindOfClass:[DOMNode class]]) {
        DOMNode *node = (DOMNode *)domObject;
        [node removeEventListener:@"input" listener:self useCapture:NO];
        [node removeEventListener:@"DOMNodeRemoved" listener:self useCapture:NO];
    }
    
    NSString *property = [dict objectForKey:@"property"];
    [domObject unbind:property];
    
    [_bindings removeObject:dict];    
}

- (void)handleEvent:(DOMEvent *)evt
{
    DOMNode *node = [evt target];
    NSSet *set = [self bindingsForDOMObject:node] ;
    NSAssert([set count] > 0, @"Got an event from a removed node");
    
    if ([[evt type] isEqualToString:@"input"]) {
        for (NSDictionary *dict in set) {
            id object = [dict objectForKey:@"object"];
            NSString *keyPath = [dict objectForKey:@"keyPath"];
            NSString *property = [dict objectForKey:@"property"];
            [object setValue:[node valueForKey:property] forKeyPath:keyPath];
        }
        return;
    }
    
    // [evt type] == "DOMNodeRemoved"
    for (NSDictionary *dict in set)
        [self _removeBindingWithDict:dict];
}


#pragma mark -
#pragma mark Public bindings functions

- (void)bindDOMObject:(DOMObject *)domObject property:(NSString *)property toObject:(id)object withKeyPath:(NSString *)keyPath options:(NSDictionary *)options
{
    NSAssert(![self bindingForDOMObject:domObject property:property], ([NSString stringWithFormat:@"Binding of %@.%@ already exists", domObject, property]));

    NSDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:domObject, @"domObject", property, @"property", keyPath, @"keyPath", object, @"object", nil];
    [_bindings addObject:dict];
    if ([domObject isKindOfClass:[DOMNode class]]) {
        DOMNode *node = (DOMNode *)domObject;
        [node addEventListener:@"DOMNodeRemoved" listener:self useCapture:NO];
        [node addEventListener:@"input" listener:self useCapture:NO];
    }
    [domObject bind:property toObject:object withKeyPath:keyPath options:nil];
}

- (void)unbindDOMObject:(DOMObject *)domObject property:(NSString *)property
{
    NSDictionary * dict = [self bindingForDOMObject:domObject property:property];
    NSAssert(dict, ([NSString stringWithFormat:@"No binding for %@.%@", domObject, property]));
    [self _removeBindingWithDict:dict];
}

- (void)clearBindingsAndObservers
{
    NSDictionary *dict;
    while ((dict = [_bindings anyObject]))
        [self _removeBindingWithDict:dict];
    while ((dict = [_observers anyObject]))
        [self _removeObserverWithDict:dict];
}

@end
