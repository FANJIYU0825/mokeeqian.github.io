title: 深入理解C函数调用机制
copyright: true
tags:
  - 函数调用
  - 栈帧
  - gdb
categories:
  - C
date: 2019-09-15 15:21:00
---
# 写在前面
C语言是面向过程的一种语言，而函数则作为解决一个个问题的“过程”，在一个程序中，会出现函数的声明、定义以及调用，我们已经知道C函数的调用和栈有关，但是在有些程序的debug过程中，如果不了解函数调用的底层实现原理，是很痛苦的。所以这里就以x86-64下的C语言函数调用为例，至于为什么不带上C++，前面已经说过，C++ is not greater C，C++里面的构造函数、虚函数，更为复杂，所以这里不做讨论。</br>
在此之前，需要了解一下：
+ <font color=red>栈帧</font></br>
栈帧也叫过程活动记录，可以说每个函数的调用都对应着一个栈帧，栈帧里保存了函数运行的环境：函数参数、返回地址(下一条指令的地址)、局部变量等。要知道，**栈的存储顺序是从高地址往低地址存储**，每个函数的每次调用，都会有属于自己的栈帧，ebp(32位)/rbp(64位)叫做栈底指针寄存器，指向栈帧的底部(高地址)；esp/rsp指向栈帧顶部(低地址)
+ <font color=red>x86-64下16个通用寄存器</font>
![](https://pic1.zhimg.com/80/v2-8f2a02c38a3b53ce857b87ed01272b80_hd.png)
	+ 每个寄存器的用途并不是单一的。
	+ %rax 通常用于存储函数调用的返回结果，同时也用于乘法和除法指令中。在imul 指令中，两个64位的乘法最多会产生128位的结果，需要 %rax 与 %rdx 共同存储乘法结果，在div 指令中被除数是128 位的，同样需要%rax 与 %rdx 共同存储被除数。
	+ %rsp 是堆栈指针寄存器，通常会指向栈顶位置，堆栈的 pop 和push 操作就是通过改变 %rsp 的值即移动堆栈指针的位置来实现的。
	+ %rbp 是栈帧指针，用于标识当前栈帧的起始位置
	+ %rdi, %rsi, %rdx, %rcx,%r8, %r9 六个寄存器用于存储函数调用时的6个参数（如果有6个或6个以上参数的话）。
	+ 被标识为 “miscellaneous registers” 的寄存器，属于通用性更为广泛的寄存器，编译器或汇编程序可以根据需要存储任何数据。
	+ 这里还要区分一下 “Caller Save” 和 ”Callee Save” 寄存器，即寄存器的值是由”调用者保存“ 还是由 ”被调用者保存“。当产生函数调用时，子函数内通常也会使用到通用寄存器，那么这些寄存器中之前保存的调用者(父函数）的值就会被覆盖。为了避免数据覆盖而导致从子函数返回时寄存器中的数据不可恢复，CPU 体系结构中就规定了通用寄存器的保存方式。
如果一个寄存器被标识为”Caller Save”， 那么在进行子函数调用前，就需要由调用者提前保存好这些寄存器的值，保存方法通常是把寄存器的值压入堆栈中，调用者保存完成后，在被调用者（子函数）中就可以随意覆盖这些寄存器的值了。</br>如果一个寄存被标识为“Callee Save”，那么在函数调用时，调用者就不必保存这些寄存器的值而直接进行子函数调用，进入子函数后，子函数在覆盖这些寄存器之前，需要先保存这些寄存器的值，即这些寄存器的值是由被调用者来保存和恢复的。

# 函数调用
函数调用时，caller与callee的栈帧结构如图：</br>
![](https://pic2.zhimg.com/80/v2-bd5a0aa1625c4445ba33e506b91dba29_hd.png)
子函数调用时，执行的操作：</br>
1. 父函数将调用参数**<font color=red>从后向前</font>**压栈 
2. 将返回地址压栈保存 
3. 跳转到子函数起始地址执行
4. 子函数将父函数栈帧起始地址（%rpb） 压栈
5. 将 %rbp 的值设置为当前 %rsp 的值，即将 %rbp 指向子函数栈帧的起始地址

示例代码：</br>
**testfun.c**
```
void fun(int a, int b, int c) {
	int x = 10;
	int y = 100;
}

int main() {
	fun(1,2,3);
	return 0;
}
```
gcc进行编译：
```
$ gcc testfun.c -g -o testfun
```
gcc生成汇编代码：
```
	.file	"testfun.c"
	.text
	.globl	fun
	.type	fun, @function
fun:
.LFB0:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movl	%edi, -20(%rbp)
	movl	%esi, -24(%rbp)
	movl	%edx, -28(%rbp)
	movl	$10, -8(%rbp)
	movl	$100, -4(%rbp)
	nop
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE0:
	.size	fun, .-fun
	.globl	main
	.type	main, @function
main:
.LFB1:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movl	$3, %edx
	movl	$2, %esi
	movl	$1, %edi
	call	fun
	movl	$0, %eax
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE1:
	.size	main, .-main
	.ident	"GCC: (Ubuntu 5.4.0-6ubuntu1~16.04.11) 5.4.0 20160609"
	.section	.note.GNU-stack,"",@progbits
```
貌似不大好看，使用objdump反汇编看看(只保留关键代码)：
```
testfun:     file format elf64-x86-64

00000000004004d6 <fun>:
void fun(int a, int b, int c) {
  4004d6:	55                   	push   %rbp
  4004d7:	48 89 e5             	mov    %rsp,%rbp
  4004da:	89 7d ec             	mov    %edi,-0x14(%rbp)
  4004dd:	89 75 e8             	mov    %esi,-0x18(%rbp)
  4004e0:	89 55 e4             	mov    %edx,-0x1c(%rbp)
	int x = 10;
  4004e3:	c7 45 f8 0a 00 00 00 	movl   $0xa,-0x8(%rbp)
	int y = 100;
  4004ea:	c7 45 fc 64 00 00 00 	movl   $0x64,-0x4(%rbp)
}
  4004f1:	90                   	nop
  4004f2:	5d                   	pop    %rbp
  4004f3:	c3                   	retq   

00000000004004f4 <main>:

int main() {
  4004f4:	55                   	push   %rbp
  4004f5:	48 89 e5             	mov    %rsp,%rbp
	fun(1,2,3);			// 对fun(int, int, int)的调用
  4004f8:	ba 03 00 00 00       	mov    $0x3,%edx	// 3先入栈
  4004fd:	be 02 00 00 00       	mov    $0x2,%esi	// 然后是2
  400502:	bf 01 00 00 00       	mov    $0x1,%ed		// 最后是1
  400507:	e8 ca ff ff ff       	callq  4004d6 <fun>	
	return 0;
  40050c:	b8 00 00 00 00       	mov    $0x0,%eax
}
  400511:	5d                   	pop    %rbp
  400512:	c3                   	retq   
  400513:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  40051a:	00 00 00 
  40051d:	0f 1f 00             	nopl   (%rax) 
```
这个就好看多了，有对应的汇编代码和C源码，对于我这个汇编菜鸟来说真是太人性化了。不过这还是不够，我们还有寄存器没有观察。万能的gdb，这件事就交给你了。
```
$ gdb testfun -tui		// 使用tui界面
```
接着，
```
$ layout regs	// 分配一个寄存器界面布局
```
然后，
```
set disassmele-next-line on		// 实时显示反汇编代码
```
接着，在fun()的调用位置打上断点，
```
$ b 7	//也就是我们的fun(1,2,3);
$ b *fun	// 注意 *fun是汇编级别的fun()函数地址
```
接着，单步运行，
```
$ ni	// 注意,ni和si都是相对于汇编代码的单步运行，n和s只是相对于C代码的单步运行；
	// 再者，n和s都有单步运行的功能，只不过s直接会进入函数调用的内部
```
**1. main**

首先，3进入%edx寄存器</br>
然后,2进入%esi寄存器</br>
接着，1进入%edi寄存器</br>
然后对fun()函数进行调用
```
   0x00000000004004f8 <main+4>: ba 03 00 00 00  mov    $0x3,%edx
   0x00000000004004fd <main+9>: be 02 00 00 00  mov    $0x2,%esi
   0x0000000000400502 <main+14>:        bf 01 00 00 00  mov    $0x1,%edi
=> 0x0000000000400507 <main+19>:        e8 ca ff ff ff  callq  0x4004d6 <fun>
```
![](http://px1awapyv.bkt.clouddn.com/step1.png)

**2. fun**
```
=> 0x00000000004004d6 <fun+0>:  55      push   %rbp
   0x00000000004004d7 <fun+1>:  48 89 e5        mov    %rsp,%rbp
   0x00000000004004da <fun+4>:  89 7d ec        mov    %edi,-0x14(%rbp)
   0x00000000004004dd <fun+7>:  89 75 e8        mov    %esi,-0x18(%rbp)
   0x00000000004004e0 <fun+10>: 89 55 e4        mov    %edx,-0x1c(%rbp)
   0x00000000004004f1 <fun+27>: 90      nop
   0x00000000004004f2 <fun+28>: 5d      pop    %rbp
   0x00000000004004f3 <fun+29>: c3      retq
```