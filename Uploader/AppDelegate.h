//
//  AppDelegate.h
//  DevBoardTest
//
//  Created by 曹伟东 on 2019/4/11.
//  Copyright © 2019 曹伟东. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ORSSerialPort.h"
#import "ORSSerialPortManager.h"

@class ORSSerialPortManager;

@interface AppDelegate : NSObject <NSApplicationDelegate,ORSSerialPortDelegate>
{
    IBOutlet NSButton *_scanBtn;
    IBOutlet NSPopUpButton *_comPathBtn;
    IBOutlet NSButton *_testBtn;
    IBOutlet NSTextField *_statusLB;
    
}

-(IBAction)scanBtnAction:(id)sender;
-(IBAction)testBtnAction:(id)sender;
-(IBAction)comPathBtnAction:(id)sender;
@property (nonatomic, strong) ORSSerialPortManager *serialPortManager;
@property (nonatomic, strong) ORSSerialPort *serialPort;

@end



