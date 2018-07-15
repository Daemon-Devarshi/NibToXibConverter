//
//  FileOperation.h
//  NibToXibConverter
//
//  Created by Ben Baker on 7/02/2014.
//
//

#import <Foundation/Foundation.h>

typedef enum
{
    kDelete,
    kCopy,
    kMove
} FileOperationType;

@interface FileOperation : NSObject <NSFileManagerDelegate>
{
    NSFileManager *m_fileManager;
	NSString *m_atPath;
	NSString *m_toPath;
	FileOperationType m_fileOperationType;
}

@property (readonly) NSFileManager *fileManager;
@property (readwrite, retain) NSString *atPath;
@property (readwrite, retain) NSString *toPath;
@property (assign) FileOperationType fileOperationType;

-(void) setFileOperationAtPath:(NSString *)atPath toPath:(NSString *)toPath fileOperationType:(FileOperationType)fileOperationType;
-(void) setFileOperationAtPath:(NSString *)atPath fileOperationType:(FileOperationType)fileOperationType;
-(void) launch;
- (NSString *)operationString;

@end
