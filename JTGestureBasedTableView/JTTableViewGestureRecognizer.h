
@import UIKit;

#import "UIColor+JTGestureBasedTableViewHelper.h"
#import "JTTransformableTableViewCell.h"

#define GRMethod(RET_TYPE) - (RET_TYPE) gestureRecognizer:(JTTableViewGestureRecognizer*)gr

@interface JTTableViewGestureRecognizer : NSObject <UITableViewDelegate>

@property (weak,readonly) UITableView *tableView;

+ (instancetype) gestureRecognizerWithTableView:(UITableView*)_ delegate:d;

@end


#pragma mark - Conform to JTTableViewGestureAddingRowDelegate to enable features: - drag down to add cell & - pinch to add cell

@protocol JTTableViewGestureAddingRowDelegate <NSObject>

GRMethod(void)               needsAddRowAtIndexPath:(NSIndexPath*)ip;
GRMethod(void)            needsCommitRowAtIndexPath:(NSIndexPath*)ip;
GRMethod(void)           needsDiscardRowAtIndexPath:(NSIndexPath*)ip;

@optional

GRMethod(NSIndexPath*)    willCreateCellAtIndexPath:(NSIndexPath*)ip;
GRMethod(CGFloat) heightForCommittingRowAtIndexPath:(NSIndexPath*)ip;

@end

typedef NS_ENUM(NSInteger, JTTableViewCellEditingState) { JTTableViewCellEditingStateMiddle,
                                                          JTTableViewCellEditingStateLeft,
                                                          JTTableViewCellEditingStateRight };

#pragma mark - Conform to JTTableViewGestureEditingRowDelegate to enable features - swipe to edit cell

@protocol JTTableViewGestureEditingRowDelegate <NSObject> @required // Panning

GRMethod(BOOL) canEditRowAtIndexPath:(NSIndexPath*)ip;

GRMethod(void)  didEnterEditingState:(JTTableViewCellEditingState)_
                   forRowAtIndexPath:(NSIndexPath*)ip;

GRMethod(void)    commitEditingState:(JTTableViewCellEditingState)_
                   forRowAtIndexPath:(NSIndexPath*)ip;

@optional

GRMethod(CGFloat) lengthForCommitEditingRowAtIndexPath:(NSIndexPath*)ip;

GRMethod(void)         didChangeContentViewTranslation:(CGPoint)translation
                                     forRowAtIndexPath:(NSIndexPath*)ip;
@end

#pragma mark - Conform to JTTableViewGestureMoveRowDelegate to enable features - long press to reorder cell

@protocol JTTableViewGestureMoveRowDelegate <NSObject>

GRMethod(BOOL)                    canMoveRowAtIndexPath:(NSIndexPath*)ip;

GRMethod(void)  needsCreatePlaceholderForRowAtIndexPath:(NSIndexPath*)ip;

GRMethod(void)                  needsMoveRowAtIndexPath:(NSIndexPath*)sourceIP
                                            toIndexPath:(NSIndexPath*)destinationIP;

GRMethod(void) needsReplacePlaceholderForRowAtIndexPath:(NSIndexPath*)ip;

@end

@interface UITableView (JTTableViewGestureDelegate)

- (JTTableViewGestureRecognizer*) enableGestureTableViewWithDelegate:_;

- (void) reloadVisibleRowsExceptIndexPath:(NSIndexPath*)ip; // Helper methods for updating cell after datasource changes

@end

extern CGFloat const JTTableViewCommitEditingRowDefaultLength, JTTableViewRowAnimationDuration;

/*
  @protocol JTTableViewGestureAddingRowDelegate, JTTableViewGestureEditingRowDelegate, JTTableViewGestureMoveRowDelegate;

  JTTableViewRowAnimationDuration is decided to be as close as the internal settings of UITableViewRowAnimation duration

 * This file is part of the JTGestureBasedTableView package.
 * (c) James Tang <mystcolor@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

