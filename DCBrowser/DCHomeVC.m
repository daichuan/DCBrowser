//
//  DCHomeVC.m
//  DCBrowser
//
//  Created by cheyr on 2018/1/31.
//  Copyright © 2018年 cheyr. All rights reserved.
//

#import "DCHomeVC.h"
#import <WebKit/WebKit.h>
#import "DCSearchBar.h"
#import <UIView+SDAutoLayout.h>

//屏幕大小判断
#define is4inches ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 1136), [[UIScreen mainScreen] currentMode].size) : NO)

#define is4_7inches ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(750, 1334), [[UIScreen mainScreen] currentMode].size) : NO)

#define is5_5inches ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1242, 2208), [[UIScreen mainScreen] currentMode].size) : NO)

#define is5_8inches ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) : NO)
#define DCScreenW [UIScreen mainScreen].bounds.size.width
#define DCScreenH [UIScreen mainScreen].bounds.size.height

#define RGB(r, g, b) [UIColor colorWithRed:((r) / 255.0) green:((g) / 255.0) blue:((b) / 255.0) alpha:1.0]

#define DCStatusBarHeight (is5_8inches ? 44 : 20)

#define DCNavBarHeight 44

#define DCTabBarHeight 49

#define DCHomeIndicator (is5_8inches ? 34 : 0)

typedef enum: NSUInteger{
    WebViewBackground,
    WebViewActive
} WebViewState;

@interface DCHomeVC ()<WKNavigationDelegate,UIScrollViewDelegate,UISearchBarDelegate>
{
    CGFloat webViewW;
    CGFloat webViewH;
}
@property (nonatomic,assign) WebViewState state;
@property (nonatomic,strong) UIScrollView *scrollView;
@property (nonatomic,strong) NSMutableArray *webViewArr;
@property (nonatomic,strong) WKWebView *currentWebView;
@property (nonatomic,strong) UIProgressView *progressView;
@property (nonatomic,strong) UIBarButtonItem *backItem;
@property (nonatomic,strong) UIBarButtonItem *goItem;
@property (nonatomic,strong) UIBarButtonItem *refreshItem;
@property (nonatomic,strong) UIBarButtonItem *addWebviewItem;
@property (nonatomic,strong) UIBarButtonItem *booksItem;
@property (nonatomic,strong) UIBarButtonItem *doneItem;

@end

@implementation DCHomeVC

#pragma mark  - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    //添加view
    [self.view addSubview:self.scrollView];
    [self.view addSubview:self.progressView];

    [self AddWebView];
    
    self.state = WebViewActive;

    //设置导航栏
    [self p_DCSetUpNav];
    [self p_DCSetUpBottomBar];
    //加载URL
    [self p_DCLoadWebWithString:@"https://www.bilibili.com"];
}

