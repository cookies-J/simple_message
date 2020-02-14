//
//  TYSMTableViewCell.m
//  simple_message
//
//  Created by jele lam on 12/2/2020.
//  Copyright © 2020 CookiesJ. All rights reserved.
//

#import "TYSMTableViewCell.h"
@interface TYSMTableViewCell ()
@property (weak, nonatomic) IBOutlet UILabel *rightContentLabel;
@property (weak, nonatomic) IBOutlet UILabel *leftContentLabel;


@end

@implementation TYSMTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setContent:(NSString *)contentString {
    if ([self.reuseIdentifier isEqualToString:@"kCellWithIdentifierLeft"]) {
        [self.leftContentLabel setText:contentString];
    } else {
        [self.rightContentLabel setText:contentString];
    }
}

@end
