  //
  //  ViewController.m
  //  JTGestureBasedTableViewDemo
  //
  //  Created by James Tang on 2/6/12.
  //  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
  //

@import AtoZTouch;


#import "ViewController.h"
#import "JTTransformableTableViewCell.h"
#import "JTTableViewGestureRecognizer.h"
#import "UIColor+JTGestureBasedTableViewHelper.h"

/*! Configure your viewController to conform to JTTableViewGestureEditingRowDelegate and/or JTTableViewGestureAddingRowDelegate,.
    depends on your needs !
 */

@interface ViewController () < JTTableViewGestureEditingRowDelegate,
                               JTTableViewGestureAddingRowDelegate,
                               JTTableViewGestureMoveRowDelegate    >

@property (nonatomic) NSArray *rows;
@property (nonatomic) JTTableViewGestureRecognizer *tableViewRecognizer;
@property (nonatomic) id grabbedObject;
@end

@implementation ViewController // @synthesize rows, tableViewRecognizer, grabbedObject;

#define ADDING_CELL @"Continue..."
#define DONE_CELL @"Done"
#define DUMMY_CELL @"Dummy"
#define COMMITING_CREATE_CELL_HEIGHT 60
#define NORMAL_CELL_FINISHING_HEIGHT 60

#pragma mark - View lifecycle

- (void) viewDidLoad {
  [super viewDidLoad];
    // In this example, we setup self.rows as datasource
  _rows =@[ @"Swipe to the right to complete",
            @"Swipe to left to delete",
            @"Drag down to create a new cell",
            @"Pinch two rows apart to create cell",
            @"Long hold to start reorder cell"];


    // Setup your tableView.delegate and tableView.datasource,
    // then enable gesture recognition in one line.
  _tableViewRecognizer = [self.tableView enableGestureTableViewWithDelegate:self];

  self.tableView.backgroundColor = UIColor.blackColor;
  self.tableView.separatorStyle  = UITableViewCellSeparatorStyleNone;
  self.tableView.rowHeight       = NORMAL_CELL_FINISHING_HEIGHT;
}

#pragma mark Private Method

- (void) moveRowToBottomForIndexPath:(NSIndexPath*)ip { __block NSIndexPath *lastIndexPath;

  [self.tableView update:^(UITableView *tv) {

    id object = _rows[ip.row];
    [[self mutableArrayValueForKey:@"rows"] removeObjectAtIndex:ip.row];
    [[self mutableArrayValueForKey:@"rows"] addObject:object];

    [tv moveRowAtIndexPath:ip toIndexPath:lastIndexPath = [NSIndexPath indexPathForRow:self.rows.count - 1 inSection:0]];

  }];

  [self.tableView performSelector:@selector(reloadVisibleRowsExceptIndexPath:) withObject:lastIndexPath
                       afterDelay:JTTableViewRowAnimationDuration];
}

#pragma mark UITableViewDatasource

TVNumRowsInSection { return [self.rows count]; }

TVNumSections      { return 1; }

