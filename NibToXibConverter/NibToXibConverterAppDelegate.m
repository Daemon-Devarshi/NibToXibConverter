//
//  NibToXibConverterAppDelegate.m
//  NibToXibConverter
//
//  Created by Devarshi on 12/10/12.
//  Copyright 2012 DaemonConstruction. All rights reserved.
//
// 7/02/2014 - Added support for XCode 5, Mavericks & Compiled Nibs (Ben Baker)
//
// Steps:
//  1. Frame array for commands
//  2. Execute each command

#import "NibToXibConverterAppDelegate.h"
#import "FileOperation.h"

@interface NibToXibConverterAppDelegate (Private)
- (void)frameIbtoolCommandForInputFilePath:(NSURL *)inputFileUrl;
- (void)executeIBToolCommands;
@end

@implementation NibToXibConverterAppDelegate

@synthesize window = m_window;
@synthesize decompileNibsCheckBox = m_decompileNibsCheckBox;
@synthesize inputFolderUrl = m_inputFolderUrl;
@synthesize outputFolderUrl = m_outputFolderUrl;
@synthesize status = m_status;
@synthesize converting = m_converting;
@synthesize toolCommandArray = m_toolCommandArray;
@synthesize processedFilesCount = m_processedFilesCount;
@synthesize totalFilesCount = m_totalFilesCount;
@synthesize leftFilesCount = m_leftFilesCount;

- (void)awakeFromNib
{
	self.converting = NO;
	self.status = @"NIB to XIB Converter";
	self.toolCommandArray = [[NSMutableArray alloc] initWithCapacity:2];
	
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
}

