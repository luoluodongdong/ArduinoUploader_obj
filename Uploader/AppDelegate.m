//
//  AppDelegate.m
//  DevBoardTest
//
//  Created by 曹伟东 on 2019/4/11.
//  Copyright © 2019 曹伟东. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()
{
    NSArray *_comArr;
}
@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    [_window setTitle:@"ICT_Atmel32U4_FW_Uploader v1.0.0"];
    [self scanPorts];
    [self showStatus:@"READY"];
    [_testBtn setEnabled:NO];
}
-(id)init{
    self.serialPortManager = [ORSSerialPortManager sharedSerialPortManager];
    
    return self;
}
-(IBAction)scanBtnAction:(id)sender{
    
    [self scanPorts];
}
-(void)scanPorts{
    [_comPathBtn removeAllItems];
    _comArr = self.serialPortManager.availablePorts;
    NSLog(@"_comArr:%@",_comArr);
    
    [_comArr enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        ORSSerialPort *port = (ORSSerialPort *)obj;
        //printf("%lu. %s\n", (unsigned long)idx, [port.name UTF8String]);
        //[self->comPaths addItemWithObjectValue:port.name];
        [self->_comPathBtn addItemWithTitle:port.name];
    }];
    if ([_comArr count]>0) {
        [_comPathBtn selectItemAtIndex:0];
    }else{
        [self showPanel:@"Not any serial ports!"];
    }
}
-(IBAction)comPathBtnAction:(id)sender{
    NSString *item=[_comPathBtn titleOfSelectedItem];
    if (![item containsString:@"usb"]) {
        [self showPanel:@"Select serial port error!"];
        NSLog(@"error:serial name error!");
        return;
    }else{
        [_testBtn setEnabled:YES];
    }
}
-(IBAction)testBtnAction:(id)sender{
    NSNumber *index=[NSNumber numberWithInteger:[_comPathBtn indexOfSelectedItem]] ;
    [NSThread detachNewThreadSelector:@selector(testThread:) toTarget:self withObject:index];
    [self showStatus:@"WORK..."];
    [_testBtn setEnabled:NO];
}
-(NSMutableArray *)GetSerialList{
    NSString *feedback=[self cmdExe:@"ls /dev/tty.*"];
    NSLog(@"fd:%@",feedback);
    NSArray *arr=[feedback componentsSeparatedByString:@"\n"];
    NSMutableArray *r_arr=[[NSMutableArray alloc] initWithCapacity:1];
    for (int i=0; i<[arr count]; i++) {
        NSString *item=[arr objectAtIndex:i];
        if (![item isEqualToString:@""]) {
            [r_arr addObject:item];
        }
    }
    return r_arr;
}
-(void)testThread:(NSNumber *)index{
    self.serialPort=[_comArr objectAtIndex:[index intValue]];
    NSString *selectCom=self.serialPort.name;
    NSLog(@"select com:%@",selectCom);
    NSMutableArray *rawComs=[self GetSerialList];
    //NSLog(@"raw coms1:%@",rawComs);
    for (NSString *item in rawComs) {
        if ([item containsString:selectCom]) {
            [rawComs removeObject:item];
        }
    }
    
    //NSLog(@"raw coms2:%@",rawComs);
    [NSThread detachNewThreadSelector:@selector(openAndClosePort:) toTarget:self withObject:index];
    float timecount=0.0;
    float timeout = 5.0;
    bool flag_operate=false;
    while (timecount < timeout) {
        [NSThread sleepForTimeInterval:0.5];
        timecount +=0.5;
        NSMutableArray *nowComs=[self GetSerialList];
        //NSLog(@"now coms1:%@",nowComs);
        if ([rawComs count] == [nowComs count]) {
            flag_operate=true;
            break;
        }
    }
    if(!flag_operate){
        [self performSelectorOnMainThread:@selector(showPanel:) withObject:@"MCU reset FAIL!" waitUntilDone:YES];
        [self performSelectorOnMainThread:@selector(showStatus:) withObject:@"FAIL" waitUntilDone:YES];
        NSLog(@"operate1 error");
        return;
    }
    flag_operate=false;
    timecount=0.0;
    timeout=7.0;
    NSMutableArray *nowComs=[[NSMutableArray alloc] initWithCapacity:1];
    while (timecount < timeout) {
        [NSThread sleepForTimeInterval:0.5];
        timecount +=0.5;
        nowComs=[self GetSerialList];
        if ([rawComs count] == [nowComs count]) continue;
        flag_operate=true;
        break;
    }
    if(!flag_operate){
        [self performSelectorOnMainThread:@selector(showPanel:) withObject:@"MCU into DFU mode FAIL!" waitUntilDone:YES];
        [self performSelectorOnMainThread:@selector(showStatus:) withObject:@"FAIL" waitUntilDone:YES];
        NSLog(@"operate2 error");
        return;
    }
    //NSLog(@"nowComs3:%@",nowComs);
    //NSLog(@"rowComs3:%@",rawComs);
    NSString *findCom=@"";
    bool find_flag=false;
    for (int i=0; i<[nowComs count]; i++) {
        findCom=[nowComs objectAtIndex:i];
        //NSLog(@"findCom:%@",findCom);
        find_flag=false;
        for (int j=0; j<[rawComs count]; j++) {
            NSString *raw_com=[rawComs objectAtIndex:j];
            //NSLog(@"raw_com:%@",raw_com);
            if ([findCom isEqualToString:raw_com])
            {
                find_flag = true;
                break;
            }
        }
        if (!find_flag) break;
    }
    if (!find_flag) {
        NSLog(@"find dfu com:%@",findCom);
        NSString *rawfilePath=[[NSBundle mainBundle] resourcePath];
        NSString *filePath=[rawfilePath stringByAppendingString:@"/ardtool/avrdude"];
        NSLog(@"file:%@",filePath);
        NSString *arvdude_p=filePath;
        NSString *conf_p=[rawfilePath stringByAppendingString:@"/ardtool/avrdude.conf"];
        NSString *port_n=findCom;
        NSString *hex_p=[rawfilePath stringByAppendingString:@"/ardtool/HID_For_W1a_FW.hex"];
        
        NSString *cmd=[NSString stringWithFormat:@"%@ -C%@ -v -patmega32u4 -cavr109 -P%@ -b57600 -D -Uflash:w:%@:i",arvdude_p,conf_p,port_n,hex_p];
        NSLog(@"cmd:%@",cmd);
        //@"/Users/caoweidong/Documents/COMdriver/Arduino.app/Contents/Java/hardware/tools/avr/bin/avrdude -C/Users/caoweidong/Documents/COMdriver/Arduino.app/Contents/Java/hardware/tools/avr/etc/avrdude.conf -v -patmega32u4 -cavr109 -P/dev/cu.usbmodem1421 -b57600 -D -Uflash:w:/var/folders/qz/j93v1vmn2jq2th79f5m_48vr0000gn/T/arduino_build_882912/HID_For_W1a.ino.hex:i";
        NSString *log=[self cmdExe:cmd];
        //NSLog(@"log:%@",log);
        
        //10408 bytes of flash written
        //avrdude: 10408 bytes of flash verified
        NSArray *result_arr=[log componentsSeparatedByString:@"\n"];
        bool write_ok_flag=false;
        for (NSString *item in result_arr) {
            if ([item containsString:@"bytes of flash written"]) {
                write_ok_flag=true;
                break;
            }
        }
        bool verify_ok_flag=false;
        for (NSString *item in result_arr) {
            if ([item containsString:@"bytes of flash verified"]) {
                verify_ok_flag=true;
                break;
            }
        }
        if (write_ok_flag && verify_ok_flag) {
            [self performSelectorOnMainThread:@selector(showStatus:) withObject:@"PASS" waitUntilDone:NO];
            NSLog(@"=====upload successful======");
            
        }else{
            [self performSelectorOnMainThread:@selector(showStatus:) withObject:@"FAIL" waitUntilDone:YES];
            NSLog(@"=======upload fail!=========");
        }
    }else{
        [self performSelectorOnMainThread:@selector(showPanel:) withObject:@"Find MCU DFU port FAIL!" waitUntilDone:YES];
        [self performSelectorOnMainThread:@selector(showStatus:) withObject:@"FAIL" waitUntilDone:YES];
        NSLog(@"find dfu com fail");
    }
    [self performSelectorOnMainThread:@selector(scanPorts) withObject:nil waitUntilDone:NO];
}
-(void)showStatus:(NSString *)status{
    if ([status isEqualToString:@"PASS"]) {
        [_statusLB setBackgroundColor:[NSColor systemGreenColor]];
    }else if([status isEqualToString:@"FAIL"]){
        [_statusLB setBackgroundColor:[NSColor systemRedColor]];
    }else if([status isEqualToString:@"WORK..."]){
        [_statusLB setBackgroundColor:[NSColor systemYellowColor]];
    }else{
        [_statusLB setBackgroundColor:[NSColor systemBlueColor]];
    }
    [_statusLB setStringValue:status];
}
-(void)openAndClosePort:(NSNumber *)index{
    NSInteger baudRate = 1200;
    NSLog(@"baud rate is %ld",(long)baudRate);
    self.serialPort=[_comArr objectAtIndex:[index intValue]];
    self.serialPort.baudRate = @(baudRate);
    self.serialPort.usesDTRDSRFlowControl=YES;
    self.serialPort.usesRTSCTSFlowControl=YES;
    [self.serialPort open];
}

