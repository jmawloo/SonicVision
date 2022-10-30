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

@property (nonatomic, strong) UIImage *depthHistogramImage;
@property (nonatomic, weak) IBOutlet UIImageView *depthHistogramImageImageView;

@property (nonatomic, weak) IBOutlet UILabel *statusLabel;

@property (nonatomic, strong) NSData *combinedImageData;

@property (nonatomic, weak) IBOutlet UIButton *imageOpenButton;
@property (nonatomic, weak) IBOutlet UIButton *depthImageSaveButton;

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
    self.imageOpenButton.enabled = YES;
    self.depthImageSaveButton.enabled = NO;
       
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
#pragma mark - Button action handlers

- (IBAction)handleActionForImageOpenButton:(id)sender {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.imageOpenButton.enabled = NO;
        [self openImagePickerAndSelectImage];
    });
}

- (IBAction)handleActionForDepthImageSaveButton:(id)sender {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.depthImageSaveButton.enabled = NO;
        UIImageWriteToSavedPhotosAlbum(self.disparityImage, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    });
}

#pragma mark - UIImagePickerController

- (void)openImagePickerAndSelectImage {
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    [imagePickerController setDelegate:self];
    [self showViewController:imagePickerController sender:self];
}

#pragma mark - UIImagePickerControllerDelegate
// NOTE: unused.
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey, id> *)info {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIImage *inputImage = [info objectForKey:UIImagePickerControllerEditedImage];
        if (inputImage == nil) {
            inputImage = [info objectForKey:UIImagePickerControllerOriginalImage];
        }

        self.mediaType = [info objectForKey:UIImagePickerControllerMediaType];
        if (inputImage) {
            self.inputImageView.image = inputImage;
            [self dismissViewControllerAnimated:YES completion:^{
                self.imageOpenButton.enabled = NO;
                self.depthImageSaveButton.enabled = NO;

               [self predictDepthMapFromInputImage:inputImage];
            }];

        }


       });
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self.navigationController popToRootViewControllerAnimated:YES];
    [self dismissViewControllerAnimated:NO completion:^{
       self.imageOpenButton.enabled = YES;
    }];
}

// Adds a photo to the saved photos album.  The optional completionSelector should have the form:
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    NSLog(@"image: %@ didFinishSavingWithError: %@ contextInfo: 0x%llx", image, error, (uint64_t)contextInfo);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.depthImageSaveButton setEnabled:YES];
        NSLog(@"Depth image was saved to gallery");
        [self updateStatusLabelText:@"Depth image was saved to gallery"];
    });
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
//         dispatch_async(dispatch_get_main_queue(), ^{
//            // self.textView.stringValue = NSLocalizedString(@"depthPrediction.completionHandler", @"Processing results...");
//             NSLog(@"Processing results...");
//             [self updateStatusLabelText:@"Processing results..."];
//         });
        
        NSArray *results = request.results;
        NSLog(@"results = \"%@\"", results);
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
    
    // draw bounding boxes
//    for(Prediction *prediction in predictions){
//        CGRect rect = [prediction BBox];
//        cv::rectangle(frame,cv::Point(rect.origin.x * width,(1 - rect.origin.y) * height),
//                      cv::Point((rect.origin.x + rect.size.width) * width, (1 - (rect.origin.y + rect.size.height)) * height),
//                      cv::Scalar(0,255,0), 1,8,0);
//    }

    [predictions removeAllObjects];
}
    

- (void)predictDepthMapFromInputImage:(UIImage*)inputImage {
    NSError *error = nil;

    VNRequestCompletionHandler completionHandler =  ^(VNRequest *request, NSError * _Nullable error) {
//         dispatch_async(dispatch_get_main_queue(), ^{
//            // self.textView.stringValue = NSLocalizedString(@"depthPrediction.completionHandler", @"Processing results...");
//             NSLog(@"Processing results...");
//             [self updateStatusLabelText:@"Processing results..."];
//         });
        NSArray *results = request.results;
//        NSLog(@"results = \"%@\"", results);
        for (VNObservation *observation in results) {
            if ([observation isKindOfClass:[VNCoreMLFeatureValueObservation class]]) {
                VNCoreMLFeatureValueObservation *featureValueObservation = (VNCoreMLFeatureValueObservation*)observation;
                MLFeatureValue *featureValue = featureValueObservation.featureValue;
                if (featureValue.type == MLFeatureTypeMultiArray) {
                    //NSLog(@"featureName: \"%@\" of type \"%@\" (%@)", featureValueObservation.featureName, @"MLFeatureTypeMultiArray", @(featureValue.type));
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

- (void)didFinish {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.imageOpenButton.enabled = YES;
    });
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
            [self.depthImageSaveButton setEnabled:YES];
        }
        
        if (self.classifiedImage) {
            [self.classifiedImageView setContentMode:UIViewContentModeScaleAspectFit];
            [self.classifiedImageView setImage:self.classifiedImage];
        }
        
        if (self.depthHistogramImage) {
            [self.depthHistogramImageImageView setImage:self.depthHistogramImage];
        }
        
    });
}

@end
