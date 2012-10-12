//
//  NibToXibConverterAppDelegate.h
//  NibToXibConverter
//
//  Created by Devarshi on 12/10/12.
//  Copyright 2012 DaemonConstruction. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NibToXibConverterAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
	NSURL *inputFolderUrl;
	NSURL *outputFolderUrl;
	BOOL converting;
	NSString *status;
	NSMutableArray *ibtoolCommandsArray;
	NSInteger processedFilesCount;
	NSInteger totalFilesCount;
	NSInteger leftFilesCount;
}

@property (assign) IBOutlet NSWindow *window;
@property (readwrite, retain) NSMutableArray *ibtoolCommandsArray;
@property (readwrite, retain) NSString *status;
@property (readwrite, retain) NSURL *inputFolderUrl;
@property (readwrite, retain) NSURL *outputFolderUrl;
@property (assign) BOOL converting;
@property (assign) NSInteger processedFilesCount;
@property (assign) NSInteger totalFilesCount;
@property (assign) NSInteger leftFilesCount;

- (void)convertToXIBFromNib;
- (void)chooseInputDirectory;
- (void)chooseOutputDirectory;
- (void)clearAll;
@end
