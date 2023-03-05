//
//  ViewController.m
//  testFCRN
//
//  Created by Doron Adler on 25/08/2019.
//  Copyright © 2019 Doron Adler. All rights reserved.
//

#import "Prediction.h"

@implementation Prediction

- (CGFloat) centreX {
    return (self.BBox.size.width + self.BBox.origin.x) / 2;
}

- (CGFloat) centreY {
    return (self.BBox.size.height + self.BBox.origin.y) / 2;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"label: %@, confidence: %lf, bounding box: %@, average depth: %lf, centre X: %lf, centre Y: %lf", self.Label, self.Confidence, NSStringFromCGRect(self.BBox), self.AvgDepth, self.centreX, self.centreY];
}

@end
