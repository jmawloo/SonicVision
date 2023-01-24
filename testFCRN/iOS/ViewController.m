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

//ML_MODEL_CLASS_NAME is defined in "User defined build settings"
//ML_MODEL_CLASS_HEADER_STRING=\"$(ML_MODEL_CLASS_NAME).h\"
//ML_MODEL_CLASS=$(ML_MODEL_CLASS_NAME)
//ML_MODEL_CLASS_NAME_STRING=@\"$(ML_MODEL_CLASS_NAME)\"

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
@property (nonatomic, weak) IBOutlet UISlider *framerate;

// FPS
@property (nonatomic, weak) IBOutlet UILabel *fpsDepth;
@property (nonatomic, weak) IBOutlet UILabel *fpsClassify;

@end


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
    //self.textView.stringValue = NSLocalizedString(@"depthPrediction.readyToOpen", @"Please open an image");
    NSLog(@"didLoadModel (\"%@\") & (\"%@\")", ML_MODEL_CLASS_NAME_STRING, ML_MODEL_OBJ_NAME_STRING);
    [self updateStatusLabelText:[NSString stringWithFormat:@"didLoadModel (\"%@\") & (\"%@\")", ML_MODEL_CLASS_NAME_STRING, ML_MODEL_OBJ_NAME_STRING]];
    
}

- (void)didFailToLoadModelWithError:(NSError*)error {
    //self.textView.stringValue = NSLocalizedString(@"depthPrediction.failToLoad", @"Error loading model");
    NSLog(@"Error loading model (\"%@\") because \"%@\"", ML_MODEL_CLASS_NAME_STRING, error);
    [self updateStatusLabelText:[NSString stringWithFormat:@"Error loading model (\"%@\") because \"%@\"", ML_MODEL_CLASS_NAME_STRING, error.localizedDescription]];
}

# pragma mark - Video Frame Capture

- (void)setupCameraSession {


    self.session = [[AVCaptureSession alloc] init];
    [self.session setSessionPreset:AVCaptureSessionPresetLow];

    AVCaptureDevice *inputDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error;
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:inputDevice error:&error];

    if ([self.session canAddInput:deviceInput]) {
        [self.session addInput:deviceInput];
    }
    // mount feed to view.
    AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    CALayer *rootLayer = [[self view] layer];
    [rootLayer setMasksToBounds:YES];
    CGRect frame = self.inputImageView.frame;
    [previewLayer setFrame:frame];
    [rootLayer insertSublayer:previewLayer atIndex:0];

    self.stillImageInput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecTypeJPEG, AVVideoCodecKey, nil];
    [self.stillImageInput setOutputSettings:outputSettings];
    [self.session addOutput:self.stillImageInput];
}

- (IBAction)handleActionForToggleVideoCaptureSwitch:(id)sender {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.toggleVideoCapture.isOn) {
            if (!self.session) {
                [self setupCameraSession];
            }
            //    dispatch_async(dispatch_get_main_queue(), ^{
            //    });
            // NOTE: this doesn't work when being called on a separate thread.
            [self.session startRunning];
            
            self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0/self.framerate.value  target:self selector:@selector(takePhoto) userInfo:nil repeats:YES];
        }
        else {
            [self.timer invalidate];
            [self.session stopRunning];
        }
    });
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
    [self.stillImageInput captureStillImageAsynchronouslyFromConnection:videoConnection
      completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
      if (imageDataSampleBuffer != NULL) {
          NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
          UIImage *tmp = [UIImage imageWithData:imageData];
          [self classifyObjectsFromInputImage:tmp];
          [self predictDepthMapFromInputImage:tmp];
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
        // Generate new rectangle scaled:
        // TODO: verify that these are mapped correctly.
        CGRect scaledRect = CGRectMake(pred.BBox.origin.x * img.size.width, pred.BBox.origin.y * img.size.height, pred.BBox.size.width * img.size.width, pred.BBox.size.height * img.size.height);
        
        NSMutableParagraphStyle* textStyle = NSMutableParagraphStyle.defaultParagraphStyle.mutableCopy;
        textStyle.alignment = NSTextAlignmentLeft;

        NSDictionary* textFontAttributes = @{NSFontAttributeName: [UIFont fontWithName: @"Helvetica" size: 12], NSForegroundColorAttributeName: UIColor.greenColor, NSParagraphStyleAttributeName: textStyle};

        [[NSString stringWithFormat:@"%@ %0.2f %%", pred.Label, pred.Confidence * 100] drawInRect:scaledRect withAttributes:textFontAttributes];
        
        UIRectFrame(scaledRect);
        
        NSLog(@"rectCoords {x,y,width,height} = \"%@\"", NSStringFromCGRect(scaledRect));
    }
    
      UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
      UIGraphicsEndImageContext();
      return newImage;
}

