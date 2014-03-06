//
//  UITableView+NXEmptyView.m
//  TableWithEmptyView
//
//  Created by Ullrich Schäfer on 21.06.12.
//
//

#import <objc/runtime.h>

#import "UITableView+NXEmptyView.h"


static const NSString *NXEmptyViewOldInsetsKey = @"NXEmptyViewOldInsetsKey";
static const NSString *NXEmptyViewAssociatedKey = @"NXEmptyViewAssociatedKey";
static const NSString *NXEmptyViewHideSeparatorLinesAssociatedKey = @"NXEmptyViewHideSeparatorLinesAssociatedKey";
static const NSString *NXEmptyViewPreviousSeparatorStyleAssociatedKey = @"NXEmptyViewPreviousSeparatorStyleAssociatedKey";
static const NSString *NXEmptyViewPreferredHeight = @"NXEmptyViewPreferredHeight";


void nxEV_swizzle(Class c, SEL orig, SEL new)
{
    Method origMethod = class_getInstanceMethod(c, orig);
    Method newMethod = class_getInstanceMethod(c, new);
    if(class_addMethod(c, orig, method_getImplementation(newMethod), method_getTypeEncoding(newMethod)))
        class_replaceMethod(c, new, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    else
        method_exchangeImplementations(origMethod, newMethod);
}



@interface UITableView (NXEmptyViewPrivate)
@property (nonatomic, assign) UITableViewCellSeparatorStyle nxEV_previousSeparatorStyle;
@end


@implementation UITableView (NXEmptyView)

#pragma mark Entry

+ (void)load;
{
    Class c = [UITableView class];
    nxEV_swizzle(c, @selector(reloadData), @selector(nxEV_reloadData));
    nxEV_swizzle(c, @selector(layoutSubviews), @selector(nxEV_layoutSubviews));
}

#pragma mark Properties

- (BOOL)nxEV_hasRowsToDisplay;
{
    NSUInteger numberOfRows = 0;
    for (NSInteger sectionIndex = 0; sectionIndex < self.numberOfSections; sectionIndex++) {
        numberOfRows += [self numberOfRowsInSection:sectionIndex];
    }
    return (numberOfRows > 0);
}

@dynamic nxEV_emptyView;
- (UIView *)nxEV_emptyView;
{
    return objc_getAssociatedObject(self, &NXEmptyViewAssociatedKey);
}

- (void)setNxEV_emptyView:(UIView *)value;
{
    if (self.nxEV_emptyView.superview) {
        [self.nxEV_emptyView removeFromSuperview];
    }
    objc_setAssociatedObject(self, &NXEmptyViewAssociatedKey, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self nxEV_updateEmptyView];
}

@dynamic nxEV_hideSeparatorLinesWheyShowingEmptyView;
- (BOOL)nxEV_hideSeparatorLinesWheyShowingEmptyView
{
    NSNumber *hideSeparator = objc_getAssociatedObject(self, &NXEmptyViewHideSeparatorLinesAssociatedKey);
    return hideSeparator ? [hideSeparator boolValue] : NO;
}

- (void)setNxEV_hideSeparatorLinesWheyShowingEmptyView:(BOOL)value
{
    NSNumber *hideSeparator = [NSNumber numberWithBool:value];
    objc_setAssociatedObject(self, &NXEmptyViewHideSeparatorLinesAssociatedKey, hideSeparator, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@dynamic nxEV_oldInsets;
- (UIEdgeInsets)nxEV_oldInsets
{
    NSValue *value = objc_getAssociatedObject(self, &NXEmptyViewOldInsetsKey);
    return value ? [value UIEdgeInsetsValue] : UIEdgeInsetsZero;
}

- (void)setNxEV_oldInsets:(UIEdgeInsets)insets
{
    NSValue *value = [NSValue valueWithUIEdgeInsets:insets];
    objc_setAssociatedObject(self, &NXEmptyViewOldInsetsKey, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@dynamic nxEV_preferredHeight;
- (CGFloat)nxEV_preferredHeight
{
    NSNumber *value = objc_getAssociatedObject(self, &NXEmptyViewPreferredHeight);
    return value ? [value floatValue] : 0;
}

- (void)setNxEV_preferredHeight:(CGFloat)height
{
    NSNumber *value = [NSNumber numberWithFloat:height];
    objc_setAssociatedObject(self, &NXEmptyViewPreferredHeight, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark Updating

- (void)nxEV_updateEmptyView;
{
    UIView *emptyView = self.nxEV_emptyView;
    
    if (!emptyView) return;
    
    if (emptyView.superview != self) {
        [self addSubview:emptyView];
    }
    
    CGRect emptyViewFrame;
    if(self.nxEV_preferredHeight == 0){
        emptyViewFrame = self.bounds;
        emptyViewFrame = UIEdgeInsetsInsetRect(emptyViewFrame, UIEdgeInsetsMake(CGRectGetHeight(self.tableHeaderView.frame), 0, 0, 0));
        if(!UIEdgeInsetsEqualToEdgeInsets(self.nxEV_oldInsets, UIEdgeInsetsMake(self.contentInset.top-60, self.contentInset.left, self.contentInset.bottom, self.contentInset.right))){ //60 is refresh control height
            emptyViewFrame = UIEdgeInsetsInsetRect(emptyViewFrame, self.contentInset);
        } else {
            emptyViewFrame = UIEdgeInsetsInsetRect(emptyViewFrame, self.nxEV_oldInsets);
        }
        [self setNxEV_oldInsets:self.contentInset];
        emptyViewFrame.origin = CGPointMake(0, 0);
    } else {
        emptyViewFrame = CGRectMake(self.bounds.origin.x, self.tableHeaderView.frame.size.height, self.bounds.size.width, self.nxEV_preferredHeight);
    }
    emptyView.frame = emptyViewFrame;
    emptyView.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
    
    // check available data
    BOOL emptyViewShouldBeShown = (self.nxEV_hasRowsToDisplay == NO);
    BOOL emptyViewIsShown       = (!emptyView.hidden);
    
    if(emptyViewShouldBeShown){
        if(self.nxEV_preferredHeight){
            [self setContentSize:CGSizeMake(self.contentSize.width,
                                            self.tableHeaderView.frame.size.height
                                            +(self.infiniteScrollingView && self.infiniteScrollingView.enabled && !self.infiniteScrollingView.hidden? MAX(0,self.nxEV_preferredHeight-self.infiniteScrollingView.frame.size.height) : self.nxEV_preferredHeight)
                                            +self.tableFooterView.frame.size.height)];
        }
    }
    
    // check bypassing
    if (emptyViewShouldBeShown && [self.dataSource respondsToSelector:@selector(tableViewShouldBypassNXEmptyView:)]) {
        BOOL emptyViewShouldBeBypassed = [(id<UITableViewNXEmptyViewDataSource>)self.dataSource tableViewShouldBypassNXEmptyView:self];
        emptyViewShouldBeShown &= !emptyViewShouldBeBypassed;
    }
    
    if (emptyViewShouldBeShown == emptyViewIsShown) return;
    
    // hide tableView separators, if present
    if (emptyViewShouldBeShown) {
        if (self.nxEV_hideSeparatorLinesWheyShowingEmptyView) {
            self.nxEV_previousSeparatorStyle = self.separatorStyle;
            self.separatorStyle = UITableViewCellSeparatorStyleNone;
        }
    } else {
        if (self.nxEV_hideSeparatorLinesWheyShowingEmptyView) {
            self.separatorStyle = self.nxEV_previousSeparatorStyle;
        }
    }
    
    // show / hide empty view
    emptyView.hidden = !emptyViewShouldBeShown;
}


#pragma mark Swizzle methods

- (void)nxEV_reloadData;
{
    // this calls the original reloadData implementation
    [self nxEV_reloadData];
    
    [self nxEV_updateEmptyView];
}

- (void)nxEV_layoutSubviews;
{
    // this calls the original layoutSubviews implementation
    [self nxEV_layoutSubviews];
    
    [self nxEV_updateEmptyView];
}

@end


#pragma mark Private
#pragma mark -

@implementation UITableView (NXEmptyViewPrivate)

@dynamic nxEV_previousSeparatorStyle;
- (UITableViewCellSeparatorStyle)nxEV_previousSeparatorStyle
{
    NSNumber *previousSeparatorStyle = objc_getAssociatedObject(self, &NXEmptyViewPreviousSeparatorStyleAssociatedKey);
    return previousSeparatorStyle ? [previousSeparatorStyle intValue] : self.separatorStyle;
}

- (void)setNxEV_previousSeparatorStyle:(UITableViewCellSeparatorStyle)value
{
    NSNumber *previousSeparatorStyle = [NSNumber numberWithInt:value];
    objc_setAssociatedObject(self, &NXEmptyViewPreviousSeparatorStyleAssociatedKey, previousSeparatorStyle, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