-(void)viewDidLayoutSubviews
{
    if(self.navigationController.navigationBarHidden)
    {
        self.scrollView.frame = CGRectMake(0, 0, webViewW, DCScreenH);
    }else
    {
        self.scrollView.frame = CGRectMake(0, 0, webViewW, webViewH);
    }

    self.progressView.frame = CGRectMake(0, 0, webViewW, 2);
    self.navigationController.toolbar.frame = CGRectMake(0, webViewH, DCScreenW, DCTabBarHeight);
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dealloc
{
    //移除监听
    [self.currentWebView removeObserver:self forKeyPath:@"estimatedProgress"];
}
//kvo监听
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"estimatedProgress"]) {
        self.progressView.progress = self.currentWebView.estimatedProgress;
        if (self.progressView.progress == 1) {
            self.progressView.hidden = YES;
        }
    }else{
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark  - event
-(void)goBack
{
    if ([self.currentWebView canGoBack])
    {
        [self.currentWebView goBack];
    }
}
-(void)goForward
{
    if ([self.currentWebView canGoForward]) {
        [self.currentWebView goForward];
    }
}
-(void)refreshWeb
{
    if (self.currentWebView.loading) { // 是否正在刷新页面
        [self.currentWebView stopLoading]; // 停止刷新
    }
    // 刷新页面
    [self.currentWebView reload];
}
-(void)showWebViewList
{
    if(self.state == WebViewBackground) return;
    self.state = WebViewBackground;
    
    [self p_DCSetUpBottomBar];
    self.scrollView.scrollEnabled = YES;
    self.currentWebView.scrollView.userInteractionEnabled = NO;
    self.currentWebView.layer.cornerRadius = 20;
    self.currentWebView.layer.masksToBounds = YES;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.navigationController.navigationBarHidden = YES;
        self.currentWebView.transform = CGAffineTransformMakeScale(0.8, 0.8);
        self.currentWebView.transform = CGAffineTransformTranslate(self.currentWebView.transform, 0, 22);

    }completion:^(BOOL finished) {
        
    } ];
}
//添加完取消scrollview的滑动
-(void)AddWebView
{
    WKWebView * webView = [[WKWebView alloc]init];
    webView.backgroundColor = [UIColor whiteColor];
    webViewW = [UIScreen mainScreen].bounds.size.width;
    webViewH = DCScreenH - DCStatusBarHeight - DCNavBarHeight - DCHomeIndicator - DCTabBarHeight;
    webView.frame = CGRectMake(self.webViewArr.count * webViewW, 0, webViewW,webViewH);
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapAction:)];
    UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeAction:)];
    swipe.direction = UISwipeGestureRecognizerDirectionUp;
    [webView addGestureRecognizer:tap];
    [webView addGestureRecognizer:swipe];
    
    webView.allowsBackForwardNavigationGestures = YES;
    webView.navigationDelegate = self;
    webView.scrollView.delegate = self;
    [self.scrollView addSubview:webView];
    
    //添加到数组中
    [self.webViewArr addObject:webView];
    
    //改变contentsize的大小和offset的位置
    self.scrollView.contentSize = CGSizeMake(webViewW * self.webViewArr.count, 0);
    self.scrollView.contentOffset = CGPointMake((self.webViewArr.count - 1) * webViewW, 0);

    self.currentWebView = webView;
    [self p_DCLoadWebWithString:@"https://baidu.com"];
    [self done];
    
}
-(void)swipeAction:(UISwipeGestureRecognizer *)swipe
{
    if(self.state == WebViewActive) return;
    //移除这个webview
    [UIView animateWithDuration:0.3 animations:^{
        swipe.view.transform = CGAffineTransformTranslate(swipe.view.transform, 0, -DCScreenH);
    } completion:^(BOOL finished) {
        [swipe.view removeFromSuperview];
        [self.webViewArr removeObject:swipe.view];
        if(self.webViewArr.count == 0)
        {
            [self AddWebView];
        }else
        {
            //从数组中移除
//            [self.webViewArr removeObject:swipe.view];
            
            //如果移除的是currentWebview，则把数组中最后一个赋值给currentview
            if(self.currentWebView == swipe.view)
            {
                self.currentWebView = self.webViewArr.lastObject;
            }
            //最后将webview从父视图中移除
//            [swipe.view removeFromSuperview];
            
            //重新排列
            [UIView animateWithDuration:0.2 animations:^{
                for(int i=0; i<self.webViewArr.count; i++)
                {
                    WKWebView *webView = self.webViewArr[i];
                    webView.transform = CGAffineTransformIdentity;//先还原，再设置frame，再缩小上移
                    webView.frame = CGRectMake(i*webViewW, 0, webViewW, webViewH);
                    webView.transform = CGAffineTransformMakeScale(0.8, 0.8);
                    webView.transform = CGAffineTransformTranslate(webView.transform, 0, 22);
                }
            } completion:^(BOOL finished) {
                self.scrollView.contentSize = CGSizeMake(self.webViewArr.count * webViewW, 0);
            }];
        }
        
    }];
}

