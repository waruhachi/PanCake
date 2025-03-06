@import Cephei;
@import CepheiPrefs;

#import <roothide.h>

#import <Preferences/PSSpecifier.h>
#import <Preferences/PSListController.h>

@interface PanCakeRootListController : HBRootListController
    @property (nonatomic, retain) UILabel *titleLabel;
    @property (nonatomic, retain) UIImageView *iconView;
    @property (nonatomic, retain) UIBarButtonItem *respringButton;
    @property (nonatomic, retain) UIView *headerView;
    @property (nonatomic, retain) UIImageView *headerImageView;

    - (void)respring:(id)sender;
@end
