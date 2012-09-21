//
//  RichTextEditorWebView.m
//  WordPress
//

#import "JSONKit.h"
#import "RichTextEditorWebView.h"

@interface RichTextEditorWebView () {
    NSString *_text;
    BOOL _ready;
}

@property (nonatomic, retain) UIWebView *webView;

- (void)hideWebViewBackgrounds:(UIWebView *)webView;
- (void)initializeEditor;
@end

@implementation RichTextEditorWebView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self initializeEditor];
    }
    return self;
}

- (void)awakeFromNib {
    [self initializeEditor];
}

- (void)initializeEditor {
    _ready = false;
    _text = [[NSString alloc] initWithString:@""];
    UIWebView *webView = [[UIWebView alloc] initWithFrame:self.bounds];
    webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.webView = webView;
    [webView release];
    self.webView.backgroundColor = self.backgroundColor;
    [self addSubview:self.webView];
    [self hideWebViewBackgrounds:webView];
    self.webView.delegate = self;
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"richtext" ofType:@"html"]isDirectory:NO]]];
}

#pragma mark - Memory Management

- (void)dealloc {
    self.text = nil;
    self.webView.delegate = nil;
    self.webView = nil;
    [super dealloc];
}

#pragma mark - Editing API

- (void)setText:(NSString *)text {
    if (![_text isEqualToString:text]) {
        [_text release];
        _text = [text retain];
    }
    if (self.isReady) {
        [self insertTextContent:_text];
    }
}

- (NSString*)text {
    
    if(self.isReady){
        // TODO: necessary escaping should happen here
        return [self.webView stringByEvaluatingJavaScriptFromString:@"getContent()"];
    } else {
        return _text;
    }
}

- (void)insertTextContent:(NSString *)text {
    if ([text isEqualToString:@""]) {
        [self.webView stringByEvaluatingJavaScriptFromString:@"clearContent();"];
    } else {
        NSLog(@"Setting: %@", [text JSONString]);
        [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"setContent(%@)", [text JSONString]]];
    }

}

#pragma mark - UIWebView manipulations

- (void)hideWebViewBackgrounds:(UIWebView *)webView
{
    UIScrollView *scrollView;
    if ([webView respondsToSelector:@selector(scrollView:)]) {
        scrollView = webView.scrollView;
    } else {
        for (UIView* view in webView.subviews) {
            if ([view isKindOfClass:[UIScrollView class]]) {
                scrollView = (UIScrollView*)view;
            }
        }
    }
    for (UIView *view in scrollView.subviews) {
        if ([view isKindOfClass:[UIImageView class]]) {
            view.alpha = 0.0;
            view.hidden = YES;
        }
    }
}

#pragma mark - Imitate UIWebView temporarily

- (NSString *)stringByEvaluatingJavaScriptFromString:(NSString *)string {
    NSLog(@"Deprecated use of stringByEvaluatingJavascriptString! %@", string);
    return [self.webView stringByEvaluatingJavaScriptFromString:string];
}


#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if (navigationType != UIWebViewNavigationTypeLinkClicked)
        return YES;
    
    return NO;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    self.ready = YES;
    [self insertTextContent:_text];
    if([self.delegate respondsToSelector:@selector(richTextEditorIsReady:)]){
        [self.delegate richTextEditorIsReady:self];
    }
//    [richEditWebView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"setPlaceholder('%@')", NSLocalizedString(@"Tap here to edit.", @"Label to tell user to tap the content in the Edit Post view")]];
//    if ((self.apost.mt_text_more != nil) && ([self.apost.mt_text_more length] > 0)) {
//        [richEditWebView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"setContent('%@');", [NSString stringWithFormat:@"%@\n<!--more-->\n%@", self.apost.content, self.apost.mt_text_more]]];
//    } else {
//        if (self.apost.content != nil) {
//            [richEditWebView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"setContent('%@');", self.apost.content]];
//        }
//    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
