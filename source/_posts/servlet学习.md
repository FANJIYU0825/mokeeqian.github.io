layout: java
title: java web--servlet学习
tags:
  - servlet
  - web
categories:
  - 前端
date: 2019-08-22 22:44:37
---
接上篇，学习servlet基础。
## servlet是什么  
java servlet是运行在web服务器上的应用程序，实现动态页面的创建，作为来自web浏览器和其他http客户端请求和http服务器上的数据库或者应用程序之间的**中间层**。  
![http请求和响应](https://res.cloudinary.com/hexo-mokeeqian/image/upload/v1566486478/hexo/874710-20170214192940050-671180063_dpxpnk.png) 
　　　　　　　　　　　　　　　　　　　　http请求和响应过程
## servlet架构
+ 架构
![架构](https://www.runoob.com/wp-content/uploads/2014/07/servlet-arch.jpg)
+ tomcat与servlet
![tomcat](https://res.cloudinary.com/hexo-mokeeqian/image/upload/v1566486469/hexo/874710-20170214204632894-1786729693_hjhji5.png)  
 + 这里可以知道，tomcat将浏览器发过来的http请求(http request)文本接收并解析，封装成httpServlet类型的request对象
 + tomcat服务器同时将要响应的信息封装成httpResponse类型的response对象，通过设置response的相关属性就可以控制输出到浏览器的内容，再将response交给tomcat，tomcat就会将其转换成要响应的文本格式返回给浏览器

## servlet任务
+ 读取客户端发送的显式数据，包括html表单，或者是applet或者用户定义程序的表单
+ 读取客户端发送的隐式http请求，包括cookies等
+ 处理数据并获得结果，可能会访问数据库调用web服务
+ 发送显式的数据到客户端，可能是文档、图片等
+ 发送隐式的http响应到客户端  

## java servlet包
java servlet是运行在带有servlet解释器的web服务器(我用的是tomcat)上的java类。
通常需要`import javax.servlet.*`来导入包。  
java servlet API 是servlet容器(tomcat为例)和servlet之间的接口，定义了各种servlet方法，和一些对象，其中主要是servletRequest和servletResponse对象比较重要。  

## 编写servlet
编写servlet有两种方法：
+ 直接编写servlet类，实现相应的方法  
这个方法需要编写完整的java类，比较复杂，而且容易出错。故我们采用第二种方法。
+ 用IDE(我的是idea)新建myServlet  
新建myServlet，默认会实现doGet()和doPost()方法，也可以根据自己的需要，实现其他方法，诸如：init()、service()、destory()  

另外，要实现与jsp的交互，必须要配置**web.xml**文件，写入servlet、servlet-mapping等标签，除此之外，**也可以在servlet类的添加注释(annoation)**，例如：　`@WebServlet(urlPatterns = "/signin", name = "signin")`，这样就可以不用配置**web.xml**文件

## 详解servlet原理
**1. servlet生命周期**  
+ servlet的生命周期始于servlet服务器启动时或者第一次请求该servlet，此时调用init()方法，初始化出一个servlet对象
+ servlet处理所有的客户端请求，执行service()方法
+ 服务器关闭，执行destory()方法，servlet被销毁

**2. servlet的service()方法**  
这里有个问题，我们在编写servlet时，只写了doPost()和doGet()方法，并没有写service()方法，那么servlet是如何执行service()方法的呢？  
public的service()方法，这是对外的公有方法，这里做了一个ServletRequest到httpServletRequest的转型
![](https://res.cloudinary.com/hexo-mokeeqian/image/upload/v1566520802/hexo/11_bb7cxt.png)

内部的protected的方法，根据请求的方法**method**不同，调用不同的响应方式：
![](https://res.cloudinary.com/hexo-mokeeqian/image/upload/v1566521046/hexo/22_jborni.png)

也就是说，service()方法一般情况下我们是不需要重写的，它已经包括的所有的推理机，我们只要重写相应需要的方法就行了，比如说doPost()、doGet()，这也是idea默认给我们重写的两个方法。  
**3. servlet重要的对象**  
servlet为我们创建了几个内置对象：
+ servletCopnfig
+ servletContext
+ httpServletRequest
+ httpServletResponse