-(void)tapAction:(UITapGestureRecognizer *)tap
{
    if(self.state == WebViewActive) return;
    self.currentWebView = (WKWebView *)tap.view;
    self.currentWebView.scrollView.userInteractionEnabled = YES;

    [UIView animateWithDuration:0.3 animations:^{
        tap.view.layer.cornerRadius = 0;
        self.navigationController.navigationBarHidden = NO;
        tap.view.transform = CGAffineTransformIdentity;
        self.scrollView.contentOffset = CGPointMake(self.currentWebView.left, 0);

    }];
    self.state = WebViewActive;
    self.scrollView.scrollEnabled = NO;
    [self p_DCSetUpBottomBar];
}
-(void)done
{
    if(self.state == WebViewActive) return;
    self.currentWebView.scrollView.userInteractionEnabled = YES;
    self.currentWebView.layer.cornerRadius = 0;

    [UIView animateWithDuration:0.3 animations:^{
        self.navigationController.navigationBarHidden = NO;
        self.currentWebView.transform = CGAffineTransformIdentity;
        self.scrollView.contentOffset = CGPointMake(self.currentWebView.left, 0);

    }];
    self.state = WebViewActive;
    self.scrollView.scrollEnabled = NO;
    [self p_DCSetUpBottomBar];
    

}
#pragma mark  - delegate
-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    [self p_checkInputString:searchBar.text];
}

#pragma mark - WKNavigationDelegate 页面跳转
// 在发送请求之前，决定是否跳转
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    
    decisionHandler(WKNavigationActionPolicyAllow);
}

// 身份验证
- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *__nullable credential))completionHandler
{
    // 不要证书验证
    completionHandler(NSURLSessionAuthChallengeUseCredential, nil);
}

// 在收到响应后，决定是否跳转
- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler
{

    decisionHandler(WKNavigationResponsePolicyAllow);

}

// 接收到服务器跳转请求之后调用
- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(null_unspecified WKNavigation *)navigation
{
    
}

// WKNavigation导航错误
- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error
{
    
}

// WKWebView终止
- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView
{
}

#pragma mark - WKNavigationDelegate 页面加载
// 页面开始加载时调用
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation {
    NSLog(@"%s",__FUNCTION__);
    self.progressView.hidden = NO;
    [self.progressView bringSubviewToFront:self.view];
}

// 当内容开始返回时调用
- (void)webView:(WKWebView *)webView didCommitNavigation:(null_unspecified WKNavigation *)navigation {
    NSLog(@"%s",__FUNCTION__);
}

// 页面加载完成之后调用
- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
        self.progressView.hidden = YES;
        
        self.goItem.enabled = self.currentWebView.canGoForward;
        self.backItem.enabled = self.currentWebView.canGoBack;
}

// 页面加载失败时调用
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    self.progressView.hidden = YES;
    NSLog(@"%@",error);
    self.goItem.enabled = self.currentWebView.canGoForward;
    self.backItem.enabled = self.currentWebView.canGoBack;
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
//    NSLog(@"contentOffset Y = %f",scrollView.contentOffset.y);
}
//实现scrollView代理
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset{
    //竖直滑动时 判断是上滑还是下滑
    if(velocity.y>0){
        //上滑
        NSLog(@"上滑");
    }else{
        //下滑
        NSLog(@"下滑");
    }
    
}

#pragma mark  - notification

#pragma mark  - private

