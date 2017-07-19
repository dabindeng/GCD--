//
//  ViewController.m
//  GCD-常见代码
//
//  Created by DB_MAC on 2017/6/20.
//  Copyright © 2017年 db. All rights reserved.
//

//GCD 核心概念：将任务添加到队列，指定任务执行的方法

/*
 
 任务  使用block封装   block就是一个提前准备好的代码块，在需要的时候执行

 队列（负责调度任务）  怎么拿任务
 串行队列:一个接一个调度任务  一个任务执行结束才回再拿下一个任务执行（在同一个线程执行）
 并行队列：可以同时调度多个任务  同时拿多个任务
 
任务执行函数  （任务需要在线程中执行）
 同步执行：当前指令不完成 不会执行下个指令  （不会到线程池获取子线程  在所在线程执行 ）
 异步执行：当前指令不完成，同样执行下一个指令  （只要有任务 就会到线程池获取线程执行指令  主队列除外） 主队列是属于串行队列
 
 小结： 开不开线程 取决于执行任务的函数  同步不开 异步才开
       开几条线程 取决于队列   串行开一条  并发队列开多条
 
 
 
 
 
 */

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
}

//主队列 同步任务 （不死锁） 当前线程是子线程
-(void)gcdDemo13
{
    void (^task)() = ^{
        dispatch_sync(dispatch_get_main_queue(), ^{///在主线程
            //能来吗
        });
        NSLog(@"come here");//此时在子线程
    };
    dispatch_async(dispatch_get_global_queue(0, 0), task);
}
//主队列 同步任务 （死锁） 当前线程是主线程
-(void)gcdDemo12{
    //主队列是专门负责在主线程上调度任务的队列  --》 不会开线程
    //同步任务 特点：这一句话不执行完毕 就不能执行下一句 阻塞式
    //队列 先进先出  当前队列有任务  添加了同步任务后 同步任务会阻塞主线程 导致任务无法继续下去  造成死锁
    //主队列有任务执行的时候 就不会调度任务
    dispatch_sync(dispatch_get_main_queue(), ^{///在主线程
        //能来吗
    });
    NSLog(@"come here");//在主线程
}
//主队列
-(void)gcdDemo11{
    //主队列是专门负责在主线程上调度任务的队列  --》 不会开线程
    //异步任务
    dispatch_async(dispatch_get_main_queue(), ^{
        //come here later
    });
    NSLog(@"come here");//先执行 再到异步主对面里面
}

-(void)gcdDemo10{
    //队列
    dispatch_queue_t q = dispatch_get_global_queue(0, 0);
    //调度组
    dispatch_group_t g = dispatch_group_create();
    //添加任务  让队列调度 任务执行情况 最后通知群组
    dispatch_group_async(g, q, ^{
        NSLog(@"1");
    });
    dispatch_group_async(g, q, ^{
        NSLog(@"2");
    });
    dispatch_group_async(g, q, ^{
        NSLog(@"3");
    });
//   调度组里的所有任务执行完毕  通知
    //用一个调度组，可以监听全局队列的任务，然后可以到主队列去执行最后的任务（更新UI）
    dispatch_group_notify(g, dispatch_get_main_queue(), ^{
       //在主队列执行最后的任务  更新UI
    });
    
    dispatch_group_notify(g, q, ^{//此代码块 也是异步执行
        //所有任务执行完毕 后 执行这个任务
        NSLog(@"ok");
    });
    
}

-(void)gcdDemo8{
    //全局队列 &  并发队列
    //名称，并发队列取名字  适合于企业开发跟踪错误
    //并发队列  在MRC下 需要释放
    //全局队列  效率高  耗电
    //全局队列 & 串行队列
    //串行 效率低  省电
    dispatch_queue_t q = dispatch_get_global_queue(0, 0);
    for (int i = 0; i<10; i++) {
        dispatch_async(q, ^{
            
        });
    }
}

-(void)gcdDemo9{
    static dispatch_once_t onceToken;//效率高 一次执行   不要使用互斥锁 效率低
    NSLog(@"%ld",onceToken);
    dispatch_once(&onceToken, ^{
        //执行到这里后 onceToken的值就变了
    });
}

