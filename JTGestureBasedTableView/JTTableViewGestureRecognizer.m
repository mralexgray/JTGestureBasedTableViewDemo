/*
 * This file is part of the JTGestureBasedTableView package.
 * (c) James Tang <mystcolor@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "JTTableViewGestureRecognizer.h"
#import "JTTransformableTableViewCell.h"
#import <QuartzCore/QuartzCore.h>

@import AtoZTouch;

typedef NS_ENUM(NSInteger, JTTableViewGestureRecognizerState) {
  JTTableViewGestureRecognizerStateNone,
  JTTableViewGestureRecognizerStateDragging,
  JTTableViewGestureRecognizerStatePinching,
  JTTableViewGestureRecognizerStatePanning,
  JTTableViewGestureRecognizerStateMoving,
} ;

CGFloat const JTTableViewCommitEditingRowDefaultLength = 80;
CGFloat const JTTableViewRowAnimationDuration          = 0.25;       // Rough guess is 0.25

@interface JTTableViewGestureRecognizer () <UIGestureRecognizerDelegate>

@property (nonatomic, weak) id <JTTableViewGestureAddingRowDelegate,
JTTableViewGestureEditingRowDelegate,
JTTableViewGestureMoveRowDelegate> delegate;

@property (nonatomic, weak) id <UITableViewDelegate> tableViewDelegate;

@property (nonatomic, weak) UITableView               * tableView;

@property (nonatomic) UIImage                         * cellSnapshot;
@property (nonatomic) NSTimer                         * movingTimer;
@property (nonatomic) UIPinchGestureRecognizer        * pinchRecognizer;
@property (nonatomic) NSIndexPath                     * addingIndexPath;
@property (nonatomic) UIPanGestureRecognizer          * panRecognizer;
@property (nonatomic) UILongPressGestureRecognizer    * longPressRecognizer;

@property (nonatomic) JTTableViewGestureRecognizerState state;
@property (nonatomic) JTTableViewCellEditingState       addingCellState;
@property (nonatomic) CGPoint                           startPinchingUpperPoint;
@property (nonatomic) CGFloat                           addingRowHeight, scrollingRate;

@end

#define CELL_SNAPSHOT_TAG 100000

@implementation JTTableViewGestureRecognizer

@synthesize delegate, tableView, tableViewDelegate, addingIndexPath, startPinchingUpperPoint, addingRowHeight, pinchRecognizer, panRecognizer, longPressRecognizer, state, addingCellState, cellSnapshot, scrollingRate, movingTimer;

- (void) scrollTable {

  // Scroll tableview while touch point is on top or bottom part

  CGPoint location  = [self.longPressRecognizer locationInView:self.tableView];

  // Refresh the indexPath since it may change while we use a new offset

  CGPoint currentOffset = self.tableView.contentOffset,
              newOffset = CGPointMake(currentOffset.x, currentOffset.y + self.scrollingRate);

  if      (newOffset.y < 0)

    newOffset.y = 0;

  else if (self.tableView.contentSize.height < self.tableView.frame.size.height)

    newOffset = currentOffset;

  else if (newOffset.y > self.tableView.contentSize.height - self.tableView.frame.size.height)

    newOffset.y = self.tableView.contentSize.height - self.tableView.frame.size.height;

  [self.tableView setContentOffset:newOffset];

  if (location.y >= 0)
    ((UIImageView *)[self.tableView viewWithTag:CELL_SNAPSHOT_TAG]).center = CGPointMake(self.tableView.center.x, location.y);

  [self updateAddingIndexPathForCurrentLocation];
}

- (void) updateAddingIndexPathForCurrentLocation {

  // Refresh the indexPath since it may change while we use a new offset

  CGPoint      location  = [longPressRecognizer locationInView:tableView];
  NSIndexPath *indexPath = [tableView indexPathForRowAtPoint:location];

  if (!indexPath || [indexPath isEqual:addingIndexPath]) return;

  [tableView update:^(UITableView *t) {

    [t deleteRowsAtIndexPaths:@[self.addingIndexPath] withRowAnimation:UITableViewRowAnimationNone];
    [t insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    [self.delegate gestureRecognizer:self needsMoveRowAtIndexPath:self.addingIndexPath toIndexPath:indexPath];

    self.addingIndexPath = indexPath;

  }];
}

#pragma mark Logic

- (void) commitOrDiscardCell {

  if (self.addingIndexPath) {

    UITableViewCell *cell = (UITableViewCell *)[self.tableView cellForRowAtIndexPath:self.addingIndexPath];

    [tableView update:^(UITableView *t) {

      CGFloat commitingCellHeight = [self.delegate respondsToSelector:@selector(gestureRecognizer:heightForCommittingRowAtIndexPath:)] ?
                                    [self.delegate gestureRecognizer:self heightForCommittingRowAtIndexPath:self.addingIndexPath] :
                                    t.rowHeight;

      if (cell.frame.size.height >= commitingCellHeight) [self.delegate gestureRecognizer:self needsCommitRowAtIndexPath:self.addingIndexPath];

      else {
        [self.delegate gestureRecognizer:self needsDiscardRowAtIndexPath:self.addingIndexPath];
        [t deleteRowsAtIndexPaths:@[self.addingIndexPath] withRowAnimation:UITableViewRowAnimationMiddle];
      }

        // We would like to reload other rows as well
      [t performSelector:@selector(reloadVisibleRowsExceptIndexPath:) withObject:self.addingIndexPath afterDelay:JTTableViewRowAnimationDuration];

      self.addingIndexPath = nil;

    }];

    // Restore contentInset while touch ends
    [UIView beginAnimations:@"" context:nil];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.5];  // Should not be less than the duration of row animation
    tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    [UIView commitAnimations];

  }
  self.state = JTTableViewGestureRecognizerStateNone;
}

#pragma mark Action

- (void)pinchGestureRecognizer:(UIPinchGestureRecognizer*)recog {

  NSLog(@"%lu %f %f", (unsigned long)recog.numberOfTouches, recog.velocity, recog.scale);

  if (recog.state == UIGestureRecognizerStateEnded || recog.numberOfTouches < 2) {

    !self.addingIndexPath ?: [self commitOrDiscardCell]; return;
  }

  CGPoint location1 = [recog locationOfTouch:0 inView:self.tableView],
  location2 = [recog locationOfTouch:1 inView:self.tableView],
  upperPoint = location1.y < location2.y ? location1 : location2;

  CGRect  rect = (CGRect){location1, location2.x - location1.x, location2.y - location1.y};

  if      (recog.state == UIGestureRecognizerStateBegan)   {

    NSAssert(self.addingIndexPath != nil, @"self.addingIndexPath must not be nil, we should have set it in recognizerShouldBegin");

    self.state = JTTableViewGestureRecognizerStatePinching;

      // Setting up properties for referencing later when touches changes
    self.startPinchingUpperPoint = upperPoint;

      // Creating contentInset to fulfill the whole screen, so our tableview won't occasionaly
      // bounds back to the top while we don't have enough cells on the screen
    self.tableView.contentInset = UIEdgeInsetsMake(self.tableView.frame.size.height, 0, self.tableView.frame.size.height, 0);

    [self.tableView beginUpdates];

    [self.delegate gestureRecognizer:self needsAddRowAtIndexPath:self.addingIndexPath];

    [self.tableView insertRowsAtIndexPaths:@[self.addingIndexPath] withRowAnimation:UITableViewRowAnimationMiddle];
    [self.tableView endUpdates];

  }
  else if (recog.state == UIGestureRecognizerStateChanged) {

    CGFloat diffRowHeight = CGRectGetHeight(rect) - CGRectGetHeight(rect)/recog.scale;

      //        NSLog(@"%f %f %f", CGRectGetHeight(rect), CGRectGetHeight(rect)/[recognizer scale], [recognizer scale]);
    if (self.addingRowHeight - diffRowHeight >= 1 || self.addingRowHeight - diffRowHeight <= -1) {
      self.addingRowHeight = diffRowHeight;
      [self.tableView reloadData];
    }

      // Scrolls tableview according to the upper touch point to mimic a realistic
      // dragging gesture
    CGPoint newUpperPoint = upperPoint;
    CGFloat diffOffsetY = self.startPinchingUpperPoint.y - newUpperPoint.y;
    CGPoint newOffset   = (CGPoint){self.tableView.contentOffset.x, self.tableView.contentOffset.y+diffOffsetY};
    [self.tableView setContentOffset:newOffset animated:NO];
  }
}

- (void)panGestureRecognizer:(UIPanGestureRecognizer*)recog{

  if (    (recog.state == UIGestureRecognizerStateBegan ||
           recog.state == UIGestureRecognizerStateChanged) &&
           recog.numberOfTouches > 0) {

      // TODO: should ask delegate before changing cell's content view

    CGPoint location1 = [recog locationOfTouch:0 inView:self.tableView];

    NSIndexPath *indexPath = self.addingIndexPath ?:

      (id)([self setAddingIndexPath: indexPath = [self.tableView indexPathForRowAtPoint:location1]], indexPath);

    self.state = JTTableViewGestureRecognizerStatePanning;

    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];

    CGPoint translation = [recog translationInView:self.tableView];
    cell.contentView.frame = CGRectOffset(cell.contentView.bounds, translation.x, 0);

    if ([self.delegate respondsToSelector:@selector(gestureRecognizer:didChangeContentViewTranslation:forRowAtIndexPath:)])
      [self.delegate gestureRecognizer:self didChangeContentViewTranslation:translation forRowAtIndexPath:indexPath];

    CGFloat commitEditingLength = JTTableViewCommitEditingRowDefaultLength;
    if ([self.delegate respondsToSelector:@selector(gestureRecognizer:lengthForCommitEditingRowAtIndexPath:)])
      commitEditingLength = [self.delegate gestureRecognizer:self lengthForCommitEditingRowAtIndexPath:indexPath];

    if (fabsf(translation.x) >= commitEditingLength) {
      if (self.addingCellState == JTTableViewCellEditingStateMiddle)
        self.addingCellState = translation.x > 0 ? JTTableViewCellEditingStateRight : JTTableViewCellEditingStateLeft;
    } else {
      if (self.addingCellState != JTTableViewCellEditingStateMiddle) self.addingCellState = JTTableViewCellEditingStateMiddle;
    }

    if ([self.delegate respondsToSelector:@selector(gestureRecognizer:didEnterEditingState:forRowAtIndexPath:)])
      [self.delegate gestureRecognizer:self didEnterEditingState:self.addingCellState forRowAtIndexPath:indexPath];
  }

  else if (recog.state == UIGestureRecognizerStateEnded) {

    NSIndexPath *indexPath = self.addingIndexPath;

      // Removes addingIndexPath before updating then tableView will be able
      // to determine correct table row height
    self.addingIndexPath = nil;

    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    CGPoint translation = [recog translationInView:self.tableView];

    CGFloat commitEditingLength = [self.delegate respondsToSelector:@selector(gestureRecognizer:lengthForCommitEditingRowAtIndexPath:)]
                                ? [self.delegate gestureRecognizer:self lengthForCommitEditingRowAtIndexPath:indexPath]
                                : JTTableViewCommitEditingRowDefaultLength;

    if (fabsf(translation.x) >= commitEditingLength) {
      if ([self.delegate respondsToSelector:@selector(gestureRecognizer:commitEditingState:forRowAtIndexPath:)])
        [self.delegate gestureRecognizer:self commitEditingState:self.addingCellState forRowAtIndexPath:indexPath];
    } else {
      [UIView beginAnimations:@"" context:nil];
      cell.contentView.frame = cell.contentView.bounds;
      [UIView commitAnimations];
    }

    self.addingCellState = JTTableViewCellEditingStateMiddle;
    self.state = JTTableViewGestureRecognizerStateNone;
  }
}

- (void) longPressGestureRecognizer:(UILongPressGestureRecognizer*)recog {

  CGPoint location = [recog locationInView:self.tableView];
  NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];

  if (recog.state == UIGestureRecognizerStateBegan) {

    self.state = JTTableViewGestureRecognizerStateMoving;

    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    UIGraphicsBeginImageContextWithOptions(cell.bounds.size, NO, 0);
    [cell.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *cellImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

      // We create an imageView for caching the cell snapshot here
    UIImageView *snapShotView = (UIImageView *)[self.tableView viewWithTag:CELL_SNAPSHOT_TAG];
    if ( ! snapShotView) {
      snapShotView = [[UIImageView alloc] initWithImage:cellImage];
      snapShotView.tag = CELL_SNAPSHOT_TAG;
      [self.tableView addSubview:snapShotView];
      CGRect rect = [self.tableView rectForRowAtIndexPath:indexPath];
      snapShotView.frame = CGRectOffset(snapShotView.bounds, rect.origin.x, rect.origin.y);
    }
      // Make a zoom in effect for the cell
    [UIView beginAnimations:@"zoomCell" context:nil];
    snapShotView.transform = CGAffineTransformMakeScale(1.1, 1.1);
    snapShotView.center = CGPointMake(self.tableView.center.x, location.y);
    [UIView commitAnimations];


    [self.tableView beginUpdates];

      [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
      [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
      [self.delegate gestureRecognizer:self needsCreatePlaceholderForRowAtIndexPath:indexPath];

      self.addingIndexPath = indexPath;

    [self.tableView endUpdates];

      // Start timer to prepare for auto scrolling
    self.movingTimer = [NSTimer timerWithTimeInterval:1/8 target:self selector:@selector(scrollTable) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.movingTimer forMode:NSDefaultRunLoopMode];

  } else if (recog.state == UIGestureRecognizerStateEnded) {
      // While long press ends, we remove the snapshot imageView

    __block __weak UIImageView *snapShotView = (UIImageView *)[self.tableView viewWithTag:CELL_SNAPSHOT_TAG];
    __block __weak JTTableViewGestureRecognizer *weakSelf = self;

      // We use self.addingIndexPath directly to make sure we dropped on a valid indexPath
      // which we've already ensure while UIGestureRecognizerStateChanged
    __block __weak NSIndexPath *indexPath = self.addingIndexPath;

      // Stop timer
    [self.movingTimer invalidate]; self.movingTimer = nil;
    self.scrollingRate = 0;

    [UIView animateWithDuration:JTTableViewRowAnimationDuration
                     animations:^{
                       CGRect rect = [weakSelf.tableView rectForRowAtIndexPath:indexPath];
                       snapShotView.transform = CGAffineTransformIdentity;    // restore the transformed value
                       snapShotView.frame = CGRectOffset(snapShotView.bounds, rect.origin.x, rect.origin.y);
                     } completion:^(BOOL finished) {
                       [snapShotView removeFromSuperview];

                       [weakSelf.tableView beginUpdates];
                       [weakSelf.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                       [weakSelf.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                       [weakSelf.delegate gestureRecognizer:weakSelf needsReplacePlaceholderForRowAtIndexPath:indexPath];
                       [weakSelf.tableView endUpdates];

                       [weakSelf.tableView reloadVisibleRowsExceptIndexPath:indexPath];
                         // Update state and clear instance variables
                       weakSelf.cellSnapshot = nil;
                       weakSelf.addingIndexPath = nil;
                       weakSelf.state = JTTableViewGestureRecognizerStateNone;
                     }];


  } else if (recog.state == UIGestureRecognizerStateChanged) {
      // While our finger moves, we also moves the snapshot imageView
    UIImageView *snapShotView = (UIImageView *)[self.tableView viewWithTag:CELL_SNAPSHOT_TAG];
    snapShotView.center = CGPointMake(self.tableView.center.x, location.y);

    CGRect rect      = self.tableView.bounds;
    CGPoint location = [self.longPressRecognizer locationInView:self.tableView];
    location.y -= self.tableView.contentOffset.y;       // We needed to compensate actual contentOffset.y to get the relative y position of touch.

    [self updateAddingIndexPathForCurrentLocation];

    CGFloat bottomDropZoneHeight = self.tableView.bounds.size.height / 6;
    CGFloat topDropZoneHeight    = bottomDropZoneHeight;
    CGFloat bottomDiff = location.y - (rect.size.height - bottomDropZoneHeight);
    if (bottomDiff > 0) {
      self.scrollingRate = bottomDiff / (bottomDropZoneHeight / 1);
    } else if (location.y <= topDropZoneHeight) {
      self.scrollingRate = -(topDropZoneHeight - MAX(location.y, 0)) / bottomDropZoneHeight;
    } else {
      self.scrollingRate = 0;
    }
  }
}

#pragma mark UIGestureRecognizer

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gRec{

  return gRec == self.panRecognizer ? ({

    if ( ! [self.delegate conformsToProtocol:@protocol(JTTableViewGestureEditingRowDelegate)]) return NO;

    UIPanGestureRecognizer *pan = (UIPanGestureRecognizer*)gRec;

    CGPoint point = [pan translationInView:self.tableView],
         location = [pan locationInView:self.tableView];

    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];

  // The pan gesture recognizer fail the original scrollView scroll gesture,
  // we wants to ensure we are panning left/right to enable the pan gesture.

    (fabsf(point.y) > fabsf(point.x) || !indexPath) ? NO
                                          /* canEditRow */   : [self.delegate gestureRecognizer:self canEditRowAtIndexPath:indexPath];

  }) : gRec == self.pinchRecognizer ? ^{

    if ( ! [self.delegate conformsToProtocol:@protocol(JTTableViewGestureAddingRowDelegate)])
      return NSLog(@"Should not begin pinch"), NO;

    CGPoint location1 = [gRec locationOfTouch:0 inView:self.tableView];
    CGPoint location2 = [gRec locationOfTouch:1 inView:self.tableView];

    CGRect  rect = (CGRect){location1, location2.x - location1.x, location2.y - location1.y};
    NSArray *indexPaths = [self.tableView indexPathsForRowsInRect:rect];

    // #16 Crash on pinch fix
    if ([indexPaths count] < 2) return NSLog(@"Should not begin pinch"), NO;

    NSIndexPath *firstIndexPath = indexPaths[0];
    NSIndexPath *lastIndexPath  = [indexPaths lastObject];
    NSInteger    midIndex = ((float)(firstIndexPath.row + lastIndexPath.row) / 2) + 0.5;
    NSIndexPath *midIndexPath = [NSIndexPath indexPathForRow:midIndex inSection:firstIndexPath.section];

    self.addingIndexPath = [self.delegate respondsToSelector:@selector(gestureRecognizer:willCreateCellAtIndexPath:)]
                         ? [self.delegate gestureRecognizer:self willCreateCellAtIndexPath:midIndexPath]
                         : midIndexPath;


    if ( ! self.addingIndexPath) return NSLog(@"Should not begin pinch"), NO; return YES;

  }() : gRec == self.longPressRecognizer ? ^{

    CGPoint location = [gRec locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];

    return indexPath && [self.delegate conformsToProtocol:@protocol(JTTableViewGestureMoveRowDelegate)]
                     ? /* canMoveRow */ [self.delegate gestureRecognizer:self canMoveRowAtIndexPath:indexPath] : NO;

  }() : YES;

}

