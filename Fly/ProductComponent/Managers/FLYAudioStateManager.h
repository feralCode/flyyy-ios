//
//  FLYAudioStateManager.h
//  Fly
//
//  Created by Xingxing Xu on 11/20/14.
//  Copyright (c) 2014 Fly. All rights reserved.
//

@class AEAudioController;
@class AERecorder;
@class AEAudioFilePlayer;

typedef void (^AudioPlayerCompleteblock)();

@interface FLYAudioStateManager : NSObject

@property (nonatomic) AEAudioController *audioController;
@property (nonatomic) AERecorder *recorder;
@property (nonatomic) AEAudioFilePlayer *player;

- (void)startRecord;
- (void)stopRecord;
- (void)playWithCompletionBlock:(AudioPlayerCompleteblock)block;

+ (instancetype)manager;

@end