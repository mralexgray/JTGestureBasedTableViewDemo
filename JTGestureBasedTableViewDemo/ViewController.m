  //
  //  ViewController.m
  //  JTGestureBasedTableViewDemo
  //
  //  Created by James Tang on 2/6/12.
  //  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
  //

@import AtoZTouch;

#import "ViewController.h"

@implementation ViewController

#pragma mark - View lifecycle

- (void) viewDidLoad {

  [super viewDidLoad];

  // In this example, we setup self.rows as datasource

  _rows = @[  @"Swipe to the right to complete",
              @"Swipe to left to delete",
              @"Drag down to create a new cell",
              @"Pinch two rows apart to create cell",
              @"Long hold to start reorder cell"].mutableCopy;

  // Setup your tableView.delegate and tableView.datasource, then enable gesture recognition in one line.

  self.tableViewRecognizer = [self.tableView enableGestureTableViewWithDelegate:self];

  self.tableView.backgroundColor = UIColor.blackColor;
  self.tableView.separatorStyle  = UITableViewCellSeparatorStyleNone;
  self.tableView.rowHeight       = NORMAL_CELL_FINISHING_HEIGHT;
}

#pragma mark Private Method

- (void) moveRowToBottomForIndexPath:(NSIndexPath*)ip {

  __block NSIndexPath *lastIP;

  [self.tableView update:^(UITableView *tv) {

    id object = _rows[ip.row];
    [_rows removeObjectAtIndex:ip.row];
    [_rows addObject:object];

    lastIP = [NSIndexPath indexPathForRow:_rows.count - 1 inSection:0];
    [tv moveRowAtIndexPath:ip toIndexPath:lastIP];

  }];

  [self.tableView performSelector:@selector(reloadVisibleRowsExceptIndexPath:) withObject:lastIP afterDelay:JTTableViewRowAnimationDuration];
}

#pragma mark UITableViewDatasource


TVNumRowsInSection { return _rows.count; }

TVNumSections      { return 1; }

