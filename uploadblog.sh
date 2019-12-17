#!/bin/bash
# 一站式发布博文脚本

hexo clean

hexo g

cp -R ../5201314 ./public	# for LW
cp ../5201314/Love_files/rose.html ./public


hexo d
