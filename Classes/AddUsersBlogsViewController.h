//
//  AddUsersBlogsViewController.h
//  WordPress
//
//  Created by Chris Boyd on 7/19/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HttpHelper.h"
#import "RegexKitLite.h"
#import "WordPressAppDelegate.h"
#import "Blog.h"
#import "WPProgressHUD.h"
#import "WPcomLoginViewController.h"
#import "BlogDataManager.h"

@interface AddUsersBlogsViewController : UIViewController <UITableViewDelegate, HTTPHelperDelegate> {
	WordPressAppDelegate *appDelegate;
	BOOL hasCompletedGetUsersBlogs;
	NSArray *usersBlogs;
	NSMutableArray *selectedBlogs;
	NSMutableDictionary *currentBlog;
	IBOutlet UITableView *tableView;
	IBOutlet UIBarButtonItem *buttonAddSelected, *buttonSelectAll;
}

@property (nonatomic, assign) BOOL hasCompletedGetUsersBlogs;
@property (nonatomic, retain) NSArray *usersBlogs;
@property (nonatomic, retain) NSMutableDictionary *currentBlog;
@property (nonatomic, retain) NSMutableArray *selectedBlogs;
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *buttonAddSelected, *buttonSelectAll;

- (IBAction)selectAllBlogs:(id)sender;
- (IBAction)deselectAllBlogs:(id)sender;
- (void)refreshBlogs;
- (IBAction)saveSelectedBlogs:(id)sender;
- (void)updateFavicons;
- (void)reloadTableView;
- (void)createBlog:(Blog *)blog;

@end