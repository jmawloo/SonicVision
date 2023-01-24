//
//  ImagePlatform.m
//  testFCRN
//
//  Created by Doron Adler on 28/07/2019.
//  Copyright © 2019 Doron Adler. All rights reserved.
//

#import "ImagePlatform.h"

#define kDepthFormat kCVPixelFormatType_DisparityFloat32
// NOTE: uses disparity instead of depth model

//#define kDepthFormat kCVPixelFormatType_DepthFloat32

@import CoreImage;
@import Accelerate;
@import AVFoundation;

@implementation IMAGE_TYPE (ImagePlatform)

- (NSData*)imageJPEGRepresentationWithCompressionFactor:(CGFloat)compressionFactor {
    NSData *imageJPEGRepresentation = UIImageJPEGRepresentation(self, compressionFactor);
    return imageJPEGRepresentation;
}

- (CGImageRef)asCGImageRef {
    CGImageRef imgRef = self.CGImage;
    
    return imgRef;
}

@end

typedef struct _sImagePlatformContext {
    uint8_t *pData;
    uint8_t pixelSizeInBytes;
    int sizeX;
    int sizeY;
    
    float   *spBuff;
    size_t  spBuffSize;
    float   maxV;
    float   minV;
    
    
}sImagePlatformContext, *sImagePlatformContextPtr;

@interface ImagePlatform () {
    CGColorSpaceRef _colorSpaceRGB;
    sImagePlatformContext _context;
}

@property (nonatomic, strong) CIContext     *imagePlatformCoreContext;
@property (nonatomic, strong) CIImage *scaledDepthImage;

@end

@implementation ImagePlatform

#pragma mark - init / dealloc

- (instancetype)init
{
    self = [super init];
    if (self) {
        _context.pData = NULL;
        _context.pixelSizeInBytes = 0;
        _context.sizeX = 0;
        _context.sizeY = 0;
        _context.spBuff = NULL;
        _context.spBuffSize = 0;
        _context.maxV = 0.0f;
        _context.minV = 0.0f;
        [self setupCoreContext];
    }
    return self;
}

- (void)dealloc
{
    [self teardownInternalContext];
    [self teardownCoreContext];
}

- (void)teardownInternalContext {
    if (_context.pData) {
        free(_context.pData);
        _context.pData = NULL;
    }
    
    _context.pixelSizeInBytes = 0;
    _context.sizeX = 0;
    _context.sizeY = 0;
    
    if (_context.spBuff) {
        free(_context.spBuff);
        _context.spBuff = NULL;
    }
    
    _context.spBuffSize = 0;
    
    _context.maxV = 0.0f;
    _context.minV = 0.0f;
}

- (void)setupCoreContext {
    
    if (self.imagePlatformCoreContext ==  nil) {
        NSDictionary *options = @{kCIContextWorkingColorSpace   : [NSNull null],
                                  kCIContextUseSoftwareRenderer : @(NO)};
        self.imagePlatformCoreContext = [CIContext contextWithOptions:options];
    }
    
    if (_colorSpaceRGB == NULL) {
        _colorSpaceRGB = CGColorSpaceCreateDeviceRGB();
    }
}

- (void)teardownCoreContext {
    self.imagePlatformCoreContext = nil;
    
    if (_colorSpaceRGB) {
        CGColorSpaceRelease(_colorSpaceRGB);
        _colorSpaceRGB = NULL;
    }
}

- (CGColorSpaceRef) colorSpaceRGB {
    return _colorSpaceRGB;
}

#pragma mark - Pixel buffer reference to image

- (CIImage *)ciImageFromPixelBuffer:(CVPixelBufferRef _Nonnull)cvPixelBufferRef
                   imageOrientation:(UIImageOrientation)imageOrientation {
    return ([CIImage imageWithCVImageBuffer:cvPixelBufferRef]);
}

