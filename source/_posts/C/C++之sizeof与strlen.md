title: C/C++之sizeof与strlen
author: Qian Jipeng
tags:
  - sizeof
  - strlen
  - 内存对齐
  - C++成员布局
categories:
  - C++
  - C
date: 2019-09-12 21:47:00
---
# C/C++中的sizeof与strlen
很久之前的C课程上面老师就提到过sizeof，当时也不知道是怎么一回事，后来在读代码的过程中经常遇到sizeof，索性就来好好了解一下吧。
# 区别
## sizeof
首先要知道一点，sizeof是C/C++中的一个运算符，我们通常的用法是`sizeof(foo)`，**<font color=red>在编译时才会计算foo的大小并返回，它的值不受foo里面所存储的内容影响，只会和foo的数据类型(char还是int还是指针...)和计算机平台(32位还是64位)有关。</font>**</br>

举个例子：</br>
**Test1.cpp**
```
#include <iostream>
using namespace std;
int main() {
	int a;
	char b;
	int *c;
	cout << sizeof(a) << endl;	// int 类型占4个字节
	cout << sizeof(b) << endl;	// char 类型占1个字节
	cout << sizeof(c) << endl;	// 64位系统指针占8个字节，32位一个指针占4个字节
	return 0;
}
```
测试输出：</br>
```
4
1
8
```
</br>
**Test2.cpp**
```
#include <iostream>
using namespace std;
int main() {
	int a = 1;
	int d = 10;
	char b;
	int *c;
	double *e;
	
	cout << sizeof(a) << endl;		// 4
	cout << sizeof(b) << endl;
	cout << sizeof(c) << endl;
	cout << sizeof(d) << endl;		// 4
	cout << sizeof(e) << endl;
	return 0;
}
```
测试输出：</br>
```
4
1
8
4
8
```
</br>
sizeof(a)和sizeof(d)相等，这就说明了sizeof(foo)与foo里面存取的内容无关。</br>
好接下来，如果<font color=green>遇到C++中的类怎么办？</font></br>
**Test3.cpp**
```
#include <iostream>
using namespace std;

class Foo {
	int a;	// 4
	char b;		// 1
	int *c;		// 8
};

int main() {
	Foo foo;
	cout << sizeof(foo) << endl;
	return 0;
}
```
测试结果：</br>
```
16
```
啥？输出是16，为什么是16呢？4+1+8不应该是13吗？</br>
一开始我也是这么认为的，知道看了***inside the C++ object module***一书时才醒悟，我们的编译器一般都会对我们的代码做出优化，一个专业名词叫做**<font color=red>内存对齐</font>**，**<font color=hotpink>编译器在编译程序时，会检测一个类的数据成员，是否sizeof(foo)的值是4的整数倍，如果不是，就会自动扩张成4的整数倍(距离当期sizeof最小的)，具体为什么，要说到C++中的成员数据的内部布局，这个我们在这先不做讨论。大家记着就好，后面我会详细介绍。</font>**</br>
所以说，上面的答案就合乎逻辑了，16 = 4 + 1 + 8 + 3，这个3叫做**padding size**。</br>

不妨再来一波？</br>
**Test4.cpp**
```
#include <iostream>
using namespace std;

class Foo {
	int a;	// 4
	char b;		// 1
	int *c;		// 8
};

class Bar:public Foo {		// 加上继承试试
	char d;		// 1
};

int main() {
	Foo foo;
	Bar bar;
	cout << "sizeof foo is: " << sizeof(foo) << endl;		// 16
	cout << "sizeof bar is: " << sizeof(bar) << endl;		// 24
	return 0;
}
```
测试结果：</br>
```
sizeof foo is: 16
sizeof bar is: 24	//why???
```
是不是又蒙了？加上继承之后，sizeof(bar)为什么是24呢？先抛砖引玉，后面的文章再详细解释。

## strlen
strlen()是C的一个库函数，注意它是函数，一般用于计算字符串的长度，遇到`'\0'`就停止计算。我们来测试一下：</br>
**Test5.cpp**
```
#include <iostream>
#include <cstring>
using namespace std;

int main() {
	char *a = "Hello World";
	char b[100] = "Hello World";
	char c[] = "Hello World";
	cout << "sizeof a is: " << sizeof(a) << endl;
	cout << "strlen a is: " << strlen(a) << endl;
	cout << "sizeof b is: " << sizeof(b) << endl;	
	cout << "strlen b is: " << strlen(b) << endl;
	cout << "sizeof c is: " << sizeof(c) << endl;
	cout << "strlen c is: " << strlen(c) << endl;
	return 0;
}
```
测试结果：</br>
```
sizeof a is: 8		// 一个指针大小
strlen a is: 11		// 字符串长度，不带'\0'
sizeof b is: 100	// 数组大小
strlen b is: 11		// 字符串长度，不带'\0'
sizeof c is: 12		// 字符串长度，加上一个'\0'
strlen c is: 11		// 字符串长度，不带'\0'
```

## 补充说明
**<font color=red>
讲到这里，二者之间的区别想必大家也都明白了，strlen 的结果要在运行的时候才能计算出来，而sizeof的值是在编译时就确定的，所以不能用sizeof来计算动态分配的类型大小。
</font>**

**Test6.cpp**
```
#include <iostream>
#include <cstring>
using namespace std;

int main() {
	char *a = new char[20];
	cout << "sizeof a is: " << sizeof(a) << endl;	// 8
	cout << "strlen a is: " << strlen(a) << endl;	// 0
	cout << "sizeof *a is: " << sizeof(*a) << endl;	// 1
	
	*a = 'a';
	
	cout << "now sizeof a is: " << sizeof(a) << endl;	// 8
	cout << "now strlen a is: " << strlen(a) << endl;	// 1
	cout << "now sizeof *a is: " << sizeof(*a) << endl;	// 1

	delete[] a;
	a = NULL;
	return 0;
}
```
测试结果：</br>
```
sizeof a is: 8
strlen a is: 0
sizeof *a is: 1
now sizeof a is: 8
now strlen a is: 1
now sizeof *a is: 1		// sizeof(*a)没变化??
```


