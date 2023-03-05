//
//  ViewController.m
//  testFCRN
//
//  Created by Doron Adler on 25/08/2019.
//  Copyright © 2019 Doron Adler. All rights reserved.
//

#import "ViewController.h"
#import "Prediction.h"

@import Photos;


// TODO: focus on depth perception, (edge detection?), wide angle camera setting.
// NOTE: Focussing on wide angle camera setting first.
// Then see if depth perception still works.

// TODO: normalize 0-1 depth perception.

//ML_MODEL_CLASS_NAME is defined in "User defined build settings"
//ML_MODEL_CLASS_HEADER_STRING=\"$(ML_MODEL_CLASS_NAME).h\"
//ML_MODEL_CLASS=$(ML_MODEL_CLASS_NAME)
//ML_MODEL_CLASS_NAME_STRING=@\"$(ML_MODEL_CLASS_NAME)\"
// NOTE: https://stackoverflow.com/questions/5198905/h-file-not-found if experience *.h file not found
#import ML_MODEL_CLASS_HEADER_STRING
#import ML_MODEL_OBJ_HEADER_STRING
#import "ImagePlatform.h"

@import CoreML;
@import Vision;
@import AVFoundation;   // Video frame capture

// TODO: increase contrast + sharpness of image to give more well-defined edges? Also LPF far away details?
// TODO: ideal demo environment in synopsium; light background uniform environment to give more contrast to well-recognized/easily distinguishable objects.

@interface ViewController ()  <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, strong) ML_MODEL_CLASS *fcrn;
@property (nonatomic, strong) ML_MODEL_OBJ *yolov3;

@property (nonatomic, strong) VNCoreMLModel *model;
@property (nonatomic, strong) VNCoreMLModel *model2;

@property (nonatomic, strong) VNCoreMLRequest *request;
@property (nonatomic, strong) VNImageRequestHandler *handler;

@property (nonatomic, strong) NSMutableArray<Prediction*> *predictions;


@property (nonatomic, strong) ImagePlatform* imagePlatform;

@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageInput;
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) NSTimer *timer;


@property (nonatomic, weak) IBOutlet UIImageView *inputImageView;
@property (nonatomic, strong) NSString *mediaType;
@property (nonatomic, strong) UIImage *classifiedImage;
@property (nonatomic, weak) IBOutlet UIImageView *classifiedImageView;

@property (nonatomic, strong) UIImage *disparityImage;
@property (nonatomic, weak) IBOutlet UIImageView *disparityImageImageView;

@property (nonatomic, weak) IBOutlet UILabel *statusLabel;

@property (nonatomic, strong) NSData *combinedImageData;

@property (nonatomic, weak) IBOutlet UISwitch *toggleVideoCapture;

// FPS
@property (nonatomic, weak) IBOutlet UILabel *fpsDepth;
@property (nonatomic, weak) IBOutlet UILabel *fpsClassify;

@end

#define DETECTION_CONFIDENCE_THRESHOLD 0

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.imagePlatform = [[ImagePlatform alloc] init];
    
    [self updateStatusLabelText:@"Loading model"];
    
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        [self loadModel];
    });
}


- (void)loadModel {
    NSError *error = nil;
   
    self.fcrn = [[ML_MODEL_CLASS alloc] init];
    MLModelConfiguration *config = self.fcrn.model.configuration;
    config.allowLowPrecisionAccumulationOnGPU = true;
    config.computeUnits = MLComputeUnitsAll;
    
    self.model = [VNCoreMLModel modelForMLModel:self.fcrn.model error:&error];
    
    self.yolov3 = [[ML_MODEL_OBJ alloc] init];
    config = self.yolov3.model.configuration;
    config.allowLowPrecisionAccumulationOnGPU = true;
    config.computeUnits = MLComputeUnitsAll;
    
    self.model2 = [VNCoreMLModel modelForMLModel:self.yolov3.model error:&error];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.model != nil && self.model2 != nil) {
            [self didLoadModel];
        } else {
            [self didFailToLoadModelWithError:error];
        }
    });
    
}

