//
//  iKYNetworking.m
//  iKYNetworking
//
//  Created by 郑钦洪 on 16/1/23.
//  Copyright © 2016年 iKingsly. All rights reserved.
//

#import "iKYNetworking.h"
#import "AFNetworking.h"
#import "AFNetworkActivityIndicatorManager.h"
#if __has_include(<YYCache/YYCache.h>)
#import <YYCache.h>
#endif
/// 基础的网络URL
static NSString *privateNetworkBaseUrl = nil;
/// 是否打印网络请求的内容，默认为YES
static BOOL isEnableInterfaceDebug = YES;
/// 是否转换为UTF8编码，默认为NO
static BOOL shouldAutoEncode = NO;
/// 请求体格式，默认为JSON
static iKYRequestType iRequestType = iKYRequestTypeJSON;
/// 响应体格式，默认为JSON
static iKYResponseType iResponseType = iKYResponseTypeJSON;
/// 公共请求头
static NSDictionary *iHttpHeaders = nil;
/// 缓存标识
static NSString * const iKYRequestCache = @"iKYRequestCache";
// 调试的时候用的打印日志
#ifdef DEBUG
#define iKYAppLog(s, ... ) NSLog( @"[%@：in line: %d]-->[message: %@]", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define iKYAppLog(s, ... )
#endif

typedef AFHTTPSessionManager iKYHTTPRequestManager;
@implementation iKYNetworking
#pragma mark - 公共配置部分
+ (void)setUpBaseUrl:(NSString *)baseUrl{
    privateNetworkBaseUrl = baseUrl;
}

+ (NSString *)baseUrl{
    return privateNetworkBaseUrl;
}

+ (void)enableInterfaceDebug:(BOOL)isDebug{
    isEnableInterfaceDebug = isDebug;
}

+ (BOOL)isDebug{
    return isEnableInterfaceDebug;
}

+ (void)shouldAutoEncodeUrl:(BOOL)autoEncode{
    shouldAutoEncode = autoEncode;
}

+ (BOOL)shouldEncode{
    return shouldAutoEncode;
}

+ (void)configRequsetType:(iKYRequestType)requestType{
    iRequestType = requestType;
}

+ (void)configResponseType:(iKYResponseType)responseType{
    iResponseType = responseType;
}

+ (void)configCommonHttpHeaders:(NSDictionary *)httpHeadersDict{
    iHttpHeaders = httpHeadersDict;
}

#pragma mark - 请求方法
#pragma mark - 

