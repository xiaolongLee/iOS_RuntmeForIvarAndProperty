//
//  ViewController.m
//  Objective-C Runtime：深入理解成员变量与属性
//
//  Created by Mac-Qke on 2019/7/11.
//  Copyright © 2019 Mac-Qke. All rights reserved.
//

#import "ViewController.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "Animal.h"
//成员变量(Ivar)的数据结构
typedef struct objc_ivar *Ivar;
//struct objc_ivar {
//    char *ivar_name OBJC2_UNAVAILABLE; // 变量名。
//    char *ivar_type OBJC2_UNAVAILABLE; // 变量类型。
//    int ivar_offset OBJC2_UNAVAILABLE; // 基地址偏移量，在对成员变量寻址时使用。
//#ifdef __LP64__
//    int space OBJC2_UNAVAILABLE;
//#endif
//}

typedef struct objc_property *objc_property_t;
//typedef struct {
//    const char * _Nonnull name;           /**< The name of the attribute */
//    const char * _Nonnull value;          /**< The value of the attribute (usually empty) */
//} objc_property_attribute_t;


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    int a[] = {1, 2};
    NSLog(@"type Coding = %s", @encode(typeof(a)));
}

//成员变量
//
//    //// 获取成员变量名
//    const char *ivar_getName(Ivar v);
//    // 获取成员变量类型编码
//    const char * ivar_getTypeEncoding ( Ivar v );
//    // 获取成员变量的偏移量
//    ptrdiff_t ivar_getOffset ( Ivar v );


//关联对象
//// 获取属性名
//const char * property_getName ( objc_property_t property );
//// 获取属性特性描述字符串
//const char * property_getAttributes ( objc_property_t property );
//// 获取属性中指定的特性
//char * property_copyAttributeValue ( objc_property_t property, const char *attributeName );
//// 获取属性的特性列表
//objc_property_attribute_t * property_copyAttributeList ( objc_property_t property, unsigned int *outCount );



//运行时操作成员变量和属性的示例代码

NSString *runtimePropertyGetterIMP(id self, SEL _cmd){
    // 获取类中指定名称实例成员变量的信息   Ivar class_getInstanceVariable ( Class cls, const char *name );
    Ivar ivar = class_getInstanceVariable([self class], "_runtimeProperty");
    // 返回对象中实例变量的值 id object_getIvar ( id obj, Ivar ivar );
    return object_getIvar(self, ivar);
}


void runtimePropertySetterIMP(id self, SEL _cmd, NSString *value){
    // 获取类中指定名称实例成员变量的信息   Ivar class_getInstanceVariable ( Class cls, const char *name );
    Ivar ivar = class_getInstanceVariable([self class], "_runtimeProperty");
     // 返回对象中实例变量的值 id object_getIvar ( id obj, Ivar ivar );
    NSString *aValue = (NSString *)object_getIvar(self, ivar);
    
    if (![aValue isEqualToString:value]) {
        // 设置对象中实例变量的值 void object_setIvar ( id obj, Ivar ivar, id value );
         object_setIvar(self, ivar, value);
    }

}


- (void)verifyPropertyAndIvar{
       #pragma clang diagnostic push
      #pragma clang diagnostic ignored "-Wundeclared-selector"
    
      //1、Add property and getter/setter method
    // 创建一个新类和元类  Class objc_allocateClassPair ( Class superclass, const char *name, size_t extraBytes );
     Class cls = objc_allocateClassPair([Animal class], "Panda", 0);
    
    
    //add instance variable
    // 添加成员变量  BOOL class_addIvar ( Class cls, const char *name, size_t size, uint8_t alignment, const char *types );
   
    BOOL isSuccess = class_addIvar(cls, "_runtimeProperty", sizeof(cls), log2(sizeof(cls)), @encode(NSString));
     NSLog(@"%@", isSuccess ? @"成功" : @"失败");//print 成功
    
     //add attributes
    objc_property_attribute_t type = {"T", "@\"NSString\""};
    objc_property_attribute_t owenrship = {"C",""}; //C = Copy
    objc_property_attribute_t isAutomic = {"N",""};// N = nonatomic
    objc_property_attribute_t backingVar = {"V","_runtimeProperty"};
    objc_property_attribute_t attributes[] = {type, owenrship, isAutomic, backingVar};
    
    // 为类添加属性  BOOL class_addProperty ( Class cls, const char *name, const objc_property_attribute_t *attributes, unsigned int attributeCount );
    class_addProperty(cls, "runtimeProperty", attributes, 4);
    //// 添加方法  BOOL class_addMethod ( Class cls, SEL name, IMP imp, const char *types );
    class_addMethod(cls, @selector(runtimeProperty), (IMP)runtimePropertyGetterIMP, "@@:");
    class_addMethod(cls, @selector(setRuntimeProperty), (IMP)runtimePropertySetterIMP, "V@:");
    // 在应用中注册由objc_allocateClassPair创建的类 void objc_registerClassPair ( Class cls );
    objc_registerClassPair(cls);
    
     //2、print all properties
    unsigned int count = 0;
    // 获取属性列表  objc_property_t * class_copyPropertyList ( Class cls, unsigned int *outCount );
    objc_property_t *properties = class_copyPropertyList(cls, &count);
    for (int32_t i = 0; i < count; i++) {
        objc_property_t property = properties[i];
       // 获取属性名 const char * property_getName ( objc_property_t property );
       // 获取属性特性描述字符串 const char * property_getAttributes ( objc_property_t property );
        NSLog(@"%s, %s\n", property_getName(property), property_getAttributes(property));
        //print: _runtimeProperty, T@"NSString",C,N,V_runtimeProperty
    }
    
    free(properties);
    
      //3、print all Ivar
    unsigned int outCount = 0 ;
    // 获取整个成员变量列表  Ivar * class_copyIvarList ( Class cls, unsigned int *outCount );
    Ivar *ivars = class_copyIvarList(cls, &outCount);
    for (int32_t i = 0; i < outCount; i ++) {
        Ivar ivar = ivars[i];
        // 获取成员变量名  const char * ivar_getName ( Ivar v );
        // 获取成员变量类型编码 const char * ivar_getTypeEncoding ( Ivar v );
        NSLog(@"%s, %s\n", ivar_getName(ivar), ivar_getTypeEncoding(ivar));
        //print:_runtimeProperty, {NSString=#}
    }
    
    free(ivars);
    
    //4、use property
    id panda = [[cls alloc] init];
    [panda performSelector:@selector(setRuntimeProperty) withObject:@"set-property"];
    NSString *propertyValue = [panda performSelector:@selector(runtimeProperty)];
    NSLog(@"return value = %@", propertyValue);
    //print: return value = set-property
    
    
     //5、destory
    panda = nil;
    // 销毁一个类及其相关联的类 void objc_disposeClassPair ( Class cls );
    objc_disposeClassPair(cls);
    
    #pragma clang diagnostic pop
}

@end
