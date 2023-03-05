//
//  ViewController.h
//  testFCRN
//
//  Created by Doron Adler on 25/08/2019.
//  Copyright © 2019 Doron Adler. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Prediction : NSObject

@property NSString *Label;
@property float Confidence;
@property CGRect BBox;
@property CGFloat AvgDepth;
@property (nonatomic, readonly) CGFloat centreX;
@property (nonatomic, readonly) CGFloat centreY;

@end
