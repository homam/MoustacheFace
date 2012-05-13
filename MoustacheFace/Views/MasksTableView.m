//
//  MasksTableView.m
//  MoustacheFace
//
//  Created by Homam Hosseini on 5/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MasksTableView.h"
#import "MasksTableViewCell.h"

@implementation MasksTableView



-(id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Initialization code
        UITableView * s = (UITableView *) self;
        s.delegate = self;
    }
    return self;
}

@synthesize maskImagesDic  = _maskImagesDic;
-(void)setMaskImagesDic:(NSDictionary *)maskImagesDic{
    _maskImagesDic = maskImagesDic;
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.maskImagesDic.allKeys.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    MasksTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    //cell.textLabel.text = [self.maskImagesDic.allKeys objectAtIndex:indexPath.row];
    cell.maskImageView.image = [self.maskImagesDic objectForKey:[self.maskImagesDic.allKeys objectAtIndex:indexPath.row]];
    
    return cell;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