- (IMAGE_TYPE*)imageFromCVPixelBufferRef:(CVPixelBufferRef)cvPixelBufferRef
                        imageOrientation:(UIImageOrientation)imageOrientation
{
    IMAGE_TYPE* imageFromCVPixelBufferRef = nil;
    
    CIImage * ciImage = [self ciImageFromPixelBuffer:cvPixelBufferRef imageOrientation:imageOrientation];
    CGRect imageRect = CGRectMake(0, 0,
                                  CVPixelBufferGetWidth(cvPixelBufferRef),
                                  CVPixelBufferGetHeight(cvPixelBufferRef));
    
    // creates image given context and rectangular bounds.
    CGImageRef imageRef = [self.imagePlatformCoreContext
                           createCGImage:ciImage
                           fromRect:imageRect];
    
    if (imageRef) {
        imageFromCVPixelBufferRef = [IMAGE_TYPE imageWithCGImage:imageRef scale:1.0 orientation:imageOrientation];
        CGImageRelease(imageRef);
    }
    
    return imageFromCVPixelBufferRef;
}

#pragma mark - Utility - CGImagePropertyOrientation <-> UIImageOrientation convertion

- (CGImagePropertyOrientation) CGImagePropertyOrientationForUIImageOrientation:(UIImageOrientation)uiOrientation {
    switch (uiOrientation) {
        default:
        case UIImageOrientationUp: return kCGImagePropertyOrientationUp;
        case UIImageOrientationDown: return kCGImagePropertyOrientationDown;
        case UIImageOrientationLeft: return kCGImagePropertyOrientationLeft;
        case UIImageOrientationRight: return kCGImagePropertyOrientationRight;
        case UIImageOrientationUpMirrored: return kCGImagePropertyOrientationUpMirrored;
        case UIImageOrientationDownMirrored: return kCGImagePropertyOrientationDownMirrored;
        case UIImageOrientationLeftMirrored: return kCGImagePropertyOrientationLeftMirrored;
        case UIImageOrientationRightMirrored: return kCGImagePropertyOrientationRightMirrored;
    }
}

-(UIImageOrientation) UIImageOrientationForCGImagePropertyOrientation:(CGImagePropertyOrientation)cgOrientation {
    switch (cgOrientation) {
        default:
        case kCGImagePropertyOrientationUp: return UIImageOrientationUp;
        case kCGImagePropertyOrientationDown: return UIImageOrientationDown;
        case kCGImagePropertyOrientationLeft: return UIImageOrientationLeft;
        case kCGImagePropertyOrientationRight: return UIImageOrientationRight;
        case kCGImagePropertyOrientationUpMirrored: return UIImageOrientationUpMirrored;
        case kCGImagePropertyOrientationDownMirrored: return UIImageOrientationDownMirrored;
        case kCGImagePropertyOrientationLeftMirrored: return UIImageOrientationLeftMirrored;
        case kCGImagePropertyOrientationRightMirrored: return UIImageOrientationRightMirrored;
    }
}


#pragma mark - Utility - Pixel buffer

- (void)teardownPixelBuffer:(CVPixelBufferRef*)pPixelBufferRef {
    if (*pPixelBufferRef != NULL) {
        //        GTLog(@"teardownPixelBuffer: \"%@\"", (*pPixelBufferRef));
        CVPixelBufferRelease(*pPixelBufferRef);
        *pPixelBufferRef = NULL;
    }
}

- (BOOL)setupPixelBuffer:(CVPixelBufferRef*)pPixelBufferRef
         pixelFormatType:(OSType)pixelFormatType
                withRect:(CGRect)rect {
    
    if ((rect.size.width <= 0) || (rect.size.height <= 0)) {
        return NO;
    }
    
    if (*pPixelBufferRef != NULL) {
        [self teardownPixelBuffer:pPixelBufferRef];
    }
    
    NSDictionary *pixelBufferAttributes = @{ (NSString*)kCVPixelBufferIOSurfacePropertiesKey : @{},
                                             (NSString*)kCVPixelBufferOpenGLESCompatibilityKey: @YES};
    
    CVReturn cvRet =  CVPixelBufferCreate(kCFAllocatorDefault,
                                          rect.size.width,
                                          rect.size.height,
                                          pixelFormatType,
                                          (__bridge CFDictionaryRef)pixelBufferAttributes,
                                          pPixelBufferRef);
    
    if (cvRet != kCVReturnSuccess)
    {
        NSLog(@"CVPixelBufferCreate failed to create a pixel buffer (\"%d\")", cvRet);
        return NO;
    }
    
    // NSLog(@"Done: setupPixelBuffer: \"%@\" withRect: \"{%f, %f, %f, %f}\"", (*pPixelBufferRef), rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
    
    return YES;
}