TVCellForRowAtIP   {

  NSObject *object = (self.rows)[ip.row];
  UIColor *backgroundColor = [UIColor.redColor colorWithHueOffset:0.12 * ip.row /
                         [self tableView:tv numberOfRowsInSection:ip.section]];

  if ([object isEqual:ADDING_CELL]) {
    NSString *cellIdentifier = nil;
    JTTransformableTableViewCell *cell = nil;

      // IndexPath.row == 0 is the case we wanted to pick the pullDown style
    if (!ip.row) {

      cellIdentifier = @"PullDownTableViewCell";

      if (!(cell = [tv dequeueReusableCellWithIdentifier:cellIdentifier])) {

        cell = [JTTransformableTableViewCell transformableTableViewCellWithStyle:JTTransformableTableViewCellStylePullDown
                                                                 reuseIdentifier:cellIdentifier];
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        cell.textLabel.textColor = UIColor.whiteColor;
      }


      cell.finishedHeight = COMMITING_CREATE_CELL_HEIGHT;
      if (cell.frame.size.height > COMMITING_CREATE_CELL_HEIGHT * 2) {
        cell.imageView.image = [UIImage imageNamed:@"reload.png"];
        cell.tintColor = UIColor.blackColor;
        cell.textLabel.text = @"Return to list...";
      } else if (cell.frame.size.height > COMMITING_CREATE_CELL_HEIGHT) {
        cell.imageView.image = nil;
        cell.tintColor = backgroundColor;           // Setup tint color
        cell.textLabel.text = @"Release to create cell...";
      } else {
        cell.imageView.image = nil;
        cell.tintColor = backgroundColor; // Setup tint color
        cell.textLabel.text = @"Continue Pulling...";
      }
      cell.contentView.backgroundColor = UIColor.clearColor;
      cell.textLabel.shadowOffset = CGSizeMake(0, 1);
      cell.textLabel.shadowColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6];
      return cell;

    } else {
        // Otherwise is the case we wanted to pick the pullDown style
      cellIdentifier = @"UnfoldingTableViewCell";
      cell = [tv dequeueReusableCellWithIdentifier:cellIdentifier];

      if (cell == nil) {
        cell = [JTTransformableTableViewCell transformableTableViewCellWithStyle:JTTransformableTableViewCellStyleUnfolding
                                                                 reuseIdentifier:cellIdentifier];
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        cell.textLabel.textColor = UIColor.whiteColor;
      }

        // Setup tint color
      cell.tintColor = backgroundColor;

      cell.finishedHeight = COMMITING_CREATE_CELL_HEIGHT;
      if (cell.frame.size.height > COMMITING_CREATE_CELL_HEIGHT) {
        cell.textLabel.text = @"Release to create cell...";
      } else {
        cell.textLabel.text = @"Continue Pinching...";
      }
      cell.contentView.backgroundColor = UIColor.clearColor;
      cell.textLabel.shadowOffset = CGSizeMake(0, 1);
      cell.textLabel.shadowColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6];
      return cell;
    }

  } else {

    static NSString *cellIdentifier = @"MyCell";
    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
      cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
      cell.textLabel.adjustsFontSizeToFitWidth = YES;
      cell.textLabel.backgroundColor = UIColor.clearColor;
      cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    cell.textLabel.text = [NSString stringWithFormat:@"%@", (NSString *)object];
    if ([object isEqual:DONE_CELL]) {
      cell.textLabel.textColor = UIColor.grayColor;
      cell.contentView.backgroundColor = UIColor.darkGrayColor;
    } else if ([object isEqual:DUMMY_CELL]) {
      cell.textLabel.text = @"";
      cell.contentView.backgroundColor = UIColor.clearColor;
    } else {
      cell.textLabel.textColor = UIColor.whiteColor;
      cell.contentView.backgroundColor = backgroundColor;
    }
    cell.textLabel.shadowOffset = CGSizeMake(0, 1);
    cell.textLabel.shadowColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6];

    return cell;
  }
}

#pragma mark UITableViewDelegate

TVHeightForRowAtIP { return NORMAL_CELL_FINISHING_HEIGHT; }

TVDidSelectRowAtIP { NSLog(@"tableView:didSelectRowAtIndexPath: %@", ip); }


#pragma mark - JTTableViewGestureAddingRowDelegate

- (void) gestureRecognizer:(JTTableViewGestureRecognizer*)gRec needsAddRowAtIndexPath:(NSIndexPath*)ip {

  [[self mutableArrayValueForKey:@"rows"] insertObject:ADDING_CELL atIndex:ip.row];
}

- (void) gestureRecognizer:(JTTableViewGestureRecognizer*)gRec needsCommitRowAtIndexPath:(NSIndexPath*)ip {

  [[self mutableArrayValueForKey:@"rows"] insertObject:@"Added!"  atIndex:ip.row];

  JTTransformableTableViewCell *cell = (id)[gRec.tableView cellForRowAtIndexPath:ip];

  BOOL isFirstCell = ip.section == 0 && ip.row == 0;
  if (isFirstCell && cell.frame.size.height > COMMITING_CREATE_CELL_HEIGHT * 2) {
    [[self mutableArrayValueForKey:@"rows"] removeObjectAtIndex:ip.row];
    [self.tableView deleteRowsAtIndexPaths:@[ip] withRowAnimation:UITableViewRowAnimationMiddle];
      // Return to list
  }
  else {

    cell.finishedHeight = NORMAL_CELL_FINISHING_HEIGHT;
    cell.imageView.image = nil;
    cell.textLabel.text = @"Just Added!";
  }
}

- (void) gestureRecognizer:(JTTableViewGestureRecognizer*)gRec needsDiscardRowAtIndexPath:(NSIndexPath*)ip {

  [[self mutableArrayValueForKey:@"rows"] removeObjectAtIndex:ip.row];
}

  // Uncomment to following code to disable pinch in to create cell gesture
  //- (NSIndexPath *)gestureRecognizer:(JTTableViewGestureRecognizer *)gestureRecognizer willCreateCellAtIndexPath:(NSIndexPath *)indexPath {
  //    if (indexPath.section == 0 && indexPath.row == 0) {
  //        return indexPath;
  //    }
  //    return nil;
  //}

