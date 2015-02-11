/*
 * This file is part of the JTGestureBasedTableView package.
 * (c) James Tang <mystcolor@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <UIKit/UIKit.h>

typedef NS_ENUM(int, JTTransformableTableViewCellStyle) { JTTransformableTableViewCellStyleUnfolding,
                                                          JTTransformableTableViewCellStylePullDown
};

@protocol JTTransformableTableViewCell <NSObject>

@property (nonatomic) CGFloat   finishedHeight;
@property (nonatomic) UIColor * tintColor;   // default is white color

@end


@interface JTTransformableTableViewCell : UITableViewCell <JTTransformableTableViewCell>

// Use the factory method below instead of
//- initWithStyle:(UITableViewCellStyle)s reuseIdentifier:(NSString *)_ __attribute__((unavailable));

+ (instancetype) transformableTableViewCellWithStyle:(JTTransformableTableViewCellStyle)s
                                     reuseIdentifier:(NSString*)_;
@end


@interface JTUnfoldingTableViewCell : JTTransformableTableViewCell

@property (nonatomic) UIView *transformable1HalfView, *transformable2HalfView;

@end

@interface JTPullDownTableViewCell : JTTransformableTableViewCell

@property (nonatomic) UIView *transformableView;

@end
