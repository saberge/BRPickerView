//
//  BRAddressPickerView.m
//  BRPickerViewDemo
//
//  Created by 任波 on 2017/8/11.
//  Copyright © 2017年 91renb. All rights reserved.
//
//  最新代码下载地址：https://github.com/91renb/BRPickerView

#import "BRAddressPickerView.h"
#import "NSBundle+BRPickerView.h"

@interface BRAddressPickerView ()<UIPickerViewDataSource, UIPickerViewDelegate>
// 地址选择器
@property (nonatomic, strong) UIPickerView *pickerView;
// 省模型数组
@property(nonatomic, copy) NSArray *provinceModelArr;
// 市模型数组
@property(nonatomic, copy) NSArray *cityModelArr;
// 区模型数组
@property(nonatomic, copy) NSArray *areaModelArr;
// 选中的省
@property(nonatomic, strong) BRProvinceModel *selectProvinceModel;
// 选中的市
@property(nonatomic, strong) BRCityModel *selectCityModel;
// 选中的区
@property(nonatomic, strong) BRAreaModel *selectAreaModel;
// 记录省选中的位置
@property(nonatomic, assign) NSInteger provinceIndex;
// 记录市选中的位置
@property(nonatomic, assign) NSInteger cityIndex;
// 记录区选中的位置
@property(nonatomic, assign) NSInteger areaIndex;

@property (nonatomic, copy) NSArray <NSString *>* mSelectValues;

@end

@implementation BRAddressPickerView

#pragma mark - 1.显示地址选择器
+ (void)showAddressPickerWithSelectIndexs:(NSArray <NSNumber *>*)selectIndexs
                              resultBlock:(BRAddressResultBlock)resultBlock {
    [self showAddressPickerWithMode:BRAddressPickerModeArea dataSource:nil selectIndexs:selectIndexs isAutoSelect:NO resultBlock:resultBlock];
}

#pragma mark - 2.显示地址选择器
+ (void)showAddressPickerWithMode:(BRAddressPickerMode)mode
                     selectIndexs:(NSArray <NSNumber *>*)selectIndexs
                     isAutoSelect:(BOOL)isAutoSelect
                      resultBlock:(BRAddressResultBlock)resultBlock {
    [self showAddressPickerWithMode:mode dataSource:nil selectIndexs:selectIndexs isAutoSelect:isAutoSelect resultBlock:resultBlock];
}


#pragma mark - 3.显示地址选择器
+ (void)showAddressPickerWithMode:(BRAddressPickerMode)mode
                       dataSource:(NSArray *)dataSource
                     selectIndexs:(NSArray <NSNumber *>*)selectIndexs
                     isAutoSelect:(BOOL)isAutoSelect
                      resultBlock:(BRAddressResultBlock)resultBlock {
    // 创建地址选择器
    BRAddressPickerView *addressPickerView = [[BRAddressPickerView alloc] initWithPickerMode:mode];
    addressPickerView.dataSourceArr = dataSource;
    addressPickerView.selectIndexs = selectIndexs;
    addressPickerView.isAutoSelect = isAutoSelect;
    addressPickerView.resultBlock = resultBlock;
    // 显示
    [addressPickerView show];
}

#pragma mark - 初始化地址选择器
- (instancetype)initWithPickerMode:(BRAddressPickerMode)pickerMode {
    if (self = [super init]) {
        self.pickerMode = pickerMode;
    }
    return self;
}

#pragma mark - 处理选择器数据
- (void)handlerPickerData {
    if (self.dataSourceArr && self.dataSourceArr.count > 0) {
        id element = [self.dataSourceArr firstObject];
        // 如果传的值是解析好的模型数组
        if ([element isKindOfClass:[BRProvinceModel class]]) {
            self.provinceModelArr = self.dataSourceArr;
        } else {
            self.provinceModelArr = [self getProvinceModelArr:self.dataSourceArr];
        }
    } else {
        // 如果外部没有传入地区数据源，就使用本地的数据源
        NSArray *dataSource = [NSBundle br_addressJsonArray];
        
        if (!dataSource || dataSource.count == 0) {
            return;
        }
        self.dataSourceArr = dataSource;
        self.provinceModelArr = [self getProvinceModelArr:self.dataSourceArr];
    }
    
    // 设置默认值
    [self handlerDefaultSelectValue];
}

