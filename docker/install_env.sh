#!/usr/bin/env bash
## 安装环境所需要的软件包

ShellDir=${JD_DIR:-$(
    cd $(dirname $0)
    pwd
)}
[[ ${JD_DIR} ]] && ShellJd=jd || ShellJd=${ShellDir}/jd.sh
ScriptsDir=${ShellDir}/scripts
cd ${ScriptsDir}
npm install -g npm npm-install-peers
npm install -g ts-node typescript axios --unsafe-perm=true --allow-root
echo -e "\n 忽略 WARN 警告类输出内容！\n"
