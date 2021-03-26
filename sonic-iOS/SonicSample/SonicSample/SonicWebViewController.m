//
//  SonicWebViewController.m
//  SonicSample
//
//  Tencent is pleased to support the open source community by making VasSonic available.
//  Copyright (C) 2017 THL A29 Limited, a Tencent company. All rights reserved.
//  Licensed under the BSD 3-Clause License (the "License"); you may not use this file except
//  in compliance with the License. You may obtain a copy of the License at
//
//  https://opensource.org/licenses/BSD-3-Clause
//
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.
//
//  Copyright © 2017年 Tencent. All rights reserved.
//

#import "SonicWebViewController.h"
#import "WebViewJavascriptBridge.h"
#import "WebViewPoolManager.h"

@interface SonicWebViewController ()


@property (nonatomic,assign)BOOL isStandSonic;
@property (nonatomic,strong) WebViewJavascriptBridge* bridge;

@end

@implementation SonicWebViewController

- (instancetype)initWithUrl:(NSString *)aUrl useSonicMode:(BOOL)isSonic unStrictMode:(BOOL)state
{
    if (self = [super init]) {
        
        self.url = aUrl;
        
        self.clickTime = (long long)([[NSDate date]timeIntervalSince1970]*1000);
        
        if (isSonic) {
            if (state) {
                SonicSessionConfiguration *configuration = [SonicSessionConfiguration new];
                NSString *linkValue = @"http://imgcache.gtimg.cn/club/platform/lib/zepto/zepto-1.1.3.js?rand=0.42398321648052617;http://imgcache.gtimg.cn/club/platform/lib/sonic/sonic-3.js?rand=0.42398321648052617;http://open.mobile.qq.com/sdk/qqapi.js?_bid=152;http://imgcache.gtimg.cn/club/platform/lib/seajs/sea-with-plugin-2.2.1.js?_bid=250&max_age=2592000";
                configuration.customResponseHeaders = @{
                                                        SonicHeaderKeyCacheOffline:SonicHeaderValueCacheOfflineStore,
                                                        SonicHeaderKeyLink:linkValue
                                                        };
                configuration.enableLocalServer = NO;
                configuration.supportCacheControl = YES;
                [[SonicEngine sharedEngine] createSessionWithUrl:self.url withWebDelegate:self withConfiguration:configuration];
            }else{
                self.isStandSonic = YES;
                SonicSessionConfiguration *configuration = [SonicSessionConfiguration new];
                configuration.supportCacheControl = YES;
                [[SonicEngine sharedEngine] createSessionWithUrl:self.url withWebDelegate:self withConfiguration:configuration];
            }
        }
    }
    return self;
}

- (void)dealloc
{
    [self.webView removeFromSuperview];
    [[WebViewPoolManager sharedManager] destoryWebView:self.webView];
    [self.bridge removeHandler:@"getPerformance"];
    [self.bridge setWebViewDelegate:nil];
    self.bridge = nil;
    [[SonicEngine sharedEngine] removeSessionWithWebDelegate:self];
}

- (void)loadView
{
    [super loadView];
    
    WKUserContentController *wkCont = [[WKUserContentController alloc] init];
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.userContentController = wkCont;
    
    WKWebView *webView = [[WebViewPoolManager sharedManager] getWebViewInstance];
    webView.frame = self.view.bounds;
//    self.webView = [[WKWebView alloc]initWithFrame:self.view.bounds configuration:config];
    webView.navigationDelegate = self;
    webView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;
    self.view = webView;
    self.webView = webView;
    
    __weak typeof(self) weakSelf = self;

    [WebViewJavascriptBridge enableLogging];
    _bridge = [WebViewJavascriptBridge bridgeForWebView:weakSelf.webView];
    [_bridge setWebViewDelegate:self];
    
    [_bridge registerHandler:@"getPerformance" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"testObjcCallback called: %@", data);
        NSString *response = [weakSelf getPerformance];
        responseCallback(response);
    }];
    
    if (self.isStandSonic) {
        UIBarButtonItem *reloadItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(updateAction)];
        self.navigationItem.rightBarButtonItem = reloadItem;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.url]];
    
    SonicSession* session = [[SonicEngine sharedEngine] sessionWithWebDelegate:self];
    if (session) {
        [self.webView loadRequest:[SonicUtil sonicWebRequestWithSession:session withOrigin:request]];
    }else{
        [self.webView loadRequest:request];
    }

}


- (NSString *)getPerformance
{
    NSDictionary *result = @{
                             @"clickTime":@(self.clickTime),
                             };
    NSData *json = [NSJSONSerialization dataWithJSONObject:result options:NSJSONWritingPrettyPrinted error:nil];
    NSString *jsonStr = [[NSString alloc]initWithData:json encoding:NSUTF8StringEncoding];
    
    return jsonStr;
}


- (void)updateAction
{
    [[SonicEngine sharedEngine] reloadSessionWithWebDelegate:self completion:^(NSDictionary *result) {
        
    }];
}

#pragma mark - UIWebViewDelegate

//- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
//{
//    self.jscontext = [self.webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
//    self.jscontext[@"sonic"] = self.sonicContext;
//
//    return YES;
//}
//
//- (void)webViewDidFinishLoad:(UIWebView *)webView
//{
//    self.jscontext = [self.webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
//    self.jscontext[@"sonic"] = self.sonicContext;
//}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation{

}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation{
    long long endTime = (long long)([[NSDate date] timeIntervalSince1970] * 1000);
    long long pageTime = endTime - self.clickTime;
    NSString *string = [NSString stringWithFormat:@"window.document.getElementById('pageTime3').innerHTML = %lld+'ms'",pageTime];
    [self.webView evaluateJavaScript:string completionHandler:nil];

}

#pragma mark - Sonic Session Delegate

- (void)sessionWillRequest:(SonicSession *)session
{
    //可以在请求发起前同步Cookie等信息
}

- (void)session:(SonicSession *)session requireWebViewReload:(NSURLRequest *)request
{
    [self.webView loadRequest:request];
}

@end
