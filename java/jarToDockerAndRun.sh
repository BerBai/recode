#!/bin/bash

#-----------使用说明-----------#
#Author: bai5775@outlook.com
#v2 2021.04.27
#1.自动创建项目路径
#v1 2021.04.17
#1.备份jar包
#2.停止、删除docker容器
#3.删除旧docker镜像
#4.构建新docker镜像
#5.运行docker容器

# 操作/项目路径(Dockerfile存放的路径)
BASE_PATH=/work/project
# 源jar路径  
SOURCE_PATH=/var/lib/jenkins/workspace/jenkins-demo/target  
# 打包后jar名字
SERVER_NAME=demo-0.0.1-SNAPSHOT
# docker 镜像/容器名字
DOCKER_NAME=demo
# 获取容器id
CID=$(docker ps | grep "$DOCKER_NAME" | awk '{print $1}')
# 获取镜像id
IID=$(docker images | grep "$DOCKER_NAME" | awk '{print $3}')
# 获取时间
DATE=`date +%Y%m%d%H%M`
 
# 将最新的jar包移动到项目环境
function transfer(){
    echo "最新的jar包 $SOURCE_PATH/$SERVER_NAME.jar 迁移至 $BASE_PATH ...."
        cp $SOURCE_PATH/$SERVER_NAME.jar $BASE_PATH 
    echo "迁移完成"
}
 
# 备份原先的jar包
function backup(){
	echo "检测项目文件夹$BASE_PATH是否存在"
	if [ ! -d "$BASE_PATH/backup" ];then
      	mkdir -p $BASE_PATH/backup
    else
      	echo "$BASE_PATH文件夹已经存在"
    fi
    
	if [ -f "$BASE_PATH/$SERVER_NAME.jar" ]; then
    	echo "$SERVER_NAME.jar 备份..."
        	mv $BASE_PATH/$SERVER_NAME.jar $BASE_PATH/$SERVER_NAME-$DATE.jar
        	mv $BASE_PATH/$SERVER_NAME-$DATE.jar $BASE_PATH/backup
        echo "备份 $SERVER_NAME.jar 完成"
    else
    	echo "$BASE_PATH/$SERVER_NAME.jar不存在，跳过备份"
    fi
}
 
# 构建docker镜像
function build(){
	if [ -n "$IID" ]; then
		echo "存在$DOCKER_NAME镜像，IID=$IID"
        if [ -n "$CID" ]; then
			echo "存在正在运行的$DOCKER_NAME容器，CID=$CID"
	        docker stop $DOCKER_NAME
            docker rm $DOCKER_NAME
			echo "停止并删除$DOCKER_NAME容器，CID=$CID"
    	fi
	    docker rmi $DOCKER_NAME
        echo "删除docker $DOCKER_NAME镜像"
	fi
	
	cd $BASE_PATH
	echo "进入$BASE_PATH目录，开始构建镜像"
	docker build -t $DOCKER_NAME .
	echo "构建镜像完成"
}
 
# 运行docker容器
function run(){
	docker run --name $DOCKER_NAME -d -p 8082:8080 $DOCKER_NAME
	echo "$DOCKER_NAME容器 运行完成"
	echo "检测运行情况"
	CID=$(docker ps | grep "$DOCKER_NAME" | awk '{print $1}')
	if [ -n "$CID" ]; then
		echo "容器$DOCKER_NAME 运行成功"
	else
		echo "容器$DOCKER_NAME 运行失败"
	fi
		
}
function main(){
	backup
	transfer
	build
    run
}
 
# 入口
main