- (NSString *)cmdExe:(NSString *)cmd
{
    // 初始化并设置shell路径
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath: @"/bin/bash"];
    // -c 用来执行string-commands（命令字符串），也就说不管后面的字符串里是什么都会被当做shellcode来执行
    NSArray *arguments = [NSArray arrayWithObjects: @"-c", cmd, nil];
    [task setArguments: arguments];
    
    // 新建输出管道作为Task的输出
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    NSPipe *pipe2=[NSPipe pipe];
    [task setStandardError:pipe2];
    
    // 开始task
    NSFileHandle *file = [pipe fileHandleForReading];
    NSFileHandle *file2 = [pipe2 fileHandleForReading];
    [task launch];
    [task waitUntilExit]; //执行结束后,得到执行的结果字符串++++++
    NSData *data;
    data = [file readDataToEndOfFile];
    NSString *result_str;
    NSString *error_str=[[NSString alloc] initWithData:[file2 readDataToEndOfFile] encoding:NSUTF8StringEncoding];
    if(![error_str isEqualToString:@""]) {
        //error_flag = true;
    }
    NSLog(@"error:%@",error_str);
    result_str = [[NSString alloc] initWithData: data encoding:NSUTF8StringEncoding]; //---------------------------------
    result_str=[result_str stringByAppendingString:error_str];
    return result_str;
}
#pragma mark - ORSSerialPortDelegate Methods

