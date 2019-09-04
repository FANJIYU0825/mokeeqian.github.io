#!/bin/bash
# 用于对hexo博客源码文件进行备份


git add .
git commit -m "更新源码文件"
sleep 10s
git push origin hexo-back