#pragma mark - 获取模型数组
- (NSArray <BRProvinceModel *>*)getProvinceModelArr:(NSArray *)dataSourceArr {
    NSMutableArray *tempArr1 = [NSMutableArray array];
    for (NSDictionary *proviceDic in dataSourceArr) {
        BRProvinceModel *proviceModel = [[BRProvinceModel alloc]init];
        proviceModel.code = [proviceDic objectForKey:@"code"];
        proviceModel.name = [proviceDic objectForKey:@"name"];
        proviceModel.index = [dataSourceArr indexOfObject:proviceDic];
        NSArray *cityList = [proviceDic.allKeys containsObject:@"cityList"] ? [proviceDic objectForKey:@"cityList"] : [proviceDic objectForKey:@"citylist"];
        NSMutableArray *tempArr2 = [NSMutableArray array];
        for (NSDictionary *cityDic in cityList) {
            BRCityModel *cityModel = [[BRCityModel alloc]init];
            cityModel.code = [cityDic objectForKey:@"code"];
            cityModel.name = [cityDic objectForKey:@"name"];
            cityModel.index = [cityList indexOfObject:cityDic];
            NSArray *areaList = [cityDic.allKeys containsObject:@"areaList"] ? [cityDic objectForKey:@"areaList"] : [cityDic objectForKey:@"arealist"];
            NSMutableArray *tempArr3 = [NSMutableArray array];
            for (NSDictionary *areaDic in areaList) {
                BRAreaModel *areaModel = [[BRAreaModel alloc]init];
                areaModel.code = [areaDic objectForKey:@"code"];
                areaModel.name = [areaDic objectForKey:@"name"];
                areaModel.index = [areaList indexOfObject:areaDic];
                [tempArr3 addObject:areaModel];
            }
            cityModel.arealist = [tempArr3 copy];
            [tempArr2 addObject:cityModel];
        }
        proviceModel.citylist = [tempArr2 copy];
        [tempArr1 addObject:proviceModel];
    }
    return [tempArr1 copy];
}

