//
//  NVMClient.m
//  NeoVimX
//
//  Created by Stefan Hoffmann on 05.06.14.
//  Copyright (c) 2014 neovim. All rights reserved.
//

#import "NVMClient.h"

#import <sys/socket.h>
#import <sys/un.h>
#import <sys/ioctl.h>
#import "MessagePack.h"


@interface NVMClient()

@property (strong) dispatch_queue_t internalQueue;

@property (strong) NSFileHandle *stream;
@property (strong) MessagePackParser *parser;
@property int channelID;
@property int nextRequestID;
@property (strong) NSMutableDictionary *callbacks;
@property (strong) NSMutableDictionary *eventCallbacks;
@property (strong) NSDictionary *apiClasses;
@property (strong) NSDictionary *apiFunctions;
@property BOOL redrawStartEndSubscribed;
@property (strong) NSMutableDictionary *redrawCallbacks;
@property (strong) NSMutableArray *bufferdReadrawCallbacks;

@end


@implementation NVMClient

- (id)init
{
    self = [super init];
    if (self) {
        self.internalQueue = dispatch_queue_create("org.neovim.client",
                                                   DISPATCH_QUEUE_SERIAL);
        self.callbackQueue = dispatch_get_main_queue();
        self.stream = nil;
        self.parser = [MessagePackParser new];
        self.channelID = 0;
        self.nextRequestID = 0;
        self.callbacks = [NSMutableDictionary new];
        self.eventCallbacks = [NSMutableDictionary new];
        self.apiClasses = nil;
        self.apiFunctions = nil;
        self.redrawStartEndSubscribed = NO;
        self.redrawCallbacks = [NSMutableDictionary new];
        self.bufferdReadrawCallbacks = nil;
    }
    return self;
}

- (void)connectTo:(NSString *) address
{
    struct sockaddr_un sun;

    sun.sun_family = AF_UNIX;
    strcpy (sun.sun_path, address.UTF8String);
    sun.sun_len = SUN_LEN(&sun);

    int sock = socket(PF_UNIX, SOCK_STREAM, 0);
    if (connect(sock, (struct sockaddr *)&sun, sun.sun_len) != 0) {
        // TODO(stefan991): better error handling
        NSLog(@"connection failed");
        return;
    }
    self.stream = [[NSFileHandle alloc] initWithFileDescriptor:sock
                                                closeOnDealloc:YES];

    __weak __typeof(*self) *weakSelf = self;
    self.stream.readabilityHandler = ^(NSFileHandle *stream) {
        [weakSelf readabilityHandler:stream];
    };
}

- (void)discoverApi:(NVMCallback)callback
{
    dispatch_async(self.internalQueue, ^{
        [self callMethod:@"vim_get_api_info"
                  params:nil
                callback:^(id error, id result) {

            if (error) {
                dispatch_async(self.callbackQueue, ^{
                    callback(error, nil);
                });
                return;
            }
            self.channelID = ((NSNumber *)result[0]).intValue;
            NSDictionary *api = result[1];
            self.apiClasses = [api[@"classes"] copy];
            NSArray *apiFunctionsArray = api[@"functions"];
            NSMutableDictionary *apiFunctions = [NSMutableDictionary new];
            for (NSDictionary *functon in apiFunctionsArray) {
                apiFunctions[functon[@"name"]] = functon;
            }
            self.apiFunctions = [apiFunctions copy];
            dispatch_async(self.callbackQueue, ^{
                callback(error, result);
            });
        }];
    });
}

- (void)callMethod:(NSString *)methodName
            params:(NSArray *)params
          callback:(NVMCallback)callback
{
    if (!params) {
        params = @[];
    }
    dispatch_async(self.internalQueue, ^{
        int requestID = self.nextRequestID++;
        NSArray *apiCall = @[@0, @(requestID), methodName, params];
        self.callbacks[@(requestID)] = callback;
        [self.stream writeData:[apiCall messagePack]];
    });
}

- (void)subscribeEvent:(NSString *)eventName
         eventCallback:(NVMCallback)eventCallback
     completionHandler:(NVMCallback)completionHandler
{
    dispatch_async(self.internalQueue, ^{
        NSMutableArray *callbacks = self.eventCallbacks[eventName];
        if (callbacks) {
            [callbacks addObject:eventCallback];
        } else {
            [self callMethod:@"vim_subscribe"
                      params:@[eventName]
                    callback:completionHandler];

            callbacks = [NSMutableArray arrayWithObject:eventCallback];
            self.eventCallbacks[eventName] = callbacks;
        }
    });
}