- (void)serialPortWasOpened:(ORSSerialPort *)serialPort
{
    //_openBtn.title = @"Close";
}

- (void)serialPortWasClosed:(ORSSerialPort *)serialPort
{
    //_openBtn.title = @"Open";
}

- (void)serialPort:(ORSSerialPort *)serialPort didReceiveData:(NSData *)data
{
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if ([string length] == 0) return;
    //[self.receivedDataTextView.textStorage.mutableString appendString:string];
    //[self.receivedDataTextView setNeedsDisplay:YES];
    NSLog(@"rec:%@",string);
}

- (void)serialPortWasRemovedFromSystem:(ORSSerialPort *)serialPort;
{
    // After a serial port is removed from the system, it is invalid and we must discard any references to it
    self.serialPort = nil;
    //_openBtn.title = @"Open";
}

- (void)serialPort:(ORSSerialPort *)serialPort didEncounterError:(NSError *)error
{
    NSLog(@"Serial port %@ encountered an error: %@", serialPort, error);
}

#pragma mark - Properties

- (void)setSerialPort:(ORSSerialPort *)port
{
    if (port != _serialPort)
    {
        [_serialPort close];
        _serialPort.delegate = nil;
        
        _serialPort = port;
        
        _serialPort.delegate = self;
    }
}
//show information window
-(long)showPanel:(NSString *)thisEnquire{
    NSLog(@"start run panel window");
    NSAlert *theAlert=[[NSAlert alloc] init];
    [theAlert addButtonWithTitle:@"OK"]; //1000
    [theAlert setMessageText:@"Info"];
    [theAlert setInformativeText:thisEnquire];
    [theAlert setAlertStyle:0];
    //[theAlert setIcon:[NSImage imageNamed:@"Check_yes_256px.png"]];
    NSLog(@"End run panel window");
    return [theAlert runModal];
}
- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

-(void)windowShouldClose:(id)sender{
    NSLog(@"window will close...");
    [NSApp terminate:self];
}
@end