#pragma mark - 设置默认选择的值
- (void)handlerDefaultSelectValue {
    __block NSString *selectProvinceName = nil;
    __block NSString *selectCityName = nil;
    __block NSString *selectAreaName = nil;
    
    if (self.mSelectValues.count > 0) {
        selectProvinceName = self.mSelectValues.count > 0 ? self.mSelectValues[0] : nil;
        selectCityName = self.mSelectValues.count > 1 ? self.mSelectValues[1] : nil;
        selectAreaName = self.mSelectValues.count > 2 ? self.mSelectValues[2] : nil;
    }
    
    if (self.pickerMode == BRAddressPickerModeProvince || self.pickerMode == BRAddressPickerModeCity || self.pickerMode == BRAddressPickerModeArea) {
        if (self.selectIndexs.count > 0) {
            NSInteger provinceIndex = [self.selectIndexs[0] integerValue];
            self.provinceIndex = (provinceIndex > 0 && provinceIndex < self.provinceModelArr.count) ? provinceIndex : 0;
            self.selectProvinceModel = self.provinceModelArr.count > self.provinceIndex ? self.provinceModelArr[self.provinceIndex] : nil;
        } else {
            @weakify(self)
            [self.provinceModelArr enumerateObjectsUsingBlock:^(BRProvinceModel *  _Nonnull model, NSUInteger idx, BOOL * _Nonnull stop) {
                @strongify(self)
                if (selectProvinceName && [model.name isEqualToString:selectProvinceName]) {
                    self.provinceIndex = idx;
                    self.selectProvinceModel = model;
                    *stop = YES;
                }
                if (idx == self.provinceModelArr.count - 1) {
                    self.provinceIndex = 0;
                    self.selectProvinceModel = self.provinceModelArr.count > 0 ? self.provinceModelArr[0] : nil;
                }
            }];
        }
    }
    
    if (self.pickerMode == BRAddressPickerModeCity || self.pickerMode == BRAddressPickerModeArea) {
        self.cityModelArr = [self getCityModelArray:self.provinceIndex];
        if (self.selectIndexs.count > 0) {
            NSInteger cityIndex = self.selectIndexs.count > 1 ? [self.selectIndexs[1] integerValue] : 0;
            self.cityIndex = (cityIndex > 0 && cityIndex < self.cityModelArr.count) ? cityIndex : 0;
            self.selectCityModel = self.cityModelArr.count > self.cityIndex ? self.cityModelArr[self.cityIndex] : nil;
        } else {
            @weakify(self)
            [self.cityModelArr enumerateObjectsUsingBlock:^(BRCityModel *  _Nonnull model, NSUInteger idx, BOOL * _Nonnull stop) {
                @strongify(self)
                if (selectCityName && [model.name isEqualToString:selectCityName]) {
                    self.cityIndex = idx;
                    self.selectCityModel = model;
                    *stop = YES;
                }
                if (idx == self.cityModelArr.count - 1) {
                    self.cityIndex = 0;
                    self.selectCityModel = self.cityModelArr.count > 0 ? self.cityModelArr[0] : nil;
                }
            }];
        }
    }
    
    if (self.pickerMode == BRAddressPickerModeArea) {
        self.areaModelArr = [self getAreaModelArray:self.provinceIndex cityIndex:self.cityIndex];
        if (self.selectIndexs.count > 0) {
            NSInteger areaIndex = self.selectIndexs.count > 2 ? [self.selectIndexs[2] integerValue] : 0;
            self.areaIndex = (areaIndex > 0 && areaIndex < self.areaModelArr.count) ? areaIndex : 0;
            self.selectAreaModel = self.areaModelArr.count > self.areaIndex ? self.areaModelArr[self.areaIndex] : nil;
        } else {
            @weakify(self)
            [self.areaModelArr enumerateObjectsUsingBlock:^(BRAreaModel *  _Nonnull model, NSUInteger idx, BOOL * _Nonnull stop) {
                @strongify(self)
                if (selectAreaName && [model.name isEqualToString:selectAreaName]) {
                    self.areaIndex = idx;
                    self.selectAreaModel = model;
                    *stop = YES;
                }
                if (idx == self.areaModelArr.count - 1) {
                    self.areaIndex = 0;
                    self.selectAreaModel = self.areaModelArr.count > 0 ? self.areaModelArr[0] : nil;
                }
            }];
        }
    }
    
    // 注意必须先刷新UI，再设置默认滚动
    [self.pickerView reloadAllComponents];
    
    // 滚动到指定行
    if (self.pickerMode == BRAddressPickerModeProvince) {
        [self.pickerView selectRow:self.provinceIndex inComponent:0 animated:YES];
    } else if (self.pickerMode == BRAddressPickerModeCity) {
        [self.pickerView selectRow:self.provinceIndex inComponent:0 animated:YES];
        [self.pickerView selectRow:self.cityIndex inComponent:1 animated:YES];
    } else if (self.pickerMode == BRAddressPickerModeArea) {
        [self.pickerView selectRow:self.provinceIndex inComponent:0 animated:YES];
        [self.pickerView selectRow:self.cityIndex inComponent:1 animated:YES];
        [self.pickerView selectRow:self.areaIndex inComponent:2 animated:YES];
    }
}

// 根据 省索引 获取 城市模型数组
- (NSArray *)getCityModelArray:(NSInteger)provinceIndex {
    BRProvinceModel *provinceModel = self.provinceModelArr[provinceIndex];
    // 返回城市模型数组
    return provinceModel.citylist;
}

// 根据 省索引和城市索引 获取 区域模型数组
- (NSArray *)getAreaModelArray:(NSInteger)provinceIndex cityIndex:(NSInteger)cityIndex {
    BRProvinceModel *provinceModel = self.provinceModelArr[provinceIndex];
    if (provinceModel.citylist && provinceModel.citylist.count > 0) {
        BRCityModel *cityModel = provinceModel.citylist[cityIndex];
        // 返回地区模型数组
        return cityModel.arealist;
    } else {
        return nil;
    }
}

#pragma mark - 地址选择器
- (UIPickerView *)pickerView {
    if (!_pickerView) {
        _pickerView = [[UIPickerView alloc]initWithFrame:CGRectMake(0, self.pickerStyle.titleBarHeight, SCREEN_WIDTH, self.pickerStyle.pickerHeight)];
        _pickerView.backgroundColor = self.pickerStyle.pickerColor;
        _pickerView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth;
        _pickerView.dataSource = self;
        _pickerView.delegate = self;
        _pickerView.showsSelectionIndicator = YES;
    }
    return _pickerView;
}


#pragma mark - UIPickerViewDataSource
// 1.指定pickerview有几个表盘(几列)
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    switch (self.pickerMode) {
        case BRAddressPickerModeProvince:
            return 1;
            break;
        case BRAddressPickerModeCity:
            return 2;
            break;
        case BRAddressPickerModeArea:
            return 3;
            break;
            
        default:
            break;
    }
}

