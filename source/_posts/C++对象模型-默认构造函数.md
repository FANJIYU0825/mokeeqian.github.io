title: C++对象模型--默认构造函数
author: Qian Jipeng
tags:
  - 默认构造函数
  - 初始化列表
  - 虚函数
  - 虚基类
  - vtbl
  - vptr
  - 对象模型
categories:
  - C++
date: 2019-08-30 13:45:00
---
这篇文章主要讲解C++中默认构造函数的机制，同时解决了困扰了我很久的问题，<font color=red>长篇文章</font>，话不多说，开干！  

# 写在前面
C++编译器为程序员自动提供下面这些成员函数(在合适的时候)：  
+ 默认构造函数
+ 默认析构函数
+ 拷贝构造函数
+ 赋值运算符
+ 地址运算符
+ 移动构造函数(C++11)
+ 移动赋值运算符(C++11)

# 默认构造函数
<font color=red>错误的、不全面的认识： </font> 
+ 如果程序员没有定义默认的构造函数，那么编译器就会提供一个默认构造函数，来完成对成员的初始化
+ 编译器合成出来的默认构造函数会明确的设置类的每个数据成员的值  

<font color=green>正确认识： </font> 
+ 默认构造函数只在“被需要”的时候，才会被编译器合成，可能是有用或无用
+ 对构造函数的需求分为程序需求和编译器需求
+ 一个有用的默认构造函数在必要的时候(4种情况下)也会被编译器合成
	+ 带有默认构造函数的类对象成员
    + 带有默认构造函数的基类
    + 带有虚函数的类
    + 带有虚基类的类
+ 编译器合成的默认构造函数，不会初始化用户定义的类成员，退一步说，只会初始化编译器“需要的”成员
+ 编译器只做编译器自己的事，程序员的事需要程序员自己做

   
# 何谓默认构造函数
　　***C++ Annotated Reference Manual(ARM)***中提及到：**<font color=hotpink>“default constrcutor在需要的时候会被编译器产生出来。”**</font>　那这里问题来了，<font color=green>“在需要的时候”，到底是什么时候？又是被谁需要？用来做什么事情？</font>  
以下代码为例：  
```
class Foo {
public:
	int val;
    Foo *pnext;
};

void foo_bar() {
	Foo bar;
    if ( bar.val || bar.pnext ) {
    // do something
    }
}
```

　　在这个程序中，要求val 和 pnext都必须被初始化为0，那么代码中并没有提供setter函数，只有通过和构造函数来初始化，但是代码也没有(显式)提供构造函数。那么这个情形是否符合上述的“在需要的时候”？答案当然是：NO。对“在需要的时候”，可以分为**程序需要**和**编译器需要**，至于前者，那是我们程序员自己的事，我们需要，那我们就自己写构造；后者，是编译器的工作。那么本例中的当然是程序需要，提供默认构造函数的责任就在于程序员。所以上述程序**不会生成一个默认构造函数**。  
　　那么，什么时候才会合成一个默认构造函数？当编译器需要的时候！被合成出来的默认构造函数**执行编译器所需要的行为**(想想都很可怕，我们都不知编译器到底在背后做了什么)，因此，即便编译器为程序合成了一个默认构造函数，这个构造函数也不会执行我们希望的操作，就是说，这个Foo()构造函数**不会把val和pnext都初始化为0**，也就是我们所说的编译器合成的**无用的默认构造函数(trivial)**，***C++ Standard[ISO-C++95]***中的原话是，**<font color=hotpink>“对于class X，如果没有任何user-defined constructor，那么会有一个default constructor会被隐式声明出来，一个隐式声明出来的defalut constructor是一个trivial constructor”。</font>**  
　　我们验证一下：  <br><br>
**代码A：**
```
#include <iostream>
using namespace std;
class Foo {
public:
	int val;
	Foo *pnext;
};

void Foo_bar() {
	Foo bar;
	cout << bar.val << endl;
    cout << bar.pnext << endl;    	
}

int main() {
	Foo_bar();
	return 0;
}
```

1. g++编译运行结果：  

  ```
 4196624
 0x400770
  ```

2. clang++编译运行结果：  
```
0
0
```

初步怀疑，与编译器有关？  
1. g++编译gdb调试： 
```
$1 = {val = 4196624, pnext = 0x400770 <_start>}
```
2. clang++编译gdb调试：
```
$2 = {val = 0, pnext = 0x0}
```

