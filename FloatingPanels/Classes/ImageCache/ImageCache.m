//
//  ImageCache.m
//  ImageCacheTest
//
//  Created by Adrian on 1/28/09.
//  Copyright 2009 Adrian Kosmaczewski. All rights reserved.
//

#import "ImageCache.h"
#import "GTMObjectSingleton.h"

@interface ImageCache (Private)

- (void)addImageToMemoryCache:(UIImage *)image withKey:(NSString *)key;
- (BOOL)addImageToDiskCache:(UIImage *)image withKey:(NSString *)key;
- (NSString *)getCacheDirectoryName;
- (NSString *)getFileNameForKey:(NSString *)key;

@end


@implementation ImageCache

#pragma mark -
#pragma mark Singleton definition

GTMOBJECT_SINGLETON_BOILERPLATE(ImageCache, sharedImageCache)

#pragma mark -
#pragma mark Constructor and destructor

- (id)init
{
    self = [super init];
    if (self)
    {
        memoryKeyArray = [[NSMutableArray alloc] initWithCapacity:MEMORY_CACHE_SIZE+1];
        memoryCache = [[NSMutableDictionary alloc] initWithCapacity:MEMORY_CACHE_SIZE+1];
        fileManager = [NSFileManager defaultManager];
        enableDiskCache = ENABLE_DISK_CACHE;
        
        NSString *cacheDirectoryName = [self getCacheDirectoryName];
        BOOL isDirectory = NO;
        BOOL folderExists = [fileManager fileExistsAtPath:cacheDirectoryName isDirectory:&isDirectory] && isDirectory;

        if (!folderExists)
        {
            NSError *error = nil;
            [fileManager createDirectoryAtPath:cacheDirectoryName withIntermediateDirectories:YES attributes:nil error:&error];
            [error release];
        }
        
        if (!enableDiskCache)
            [self removeAllImages];
    }
    return self;
}

- (void)dealloc
{
    [memoryKeyArray removeAllObjects];
    [memoryKeyArray release];
    memoryKeyArray = nil;
    [memoryCache removeAllObjects];
    [memoryCache release];
    memoryCache = nil;
    fileManager = nil;
    [super dealloc];
}

#pragma mark -
#pragma mark Public methods

- (UIImage *)imageForKey:(NSString *)key
{
    if (key == nil || [key length] < 1)
        return nil;
    
    UIImage *image = (UIImage *)[memoryCache objectForKey:key];
    if (image == nil && [self imageExistsInDisk:key])
    {
        NSString *fileName = [self getFileNameForKey:key];
        NSData *data = [NSData dataWithContentsOfFile:fileName];
        image = [[[UIImage alloc] initWithData:data] autorelease];
        [self addImageToMemoryCache:image withKey:key];
    }
    return image;
}

- (BOOL)hasImageWithKey:(NSString *)key
{
    BOOL exists = [self imageExistsInMemory:key];
    
    if (!exists && enableDiskCache)
        exists = [self imageExistsInDisk:key];
    
    return exists;
}

- (void)storeImage:(UIImage *)image withKey:(NSString *)key
{
    if (image != nil && key != nil)
    {
        [self addImageToMemoryCache:image withKey:key];
        
        if (!enableDiskCache)
            return;
        
        //Why is this even here? Causing weird problem on caching
        //NSString *fileName = [self getFileNameForKey:key];
        //    [UIImagePNGRepresentation(image) writeToFile:fileName atomically:YES];
    }
}

- (void)removeImageWithKey:(NSString *)key
{
    if ([self imageExistsInMemory:key])
    {
        NSUInteger index = [memoryKeyArray indexOfObject:key];
        [memoryKeyArray removeObjectAtIndex:index];
        [memoryCache removeObjectForKey:key];
    }

    if ([self imageExistsInDisk:key])
    {
        NSError *error = nil;
        NSString *fileName = [self getFileNameForKey:key];
        [fileManager removeItemAtPath:fileName error:&error];
        [error release];
    }
}

- (void)removeAllImages
{
    [memoryCache removeAllObjects];
    
    NSString *cacheDirectoryName = [self getCacheDirectoryName];
    NSArray *items = [fileManager contentsOfDirectoryAtPath:cacheDirectoryName error:nil];
    for (NSString *item in items)
    {
        NSString *path = [cacheDirectoryName stringByAppendingPathComponent:item];
        NSError *error = nil;
        [fileManager removeItemAtPath:path error:&error];
        [error release];
    }
}