#pragma mark - Depth buffer proccesing

- (BOOL)prepareImagePlatformContextFromResultData:(uint8_t *)pData
                                 pixelSizeInBytes:(uint8_t)pixelSizeInBytes
                                            sizeX:(int)sizeX
                                            sizeY:(int)sizeY {
    
    if ((_context.sizeX != sizeX) || (_context.sizeY != sizeY) || (_context.pixelSizeInBytes != pixelSizeInBytes)) {
        [self teardownInternalContext];
    }
    
    if (_context.pData == NULL) {
        _context.pData = malloc(sizeX * sizeY * pixelSizeInBytes);
        _context.pixelSizeInBytes = pixelSizeInBytes;
        _context.sizeX = sizeX;
        _context.sizeY = sizeY;
    }
    
    memcpy(_context.pData, pData, (sizeX * sizeY * pixelSizeInBytes));
    
    if (_context.spBuff == NULL) {
        _context.spBuffSize = sizeX * sizeY * sizeof(float);
        _context.spBuff = malloc(_context.spBuffSize);
    }
    /**
     
      scale = 1.0 / (max + (min / 2))
            max + min / 2 = 1 / scale
        Dunno y this is the design decision.
     */
    // Likely scales image buffer for depth perception. Stored as 1D array.
    double maxVD = 0.;
    vDSP_maxvD((const double *)pData, 1, &maxVD, sizeY*sizeX);
    double minVD = 0.;
    vDSP_minvD((const double *)pData, 1, &minVD, sizeY*sizeX);
    
    NSLog(@"maxVD: %f minVD: %f", maxVD, minVD);
    
//    const double scalar = 1.0 / ((maxVD+minVD)/2.0); // Try midpoint formula, (maxVD+minVD)/2
//    vDSP_vsmulD((const double *)pData, 1, &scalar, (double *)_context.pData, 1, sizeY*sizeX); // multiply vector by scalar.
//    vDSP_vdpsp((const double *)_context.pData,1, (float*)_context.spBuff, 1,  sizeY*sizeX); // double to float precision (spBuff is output).
    
    const double scalar = 1.0 / (maxVD-minVD);
    const double offset = -minVD;
    
    vDSP_vsaddD((const double *)_context.pData, 1, &offset, (double *)pData, 1, sizeY*sizeX);
    vDSP_vsmulD((const double *)pData, 1, &scalar, (double *)_context.pData, 1, sizeY*sizeX); // multiply vector by scalar.
    vDSP_vdpsp((const double *)_context.pData,1, (float*)_context.spBuff, 1,  sizeY*sizeX); // double to float precision (spBuff is output).
    
    float maxV = 0.;
    float minV = 0.;
    vDSP_maxv((float*)_context.spBuff, 1, &maxV, _context.sizeY*_context.sizeX);
    vDSP_minv((float*)_context.spBuff, 1, &minV, _context.sizeY*_context.sizeX);
    
    _context.maxV = maxV;
    _context.minV = minV;
    
    [self prepareDisperityDepthImage];
    
    return YES;
}

