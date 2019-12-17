title: CSAPP--cachelab
author: Qian Jipeng
tags:
  - CSAPP
  - cache
categories:
  - 计算机系统
date: 2019-10-09 21:06:00
---
# 写在前面(未完待续)
这学期跟着同学蹭了计算机系统基础这门课，有幸接触到CSAPP的第一个lab--cachelab，其实前几个lab我已经错过了。简单回顾一下cache。

# cache的组成
![](https://images2015.cnblogs.com/blog/830677/201606/830677-20160601183337883-1142045675.png)
这是组相连映射的cache,每个cache有S个set，每个set有E个行，每一行里面有一个valid位，占一个比特、一个tag位、一个block位，存放实际的数据。</br>
我们给定一个地址，这个地址m = t + s + b。
以下给出cache的数据结构模拟：
```
// 缓存行
typedef struct
{
	int valid;		// 有效位
	int tag;		// 标示位
	int data;	// 数据位(时间)	--> LRU counter, 初始化都是0
}cacheLine;

// 缓存组
typedef struct
{
	cacheLine *line;	// 一组中的所有行, 一个数组
}cacheSet;

// 缓存
typedef struct
{
	int numSets;		// cache中set总数目
	int numLinesPerSet;	// cache中每一个set中的行数
	cacheSet *set;		// 一个cache中的所有set,一个数组
}simCache;
```
