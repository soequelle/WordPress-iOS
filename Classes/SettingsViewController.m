//
//  SettingsViewController.m
//  WordPress
//
//  Created by Jorge Bernal on 6/1/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

/*
 
 Settings contents:
 
 - Blogs list
    - Add blog
    - Edit/Delete
 - WordPress.com account
    - Sign out / Sign in
 - Media Settings
    - Image Resize
    - Video API
    - Video Quality
    - Video Content
 - Info
    - Version
    - About
    - Extra debug

 */

#import "SettingsViewController.h"
#import "WordPressAppDelegate.h"
#import "EditSiteViewController.h"
#import "WelcomeViewController.h"
#import "WPcomLoginViewController.h"
#import "UIImageView+Gravatar.h"
#import "WordPressComApi.h"
#import "AboutViewController.h"
#import "SettingsPageViewController.h"

typedef enum {
    SettingsSectionBlogs = 0,
    SettingsSectionBlogsAdd,
    SettingsSectionWpcom,
    SettingsSectionMedia,
    SettingsSectionInfo,
    
    SettingsSectionCount
} SettingsSection;

@interface SettingsViewController () <NSFetchedResultsControllerDelegate, UIActionSheetDelegate, WPcomLoginViewControllerDelegate>

@property (readonly) NSFetchedResultsController *resultsController;
@property (nonatomic, strong) NSArray *mediaSettingsArray;

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
- (UITableViewCell *)cellForIndexPath:(NSIndexPath *)indexPath;
- (void)checkCloseButton;
- (void)setupMedia;

@end

@implementation SettingsViewController {
    NSFetchedResultsController *_resultsController;
}

@synthesize mediaSettingsArray;

#pragma mark -
#pragma mark LifeCycle Methods

- (void)dealloc {
    [_resultsController release];
    [mediaSettingsArray release];
    
    [super dealloc];
}


- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Settings", @"App Settings");
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", @"") style:UIBarButtonItemStyleBordered target:self action:@selector(dismiss)] autorelease];
    [[NSNotificationCenter defaultCenter] addObserverForName:WordPressComApiDidLoginNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SettingsSectionWpcom] withRowAnimation:UITableViewRowAnimationFade];
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:WordPressComApiDidLogoutNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SettingsSectionWpcom] withRowAnimation:UITableViewRowAnimationFade];
    }];
    
    self.tableView.backgroundView = nil;
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"settings_bg"]];
    [self setupMedia];
}


- (void)viewDidUnload {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewDidUnload];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self checkCloseButton];
    self.editButtonItem.enabled = ([[self.resultsController fetchedObjects] count] > 0); // Disable if we have no blogs.
    [self.tableView reloadData];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}


#pragma mark - 
#pragma mark Custom methods