- (void)prepareDisperityDepthImage {
    NSAssert((_context.pixelSizeInBytes == 8), @"Expected double sized elements");
    
    CVPixelBufferRef grayImageBuffer = NULL;
    CGRect pixelBufferRect = CGRectMake(0.0f, 0.0f, (CGFloat)(_context.sizeX), (CGFloat)(_context.sizeY));
    BOOL didSetup = [self setupPixelBuffer:&grayImageBuffer
                           pixelFormatType:kDepthFormat
                                  withRect:pixelBufferRect];
    
    if (grayImageBuffer == NULL || didSetup == NO) {
        return;
    }
    
    CVPixelBufferLockBaseAddress(grayImageBuffer, 0);
    float *spBuff = (float *)CVPixelBufferGetBaseAddress(grayImageBuffer);
    memcpy(spBuff, _context.spBuff, _context.spBuffSize);
    CVPixelBufferUnlockBaseAddress(grayImageBuffer, 0);
    
    CIImage *unproccessedImage = [CIImage imageWithCVImageBuffer:grayImageBuffer];
    
    // Remove pixel artifacts; sharpen image result using lanczos transform.
    CIFilter *lanczosScaleTransform = [CIFilter filterWithName:@"CILanczosScaleTransform"];
    [lanczosScaleTransform setValue:unproccessedImage forKey:kCIInputImageKey];
    
#define kDepthMapScaleFactor (5.0f)
    [lanczosScaleTransform setValue:@(kDepthMapScaleFactor) forKey: kCIInputScaleKey];
    
    CGFloat aspectRatio = 1.0f;
    [lanczosScaleTransform setValue:@(aspectRatio) forKey: kCIInputAspectRatioKey];
    
    CIFilter *colorInvert = [CIFilter filterWithName:@"CIColorInvert"];
    [colorInvert setValue:[lanczosScaleTransform outputImage] forKey:kCIInputImageKey];
    
    CIImage *scaledDepthImage = [colorInvert outputImage];
    CGRect scaledDepthImageRect = [scaledDepthImage extent];
    CVPixelBufferRef scaledDepthPixelBufferRef = NULL;
    didSetup = [self setupPixelBuffer:&scaledDepthPixelBufferRef
                      pixelFormatType:kDepthFormat
                             withRect:scaledDepthImageRect];
    
    if (scaledDepthPixelBufferRef == NULL || didSetup == NO) {
        [self teardownPixelBuffer:&grayImageBuffer];
        return;
    }
    
    [self.imagePlatformCoreContext render:scaledDepthImage toCVPixelBuffer:scaledDepthPixelBufferRef];
    
    self.scaledDepthImage = [CIImage imageWithCVImageBuffer:scaledDepthPixelBufferRef];
    
    [self teardownPixelBuffer:&grayImageBuffer];
    [self teardownPixelBuffer:&scaledDepthPixelBufferRef];
}

- (IMAGE_TYPE*)createDisperityDepthImage {
    
    // We already ran Depth model at this point, just need to convert output into image with correct orientation.
    CVPixelBufferRef scaledDepthPixelBufferRef = [self.scaledDepthImage pixelBuffer];
    
    IMAGE_TYPE * depthImage = [self imageFromCVPixelBufferRef:scaledDepthPixelBufferRef imageOrientation:UIImageOrientationUp];
    
    return depthImage;
}

- (nullable NSDictionary *)auxiliaryDictWithImageData:(nonnull NSData *)imageData
                                     infoMetadataDict:(NSDictionary *)infoMetadataDict
                                              xmpPath:(NSString*)xmpPath {
    
    NSData* xmpData = [NSData dataWithContentsOfFile:xmpPath];
    CFDataRef xmpDataRef = (__bridge CFDataRef)xmpData;
    CGImageMetadataRef imgMetaData = CGImageMetadataCreateFromXMPData(xmpDataRef);
    
    NSDictionary *auxDict = @{(NSString*)kCGImageAuxiliaryDataInfoData : imageData,
                              (NSString*)kCGImageAuxiliaryDataInfoMetadata : (id)CFBridgingRelease(imgMetaData),
                              (NSString*)kCGImageAuxiliaryDataInfoDataDescription : infoMetadataDict};
    
    //[AVDepthData depthDataFromDictionaryRepresentation:auxDict error:&error];
    
    return auxDict;
}

@end
