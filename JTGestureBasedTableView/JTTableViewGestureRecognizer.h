/*
 * This file is part of the JTGestureBasedTableView package.
 * (c) James Tang <mystcolor@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, JTTableViewCellEditingState) {
    JTTableViewCellEditingStateMiddle,
    JTTableViewCellEditingStateLeft,
    JTTableViewCellEditingStateRight,
} ;

extern CGFloat const JTTableViewCommitEditingRowDefaultLength;

// JTTableViewRowAnimationDuration is decided to be as close as the internal settings of UITableViewRowAnimation duration
extern CGFloat const JTTableViewRowAnimationDuration;

@protocol JTTableViewGestureAddingRowDelegate, JTTableViewGestureEditingRowDelegate, JTTableViewGestureMoveRowDelegate;

@interface JTTableViewGestureRecognizer : NSObject <UITableViewDelegate>

@property (weak, readonly) UITableView *tableView;

+ (JTTableViewGestureRecognizer*) gestureRecognizerWithTableView:(UITableView*)_ delegate:d;

@end

#pragma mark - Conform to JTTableViewGestureAddingRowDelegate to enable features: - drag down to add cell & - pinch to add cell

@protocol JTTableViewGestureAddingRowDelegate <NSObject>

- (void) gestureRecognizer:(JTTableViewGestureRecognizer*)gr     needsAddRowAtIndexPath:(NSIndexPath*)ip;
- (void) gestureRecognizer:(JTTableViewGestureRecognizer*)gr  needsCommitRowAtIndexPath:(NSIndexPath*)ip;
- (void) gestureRecognizer:(JTTableViewGestureRecognizer*)gr needsDiscardRowAtIndexPath:(NSIndexPath*)ip;

@optional

- (NSIndexPath*) gestureRecognizer:(JTTableViewGestureRecognizer*)gr         willCreateCellAtIndexPath:(NSIndexPath*)ip;
- (CGFloat)      gestureRecognizer:(JTTableViewGestureRecognizer*)gr heightForCommittingRowAtIndexPath:(NSIndexPath*)ip;

@end


#pragma mark - Conform to JTTableViewGestureEditingRowDelegate to enable features - swipe to edit cell

@protocol JTTableViewGestureEditingRowDelegate <NSObject>

@required // Panning

- (BOOL) gestureRecognizer:(JTTableViewGestureRecognizer*)gr canEditRowAtIndexPath:(NSIndexPath*)ip;

- (void) gestureRecognizer:(JTTableViewGestureRecognizer*)gr  didEnterEditingState:(JTTableViewCellEditingState)state
                                                                 forRowAtIndexPath:(NSIndexPath*)ip;

- (void) gestureRecognizer:(JTTableViewGestureRecognizer*)gr    commitEditingState:(JTTableViewCellEditingState)state
                                                                 forRowAtIndexPath:(NSIndexPath*)ip;
@optional

- (CGFloat)gestureRecognizer:(JTTableViewGestureRecognizer*)gr lengthForCommitEditingRowAtIndexPath:(NSIndexPath*)ip;

- (void)   gestureRecognizer:(JTTableViewGestureRecognizer*)gr      didChangeContentViewTranslation:(CGPoint)translation
                                                                                  forRowAtIndexPath:(NSIndexPath*)ip;
@end

#pragma mark - Conform to JTTableViewGestureMoveRowDelegate to enable features - long press to reorder cell

@protocol JTTableViewGestureMoveRowDelegate <NSObject>

- (BOOL) gestureRecognizer:(JTTableViewGestureRecognizer*)gr                    canMoveRowAtIndexPath:(NSIndexPath*)ip;

- (void) gestureRecognizer:(JTTableViewGestureRecognizer*)gr  needsCreatePlaceholderForRowAtIndexPath:(NSIndexPath*)ip;

- (void) gestureRecognizer:(JTTableViewGestureRecognizer*)gr                  needsMoveRowAtIndexPath:(NSIndexPath*)sourceIP
                                                                                          toIndexPath:(NSIndexPath *)destinationIP;

- (void) gestureRecognizer:(JTTableViewGestureRecognizer*)gr needsReplacePlaceholderForRowAtIndexPath:(NSIndexPath*)ip;

@end


@interface UITableView (JTTableViewGestureDelegate)

- (JTTableViewGestureRecognizer*) enableGestureTableViewWithDelegate:_;

- (void) reloadVisibleRowsExceptIndexPath:(NSIndexPath*)ip; // Helper methods for updating cell after datasource changes

@end