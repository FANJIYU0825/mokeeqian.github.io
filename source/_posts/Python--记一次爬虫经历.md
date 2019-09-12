title: Python--记一次爬虫经历
author: Qian Jipeng
tags:
  - Python爬虫
  - 正方教务
categories:
  - Python
date: 2019-09-11 21:33:00
---
# 记一次Python爬虫经历
　　这几天，老师让我写一个爬虫，抓取正方教务系统的数据，想想自己很久没有搞Python了，于是答应了，刚好自己之前有过这样的想法，爬一爬教务处的网站，以后查信息什么的就方便多了。</br>
　　其实自己之前写过的爬虫都是静态网站的，直接get请求一下，解析相应的网页内容就能实现了，但是这次做的是动态网站，需要提交验证码，好在观察了一下，验证码只是简单的数字验证码，没有像铁总的12306那样反人类的验证码。话不多说，开干。</br>


# 实现过程

## 登录实现
![](http://px1awapyv.bkt.clouddn.com/1.png)
上图中的表单正是我们登录系统的，获取它的id，然后我们人为把我们的登录信息传递给这些id，我们再来看看请求头，请求方式是post，也就是说，我们要把headers、cookies、data这些参数一起post到web服务器上。
![](http://px1awapyv.bkt.clouddn.com/2.png)

下面的这是我们的用户信息，也就是浏览器中的输入框和选择按钮，其中`__VIEWSTATE`这个属性好像是sessionId？我尝试了一下不带这个参数进行post，结果没有登录成功。咱也不知道，赞只管用就行了。
来说明一下：</br>
<font color=red>
TextBox1是用户名</br>
TextBox2是用户密码</br>
TextBox3是验证码</br>
RadioButtonList1是用户身份，我们默认的学生就好</br>
Button1是登录按钮</br></font>
![](http://px1awapyv.bkt.clouddn.com/3.png)

等等，是不是忘了什么重要的事情？验证码呢？</br>
![](http://px1awapyv.bkt.clouddn.com/4.png)
这是验证码所在的url，我们等下可以get一下，抓取网页内容，然后将验证码保存下来。</br>

## 查询实现
查询功能就比较容易实现了，只要我们获取到了cookies就可以了，然后每次进行不同的查询时，只要更新一下headers中的`__VIEWSTATE`属性的值就可以了，然后抓取相应的网页内容，进行信息的提取，可以发现，我们的信息主要都是表格布局，所以简单来说只要用正则匹配一下就可以简单获取信息了。

## 代码实现
**1. config_loader.py**
```
#!/usr/bin/env python3
# encoding=utf-8
# Copyright: Qian Jipeng(C) 2019

import configparser
cf = configparser.ConfigParser()

cf.read("config.conf")
section = cf.sections() # a list
#print(section)
#print(cf.options('user'))

def getUserId():
	return str(cf.get('user', 'userid'))

def getUserPassword():
	return str(cf.get('user', 'password'))

def getIndexUrl():
	return str(cf.get('web', 'index'))

def getLoginUrl():
	return str(cf.get('web', 'loginurl'))

def getCheckcodeUrl():
	return str(cf.get('web', 'checkcodeurl'))
```

**2. main.py**
```
#!/usr/bin/env python3
# encoding=utf-8
# Copyright: Qian Jipeng(C) 2019
"""
TODO:
	数据清洗与进一步解析!
"""

import os
import re
import urllib.parse

import requests
import config_loader as cfl
from html.parser import *
from PIL import Image


class TagParser(HTMLParser):
	# view_state = list()     # 有点像C++中的static变量，是类变量，不可行

	def __init__(self):
		super().__init__()
		self.view_state = list()    # 用来存放viewstate

	def __del__(self):
		del self.view_state         # 释放资源

	def handle_starttag(self, tag, attrs):
		if tag == 'input':
			attrs = dict(attrs)
			if attrs.__contains__('name') and attrs['name'] == '__VIEWSTATE':
				self.view_state.append(attrs['value'])

	def doParse(self, webData):
		self.feed(data=webData)


class Login:

	def __init__(self):
		self.user_id = cfl.getUserId()
		self.user_pwd = cfl.getUserPassword()
		self.user_name = ""
		self.login_url = cfl.getLoginUrl()
		self.checkcode_url = cfl.getCheckcodeUrl()
		self.cookies = requests.get(self.login_url).cookies
		self.headers = {
				'User-Agent': r'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.100 Safari/537.36',
		}

		# self.query_headers = {
		# 	'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3',
		# 	'Accept-Encoding': 'gzip, deflate',
		# 	'Accept-Language': 'en-US,en;q=0.9',
		# 	'Connection': 'keep-alive',
		# 	'Content-Type': 'text/html; charset=gb2312',
		# 	'Referer': '',   # cfl.getIndexUrl() + 'xskbcx.aspx?xh=' + self.user_id + "&xm=" + self.user_name + "&gnmkdm=" + kdn_code,
		# 	# 'Referer': website + 'xs_main.aspx?xh=' + userxh,
		# 	'Upgrade-Insecure-Requests': '1',
		# 	'User-Agent': r'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.100 Safari/537.36',
		# }

		self.config = {
			'__VIEWSTATE': '',  # viewstate
			'TextBox1': self.user_id,     # userid
			'TextBox2': self.user_pwd,     # password
			'TextBox3': '',  # checkcode
			'RadioButtonList1': '%D1%A7%C9%FA',     # session
			'Button1': "",
			'lbLanguage': '',
		}
		self.tag_parser = TagParser()
		self.tag_parser.doParse(requests.get(self.login_url).text)    # 解析

	# 获取验证码并显示
	def getCheckCodePic(self, filename):

		pic = requests.post(url=self.checkcode_url, cookies=self.cookies, headers=self.headers)
		if os.path.exists(filename):
			os.remove(filename)
		# write as byte
		with open(filename, 'wb') as filewriter:
			filewriter.write(pic.content)

		image = Image.open(filename)        # PIL
		image.show()

	# # 更新headers字典，在查询之前，必须先调用该函数
	# def updateQueryHeaders(self, referer):
	# 	self.query_headers['Referer'] = referer

	# 应该在获取验证码后调用
	def updateConfig(self, viewstate, checkcode):
		self.config['__VIEWSTATE'] = viewstate
		self.config['TextBox3'] = checkcode

	# 是否登陆成功
	def checkIfSuccess(self, webContent):
		pattern = r'<title>(.*?)</title>'
		items = re.findall(pattern, webContent.text)
		if items[0] == "欢迎使用正方教务管理系统！请登录":      # 特征匹配
			# print("登陆失败")
			return False
		else:
			# print("登陆成功")
			# 抓取名字
			catch = '<span id="xhxm">(.*?)</span></em>'
			name = re.findall(catch, webContent.text)
			name = name[0][:-2]
			# name = name[:-2]
			print(name)
			self.user_name = urllib.parse.quote(name.encode("gb2312"))      # 更新用户姓名
			return True

# # Not used
# class Query(Login):
#
# 	def __init__(self):
# 		Login.__init__(self)
# 		self.course_url = cfl.getIndexUrl() + "xskbcx.aspx?xh=" + self.user_id + "&xm=" + self.user_name + "&gnmkdm=" + "N121603"
# 		self.exam_url = cfl.getIndexUrl() + "xskscx.aspx?xh=" + self.user_id + "&xm=" + self.user_name + "&gnmkdm=" + "N121604"
# 		self.query_state = ""
# 		self.query_config = {
# 			'__EVENTTARGET': '',
# 			'__EVENTARGUMENT': '',
# 			'__VIEWSTATE': '',
# 		}
# 		self.query_headers = {
# 			'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3',
# 			'Accept-Encoding': 'gzip, deflate',
# 			'Accept-Language': 'en-US,en;q=0.9',
# 			'Connection': 'keep-alive',
# 			'Content-Type': 'text/html; charset=gb2312',
# 			#'Referer': '',
# 			# cfl.getIndexUrl() + 'xskbcx.aspx?xh=' + self.user_id + "&xm=" + self.user_name + "&gnmkdm=" + kdn_code,
# 			'Upgrade-Insecure-Requests': '1',
# 			'User-Agent': r'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.100 Safari/537.36',
# 		}
#
# 	def updateQueryConfig(self, queryviewstate):
# 		self.query_config['__VIEWSTATE'] = queryviewstate
#
# 	def updateQueryHeaders(self, referer):
# 		self.query_headers['Referfer'] = referer
#
# 	def updateQueryState(self):
# 		content = requests.get(url=self.course_url, cookies=self.cookies, headers=self.headers)
# 		print(content.text)
# 		catch = '<input type="hidden" name="__VIEWSTATE" value="(.*?)" />'
# 		self.query_state = re.findall(catch, content.text)[0]
#
# 	# 课表查询
# 	def queryCourse(self):
# 		# 先配置headers
# 		self.updateQueryHeaders(self.course_url)
#
# 		# print(self.query_headers)
#
# 		self.updateQueryState()
# 		self.updateQueryConfig(self.query_state)
# 		print("config")
# 		print(self.query_config)
# 		content = requests.session().get(url=self.course_url, data=self.query_config,
# 		                                 headers=self.query_headers, cookies=super().cookies)
# 		# 保存表格
# 		catch = '<td>(.*?)</td>'
# 		table = re.findall(catch, content.text)
#
# 		f = open("test.txt", "w")
# 		for each_line in table:
# 			if "&nbsp" in each_line:
# 				# TODO: 数据清洗
# 				pass
# 			f.write(each_line + "\n")
# 		f.close()


# 全局函数，对外接口
def doLogin(loginobject:Login, filename:str):
	loginobject.getCheckCodePic(filename)
	checkcode = input("输入验证码: ")
	loginobject.updateConfig(loginobject.tag_parser.view_state[0], checkcode)
	# print(loginobject.config)
	content = requests.post(url=loginobject.login_url, data=loginobject.config,
	                        headers=loginobject.headers, cookies=loginobject.cookies)

	if loginobject.checkIfSuccess(content):
		print("登陆成功!!!")
	else:
		print("登录失败~~~")

	# query = Query()
	# query.queryCourse()

	print("-------------开始查询----------------")
	# 配置区
	course_url = cfl.getIndexUrl() + 'xskbcx.aspx?xh=' + loginobject.user_id + "&xm=" + loginobject.user_name + "&gnmkdm=" + "N121603"
	exam_url = cfl.getIndexUrl() + 'xskscx.aspx?xh=' + loginobject.user_id + "&xm=" + loginobject.user_name + "&gnmkdm=" + "N121604"
	classexam_url = cfl.getIndexUrl() + 'xsdjkscx.aspx?xh=' + loginobject.user_id + "&xm=" + loginobject.user_name + "&gnmkdm=" + "N121606"
	plan_url = cfl.getIndexUrl() + 'pyjh.aspx?xh=' + loginobject.user_id + "&xm=" + loginobject.user_name + "&gnmkdm=" + "N121607"
	select_course_url = cfl.getIndexUrl() + 'pyjh.aspx?xh=' + loginobject.user_id + "&xm=" + loginobject.user_name + "&gnmkdm=" + "N121615"
	add_exam_url = cfl.getIndexUrl() + 'xsbkkscx.aspx?xh=' + loginobject.user_id + "&xm=" + loginobject.user_name + "&gnmkdm=" + "N121613"


	query_config = {
		'__EVENTTARGET': '',
		'__EVENTARGUMENT': '',
		'__VIEWSTATE': '',
	}
	query_headers = {
		'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3',
		'Accept-Encoding': 'gzip, deflate', 'Accept-Language': 'en-US,en;q=0.9', 'Connection': 'keep-alive',
		'Content-Type': 'text/html; charset=gb2312', 'Referer': '', 'Upgrade-Insecure-Requests': '1',
		'User-Agent': r'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.100 Safari/537.36'}
	# end 配置区

	# ------------------------- 查询课表 ----------------------
	query_headers['Referer'] = course_url
	# 先get一下，获取view_state
	course_html = requests.get(course_url, cookies=loginobject.cookies,
	                    headers=query_headers)
	catch = '<input type="hidden" name="__VIEWSTATE" value="(.*?)" />'
	query_state = re.findall(catch, course_html.text)[0]
	query_config['__VIEWSTATE'] = query_state
	del query_state
	course = requests.session().get(url=course_url, data=query_config,
	                                headers=query_headers, cookies=loginobject.cookies)
	# print(course.text)        # 测试ok
	# 写入文件
	catch = '<td>(.*?)</td>'
	course_table = re.findall(catch, course.text)
	del course

	f = open("course_table.txt", "w")
	for each_line in course_table:
		if "&nbsp" in each_line:
			# TODO: 数据清洗
			pass
		f.write(each_line + "\n")
	f.close()
	del course_table
	# ------------------------- 课表结束 ------------------------

	# ------------------------- 查询考试安排 -----------------------
	query_headers['Referer'] = exam_url
	exam_html = requests.get(exam_url, cookies=loginobject.cookies,
	                           headers=query_headers)
	catch = '<input type="hidden" name="__VIEWSTATE" value="(.*?)" />'
	query_state = re.findall(catch, exam_html.text)[0]
	query_config['__VIEWSTATE'] = query_state
	del query_state
	exam = requests.session().get(url=exam_url, data=query_config,
	                                headers=query_headers, cookies=loginobject.cookies)
	# print(course.text)        # 测试ok
	# 写入文件
	catch = '<td>(.*?)</td>'
	exam_table = re.findall(catch, exam.text)
	del exam

	f = open("exam_arrangement.txt", "w")
	for each_line in exam_table:
		if "&nbsp" in each_line:
			# TODO: 数据清洗
			pass
		f.write(each_line + "\n")
	f.close()
	del exam_table
	# ----------------------------------- 结束 -----------------------------------------

	# ----------------------------------等级考试成绩查询 --------------------------------
	query_headers['Referer'] = classexam_url
	classexam_html = requests.get(classexam_url, cookies=loginobject.cookies,
	                         headers=query_headers)
	catch = '<input type="hidden" name="__VIEWSTATE" value="(.*?)" />'
	query_state = re.findall(catch, classexam_html.text)[0]
	query_config['__VIEWSTATE'] = query_state
	del query_state
	classexam = requests.session().get(url=classexam_url, data=query_config,
	                              headers=query_headers, cookies=loginobject.cookies)
	# print(course.text)        # 测试ok
	# 写入文件
	catch = '<td>(.*?)</td>'
	classexam_table = re.findall(catch, classexam.text)
	del classexam

	f = open("class_exam.txt", "w")
	for each_line in classexam_table:
		if "&nbsp" in each_line:
			# TODO: 数据清洗
			pass
		f.write(each_line + "\n")
	f.close()
	del classexam_table
	# --------------------------- 结束 --------------------------

	# -------------------- 培养计划查询 ------------------------
	query_headers['Referer'] = plan_url
	plan_html = requests.get(plan_url, cookies=loginobject.cookies,
	                         headers=query_headers)
	catch = '<input type="hidden" name="__VIEWSTATE" value="(.*?)" />'
	query_state = re.findall(catch, plan_html.text)[0]
	query_config['__VIEWSTATE'] = query_state
	del query_state
	plan = requests.session().get(url=plan_url, data=query_config,
	                              headers=query_headers, cookies=loginobject.cookies)
	# print(course.text)        # 测试ok
	# 写入文件
	catch = '<td>(.*?)</td>'
	plan_table = re.findall(catch, plan.text)
	del plan

	f = open("development_plan.txt", "w")
	for each_line in plan_table:
		if "&nbsp" in each_line:
			# TODO: 数据清洗
			pass
		f.write(each_line + "\n")
	f.close()
	del plan_table
	# --------------------- 结束 ----------------------------

	# --------------------- 学生选课情况查询 ------------------------------
	query_headers['Referer'] = select_course_url
	select_course_html = requests.get(select_course_url, cookies=loginobject.cookies,
	                         headers=query_headers)
	catch = '<input type="hidden" name="__VIEWSTATE" value="(.*?)" />'
	query_state = re.findall(catch, select_course_html.text)[0]
	query_config['__VIEWSTATE'] = query_state
	del query_state
	select_course = requests.session().get(url=select_course_url, data=query_config,
	                              headers=query_headers, cookies=loginobject.cookies)
	# print(course.text)        # 测试ok
	# 写入文件
	catch = '<td>(.*?)</td>'
	select_course_table = re.findall(catch, select_course.text)
	del select_course

	f = open("select_course.txt", "w")
	for each_line in select_course_table:
		if "&nbsp" in each_line:
			# TODO: 数据清洗
			pass
		f.write(each_line + "\n")
	f.close()
	del select_course_table
	# --------------------- 结束 ----------------------------

	# ------------------- 补考开始查询 ----------------------
	query_headers['Referer'] = add_exam_url
	add_exam_html = requests.get(add_exam_url, cookies=loginobject.cookies,
	                         headers=query_headers)
	catch = '<input type="hidden" name="__VIEWSTATE" value="(.*?)" />'
	query_state = re.findall(catch, add_exam_html.text)[0]
	query_config['__VIEWSTATE'] = query_state
	del query_state
	add_exam = requests.session().get(url=add_exam_url, data=query_config,
	                              headers=query_headers, cookies=loginobject.cookies)
	# print(course.text)        # 测试ok
	# 写入文件
	catch = '<td>(.*?)</td>'
	add_exam_table = re.findall(catch, add_exam.text)
	del add_exam

	f = open("add_exam.txt", "w")
	for each_line in add_exam_table:
		if "&nbsp" in each_line:
			# TODO: 数据清洗
			pass
		f.write(each_line + "\n")
	f.close()
	del add_exam_table
	# ------------------- 结束 ------------------------

	print("------------查询成功-----------")


if __name__ == '__main__':

	login = Login()
	doLogin(login, "./checkcode.png")
```