#pragma mark - GET Method
+ (iKYRequestDataTask *)getWithUrlString:(NSString *)urlString
                                  params:(NSDictionary *)params
                                 success:(iKYResponseSuccess)success
                                    fail:(iKYResponseFail)fail {
    if ([self shouldEncode]) {
        urlString = [self encodeUrlString:urlString];
    }
    
    iKYHTTPRequestManager *manager = [self manager];

    iKYRequestDataTask *task = [manager GET:urlString
                                 parameters:params
                                   progress:nil
                                    success:^(NSURLSessionDataTask * _Nonnull task,
                                              id  _Nullable responseObject) {
        [self successResponse:responseObject callBack:success];
        if ([self isDebug]) { // 打印网络请求
            [self logWithSuccessResponse:responseObject urlString:urlString params:params];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task,
                NSError * _Nonnull error) {
        if (fail) {
            fail(error);
        }

        if ([self isDebug]) { // 打印错误原因
            [self logWithFailError:error
                         urlString:urlString
                            params:params];
        }
    }];

    [task resume];
    return task;
}

+ (iKYRequestDataTask *)getWithUrlString:(NSString *)urlString
                                 success:(iKYResponseSuccess)success
                                    fail:(iKYResponseFail)fail{
   return [self getWithUrlString:urlString params:nil success:success fail:fail];
}

#pragma mark - POST Method
+ (iKYRequestDataTask *)postWithUrlString:(NSString *)urlString
                                   params:(NSDictionary *)params
                                  success:(iKYResponseSuccess)success
                                     fail:(iKYResponseFail)fail{
    return [self postWithUrlString:urlString
                            params:params
                     cacheInstance:nil
                           success:success
                              fail:fail];
}

+ (iKYRequestDataTask *)postWithUrlString:(NSString *)urlString
                                   params:(NSDictionary *)params
                            cacheInstance:(YYCache *)cache
                                  success:(iKYResponseSuccess)success
                                     fail:(iKYResponseFail)fail{
    iKYHTTPRequestManager *manager = [self manager];
    if ([self shouldEncode]) {
        urlString = [self encodeUrlString:urlString];
    }

    iKYRequestDataTask *task = [manager POST:urlString
                                  parameters:params
                                    progress:nil
                                     success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (cache) {
            NSString *cacheKey = [self cacheDataUrlStringToCacheKey:urlString];
            //YYCache 已经做了responseObject为空处理
            [cache setObject:responseObject forKey:cacheKey];
        }
        [self successResponse:responseObject callBack:success];
        if ([self isDebug]) {
            [self logWithSuccessResponse:responseObject
                               urlString:urlString
                                  params:params];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task,
                NSError * _Nonnull error) {
        if (fail) {
            fail(error);
        }
        if ([self isDebug]) {
            [self logWithFailError:error
                         urlString:urlString
                            params:params];
        }
    }];

    [task resume];
    return task;
}

+ (iKYRequestDataTask *)postWithUrlString:(NSString *)urlString
                                   params:(NSDictionary *)params
                          cacheDataPolicy:(iKYRequestCachePolicy)cachePolicy
                                  success:(iKYResponseSuccess)success
                                     fail:(iKYResponseFail)fail{
    // 用url来做cache的key
    NSString *cacheKey = [self cacheDataUrlStringToCacheKey:urlString];
    // 创建cache
    YYCache *cache = [[YYCache alloc] initWithName:iKYRequestCache];
    cache.memoryCache.shouldRemoveAllObjectsOnMemoryWarning = YES;
    cache.memoryCache.shouldRemoveAllObjectsWhenEnteringBackground = YES;
    
    id object = [cache objectForKey:cacheKey];
    
    switch (cachePolicy) {
        case iKYCahceRequestCachePolicyReturnCacheDataThenLoad: { /// 先加载缓存再做同步请求
            if (object) {
                success(object);
            }
            break;
        }
        case iKYCahceRequestCachePolicyReloadIgnoringCacheData: { /// 忽略本地缓存，重新发送网络请求
            // 直接发送网络请求
            break;
        }
        case iKYCahceRequestCachePolicyReturnCacheDataOrLoad: { /// 有缓存就直接用缓存，没有缓存再请求
            if(object){
                success(object);
                return nil;
            }
            break;
        }
        case iKYCahceRequestCachePolicyCacheDataDontLoad: { /// 有缓存则先用缓存，没有缓存就不发送请求，当错误处理
            if (object) {
                success(object);
            }
            return nil;
            break;
        }
    }
    return [self postWithUrlString:urlString
                            params:params
                     cacheInstance:cache
                           success:success
                              fail:fail];
}

#pragma mark - DownLoad
+ (iKYRequestDownLoadDataTask *)downloadWithUrlString:(NSString *)urlString
                                   saveToPath:(NSURL *)saveToPath
                                     progress:(iKYDownloadProgress)progressBlock
                                      success:(iKYResponseSuccess)success
                                      failure:(iKYResponseFail)failure{
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    iKYHTTPRequestManager *manager = [self manager];
    NSURLSessionDownloadTask *downloadtask = [manager downloadTaskWithRequest:urlRequest
                                                                     progress:^(NSProgress * _Nonnull downloadProgress) {
        progressBlock(downloadProgress);

    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath,
                                    NSURLResponse * _Nonnull response) {
        // 拼接下载文件名
       return [saveToPath URLByAppendingPathComponent:[response suggestedFilename]];
    } completionHandler:^(NSURLResponse * _Nonnull response,
                          NSURL * _Nullable filePath,
                          NSError * _Nullable error) {
        if (error) {
            if (failure) {
                failure(error);
            }
        } else {
            if (success) {
                success(saveToPath);
            }
        }
    }];

    [downloadtask resume];
    
    return downloadtask;
}

#pragma mark - 图片上传接口
+ (iKYRequestUpLoadDataTask *)uploadWithImage:(UIImage *)image
                              urlString:(NSString *)urlString
                               fileName:(NSString *)fileName
                                   name:(NSString *)name
                             parameters:(NSDictionary *)parameters
                               progress:(iKYUpLoadProgress)progressBlock
                                success:(iKYResponseSuccess)success
                                   fail:(iKYResponseFail)fail{
    if ([self shouldEncode]) {
        urlString = [self encodeUrlString:urlString];
    }

    iKYHTTPRequestManager *manager = [self manager];

    NSURLSessionDataTask *task = [manager POST:urlString parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        /// -----------------------------在这里更改图片的格式------------------------------------
        NSData *imageData = UIImageJPEGRepresentation(image, 1);
        NSString *imageFileName = fileName;
        if (fileName == nil || ![fileName isKindOfClass:[NSString class]] || fileName.length == 0) {
            NSDateFormatter *formatter = [NSDateFormatter new];
            formatter.dateFormat = @"yyyyMMddHHmmss";
            NSString *str = [formatter stringFromDate:[NSDate date]];
            imageFileName = [str stringByAppendingString:@".jpg"];
        }

        // 二进制流格式上传图片
        [formData appendPartWithFileData:imageData name:name fileName:imageFileName mimeType:@"image/jpeg"];

    } progress:^(NSProgress * _Nonnull uploadProgress) {
        progressBlock(uploadProgress);
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self successResponse:responseObject callBack:success];

        if ([self isDebug]) {
            [self logWithSuccessResponse:responseObject urlString:urlString params:parameters];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (fail) {
            fail(error);
        }

        if ([self isDebug]) {
            [self logWithFailError:error urlString:urlString params:parameters];
        }
    }];
    [task resume];
    
    return task;
}