#pragma mark JTTableViewGestureEditingRowDelegate

- (void)gestureRecognizer:(JTTableViewGestureRecognizer *)gestureRecognizer didEnterEditingState:(JTTableViewCellEditingState)state forRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];

  UIColor *backgroundColor = nil;
  switch (state) {
    case JTTableViewCellEditingStateMiddle:
      backgroundColor = [UIColor.redColor colorWithHueOffset:0.12 * indexPath.row / [self tableView:self.tableView numberOfRowsInSection:indexPath.section]];
      break;
    case JTTableViewCellEditingStateRight:
      backgroundColor = UIColor.greenColor;
      break;
    default:
      backgroundColor = UIColor.darkGrayColor;
      break;
  }
  cell.contentView.backgroundColor = backgroundColor;
  if ([cell isKindOfClass:[JTTransformableTableViewCell class]]) {
    ((JTTransformableTableViewCell *)cell).tintColor = backgroundColor;
  }
}

  // This is needed to be implemented to let our delegate choose whether the panning gesture should work
- (BOOL)gestureRecognizer:(JTTableViewGestureRecognizer *)gestureRecognizer canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  return YES;
}

- (void)gestureRecognizer:(JTTableViewGestureRecognizer*)gRec commitEditingState:(JTTableViewCellEditingState)state forRowAtIndexPath:(NSIndexPath *)ip {

  __block NSIndexPath *rowToBeMovedToBottom = nil;

  [gRec.tableView update:^(UITableView *tv) {

    state == JTTableViewCellEditingStateLeft ? // An example to discard the cell at JTTableViewCellEditingStateLeft

      [[self mutableArrayValueForKey:@"rows"] removeObjectAtIndex:ip.row],
             [tv deleteRowsAtIndexPaths:@[ip] withRowAnimation:UITableViewRowAnimationLeft] :

    state == JTTableViewCellEditingStateRight ? ({

        // An example to retain the cell at commiting at JTTableViewCellEditingStateRight
      [[self mutableArrayValueForKey:@"rows"] insertObject:DONE_CELL atIndex:ip.row];

      [tv reloadRowsAtIndexPaths:@[ip] withRowAnimation:UITableViewRowAnimationLeft];

      rowToBeMovedToBottom = ip;

   }) : ({  ;; });
        // JTTableViewCellEditingStateMiddle shouldn't really happen in
        // - [JTTableViewGestureDelegate gestureRecognizer:commitEditingState:forRowAtIndexPath:]

  }];


  // Row color needs update after datasource changes, reload it.
  [gRec.tableView performSelector:@selector(reloadVisibleRowsExceptIndexPath:) withObject:ip afterDelay:JTTableViewRowAnimationDuration];

  if (rowToBeMovedToBottom)
   [self performSelector:@selector(moveRowToBottomForIndexPath:) withObject:rowToBeMovedToBottom afterDelay:JTTableViewRowAnimationDuration * 2];
}

#pragma mark JTTableViewGestureMoveRowDelegate

- (BOOL) gestureRecognizer:(JTTableViewGestureRecognizer *)gRec canMoveRowAtIndexPath:(NSIndexPath *)ip { return YES; }

- (void)gestureRecognizer:(JTTableViewGestureRecognizer*)gRec needsCreatePlaceholderForRowAtIndexPath:(NSIndexPath*)ip {

  self.grabbedObject = self.rows[ip.row];
  [[self mutableArrayValueForKey:@"rows"] insertObject:DUMMY_CELL atIndex:ip.row];
}

- (void)gestureRecognizer:(JTTableViewGestureRecognizer*)gRec needsMoveRowAtIndexPath:(NSIndexPath*)sourceIP
                                                                          toIndexPath:(NSIndexPath*)destinationIP {

  id object = _rows[sourceIP.row];
  [[self mutableArrayValueForKey:@"rows"] removeObjectAtIndex:sourceIP.row];
  [[self mutableArrayValueForKey:@"rows"]        insertObject:object atIndex:destinationIP.row];
}

- (void)gestureRecognizer:(JTTableViewGestureRecognizer*)gRec needsReplacePlaceholderForRowAtIndexPath:(NSIndexPath*)ip{

  [[self mutableArrayValueForKey:@"rows"] insertObject:self.grabbedObject atIndex:ip.row];
  self.grabbedObject = nil;
}

@end
