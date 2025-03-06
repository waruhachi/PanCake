#import "Tweak.h"


HBPreferences *preferences;

BOOL enabled;
BOOL hapticFeedbackEnabled;

NSString *appName;
NSInteger hapticFeedbackStrength;


%group PanCake

BOOL shouldRecognizeSimultaneousGestures;

static BOOL panGestureIsSwipingLeftToRight(UIPanGestureRecognizer *panGest) {
    CGPoint velocity = [panGest velocityInView:panGest.view];

    // horizontal
    if (fabs(velocity.x) > fabs(velocity.y)) {
        // right to left, for arabic devices
        BOOL deviceIsRTL = [UIApplication sharedApplication].userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft;

        // from left to right on LTR, or from right to left on RTL
        if ((!deviceIsRTL && velocity.x > 0) || (deviceIsRTL && velocity.x < 0)) {
            return YES;
        }
    }

    return NO;
}

%hook UINavigationController

- (void)_layoutTopViewController {
    %orig;

    UIViewController *viewController = [self topViewController];

    //check viewLoaded is required for some apps loading nibs on launch (Apple Support)
    if (!viewController || !viewController.viewLoaded) return;

    // #pragma clang diagnostic push
    // #pragma clang diagnostic ignored "-Wundeclared-selector"

    UIView *viewForGesture = viewController.view;

    // if it's not rootviewcontroller
    if (viewController.navigationController.viewControllers.count > 0 && viewController != [viewController.navigationController.viewControllers objectAtIndex:0]) {
        if (!viewForGesture.dismissPanGestureRecognizer) {
            if ([self._cachedInteractionController respondsToSelector:@selector(handleNavigationTransition:)]) {
                viewForGesture.dismissPanGestureRecognizer = [[UIPanGestureRecognizer alloc]initWithTarget:self._cachedInteractionController action:@selector(handleNavigationTransition:)];
                viewForGesture.dismissPanGestureRecognizer.delegate = self;

                [viewForGesture addGestureRecognizer:viewForGesture.dismissPanGestureRecognizer];
            }
        }
    }

    // #pragma clang diagnostic pop
}

// Limit conflicts with some UIScrollView and swipes from right to left
%new
- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)panGestureRecognizer {
    if (panGestureRecognizer == panGestureRecognizer.view.dismissPanGestureRecognizer) {
        return panGestureIsSwipingLeftToRight(panGestureRecognizer);
    }

    return YES;
}

%new
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if (shouldRecognizeSimultaneousGestures) {
        if (gestureRecognizer == gestureRecognizer.view.dismissPanGestureRecognizer) {
            if ([appName isEqualToString:@"com.facebook.Messenger"]) {
                // Messenger app requires this additional check (swiping side)
                return panGestureIsSwipingLeftToRight(gestureRecognizer.view.dismissPanGestureRecognizer);
            } else {
                return YES;
            }
        }
    }

    return NO;
}

// Limit conflicts with UISlider (Know issue: sometimes gestures will stop working after playing a bit with a slider, still need to be fixed)
%new
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (gestureRecognizer == gestureRecognizer.view.dismissPanGestureRecognizer) {
        if ([touch.view isKindOfClass:[UISlider class]]) {
            return NO;
        }
    }

    return YES;
}

%end

%hook UIView

%property (nonatomic, retain) UIPanGestureRecognizer *dismissPanGestureRecognizer;

%end

%hook _UINavigationInteractiveTransitionBase

- (void)handleNavigationTransition:(UIPanGestureRecognizer*)arg1 {
    %orig;
}

%end

%end

%group HapticFeedback

%hook UINavigationController

- (void)_finishInteractiveTransition:(double)arg1 transitionContext:(id)arg2 {
    %orig;

    if (hapticFeedbackEnabled) {
        switch (hapticFeedbackStrength) {
            case 0:
                [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
                break;
            case 1:
                [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium] impactOccurred];
                break;
            case 2:
                [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy] impactOccurred];
                break;
            default:
                break;
        }
    }
}

%end

%end

void setDefaultBlacklistedApps() {
    NSArray* defaultBlacklistedApp = @[
        //already natively implemented
        @"com.atebits.Tweetie2",
        @"com.burbn.instagram",
        @"com.facebook.Facebook",
        @"com.christianselig.Apollo",
        @"ph.telegra.Telegraph",
        @"com.reddit.Reddit",

        //gesture conflicts
        @"com.spotify.client", //adding song to the queue
        @"com.hegenberg.BetterTouchToolRemote", //showing left controls
        @"com.intsig.CamScanner" //resizing image conflicts
    ];

    NSFileManager *fileManager = [NSFileManager defaultManager];

    if(![fileManager fileExistsAtPath:preferencesPath]) {
        NSMutableDictionary *plistDict = [[NSMutableDictionary alloc] init];

        for (NSString *blacklistedApp in defaultBlacklistedApp) {
            [plistDict setValue:@"YES" forKey:blacklistedApp];
        }

        [plistDict writeToFile:preferencesPath atomically:YES];
    }
}

static BOOL appIsBlacklisted(NSString *appName) {
    return preferencesGetBool(appName);
}

static BOOL tweakShouldLoad() {
    // https://www.reddit.com/r/jailbreak/comments/4yz5v5/comment/d6rlh88/

    BOOL shouldLoad = NO;

    NSArray *args = [[NSClassFromString(@"NSProcessInfo") processInfo] arguments];
    NSUInteger argsCount = args.count;

    if (argsCount != 0) {
        NSString *executablePath = args[0];

        if (executablePath) {
            NSString *processName = [executablePath lastPathComponent];

            BOOL isApplication = [executablePath rangeOfString:@"/Application/"].location != NSNotFound || [executablePath rangeOfString:@"/Applications/"].location != NSNotFound;
            BOOL isSpringBoard = [processName isEqualToString:@"SpringBoard"];
            BOOL isFileProvider = [[processName lowercaseString] rangeOfString:@"fileprovider"].location != NSNotFound;
            BOOL skip = [processName isEqualToString:@"AdSheet"] || [processName isEqualToString:@"CoreAuthUI"] || [processName isEqualToString:@"InCallService"] || [processName isEqualToString:@"MessagesNotificationViewService"] || [processName isEqualToString:@"PassbookUIService"] || [executablePath rangeOfString:@".appex/"].location != NSNotFound;

            if (!isFileProvider && (isApplication || isSpringBoard) && !skip) {
                shouldLoad = YES;
            }
        }
    }

    return shouldLoad;
}

%ctor {
    if (!tweakShouldLoad()) {
        return;
    }

    preferences = [[HBPreferences alloc] initWithIdentifier:@"com.anthopak.pancake"];

    [preferences registerBool:&enabled default:YES forKey:@"enabled"];
    [preferences registerBool:&hapticFeedbackEnabled default:YES forKey:@"hapticFeedbackEnabled"];
    [preferences registerInteger:&hapticFeedbackStrength default:0 forKey:@"hapticFeedbackStrength"];

    setDefaultBlacklistedApps();

    if (enabled) {
        appName = [[NSBundle mainBundle] bundleIdentifier];

        if (appName && !appIsBlacklisted(appName)) {
            if ([appName isEqualToString:@"com.apple.MobileSMS"] || [appName isEqualToString:@"com.facebook.Messenger"]) {
                shouldRecognizeSimultaneousGestures = YES;
            }

            %init(PanCake);
        }

        // HapticFeedback is splitted so that it can be performed even in blacklisted apps
        if (hapticFeedbackEnabled) {
            %init(HapticFeedback);
        }
    }
}
