title: C++对象模型--拷贝构造函数
author: Qian Jipeng
tags:
  - 对象模型
  - 拷贝构造函数
  - 深拷贝
  - 浅拷贝
categories:
  - C++
date: 2019-08-31 22:58:00
---
接上一篇[C++默认构造函数](http://mokeeqian.github.io/2019/08/30/C++%E5%AF%B9%E8%B1%A1%E6%A8%A1%E5%9E%8B-%E9%BB%98%E8%AE%A4%E6%9E%84%E9%80%A0%E5%87%BD%E6%95%B0/)，这一篇我们来讲C++拷贝构造函数。  

# 写在前面(关于深拷贝、浅拷贝)
在此之前，先介绍一下：  
+ **浅拷贝(值拷贝)**  
只是对指针进行了拷贝，指针指向的地址并没有进行拷贝，**<font color=red>拷贝后的指针和原指针指向同一块内存区域(这是很危险的、如果析构，会析构两次，导致内存泄漏！</font>**。我们的C++编译器合成的拷贝构造函数是执行**浅拷贝**，如果拷贝了指针(如Foo::*p)，必定会出错，这个指针会成为野指针
![](http://px1awapyv.bkt.clouddn.com/less.png)
+ **深拷贝(位拷贝)**  
对指针和指针指向的地址都进行拷贝，**<font color=red>拷贝后的指针和原指针指向两块不同的内存区域，所以，执行深拷贝，需要开辟新的内存空间。</font>**  
![](http://px1awapyv.bkt.clouddn.com/deep.png)

## 区别
来看一个例子：  
**TestA.cpp**
```
#include <iostream>  
using namespace std;

class Student
{
private:
	int num;
	char *name;
public:
	Student();
	~Student();
};
 
Student::Student()
{
	name = new char(20);
	cout << "Student" << endl;
}
Student::~Student()
{
	cout << "~Student " << name << endl;
	delete name;
	name = NULL;
}
 
int main()
{
	{// 花括号让s1和s2变成局部对象，方便测试
		Student s1;
		Student s2(s1);// 调用默认拷贝构造函数
	}
	return 0;
}
```
运行结果：  
```
Student
~Student 
~Student 
*** Error in `./a.out': double free or corruption (fasttop): 0x00000000010f9c20 ***
```
很显然，报出了一个错误，double free，也就是进行两次析构，这是不允许的。为什么呢？
**<font color=gree>因为我这里调用的是编译器合成的拷贝构造函数，它进行的是浅拷贝，拷贝后s1.name和s2.name都是指向同一块内存区域，对同一块内存区域进行两次释放，能不出错吗？</font>**  

我们来gdb一下看看：  
这是对s2进行拷贝初始化之前，s2这时候还不存在，内存地址都还是起始地址
```
$1 = {num = 2, name = 0x614c20 "\024"}
(gdb) p s2
$2 = {num = 0, name = 0x0}
```
这是对s2进行拷贝初始化之后，s2这时候和s1的数据成员完全一致，也就是说，我们的拷贝构造函数只是对s1.name和s1.num进行了简单的复制，赋值给s2
```
(gdb) p s2
$3 = {num = 2, name = 0x614c20 "\024"}
(gdb) p s1
$4 = {num = 2, name = 0x614c20 "\024"}
```

我们修改一下原来的代码、加上一个user-defined拷贝构造函数，进行深拷贝：   
**TestB.cpp**
```
#include <iostream>
#include <string.h>
using namespace std;
 
class Student
{
private:
	int num;
	char *name;
public:
	Student();
	Student(const Student & stu);
	~Student();
};
 
Student::Student()
{
	name = new char(20);
	cout << "Student" << endl;
 
}
Student::~Student()
{
	cout << "~Student " << name << endl;
	delete name;
	name = NULL;
}

// 深拷贝构造函数
Student::Student( const Student & stu ) {
	num = stu.num;
	name = new char[20];
	if ( name!= NULL )
		strcpy(name, stu.name);
}
 
int main()
{
	{// 花括号让s1和s2变成局部对象，方便测试
		Student s1;
		Student s2(s1);
		cout << "结束" << endl;	
    }
	return 0;
}
```
运行结果：  
```
Student
~Student 
~Student 
```
这次没有出现重复析构的错误了，输出的是我们希望的结果，我们再一次gdb看一下：  
```
(gdb) p s1
$3 = {num = 2, name = 0x614c20 "\024"}
(gdb) p s2
$4 = {num = 2, name = 0x615050 "\024"}
```
刚刚为TestB.cpp加上了一个拷贝构造函数，所以**<font color=gree>执行Student s2(s1)的时候，会调用我定义的Student(const Student &stu)这个拷贝构造函数，执行深拷贝，即为s2对象的name属性开辟新的内存空间(首地址0x615050)，使得name指针指向这个新开辟的内存地址，而不是原来的s1的name指针所指向的地址(首地址0x614c20)</font>**，这样在析构的时候，便没有内存泄漏的错误了。

## 使用
知道区别之后，那么我们什么时候该用浅拷贝、什么时候该用深拷贝？
或许上面的例子是一个答案，当我们需要对动态的数据类型(指针、数组等)进行拷贝的时候，使用深拷贝，防止内存泄漏、指针悬挂问题的出现。
当然大多数情况下，浅拷贝就可以解决我们的问题了。


# 拷贝构造函数
## 什么是拷贝构造函数
+ 对于普通的内置数据类型，要对它们进行复制很简单，只需要简单的赋值操作符就可以了
+ 类对象数据类型就不行了，它比较复杂，有各种各样的成员变量

我们看一个例子：　　
```
    #include <iostream>  
    using namespace std;  
      
    class Foo {  
    private:  
        int a;  
    public:  
        //构造函数  
        Foo(int b)  
        { a = b;}  
          
        //拷贝构造函数  
        Foo(const Foo & C)  
        {  
            a = C.a;  
        }  
      
        void Show ()  
        {  
            cout<<a<<endl;  
        }  
    };  
      
    int main()  
    {  
        Foo A(100);  
        Foo B(A);
        //Foo B = A; 
        B.Show ();  
        return 0;  
    }   
```
这里的Foo(const Foo & c)就是一个拷贝构造函数，它是一种特殊的构造函数，**参数中必须要有一个是这个类的类型的引用变量**，一个类中可以有多个拷贝构造函数。

## 何时调用
**1. 对象需要通过另外一个对象进行初始化**
这一点显而易见
```
Foo a(b);		// 拷贝构造函数
Foo a = b;		// 拷贝赋值操作符
```

**2. 对象以值传递的方式传入函数参数**
```
    class Foo {  
    private:  
    	int a;
    public:   
     	Foo(int b) 
        {  
      		a = b;  
      		cout<<"creat: "<<a<<endl; 
        }
       
     	Foo(const Foo& C) 
        {
      		a = C.a;  
      		cout<<"copy"<<endl;  
     	}  
       
     	~Foo()  
     	{  
      		cout<< "delete: "<<a<<endl;  
     	}  
      
         void Show ()  
         {  
         	cout<<a<<endl;  
         }  
    };  
      
    //全局函数，传入的是对象  
    void Foo_bar(Foo C)  
    {  
    	cout<<"test"<<endl;  
    }  
      
    int main()  
    {  
    	Foo test(1);  
     	//传入对象  
     	Foo_bar(test);  
     	return 0;  
    }  
```
调用Foo_bar()的过程中，会有如下操作：  
+ test作为实参传入Foo_bar()函数的形参，生成临时Foo对象tmp
+ 调用拷贝构造函数，把test的值传递给tmp,一、二操作在一起就是Foo tmp(test)
+ Foo_bar()函数执行完之后，调用析构函数，析构tmp对象 

**3. 对象以值传递的方式从函数返回**
```
    class Foo {  
    private:  
    	int a;
    public:   
     	Foo(int b) 
        {  
      		a = b;  
      		cout<<"creat: "<<a<<endl; 
        }
       
     	Foo(const Foo& C) 
        {
      		a = C.a;  
      		cout<<"copy"<<endl;  
     	}  
       
     	~Foo()  
     	{  
      		cout<< "delete: "<<a<<endl;  
     	}  
      
         void Show ()  
         {  
         	cout<<a<<endl;  
         }  
    };  
      
    //全局函数，传入的是对象  
    Foo Foo_bar()  
    {
    	Foo test_local(100);  
    	return test_local;
    } 
      
    int main()  
    {  
     	Foo_bar();  
     	return 0;  
    } 
```
当Foo_bar()执行到return 语句时候：
+ 产生一个临时对象tmp
+ 调用拷贝构造函数，把test_local的值传递给tmp,一、二操作在一起就是Foo tmp(test_local)
+ Foo_bar()函数执行到最后，调用析构函数，先析构test_local对象，再析构tmp对象

## 一些注意事项
+ **<font color=red>拷贝构造函数不能对static member进行拷贝赋值，因为static member属于这个类，而不被某个特定的对象所拥有</font>**

# 写在后面
暂时就想到这么多，后面再进行补充。