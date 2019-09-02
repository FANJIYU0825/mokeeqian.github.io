layout: java
title: web--浅谈jsp与servlet
tags:
  - servlet
  - jsp
  - web
categories:
  - 前端
author: ''
date: 2019-08-23 09:30:00
---
# JSP和servlet
## 区别
+ jsp的本质就是servlet，jsp经过编译后会转化成servlet  
因为jvm只能识别java类，不能识别其他的类文件，所以就有了一系列的web容器(服务器)，如tomcat，这些容器将jsp编译成jvm能够识别的java类
+ 一般来说，jsp用于**页面展示**，servlet用于**逻辑控制**  
比如说要实现一个用户登录模块，我们会把页面显示交给jsp，内部逻辑控制交给servlet
+ servlet没有内置对象，jsp有一些内置对象

## 联系
+ servlet是严格意义上的java类，它在*MVC*模型中是**控制层**，它与**表现层**完全分离
+ jsp可以是html标签，可以嵌入java代码，它是**表现层**，侧重于视图

## 做好理解
+ 不同之处  
servlet通过java代码httpServletResponse对象向客户端动态输出html内容，就是说，如果我要在servlet中向客户端输出或者展示一些东西，必须要以html标签的形式
+ 各自特点  
servlet可以很好的组织**业务逻辑**，但是通过以字符串的形式向客户端传送html标签使得代码维护起来比较困难。  
但是一概的在jsp里面混入大量的业务逻辑也是不可取的。
+ 如何均衡  
那么如何做到二者的优势互补？答案当然是[MVC](https://baike.baidu.com/item/MVC%E6%A1%86%E6%9E%B6/9241230)，MVC是一种软件架构，分为:  
 + 模型层(Model)---业务逻辑
 + 视图层(View)---负责页面显示
 + 控制层(Controler)---负责相关交互操作
 
## 示例demo
这个小demo主要实现了html表单的用户登录操作，然后记录用户的提交信息，返回给客户端。

**1. loginServlet.java**  

```
package servlet;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;

@WebServlet(urlPatterns = "/login", name = "login")
/**
 * 这里是 servlet负责页面显示， 也可以是SERVLET负责数据处理, jsp 负责页面显示
 */
public class LoginServlet extends HttpServlet {

    public static final long serialVersionUID = 1L;
    public LoginServlet() {
        super();
    }

    // post 提交浏览器不会显示，比较安全
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        doGet(request, response);
    }

    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        // 设置页面编码格式
        request.setCharacterEncoding("UTF-8");
        response.setContentType("text/html;charset=UTF-8");
        String user = request.getParameter("user");

        // 这样写是没有效果的，servlet向浏览器输出内容，浏览器只能解析html,所以要用html标签向页面传送信息
        //response.getWriter().println(user);
        //response.getWriter().print("这是登录界面");

        // response.getWriter() 获得一个输出流
        String string = "<html> <head> <title>这是servlet返回的结果</title></head> <body> 欢迎 " + user + "</body> </html>";
        response.getWriter().print(string);

    }
}

```

**2. login.jsp**  
```

<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<html>
<head>
    <title>servlet测试</title>
</head>
<body>

<form action="login" method="post">
    <table>
        <tb>
            uesr:
            <input type="text" name="user"> <br>
        </tb>

        <tb>
            passwd:
            <input type="password" name="passwd"> <br>
        </tb>
    </table>

    <button>提交</button>
</form>

</body>
</html>
```

## 测试结果
可以知道，我输入的`user`是“servler测试”，点击登录按钮后，返回给客户端的就是用户提交的`user`值，”servlet测试“。
+ 页面提交
![页面提交](https://res.cloudinary.com/hexo-mokeeqian/image/upload/v1566523985/hexo/33_k8dao7.png)
+ 信息返回
![](https://res.cloudinary.com/hexo-mokeeqian/image/upload/v1566523985/hexo/44_rw8cgj.png)