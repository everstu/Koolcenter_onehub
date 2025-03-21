#!/bin/sh
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'

echo_date "正在删除插件资源文件..."
sh /koolshare/scripts/onehub_config.sh stop
rm -rf /koolshare/configs/onehub >/dev/null 2>&1
rm -rf /koolshare/scripts/onehub_config.sh >/dev/null 2>&1
rm -rf /koolshare/webs/Module_onehub.asp >/dev/null 2>&1
rm -rf /koolshare/res/*onehub* >/dev/null 2>&1
find /koolshare/init.d/ -name "*onehub*" | xargs rm -rf >/dev/null 2>&1
rm -rf /koolshare/bin/onehub >/dev/null 2>&1
sed -i '/onehub_watchdog/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
echo_date "插件资源文件删除成功..."

rm -rf /koolshare/scripts/uninstall_onehub.sh >/dev/null 2>&1
echo_date "已成功移除插件... Bye~Bye~"