- (void)setupMedia {
    if (mediaSettingsArray) return;
    
    // Construct the media data to mimick how it would appear if a settings bundle plist was loaded
    // into an NSDictionary
    // Our settings bundle stored numeric values as strings so we use strings here for backward compatibility.
    NSDictionary *imageResizeDict = [NSDictionary dictionaryWithObjectsAndKeys:@"0", @"DefaultValue", 
                                     @"media_resize_preference", @"Key", 
                                     NSLocalizedString(@"Image Resize", @""), @"Title", 
                                     [NSArray arrayWithObjects:NSLocalizedString(@"Always Ask", @"Image resize preference"), 
                                      NSLocalizedString(@"Small", @"Image resize preference"),
                                      NSLocalizedString(@"Medium", @"Image resize preference"),
                                      NSLocalizedString(@"Large", @"Image resize preference"),
                                      NSLocalizedString(@"Disabled", @"Image resize preference"), nil], @"Titles",
                                     [NSArray arrayWithObjects:@"0",@"1",@"2",@"3",@"4", nil], @"Values",
                                     NSLocalizedString(@"Set default size images should be uploaded.", @""), @"Info",
                                     nil];
    
    NSDictionary *videoApiDict = [NSDictionary dictionaryWithObjectsAndKeys:@"2", @"DefaultValue", 
                                     @"video_api_preference", @"Key", 
                                     NSLocalizedString(@"Video API", @""), @"Title", 
                                     [NSArray arrayWithObjects:@"AtomPub",@"XML-RPC", nil ], @"Titles", 
                                     [NSArray arrayWithObjects:@"1", @"2", nil], @"Values",
                                     NSLocalizedString(@"Set whether your blog uses the AtomPub format or the XML-RPC format when syncing data to the app.", @""), @"Info",
                                     nil];
    
    NSDictionary *videoQualityDict = [NSDictionary dictionaryWithObjectsAndKeys:@"1", @"DefaultValue", 
                                      @"video_quality_preference", @"Key", 
                                      NSLocalizedString(@"Video Quality", @""), @"Title", 
                                      [NSArray arrayWithObjects:NSLocalizedString(@"High", @"Video quality"),
                                      @"640x480", 
                                      NSLocalizedString(@"Medium", @"Video quality"),
                                      NSLocalizedString(@"Low", @"Video quality"), nil], @"Titles", 
                                      [NSArray arrayWithObjects:@"0", @"3", @"1", @"2", nil], @"Values",
                                      NSLocalizedString(@"Choose the quality at which video should be uploaded when inserting into posts.", @""), @"Info",                                      
                                      nil];
    
    NSDictionary *videoContentDict = [NSDictionary dictionaryWithObjectsAndKeys:@"0", @"DefaultValue", 
                                      @"video_html_preference", @"Key", 
                                      NSLocalizedString(@"Video Content", @""), @"Title", 
                                      [NSArray arrayWithObjects:@"HTML 5",@"HTML 4", nil ], @"Titles", 
                                      [NSArray arrayWithObjects:@"0", @"1", nil], @"Values",
                                      NSLocalizedString(@"Set which HTML standard video should conform to when added to a post.", @""), @"Info",
                                      nil];
    self.mediaSettingsArray = [NSArray arrayWithObjects:imageResizeDict, videoApiDict, videoQualityDict, videoContentDict, nil];
}


- (void)dismiss {
    [self dismissModalViewControllerAnimated:YES];
}


- (void)checkCloseButton {
    if ([[self.resultsController fetchedObjects] count] == 0 && [WordPressComApi sharedApi].username == nil) {
        WelcomeViewController *welcomeViewController;
        welcomeViewController = [[[WelcomeViewController alloc] initWithNibName:@"WelcomeViewController" bundle:nil] autorelease]; 
        [welcomeViewController automaticallyDismissOnLoginActions];
        self.navigationController.navigationBar.hidden = YES;
        [self.navigationController pushViewController:welcomeViewController animated:YES];
    } else {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
}


- (void)handleExtraDebugChanged:(id)sender {
    UISwitch *aSwitch = (UISwitch *)sender;
    [[NSUserDefaults standardUserDefaults] setBool:aSwitch.on forKey:@"extra_debug"];
    [NSUserDefaults resetStandardUserDefaults];
}


#pragma mark - 
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return SettingsSectionCount;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case SettingsSectionBlogs:
            return [[self.resultsController fetchedObjects] count];
        case SettingsSectionBlogsAdd:
            return 1;
        case SettingsSectionWpcom:
            return [WordPressComApi sharedApi].username ? 2 : 1;
        case SettingsSectionMedia:
            return [mediaSettingsArray count];
        case SettingsSectionInfo:
            return 3;
        default:
            return 0;
    }
}


- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == SettingsSectionBlogs) {
        return NSLocalizedString(@"Remove", @"Button label when removing a blog");
    }
    return nil;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == SettingsSectionBlogs) {
        return NSLocalizedString(@"Blogs", @"");
    } else if (section == SettingsSectionWpcom) {
        return NSLocalizedString(@"WordPress.com", @"");
    } else if (section == SettingsSectionBlogsAdd) {
        return nil;    
    } else if (section == SettingsSectionMedia) {
        return NSLocalizedString(@"Media", @"");
    } else if (section == SettingsSectionInfo) {
        return NSLocalizedString(@"App Info", @"");
    }
    return nil;
}


- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {    
    cell.textLabel.textAlignment = UITextAlignmentLeft;
    cell.accessoryType = UITableViewCellAccessoryNone;
    if (indexPath.section == SettingsSectionBlogs) {
        Blog *blog = [self.resultsController objectAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:0]];
        cell.textLabel.text = blog.blogName;
        cell.detailTextLabel.text = blog.hostURL;
        [cell.imageView setImageWithBlavatarUrl:blog.blavatarUrl isWPcom:blog.isWPcom];
    } else if (indexPath.section == SettingsSectionBlogsAdd) {
        cell.textLabel.text = NSLocalizedString(@"Add a Blog", @"");
        cell.textLabel.textAlignment = UITextAlignmentCenter;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else if (indexPath.section == SettingsSectionWpcom) {
        if ([WordPressComApi sharedApi].username) {
            if (indexPath.row == 0) {
                cell.textLabel.text = NSLocalizedString(@"Username:", @"");
                cell.detailTextLabel.text = [WordPressComApi sharedApi].username;
                cell.detailTextLabel.textColor = [UIColor UIColorFromHex:0x888888];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            } else {
                cell.textLabel.textAlignment = UITextAlignmentCenter;
                cell.textLabel.text = NSLocalizedString(@"Sign Out", @"Sign out from WordPress.com");
            }
        } else {
            cell.textLabel.textAlignment = UITextAlignmentCenter;
            cell.textLabel.text = NSLocalizedString(@"Sign In", @"Sign in to WordPress.com");
        }
    } else if (indexPath.section == SettingsSectionMedia){
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        NSDictionary *dict = [mediaSettingsArray objectAtIndex:indexPath.row];
        cell.textLabel.text = [dict objectForKey:@"Title"];
        NSString *key = [dict objectForKey:@"Key"];
        NSString *currentVal = [[NSUserDefaults standardUserDefaults] objectForKey:key];
        if (currentVal == nil) {
            currentVal = [dict objectForKey:@"DefaultValue"];
        }
        
        NSArray *values = [dict objectForKey:@"Values"];
        NSInteger index = [values indexOfObject:currentVal];
        
        NSArray *titles = [dict objectForKey:@"Titles"];
        cell.detailTextLabel.text = [titles objectAtIndex:index];

    } else if (indexPath.section == SettingsSectionInfo) {
        if (indexPath.row == 0) {
            cell.textLabel.text = NSLocalizedString(@"Version:", @"");
            NSString *appversion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
            cell.detailTextLabel.text = appversion;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        } else if (indexPath.row == 1) {
            cell.textLabel.text = NSLocalizedString(@"About", @"");
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } else if (indexPath.row == 2) {
            cell.textLabel.text = NSLocalizedString(@"Extra Debug", @"A lable for the settings switch to enable extra debugging and logging.");
            UISwitch *aSwitch = [[[UISwitch alloc] initWithFrame:CGRectZero] autorelease]; // Frame is ignored.
            [aSwitch addTarget:self action:@selector(handleExtraDebugChanged:) forControlEvents:UIControlEventValueChanged];
            aSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"extra_debug"];
            cell.accessoryView = aSwitch;
        }
    }
}


- (UITableViewCell *)cellForIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = @"Cell";
    UITableViewCellStyle cellStyle = UITableViewCellStyleDefault;
    
    switch (indexPath.section) {
        case SettingsSectionBlogs:
            cellIdentifier = @"BlogCell";
            cellStyle = UITableViewCellStyleSubtitle;
            break;
        case SettingsSectionWpcom:
            cellIdentifier = @"WpcomCell";
            cellStyle = UITableViewCellStyleValue1;
            break;
        case SettingsSectionMedia:
            cellIdentifier = @"Media";
            cellStyle = UITableViewCellStyleValue1;
            break;
        case SettingsSectionInfo:
            if (indexPath.row == 0) {
                cellIdentifier = @"InfoCell";
                cellStyle = UITableViewCellStyleValue1;
            }
            break;
        default:
            break;
    }
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:cellStyle reuseIdentifier:cellIdentifier] autorelease];
    }
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self cellForIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return (indexPath.section == SettingsSectionBlogs);
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Blog *blog = [self.resultsController objectAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:0]];
        [blog remove];
        
        if([[self.resultsController fetchedObjects] count] == 0) {
            [self setEditing:NO];
            self.editButtonItem.enabled = NO;
        }
    }   
}