#pragma mark - Image Classification + Depth prediction

// from https://stackoverflow.com/questions/59306701/coreml-and-yolov3-performance-issue
- (void)classifyObjectsFromInputImage:(UIImage*)inputImage {
    NSError *error = nil;
    float threshold = 0.8; // label objects only with 0.8+ accuracy.
    NSMutableArray<Prediction*> *predictions = [[NSMutableArray alloc] init];
    
    // Sort classification labels by highest confidence first:
    NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"confidence" ascending:NO];


    VNRequestCompletionHandler completionHandler =  ^(VNRequest *request, NSError * _Nullable error) {
        
        NSArray *results = request.results;

        for (VNObservation *observation in results) {
            if([observation isKindOfClass:[VNRecognizedObjectObservation class]] && observation.confidence > threshold){ // Detected an object in the first place with confidence x.
                VNRecognizedObjectObservation *obs = (VNRecognizedObjectObservation *) observation;
                CGRect rect = obs.boundingBox;
                
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
                                                          options:@{VNImageOptionCIContext : self.imagePlatform.imagePlatformCoreContext}];
    
    // object classification:
    [self updateStatusLabelText:@"Predicting object classification..."];

    NSDate *start = [NSDate date];
    [self.handler performRequests:@[self.request] error:&error];

    
    [self updateFPSClassifyText:[NSString stringWithFormat:@"Classify FPS: %.2f", -1.0/[start timeIntervalSinceNow]]];

    [predictions removeAllObjects];
}
    

- (void)predictDepthMapFromInputImage:(UIImage*)inputImage {
    NSError *error = nil;

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
                    
                    [self.imagePlatform prepareImagePlatformContextFromResultData:pData
                                                                 pixelSizeInBytes:pixelSizeInBytes
                                                                            sizeX:sizeX
                                                                            sizeY:sizeY];
                    
                    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
                        self.disparityImage = [self.imagePlatform createDisperityDepthImage];
                        //self.depthImage =  [self.imagePlatform createBGRADepthImage];
                        [self didPrepareImages];
                    });
                }
            }
        }
    };
    
    
    self.request = [[VNCoreMLRequest alloc] initWithModel:self.model completionHandler:completionHandler];
    CGImageRef imageRef = [inputImage asCGImageRef];
    self.handler = [[VNImageRequestHandler alloc] initWithCGImage: imageRef
                                                          options:@{VNImageOptionCIContext : self.imagePlatform.imagePlatformCoreContext}];
    //[self.handler performRequests:self.request];
    [self updateStatusLabelText:@"Predicting depth map..."];
    
    NSDate *start = [NSDate date];
    [self.handler performRequests:@[self.request] error:&error];
    
    [self updateFPSDepthText:[NSString stringWithFormat:@"Depth FPS: %.2f", -1.0/[start timeIntervalSinceNow]]];
}

- (void)didPrepareImages {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        self.handler = nil;
        self.request = nil;
        
        //self.textView.stringValue = NSLocalizedString(@"depthPrediction.didPrepareImages", @"Images are ready");
        NSLog(@"Images are ready");
        [self updateStatusLabelText:@"Images are ready"];

        if (self.disparityImage) {
            [self.disparityImageImageView setContentMode:UIViewContentModeScaleAspectFit];
            [self.disparityImageImageView setImage:self.disparityImage];
            self.disparityImageImageView.transform = CGAffineTransformMakeRotation(M_PI_2);
        }
        
        if (self.classifiedImage) {
            [self.classifiedImageView setContentMode:UIViewContentModeScaleAspectFit];
            [self.classifiedImageView setImage:self.classifiedImage];
        }

        
    });
}

@end
