//
// Created by Jakob Vinther-Larsen on 20/03/15.
// Copyright (c) 2015 Shape A/S. All rights reserved.
//

#import "CHDDescriptionViewController.h"

@interface CHDDescriptionViewController()
@property (nonatomic, strong) UITextView *descriptionView;
@end

@implementation CHDDescriptionViewController
- (instancetype)initWithDescription:(NSString *)description {
    self = [super init];
    if(self){
        [self.view addSubview:self.descriptionView];

        [self.descriptionView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.view);
        }];

        [self.descriptionView setText:description];
    }
    return self;
}

- (UITextView*) descriptionView {
    if(!_descriptionView){
        _descriptionView = [UITextView new];
        _descriptionView.editable = NO;
        _descriptionView.scrollEnabled = YES;
        _descriptionView.contentInset = UIEdgeInsetsMake(15, 15, 15, 15);
        _descriptionView.font = [UIFont chd_fontWithFontWeight:CHDFontWeightRegular size:17];
        _descriptionView.textColor = [UIColor chd_textDarkColor];
    }
    return _descriptionView;
}

@end