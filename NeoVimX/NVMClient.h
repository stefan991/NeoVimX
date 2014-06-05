//
//  NVMClient.h
//  NeoVimX
//
//  Created by Stefan Hoffmann on 05.06.14.
//  Copyright (c) 2014 neovim. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^NVMCallback)(id error, id result);

@interface NVMClient : NSObject

@property (strong) dispatch_queue_t callbackQueue;

- (void)connectTo:(NSString *)address;

- (void)discoverApi:(NVMCallback)callback;

- (void)callMethod:(NSString *)methodName
			params:(NSArray *)params
		  callback:(NVMCallback)callback;

@end
