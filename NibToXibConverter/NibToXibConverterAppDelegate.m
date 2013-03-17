//
//  NibToXibConverterAppDelegate.m
//  NibToXibConverter
//
//  Created by Devarshi on 12/10/12.
//  Copyright 2012 DaemonConstruction. All rights reserved.
//Steps:
// 1. Frame array for iBtool commands
// 2. Execute each command

#import "NibToXibConverterAppDelegate.h"

@interface NibToXibConverterAppDelegate (Private)
- (void)frameIbtoolCommandForInputFilePath:(NSURL *)inputFileUrl;
- (void)executeIBToolCommands;
@end

@implementation NibToXibConverterAppDelegate

@synthesize window, inputFolderUrl, outputFolderUrl, status, converting, ibtoolCommandsArray, processedFilesCount, totalFilesCount, leftFilesCount;

- (void)awakeFromNib
{
	self.converting = NO;
	self.status = @"NIB to XIB Converter";
	self.ibtoolCommandsArray = [[NSMutableArray alloc] initWithCapacity:2];
	
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application 
	
}

- (void)chooseInputDirectory
{
	self.status = @"Choose Input Directory";
	NSOpenPanel *anOpenPanel = [NSOpenPanel openPanel];
    [anOpenPanel setCanChooseDirectories:YES];
    [anOpenPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
		if (result == NSFileHandlingPanelOKButton) {
			self.inputFolderUrl = [[anOpenPanel URLs] objectAtIndex:0];
			
		}
        self.status = @"NIB to XIB Converter";
	}];
	
	
}

- (void)chooseOutputDirectory
{
	self.status = @"Choose Output Directory";
	NSOpenPanel *anOpenPanel = [NSOpenPanel openPanel];
    [anOpenPanel setCanChooseDirectories:YES];
    [anOpenPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
		if (result == NSFileHandlingPanelOKButton) {
			self.outputFolderUrl = [[anOpenPanel URLs] objectAtIndex:0];
		}
		
		self.status = @"NIB to XIB Converter";
	}];
	
	
}

- (void)convertToXIBFromNib
{
	
	BOOL isDirectory;
	if ([[NSFileManager defaultManager] fileExistsAtPath:[self.inputFolderUrl path] isDirectory:&isDirectory] && isDirectory)
	{
		if ([[self.inputFolderUrl pathExtension] isEqualToString:@"nib"]) {
			// use ibtool because nib is found :-)
			
			[self frameIbtoolCommandForInputFilePath:self.inputFolderUrl];
		}
		else {
			// folder contains other folders so navigate
			
			NSFileManager *fileManager =[NSFileManager defaultManager];
			NSArray *keys = [NSArray arrayWithObjects:NSURLIsDirectoryKey,NSURLNameKey,NSURLNameKey,nil];
			
			NSDirectoryEnumerator *directoryEnumerator = [fileManager enumeratorAtURL:self.inputFolderUrl includingPropertiesForKeys:keys options:NSDirectoryEnumerationSkipsHiddenFiles errorHandler:^BOOL(NSURL *url, NSError *error) {
				return YES;
			}];
			
			for (NSURL *url in directoryEnumerator)
			{
				NSNumber *isDirectory;
				[url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
				
				if ([isDirectory boolValue]) {
					
					NSString *directoryName;
					[url getResourceValue:&directoryName forKey:NSURLNameKey error:NULL];
					
					if ([[directoryName pathExtension] isEqualToString:@"nib"]) {
						[self frameIbtoolCommandForInputFilePath:url];
						[directoryEnumerator skipDescendants];
					}
					else {
						// do nothing
						// just chill :-)
					}

				}
				else {
					// file found :-(
					// do nothing :-)
				}

			}
			
		}

	}
	else {
		// file found :-(
		// do nothing :-)
	}

	
	[self executeIBToolCommands];
	
	
}

- (void)frameIbtoolCommandForInputFilePath:(NSURL *)inputFileUrl
{
	// obtain outputFileUrl
	NSString *inputFileName = [inputFileUrl lastPathComponent]; // file name with nib extension obtained
	NSString *inputFileBaseName = [inputFileName stringByDeletingPathExtension];
	
	NSString *outputFileName = [inputFileBaseName stringByAppendingPathExtension:@"xib"];
	
	// If inputFolderUrl and outputFolderUrl are the same, we convert the nib file in-place.
	NSURL *outputFileBaseURL;
	if ([self.outputFolderUrl isEqual:self.inputFolderUrl]) {
		outputFileBaseURL = [inputFileUrl URLByDeletingLastPathComponent];
	}
	else {
		outputFileBaseURL = self.outputFolderUrl;
	}
	
	NSURL *outputFileURL = [outputFileBaseURL URLByAppendingPathComponent:outputFileName];
	
	NSTask *theIBToolCommand = [[NSTask alloc] init];
	[theIBToolCommand setLaunchPath:@"/Developer/usr/bin/ibtool"];
	
	NSArray *argumentsArray = [[NSArray alloc] initWithObjects:[inputFileUrl path],@"--upgrade",@"--write",[outputFileURL path],nil];
	[theIBToolCommand setArguments:argumentsArray];
	[argumentsArray release];
	
	[self.ibtoolCommandsArray addObject:theIBToolCommand];
	[theIBToolCommand release];
	//[theIBToolCommand launch];
//	[theIBToolCommand waitUntilExit];
}

- (void)executeIBToolCommands
{
	self.status = @"Converting ...";
	self.totalFilesCount = [self.ibtoolCommandsArray count];
	self.leftFilesCount = self.totalFilesCount;
	self.processedFilesCount = 0;
	
	dispatch_queue_t aGlobalConcurrentQueue = dispatch_get_global_queue(0, 0);
	dispatch_async(aGlobalConcurrentQueue, ^{
		self.converting = YES;
		dispatch_apply([self.ibtoolCommandsArray count], aGlobalConcurrentQueue, ^(size_t index) {
					   ++ self.processedFilesCount;
					   -- self.leftFilesCount;
					   NSTask *receivedTask  = [self.ibtoolCommandsArray objectAtIndex:index];
					   NSString *statusString = [[NSString alloc] initWithFormat:@"%@",[[[receivedTask arguments] lastObject] lastPathComponent]];
					   self.status = statusString;
					   [statusString release];
					   [receivedTask launch];
					   [receivedTask waitUntilExit];
	});
		
		self.leftFilesCount = 0;
		self.converting = NO;
		self.status = @"NIB to XIB Converter";
		[self.ibtoolCommandsArray removeAllObjects];
		
	});
	
	
	
}
- (void)clearAll
{
	self.status = @"NIB to XIB Converter";//
	self.leftFilesCount = 0; //
	self.processedFilesCount = 0; //
	self.inputFolderUrl = nil;
	self.outputFolderUrl = nil;
	[self.ibtoolCommandsArray removeAllObjects];//
	self.totalFilesCount = 0;//
}


@end