-(void)p_DCSetUpNav
{
    self.navigationController.navigationBar.translucent = NO;
    UISearchBar *searchBar = [[UISearchBar alloc]initWithFrame:CGRectMake(20, 5, DCScreenW - 40, 34)];
    searchBar.placeholder = @"搜索或输入网站名称";
    searchBar.delegate = self;
    searchBar.layer.cornerRadius = 5;
    self.navigationItem.titleView = searchBar;
    
    [self.navigationController setToolbarHidden:NO animated:YES];
    [self.navigationController.toolbar setBarStyle:UIBarStyleDefault];
}
-(void)p_DCSetUpBottomBar
{
    UIBarButtonItem *spaceItem = [[UIBarButtonItem alloc]
                                  initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                  target:nil action:nil];
    if(self.state == WebViewActive)
    {
        self.toolbarItems = @[self.backItem,spaceItem,self.goItem,spaceItem,self.refreshItem,spaceItem,self.booksItem];
    }else
    {
        self.toolbarItems = @[spaceItem,self.addWebviewItem,spaceItem,self.doneItem];
    }
        
}
-(void)p_DCLoadWebWithString:(NSString *)string
{
    NSURLRequest *request = [[NSURLRequest alloc]initWithURL:[NSURL URLWithString:string]];
    [self.currentWebView loadRequest:request];
}
-(void)p_checkInputString:(NSString *)string
{
    NSMutableString * urlStr = [[NSMutableString alloc]init];
    //检测是不是网址
    NSRange url = [string rangeOfString:@"www."];
    if(url.length > 0)
    {
        [urlStr appendString:string];
    }else
    {
        //适配 iOS9 字符串UTF8编码
        if (NSFoundationVersionNumber >= NSFoundationVersionNumber_iOS_9_0) {
            string = [string stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        }else {
            string = [string stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        }
        [urlStr appendString:@"https://www.baidu.com/s?wd="];
        [urlStr appendString:string];
    }
    
    [self p_DCLoadWebWithString:urlStr];
    return;
    
}
#pragma mark  - public

#pragma mark  - setter or getter
-(NSMutableArray *)webViewArr
{
    if(_webViewArr == nil)
    {
        _webViewArr = [[NSMutableArray alloc]init];
    }
    return _webViewArr;
}
-(UIProgressView *)progressView
{
    if(_progressView == nil)
    {
        // 0 183 241
        _progressView = [[UIProgressView alloc]init];
        _progressView.progressTintColor = RGB(0, 183, 241);
        _progressView.trackTintColor = [UIColor clearColor];
        _progressView.hidden = YES;
    }
    return _progressView;
}
-(UIBarButtonItem *)backItem
{
    if(_backItem == nil)
    {
        _backItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRewind target:self action:@selector(goBack)];
        _backItem.enabled = NO;
    }
    return _backItem;
}
-(UIBarButtonItem *)goItem
{
    if(_goItem == nil)
    {
        _goItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFastForward target:self action:@selector(goForward)];
        _goItem.enabled = NO;
    }
    return _goItem;
}
-(UIBarButtonItem *)refreshItem
{
    if(_refreshItem == nil)
    {
        _refreshItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshWeb)];
    }
    return _refreshItem;
}
-(UIBarButtonItem *)addWebviewItem
{
    if(_addWebviewItem == nil)
    {
        _addWebviewItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(AddWebView)];
    }
    return _addWebviewItem;
}
-(UIBarButtonItem *)booksItem
{
    if(_booksItem == nil)
    {
        _booksItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks target:self action:@selector(showWebViewList)];
    }
    return _booksItem;
}
-(UIBarButtonItem *)doneItem
{
    if(_doneItem == nil)
    {
        
        _doneItem = [[UIBarButtonItem alloc]initWithTitle:@"完成" style:UIBarButtonItemStyleDone target:self action:@selector(done)];
    }
    return _doneItem;
}
-(UIScrollView *)scrollView
{
    if(_scrollView == nil)
    {
        _scrollView = [[UIScrollView  alloc]init];
        _scrollView.backgroundColor = [UIColor blackColor];
        _scrollView.scrollEnabled = NO;
    }
    return _scrollView;
}
-(void)setCurrentWebView:(WKWebView *)currentWebView
{
    //移除监听
    [_currentWebView removeObserver:self forKeyPath:@"estimatedProgress"];

    //赋值
    _currentWebView = currentWebView;
    
    //给新的webview添加监听
    [self.currentWebView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];

}
-(void)setState:(WebViewState)state
{
    _state = state;
    if(state == WebViewBackground)
    {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    }else
    {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    }
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