- (void)didLoadModel {
    NSLog(@"didLoadModel (\"%@\") & (\"%@\")", ML_MODEL_CLASS_NAME_STRING, ML_MODEL_OBJ_NAME_STRING);
    [self updateStatusLabelText:[NSString stringWithFormat:@"didLoadModel (\"%@\") & (\"%@\")", ML_MODEL_CLASS_NAME_STRING, ML_MODEL_OBJ_NAME_STRING]];
    
}

- (void)didFailToLoadModelWithError:(NSError*)error {
    //self.textView.stringValue = NSLocalizedString(@"depthPrediction.failToLoad", @"Error loading model");
    NSLog(@"Error loading model (\"%@\") because \"%@\"", ML_MODEL_CLASS_NAME_STRING, error);
    [self updateStatusLabelText:[NSString stringWithFormat:@"Error loading model (\"%@\") because \"%@\"", ML_MODEL_CLASS_NAME_STRING, error.localizedDescription]];
}

# pragma mark - Wide angle Camera Capture

- (void)setupCameraSession {


    self.session = [[AVCaptureSession alloc] init];
    [self.session setSessionPreset:AVCaptureSessionPreset640x480];

    AVCaptureDevice *inputDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType: AVMediaTypeVideo position:AVCaptureDevicePositionBack
    ];
    
    // Configure hardware to zoom out.
    NSError *error;
    [inputDevice lockForConfiguration:&error];
    
    inputDevice.videoZoomFactor = 1.0;
    
    [inputDevice unlockForConfiguration];
    
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:inputDevice error:&error];

    if ([self.session canAddInput:deviceInput]) {
        [self.session addInput:deviceInput];
    }


    // TODO: convert to AVCapturePhotoOutput and add wide camera angle setting.
    self.stillImageInput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecTypeJPEG, AVVideoCodecKey, nil];
    [self.stillImageInput setOutputSettings:outputSettings];
    [self.session addOutput:self.stillImageInput];
    
    
    // mount feed to view.
    AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
//    [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    CALayer *rootLayer = [[self view] layer];
    [rootLayer setMasksToBounds:YES];
    CGRect frame = self.inputImageView.frame;
    [previewLayer setFrame:frame];
    [rootLayer insertSublayer:previewLayer atIndex:0];
}

- (IBAction)handleActionForToggleVideoCaptureSwitch:(id)sender {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.toggleVideoCapture.isOn) {
            if (!self.session) {
                [self setupCameraSession];
            }
//            dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0), ^{
//
//
////                [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
//            });
            // NOTE: this doesn't work when being called on a separate thread.
            [self.session startRunning];
            self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(takePhoto) userInfo:nil repeats:YES];
        }
        else {
            [self.timer invalidate];
            [self.session stopRunning];
        }
    });
}

#pragma mark - Output conversion utility functions

// Computes average depth per prediction box; modifies prediction objects in place.
- (void) convertToAvgDepth:(NSArray<Prediction *> *)predictions depthMap:(UIImage *)depthMap {
//    NSMutableArray<NSNumber *> *avgDepths = [NSMutableArray array];
    for (Prediction *prediction in predictions) {
        CGRect rect = prediction.BBox;  // Already converted to image dimensions.
        CGFloat totalDepth = 0;
        NSUInteger count = 0;
        
        // Check every pixel in bounding box:
        // NOTE: For more accurate avgDepth, weigh the "closer" values more highly.
        for (int x = rect.origin.x; x < rect.origin.x + rect.size.width; x++) {
            for (int y = rect.origin.y; y < rect.origin.y + rect.size.height; y++) {
                if (x >= 0 && x < depthMap.size.width && y >= 0 && y < depthMap.size.height) {
                    CGFloat depth = [self depthAtPoint:CGPointMake(x, y) inDepthMap:depthMap];
                    if (!isnan(depth)) {
                        totalDepth += depth;
                        count++;
                    }
                }
            }
        }
        if (count > 0) {
            CGFloat avgDepth = totalDepth / count;
            prediction.AvgDepth = avgDepth;
        }
    }
}

