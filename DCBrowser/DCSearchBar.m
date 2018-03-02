//
//  DCSearchBar.m
//  DCBrowser
//
//  Created by cheyr on 2018/1/31.
//  Copyright © 2018年 cheyr. All rights reserved.
//

#import "DCSearchBar.h"
#import "UIImage+Tool.h"

#define RGB(r, g, b) [UIColor colorWithRed:((r) / 255.0) green:((g) / 255.0) blue:((b) / 255.0) alpha:1.0]

@interface DCSearchBar () <UITextFieldDelegate>

// placeholder 和icon 和 间隙的整体宽度
@property (nonatomic, assign) CGFloat placeholderWidth;
@property (nonatomic,assign) CGFloat textWidth;
@property (nonatomic,copy) NSString *tfText;

@end

// icon宽度
static CGFloat const searchIconW = 20.0;
// icon与placeholder间距
static CGFloat const iconSpacing = 10.0;
// 占位文字的字体大小
static CGFloat const placeHolderFont = 15.0;

static CGFloat const textFont = 15.0;

@implementation DCSearchBar


- (void)layoutSubviews {
    [super layoutSubviews];
    // 设置背景图片
    UIImage *backImage = [UIImage imageWithColor:[UIColor colorWithRed:239/255.0 green:239/255.0 blue:244/255.0 alpha:1]];
    [self setBackgroundImage:backImage];
    for (UIView *view in [self.subviews lastObject].subviews) {
        if ([view isKindOfClass:[UITextField class]]) {
            UITextField *field = (UITextField *)view;
            // 重设field的frame
            field.frame = CGRectMake(15.0, 7.5, self.frame.size.width-30.0, self.frame.size.height-15.0);
            [field setBackgroundColor:RGB(246, 246, 246)];
            field.textColor = [UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1];
            field.font = [UIFont systemFontOfSize:textFont];
            field.borderStyle = UITextBorderStyleNone;
            field.layer.cornerRadius = 10.0f;
            field.layer.masksToBounds = YES;
            self.tfText = field.text;
            
            // 设置占位文字字体颜色
            [field setValue:[UIColor colorWithRed:156/255.0 green:156/255.0 blue:156/255.0 alpha:1] forKeyPath:@"_placeholderLabel.textColor"];
            [field setValue:[UIFont systemFontOfSize:placeHolderFont] forKeyPath:@"_placeholderLabel.font"];
            
            if (@available(iOS 11.0, *)) {
                // 先默认居中placeholder
                [self setPositionAdjustment:UIOffsetMake((field.frame.size.width-self.placeholderWidth)/2, 0) forSearchBarIcon:UISearchBarIconSearch];
            }
        }
    }
}

// 开始编辑的时候重置为靠左
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    // 继续传递代理方法
    if ([self.delegate respondsToSelector:@selector(searchBarShouldBeginEditing:)]) {
        [self.delegate searchBarShouldBeginEditing:self];
    }
    if (@available(iOS 11.0, *)) {
            [self setPositionAdjustment:UIOffsetZero forSearchBarIcon:UISearchBarIconSearch];
    }
    return YES;
}
// 结束编辑的时候设置为居中
- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    if ([self.delegate respondsToSelector:@selector(searchBarShouldEndEditing:)]) {
        [self.delegate searchBarShouldEndEditing:self];
    }
    if (@available(iOS 11.0, *)) {
        if(textField.text.length > 0 )
        {
            [self setPositionAdjustment:UIOffsetMake((textField.frame.size.width-self.textWidth)/2, 0) forSearchBarIcon:UISearchBarIconSearch];
        }else
        {
            [self setPositionAdjustment:UIOffsetMake((textField.frame.size.width-self.placeholderWidth)/2, 0) forSearchBarIcon:UISearchBarIconSearch];
        }

    }
    return YES;
}

// 计算placeholder、icon、icon和placeholder间距的总宽度
- (CGFloat)placeholderWidth {
    if (!_placeholderWidth) {
        CGSize size = [self.placeholder boundingRectWithSize:CGSizeMake(MAXFLOAT, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:placeHolderFont]} context:nil].size;
        _placeholderWidth = size.width + iconSpacing + searchIconW;
    }
    return _placeholderWidth;
}
- (CGFloat)textWidth
{
    CGSize size = [self.tfText boundingRectWithSize:CGSizeMake(MAXFLOAT, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:textFont]} context:nil].size;
        _textWidth = size.width + searchIconW +iconSpacing;
    return _textWidth;
}
@end