// 2.指定每个表盘上有几行数据
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if (component == 0) {
        // 返回省个数
        return self.provinceModelArr.count;
    }
    if (component == 1) {
        // 返回市个数
        return self.cityModelArr.count;
    }
    if (component == 2) {
        // 返回区个数
        return self.areaModelArr.count;
    }
    return 0;
    
}

#pragma mark - UIPickerViewDelegate
// 3.设置 pickerView 的 显示内容
- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(nullable UIView *)view {
    
    // 设置分割线的颜色
    for (UIView *subView in pickerView.subviews) {
        if (subView && [subView isKindOfClass:[UIView class]] && subView.frame.size.height <= 1) {
            subView.backgroundColor = self.pickerStyle.separatorColor;
        }
    }
    
    UILabel *label = (UILabel *)view;
    if (!label) {
        label = [[UILabel alloc]init];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = self.pickerStyle.pickerTextFont;
        label.textColor = self.pickerStyle.pickerTextColor;
        // 字体自适应属性
        label.adjustsFontSizeToFitWidth = YES;
        // 自适应最小字体缩放比例
        label.minimumScaleFactor = 0.5f;
    }
    if (component == 0) {
        BRProvinceModel *model = self.provinceModelArr[row];
        label.text = model.name;
    } else if (component == 1) {
        BRCityModel *model = self.cityModelArr[row];
        label.text = model.name;
    } else if (component == 2) {
        BRAreaModel *model = self.areaModelArr[row];
        label.text = model.name;
    }
    
    return label;
}

// 4.选中时回调的委托方法，在此方法中实现省份和城市间的联动
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (component == 0) { // 选择省
        // 保存选择的省份的索引
        self.provinceIndex = row;
        switch (self.pickerMode) {
            case BRAddressPickerModeProvince:
            {
                self.selectProvinceModel = self.provinceModelArr.count > self.provinceIndex ? self.provinceModelArr[self.provinceIndex] : nil;
                self.selectCityModel = nil;
                self.selectAreaModel = nil;
            }
                break;
            case BRAddressPickerModeCity:
            {
                self.cityModelArr = [self getCityModelArray:self.provinceIndex];
                [self.pickerView reloadComponent:1];
                [self.pickerView selectRow:0 inComponent:1 animated:YES];
                self.selectProvinceModel = self.provinceModelArr.count > self.provinceIndex ? self.provinceModelArr[self.provinceIndex] : nil;
                self.selectCityModel = self.cityModelArr.count > 0 ? self.cityModelArr[0] : nil;
                self.selectAreaModel = nil;
            }
                break;
            case BRAddressPickerModeArea:
            {
                self.cityModelArr = [self getCityModelArray:self.provinceIndex];
                self.areaModelArr = [self getAreaModelArray:self.provinceIndex cityIndex:0];
                [self.pickerView reloadComponent:1];
                [self.pickerView selectRow:0 inComponent:1 animated:YES];
                [self.pickerView reloadComponent:2];
                [self.pickerView selectRow:0 inComponent:2 animated:YES];
                self.selectProvinceModel = self.provinceModelArr.count > self.provinceIndex ? self.provinceModelArr[self.provinceIndex] : nil;
                self.selectCityModel = self.cityModelArr.count > 0 ? self.cityModelArr[0] : nil;
                self.selectAreaModel = self.areaModelArr.count > 0 ? self.areaModelArr[0] : nil;
            }
                break;
            default:
                break;
        }
    }
    if (component == 1) { // 选择市
        // 保存选择的城市的索引
        self.cityIndex = row;
        switch (self.pickerMode) {
            case BRAddressPickerModeCity:
            {
                self.selectCityModel = self.cityModelArr.count > self.cityIndex ? self.cityModelArr[self.cityIndex] : nil;
                self.selectAreaModel = nil;
            }
                break;
            case BRAddressPickerModeArea:
            {
                self.areaModelArr = [self getAreaModelArray:self.provinceIndex cityIndex:self.cityIndex];
                [self.pickerView reloadComponent:2];
                [self.pickerView selectRow:0 inComponent:2 animated:YES];
                self.selectCityModel = self.cityModelArr.count > self.cityIndex ? self.cityModelArr[self.cityIndex] : nil;
                self.selectAreaModel = self.areaModelArr.count > 0 ? self.areaModelArr[0] : nil;
            }
                break;
            default:
                break;
        }
    }
    if (component == 2) { // 选择区
        // 保存选择的地区的索引
        self.areaIndex = row;
        if (self.pickerMode == BRAddressPickerModeArea) {
            self.selectAreaModel = self.areaModelArr.count > self.areaIndex ? self.areaModelArr[self.areaIndex] : nil;
        }
    }
    
    // 滚动选择时执行 changeBlock
    if (self.changeBlock) {
        self.changeBlock(self.selectProvinceModel, self.selectCityModel, self.selectAreaModel);
    }
    
    // 设置自动选择时，滚动选择时就执行 resultBlock
    if (self.isAutoSelect) {
        if (self.resultBlock) {
            self.resultBlock(self.selectProvinceModel, self.selectCityModel, self.selectAreaModel);
        }
    }
}

