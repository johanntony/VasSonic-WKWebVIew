//
//  WebViewPoolManager.h
//  SonicSample
//
//  Created by jiahan on 2021/3/25.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

#define webViewCount 5

NS_ASSUME_NONNULL_BEGIN

@interface WebViewPoolManager : NSObject

@property (nonatomic,strong,readonly) NSMutableArray *webViewPool;

+ (WebViewPoolManager *)sharedManager;

- (WKWebView *)getWebViewInstance;

- (void)destoryWebView:(WKWebView *)webView;

@end

NS_ASSUME_NONNULL_END
