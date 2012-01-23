//
//  ImageCache.h
//  ImageCacheTest
//
//  Created by Adrian on 1/28/09.
//  Copyright 2009 Adrian Kosmaczewski. All rights reserved.
//

#import <Foundation/Foundation.h>

#define MEMORY_CACHE_SIZE  50
#define ENABLE_DISK_CACHE  NO
#define CACHE_FOLDER_NAME @"ImageCacheFolder"

// 2 hours converted to seconds
#define IMAGE_FILE_LIFETIME 7200.0

@interface ImageCache : NSObject 
{
@private
    NSMutableArray *memoryKeyArray;
    NSMutableDictionary *memoryCache;
    NSFileManager *fileManager;
    BOOL enableDiskCache;
}

+ (ImageCache *)sharedImageCache;

- (UIImage *)imageForKey:(NSString *)key;

- (BOOL)hasImageWithKey:(NSString *)key;

- (void)storeImage:(UIImage *)image withKey:(NSString *)key;

- (BOOL)imageExistsInMemory:(NSString *)key;

- (BOOL)imageExistsInDisk:(NSString *)key;

- (NSUInteger)countImagesInMemory;

- (NSUInteger)countImagesInDisk;

- (void)removeImageWithKey:(NSString *)key;

- (void)removeAllImages;

- (void)removeAllImagesInMemory;

- (void)removeOldImages;

@end