// 设置行高
- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
    return self.pickerStyle.rowHeight;
}

#pragma mark - 重写父类方法
- (void)addPickerToView:(UIView *)view {
    // 添加地址选择器
    if (view) {
        // 立即刷新容器视图 view 的布局（防止 view 使用自动布局时，选择器视图无法正常显示）
        [view setNeedsLayout];
        [view layoutIfNeeded];
        
        self.frame = view.bounds;
        self.pickerView.frame = view.bounds;
        [self addSubview:self.pickerView];
    } else {
        [self.alertView addSubview:self.pickerView];
    }
    
    [self handlerPickerData];
    
    __weak typeof(self) weakSelf = self;
    self.doneBlock = ^{
        // 点击确定按钮后，执行block回调
        [weakSelf removePickerFromView:view];
        
        if (weakSelf.resultBlock) {
            weakSelf.resultBlock(weakSelf.selectProvinceModel, weakSelf.selectCityModel, weakSelf.selectAreaModel);
        }
    };
    
    [super addPickerToView:view];
}

#pragma mark - 重写父类方法
- (void)addSubViewToPicker:(UIView *)customView {
    [self.pickerView addSubview:customView];
}

#pragma mark - 弹出选择器视图
- (void)show {
    [self addPickerToView:nil];
}

#pragma mark - 关闭选择器视图
- (void)dismiss {
    [self removePickerFromView:nil];
}

#pragma mark - setter方法
- (void)setPickerMode:(BRAddressPickerMode)pickerMode {
    _pickerMode = pickerMode;
    if (_pickerView) {
        [self handlerDefaultSelectValue];
    }
}

- (void)setSelectValues:(NSArray<NSString *> *)selectValues {
    self.mSelectValues = selectValues;
}

#pragma mark - getter方法
- (NSArray *)provinceModelArr {
    if (!_provinceModelArr) {
        _provinceModelArr = [NSArray array];
    }
    return _provinceModelArr;
}

- (NSArray *)cityModelArr {
    if (!_cityModelArr) {
        _cityModelArr = [NSArray array];
    }
    return _cityModelArr;
}

- (NSArray *)areaModelArr {
    if (!_areaModelArr) {
        _areaModelArr = [NSArray array];
    }
    return _areaModelArr;
}

- (BRProvinceModel *)selectProvinceModel {
    if (!_selectProvinceModel) {
        _selectProvinceModel = [[BRProvinceModel alloc]init];
    }
    return _selectProvinceModel;
}

- (BRCityModel *)selectCityModel {
    if (!_selectCityModel) {
        _selectCityModel = [[BRCityModel alloc]init];
        _selectCityModel.code = @"";
        _selectCityModel.name = @"";
    }
    return _selectCityModel;
}

- (BRAreaModel *)selectAreaModel {
    if (!_selectAreaModel) {
        _selectAreaModel = [[BRAreaModel alloc]init];
        _selectAreaModel.code = @"";
        _selectAreaModel.name = @"";
    }
    return _selectAreaModel;
}

- (NSArray *)dataSourceArr {
    if (!_dataSourceArr) {
        _dataSourceArr = [NSArray array];
    }
    return _dataSourceArr;
}

- (NSArray<NSString *> *)mSelectValues {
    if (!_mSelectValues) {
        _mSelectValues = [NSArray array];
    }
    return _mSelectValues;
}

- (NSArray<NSNumber *> *)selectIndexs {
    if (!_selectIndexs) {
        _selectIndexs = [NSArray array];
    }
    return _selectIndexs;
}

@end