- (CGFloat)depthAtPoint:(CGPoint)point inDepthMap:(UIImage *)depthMap {
    CGImageRef cgImage = depthMap.CGImage;
    if (cgImage == NULL) {
        return NAN;
    }
    NSUInteger width = CGImageGetWidth(cgImage);
    NSUInteger height = CGImageGetHeight(cgImage);
    NSUInteger bytesPerPixel = CGImageGetBitsPerPixel(cgImage) / 8;
    NSUInteger bytesPerRow = CGImageGetBytesPerRow(cgImage);
    NSUInteger bitsPerComponent = CGImageGetBitsPerComponent(cgImage);
    CGDataProviderRef provider = CGImageGetDataProvider(cgImage);
    if (provider == NULL) {
        return NAN;
    }
    CFDataRef data = CGDataProviderCopyData(provider);
    if (data == NULL) {
        return NAN;
    }
    const UInt8 *bytes = CFDataGetBytePtr(data);
    if (bytes == NULL) {
        CFRelease(data);
        return NAN;
    }
    NSUInteger x = round(point.x);
    NSUInteger y = round(point.y);
    if (x >= width || y >= height) {
        CFRelease(data);
        return NAN;
    }
    const UInt8 *pixel = bytes + y * bytesPerRow + x * bytesPerPixel;
    CGFloat depth = 0;
    if (bitsPerComponent == 16) {
        uint16_t *pixel16 = (uint16_t *)pixel;
        depth = (CGFloat)(*pixel16) / UINT16_MAX;
    } else if (bitsPerComponent == 8) {
        UInt8 *pixel8 = (UInt8 *)pixel;
        depth = (CGFloat)(*pixel8) / UINT8_MAX;
    }
    CFRelease(data);
    return depth;
}

#pragma mark - Image utility functions

- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    //UIGraphicsBeginImageContext(newSize);
    // In next line, pass 0.0 to use the current device's pixel scaling factor (and thus account for Retina resolution).
    // Pass 1.0 to force exact pixel size.
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (CGImagePropertyOrientation) getImgOrientation:(bool)forDepth {
    if (forDepth) {
        return kCGImagePropertyOrientationRight;
//        return kCGImagePropertyOrientationUp;
    }
    
    return kCGImagePropertyOrientationRightMirrored; // for classification
    // Determine current camera orientation:
//    UIDeviceOrientation curDeviceOrientation = UIDevice.currentDevice.orientation;

//    switch (curDeviceOrientation) {
//    case (UIDeviceOrientationPortraitUpsideDown):  // Device oriented vertically, home button on the top00
//            return kCGImagePropertyOrientationRightMirrored;
//    case (UIDeviceOrientationLandscapeLeft):       // Device oriented horizontally, home button on the right
//            return kCGImagePropertyOrientationRightMirrored;
//    case (UIDeviceOrientationLandscapeRight):      // Device oriented horizontally, home button on the left
//          return kCGImagePropertyOrientationRightMirrored;
//    case (UIDeviceOrientationPortrait):      // Device oriented horizontally, home button on the left
//          return kCGImagePropertyOrientationRightMirrored;
//    default: // UIDeviceOrientationPortrait. Device oriented vertically, home button on the bottom
//            return kCGImagePropertyOrientationRightMirrored;
//    }
}

- (void) takePhoto {
    AVCaptureConnection *videoConnection = nil;
    // isolate for video connection.
    for (AVCaptureConnection *connection in self.stillImageInput.connections) {
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
                videoConnection = connection;
                break;
            }
        }
        if (videoConnection) {
            break;
        }
    }
//    NSLog(@"test");
    if (!videoConnection || !videoConnection.enabled || !videoConnection.active) return;   // Video connection not ready yet.
//    NSLog(@"connection: %@", videoConnection);
    
    [self.stillImageInput captureStillImageAsynchronouslyFromConnection:videoConnection
      completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
      if (imageDataSampleBuffer != NULL) {
          NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
          UIImage *rawOutImg = [UIImage imageWithData:imageData];
//          UIImage *scaledImg = [self imageWithImage:rawOutImg scaledToSize:CGSizeMake(480, 600)];
          [self classifyObjectsFromInputImage:rawOutImg];
          // Depth map now has object predictions
          [self predictDepthMapFromInputImage:rawOutImg];
      }
  }];
}

