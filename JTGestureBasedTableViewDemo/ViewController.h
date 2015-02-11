
#import <UIKit/UIKit.h>

#define ADDING_CELL @"Continue..."
#define DONE_CELL @"Done"
#define DUMMY_CELL @"Dummy"
#define COMMITING_CREATE_CELL_HEIGHT 60
#define NORMAL_CELL_FINISHING_HEIGHT 60

#import "JTTableViewGestureRecognizer.h"

/*! Configure your viewController to conform to JTTableViewGestureEditingRowDelegate and/or JTTableViewGestureAddingRowDelegate,.
    depends on your needs !
 */

@interface ViewController : UITableViewController
                          < JTTableViewGestureEditingRowDelegate,
                            JTTableViewGestureAddingRowDelegate,
                            JTTableViewGestureMoveRowDelegate >

@property (nonatomic) NSMutableArray *rows;
@property (nonatomic) JTTableViewGestureRecognizer *tableViewRecognizer;
@property (nonatomic) id grabbedObject;

@end

