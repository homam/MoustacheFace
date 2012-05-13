//
//  MasksTableView.h
//  MoustacheFace
//
//  Created by Homam Hosseini on 5/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MasksTableView : UITableView <UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, weak) NSDictionary* maskImagesDic;

@end
