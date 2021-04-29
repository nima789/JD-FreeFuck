#!/bin/env bash
cat /etc/hosts | grep "raw.githubusercontent.com" -q
if [ $? -ne 0 ]; then
  echo "199.232.28.133 raw.githubusercontent.com" >>/etc/hosts
  echo "185.199.108.133 raw.githubusercontent.com" >>/etc/hosts
  echo "185.199.109.133 raw.githubusercontent.com" >>/etc/hosts
  echo "185.199.110.133 raw.githubusercontent.com" >>/etc/hosts
  echo "185.199.111.133 raw.githubusercontent.com" >>/etc/hosts
fi
## ======================================= 定 义 相 关 变 量 ===============================================
## 安装目录
BASE="/jd"
## 项目分支
JD_BASE_BRANCH="master"
## 项目地址
JD_BASE_URL="git@jd_base_gitee:supermanito/jd_base.git"
## 活动脚本库私钥
JD_KEY_URL="https://raw.githubusercontent.com/nima789/JD-FreeFuck/part2/.ssh/"
JD_KEY1="config"
JD_KEY2="jd_base"
JD_KEY3="jd_scripts"
JD_KEY4="known_hosts"

## 定义变量：
## 组合各个函数模块部署项目：
function Installation() {
    ## 根据各部分函数执行结果判定部署结果
    ## 判断环境条件决定是否退出部署脚本
    EnvJudgment
    EnvStructures
    ## 判定Nodejs是否安装成功，否则跳出
    VERIFICATION=$(node -v | cut -c2)
    if [ $VERIFICATION = "1" ]; then
        PrivateKeyInstallation
        ## 判定私钥是否安装成功，否则跳出
        ls /root/.ssh | grep jd_scripts -wq
        if [ $? -eq 0 ]; then
            ProjectDeployment
            SetConfig
            PanelJudgment
            UseNotes
        else
            PrivateKeyFailureTips
        fi
    else
        NodejsFailureTips
    fi
}

## 环境判定：
function EnvJudgment() {
    ## 当前用户判定：
    if [ $UID -ne 0 ]; then
        echo -e '\033[31m ------------ Permission no enough, please use user ROOT! ------------ \033[0m'
        exit
    fi
    ## 网络环境判定：
    ping -c 1 www.baidu.com >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        apt-get install -y iputils-ping
    fi
    ping -c 1 www.baidu.com >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo -e "\033[31m ----- Network connection error.Please check the network environment and try again later! ----- \033[0m"
        exit
    fi
}

## 环境搭建：
function EnvStructures() {
    Welcome
    ## 修改系统时区：
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime >/dev/null 2>&1
    timedatectl set-timezone "Asia/Shanghai" >/dev/null 2>&1
    ## 放行控制面板需要用到的端口
    firewall-cmd --zone=public --add-port=5678/tcp --permanent >/dev/null 2>&1
    systemctl reload firewalld >/dev/null 2>&1
    
        ## 更新软件源，列出索引
        apt update
        ## 卸载 Nodejs 旧版本，从而确保安装新版本
        apt remove -y nodejs npm >/dev/null 2>&1
        rm -rf /etc/apt/sources.list.d/nodesource.list
        ## 安装需要的软件包
        apt install -y wget curl net-tools openssh-server git perl moreutils cronie
        ## 安装 Nodejs 与 npm
        curl -sL https://deb.nodesource.com/setup_14.x | bash -
        DownloadTip
        apt install -y nodejs
        apt autoremove -y
}

## 部署私钥：
function PrivateKeyInstallation() {
    mkdir -p /root/.ssh
    ls $JD_KEY_BASE | grep jd_scripts -wq
    if [ $? -eq 0 ]; then
    rm -r $JD_KEY_BASE/$JD_KEY1
    rm -r $JD_KEY_BASE/$JD_KEY2
    rm -r $JD_KEY_BASE/$JD_KEY3
    rm -r $JD_KEY_BASE/$JD_KEY4
    fi
    ##下载私钥
    wget -P /root/.ssh $JD_KEY_URL$JD_KEY1
    wget -P /root/.ssh $JD_KEY_URL$JD_KEY2
    wget -P /root/.ssh $JD_KEY_URL$JD_KEY3
    wget -P /root/.ssh $JD_KEY_URL$JD_KEY4
    ## 安装私钥
    chmod 700 /root/.ssh
    chmod 600 /root/.ssh/$JD_KEY1
    chmod 600 /root/.ssh/$JD_KEY2
    chmod 600 /root/.ssh/$JD_KEY3
    chmod 600 /root/.ssh/$JD_KEY4  
}

