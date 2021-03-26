//
//  WebViewPool.m
//  SonicSample
//
//  Created by jiahan on 2021/3/25.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "WebViewPoolManager.h"

@interface WebViewPoolManager()

@property (nonatomic,strong) NSMutableArray *webViewPool;

@end

@implementation WebViewPoolManager

+ (WebViewPoolManager *)sharedManager
{
    static WebViewPoolManager *_manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manager = [[self alloc] init];
    });
    return _manager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.webViewPool = [NSMutableArray arrayWithCapacity:webViewCount];
        [self initWebViewPool];
    }
    return self;
}

- (void)initWebViewPool{
    for (int i = 0; i < webViewCount; i++) {
        WKWebView *webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:[self generateDefaultConfiguration]];
        [self.webViewPool addObject:webView];
    }
}

- (WKWebViewConfiguration *)generateDefaultConfiguration{
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    WKUserContentController *wkCont = [[WKUserContentController alloc] init];
    config.userContentController = wkCont;
    return config;
}

- (void)returnToPool{
    WKWebView *webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:[self generateDefaultConfiguration]];
    [self.webViewPool addObject:webView];
}

- (WKWebView *)getFromPoll{
    WKWebView *wkWebView = [self.webViewPool objectAtIndex:0];
    return wkWebView;
}

- (WKWebView *)getWebViewInstance{
    if (self.webViewPool.count > 0) {
        WKWebView *wkWebView = [self getFromPoll];
        return wkWebView;
    }else{
        return [[WKWebView alloc] init];
    }
}

- (void)destoryWebView:(WKWebView *)webView{
    if ([self.webViewPool containsObject:webView]) {
        [self.webViewPool removeObject:webView];
    }
    [self returnToPool];
}

@end
