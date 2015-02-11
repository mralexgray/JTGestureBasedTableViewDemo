/*
 * This file is part of the JTGestureBasedTableView package.
 * (c) James Tang <mystcolor@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "JTTransformableTableViewCell.h"
#import "UIColor+JTGestureBasedTableViewHelper.h"
#import <QuartzCore/QuartzCore.h>


#pragma mark -

@implementation JTUnfoldingTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
  if (!(self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) return nil;

  CATransform3D transform = CATransform3DIdentity;
            transform.m34 = -1/500.f;

  self.contentView.layer.sublayerTransform = transform;

  _transformable1HalfView = [UIView.alloc initWithFrame:self.contentView.bounds];
  _transformable1HalfView.layer.anchorPoint = CGPointMake(0.5, 0.0);
  _transformable1HalfView.clipsToBounds = YES;
  [self.contentView addSubview:self.transformable1HalfView];

  _transformable2HalfView = [UIView.alloc initWithFrame:self.contentView.bounds];
  _transformable2HalfView.layer.anchorPoint = CGPointMake(0.5, 1.0);
  _transformable2HalfView.clipsToBounds = YES;
  [self.contentView addSubview:self.transformable2HalfView];

  self.selectionStyle = UITableViewCellSelectionStyleNone;

  self.textLabel.autoresizingMask = UIViewAutoresizingNone;
  self.textLabel.backgroundColor = UIColor.clearColor;
  self.detailTextLabel.autoresizingMask = UIViewAutoresizingNone;
  self.detailTextLabel.backgroundColor = UIColor.clearColor;

  self.tintColor = UIColor.whiteColor;
  return self;
}

- (void)layoutSubviews
{
  [super layoutSubviews];

  CGFloat fraction = MAX(MIN(1, (self.frame.size.height / self.finishedHeight)), 0);

  CGFloat angle = (M_PI / 2) - asinf(fraction);


  _transformable1HalfView.layer.transform = CATransform3DMakeRotation(angle, -1, 0, 0);
  _transformable2HalfView.layer.transform = CATransform3DMakeRotation(angle, 1, 0, 0);

  self.transformable1HalfView.backgroundColor = [self.tintColor colorWithBrightness:0.3 + 0.7*fraction];
  self.transformable2HalfView.backgroundColor = [self.tintColor colorWithBrightness:0.5 + 0.5*fraction];

  CGSize  contentViewSize = self.contentView.frame.size;
  CGFloat contentViewMidY = contentViewSize.height / 2,
              labelHeight = self.finishedHeight    / 2;

  // OPTI: Always accomodate 1 px to the top label to ensure two labels
  // won't display one px gap in between sometimes for certain angles
  self.transformable1HalfView.frame = CGRectMake(0, contentViewMidY - (labelHeight * fraction),
                                                 contentViewSize.width, labelHeight + 1);
  self.transformable2HalfView.frame = CGRectMake(0, contentViewMidY - (labelHeight * (1 - fraction)),
                                                 contentViewSize.width, labelHeight);

  if ([self.textLabel.text length]) {
    self.detailTextLabel.text = self.textLabel.text;
    self.detailTextLabel.font = self.textLabel.font;
    self.detailTextLabel.textColor = self.textLabel.textColor;
    self.detailTextLabel.textAlignment = self.textLabel.textAlignment;
    self.detailTextLabel.textColor = UIColor.whiteColor;
    self.detailTextLabel.shadowColor = self.textLabel.shadowColor;
    self.detailTextLabel.shadowOffset = self.textLabel.shadowOffset;
  }
  self.textLabel.frame = CGRectMake(10.0, 0.0, contentViewSize.width - 20.0, self.finishedHeight);
  self.detailTextLabel.frame = CGRectMake(10.0, -self.finishedHeight / 2, contentViewSize.width - 20.0, self.finishedHeight);
}

- (UILabel *)textLabel {

  if (super.textLabel.superview != self.transformable1HalfView) [self.transformable1HalfView addSubview:super.textLabel];
  return super.textLabel;
}

- (UILabel *)detailTextLabel {

  if (super.detailTextLabel.superview != self.transformable2HalfView) [self.transformable2HalfView addSubview:super.detailTextLabel];
  return super.detailTextLabel;
}

- (UIImageView *)imageView {

  if (super.imageView.superview != self.transformable1HalfView) [self.transformable1HalfView addSubview:super.imageView];
  return super.imageView;
}

@end

@implementation JTPullDownTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
  if (!(self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) return nil;

  CATransform3D transform = CATransform3DIdentity;
            transform.m34 = -1/500.f;

  [self.contentView.layer setSublayerTransform:transform];

  _transformableView                    = [UIView.alloc initWithFrame:self.contentView.bounds];
  _transformableView.autoresizingMask   = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  _transformableView.layer.anchorPoint  = CGPointMake(0.5, 1.0);

  [self.contentView addSubview:_transformableView];

  self.selectionStyle             = UITableViewCellSelectionStyleNone;
  self.textLabel.autoresizingMask = UIViewAutoresizingNone;
  self.textLabel.backgroundColor  = UIColor.clearColor;

  self.tintColor = UIColor.whiteColor;
  return self;
}

- (UILabel *)textLabel
{
  UILabel *label = super.textLabel;
  return label.superview != self.transformableView ? [self.transformableView addSubview:label], label : label;
}

- (UILabel *)detailTextLabel
{
  UILabel *label = super.detailTextLabel;
  return label.superview != self.transformableView ? [self.transformableView addSubview:label], label : label;
}

- (UIImageView *)imageView {

  UIImageView *imageView = super.imageView;
  return imageView.superview != self.transformableView ? [self.transformableView addSubview:imageView], imageView : imageView;
}

- (void)layoutSubviews
{
  [super layoutSubviews];

  CGFloat fraction = (self.frame.size.height / self.finishedHeight);
  fraction = MAX(MIN(1, fraction), 0);

  CGFloat angle = (M_PI / 2) - asinf(fraction);
  CATransform3D transform = CATransform3DMakeRotation(angle, 1, 0, 0);
  [self.transformableView setFrame:self.contentView.bounds];
  [self.transformableView.layer setTransform:transform];
  self.transformableView.backgroundColor = [self.tintColor colorWithBrightness:0.3 + 0.7*fraction];

  CGSize contentViewSize = self.contentView.frame.size;

    // OPTI: Always accomodate 1 px to the top label to ensure two labels
    // won't display one px gap in between sometimes for certain angles
  self.transformableView.frame = CGRectMake(0.0, contentViewSize.height - self.finishedHeight,
                                            contentViewSize.width, self.finishedHeight);


  CGSize requiredLabelSize;

    // Since sizeWithFont() method has been depreciated, boundingRectWithSize() method has been used for iOS 7.
  if ([NSString instancesRespondToSelector:@selector(boundingRectWithSize:options:attributes:context:)]) {
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    paragraphStyle.lineBreakMode = NSLineBreakByClipping;
    CGRect requiredLabelRect = [self.textLabel.text boundingRectWithSize:contentViewSize
                                                                 options:NSStringDrawingUsesLineFragmentOrigin
                                                              attributes:@{NSFontAttributeName:self.textLabel.font,
                                                                           NSParagraphStyleAttributeName: paragraphStyle}
                                                                 context:nil];

    requiredLabelSize = requiredLabelRect.size;

  } else {

//  CGSize size = [self.textLabel.text sizeWithAttributes:@{NSFontAttributeName: self.textLabel.font}];

  // Values are fractional -- you should take the ceilf to get equivalent values
//  CGSize adjustedSize = CGSizeMake(ceilf(size.width), ceilf(size.height));

//    requiredLabelSize = adjustedSize; //[self.textLabel.text sizeWithFont:self.textLabel.font
                                       // constrainedToSize:contentViewSize
                                         //   lineBreakMode:NSLineBreakByClipping];

  NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:self.textLabel.text attributes:@{NSFontAttributeName:self.textLabel.font}];
  CGRect rect = [attributedText boundingRectWithSize:contentViewSize
                                           options:NSStringDrawingTruncatesLastVisibleLine // NSStringDrawingUsesLineFragmentOrigin
                                           context:nil];
    requiredLabelSize = (CGSize){ ceilf(rect.size.width),ceilf(rect.size.height)};

  }

  self.imageView.frame = CGRectMake(10.0 + requiredLabelSize.width + 10.0,
                                    (self.finishedHeight - self.imageView.frame.size.height)/2,
                                    self.imageView.frame.size.width,
                                    self.imageView.frame.size.height);

  self.textLabel.frame = CGRectMake(10.0, 0.0, contentViewSize.width - 20.0, self.finishedHeight);
}

@end

#define MAKE_WITH_STYLE_ID(STYLE,X)   (id)[JTPullDownTableViewCell.alloc initWithStyle:STYLE reuseIdentifier:X]

@implementation JTTransformableTableViewCell @synthesize finishedHeight, tintColor;

+ (instancetype)unfoldingTableViewCellWithReuseIdentifier:(NSString *)reuseIdentifier {

  return MAKE_WITH_STYLE_ID(UITableViewCellStyleSubtitle,reuseIdentifier);
}

+ (instancetype) pullDownTableViewCellWithReuseIdentifier:(NSString *)reuseIdentifier {

  return MAKE_WITH_STYLE_ID(UITableViewCellStyleDefault,reuseIdentifier);
}

+ (instancetype) transformableTableViewCellWithStyle:(JTTransformableTableViewCellStyle)_ reuseIdentifier:(NSString *)reuseID {

  return _ == JTTransformableTableViewCellStylePullDown  ? [self.class  pullDownTableViewCellWithReuseIdentifier:reuseID] :
         _ == JTTransformableTableViewCellStyleUnfolding ? [self.class unfoldingTableViewCellWithReuseIdentifier:reuseID] : nil;
}

@end
