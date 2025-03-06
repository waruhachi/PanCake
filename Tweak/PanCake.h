#import <roothide.h>
#import <Cephei/HBPreferences.h>
#import <Foundation/Foundation.h>

#define preferencesPath jbroot(@"/var/mobile/Library/Preferences/com.anthopak.pancake.plist")
#define preferencesGetValue(key) [[NSDictionary dictionaryWithContentsOfFile:preferencesPath] valueForKey:key]
#define preferencesGetBool(key) [preferencesGetValue(key) boolValue]


@interface _UINavigationInteractiveTransitionBase : NSObject
    @property (assign,nonatomic) UIPanGestureRecognizer *gestureRecognizer;

    -(void)startInteractiveTransition;
    -(void)handleNavigationTransition:(UIPanGestureRecognizer*)arg1;
@end


@interface _UINavigationInteractiveTransition : _UINavigationInteractiveTransitionBase
@end


@interface UINavigationController (PanCake)<UIGestureRecognizerDelegate>
    @property (strong, nonatomic) _UINavigationInteractiveTransition *_cachedInteractionController;

    + (UIViewController*) topMostController;
    - (void)_updateInteractiveTransition:(double)arg1;
    - (void)_finishInteractiveTransition:(double)arg1 transitionContext:(id)arg2;
    - (void)_cancelInteractiveTransition:(double)arg1 transitionContext:(id)arg2;
    - (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)panGestureRecognizer;
@end


@interface UIView (PanCake)
    @property (nonatomic, retain) UIPanGestureRecognizer *dismissPanGestureRecognizer;
@end