#pragma mark - Status label + other labels

- (void)updateStatusLabelText:(NSString*)text {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.statusLabel.text = text;
    });
}

- (void)updateFPSDepthText:(NSString*)text {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.fpsDepth.text = text;
    });
}

- (void)updateFPSClassifyText:(NSString*)text {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.fpsClassify.text = text;
    });
}

#pragma mark - Draw Image:

-(UIImage *)drawRectanglesOnImage:(UIImage *)img predictions:(NSMutableArray<Prediction*> *)preds{
      CGSize imgSize = img.size;
      CGFloat scale = 0;
      UIGraphicsBeginImageContextWithOptions(imgSize, NO, scale);
      [img drawAtPoint:CGPointZero];
    
    // Draw frames:
      [[UIColor greenColor] setStroke];
    
    for (Prediction* pred in preds) {
        NSMutableParagraphStyle* textStyle = NSMutableParagraphStyle.defaultParagraphStyle.mutableCopy;
        textStyle.alignment = NSTextAlignmentLeft;

        NSDictionary* textFontAttributes = @{NSFontAttributeName: [UIFont fontWithName: @"Helvetica" size: 16], NSForegroundColorAttributeName: UIColor.greenColor, NSParagraphStyleAttributeName: textStyle};

        [[NSString stringWithFormat:@"%@ %0.2f %%", pred.Label, pred.Confidence * 100] drawInRect:pred.BBox withAttributes:textFontAttributes];
        
        UIRectFrame(pred.BBox);
        
        //NSLog(@"rectCoords {x,y,width,height} = \"%@\"", NSStringFromCGRect(pred.BBox));
    }
    
      UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
      UIGraphicsEndImageContext();
      return newImage;
}

#pragma mark - Image Classification + Depth prediction

// from https://stackoverflow.com/questions/59306701/coreml-and-yolov3-performance-issue
- (void)classifyObjectsFromInputImage:(UIImage*)inputImage {
    NSError *error = nil;
    NSMutableArray<Prediction*> *predictions = [[NSMutableArray alloc] init];
    
    // Sort classification labels by highest confidence first:
    NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"confidence" ascending:NO];


    VNRequestCompletionHandler completionHandler =  ^(VNRequest *request, NSError * _Nullable error) {
        
        NSArray *results = request.results;

        for (VNObservation *observation in results) {
            if([observation isKindOfClass:[VNRecognizedObjectObservation class]] && observation.confidence > DETECTION_CONFIDENCE_THRESHOLD){ // Detected an object in the first place with confidence x.
                VNRecognizedObjectObservation *obs = (VNRecognizedObjectObservation *) observation;
                CGRect rect = VNImageRectForNormalizedRect(obs.boundingBox, (int) (inputImage.size.width * inputImage.scale), (int) (inputImage.size.height * inputImage.scale));
                
                NSArray<VNClassificationObservation *> *labels = obs.labels;
                VNClassificationObservation *bestLabel = [labels sortedArrayUsingDescriptors:@[sd]][0];
                
                Prediction* prediction = [Prediction alloc];
                prediction.Label = bestLabel.identifier;
                prediction.Confidence = bestLabel.confidence;
                prediction.BBox = rect;
                
                [predictions addObject:prediction];
            }
        }
        self.classifiedImage = [self drawRectanglesOnImage:inputImage predictions:predictions];
    };
    
    
    self.request = [[VNCoreMLRequest alloc] initWithModel:self.model2 completionHandler:completionHandler];
    CGImageRef imageRef = [inputImage asCGImageRef];
    
    // NOTE: unsure about options field:
    self.handler = [[VNImageRequestHandler alloc] initWithCGImage: imageRef
                                                      orientation:[self getImgOrientation:false]
                                                          options:@{VNImageOptionCIContext : self.imagePlatform.imagePlatformCoreContext}];
    
    // object classification:
    [self updateStatusLabelText:@"Predicting object classification..."];

    NSDate *start = [NSDate date];
    [self.handler performRequests:@[self.request] error:&error];

    
    [self updateFPSClassifyText:[NSString stringWithFormat:@"Classify FPS: %.2f", -1.0/[start timeIntervalSinceNow]]];

    [self.predictions removeAllObjects];
    self.predictions = predictions;
}
    

