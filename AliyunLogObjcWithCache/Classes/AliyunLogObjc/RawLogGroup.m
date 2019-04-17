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

    [dic setObject:_mTopic forKey:@"__topic__"];
    [dic setObject:_mSource forKey:@"__source__"];
    
    NSMutableArray *arr = [NSMutableArray array];
    
    [_rawLogs enumerateObjectsUsingBlock:^(RawLog * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
       
        [arr addObject:[obj GetContent]];
        
    }];
    
    [dic setObject:arr forKey:@"__logs__"];
    
    return [self hbc_JSONString:dic];
}

- (NSString *)hbc_JSONString:(NSDictionary *)dic {
    if ([NSJSONSerialization isValidJSONObject:dic]) {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&error];
        if (error != nil) {
            //            DLog(@"Json Serialize error:%@,jsonObject:%@",error,self);
            return nil;
        }
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        return jsonString;
    }
    return nil;
}

@end
