//
//  KeyboardViewController.m
//  MKBlueTooth
//
//  Created by xxl on 2017/3/14.
//  Copyright © 2017年 Monky. All rights reserved.
//

#import "KeyboardViewController.h"
#define MyDeviceName @"BT05"

@interface KeyboardViewController ()

@property (nonatomic, strong) CBCentralManager *centralMgr;
@property (nonatomic, strong) CBPeripheral *discoveredPeripheral;
@property (nonatomic, strong) CBCharacteristic *writeCharacteristic;

@end

@implementation KeyboardViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    for  (int i = 21; i <= 108; i++) {
        UIButton *btn1 =  [UIButton buttonWithType:UIButtonTypeCustom];
        btn1.tag = 10000 + i;
        btn1.backgroundColor = [UIColor redColor];
        
        int quantity = i - 21;
        int line = quantity % 20;
        int row = quantity / 20;
        
        btn1.frame = CGRectMake(60+45*line, 100+45*row, 40, 40);
        [self.view addSubview:btn1];
        [btn1 addTarget:self action:@selector(clickMethod) forControlEvents:UIControlEventTouchUpInside];
    }
}

//检查App的设备BLE是否可用 （ensure that Bluetooth low energy is supported and available to use on the central device）
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (central.state)
    {
        case CBCentralManagerStatePoweredOn:
            //discover what peripheral devices are available for your app to connect to
            //第一个参数为CBUUID的数组，需要搜索特点服务的蓝牙设备，只要每搜索到一个符合条件的蓝牙设备都会调用didDiscoverPeripheral代理方法
            [self.centralMgr scanForPeripheralsWithServices:nil options:nil];
            break;
        default:
            NSLog(@"Central Manager did change state");
            break;
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    //找到需要的蓝牙设备，停止搜素，保存数据
    NSString *localName = [advertisementData objectForKey:CBAdvertisementDataLocalNameKey];
    NSLog(@"device name:%@",localName);
    if ([localName rangeOfString:MyDeviceName options:NSCaseInsensitiveSearch].length > 0) {//[localName rangeOfString:@"BT05" options:NSCaseInsensitiveSearch].length > 0 ||
        
        _discoveredPeripheral = peripheral;
        [_centralMgr connectPeripheral:peripheral options:nil];
        [_centralMgr stopScan];
    }
}

//连接成功
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    //Before you begin interacting with the peripheral, you should set the peripheral’s delegate to ensure that it receives the appropriate callbacks（设置代理）
    [_discoveredPeripheral setDelegate:self];
    //discover all of the services that a peripheral offers,搜索服务,回调didDiscoverServices
    [_discoveredPeripheral discoverServices:nil];
    NSLog(@"connected periphheral success");
}

//连接失败，就会得到回调：
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    //此时连接发生错误
    NSLog(@"connected periphheral failed");
}

//获取服务后的回调
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error)
    {
        NSLog(@"didDiscoverServices : %@", [error localizedDescription]);
        return;
    }
    
    for (CBService *s in peripheral.services)
    {
        NSLog(@"Service found with UUID : %@", s.UUID);
        //Discovering all of the characteristics of a service,回调didDiscoverCharacteristicsForService
        [s.peripheral discoverCharacteristics:nil forService:s];
    }
}

//获取特征后的回调
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    if (error)
    {
        NSLog(@"didDiscoverCharacteristicsForService error : %@", [error localizedDescription]);
        return;
    }
    
    for (CBCharacteristic *c in service.characteristics)
    {
        NSLog(@"c.properties:%lu",(unsigned long)c.properties) ;
        //Subscribing to a Characteristic’s Value 订阅
        [peripheral setNotifyValue:YES forCharacteristic:c];
        // read the characteristic’s value，回调didUpdateValueForCharacteristic
        [peripheral readValueForCharacteristic:c];
        _writeCharacteristic = c;
    }
}

//订阅的特征值有新的数据时回调
- (void)peripheral:(CBPeripheral *)peripheral
didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error {
    if (error) {
        NSLog(@"Error changing notification state: %@",
              [error localizedDescription]);
    }
    
    [peripheral readValueForCharacteristic:characteristic];
    
}

// 获取到特征的值时回调
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSData* midiData = [characteristic value];
    NSLog(@"Midi data:%@",midiData);
    NSUInteger len = [midiData length];
    NSUInteger loopCount = len / 5;
    const unsigned char *nsdata_bytes = (unsigned char*)[midiData bytes];
    for (int i = 0; i < loopCount; i++) {
        unsigned int noteStatus = nsdata_bytes[i*5 + 2];//开始结束标志
        unsigned int noteValue = nsdata_bytes[i*5 + 3];//音符
        //        unsigned int noteVelocity = nsdata_bytes[4];//力度
        
        // 按键检查：note on(144代表按下键)接受到后，state变为1，在此基础上，相同键位的off(128代表键抬起)接收到后state变为2。
        // state为2时才代表该按键合格
        if(noteStatus == 128){
            //note off
            NSLog(@"Note off");
            if(_testKeyNumber == noteValue){
                _testKeyState = 2;
            }
            
            if(_testKeyState == 2){
                NSArray*childViews = self.view.subviews;
                for (int i = 0; i<childViews.count; i++) {
                    UIButton* btn = childViews[i];
                    if (btn.tag == 10000 + noteValue) {
                        btn.backgroundColor = [UIColor blueColor];
                    }
                }
                _testKeyState = 0;
                _testKeyNumber = 0;
            }
        }else if(noteStatus == 144){
            //note on
            NSLog(@"Note on");
            _testKeyNumber = noteValue;
            _testKeyState = 1;
        }
        
        NSLog(@"Note status:%u,note value:%u",noteStatus,noteValue);
    }
}

- (void)clickMethod{
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