- (void)removeAllImagesInMemory
{
    NSLog(@"Image cache cleared!");
    [memoryCache removeAllObjects];
}

- (void)removeOldImages
{
    NSString *cacheDirectoryName = [self getCacheDirectoryName];
    NSArray *items = [fileManager contentsOfDirectoryAtPath:cacheDirectoryName error:nil];
    for (NSString *item in items)
    {
        NSString *path = [cacheDirectoryName stringByAppendingPathComponent:item];
        NSDictionary *attributes = [fileManager attributesOfItemAtPath:path error:nil];
        NSDate *creationDate = [attributes valueForKey:NSFileCreationDate];
        if (abs([creationDate timeIntervalSinceNow]) > IMAGE_FILE_LIFETIME)
        {
            NSError *error = nil;
            [fileManager removeItemAtPath:path error:&error];
        }
    }
}

- (BOOL)imageExistsInMemory:(NSString *)key
{
    return ([memoryCache objectForKey:key] != nil);
}

- (BOOL)imageExistsInDisk:(NSString *)key
{
    if (!enableDiskCache)
        return NO;
    
    NSString *fileName = [self getFileNameForKey:key];
    return [fileManager fileExistsAtPath:fileName];
}

- (NSUInteger)countImagesInMemory
{
    return [memoryCache count];
}

- (NSUInteger)countImagesInDisk
{
    if (!enableDiskCache)
        return 0;
    
    NSString *cacheDirectoryName = [self getCacheDirectoryName];
    NSArray *items = [fileManager contentsOfDirectoryAtPath:cacheDirectoryName error:nil];
    return [items count];
}

#pragma mark -
#pragma mark Private methods

- (void)addImageToMemoryCache:(UIImage *)image withKey:(NSString *)key
{
    //Already in cache, do nothing
    if ([memoryCache objectForKey:key] != nil) {
        //NSLog(@"duplicate cache (expected behaviour)");
        return;
    }
    
    // Remove the first object previously added to the memory cache
    if ([memoryKeyArray count] > MEMORY_CACHE_SIZE)
    {
        // We use memoryKeyArray to keep track of the FIFO of 'key' only
        // We cannot use memoryCache because it is a dictionary
        NSString *lastObjectKey = [memoryKeyArray lastObject];
        
        // Remove expired disk cache images
        [self removeOldImages];
        
        if (enableDiskCache)
        {
            // Transfer to disk
            @try
            {
                [self addImageToDiskCache:[self imageForKey:lastObjectKey] withKey:lastObjectKey];
            }
            @catch ( NSException *e )
            {
                NSLog(@"Failed to transfer memory cache to disk cache");
            }
        }
        
        // Remove from memory cache
        [memoryKeyArray removeLastObject];
        [memoryCache removeObjectForKey:lastObjectKey];
    }    

    // Add the object to the memory cache for faster retrieval next time
    [memoryCache setObject:image forKey:key];
    
    // Add the key at the beginning of the memoryKeyArray
    [memoryKeyArray insertObject:key atIndex:0];
}

- (BOOL)addImageToDiskCache:(UIImage *)image withKey:(NSString *)key
{
    if (!enableDiskCache)
        return NO;
    
    NSData *imageData = UIImagePNGRepresentation(image);
    NSString *savePath = [self getFileNameForKey:key];
    NSLog(@"Save to disk cache: %@", savePath);
    return [fileManager createFileAtPath:savePath contents:imageData attributes:nil];
}

- (NSString *)getCacheDirectoryName
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *cacheDirectoryName = [documentsDirectory stringByAppendingPathComponent:CACHE_FOLDER_NAME];
    return cacheDirectoryName;
}

- (NSString *)getFileNameForKey:(NSString *)key
{
    if (![key isKindOfClass:[NSString class]])
        return nil;
    
    // The input 'key' is usually a full HTTP path (eg. http://abc.facebuk.com")
    // We need to replace '/' by something else in order to avoid sub-directories
    NSString *modifiedKey = [key stringByReplacingOccurrencesOfString:@"/" withString:@"||"];
    
    NSString *cacheDirectoryName = [self getCacheDirectoryName];
    NSString *fileName = [cacheDirectoryName stringByAppendingPathComponent:modifiedKey];
    return fileName;
}

@end