#pragma mark - 
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == SettingsSectionBlogs) {
        Blog *blog = [self.resultsController objectAtIndexPath:indexPath];

		EditSiteViewController *editSiteViewController = [[[EditSiteViewController alloc] init] autorelease];
        editSiteViewController.blog = blog;
        [self.navigationController pushViewController:editSiteViewController animated:YES];

    } else if (indexPath.section == SettingsSectionBlogsAdd) {
        WelcomeViewController *welcomeViewController;
        welcomeViewController = [[[WelcomeViewController alloc] initWithNibName:@"WelcomeViewController" bundle:nil] autorelease]; 
        welcomeViewController.title = NSLocalizedString(@"Add a Blog", @"");
        [self.navigationController pushViewController:welcomeViewController animated:YES];
        
    } else if (indexPath.section == SettingsSectionWpcom) {
        if ([WordPressComApi sharedApi].username) {
            if (indexPath.row == 1) {
                // Present the Sign out ActionSheet
                NSString *signOutTitle = NSLocalizedString(@"You are logged in as", @"");
                signOutTitle = [NSString stringWithFormat:@"%@ %@", signOutTitle, [WordPressComApi sharedApi].username];
                UIActionSheet *actionSheet;
                actionSheet = [[UIActionSheet alloc] initWithTitle:signOutTitle 
                                                          delegate:self 
                                                 cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
                                            destructiveButtonTitle:NSLocalizedString(@"Sign Out", @"")otherButtonTitles:nil, nil ];
                actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
                [actionSheet showInView:self.view];
                [actionSheet release];
            }
        } else {
            WPcomLoginViewController *loginViewController = [[WPcomLoginViewController alloc] initWithStyle:UITableViewStyleGrouped];
            loginViewController.delegate = self;
            [self.navigationController pushViewController:loginViewController animated:YES];
        }
        
    } else if (indexPath.section == SettingsSectionMedia) {
        NSDictionary *dict = [mediaSettingsArray objectAtIndex:indexPath.row];
        SettingsPageViewController *controller = [[[SettingsPageViewController alloc] initWithDictionary:dict] autorelease];
        [self.navigationController pushViewController:controller animated:YES];
    
    } else if (indexPath.section == SettingsSectionInfo) {
        if (indexPath.row == 1) {
            AboutViewController *aboutViewController = [[[AboutViewController alloc] initWithNibName:@"AboutViewController" bundle:nil] autorelease]; 
            [self.navigationController pushViewController:aboutViewController animated:YES];
        }
    }
}


#pragma mark - 
#pragma mark NSFetchedResultsController

- (NSFetchedResultsController *)resultsController {
    if (_resultsController) {
        return _resultsController;
    }

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSManagedObjectContext *moc = [[WordPressAppDelegate sharedWordPressApp] managedObjectContext];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Blog" inManagedObjectContext:moc]];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"blogName" ascending:YES]]];
    
    // For some reasons, the cache sometimes gets corrupted
    // Since we don't really use sections we skip the cache here
    _resultsController = [[NSFetchedResultsController alloc]
                                                      initWithFetchRequest:fetchRequest
                                                      managedObjectContext:moc
                                                      sectionNameKeyPath:nil
                                                      cacheName:nil];
    _resultsController.delegate = self;

    NSError *error = nil;
    if (![_resultsController performFetch:&error]) {
        WPFLog(@"Couldn't fetch blogs: %@", [error localizedDescription]);
        [_resultsController release];
        _resultsController = nil;
    }
    [fetchRequest release];
    return _resultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
    [self checkCloseButton];
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    
    if (NSFetchedResultsChangeUpdate == type && newIndexPath != nil) {
        // Seriously, Apple?
        // http://developer.apple.com/library/ios/#releasenotes/iPhone/NSFetchedResultsChangeMoveReportedAsNSFetchedResultsChangeUpdate/_index.html
        type = NSFetchedResultsChangeMove;
    }
    
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[self.tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [self.tableView deleteRowsAtIndexPaths:[NSArray
                                                    arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView insertRowsAtIndexPaths:[NSArray
                                                    arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


#pragma mark - 
#pragma mark WPComLoginViewControllerDelegate

- (void)loginController:(WPcomLoginViewController *)loginController didAuthenticateWithUsername:(NSString *)username {
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SettingsSectionWpcom] withRowAnimation:UITableViewRowAnimationFade];
    [self.navigationController popToRootViewControllerAnimated:YES];
    [self checkCloseButton];
}


- (void)loginControllerDidDismiss:(WPcomLoginViewController *)loginController {
    [self.navigationController popToRootViewControllerAnimated:YES];
}


#pragma mark -
#pragma mark Action Sheet Delegate Methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(buttonIndex == 0) {
        // Sign out
        [[WordPressComApi sharedApi] signOut];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SettingsSectionWpcom] withRowAnimation:UITableViewRowAnimationFade];
        [self checkCloseButton];
    }
}

@end
