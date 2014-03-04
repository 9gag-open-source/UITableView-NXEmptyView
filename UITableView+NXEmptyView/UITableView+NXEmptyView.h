//
//  UITableView+NXEmptyView.h
//  TableWithEmptyView
//
//  Created by Ullrich Schäfer on 21.06.12.
//
//

#import <UIKit/UIKit.h>

@interface UITableView (NXEmptyView)

@property (nonatomic, strong) IBOutlet UIView *nxEV_emptyView;
@property (nonatomic, assign) BOOL nxEV_hideSeparatorLinesWheyShowingEmptyView;
@property (nonatomic, assign) UIEdgeInsets nxEV_oldInsets;
@property (nonatomic, assign) CGSize nxEV_preferredSize;

@end


@protocol UITableViewNXEmptyViewDataSource <UITableViewDataSource>
@optional
- (BOOL)tableViewShouldBypassNXEmptyView:(UITableView *)tableView;
@end