//全局队列  (并行队列)
-(void)gcdDemo7{
    dispatch_queue_t q = dispatch_get_global_queue(0, 0);//全局队列
//    参数1：涉及系统适配  优先级  不管使用什么优先级->尤其不要使用 BackGround   否则线程会无比缓慢
//    iOS 8 ->服务质量
//    
//    QOS_CLASS_USER_INTERACTIVE  用户交互 希望线程快速被执行 不要耗时操作  相当于高优先级
//    QOS_CLASS_USER_INITIATED    用户需要  不要耗时操作
//    QOS_CLASS_DEFAULT            默认的  给系统重置队列的
//    QOS_CLASS_UTILITY             使用工具 用来做耗时操作
//    QOS_CLASS_BACKGROUND          后台
//    QOS_CLASS_UNSPECIFIED          没有指定
    
    
    //          ios 7->调度优先级
//#define DISPATCH_QUEUE_PRIORITY_HIGH 2   高优先级
//#define DISPATCH_QUEUE_PRIORITY_DEFAULT 0  默认优先级
//#define DISPATCH_QUEUE_PRIORITY_LOW (-2)  低优先级
//#define DISPATCH_QUEUE_PRIORITY_BACKGROUND INT16_MIN  后台优先级
    

//    参数2： 为未来使用的一个保留  现在始终给0
    
    for (int i = 0; i < 10; i++) {
        dispatch_async(q, ^{
            NSLog(@"%@",[NSThread currentThread]);
        });
    }
}

-(void)gcdDemo6{
    //增强版 同步任务
//    可以队列调度多个任务前  指定一个同步任务  让所有的异步任务等待同步任务完成  这就是依赖关系
//    同步任务 会造成死锁 锁住当前子线程
    
    dispatch_queue_t q = dispatch_queue_create("name", DISPATCH_QUEUE_CONCURRENT);
    
    void (^task)() = ^{
        dispatch_sync(q, ^{//把同步任务 放到子线程任务block中  然后在开启子线程执行同步任务
            //用户登录  一登录就执行付款
//            有些任务彼此有依赖关系。利用同步任务能够做到任务依赖关系
            NSLog(@"%@",[NSThread currentThread]);
        });
        dispatch_async(q, ^{
            //用户支付
            NSLog(@"%@",[NSThread currentThread]);
        });
        dispatch_async(q, ^{
            //用户下载
            NSLog(@"%@",[NSThread currentThread]);
        });
    };
    dispatch_async(q, task);
    
    
}

-(void)gcdDemo5{
    
    
//    开发中，通常会将耗时操作放后台执行，有时候，有些任务彼此有依赖关系。利用同步任务能够做到任务依赖关系
    
    
    dispatch_queue_t q = dispatch_queue_create("name", DISPATCH_QUEUE_CONCURRENT);
    dispatch_sync(q, ^{//会阻塞主线程
        //用户登录  一登录就执行付款
        NSLog(@"%@",[NSThread currentThread]);
    });
    dispatch_async(q, ^{
        //用户支付
        NSLog(@"%@",[NSThread currentThread]);
    });
    dispatch_async(q, ^{
        //用户下载
        NSLog(@"%@",[NSThread currentThread]);
    });
    
    
    
}

//串行队列  同步任务 不会开启线程(在主线程执行)  按顺序执行
-(void)gcdDemo1{
    //串行队列  参数1：队列名称   参数2：队列的属性
    dispatch_queue_t q = dispatch_queue_create("队列名称", NULL);
    dispatch_sync(q, ^{
        NSLog(@"%@",[NSThread currentThread]);
    });
}
//串行队列  异步任务  会开启线程  按顺序执行
-(void)gcdDemo2
{
    dispatch_queue_t q = dispatch_queue_create("队列名称", NULL);
    dispatch_async(q, ^{
        NSLog(@"%@",[NSThread currentThread]);
    });
    
    
}
//并行队列  异步执行  会开启多个线程  不会顺序执行
-(void)gcdDemo3{
    //并发队列的宏定义：DISPATCH_QUEUE_CONCURRENT
    dispatch_queue_t q = dispatch_queue_create("队列名称", DISPATCH_QUEUE_CONCURRENT);
    for (int i = 0; i<10; i++) {
        dispatch_async(q, ^{
            NSLog(@"%@",[NSThread currentThread]);
        });
    }

}

//并行队列  同步执行  不会开启线程(在主线程执行)  会顺序执行
-(void)gcdDemo4{
    //并发队列的宏定义：DISPATCH_QUEUE_CONCURRENT
    dispatch_queue_t q = dispatch_queue_create("队列名称", DISPATCH_QUEUE_CONCURRENT);
    dispatch_sync(q, ^{
        NSLog(@"%@",[NSThread currentThread]);
    });
}


-(void)demo1{
    //创建队列
    dispatch_queue_t q = dispatch_get_global_queue(0, 0);
//    定义任务
    void(^taskBlock)() = ^() {
        NSLog(@"%@",[NSThread currentThread]);
    };
//    添加任务到队列并且他会实现  sync是同步执行
    dispatch_sync(q, taskBlock);
    
    
    //定义任务  与 添加任务到队列 合并
//    dispatch_sync(q, ^{
//        
//    });
    
}

-(void)demo2{
    dispatch_queue_t q = dispatch_get_global_queue(0, 0);
    //异步执行  具备开启线程的能力
    dispatch_async(q, ^{
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
        });
    });
}

-(void)demo3
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
       //耗时操作
        
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            //更新UI  主队列  就是专门负责在主线程调度任务的队列
            
            
        });
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
