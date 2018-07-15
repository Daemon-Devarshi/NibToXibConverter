//
//  FileOperation.m
//  NibToXibConverter
//
//  Created by Ben Baker on 7/02/2014.
//
//

#import "FileOperation.h"

@implementation FileOperation

@synthesize fileManager = m_fileManager;
@synthesize atPath = m_atPath;
@synthesize toPath = m_toPath;
@synthesize fileOperationType = m_fileOperationType;

-(id) init
{
    self = [super init];
	
    if (self)
	{
		m_fileManager = [[NSFileManager alloc] init];
		m_fileManager.delegate = self;
    }
	
    return self;
}

-(void) dealloc
{
	[m_fileManager release];
    [super dealloc];
}

-(void) setFileOperationAtPath:(NSString *)atPath toPath:(NSString *)toPath fileOperationType:(FileOperationType)fileOperationType
{
	m_atPath = [atPath retain];
	m_toPath = [toPath retain];
	m_fileOperationType = fileOperationType;
}

-(void) setFileOperationAtPath:(NSString *)atPath fileOperationType:(FileOperationType)fileOperationType
{
	m_atPath = [atPath retain];
	m_fileOperationType = fileOperationType;
}

-(void) launch
{
	NSError *error;

	switch (m_fileOperationType)
	{
		case kDelete:
			[m_fileManager removeItemAtPath:m_atPath error:&error];
			break;
		case kCopy:
			[m_fileManager copyItemAtPath:m_atPath toPath:m_toPath error:&error];
			break;
		case kMove:
			[m_fileManager moveItemAtPath:m_atPath toPath:m_toPath error:&error];
			break;
	}
}

- (NSString *)operationString
{
	NSString *retString;
	
	switch (m_fileOperationType)
	{
		case kDelete:
			retString = [NSString stringWithFormat:@"Deleting %@", m_atPath];
			break;
		case kCopy:
			retString = [NSString stringWithFormat:@"Copying %@ to %@", m_atPath, m_toPath];
			break;
		case kMove:
			retString = [NSString stringWithFormat:@"Moving %@ to %@", m_atPath, m_toPath];
			break;
	}
	
	return retString;
}

@end
