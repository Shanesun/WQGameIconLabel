//
//  WQGameIconLabel.m
//  TestTextKit
//
//  Created by December on 16/3/1.
//  Copyright © 2016年 anzogame. All rights reserved.
//

#import "WQGameIconLabel.h"
#import <CoreText/CoreText.h>

@interface WQGameIconLabel ()
{
    CGFloat _fontHeigh;
}
@property(nonatomic,strong)NSMutableParagraphStyle *paragraphStyle;
@property(nonatomic,strong)NSMutableAttributedString *realAttString;
@property(nonatomic,strong)NSMutableAttributedString *iconAttString;
@property(nonatomic,strong)NSMutableArray<UIView *> *icons;
@property(nonatomic,assign)CGSize iconSize;
@property(nonatomic,assign)CTFrameRef textFrame;
@end

@implementation WQGameIconLabel
@synthesize textColor = _textColor;
@synthesize font = _font;
@synthesize lineSpace = _lineSpace;

-(instancetype)init
{
    self = [super init];
    if (self) {
        self.textFrame = NULL;
    }
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.textFrame = NULL;
    }
    return self;
}

-(instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.textFrame = NULL;
    }
    return self;
}

-(void)dealloc
{
    if (self.textFrame!=NULL) {
        CFRelease(self.textFrame);
        self.textFrame = NULL;
    }
}

-(CGSize)intrinsicContentSize
{
    if (self.textFrame==NULL) {
        return CGSizeZero;
    }else{
        CFArrayRef lines = CTFrameGetLines(self.textFrame);
        NSUInteger lineCount = CFArrayGetCount(lines);
        CGFloat maxY = 0;
#warning TODO:在字数超过最大行数的时候，直接取的最大宽度，这里如果做的细致一些的话，还是应该把每行的高度取出来比较，拿最大宽度，如果图片高度超过了行高的话，这里高度也是错的
        if (lineCount>=self.numberOfLines) {
            return CGSizeMake(self.preferredMaxLayoutWidth, self.numberOfLines*(_fontHeigh+self.lineSpace));
        }
        
        CTLineRef lastLine = CFArrayGetValueAtIndex(lines, lineCount-1);
        CGFloat worldWidth = CTLineGetOffsetForStringIndex(lastLine, 1000, NULL);
        int lastWorldIconCount = worldWidth/(self.iconSize.width+5);
        int iconCountPerLine = (self.preferredMaxLayoutWidth+5)/(self.iconSize.width+5);
        int iconLines = ((int)self.icons.count-lastWorldIconCount)/iconCountPerLine;
        if (iconLines<0) {
            iconLines = 0;
        }
        lineCount += iconLines;
        maxY = lineCount*(_fontHeigh+self.lineSpace);
        if (lineCount>=self.numberOfLines) {
            return CGSizeMake(self.preferredMaxLayoutWidth, self.numberOfLines*(_fontHeigh+self.lineSpace));
        }else if(lineCount==1){
            if (lineCount==1) {
                return CGSizeMake(worldWidth+self.icons.count*(self.iconSize.width+5), _fontHeigh+2.0);
            }
        }else{
            return CGSizeMake(self.preferredMaxLayoutWidth, maxY);
        }
    }
    return CGSizeMake(300, 60);
}
-(void)drawRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (ctx == nil)
    {
        return;
    }
    [self.backgroundColor setFill];
    CGContextSaveGState(ctx);
    CGAffineTransform transform = [self transformForCoreText];
    CGContextConcatCTM(ctx, transform);
    

    if (self.realAttString)
    {
        if (self.textFrame) {
            [self drawLessTextInFrame:self.textFrame context:ctx];
        }
    }
    CGContextRestoreGState(ctx);
}


#pragma mark - 
- (CGAffineTransform)transformForCoreText
{
    return CGAffineTransformScale(CGAffineTransformMakeTranslation(0, self.bounds.size.height), 1.f, -1.f);
}