## 项目部署：
function ProjectDeployment() {
    ## 卸载旧版本
    rm -rf $BASE
    rm -rf /usr/local/bin/jd
    rm -rf /usr/local/bin/git_pull
    rm -rf /usr/local/bin/rm_log
    rm -rf /usr/local/bin/export_sharecodes
    rm -rf /usr/local/bin/run_all
    ## 克隆项目
    git clone -b $JD_BASE_BRANCH $JD_BASE_URL $BASE
    ## 创建目录
    mkdir $BASE/config
    mkdir $BASE/log
    ## 根据安装目录配置定时任务
    sed -i "s#BASE#$BASE#g" $BASE/sample/computer.list.sample
    ## 创建项目配置文件与定时任务配置文件
    cp $BASE/sample/config.sh.sample $BASE/config/config.sh
    cp $BASE/sample/computer.list.sample $BASE/config/crontab.list
    ## 切换 npm 官方源为淘宝源
    npm config set registry http://registry.npm.taobao.org
    ## 安装控制面板功能
    cp $BASE/sample/auth.json $BASE/config/auth.json
    echo -e "{"user":"xz123","password":"20001201"}" > $BASE/config/auth.json
    cd $BASE/panel
    npm install || npm install --registry=https://registry.npm.taobao.org
    npm install -g pm2
    pm2 start ecosystem.config.js
    ## 拉取活动脚本
    bash $BASE/git_pull.sh
    bash $BASE/git_pull.sh >/dev/null 2>&1
    ## 创建软链接
    ln -sf $BASE/jd.sh /usr/local/bin/jd
    ln -sf $BASE/git_pull.sh /usr/local/bin/git_pull
    ln -sf $BASE/rm_log.sh /usr/local/bin/rm_log
    ln -sf $BASE/export_sharecodes.sh /usr/local/bin/export_sharecodes
    ln -sf $BASE/run_all.sh /usr/local/bin/run_all
    ## 定义全局变量
    echo "export JD_DIR=$BASE" >>/etc/profile
    source /etc/profile
}

## 判定控制面板安装结果：
function PanelJudgment() {
    netstat -tunlp | grep 5678 -wq
    PanelTestA=$?
    curl -sSL 127.0.0.1:5678 | grep "京东薅羊毛控制面板" -wq
    PanelTestB=$?
    if [ ${PanelTestA} -eq 0 ] || [ ${PanelTestB} -eq 0 ]; then
        PanelUseNotes
    else
        echo -e ''
        echo -e "\033[31m ------------------- 控制面板安装失败 ------------------- \033[0m"
    fi
}

## 欢迎语：
function Welcome() {
    echo -e ''
    echo -e '+---------------------------------------------------+'
    echo -e '|                                                   |'
    echo -e '|   =============================================   |'
    echo -e '|                                                   |'
    echo -e '|      欢迎使用《京东薅羊毛》一键部署 For Linux     |'
    echo -e '|                                                   |'
    echo -e '|   =============================================   |'
    echo -e '|                                                   |'
    echo -e '+---------------------------------------------------+'
    echo -e ''
    echo -e '#####################################################'
    echo -e ''
    echo -e "      当前系统时间  $(date +%Y-%m-%d) $(date +%H:%M)"
    echo -e ''
    echo -e '#####################################################'
    echo -e ''
    sleep 3s
}

## 下载提示：
function DownloadTip() {
    echo -e "\033[32m +----------------- 开 始 下 载 并 安 装 Nodejs -----------------+ \033[0m"
    echo -e "\033[32m |                                                               | \033[0m"
    echo -e "\033[32m |   因 Nodesource 无国内源，下载网速可能过慢请您耐心等候......  | \033[0m"
    echo -e "\033[32m |                                                               | \033[0m"
    echo -e "\033[32m +---------------------------------------------------------------+ \033[0m"
    echo -e ''
    echo -e ''
}

## 失败原因提示：
function PrivateKeyFailureTips() {
    echo -e ''
    echo -e "\033[31m -------------- 私钥安装失败，退出部署脚本 -------------- \033[0m"
    echo -e "\033[31m 原因：1. 在 /root/.ssh 目录下没有检测到私钥文件 \033[0m"
    echo -e "\033[31m      2. 可能由于 /root/.ssh 目录创建失败导致 \033[0m"
    echo -e "\033[31m      3. 权限不足的问题 \033[0m"
    exit
}
function NodejsFailureTips() {
    echo -e ''
    echo -e "\033[31m -------------- Nodejs安装失败，退出部署脚本 -------------- \033[0m"
    echo -e "\033[31m 原因：1. 由于网络环境导致软件包下载失败 \033[0m"
    echo -e "\033[31m      2. 您使用的 Linux 发行版可能不受本项目支持 \033[0m"
    exit
}

