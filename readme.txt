readme.txt>

front panel界面的绘制使用了ncuses库和lua脚本解析器，这两者均为开源软件，可直接从网上找到。
其中ncuses在我们的设备上使用的5.6版本，通常在linux系统上已经安装更高版本，U4/G4设备上已经有5.6版本的动态库，可 以直接使用。lua解析器使用的是5.1.4版本。
目前的front panel程序只实现了测试界面的绘制、对按键的响应以及取测试需要参数的操作，测试接口还在实现中，所以未有加入到代码里，后续会再提供。
对打包文件的目录结构有如下说明：
bit32  curses  front_panel  include  lib  Makefile  posix
1）bit32/curses/posix是辅助的库，其中bit32实现的是对位的操作，curses是在终端界面上画图的库，posix 实现了部分linux的系统调用接口。
2）lib目录用于存放以上三个辅助库的动态库。
3）front_panel目录为front_panel实现源码，主要有以下四个源码：
load2tty0.lua front_panel.lua menu_show.lua menu_data.lua
3-1）load2tty0.lua只在target端需要使用，通过"./load2tty0.lua front_panel.lua"命令使界面输出到LCD以及接收target端按键输入。在pc上调试时，不需要。
3-2）front_panel.lua为程序执行起点。
3-3）menu_show.lua负责显示界面的绘制以及对通用按键的响应操作。
3-4）menu_data.lua为界面显示的数据表，用来控制界面的显示内容、执行流程以及对实现对特定界面的响应操作。当需要增加新的测试操作，可以通过配置该数据表格实现。该数据表格可以根据测试执行过程动态修改。目前提供的只是FCC的测试界面，其它测试界面可以通过提供类似的数据表实现。
