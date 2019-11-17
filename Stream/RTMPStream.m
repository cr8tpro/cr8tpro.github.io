//
//  RTMPStream.m
//  PunditsTutor
//
//  Created by Евгений Литвиненко on 16.09.15.
//  Copyright (c) 2015 Developer. All rights reserved.
//
//https://github.com/slavavdovichenko/MediaLibDemos3x/issues/27

#import <mach/mach_time.h>

#import "RTMPStream.h"

#import "BroadcastStreamClient.h"
#import "DEBUG.h"
//url: 52.89.184.69:1935/answers/:tutorId_:questionId
//http://52.3.245.200:1935/testlow/evgenStream/playlist.m3u8
static NSString *host = @"rtmp://ec2-52-89-107-62.us-west-2.compute.amazonaws.com/answers";//@"rtmp://52.3.245.200:1935/testlow";
static int defaultFPS = 24;

@interface RTMPStream ()  <MPIMediaStreamEvent> {
    
    BroadcastStreamClient       *upstream;
    MPVideoResolution           _resolution;
    NSString                    *questionId;
    NSString                    *tutorId;
}

@end

@implementation RTMPStream

- (void)startPublishForTutorId:(NSString*)tId questionId:(NSString*)qId{
    questionId = qId;//[NSString stringWithFormat:@"%@_%@",tId,qId];
    tutorId = tId;
    [self connect];
}

-(void)stopPublish {
    [self disconnect];
}

-(void)sendImageFrame:(UIImage*)image {
    
    if (upstream.state == STREAM_PLAYING) {
        [self serialImage:image];
    }
}

- (void)dealloc {
    upstream.delegate = nil;
}

#pragma mark Private Methods

- (void)connect {
    
    NSLog(@"******************> connect\n");
    
    _resolution = RESOLUTION_VGA;
    
    RTMPClient *client = [[RTMPClient alloc] init:host];
    upstream = [[BroadcastStreamClient alloc] initWithClient:client resolution:_resolution];

    [upstream setVideoCustom:defaultFPS width:768 height:720];
    upstream.delegate = self;
    
    upstream.videoCodecId = MP_VIDEO_CODEC_H264;
    upstream.audioCodecId = MP_AUDIO_CODEC_AAC;
    
    if (!questionId.length)
        questionId = @"evgenStream";
    else
        questionId = [[tutorId stringByAppendingString:@"_"] stringByAppendingString:questionId];
    
    NSLog(@"STREAM_URL: %@/%@/playlist.m3u8",host,questionId);
    
    [upstream stream:questionId publishType:PUBLISH_LIVE];
}

- (void)disconnect {
    
    NSLog(@"******************> disconnect\n");
    [upstream disconnect];
}

- (void)getDisconnected {
    
    NSLog(@"******************> getDisconnected\n");
    upstream = nil;
}

- (void)start {
    
    NSLog(@"******************> start\n");
    [upstream start];
}

- (int64_t)getTimestampMs {
    mach_timebase_info_data_t info;
    mach_timebase_info(&info);
    return 1e-6*mach_absolute_time()*info.numer/info.denom;
}

- (void)serialImage:(UIImage *)image
{
    if (!upstream)
        return;
    
    int64_t _timestamp = [self getTimestampMs];
    
    NSLog(@"serialImage: timestamp = %lld", _timestamp);
    
    NSLog(@"image = %f", image.size.width);
    
    [upstream sendImage:[image CGImage] timestamp:_timestamp];
}

#pragma mark IMediaStreamEvent Methods

- (void)stateChanged:(id)sender state:(MPMediaStreamState)state description:(NSString *)description {
    
    NSLog(@" $$$$$$ <IMediaStreamEvent> stateChangedEvent: %d = %@", (int)state, description);
    
    switch (state) {
            
        case CONN_DISCONNECTED:
        {
            [self getDisconnected];
            break;
        }
            
        case CONN_CONNECTED:
        {
            if (![description isEqualToString:MP_RTMP_CLIENT_IS_CONNECTED])
                break;
            
            [self start];
            break;
        }
            
        case STREAM_PAUSED:
        {
            if ([description isEqualToString:MP_NETSTREAM_PLAY_STREAM_NOT_FOUND]) {
                [self disconnect];
                return;
            }
            
            break;
        }
            
        case STREAM_PLAYING:
        {
            if (![description isEqualToString:MP_NETSTREAM_PUBLISH_START]) {
                [self disconnect];
                return;
            }
            
            break;
        }
            
        default:
            break;
    }
}

-(void)connectFailed:(id)sender code:(int)code description:(NSString *)description {
    
    NSLog(@" $$$$$$ <IMediaStreamEvent> connectFailedEvent: %d = %@\n", code, description);
    
    //if (code > 0)
    {
        [self getDisconnected];
        [self connect];
    }
}

@end
