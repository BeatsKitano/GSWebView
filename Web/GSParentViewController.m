 
#import "GSParentViewController.h"
#import "ViewController.h"

@interface GSParentViewController ()

@end

@implementation GSParentViewController

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    ViewController * vc = [[ViewController alloc] init];
     
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)test
{
    NSLog(@"GSParentViewController 内部方法成功调用");
}

@end
