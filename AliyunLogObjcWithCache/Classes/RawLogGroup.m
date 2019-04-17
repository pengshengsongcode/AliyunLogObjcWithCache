//
//  LogGroup.m
//  AliyunLogObjc
//
//  Created by 陆家靖 on 2016/10/27.
//  Copyright © 2016年 陆家靖. All rights reserved.
//

#import "RawLogGroup.h"
#import "RawLog.h"
#import "JSONSerializer.h"
#import "NSDictionary+HBCExts.h"

@implementation RawLogGroup

- (id)initWithTopic: (NSString *) topic andSource:(NSString *) source {
    if(self = [super init]) {
        _mTopic = topic;
        _mSource = source;
        _rawLogs = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)PutTopic: (NSString *)topic {
    _mTopic = topic;
}

- (void)PutSource: (NSString *)source {
    _mSource = source;
}

- (void)PutLog: (RawLog *)log {
    [_rawLogs addObject:log];
}

- (NSData *) serialize: (AliSLSSerializer) serdeType {
    if (serdeType == AliSLSJSONSerializer) {
        return [(JSONSerializer*)[JSONSerializer sharedInstance] serialize: self];
    } else {
        return nil;
    }
}

- (NSString *) GetTopic {
    return _mTopic;
}

- (NSString *) GetSource {
    return _mSource;
}

- (NSArray<RawLog *> *) GetLogs {
    return _rawLogs;
}

- (NSString *)jsonPachage {
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];

    [dic hbc_setObject:_mTopic forKey:@"__topic__"];
    [dic hbc_setObject:_mSource forKey:@"__source__"];
    
    NSMutableArray *arr = [NSMutableArray array];
    
    [_rawLogs enumerateObjectsUsingBlock:^(RawLog * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
       
        [arr hbc_addObject:[obj GetContent]];
        
    }];
    
    [dic hbc_setObject:arr forKey:@"__logs__"];
    
    return [dic hbc_JSONString];
}

@end