#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  if ([indexPath isEqual:self.addingIndexPath]
      && (self.state == JTTableViewGestureRecognizerStatePinching || self.state == JTTableViewGestureRecognizerStateDragging)) {
      // While state is in pinching or dragging mode, we intercept the row height
      // For Moving state, we leave our real delegate to determine the actual height
    return MAX(1, self.addingRowHeight);
  }

  CGFloat normalCellHeight = aTableView.rowHeight;
  if ([self.tableViewDelegate respondsToSelector:@selector(tableView:heightForRowAtIndexPath:)]) {
    normalCellHeight = [self.tableViewDelegate tableView:aTableView heightForRowAtIndexPath:indexPath];
  }
  return normalCellHeight;
}

#pragma mark UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  if ( ! [self.delegate conformsToProtocol:@protocol(JTTableViewGestureAddingRowDelegate)]) {
    if ([self.tableViewDelegate respondsToSelector:@selector(scrollViewDidScroll:)]) {
      [self.tableViewDelegate scrollViewDidScroll:scrollView];
    }
    return;
  }

    // We try to create a new cell when the user tries to drag the content to and offset of negative value
  if (scrollView.contentOffset.y < 0) {
      // Here we make sure we're not conflicting with the pinch event,
      // ! scrollView.isDecelerating is to detect if user is actually
      // touching on our scrollView, if not, we should assume the scrollView
      // needed not to be adding cell
    if ( ! self.addingIndexPath && self.state == JTTableViewGestureRecognizerStateNone && ! scrollView.isDecelerating) {
      self.state = JTTableViewGestureRecognizerStateDragging;

      self.addingIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
      if ([self.delegate respondsToSelector:@selector(gestureRecognizer:willCreateCellAtIndexPath:)]) {
        self.addingIndexPath = [self.delegate gestureRecognizer:self willCreateCellAtIndexPath:self.addingIndexPath];
      }

      if (self.addingIndexPath) {
        [self.tableView beginUpdates];
        [self.delegate gestureRecognizer:self needsAddRowAtIndexPath:self.addingIndexPath];
        [self.tableView insertRowsAtIndexPaths:@[self.addingIndexPath] withRowAnimation:UITableViewRowAnimationNone];

        self.addingRowHeight = fabsf(scrollView.contentOffset.y);
        [self.tableView endUpdates];
      }
    }
  }

    // Check if addingIndexPath not exists, we don't want to
    // alter the contentOffset of our scrollView
  if (self.addingIndexPath && self.state == JTTableViewGestureRecognizerStateDragging) {
    self.addingRowHeight += scrollView.contentOffset.y * -1;
    [self.tableView reloadData];
    [scrollView setContentOffset:CGPointZero];
  }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
  if ( ! [self.delegate conformsToProtocol:@protocol(JTTableViewGestureAddingRowDelegate)]) {
    if ([self.tableViewDelegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)]) {
      [self.tableViewDelegate scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
    }
    return;
  }

  if (self.state == JTTableViewGestureRecognizerStateDragging) {
    self.state = JTTableViewGestureRecognizerStateNone;
    [self commitOrDiscardCell];
  }
}

