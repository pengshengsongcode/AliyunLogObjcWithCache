//
//  CacheCheckManager.m
//  HBCGAPP
//
//  Created by 彭盛凇 on 2019/3/16.
//  Copyright © 2019 HBC. All rights reserved.
//

#import "CacheCheckManager.h"
#import "DBManager.h"
#import "RawLogGroup.h"
#import "RawLog.h"

@implementation CacheCheckManager

-(instancetype)initWithTimeInterval:(NSInteger)timeInterval client:(LogClient *)client fetchCount:(NSInteger)fetchCount {
    
    if (self = [super init]) {
        
        self.mTimeInterval = timeInterval;
        
        self.manager = [Reachability reachabilityWithHostName:@"www.aliyun.com"];
        self.group = dispatch_group_create();
        self.mClient = client;
        self.mFetchCount = fetchCount;
    }
    return self;
}

- (void)startCacheCheck {
    [self.manager startNotifier];
    [self startMonitor];
}

- (void)stopMonitor {
    
    if (self.gcdTimer) {
        
        dispatch_source_cancel(self.gcdTimer);
        
        self.gcdTimer = nil;
        
    }
    
}

- (void)startMonitor {
    
    dispatch_queue_t queue = dispatch_queue_create("com.aliyun.sls.gcdTimer",DISPATCH_QUEUE_CONCURRENT);
    
    if (self.gcdTimer) {
        
        dispatch_source_cancel(self.gcdTimer);
    }
    
    self.gcdTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    
    dispatch_source_set_timer(self.gcdTimer, DISPATCH_TIME_NOW, self.mTimeInterval*NSEC_PER_SEC, 0);
    
    __weak typeof(self)weakSelf = self;
    
    dispatch_source_set_event_handler(self.gcdTimer, ^{
       
        [weakSelf postLogsFromeDB];
        
    });
    
    dispatch_resume(self.gcdTimer);
    
}

- (id)JSONObject:(NSString *)str {
    NSError *error;
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    
    if (error != nil) {
//        DLog(@"json unSerializ error:%@,json:%@",error,self);
        return nil;
    }
    
    return jsonObject;
}

- (void)postLogsFromeDB {
    
    if ([self.manager currentReachabilityStatus] != ReachableViaWiFi && [self.manager currentReachabilityStatus] != ReachableViaWWAN) {
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
       
        NSArray *logs = [[DBManager sharedInstance] fetchRecordsWithLimit:self.mFetchCount];
        
        if (logs.count <= 0 || self.pending) {
            return;
        }
        
        [logs enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            NSDictionary *record = obj;
            
            NSNumber *IDNumber = [record valueForKey:@"id"];
            
            long long int ID = IDNumber.longLongValue;
            
            NSString *endpoint = [record valueForKey:@"endpoint"];
            NSString *logstore = [record valueForKey:@"logstore"];
            NSString *msg = [record valueForKey:@"log"];
            
            NSDictionary *logDic = [self JSONObject:msg];
            
            NSString *topic = [logDic objectForKey:@"__topic__"];
            NSString *source = [logDic objectForKey:@"__source__"];
            NSArray *realLogs = [logDic objectForKey:@"__logs__"];
            
            [realLogs enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                
                RawLogGroup *logGroup = [[RawLogGroup alloc] initWithTopic:topic andSource:source];
                
                __block RawLog *rawlog = [[RawLog alloc] init];
                
                NSDictionary *log = obj;
                
                [log enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                    
                    [rawlog PutContent:obj withKey:key];
                }];
                
                [logGroup PutLog:rawlog];
                
                if ([[self.mClient GetEndPoint] isEqualToString:endpoint]) {
                    
                    dispatch_group_enter(self.group);
                    
                    self.pending = YES;
                    
                    [self.mClient PostLogInCache:logGroup logStoreName:logstore call:^(NSURLResponse * _Nullable response, NSError * _Nullable error) {
                        
                        dispatch_group_leave(self.group);
                        
                        if (error) {
                            
                        }else {
                            [[DBManager sharedInstance] deleteRecordWithRecord:@{@"id":@(ID)}];
                        }
                        
                        
                    }];
                    
                }
            }];
            
        }];
        
    });
    
    dispatch_group_notify(self.group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
       
        self.pending = NO;
        
    });
    
    [[DBManager sharedInstance] checkDBSize];
    
}

- (void)dealloc {
    [self stopMonitor];
}



@end
