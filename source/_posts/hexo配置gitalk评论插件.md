---
title: hexo配置gitalk评论插件
copyright: true
date: 2019-08-20 21:13:05
tags:
	- 评论
	- hexo
categories:
	- blog
---
之前用的一直是来比力，不知为何加载很慢，而且社区版没有邮件登录的选项，比较不方便，于是乎，改成了gitalk，基于github issue的评论插件。
原理是，创建一个用来存放comment的repo，将所有的comment都放在特定的issue下。

# 写在前面
[官方repo](https://github.com/gitalk/gitalk)

# 创建OAuth application
创建一个github OAuth application，[点击这里](https://github.com/settings/applications/new)，点进去如下：
![图片1](https://res.cloudinary.com/hexo-mokeeqian/image/upload/v1566481819/hexo/1_px6klt.png)
+ Application name: 随便写
+ Homepage url: 写你的博客主页url
+ Application description: 应用的描述
+ Authorization callback url: 回调url，写你的博客url ~~如果你有自己的custom domain，写自己的域名~~

# 创建一个github repo
这个很简单，一个空的public的repo就行，先创在这。
~~私有仓库不知道行不行，貌似更加隐私~~

# 配置hexo配置文件
*以next主题为例，其他主题可能有所差别*
1. 新建*gittalk.swig*文件
   + 路径: **themes/next/layout/_third-party/comments/**
   + 文件内容:
   
   ````
	   <!-- gitalk 评论系统 2019.8.19 -->
	{% if page.comments && theme.gitalk.enable %}
	  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/gitalk@1/dist/gitalk.css">
	  <script src="https://cdn.jsdelivr.net/npm/gitalk@1/dist/gitalk.min.js"></script>
	  <script type="text/javascript">
		const gitalk = new Gitalk({
		  clientID: '{{theme.gitalk.clientID}}',
		  clientSecret: '{{theme.gitalk.clientSecret}}',
		  repo: '{{theme.gitalk.repo}}',
		  owner: '{{theme.gitalk.githubID}}',
		  admin: ['{{theme.gitalk.adminUser}}'],	// 注意使用列表
		  id: location.pathname, // 依据官方readme,这里可能会有bug, post lable长度超过50会有报错
		})
		gitalk.render('gitalk-container')
	  </script>
	{% endif %}
   ````
   
2. 修改*index.swig*文件
   + 路径: **themes/next/layout/_third-party/comments/**
   + 修改内容:
   在文件最后一行追加下列语句:
   
   ````
   	{% include 'gitalk.swig' %}
   ````
   
3. 修改*comment.swig*文件
   + 路径: **/themes/next/layout/_partials/**
   + 修改内容:
   
   ````
   {% elseif theme.valine.appid and theme.valine.appkey %}
	 <div class="comments" id="comments">
	 </div>		// 在这一行的下一行开始加

   {% elseif theme.gitalk.enable %}			// 加入以下三行
	 <div class="comments" id="comments">
	 <div id="gitalk-container"></div>

   {% endif %}
  {% endif %}
  ````
  
4. 修改主题配置文件*_config.yml*
   1. 文件路径: **/themes/**
   2. 修改内容:
   
   ````
	   #gitalk评论
	gitalk:
	  enable: true
	  githubID: github用户名
	  repo: 用来存放comment的repo
	  clientID: 你的clientID
	  clientSecret: 你的clientSecret
	  adminUser: admin用户，只有admin才可以init issue
	  perPage: 15
	  pagerDirection: last
	  createIssueManually: false
	  distractionFreeMode: false
   ````

# 测试
`hexo clean`

`hexo g`

`hexo d`

## 最终结果
![图片2](https://res.cloudinary.com/hexo-mokeeqian/image/upload/v1566481823/hexo/2_oppyfh.png)

# 踩过的坑
+ *comment.swig*文件配置错误，注意所加代码的位置
+ *OAuth application*创建有错误，按以上做法即可
+ 粗心、大小写、配置文件写错

# 写在后面
不知道为什么在hexo中markdown会解析奇怪的东西，比如说我写了\`\{% include 'gitalk.swig' \%}\`这个东西，在`hexo g`的过程中，会报错，很奇怪的错误。
后来把这个post删除了，再生成就没有问题了，所以说，可以确定这个问题是出在我刚刚写的`.md`文件内容导致的。
## 解决步骤
+ 删除所有代码块，错误消失，还原所有内容
+ 删除\`\{% include 'gitalk.swig' \%}\`这个内容，错误消失
至此，可以知道，问题就出在\`\{% include 'gitalk.swig' \%}\`这段内容里，后来改成\`\`\`包含的代码块就没有问题。
所以说，遇到`\{\%`这样的字符需要转义，否则会被md解析。
## TODO
这里还要深入了解一下md的解析原理