#pragma mark NSProxy

- (void)forwardInvocation:(NSInvocation *)anInvocation {
  [anInvocation invokeWithTarget:self.tableViewDelegate];
}

- (NSMethodSignature*) methodSignatureForSelector:(SEL)_ { return [(NSObject *)self.tableViewDelegate methodSignatureForSelector:_]; }

- (BOOL)respondsToSelector:(SEL)_ {
  NSAssert(self.tableViewDelegate != nil, @"self.tableViewDelegate should not be nil, assign your tableView.delegate before enabling gestureRecognizer", nil);

  return [self.tableViewDelegate respondsToSelector:_] ?: [self.class instancesRespondToSelector:_];
}

#pragma mark Class method

+ (JTTableViewGestureRecognizer *)gestureRecognizerWithTableView:(UITableView *)tableView delegate:(id)delegate {
  JTTableViewGestureRecognizer *recognizer = [[JTTableViewGestureRecognizer alloc] init];
  recognizer.delegate             = (id)delegate;
  recognizer.tableView            = tableView;
  recognizer.tableViewDelegate    = tableView.delegate;     // Assign the delegate before chaning the tableView's delegate
  tableView.delegate              = recognizer;

  UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:recognizer action:@selector(pinchGestureRecognizer:)];
  [tableView addGestureRecognizer:pinch];
  pinch.delegate             = recognizer;
  recognizer.pinchRecognizer = pinch;

  UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:recognizer action:@selector(panGestureRecognizer:)];
  [tableView addGestureRecognizer:pan];
  pan.delegate             = recognizer;
  recognizer.panRecognizer = pan;

  UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:recognizer action:@selector(longPressGestureRecognizer:)];
  [tableView addGestureRecognizer:longPress];
  longPress.delegate              = recognizer;
  recognizer.longPressRecognizer  = longPress;

  return recognizer;
}

@end


@implementation UITableView (JTTableViewGestureDelegate)

- (JTTableViewGestureRecognizer *)enableGestureTableViewWithDelegate:(id)delegate {

  if (![@[@"JTTableViewGestureAddingRowDelegate", @"JTTableViewGestureEditingRowDelegate", @"JTTableViewGestureMoveRowDelegate"]
        filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {

    return [delegate conformsToProtocol:NSProtocolFromString(evaluatedObject)];

  }]].count)

    [NSException raise:@"delegate should at least conform to one of JTTableViewGestureAddingRowDelegate, JTTableViewGestureEditingRowDelegate or JTTableViewGestureMoveRowDelegate" format:nil];
  
  return [JTTableViewGestureRecognizer gestureRecognizerWithTableView:self delegate:delegate];
}

#pragma mark Helper methods

- (void)reloadVisibleRowsExceptIndexPath:(NSIndexPath *)indexPath {
  
  NSMutableArray *visibleRows = self.indexPathsForVisibleRows.mutableCopy; [visibleRows removeObject:indexPath];
  
  [self reloadRowsAtIndexPaths:visibleRows withRowAnimation:UITableViewRowAnimationNone];
}

@end