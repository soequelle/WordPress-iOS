//
//  RichTextEditorWebView.h
//  WordPress
//

#import <UIKit/UIKit.h>

@class RichTextEditorWebView;

@protocol RichTextEditorWebViewDelegate <NSObject>

@optional

- (void)richTextEditorIsReady:(RichTextEditorWebView *)editorView;

@end

@interface RichTextEditorWebView : UIView <UIWebViewDelegate>

@property (nonatomic, assign) id<RichTextEditorWebViewDelegate> delegate;
@property (nonatomic, retain) NSString *text;
@property (nonatomic, retain) NSString *placeholderText;
@property (nonatomic, assign, getter = isReady) BOOL ready;

- (NSString *)stringByEvaluatingJavaScriptFromString:(NSString *)string;

@end
