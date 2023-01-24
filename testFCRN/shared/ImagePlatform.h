//
//  ImagePlatform.h
//  testFCRN
//
//  Created by Doron Adler on 28/07/2019.
//  Copyright © 2019 Doron Adler. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TargetPlatform.h"

#if !defined(IMAGE_TYPE)
    #import <UIKit/UIKit.h>
    #define IMAGE_TYPE UIImage
#endif

#define MAKE_RGBA_uint32_t(R, G, B, A) ((((uint32_t)(R & 0xFF)) << 24) | (((uint32_t)(G & 0xFF)) << 16) | (((uint32_t)(B & 0xFF)) << 8 ) | ((uint32_t)(A & 0xFF) << 0 ))

NS_ASSUME_NONNULL_BEGIN

@interface IMAGE_TYPE (ImagePlatform)

- (NSData*)imageJPEGRepresentationWithCompressionFactor:(CGFloat)compressionFactor;
- (CGImageRef)asCGImageRef;

@end

@interface ImagePlatform : NSObject

@property (nonatomic, readonly) CIContext       *imagePlatformCoreContext;
@property (nonatomic, readonly) CGColorSpaceRef colorSpaceRGB;

- (IMAGE_TYPE * __nullable)imageFromCVPixelBufferRef:(CVPixelBufferRef)cvPixelBufferRef
                        imageOrientation:(UIImageOrientation)imageOrientation;

- (BOOL)setupPixelBuffer:(CVPixelBufferRef _Nonnull *_Nullable)pPixelBufferRef
         pixelFormatType:(OSType)pixelFormatType
                withRect:(CGRect)rect;
- (void)teardownPixelBuffer:(CVPixelBufferRef _Nonnull *_Nonnull)pPixelBufferRef;

- (BOOL)prepareImagePlatformContextFromResultData:(uint8_t *)pData
                                 pixelSizeInBytes:(uint8_t)pixelSizeInBytes
                                            sizeX:(int)sizeX
                                            sizeY:(int)sizeY;
- (IMAGE_TYPE* __nullable)createDisperityDepthImage;
//- (IMAGE_TYPE* __nullable)createBGRADepthImage;
- (NSData*)addDepthMapToExistingImage:(IMAGE_TYPE*)existingImage;

- (IMAGE_TYPE* __nullable)depthHistogram;

@end

NS_ASSUME_NONNULL_END