- (void)chooseInputDirectory
{
	self.status = @"Choose Input Directory";
	NSOpenPanel *anOpenPanel = [NSOpenPanel openPanel];
    
	[anOpenPanel setCanChooseDirectories:YES];
  
	[anOpenPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result)
	{
		if (result == NSFileHandlingPanelOKButton)
		{
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
    [anOpenPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result)
	{
		if (result == NSFileHandlingPanelOKButton)
		{
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
		if ([[self.inputFolderUrl pathExtension] isEqualToString:@"nib"])
		{
			// use ibtool because nib is found :-)
			
			[self frameIbtoolCommandForInputFilePath:self.inputFolderUrl];
		}
		else
		{
			// folder contains other folders so navigate
			
			NSFileManager *fileManager =[NSFileManager defaultManager];
			NSArray *keys = [NSArray arrayWithObjects:NSURLIsDirectoryKey,NSURLNameKey,NSURLNameKey,nil];
			
			NSDirectoryEnumerator *directoryEnumerator = [fileManager enumeratorAtURL:self.inputFolderUrl includingPropertiesForKeys:keys options:NSDirectoryEnumerationSkipsHiddenFiles errorHandler:^BOOL(NSURL *url, NSError *error)
			{
				return YES;
			}];
			
			for (NSURL *url in directoryEnumerator)
			{
				NSNumber *isDirectory;
				[url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
				
				if ([isDirectory boolValue])
				{
					NSString *directoryName;
					[url getResourceValue:&directoryName forKey:NSURLNameKey error:NULL];
					
					if ([[directoryName pathExtension] isEqualToString:@"nib"])
					{
						[self frameIbtoolCommandForInputFilePath:url];
						[directoryEnumerator skipDescendants];
					}
					else
					{
						// do nothing
						// just chill :-)
					}

				}
				else
				{
					// file found :-(
					// do nothing :-)
					
					// Added this - Ben
					[self frameIbtoolCommandForInputFilePath:url];
				}
			}
		}
	}
	else
	{
		// file found :-(
		// do nothing :-)
	}

	[self executeToolCommands];
}

- (void)frameIbtoolCommandForInputFilePath:(NSURL *)inputFileUrl
{
	// obtain outputFileUrl
	NSString *inputFileName = [inputFileUrl lastPathComponent]; // file name with nib extension obtained
	NSString *inputFileBaseName = [inputFileName stringByDeletingPathExtension];
	NSString *outputFileName = [inputFileBaseName stringByAppendingPathExtension:@"xib"];
	
	// If inputFolderUrl and outputFolderUrl are the same, we convert the nib file in-place.
	NSURL *outputFileBaseURL = ([self.outputFolderUrl isEqual:self.inputFolderUrl] ? [inputFileUrl URLByDeletingLastPathComponent] : self.outputFolderUrl);
	NSURL *outputFileURL = [outputFileBaseURL URLByAppendingPathComponent:outputFileName];
	
	NSTask *launchCommand = nil;
	NSArray *argumentsArray = nil;
	FileOperation *fileOperation = nil;
	
	NSString *nibFileName = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Compiled Nib Opener.zip"];
	NSURL *tempFileURL = [outputFileBaseURL URLByAppendingPathComponent:@"Compiled Nib Opener"];
	NSURL *keyedObjectsURL = [tempFileURL URLByAppendingPathComponent:@"keyedobjects.nib"];
	
	if([m_decompileNibsCheckBox state] == NSOnState)
	{
		// ===========================================================================
		// *** Convert binary plist to xml plist ***
		//
		// plutil -convert xml1 MyFile.nib
		// ===========================================================================
		launchCommand = [[NSTask alloc] init];
		[launchCommand setLaunchPath:@"/usr/bin/plutil"];
		argumentsArray = [[NSArray alloc] initWithObjects:@"-convert", @"xml1", [inputFileUrl path], nil];
		[launchCommand setArguments:argumentsArray];
		[argumentsArray release];
		[self.toolCommandArray addObject:launchCommand];
		[launchCommand release];
		
		// ===========================================================================
		// *** Replace NSIBUserDefinedRuntimeAttributesConnector with NSIBObjectData ***
		//
		// NOTE: Fixes error "NSIBUserDefinedRuntimeAttributesConnector connections are not supported by Interface Builder 3.0."
		//
		// sed -i '' 's/NSIBUserDefinedRuntimeAttributesConnector/NSIBObjectData/g'
		// ===========================================================================
		launchCommand = [[NSTask alloc] init];
		[launchCommand setLaunchPath:@"/usr/bin/sed"];
		argumentsArray = [[NSArray alloc] initWithObjects:@"-i", @"", @"s/NSIBUserDefinedRuntimeAttributesConnector/NSIBObjectData/g", [inputFileUrl path], nil];
		[launchCommand setArguments:argumentsArray];
		[argumentsArray release];
		[self.toolCommandArray addObject:launchCommand];
		[launchCommand release];
		
		// ===========================================================================
		// *** Convert xml plist to binary plist ***
		//
		// plutil -convert binary1 MyFile.nib
		// ===========================================================================
		launchCommand = [[NSTask alloc] init];
		[launchCommand setLaunchPath:@"/usr/bin/plutil"];
		argumentsArray = [[NSArray alloc] initWithObjects:@"-convert", @"binary1", [inputFileUrl path], nil];
		[launchCommand setArguments:argumentsArray];
		[argumentsArray release];
		[self.toolCommandArray addObject:launchCommand];
		[launchCommand release];
		
		// ===========================================================================
		// *** Unzip Compiled Nib Opener.zip ***
		//
		// unzip -o Compiled Nib Opener -d Output Path
		// ===========================================================================
		launchCommand = [[NSTask alloc] init];
		[launchCommand setLaunchPath:@"/usr/bin/unzip"];
		argumentsArray = [[NSArray alloc] initWithObjects:@"-o", nibFileName, @"-d", [outputFileBaseURL path], nil];
		[launchCommand setArguments:argumentsArray];
		[argumentsArray release];
		[self.toolCommandArray addObject:launchCommand];
		[launchCommand release];
		
		// ===========================================================================
		// *** Delete Compiled Nib Opener/keyedobjects.nib ***
		// ===========================================================================
		fileOperation = [[FileOperation alloc] init];
		[fileOperation setFileOperationAtPath:[keyedObjectsURL path] fileOperationType:kDelete];
		[self.toolCommandArray addObject:fileOperation];
		[fileOperation release];
		
		// ===========================================================================
		// *** Copy MyFile.nib to Compiled Nib Opener/keyedobjects.nib ***
		// ===========================================================================
		fileOperation = [[FileOperation alloc] init];
		[fileOperation setFileOperationAtPath:[inputFileUrl path] toPath:[keyedObjectsURL path] fileOperationType:kCopy];
		[self.toolCommandArray addObject:fileOperation];
		[fileOperation release];
		
		// ===========================================================================
		// *** Delete MyFile.nib ***
		// ===========================================================================
		fileOperation = [[FileOperation alloc] init];
		[fileOperation setFileOperationAtPath:[inputFileUrl path] fileOperationType:kDelete];
		[self.toolCommandArray addObject:fileOperation];
		[fileOperation release];
		
		// ===========================================================================
		// *** Move Compiled Nib Opener to MyFile.nib ***
		// ===========================================================================
		fileOperation = [[FileOperation alloc] init];
		[fileOperation setFileOperationAtPath:[tempFileURL path] toPath:[inputFileUrl path] fileOperationType:kMove];
		[self.toolCommandArray addObject:fileOperation];
		[fileOperation release];
	}
	
	// ===========================================================================
	// *** NIB to XIB ***
	//
	// ibtool MyFile.nib --upgrade --write new MyFile.xib
	// ===========================================================================
	launchCommand = [[NSTask alloc] init];
	[launchCommand setLaunchPath:@"/Applications/Xcode.app/Contents/Developer/usr/bin/ibtool"];
	argumentsArray = [[NSArray alloc] initWithObjects:[inputFileUrl path], @"--upgrade", @"--write", [outputFileURL path], nil];
	[launchCommand setArguments:argumentsArray];
	[argumentsArray release];
	[self.toolCommandArray addObject:launchCommand];
	[launchCommand release];
	// ===========================================================================
	
	//[toolCommand launch];
	//[toolCommand waitUntilExit];
}

- (void)executeToolCommands
{
	self.status = @"Converting ...";
	self.totalFilesCount = [self.toolCommandArray count];
	self.leftFilesCount = self.totalFilesCount;
	self.processedFilesCount = 0;
	
	dispatch_queue_t aGlobalConcurrentQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_async(aGlobalConcurrentQueue, ^{
		self.converting = YES;
		//dispatch_apply([self.toolCommandArray count], aGlobalConcurrentQueue, ^(size_t i)
		
		// This needs to be sequential for file operations - Ben
		for(int i = 0; i < [self.toolCommandArray count]; i++)
					   {
						   ++self.processedFilesCount;
						   --self.leftFilesCount;
						   
						   id obj = [self.toolCommandArray objectAtIndex:i];
						   
						   if ([obj isKindOfClass:[NSTask class]])
						   {
							   NSTask *receivedTask = obj;
							   NSString *statusString = [[NSString alloc] initWithFormat:@"%@", [[[receivedTask arguments] lastObject] lastPathComponent]];
							   
							   self.status = statusString;
							   
							   //NSLog(@"====> %@ %@", [receivedTask launchPath], [receivedTask arguments]);
							   
							   [statusString release];
							   
							   [receivedTask launch];
							   [receivedTask waitUntilExit];
						   }
						   else if ([obj isKindOfClass:[FileOperation class]])
						   {
							   FileOperation *fileOperation = obj;
							   self.status = [fileOperation operationString];
							   
							   //NSLog(@"====> %@", self.status);
							   
							   [fileOperation launch];
						   }
					   }//);
		
		self.leftFilesCount = 0;
		self.converting = NO;
		self.status = @"NIB to XIB Converter";
		
		[self.toolCommandArray removeAllObjects];
	});
}

- (void)clearAll
{
	self.status = @"NIB to XIB Converter";
	self.leftFilesCount = 0;
	self.processedFilesCount = 0;
	self.inputFolderUrl = nil;
	self.outputFolderUrl = nil;
	[self.toolCommandArray removeAllObjects];
	self.totalFilesCount = 0;
}

@end
