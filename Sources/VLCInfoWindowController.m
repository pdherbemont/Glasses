//
//  VLCInfoWindowController.m
//  Lunettes
//
//  Created by Pierre d'Herbemont on 1/31/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "VLCInfoWindowController.h"
#import "VLCDocumentController.h"
#import "VLCMediaLibrary.h"

@implementation VLCInfoWindowController
- (NSString *)windowNibName
{
    return @"InfoWindow";
}

- (VLCDocumentController *)documentController
{
    return [VLCDocumentController sharedDocumentController];
}

- (IBAction)tvShowNameChanged:(id)sender
{
    NSArray *array = [[[VLCDocumentController sharedDocumentController] currentArrayController] selectedObjects];

    VLCAssert([sender isKindOfClass:[NSComboBox class]], @"Should be a combobox");
    NSComboBox *combo = sender;
    NSString *tvShowName = [combo stringValue];

    NSManagedObjectContext *moc = [[VLCLMediaLibrary sharedMediaLibrary] managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Show" inManagedObjectContext:moc];

    [request setEntity:entity];
    [request setFetchLimit:1];

    [request setPredicate:[NSPredicate predicateWithFormat:@"name == %@", tvShowName]];

    NSArray *result = [moc executeFetchRequest:request error:nil];
    [request release];

    id tvshow;
    if ([result count] == 0) {
        tvshow = [NSEntityDescription insertNewObjectForEntityForName:@"Show" inManagedObjectContext:moc];
        [tvshow setValue:tvShowName forKey:@"name"];
    } else
        tvshow = [result objectAtIndex:0];

    for (NSManagedObject *object in array)
        [object setValue:tvshow forKey:@"show"];
}

- (void)windowWillClose:(NSNotification *)notification
{
    [[VLCDocumentController sharedDocumentController] closeInfoWindow];
}
@end