另外，在线编译器爆出了一个warnning:  
```
Start
prog.cc: In function 'void Foo_bar()':
prog.cc:11:14: warning: 'bar.Foo::val' is used uninitialized in this function [-Wuninitialized]
   11 |  cout << bar.val << endl;
      |              ^~~
prog.cc:12:17: warning: 'bar.Foo::pnext' may be used uninitialized in this function [-Wmaybe-uninitialized]
   12 |     cout << bar.pnext << endl;
      |             ~~~~^~~~~
4197792
0x400c20
0
Finish
```
意思是val和pnext没有被初始化，这就说明了我们的无用的默认构造函数没有对类成员进行初始化，在这里，貌似要解释一下<font color=red>初始化</font>和<font color=red>赋值  </font>  <br><br>
**代码B：**
```
#include <iostream>
using namespace std;
class Foo {
public:
	int val;
	Foo *pnext;
};

void Foo_bar() {
	Foo bar;
}

int main() {
	Foo_bar();
	return 0;
}
```
1. g++编译，gdb调试结果：  
```
$1 = {val = 4196128, pnext = 0x4005c0 <_start>}
```
可见，这里的val = 4196128, 貌似是一个~~随机生成的数值~~。 

2. clang++编译，gdb调试结果：
```
$1 = {val = 0, pnext = 0x0}
```

此上，基本可以推断出，默认构造函数的行为貌似与编译器有关？
但是可以肯定的是，

# non-trivial(有用的)默认构造函数
## ***带有defalut constructor的member class object***  
举个例子： 

  ```
  class Foo {
  public:
      Foo();
      Foo(int val);
  };

  class Bar {
  public:
      Foo foo;		// 不是继承，是内含!
      char *str;
  };
  
  void foo_bar() {
  	Bar bar;	//Bar::foo必须在这里初始化
  	if ( str ) {
    	//do something
      }
  }
  ```
我们的Foo是一个拥有默认构造函数的一个类，当Foo的一个对象foo作为我们的Bar类的一个成员，同时Bar类没有任何构造函数的时候，那么这个类的implicit default constructor就是nontrivial的，编译器为就会在Bar类的constructor**<font color=red>真正需要</font>**的时候，为其合成一个默认构造函数。  
被合成的Bar类的构造函数，里面有必要的代码，能够调用Foo::Foo()对Bar::foo进行处理，但是Bar::str需要程序员来初始化，我们大胆猜测一下，编译器合成的Bar::Bar()可能是这样子的：  
```
inline Bar::Bar() {
	foo.Foo::Foo();		//伪代码
}
```
同时，我们程序员还会写一个Bar::Bar()，对Bar::str初始化：  
```
Bar::Bar() {
	str = 0;
}
```
现在好了，程序的需求已经得到满足了，但是我们的Bar::foo还没有初始化，但是这里程序员已经显式定义了默认构造函数，所以编译器无法再次合成了，怎么办呢？  
编译器的做法是：  
<font color=hotpink>**“如果Class A内含有一个或者一个以上的member class object，那么Class A的每一个构造函数都必须调用每一个member class的默认构造函数”***</font>，即编译器会**扩张**已经存在的构造函数，在其中安插一些代码，在user code被执行之前，调用相应的defalut constructor。  

	所以，扩张后的构造函数可能是这样的：　　
```
Bar::Bar() {
	foo.Foo::Foo();		// 编译器插入的
    str = 0;			// 程序员写的
}
```

最后说一点，如果Bar类有多个member class object怎么办？当然是按上面的道理来，只不过对这些object，**<font color=red>按照它们声明的顺序来初始化</font>**。
## ***带有defalut constructor的base class***
顾名思义，如果一个没有任何构造函数的继承于一个带有默认构造函数的基类，那么编译器就会**<font color=red>为这个类合成一个默认构造函数，这个构造函数会调用上一层继承类的默认构造函数。</font>**  
那么如果程序员为这个类写了很多个构造函数，但是就是没有默认构造函数，怎么办？**<font color=red>编译器会把默认构造函数中需要的代码插入到所有的现有的构造函数中，那么如果上述第一种情况也存在呢？答案是，这些构造函数会在基类构造函数被调用之后，再被调用。</font>**