- (void)predictDepthMapFromInputImage:(UIImage*)inputImage {
    NSError *error = nil;

    
    NSLog(@"Input image dimensions: %.3f by %.3f, scale: %.3f", inputImage.size.width, inputImage.size.height, inputImage.scale);

    VNRequestCompletionHandler completionHandler =  ^(VNRequest *request, NSError * _Nullable error) {
        NSArray *results = request.results;
        
        for (VNObservation *observation in results) {
            if ([observation isKindOfClass:[VNCoreMLFeatureValueObservation class]]) {
                VNCoreMLFeatureValueObservation *featureValueObservation = (VNCoreMLFeatureValueObservation*)observation;
                MLFeatureValue *featureValue = featureValueObservation.featureValue;
                if (featureValue.type == MLFeatureTypeMultiArray) {
                    MLMultiArray *multiArrayValue = featureValue.multiArrayValue;
                    MLMultiArrayDataType dataType = multiArrayValue.dataType;
                    uint8_t pixelSizeInBytes = (dataType & 0xFF) / 8;
                    uint8_t* pData = (uint8_t*)multiArrayValue.dataPointer;
                    //int sizeZ = [multiArrayValue.shape[0] intValue];
                    int sizeY = [multiArrayValue.shape[1] intValue];
                    int sizeX = [multiArrayValue.shape[2] intValue];
                   // todo: check sizeY and sizeX values,.
                    NSLog(@"sizeX: %d, sizeY: %d", sizeX, sizeY);
                    
                    
                    [self.imagePlatform prepareImagePlatformContextFromResultData:pData
                                                                 pixelSizeInBytes:pixelSizeInBytes
                                                                            sizeX:sizeX
                                                                            sizeY:sizeY];
                    
                    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
                        UIImage *rawOutImg = [self.imagePlatform createDisperityDepthImage];
                        UIImage *scaledImg = [self imageWithImage:rawOutImg scaledToSize:CGSizeMake(480, 640)];
                        
//                        self.disparityImage = [self drawRectanglesOnImage:scaledImg predictions:self.predictions];
                        self.disparityImage = scaledImg;
                        
                        [self didPrepareImages];
                    });
                }
            }
        }
    };
    
    
    self.request = [[VNCoreMLRequest alloc] initWithModel:self.model completionHandler:completionHandler];
    self.request.imageCropAndScaleOption = VNImageCropAndScaleOptionScaleFill;
    CGImageRef imageRef = [inputImage asCGImageRef];
    self.handler = [[VNImageRequestHandler alloc] initWithCGImage: imageRef
                                                      orientation:[self getImgOrientation:true]
                                                          options:@{VNImageOptionCIContext : self.imagePlatform.imagePlatformCoreContext}];
    [self updateStatusLabelText:@"Predicting depth map..."];
    
    NSDate *start = [NSDate date];
    [self.handler performRequests:@[self.request] error:&error];
    
    [self updateFPSDepthText:[NSString stringWithFormat:@"Depth FPS: %.2f", -1.0/[start timeIntervalSinceNow]]];
}

- (void)didPrepareImages {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        self.handler = nil;
        self.request = nil;
        
        NSLog(@"Images are ready");
        [self updateStatusLabelText:@"Images are ready"];

        if (self.disparityImage) {
            [self.disparityImageImageView setContentMode:UIViewContentModeScaleAspectFit];
            [self.disparityImageImageView setImage:[self drawRectanglesOnImage:self.disparityImage predictions:self.predictions]];
            
            
            // NOTE: Assume at this point, we have predictions too:
            if (self.predictions) {
                [self convertToAvgDepth:self.predictions depthMap:self.disparityImage];
                NSLog(@"predictions: %@", self.predictions);
            }
        }
        
        if (self.classifiedImage) {
            [self.classifiedImageView setContentMode:UIViewContentModeScaleAspectFit];
            [self.classifiedImageView setImage:self.classifiedImage];
        }

        
    });
}

@end
