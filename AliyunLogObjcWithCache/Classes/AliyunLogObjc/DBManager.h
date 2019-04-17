//
//  DBManager.h
//  HBCGAPP
//
//  Created by 彭盛凇 on 2019/3/16.
//  Copyright © 2019 HBC. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DBManager : NSObject

- (instancetype)init
;

+ (instancetype)sharedInstance ;

- (void)checkTableExists ;

- (void)insertRecordsWithEndpoint:(NSString *)endpoint project:(NSString *)project logstore:(NSString *)logstore log:(NSString *)log timestamp:(double)timestamp ;

- (void)deleteRecordWithRecord:(NSDictionary *)record ;

- (NSArray *)fetchRecordsWithLimit:(NSInteger)limit ;

- (void)asyncDeleteRecordsWithCount:(int)count ;

- (void)checkDBSize ;


@end

NS_ASSUME_NONNULL_END
