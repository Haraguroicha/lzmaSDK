//
//  LZMAExtractor.m
//  flipbooks
//
//  Created by Mo DeJong on 11/19/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "LZMAExtractor.h"

int do7z_extract_entry(char *archivePath, char *archiveCachePath, char *entryName, char *entryPath, int fullPaths);

@implementation LZMAExtractor

// Recurse into directories to determine the full paths of elements extracted
// from a archive.

+ (void) recurseIntoDirectories:(NSMutableArray*)fullPathContents
                        dirName:(NSString*)dirName
                    entryPrefix:(NSString*)entryPrefix
{
    NSFileManager *manager = [NSFileManager defaultManager];
    NSArray *contents = [manager contentsOfDirectoryAtPath:dirName
                                                     error:nil];
    NSAssert(contents, @"contentsOfDirectoryAtPath failed");
    
    for (NSString *path in contents) {
        //NSLog(@"found dir path: %@", path);
        NSString *fullPath = [dirName stringByAppendingPathComponent:path];
        //NSLog(@"found full path: %@", fullPath);
        
        BOOL isDirectory = FALSE;
        BOOL exists = [manager fileExistsAtPath:fullPath
                                    isDirectory:&isDirectory];
        assert(exists);
        
        NSString *combinedEntryPrefix;
        if ([entryPrefix length] == 0) {
            combinedEntryPrefix = path;
        } else {
            combinedEntryPrefix = [NSString stringWithFormat:@"%@/%@", entryPrefix, path];
        }
        
        //NSLog(@"found entry path: %@", combinedEntryPrefix);
        
        if (isDirectory) {
            // Recurse into this directory and add the files in the directory
            
            [self recurseIntoDirectories:fullPathContents
                                 dirName:fullPath
                             entryPrefix:combinedEntryPrefix];
        } else {
            // A plain file path, append the entry name portion of the path.
            
            [fullPathContents addObject:fullPath];
        }
    }
    
    return;
}

+ (void)prepareDirectory:(NSString *)directory
{
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL worked, isDir, existsAlready;
    existsAlready = [manager fileExistsAtPath:directory
                                  isDirectory:&isDir];
    
    if (existsAlready && !isDir) {
        worked = [manager removeItemAtPath:directory
                                     error:nil];
        NSAssert(worked, @"could not remove existing file with same name as tmp dir");
        // create the directory below
    }
    
    if (existsAlready && isDir) {
        // Remove all the files in the named tmp dir
        NSArray *contents = [manager contentsOfDirectoryAtPath:directory
                                                         error:nil];
        NSAssert(contents, @"contentsOfDirectoryAtPath failed");
        for (NSString *path in contents) {
            NSString *myTmpDirPath = [directory stringByAppendingPathComponent:path];
            worked = [manager removeItemAtPath:myTmpDirPath
                                         error:nil];
            NSAssert(worked, @"could not remove existing file");
        }
    } else {
        worked = [manager createDirectoryAtPath:directory
                    withIntermediateDirectories:YES
                                     attributes:nil
                                          error:nil];
        NSAssert(worked, @"could not create tmp dir");
    }
    
    worked = [manager changeCurrentDirectoryPath:directory];
    NSAssert(worked, @"cd to tmp 7z dir failed");
}

// Extract all the contents of a .7z archive directly into the indicated dir

+ (NSArray*) extract7zArchive:(NSString*)archivePath
                      dirName:(NSString*)dirName
                  preserveDir:(BOOL)preserveDir
{
    NSAssert(archivePath, @"archivePath");
    NSAssert(dirName, @"dirName");
    
    [self prepareDirectory:dirName];
    BOOL result;
    result = [self doExtract7zArchive:archivePath
                         archiveEntry:nil
                              outPath:nil
                          preserveDir:preserveDir];
    NSAssert(result, @"could not extract files from 7z archive");
    
    // Examine the contents of the current directory to see what was extracted
    
    NSMutableArray *fullPathContents = [NSMutableArray array];
    
    [self recurseIntoDirectories:fullPathContents
                         dirName:dirName
                     entryPrefix:@""];
    
    return [NSArray arrayWithArray:fullPathContents];
}

// Extract all the contents of a .7z archive into the indicated temp dir
// and return an array of the fully qualified filenames.

+ (NSArray*) extract7zArchive:(NSString*)archivePath
                   tmpDirName:(NSString*)tmpDirName
{
    NSAssert(archivePath, @"archivePath");
    NSAssert(tmpDirName, @"tmpDirName");
    NSString *tmpDir = NSTemporaryDirectory();
    NSString *fullTmpDir = [tmpDir stringByAppendingPathComponent:tmpDirName];
    return [self extract7zArchive:archivePath
                          dirName:fullTmpDir
                      preserveDir:FALSE];
}

// Extract just one entry from an archive and save it at the
// path indicated by outPath.

+ (BOOL) extractArchiveEntry:(NSString*)archivePath
                archiveEntry:(NSString*)archiveEntry
                     outPath:(NSString*)outPath
{
    NSAssert(archiveEntry, @"archiveEntry");
    NSAssert(outPath, @"outPath");
    return [self doExtract7zArchive:archivePath
                       archiveEntry:archiveEntry
                            outPath:outPath
                        preserveDir:NO];
}

+ (BOOL)doExtract7zArchive:(NSString *)archivePath
              archiveEntry:(NSString *)archiveEntry
                   outPath:(NSString *)outPath
               preserveDir:(BOOL)preserveDir
{
    NSAssert(archivePath, @"archivePath");
    char *archivePathCStr = (char*) [archivePath UTF8String];
    char *entryNameCStr = archiveEntry ? (char*) [archiveEntry UTF8String] : NULL;
    char *entryPathCStr = outPath ? (char*) [outPath UTF8String] : NULL;
    int result = do7z_extract_entry(archivePathCStr, [self archiveCacheDir], entryNameCStr, entryPathCStr, preserveDir ? 1 : 0);
    return result == 0;
}

+(char *)archiveCacheDir
{
    NSString *randomSuffix = [[[NSProcessInfo processInfo] globallyUniqueString] lowercaseString];
    randomSuffix = [randomSuffix stringByReplacingOccurrencesOfString:@"-" withString:@""];
    randomSuffix = [randomSuffix stringByTrimmingCharactersInSet:[NSCharacterSet decimalDigitCharacterSet]];
    NSString *tmpDir = [NSTemporaryDirectory() stringByAppendingPathComponent:@"lzmaSDK.archiveCache"];
    tmpDir = [tmpDir stringByAppendingPathExtension:[randomSuffix substringToIndex:10]];
    char *template = (char*) [tmpDir UTF8String];
    return mktemp(template);
}

@end