## ***带有一个virtual function的class***
这个与C++中的虚函数的机制有关，参见[C++虚函数机制](http://mokeeqian.github.io/2019/08/22/C++%E5%AF%B9%E8%B1%A1%E6%A8%A1%E5%9E%8B--%E5%85%B3%E4%BA%8E%E5%AF%B9%E8%B1%A1/)，以下代码为例：  
```
class Widget {
public:
	virtual void flip() = 0;
    // ...
};

void flip(const Widget & widget) {
	widget.flip();
}

// 假设Bell和Whistle都是继承于Widget
void foo() {
	Bell b;
    Whistle w;
    flip(b);
    flip(w);-
}
```
+ 一个虚函数表vtbl会在编译的时候被合成出来，用来存放虚函数的地址
+ 在每一个Widget对象中，都会有一个额外的指针成员vptr，用来存放虚函数表的地址

此外，widget.flip()的虚拟调用操作会被重新改写，因为flip()在vtbl中是需要通过索引来获得的。可能的代码如下：  
```
(*widget.vptr[1]) (&widget)	// &widget是this指针
```
至于索引为什么是1？因为vtbl中的第一个元素存放的是**type_info**    

为了让这个机制有效，编译器必须需要为每一个Widget或其派生类的对象的vptr赋值，放上适当的vtbl的地址。**<font color=red>对于class所定义的每一个构造函数，编译器都会插入一些代码来完成这样的事情；对于那些没有定义任何构造函数的class，编译器ｈｉ合成一个这样的默认构造函数，完成对vptr的初始化。</font>**
## ***带有一个virtual base class的class***
这一条没有弄懂.....


# trivial(无用的)默认构造函数(实际上不存在)
不满足上述4种情况、没有显式提供user-defined constructor的时候，这个默认构造函数叫implicit trivial default constructor，实际上**编译器根本不会合成这样的一个构造函数**。

# 编译器如何合成默认构造函数
当程序员没有定义构造函数时，编译器会合成一个默认构造函数，来完成编译器需要的工作；当程序员定义了自己的构造函数时，有时候，编译器也会对它“需要的”一些成员进行操作，这时候，编译器的做法是：  
**<font color=red>修改构造函数，在程序员写的构造函数里添加代码，添加的代码位于程序员的代码之前。</font>**

# 小结
+ 默认构造函数只有在上述4种情况下，才会由编译器强制合成，C++ Standard称之为implicit nontrivial default constructor，它只会满足**<font color=red>编译器的需要</font>**，其他事一概不会做。
+ 对那些不满足上述4种情况、没有任何user-defined constructor的类，我们说它拥有的是implicit trivial default constructor，实际上，这个默认构造函数**<font color=red>根本不会被合成</font>**。
+ 在合成的默认构造函数中，只有**<font color=red>基类的子对象、类的成员对象</font>会**被初始化，所有其他的**<font color=red>nonstatic data membe</font>r**(如整数、整数指针、整数数组等)都**不会**被初始化，这些初始化对于程序而言或许很重要，但是编译器它管你干啥子。
+ 自己的事情自己做，编译器合成出来的构造函数只会做编译器需要做的工作，其他的工作需要程序员自己想办法。

# 成员初始化列表(补充说明)
## 初识
C++还提供了一种初始化成员的方法：**成员初始化列表**  
何为初始化列表？看个例子：  
```
class Foo {
public:
	int a;
    float b;
    
    // 初始化列表初始化
    Foo(int _a, float _b):a(_a),b(_b)
    { }
    
    // 一般赋值运算符初始化
    Foo(int _a, float _b)
    {
    	a = _a;
        b = _b;
    }
    
    ~Foo()
    { }
};  
```

如上的`Foo(int _a, float _b):a(_a),b(_b) { }`就是一个含有列表初始化式的构造函数，观察上述两种初始化的方法，貌似没有区别，真的是这样的吗？  
首先区别肯定是有的，而且**C++ Primer**中明确提出，有的时候，必须要使用成员初始化列表，否则编译器就会爆出错误！

## 本质
初始化列表的本质是什么？</br>
举个例子：</br>
```
class Word {
private:
	String name;
    int count;
public:
	Word():name(0)
    {
    	count = 0;
    }
};
```
我们猜测一下，这个name是如何被初始化的。</br>
```
// C++伪代码
Word::Word(*this)
{
	// String(int) 构造
    name.String::String(0);
    count = 0;
}
```
这里，0 要被String类的String(int)构造函数来构造成一个String对象，然后才能对name初始化。
也就是说，**<font color=red>对于成员初始化列表，编译器会将其按照变量声明顺序来处理(也不是绝对的，后面会给出例子)，插入一些代码到构造函数中的任何user-defined code之前。</font>**


## 何时使用
**1. 编译器要求的时候**  
**深度探索C++对象模型**中提到，在以下四种情况，对成员的初始化必须要使用成员初始化列表：  
+ 初始化一个reference member
+ 初始化一个const member
+ 调用base class的constructor，而它拥有一组参数  
+ 调用member class的constructor，而它拥有一组参数  


下面对以上四种情况给出说明：  
### 初始化reference member
我们知道引用一经指定，便不可以再改变，一个引用的成员在声明之后，不可以进行赋值。
```
class Foo {
public:
	int a;
    int &b;
    

    
    // 一般赋值运算符初始化
    Foo(int _a, int _b)
    {
    	a = _a;
        b = _b;
    }
    
    ~Foo()
    { }
}; 

int main() {
	Foo foo(1, 2);
    return 0;
}
```
报错：</br>
```
5.cpp: In constructor ‘Foo::Foo(int, int)’:
5.cpp:9:5: error: uninitialized reference member in ‘int&’ [-fpermissive]
     Foo(int _a, int _b)
     ^
5.cpp:4:10: note: ‘int& Foo::b’ should be initialized
     int &b;
          ^
```
说我Foo::b没有初始化，也就是把b放在构造函数中，不能够正确初始化，那么我们来改一下：</br>
```
class Foo {
public:
	int a;
    int &b;
    
    Foo(int _a, int _b):b(_b)
    {
    	a = _a;
    }
    
    ~Foo()
    { }
}; 

int main() {
	Foo foo(1, 2);
    return 0;
}
```
这样是没有问题的了。

### 初始化const member
为什么const member需要使用成员初始化列表呢？貌似不可理解。</br>
实际上，const成员在声明后就马上需要初始化，如果放在构造函数中，执行的是赋值操作，这是不允许的。</br>
我们来试试用构造函数初始化const member：</br>
**TestA.cpp：**
```
class Foo {
public:
	int a;
    const float b;
    
    // 初始化列表初始化
    //o(int _a, float _b):a(_a),b(_b)
    //}
    
    // 一般赋值运算符初始化
    Foo(int _a, float _b)
    {
    	a = _a;
        b = _b;
    }
    
    ~Foo()
    { }
}; 

int main() {
	Foo foo(1, 0.1);
    return 0;
}
```
编译报错：
```
5.cpp: In constructor ‘Foo::Foo(int, float)’:
5.cpp:9:5: error: uninitialized const member in ‘const float’ [-fpermissive]
     Foo(int _a, float _b)
     ^
5.cpp:4:17: note: ‘const float Foo::b’ should be initialized
     const float b;
                 ^
5.cpp:12:11: error: assignment of read-only member ‘Foo::b’
         b = _b;
           ^
```

他说，我对只读的成员Foo::b赋值了，如你所见，因为**<font color=red>const成员变量一经声明或定义，就不可以在修改，而我们放在构造函数中，进行的是赋值操作，所以编译器会报错。</font>**所以const member必须要用成员列表初始化。

### 调用base class的constructor，而它拥有一组参数
即: 初始化基类的成员，而且这个基类只有带参数的构造函数，没有无参构造函数</br>
**TestB.cpp**
```
#include <iostream>
using namespace std;
class Foo {
public:
	int a;
    float b;
  
    // 一般赋值运算符初始化
    Foo(int _a, float _b)
    {
    	a = _a;
        b = _b;
    }
    
    ~Foo()
    { }
}; 

class Bar:public Foo {
public:
	int c;

    
    Bar(int _a, int _b, int _c):c(_c),Foo(_a,_b)
    { }
    
    ~Bar()
    { }

};
int main() {
	Bar bar(1,2.2,2);
    cout << bar.a <<endl << bar.b << endl << bar.c <<endl;
    return 0;
}
```
运行结果：</br>
```
1
2
2
```

### 调用member class的constructor，而它拥有一组参数
即初始化的是一个类对象成员，而且这个类成员所对应的类只有带参数的构造函数，没有无参的构造函数。</br>
这一点貌似与上一条类似？


**2. 程序效率要求的时候**</br>
这点先放着，等我搞懂初始化、赋值、定义、声明后在写。
```
class Word {
private:
	String name;
    int count;
public:
	Word() 
    {
    	name = 0;
        count = 0;
    }
};
```


## 注意
C++初始化列表的初始化顺序是什么样的呢？</br>
**<font color=red>与初始化列表的变量出现顺序无关，而是和变量的声明顺序有关！</font>**</br>
但是答案就是绝对的了吗？看个例子：</br>
```
class X {
	int i;
    int j;
public:
	X(int val)
    	:j(val), i(j)
    { }
};
```
这里你发现了什么？</br>
**没错！如果按照变量声明的顺序来初始化的话，那么就是先初始化i，在初始化j，那么这个构造函数必定会出错，因为用j来初始化i，此时j还没有被初始化！！！</br>
所以说，<font color=red>初始化列表的初始化顺序也不是确定的，要视具体情况而定。</font>**




