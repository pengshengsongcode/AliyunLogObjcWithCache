//
//  DBManager.m
//  HBCGAPP
//
//  Created by 彭盛凇 on 2019/3/16.
//  Copyright © 2019 HBC. All rights reserved.
//

#import "DBManager.h"
#import <FMDB.h>

NSString *sls_sql_create_table = @"create table if not exists slslog (id integer primary key autoincrement, endpoint text, project text, logstore text, log text, timestamp double);vacuum slslog;";
NSString *sls_sql_query_table_rowCount = @"select count(*) as count from slslog;";
NSString *sls_sql_query_table = @"select * from slslog order by timestamp asc limit ";
NSString *sls_sql_insert_records = @"insert into slslog (endpoint, project, logstore, log, timestamp) VALUES (?, ?, ?, ?, ?)";
NSString *sls_sql_delete_records = @"delete from slslog where id in(select id from slslog order by timestamp asc limit ";
NSString *sls_sql_delete_specific_records = @"delete from slslog where id=";
NSInteger SLS_MAX_DB_SAVE_RECORDS = 10000;


@interface DBManager ()

@property (nonatomic, strong) FMDatabaseQueue *dbQueue;

@end

@implementation DBManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSFileManager *fm = [NSFileManager defaultManager];
        
        NSString *folderPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingString:@"/slslog"];
        
        if (![fm fileExistsAtPath:folderPath]) {
            
            [fm createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:nil];
            
        }
        
        self.dbQueue = [[FMDatabaseQueue alloc] initWithPath:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingString:@"/slslog/log.sqlite"]];
        
    }
    return self;
}

+ (instancetype)sharedInstance {
    static DBManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (manager == nil) {
            manager = [[DBManager alloc] init];
            [manager checkTableExists];
        }
    });
    
    return manager;
}

- (void)checkTableExists {
    [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
       
        [db executeUpdate:sls_sql_create_table values:nil error:nil];
        
    }];
}

- (void)insertRecordsWithEndpoint:(NSString *)endpoint project:(NSString *)project logstore:(NSString *)logstore log:(NSString *)log timestamp:(double)timestamp {
 
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
       
        [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
            
            NSError *error;
            
            [db executeUpdate:sls_sql_insert_records values:@[endpoint,project,logstore,log,@(timestamp)] error:&error];
            
            
            if (error) {
                
            }
            
        }];
        
    });
    
}

- (void)deleteRecordWithRecord:(NSDictionary *)record {
    if (!record) {
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
           
            id ID = [record valueForKey:@"id"];
            
            //arguments
            NSString *sql = [NSString stringWithFormat:@"%@%@;",sls_sql_delete_specific_records,ID];
            
            [db executeUpdate:sql values:nil error:nil];
            
        }];
        
    });

}

- (NSArray *)fetchRecordsWithLimit:(NSInteger)limit {
    
    __block NSMutableArray *records = [NSMutableArray array];

    if (self.dbQueue) {
        
        [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
            
            NSString *query_sql = [NSString stringWithFormat:@"%@%ld;",sls_sql_query_table, limit];
            
            FMResultSet * rs = [db executeQuery:query_sql values:nil error:nil];
            
            while ([rs next]) {
                
                long long int ID = [rs unsignedLongLongIntForColumn:@"id"];
                NSString *endpoint = [rs stringForColumn:@"endpoint"];
                NSString *project = [rs stringForColumn:@"project"];
                NSString *logstore = [rs stringForColumn:@"logstore"];
                NSString *log = [rs stringForColumn:@"log"];
                double timestamp = [rs doubleForColumn:@"timestamp"];
                
                
                if (endpoint && project && logstore && log) {
                    
                    [records addObject:@{@"id":@(ID),@"endpoint":endpoint,@"project":project,@"logstore":logstore,@"log":log,@"timestamp":@(timestamp)}];
                    
                }
            }
            [rs close];
        }];
        
    }else {
        //--
    }
    
    return records;
    
}

- (void)asyncDeleteRecordsWithCount:(int)count {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
            
            //arguments
            NSString *sql = [NSString stringWithFormat:@"%@%d);vacuum slslog;",sls_sql_delete_records,count];
            
            [db executeUpdate:sql values:nil error:nil];
            
        }];
        
    });
}

- (void)checkDBSize {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSFileManager *fm = [NSFileManager defaultManager];
        
        NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingString:@"/slslog/log.sqlite"];
        
        NSDictionary<NSFileAttributeKey, id> *attributes = [fm attributesOfItemAtPath:path error:nil];
        
         long long fileSize = [attributes fileSize];
        
        if (fileSize > 1024 * 1024 * 30) {
            [self asyncDeleteRecordsWithCount:2000];
        }
        
    });
    
    
}


@end
