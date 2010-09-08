//
//  MediaObjectViewController.m
//  WordPress
//
//  Created by Chris Boyd on 9/6/10.
//

#import "MediaObjectViewController.h"


@implementation MediaObjectViewController

@synthesize media, mediaManager, imageView, videoPlayer, deleteButton, insertButton, isDeleting, isInserting;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	
	if((media != nil) && ([media.mediaType isEqualToString:@"video"])) {
		self.navigationItem.title = @"Video";
		videoPlayer = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL fileURLWithPath:media.localURL]];
		[videoPlayer prepareToPlay];
		videoPlayer.view.frame = self.view.frame;
		[self.view addSubview:videoPlayer.view];
	}
	else if((media != nil) && ([media.mediaType isEqualToString:@"image"])) {
		self.navigationItem.title = @"Image";
		imageView.image = [UIImage imageWithContentsOfFile:media.localURL];
	}
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

#pragma mark -
#pragma mark UIActionSheet delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(isDeleting == YES) {
		switch (buttonIndex) {
			case 0:
				NSLog(@"deleting...");
				[[NSNotificationCenter defaultCenter] postNotificationName:@"ShouldDeleteMedia" object:media];
				[self.navigationController popViewControllerAnimated:YES];
				break;
			case 1:
				NSLog(@"cancelling...");
				break;
			default:
				break;
		}
	}
	else if(isInserting == YES) {
		switch (buttonIndex) {
			case 0:
				NSLog(@"inserting media above...");
				[[NSNotificationCenter defaultCenter] postNotificationName:@"ShouldInsertMediaAbove" object:media];
				[self.navigationController popViewControllerAnimated:YES];
				break;
			case 1:
				NSLog(@"inserting media below...");
				[[NSNotificationCenter defaultCenter] postNotificationName:@"ShouldInsertMediaBelow" object:media];
				[self.navigationController popViewControllerAnimated:YES];
				break;
			case 2:
				NSLog(@"cancelling...");
				break;
			default:
				break;
		}
	}
}

#pragma mark -
#pragma mark Custom methods

- (IBAction)deleteObject:(id)sender {
	isDeleting = YES;
	isInserting = NO;
	
	NSString *titleString = [NSString stringWithFormat:@"Delete %@?", media.mediaType];
	UIActionSheet *deleteActionSheet = [[UIActionSheet alloc] initWithTitle:titleString 
																   delegate:self 
														  cancelButtonTitle:@"Cancel" 
													 destructiveButtonTitle:@"Delete" 
														  otherButtonTitles:nil];
	[deleteActionSheet showInView:self.view];
	[deleteActionSheet release];
}

- (IBAction)insertObject:(id)sender {
	isDeleting = NO;
	isInserting = YES;
	
	NSString *titleString = [NSString stringWithFormat:@"Insert %@:", media.mediaType];
	UIActionSheet *insertActionSheet = [[UIActionSheet alloc] initWithTitle:titleString 
																   delegate:self 
														  cancelButtonTitle:@"Cancel" 
													 destructiveButtonTitle:nil
														  otherButtonTitles:@"Above Content", @"Below Content", nil];
	[insertActionSheet showInView:self.view];
	[insertActionSheet release];
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark Dealloc

- (void)dealloc {
	[insertButton release];
	[deleteButton release];
	[media release];
	[mediaManager release];
	[imageView release];
	[videoPlayer release];
    [super dealloc];
}


@end