+ (iKYRequestUpLoadDataTask *)uploadWithImage:(UIImage *)image
                              urlString:(NSString *)urlString
                               fileName:(NSString *)fileName
                                   name:(NSString *)name
                                success:(iKYResponseSuccess)success
                                   fail:(iKYResponseFail)fail{
    return [self uploadWithImage:image
                       urlString:urlString
                        fileName:fileName
                            name:name
                      parameters:nil
                        progress:nil
                         success:success
                            fail:fail];
}

+ (iKYRequestUpLoadDataTask *)uploadWithImage:(UIImage *)image
                              urlString:(NSString *)urlString
                               fileName:(NSString *)fileName
                                   name:(NSString *)name
                             parameters:(NSDictionary *)parameters
                                success:(iKYResponseSuccess)success
                                   fail:(iKYResponseFail)fail{
    return [self uploadWithImage:image
                       urlString:urlString
                        fileName:fileName
                            name:name
                      parameters:parameters
                        progress:nil
                         success:success
                            fail:fail];
}

+ (iKYRequestUpLoadDataTask *)uploadWithImage:(UIImage *)image
                              urlString:(NSString *)urlString
                               fileName:(NSString *)fileName
                                   name:(NSString *)name
                               progress:(iKYUpLoadProgress)progressBlock
                                success:(iKYResponseSuccess)success
                                   fail:(iKYResponseFail)fail{
    return [self uploadWithImage:image
                       urlString:urlString
                        fileName:fileName
                            name:name
                      parameters:nil
                        progress:progressBlock
                         success:success
                            fail:fail];
}
#pragma mark - 私有方法
+ (iKYHTTPRequestManager *) manager{
    // 开启转圈圈
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    
    // 初始化
    iKYHTTPRequestManager *manager = nil;
    
    if ([self baseUrl] != nil) { // 如果有baseUrl 设置为Manager的默认URL
        manager = [[iKYHTTPRequestManager alloc] initWithBaseURL:[NSURL URLWithString:[self baseUrl]]];
    }else{ // 没有baseUrl 初始化Manager
        manager = [iKYHTTPRequestManager manager];
    }
    
    // 设置请求内容解析
    switch (iRequestType) {
        case iKYRequestTypeJSON: {
            manager.requestSerializer = [AFJSONRequestSerializer serializer];
            [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
            [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
            break;
        }
        case iKYRequestTypePlainText: {
            manager.requestSerializer = [AFHTTPRequestSerializer serializer];
            break;
        }
    }
    
    // 设置返回内容格式解析
    switch (iResponseType) {
        case iKYResponseTypeJSON: {
            manager.responseSerializer = [AFJSONResponseSerializer serializer];
            break;
        }
        case iKYResponseTypeXML: {
            manager.responseSerializer = [AFXMLParserResponseSerializer serializer];
            break;
        }
        case iKYResponseTypeData: {
            manager.responseSerializer = [AFHTTPResponseSerializer serializer];
            break;
        }
    }
    
    manager.requestSerializer.stringEncoding = NSUTF8StringEncoding;
    
    for (NSString *key in iHttpHeaders.allKeys) {
        if (iHttpHeaders[key] != nil) {
            [manager.requestSerializer setValue:iHttpHeaders[key] forKey:key];
        }
    }
    
    // 设置解析内容的格式
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithArray:@[@"application/json",
                       @"text/html",
                       @"text/json",
                       @"text/plain",
                       @"text/javascript",
                       @"text/xml",
                       @"image/*"]];
    // 设置允许的最大并发数量为3
    manager.operationQueue.maxConcurrentOperationCount = 3;
    return manager;
}

+ (NSString *)encodeUrlString:(NSString *)urlString{
    return [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

+ (void)logWithSuccessResponse:(id)response urlString:(NSString *)urlString params:(NSDictionary *)params {
    iKYAppLog(@"🍏\n Url: %@ \n params:%@ \n response:%@\n🍏",
              urlString,
              params,
              [self tryToParseData:response]);
}

+ (void)logWithFailError:(NSError *)error urlString:(NSString *)urlString params:(NSDictionary *)params {
    iKYAppLog(@"🍎\n Url: %@ \n params:%@ \n errorInfo:%@\n🍎",
              urlString,
              params,
              [error localizedDescription]);
}

+ (id)tryToParseData:(id)responseData {
    if ([responseData isKindOfClass:[NSData class]]) {
        // 尝试解析成JSON
        if (responseData == nil) {
            return responseData;
        } else{
            NSError *error = nil;
            NSDictionary *response = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:&error];
            
            if (error != nil) {
                return responseData;
            } else{
                return response;
            }
        }
    } else {
        return responseData;
    }
}

+ (void)successResponse:(id)responseData callBack:(iKYResponseSuccess) success{
    if (success) {
        success([self tryToParseData:responseData]);
    }
}



+ (NSString *)cacheDataUrlStringToCacheKey:(NSString *)urlString{
    NSRange range = [urlString rangeOfString:@"?"];
    if (range.length) {
        return [urlString substringToIndex:range.location];
    }else{
        return urlString;
    }
}
@end
