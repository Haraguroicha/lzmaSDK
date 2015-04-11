#import <lzmaSDK/LZMAExtractor.h>

@interface LZMAExtractor (Private)
+ (BOOL)doExtract7zArchive:(NSString *)archivePath
              archiveEntry:(NSString *)archiveEntry
                   outPath:(NSString *)outPath
               preserveDir:(BOOL)preserveDir;
@end
