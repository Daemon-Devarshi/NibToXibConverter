//
//  NibToXibConverterAppDelegate.h
//  NibToXibConverter
//
//  Created by Devarshi on 12/10/12.
//  Copyright 2012 DaemonConstruction. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NibToXibConverterAppDelegate : NSObject <NSApplicationDelegate>
{
    NSWindow *m_window;
	NSButton *m_decompileNibsCheckBox;
	NSURL *m_inputFolderUrl;
	NSURL *m_outputFolderUrl;
	BOOL m_converting;
	NSString *m_status;
	NSMutableArray *m_toolCommandArray;
	NSInteger m_processedFilesCount;
	NSInteger m_totalFilesCount;
	NSInteger m_leftFilesCount;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSButton *decompileNibsCheckBox;

@property (readwrite, retain) NSMutableArray *toolCommandArray;
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