//整体行数小于maxLine
-(void)drawLessTextInFrame:(CTFrameRef)textFrame context:(CGContextRef)context
{
    CFArrayRef lines = CTFrameGetLines(textFrame);
    NSInteger numberOfLines = self.numberOfLines;
    NSUInteger lineCount = CFArrayGetCount(lines);
    if (lineCount>numberOfLines) {
        lineCount = numberOfLines;
    }
    //5 为icon中间的间隔，这里
    CGFloat iconLines = 0;
    CGFloat iconWidth = (self.iconSize.width+5)*self.icons.count-5;
    int iconsCountPerLine = (self.preferredMaxLayoutWidth+5)/(self.iconSize.width+5);
    if (iconWidth>self.preferredMaxLayoutWidth) {
        iconLines = self.icons.count/iconsCountPerLine+(self.icons.count%iconsCountPerLine>0);
        iconWidth = (self.iconSize.width+5)*(self.icons.count%iconsCountPerLine);
    }
    
    if (iconLines+lineCount>=self.numberOfLines) {
        NSUInteger firstIconCount = self.icons.count%iconsCountPerLine;
        for (int i=0; i<lineCount-iconLines; i++) {
            CGFloat y = i*(_fontHeigh+self.lineSpace);
            CGContextSetTextPosition(context,0, self.frame.size.height-_fontHeigh - y);
            CTLineRef oneLine = CFArrayGetValueAtIndex(lines, i);
            
            if (i==lineCount-iconLines-1) {
                CGFloat worldWidth = CTLineGetOffsetForStringIndex(oneLine, 1000, NULL);
                if (worldWidth+iconWidth<self.preferredMaxLayoutWidth) {
                    firstIconCount = (self.preferredMaxLayoutWidth-worldWidth)/iconsCountPerLine;
                }
                NSAttributedString *truncatedString = [[NSAttributedString alloc]initWithString:@"\u2026"];
                CTLineRef token = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)truncatedString);
                CTLineTruncationType endType = kCTLineTruncationEnd;
                oneLine = CTLineCreateTruncatedLine(oneLine, self.preferredMaxLayoutWidth-iconWidth, endType, token);
                NSArray *firstIcons = [self.icons subarrayWithRange:NSMakeRange(0, firstIconCount)];
                for (int j=0; j<firstIcons.count; j++) {
                    UIView *oneIcon = firstIcons[j];
                    [oneIcon setFrame:CGRectMake(self.preferredMaxLayoutWidth-iconWidth+j*(self.iconSize.width+5), y+(_fontHeigh-self.iconSize.height), self.iconSize.width, self.iconSize.height)];
                    if (oneIcon.superview!=self) {
                        [self addSubview:oneIcon];
                    }
                }
            }
            CTLineDraw(oneLine, context);
        }
        NSArray *lastIcons = [self.icons subarrayWithRange:NSMakeRange(firstIconCount, self.icons.count-firstIconCount)];
        for (int i=0; i<lastIcons.count; i++) {
            UIView *oneIcon = lastIcons[i];
            [oneIcon setFrame:CGRectMake(i*(self.iconSize.width+5), (lineCount+i/iconsCountPerLine)*(_fontHeigh+self.lineSpace)+(_fontHeigh-self.iconSize.height), self.iconSize.width, self.iconSize.height)];
            if (oneIcon.superview!=self) {
                [self addSubview:oneIcon];
            }
        }
    }else{
        NSUInteger firstIconsCount = 0;
        for (int i=0; i<lineCount; i++) {
            CGFloat y = i*(_fontHeigh+self.lineSpace);
            CGContextSetTextPosition(context,0, self.frame.size.height-_fontHeigh - y);
            CTLineRef oneLine = CFArrayGetValueAtIndex(lines, i);
            if (i==lineCount-1) {
                CGFloat worldWidth = CTLineGetOffsetForStringIndex(oneLine, 1000, NULL);
                firstIconsCount = worldWidth/(self.iconSize.width+5);
                if (firstIconsCount>self.icons.count) {
                    firstIconsCount = self.icons.count;
                }
                NSArray *firstIcons = [self.icons subarrayWithRange:NSMakeRange(0, firstIconsCount)];
                for (int j=0; j<firstIcons.count; j++) {
                    UIView *oneIcon = firstIcons[j];
                    [oneIcon setFrame:CGRectMake(worldWidth+5+j*(self.iconSize.width+5), y+(_fontHeigh-self.iconSize.height), self.iconSize.width, self.iconSize.height)];
                    if (oneIcon.superview!=self) {
                        [self addSubview:oneIcon];
                    }
                }
            }
            CTLineDraw(oneLine, context);
        }
        if (firstIconsCount<self.icons.count) {
            NSArray *lastIcons = [self.icons subarrayWithRange:NSMakeRange(firstIconsCount, self.icons.count-self.icons.count%iconsCountPerLine)];
            for (int i=0; i<lastIcons.count; i++) {
                UIView *oneIcon = lastIcons[i];
                [oneIcon setFrame:CGRectMake(i*(self.iconSize.width+5), (lineCount+i/iconsCountPerLine)*(_fontHeigh+self.lineSpace)+(_fontHeigh-self.iconSize.height), self.iconSize.width, self.iconSize.height)];
                if (oneIcon.superview!=self) {
                    [self addSubview:oneIcon];
                }
            }
        }
        
    }
}

