#!/bin/bash
# 用于对hexo博客源码文件进行备份

git add source themes scaffolds _config.yml package.json package-lock.json _admin-config.yml
git commit -m "更新源码文件"
git push origin hexo-back
