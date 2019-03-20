//
//  CacheCheckManager.h
//  HBCGAPP
//
//  Created by 彭盛凇 on 2019/3/16.
//  Copyright © 2019 HBC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Reachability.h"
#import "LogClient.h"

//NS_ASSUME_NONNULL_BEGIN

/// 本地缓存日志的管理器。在实例化时会开启定时器,网络状态监控器。每隔30秒会判断是否达到发送的网络条件,如果是的话,则从缓存中读取30条记录,然后批量上传。同时还会判断本地数据库文件是否达到大小上限(默认是30M,大于30M时从数据库中删除最先加入到数据库中的2000条记录) 此时处于上传中状态。当所有在group中的请求都结束时,才重置为可用状态。

@interface CacheCheckManager : NSObject

@property (nonatomic, strong) dispatch_source_t gcdTimer;
@property (nonatomic, strong) Reachability *manager;
@property (nonatomic, assign) BOOL pending;
@property (nonatomic) dispatch_group_t group;
@property (nonatomic) LogClient *mClient;
@property (nonatomic, assign) NSInteger mTimeInterval;
@property (nonatomic, assign) NSInteger mFetchCount;

-(instancetype)initWithTimeInterval:(NSInteger)timeInterval client:(LogClient *)client fetchCount:(NSInteger)fetchCount;

- (void)startCacheCheck;

@end

//NS_ASSUME_NONNULL_END