-(void)creatDrawString
{
    if (self.text==nil) {
        return;
    }
    if (_fontHeigh==0) {
        _fontHeigh = 10;
    }
    self.paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    self.paragraphStyle.lineSpacing = self.lineSpace;
    self.paragraphStyle.lineBreakMode = NSLineBreakByCharWrapping;
    self.realAttString = [[NSMutableAttributedString alloc] initWithString:self.text attributes:@{NSFontAttributeName:self.font,NSForegroundColorAttributeName:self.textColor,NSParagraphStyleAttributeName:self.paragraphStyle}];
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)self.realAttString);
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, nil,CGRectMake(0, 0, self.preferredMaxLayoutWidth, CGFLOAT_MAX));
     self.textFrame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, NULL);
    CGPathRelease(path);
    CFRelease(framesetter);
    
}

#pragma mark - public

-(void)addIconURLs:(NSArray<NSString *> *)urls withIconSize:(CGSize)iconSize
{
    self.icons = [NSMutableArray array];
    for (NSString *oneURL in urls) {
        UIView *icon = [[UIView alloc] initWithFrame:CGRectMake(0, 0, iconSize.width, iconSize.height)];
#warning test 需要加入sdwebimage的图片load
        NSLog(@"%@",oneURL);
        icon.backgroundColor = [UIColor greenColor];
        [self.icons addObject:icon];
    }
    self.iconSize = iconSize;
    [self invalidateIntrinsicContentSize];
    [self setNeedsDisplay];
    [self layoutIfNeeded];
}

#pragma mark - setter && getter

-(CGFloat)lineSpace
{
    if (_lineSpace==0) {
        _lineSpace = 3;
    }
    return _lineSpace;
}

-(void)setLineSpace:(CGFloat)lineSpace
{
    _lineSpace = lineSpace;
    self.paragraphStyle.lineSpacing = lineSpace;
    [self invalidateIntrinsicContentSize];
    [self setNeedsDisplay];
    [self layoutIfNeeded];
}
-(UIFont *)font
{
    if (_font==nil) {
        _font = [UIFont systemFontOfSize:10];
    }
    return _font;
}

-(void)setFont:(UIFont *)font
{
    _font = font;
    if (_font==nil) {
        _font = [UIFont systemFontOfSize:10];
    }
    CTFontRef fontRef = CTFontCreateWithName((CFStringRef)_font.fontName, _font.pointSize, NULL);
    if (fontRef)
    {
        _fontHeigh     = CTFontGetSize(fontRef);
        CFRelease(fontRef);
    }
    [self.realAttString removeAttribute:NSFontAttributeName range:NSMakeRange(0, self.realAttString.string.length)];
    [self.realAttString addAttribute:NSFontAttributeName value:_font range:NSMakeRange(0, self.realAttString.string.length)];
    [self invalidateIntrinsicContentSize];
    [self setNeedsDisplay];
    [self layoutIfNeeded];
}

-(UIColor *)textColor
{
    if (_textColor==nil) {
        _textColor = [UIColor blackColor];
    }
    return _textColor;
}

-(void)setTextColor:(UIColor *)textColor
{
    _textColor = textColor;
    if (_textColor==nil) {
        _textColor = [UIColor blackColor];
    }
    [self.realAttString removeAttribute:NSFontAttributeName range:NSMakeRange(0, self.realAttString.string.length)];
    [self.realAttString addAttribute:NSForegroundColorAttributeName value:_textColor range:NSMakeRange(0, self.realAttString.string.length)];
    [self.realAttString addAttributes:@{NSForegroundColorAttributeName:_textColor} range:NSMakeRange(0, self.realAttString.string.length)];
    [self setNeedsDisplay];
}

-(void)setText:(NSString *)text
{
    _text = text;
    if (_text==nil) {
        self.realAttString = nil;
    }else{
        [self creatDrawString];
    }
    [self setNeedsDisplay];
    [self layoutIfNeeded];
}

@end