TVCellForRowAtIP   { NSObject *object;

  UIColor *backgroundColor = [UIColor.redColor colorWithHueOffset:0.12 * ip.row /
                             [self tableView:tv numberOfRowsInSection:ip.section]];

  if ([(object = _rows[ip.row]) isEqual:ADDING_CELL]) {

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

  }

  else {

    static NSString *cellIdentifier = @"MyCell";
    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:cellIdentifier] ?: ({

      cell = [UITableViewCell.alloc initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
      cell.textLabel.adjustsFontSizeToFitWidth = YES;
      cell.textLabel.backgroundColor = UIColor.clearColor;
      cell.selectionStyle = UITableViewCellSelectionStyleNone;
      cell;

    });

    cell.textLabel.text = (NSString *)object;

    if ([object isEqual:DONE_CELL]) {

        cell.textLabel.textColor         = UIColor.grayColor;
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


#pragma mark - ADDING (JTTableViewGestureAddingRowDelegate)

GRMethod(void)    needsAddRowAtIndexPath:(NSIndexPath*)ip { [self.rows insertObject:ADDING_CELL atIndex:ip.row]; }

GRMethod(void) needsCommitRowAtIndexPath:(NSIndexPath*)ip {

  self.rows[ip.row] = @"Added!";

  JTTransformableTableViewCell *cell = (id)[gr.tableView cellForRowAtIndexPath:ip];

  BOOL isFirstCell = ip.section == 0 && ip.row == 0;

  if (isFirstCell && cell.frame.size.height > COMMITING_CREATE_CELL_HEIGHT * 2) {

    [self.rows removeObjectAtIndex:ip.row];
    [self.tableView deleteRowsAtIndexPaths:@[ip] withRowAnimation:UITableViewRowAnimationMiddle];  // Return to list

  } else {

    cell.finishedHeight = NORMAL_CELL_FINISHING_HEIGHT;
    cell.imageView.image = nil;
    cell.textLabel.text = @"Just Added!";
  }
}

GRMethod(void) needsDiscardRowAtIndexPath:(NSIndexPath*)ip { [self.rows removeObjectAtIndex:ip.row]; }

  // Uncomment to following code to disable pinch in to create cell gesture
  //- (NSIndexPath *)gestureRecognizer:(JTTableViewGestureRecognizer *)gestureRecognizer willCreateCellAtIndexPath:(NSIndexPath *)indexPath {
  //    if (indexPath.section == 0 && indexPath.row == 0) {
  //        return indexPath;
  //    }
  //    return nil;
  //}

#pragma mark JTTableViewGestureEditingRowDelegate

GRMethod(void) didEnterEditingState:(JTTableViewCellEditingState)state forRowAtIndexPath:(NSIndexPath*)ip {

  UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:ip];

  UIColor *backgroundColor = state == JTTableViewCellEditingStateMiddle
                           ? [UIColor.redColor colorWithHueOffset:0.12 * ip.row / [self tableView:self.tableView numberOfRowsInSection:ip.section]]
                           : state == JTTableViewCellEditingStateRight
                           ? UIColor.greenColor
                           : UIColor.darkGrayColor;

  cell.contentView.backgroundColor = backgroundColor;

  if ([cell isKindOfClass:JTTransformableTableViewCell.class]) ((JTTransformableTableViewCell *)cell).tintColor = backgroundColor;
}

// This is needed to be implemented to let our delegate choose whether the panning gesture should work

GRMethod(BOOL) canEditRowAtIndexPath:(NSIndexPath*)ip { return YES; }

GRMethod(void) commitEditingState:(JTTableViewCellEditingState)state forRowAtIndexPath:(NSIndexPath *)ip {

  __block NSIndexPath *rowToBeMovedToBottom = nil;

  [gr.tableView update:^(UITableView *tv) {

    state == JTTableViewCellEditingStateLeft ? // An example to discard the cell at JTTableViewCellEditingStateLeft

      [self.rows removeObjectAtIndex:ip.row], [tv deleteRowsAtIndexPaths:@[ip] withRowAnimation:UITableViewRowAnimationLeft] :

    state == JTTableViewCellEditingStateRight ? ({

        // An example to retain the cell at commiting at JTTableViewCellEditingStateRight
      self.rows[ip.row] = DONE_CELL;

      [tv reloadRowsAtIndexPaths:@[ip] withRowAnimation:UITableViewRowAnimationLeft];

      rowToBeMovedToBottom = ip;

   }) : ({  ;; });
        // JTTableViewCellEditingStateMiddle shouldn't really happen in
        // - [JTTableViewGestureDelegate gestureRecognizer:commitEditingState:forRowAtIndexPath:]

  }];


  // Row color needs update after datasource changes, reload it.
  [gr.tableView performSelector:@selector(reloadVisibleRowsExceptIndexPath:) withObject:ip
                     afterDelay:JTTableViewRowAnimationDuration];

  if (rowToBeMovedToBottom)
   [self performSelector:@selector(moveRowToBottomForIndexPath:) withObject:rowToBeMovedToBottom
              afterDelay:JTTableViewRowAnimationDuration * 2];
}

#pragma mark JTTableViewGestureMoveRowDelegate

GRMethod(BOOL) canMoveRowAtIndexPath:(NSIndexPath *)ip { return YES; }

GRMethod(void) needsCreatePlaceholderForRowAtIndexPath:(NSIndexPath*)ip {

  self.grabbedObject = self.rows[ip.row];
   self.rows[ip.row] = DUMMY_CELL;
}

GRMethod(void) needsMoveRowAtIndexPath:(NSIndexPath*)sourceIP toIndexPath:(NSIndexPath*)destinationIP {

  id object = _rows[sourceIP.row];
  [_rows removeObjectAtIndex:sourceIP.row];
//  UITableViewCell *r = [self.tableView ]
  [_rows        insertObject:object
                     atIndex:destinationIP.row];
}

GRMethod(void) needsReplacePlaceholderForRowAtIndexPath:(NSIndexPath*)ip{

  self.rows[ip.row] = self.grabbedObject;
  self.grabbedObject = nil;
}

@end