- (void)subscribeRedrawEvent:(NSString *)eventName
               eventCallback:(NVMCallback)eventCallback
           completionHandler:(NVMCallback)completionHandler
{
    dispatch_async(self.internalQueue, ^{

        dispatch_group_t startEndGroup = dispatch_group_create();

        // subscribe to 'redraw:{start,stop}' if not already done
        if (!self.redrawStartEndSubscribed) {
            // TODO(stefan991): the next two calls dispatch to the main queue,
            //                  remove this extra dispatch
            dispatch_group_enter(startEndGroup);
            [self callMethod:@"vim_subscribe"
                      params:@[@"redraw:start"]
                    callback:^(id error, id result) {
                dispatch_group_leave(startEndGroup);
            }];
            dispatch_group_enter(startEndGroup);
            [self callMethod:@"vim_subscribe"
                      params:@[@"redraw:end"]
                    callback:^(id error, id result) {
                dispatch_group_leave(startEndGroup);
            }];
            self.redrawStartEndSubscribed = YES;
        }
        // subscribe the redraw event
        dispatch_group_notify(startEndGroup, self.internalQueue, ^(){

            NVMCallback internalCallback = ^(id error, id eventData) {
                if (self.bufferdReadrawCallbacks) {
                    [self.bufferdReadrawCallbacks addObject:^{
                        eventCallback(nil, eventData);
                    }];
                } else {
                    dispatch_async(self.callbackQueue, ^{
                        eventCallback(nil, eventData);
                    });
                }
            };

            NSMutableArray *callbacks = self.redrawCallbacks[eventName];
            if (callbacks) {
                [callbacks addObject:internalCallback];
            } else {
                [self callMethod:@"vim_subscribe"
                          params:@[eventName]
                        callback:completionHandler];

                callbacks = [NSMutableArray arrayWithObject:internalCallback];
                self.redrawCallbacks[eventName] = callbacks;
            }
        });
    });
}

- (void)handleRedrawStart
{
    NSAssert(self.bufferdReadrawCallbacks == nil,
             @"Nested 'redraw:start' events");
    self.bufferdReadrawCallbacks = [NSMutableArray new];
}

- (void)handleRedrawEnd
{
    NSArray *callbacks = self.bufferdReadrawCallbacks;
    self.bufferdReadrawCallbacks = nil;
    dispatch_async(self.callbackQueue, ^{
        for (dispatch_block_t callback in callbacks) {
            callback();
        }
    });
}

- (void)readabilityHandler:(NSFileHandle *)stream
{
    NSData *data = [stream availableData];
    dispatch_async(self.internalQueue, ^{
        [self.parser feed:data];
        NSArray *message;
        while ((message = [self.parser next])) {
            // TODO: see why parsing failes 
            [self handleMessage:message];
        }
    });

}

- (void)handleMessage:(NSArray *)message
{
    NSNumber *type = message[0];
    if ([type isEqualToNumber:@(1)]) {  // response
        NSNumber *requestID = message[1];
        id error = message[2];  // TODO(stefan991): wrap in NSError
        id result = message[3];
        NVMCallback callback = self.callbacks[requestID];
        if (callback) {
            if (error == [NSNull null]) {
                error = nil;
            }
            dispatch_async(self.callbackQueue, ^{
                callback(error, result);
            });
            [self.callbacks removeObjectForKey:requestID];
        } else {
            // TODO(stefan991): improve error handling
            NSLog(@"invalid response");
        }
    }
    if ([type isEqualToNumber:@(2)]) {  // notification
        NSString *eventName = message[1];
        // NSLog(@"Event: %@", eventName);
        if ([eventName isEqualToString:@"redraw:start"]) {
            [self handleRedrawStart];
        }
        if ([eventName isEqualToString:@"redraw:end"]) {
            [self handleRedrawEnd];
        }
        id data = message[2];

        // handle redraw events on internal queue
        NSMutableArray *redrawCallbacks = self.redrawCallbacks[eventName];
        for (NVMCallback callback in redrawCallbacks) {
            callback(nil, data);
        }

        // handle normal events on callback queue
        NSMutableArray *callbacks = self.eventCallbacks[eventName];
        if (callbacks) {
            NSArray *callbacksCopy = [callbacks copy];
            dispatch_async(self.callbackQueue, ^{
                for (NVMCallback callback in callbacksCopy) {
                    callback(nil, data);
                }
            });
        }
    }
}

@end
