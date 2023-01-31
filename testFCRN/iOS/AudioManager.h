/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    AudioEngine is the main controller class that manages the following:
                    AVAudioEngine           *_engine;
                    AVAudioEnvironmentNode  *_environment;
                    AVAudioPCMBuffer        *_collisionSoundBuffer;
                    NSMutableArray          *_collisionPlayerArray;
                    AVAudioPlayerNode       *_launchSoundPlayer;
                    AVAudioPCMBuffer        *_launchSoundBuffer;
                    bool                    _multichannelOutputEnabled;
    
                 It creates and connects all the nodes, loads the buffers as well as controls the AVAudioEngine object itself.
*/

@import Foundation;
@import AVFoundation;
@import SceneKit;

@interface AudioEngine : NSObject

- (void)setupAudio;
- (void)addNodeAndPlayWith:(Float32)x y:(Float32)y z:(Float32)z distance:(Float32)distance type:(NSNumber*)type;

@end
