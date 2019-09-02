---
title: Linux系统下文件乱码问题解决
copyright: true
date: 2019-08-17 20:28:45
tags:
	- Linux
	- 编码
	- shell
categories:
	- utils
top: false
---
今天在github上clone了一个master，想拿来练手，无奈是Windows下的编码，中文乱码，英文OK。于是想到之前看过一篇帖子，记录如下。
 + 主要是用到了Linux的 [iconv](https://baike.baidu.com/item/iconv/524310) 命令


## Step one　获取当前文件编码

我当前文件是 *Student.cpp*
```bash
file Student.cpp
```

得到输出如下：
```bash
Student.cpp: C source, UTF-8 Unicode text
```

是个万国码


## Step Two 获取本机编码

```bash
cat /etc/sysconfig/i18n
```

不知道为什么我这里报错，没有这个文件???
不过Linux一般都是UTF-8

## Step Three 修改文件编码

```bash
iconv -f GBK -t UTF-8  Student.cpp -o  Student0.cpp 
```

这里*Student.cpp*是原来的文件，*Student0.cpp*是我修改后的文件。

改后打开文件就没有乱码问题了


### 这里有个问题，如果有多个文件不能在一起转化
比如我有两个文件，*Student.cpp* 和 *Student.h* 必须要执行两次命令，尴尬。
后来想起来可以用通配符，文件名不改变，即可

+ 注意： 通配符要慎用!
+ 最后的最后: 写了个小项目，放在了仓库中[编码转换](https://github.com/mokeeqian/demo-projects/tree/master/%E7%BC%96%E7%A0%81%E8%BD%AC%E6%8D%A2)
