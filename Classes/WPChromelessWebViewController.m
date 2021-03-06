//
//  WPChromelessWebViewController.m
//
//  Created by Eric Johnson on 5/24/12.
//

#import "WPChromelessWebViewController.h"
#import "WordPressAppDelegate.h"
#import "WPWebViewController.h"
#import "PanelNavigationConstants.h"

@interface WPChromelessWebViewController ()
@property (nonatomic, retain) WPWebView *webView;
@end

@implementation WPChromelessWebViewController

@synthesize webView, path=_path;

#pragma mark -
#pragma mark Lifecycle Methods

- (void)dealloc {
    self.path = nil;
    webView.delegate = nil;
    [webView release];
    
    [super dealloc];
}

- (void)loadView {
    [super loadView];
    
    CGRect frame = self.view.bounds;
    self.webView = [[[WPWebView alloc] initWithFrame:frame] autorelease];
    webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    webView.delegate = self;
    [self.view addSubview:webView];
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if (self.path != nil) {
        [webView loadPath:self.path];
    }
}


- (void)viewDidUnload {
    [super viewDidUnload];
    
    webView.delegate = nil;
    self.webView = nil;
}


#pragma mark -
#pragma mark Instance Methods

- (void)setPath:(NSString *)path {
    if (![_path isEqualToString:path]) {
        [_path release];
        _path = [path retain];
        NSLog(@"Path is: %@", self.path);
        if ([self isViewLoaded]) {
            [webView loadPath:self.path];
        }
        
    }
}

- (void)loadPath:(NSString *)aPath {
    self.path = aPath;
}


- (NSURL *)currentURL {
    return [self.webView currentURL];
}


- (BOOL)expectsWidePanel {
    return YES;
}


#pragma mark -
#pragma mark WPWebView Delegate Methods

- (BOOL)wpWebView:(WPWebView *)wpWebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    // If a link to a new URL is clicked we want to open in a new window.
    // This method is also triggered when loading html from a string so we need to handle that case as well.
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {

        // Check the panelNavigationController's stack to see if the previous item was a chromeless webview controller.
        // If so check to see if its displaying the same url that was just clicked. 
        // If so just pop ourself off the stack.
        UIViewController *prevController = nil;
        NSArray *controllers = [self.panelNavigationController viewControllers];
        NSInteger len = [controllers count]; 
        if(len > 0) {
            for (NSInteger i = len; i > 0; i--) {
                NSInteger idx = i-1;
                UIViewController *controller = [controllers objectAtIndex:idx];
                if ([controller isEqual:self]) {
                    if (idx > 0) {
                        prevController = [controllers objectAtIndex:(idx-1)];
                        break;
                    }
                }
            }
        }
        
        if (prevController && [prevController isKindOfClass:[self class]]) {
            WPChromelessWebViewController *controller = (WPChromelessWebViewController *)prevController;

            // Check the url parts individually. Comparing absoluteStrings can yield an incorrect result.
            NSURL *currURL = [controller currentURL];
            NSURL *reqURL = [request URL];
            if ([currURL.host isEqualToString:reqURL.host]) {
                if([currURL.path isEqualToString:reqURL.path]) {
                    if ([currURL.query isEqualToString:reqURL.query]) {
                        // if the detail controller is ourself disregard the click so we don't spam a series of the same page.
                        [self.panelNavigationController popToViewController:prevController animated:YES];
                        return NO;
                    }
                }
            }
        }       

        // If the url points off-site we want to handle it differently.
        NSString *host = request.URL.host;
        if ([host rangeOfString:@"wordpress.com"].location == NSNotFound) {
            WPWebViewController *controller;
            if (IS_IPAD) {
                controller = [[[WPWebViewController alloc] initWithNibName:@"WPWebViewController-iPad" bundle:nil] autorelease];
            }
            else {
                controller = [[[WPWebViewController alloc] initWithNibName:@"WPWebViewController" bundle:nil] autorelease];
            }
            [controller setUrl:request.URL];
            [self.panelNavigationController pushViewController:controller animated:YES];
            return NO;
        }
        
        WPChromelessWebViewController *controller = [[WPChromelessWebViewController alloc] init];
        [controller loadPath:request.URL.absoluteString];        
        [self.panelNavigationController pushViewController:controller fromViewController:self animated:YES];
        [controller release];
        
        return NO;
    }
    
    return YES;
}


- (void)webViewDidFinishLoad:(WPWebView *)wpWebView {
    NSString *title = [wpWebView stringByEvaluatingJavaScriptFromString:@"document.title;"];
    if (title && [title length] > 0) {
        self.title = title;
    }
}

@end