## 控制面板使用需知：
function PanelUseNotes() {
    echo -e ''
    echo -e "\033[32m +--------- 控 制 面 板 安 装 成 功 并 已 启 动 ---------+ \033[0m"
    echo -e "\033[32m |                                                       | \033[0m"
    echo -e "\033[32m |      本地访问：http://127.0.0.1:5678                  | \033[0m"
    echo -e "\033[32m |                                                       | \033[0m"
    echo -e "\033[32m |      外部访问：http://内部或外部IP地址:5678           | \033[0m"
    echo -e "\033[32m |                                                       | \033[0m"
    echo -e "\033[32m |      初始用户名：useradmin  初始密码：supermanito     | \033[0m"
    echo -e "\033[32m |                                                       | \033[0m"
    echo -e "\033[32m |      控制面板默认开机自启，如若失效请自行重启         | \033[0m"
    echo -e "\033[32m |                                                       | \033[0m"
    echo -e "\033[32m |      关于更多使用帮助请通过《使用与更新》教程获取     | \033[0m"
    echo -e "\033[32m |                                                       | \033[0m"
    echo -e "\033[32m +-------------------------------------------------------+ \033[0m"
    echo -e ''
    sleep 3s
}

## 项目使用需知：
function UseNotes() {
    echo -e ''
    echo -e "\033[32m =========================================== 一   键   部   署   成   功 =========================================== \033[0m"
    echo -e ''
    echo -e "\033[32m +-----------------------------------------------------------------------------------------------------------------+ \033[0m"
    echo -e "\033[32m |                                                                                                                 | \033[0m"
    echo -e "\033[32m | 注意：1. 本项目文件以及一键脚本的安装目录为$BASE                                                              | \033[0m"
    echo -e "\033[32m |                                                                                                                 | \033[0m"
    echo -e "\033[32m |       2. 为了保证项目脚本的正常运行，请不要更改任何组件的位置以避免出现未知的错误                               | \033[0m"
    echo -e "\033[32m |                                                                                                                 | \033[0m"
    echo -e "\033[32m |       3. git_pull.sh 为一键更新脚本，run_all.sh 为一键执行所有活动脚本                                          | \033[0m"
    echo -e "\033[32m |                                                                                                                 | \033[0m"
    echo -e "\033[32m |       4. 您可以通过项目安装目录内 course 目录下的 linux.md 文档来查看《使用与更新》教程                         | \033[0m"
    echo -e "\033[32m |                                                                                                                 | \033[0m"
    echo -e "\033[32m |       5. 手动执行 run_all.sh 脚本后无需守在电脑旁，会自动在最后运行挂机活动脚本                                 | \033[0m"
    echo -e "\033[32m |                                                                                                                 | \033[0m"
    if [ $SYSTEM = "Debian" ]; then
        echo -e "\033[32m |       6. 执行 run_all 脚本期间如果卡住，可按回车键尝试或通过命令 Ctrl + Z 跳过继续执行剩余活动脚本              | \033[0m"
    elif [ $SYSTEM = "RedHat" ]; then
        echo -e "\033[32m |       6. 执行 run_all 脚本期间如果卡住，可按回车键尝试或通过命令 Ctrl + C 跳过继续执行剩余活动脚本              | \033[0m"
    fi
    echo -e "\033[32m |                                                                                                                 | \033[0m"
    echo -e "\033[32m |       7. 由于京东活动一直变化可能会出现无法参加活动、报错等正常现象，可手动执行一键更新脚本完成更新             | \033[0m"
    echo -e "\033[32m |                                                                                                                 | \033[0m"
    echo -e "\033[32m |       8. 除手动运行活动脚本外本项目可以通过定时的方式全天候自动运行活动脚本，具体运行记录可通过日志查看         | \033[0m"
    echo -e "\033[32m |                                                                                                                 | \033[0m"
    echo -e "\033[32m |       9. 项目已配置好 Crontab 定时任务，定时配置文件 crontab.list 会通过活动脚本的更新而同步更新                | \033[0m"
    echo -e "\033[32m |                                                                                                                 | \033[0m"
    echo -e "\033[32m |       10. 之前填入的 Cookie 部分内容具有一定的时效性，若提示失效请根据教程重新获取并通过命令手动更新            | \033[0m"
    echo -e "\033[32m |                                                                                                                 | \033[0m"
    echo -e "\033[32m |       11. 我不是活动脚本的开发者，但后续使用遇到任何问题都可访问本项目寻求帮助，制作不易，理解万岁              | \033[0m"
    echo -e "\033[32m |                                                                                                                 | \033[0m"
    echo -e "\033[32m +-----------------------------------------------------------------------------------------------------------------+ \033[0m"
}

## 执行相关函数开始部署
Installation
