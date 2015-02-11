#import <UIKit/UIKit.h>

#import "ViewController.h"


@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic) UIWindow *window;
@property (nonatomic) ViewController *viewController;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    // Will auto load the corresponding viewController.xib
  self.window.rootViewController = (self.viewController = [ViewController.alloc initWithNibName:nil bundle:nil]);

  [UIApplication.sharedApplication setStatusBarStyle:UIStatusBarStyleLightContent];

  return [self.window makeKeyAndVisible], YES;
}

@end
