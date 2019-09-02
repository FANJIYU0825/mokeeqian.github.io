title: C++对象模型--关于对象
copyright: true
tags:
  - C++对象
  - 对象模型
  - 指针
categories:
  - C++
date: 2019-08-22 09:39:00
---
# 写在前面
为什么要写C++一栏的博客呢?其实是为了加深理解和敦促学习，我发现只要离开写博客，人就变得懒散起来，每天写的代码零零散散，C++这门课程是在大二上开的，上课也就水水过去了，老师上课其实也还挺好，无奈听不懂啊，听不懂就不想听啊。现在想想挺后悔的。<br>
后来由于实验室需要，而且自己也意识到C++的重要性，于是便自学。(貌似我所有的编程语言都是自学的、除了大一的C)至于自学，我的做法是，找博客，一个一个知识点地去学，后来也勉强算是入门了把。
好记性不如烂笔头，于是还是记录下来比较好。

### 关于入门  
入门书籍的选取太重要了。谁要是和你推荐诸如*21天学通C++*、*Visual C++ xxx*的，可以绝交了(滑稽)，我推荐*C++ primer*而不是*C++ primer plus*，不是带了个*plus*就是更牛x一点，相反，*plus*对于新入门的来说，讲的太过细致，有点晦涩，以至于你想放弃。搞清楚C++的大致框架后，可以读一读*C++沉思录*，这本书介绍的是一些C++思想，有助于你更好的理解。后期实战可以读一读
*Effecitve C++*、*More Effective C++*，如果想深入了解C++底层机制的话，那么*深度探索C++对象模型*一定值得细细评味。   

# 关于C++对象
1. **C++对象模式**  
在C++中，有两种类数据成员：静态数据成员(static关键词修饰)和非静态数据成员(没有static关键词修饰)，三种类成员函数：static、non-static、virtual。
以下程序为例:

  ```
  class Point{
  public:
      int x;
      int y;
      Point(int _x, int _y);
      virtual ~Point();
      int X() const;
  };

  Point point;

  ```
我创建了一个Point的对象，那么这个对象point的data member和funtion member是怎么布局呢?
 + **简单对象模型**  
![简单对象模型](https://res.cloudinary.com/hexo-mokeeqian/image/upload/v1566482922/hexo/IMG_20190822_215545_xqr4z3.jpg)
这个模型是简单的一个模型，每个对象抽象成一些列的slots，每个slot对应一个成员，这样一来实现了member的对号入座。这样简化了编译器的设计复杂度，但是牺牲了效率和空间。
在这个模型下，**members本身不在object中，而是指向members的指针存放在object中**，避免了*"members有不同的数据类型，因而需要不同的储存空间"*。
如此，object中的member便是通过slots的索引值来索引的。
但是这个模型并***没有***被C++所采用，不过这个观念被应用到了指向成员的指针(pointer-to-member)这一概念之中。
 + **表格驱动摸模型**  
![表格驱动模型](https://res.cloudinary.com/hexo-mokeeqian/image/upload/v1566482837/hexo/0822_3_muhhsi.jpg)
这个模型是把members划分为两类，datas放在data member table中，functions放在member function table中，object本身含有指向这两个表格的指针。data member table直接指向data本身，function member table是一系列的slots，每个slots指出一个member function。
很遗憾，这个模型也***没有***被采用。但是member funciton table这一观念却支持了virtual function的机制。
 + **C++对象模型**  
![C++对象模型](https://res.cloudinary.com/hexo-mokeeqian/image/upload/v1566482844/hexo/0822_2_jibhqp.jpg)
这是Stroustrup设计C++时采用的模型。在这个模型之下，所有的non-static members都被置于每一个class object之中，static data members则被存放在这个class中(原书说法是~~存放在个别的class object之外~~)，static和non-static function members也被存放在个别的class object之外。而virtual functions分两步处理:
    + 每一个class都会产生一系列指向virtual functions的指针，这些指针存放在一个叫***virtual table***(vtbl)的表格之中
    + 每一个class object都会被"安排"一个指向这个class的***vtbl***的指针(***vptr***)，vptr的设置和重置由类的构造函数、拷贝构造函数、析构函数完成。(这里先不讨论)
每个class还会关联一个***type info object***,由vtbl指出来，通常放在vtbl的第一个slots的位置(![虚函数的实现机制](https://res.cloudinary.com/hexo-mokeeqian/image/upload/v1566482845/hexo/0822_1_fniz8u.jpg))。

2. **关键词的差异**(class和struct)  
struct即结构，class即我们所说的类。C++为了兼容C，仍然保留了C的struct关键字，作为一种数据类型。
 + **区别(简单理解)**
    + struct默认访问限制和继承方式是**public**，并且C++中struct类型中也可以拥有构造函数<br>这点我在代码中有遇到过，一般用到struct的是一些比较操作，用于**STL**容器的*sort()*函数。如下示例程序:<br>
    ```
    class A {
            struct cmp{
                int a;
                int b;
                bool operator()(int lhs, int rhs) {
                    return lhs > rhs;
                };
            };
    };
    ```
    + class默认访问限制是**private**
  + **何时该用struct**  
 我觉得都可以，在C++中可以将两者等同，如果你愿意使用struct的话。
 
3. **对象的差异**  
 C++程序设计模型直接支持以下三种程序设计范式： 
 + **程序模型(procedural model)**
 + **抽象数据类型模式(abstract data type model)**  
 + **面向对象模型(object-oriented model)**　
 
4. **杂谈**
 + 关于指针  
 　　***一个指针或引用，无论其指向哪种数据类型，其本身所占内存大小是固定的。***  
 指针的类型，“指向不同的类型的指针”之间的差异，不在于指针的表示方法不同，也不在于指针的内容(地址)的不同，***而是在于由这个指针所寻址出来的object类型的不同***。也就是说，指针类型会让编译器以相应的方式去解释特定地址中的内容及大小。  
　　一个指向地址100０的int类型的指针，在32位机器上，其所占的地址空间为1000~1003，因为32位机器上int类型所占４个字节(byte)。  
　　那么一个指向地址1000的**void\***类型的指针呢？我们不知道，这也是为什么一个void\*的类型的指针只能持有一个地址，不能操作其所指的对象的原因。  
　　这里可以学习一下C++的四种**cast**。其本质是，**只影响被指出的内存的大小和内容，不改变指针所指向的真正地址。**  
  　　日后再补充。
    
# 写在后面
C++真是一门**magic**的语言，究其本质，晦涩而又有点魅力，加油吧。