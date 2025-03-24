#!/bin/sh

source /koolshare/scripts/base.sh
eval $(dbus export onehub_)
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'
OnehubBaseDir=/koolshare/configs/onehub
ONEHUB_RUN_LOG_DIR=/tmp/upload/onehub_run_log/
LOG_FILE=/tmp/upload/onehub_log.txt
LOCK_FILE=/var/lock/onehub_run.lock
BASH=${0##*/}
ARGS=$@
#初始化配置变量
port=#监听端口
userTokenSecret=#用户Apitoken密钥
sessionSecret=#Session密钥
sqlDsn=#数据库地址
redisConnString=#Redis连接地址
channelTestFrequency=#频道测试频率
globalApiRateLimit=#全局Api速率限制
globalWebRateLimit=#全局Web速率限制

set_lock() {
	exec 233> ${LOCK_FILE}
	flock -n 233 || {
		# bring back to original log
		http_response "$ACTION"
		exit 1
	}
}

unset_lock() {
	flock -u 233
	rm -rf ${LOCK_FILE}
}

number_test() {
	case $1 in
		'' | *[!0-9]*)
		echo 1
	;;
	*)
		echo 0
	;;
	esac
}

dbus_rm() {
	# remove key when value exist
	if [ -n "$1" ]; then
		dbus remove $1
	fi
}

check_run_log(){
	local REAL_RUN
	local IS_INIT
	local i=40
	until [ -n "${REAL_RUN}" ]; do
		usleep 300000
		i=$(($i - 1))
		# 检测日志文件是否存在
		if [ -f "${ONEHUB_RUN_LOG_DIR}one-hub.log" ]; then
			REAL_RUN=$(cat ${ONEHUB_RUN_LOG_DIR}one-hub.log |grep "Task | running")
			# 如果IS_INIT为空
			if [ -z "${IS_INIT}" ]; then
				IS_INIT=$(cat ${ONEHUB_RUN_LOG_DIR}one-hub.log |grep "no user exists, create a root user for you")
				# 如果IS_INIT不为空，说明是初始化，要提醒用户初始化账户和密码
				if [ -n "${IS_INIT}" ]; then
					echo_date "⚠️检测到 OneHub 初始化安装，请耐心等待！"
					echo_date "ℹ️初始用户：root"
					echo_date "ℹ️初始密码：123456"
					echo_date "⚠️请尽快登录 OneHub 控制面板修改密码！"
				fi
			fi
		fi
		if [ "$i" -lt 1 ]; then
			echo_date "🔴未检测到 OneHub 启动成功，请自行查看 OneHub 启动日志！"
			return
		fi
	done
	echo_date "✅️OneHub 已启动，请打开控制面板查看！"
}

detect_running_status() {
	local BINNAME=$1
	local PID
	local i=40
	until [ -n "${PID}" ]; do
		usleep 250000
		i=$(($i - 1))
		PID=$(pidof ${BINNAME})
		if [ "$i" -lt 1 ]; then
			echo_date "🔴$1进程启动失败，请检查你的配置！"
			return
		fi
	done
	echo_date "🟢$1进程启动成功，pid：${PID}"
	check_run_log
}

check_usb2jffs_used_status() {
	# 查看当前/jffs的挂载点是什么设备，如/dev/mtdblock9, /dev/sda1；有usb2jffs的时候，/dev/sda1，无usb2jffs的时候，/dev/mtdblock9，出问题未正确挂载的时候，为空
	local cur_patition=$(df -h | /bin/grep /jffs | awk '{print $1}')
	local jffs_device="not mount"
	if [ -n "${cur_patition}" ]; then
		jffs_device=${cur_patition}
	fi
	local mounted_nu=$(mount | /bin/grep "${jffs_device}" | grep -E "/tmp/mnt/|/jffs" | /bin/grep -c "/dev/s")
	if [ "${mounted_nu}" -eq "2" ]; then
		echo "1" #已安装并成功挂载
	else
		echo "0" #未安装或未挂载
	fi
}

#检查已开启插件
check_enable_plugin() {
	echo_date "ℹ️当前已开启如下插件："
	echo_date "➡️"$(dbus listall | grep 'enable=1' | awk -F '_' '!a[$1]++' | awk -F '_' '{print "dbus get softcenter_module_"$1"_title"|"bash"}' | tr '\n' ',' | sed 's/,$/ /')
}

#检查内存是否合规
check_memory() {
	local swap_size=$(free | grep Swap | awk '{print $2}')
	echo_date "ℹ️检查系统内存是否合规！"
	if [ "$swap_size" != "0" ]; then
		echo_date "✅️当前系统已经启用虚拟内存！容量：${swap_size}KB"
	else
		local memory_size=$(free | grep Mem | awk '{print $2}')
		if [ "$memory_size" != "0" ]; then
			if [ $memory_size -le 750000 ]; then
				echo_date "❌️插件启动异常！"
				echo_date "❌️检测到系统内存为：${memory_size}KB，需挂载虚拟内存！"
				echo_date "❌️程序对路由器开销极大，请挂载1G及以上虚拟内存后重新启动插件！"
				stop_process
				exit
			else
				echo_date "⚠️程序对路由器开销极大，建议挂载1G及以上虚拟内存，以保证稳定！"
			fi
		else
			echo_date"⚠️未查询到系统内存，请自行注意系统内存！"
		fi
	fi
	echo_date "=============================================="
}
#实现随机密码
random_password() {
	# 生成16 字节随机密码,输出为 32 位十六进制字符串
	local random_length=$1
	# 如果random_length为空，则默认16
	if [ -z "${random_length}" ]; then
		random_length=16
	fi
	echo $(openssl rand -hex ${random_length});
}

genDefaultConfig(){
	# onehub_port 为空时，设置默认值
	if [ -z "${onehub_port}" ]; then
		dbus set onehub_port="3000"
	fi
	# onehub_user_token_secret 为空时，设置默认值
	if [ -z "${onehub_user_token_secret}" ]; then
		dbus set onehub_user_token_secret=$(random_password 32)
	fi
	# onehub_session_secret 为空时，设置默认值
	if [ -z "${onehub_session_secret}" ]; then
		dbus set onehub_session_secret=$(random_password 16)
	fi
	# 给变量赋值
	port=${onehub_port}
	userTokenSecret=${onehub_user_token_secret}
	sessionSecret=${onehub_session_secret}
	sqlDsn=${onehub_sqldsn}
	redisConnString=${onehub_redisconnstring}
	channelTestFrequency=${onehub_channeltestfrequency}
	globalApiRateLimit=${onehub_globalapiratelimit}
	globalWebRateLimit=${onehub_globalwebratelimit}
}


start_process() {
	rm -rf ${ONEHUB_RUN_LOG_DIR}
	if [ "${onehub_watchdog}" == "1" ]; then
		echo_date "🟠启动 OneHub 进程，开启进程实时守护..."
		mkdir -p /koolshare/perp/onehub
		cat >/koolshare/perp/onehub/rc.main <<-EOF
		#!/bin/sh
		source /koolshare/scripts/base.sh
		# 导入环境变量
		export USER_TOKEN_SECRET=${userTokenSecret}
		export SESSION_SECRET=${sessionSecret}
		export SQL_DSN=${sqlDsn}
		export REDIS_CONN_STRING=${redisConnString}
		export CHANNEL_TEST_FREQUENCY=${channelTestFrequency}
		export GLOBAL_API_RATE_LIMIT=${globalApiRateLimit}
		export GLOBAL_WEB_RATE_LIMIT=${globalWebRateLimit}
		# 进入运行目录
		cd ${OnehubBaseDir}
		# 组装命令
		CMD="/koolshare/bin/onehub --port=${port} --log-dir=${ONEHUB_RUN_LOG_DIR}"
		if test \${1} = 'start' ; then
		exec \$CMD
		fi
		exit 0

		EOF
		chmod +x /koolshare/perp/onehub/rc.main
		chmod +t /koolshare/perp/onehub/
		sync
		perpctl A onehub >/dev/null 2>&1
		perpctl u onehub >/dev/null 2>&1
		detect_running_status onehub
	else
		echo_date "🟠启动 OneHub 进程..."
		rm -rf /tmp/onehub.pid
		export USER_TOKEN_SECRET=${userTokenSecret}
		export SESSION_SECRET=${sessionSecret}
		export SQL_DSN=${sqlDsn}
		export REDIS_CONN_STRING=${redisConnString}
		export CHANNEL_TEST_FREQUENCY=${channelTestFrequency}
		export GLOBAL_API_RATE_LIMIT=${globalApiRateLimit}
		export GLOBAL_WEB_RATE_LIMIT=${globalWebRateLimit}
		start-stop-daemon --start \
		--quiet \
		--make-pidfile \
		--pidfile /tmp/onehub.pid \
		--background \
		--startas /bin/sh \
		-- -c \
		"cd \"$OnehubBaseDir\" && \
		exec /koolshare/bin/onehub --port=\"$port\" --log-dir=\"$ONEHUB_RUN_LOG_DIR\" 2>&1"
		detect_running_status onehub
	fi
}

start() {
	# 0. prepare folder if not exist
	mkdir -p ${OnehubBaseDir}

	# 1. system_check
	echo_date "==================== 系统检测 ===================="
	#1.1 memory_check
	check_memory
	#1.2 enable_plugin
	check_enable_plugin
	#1.3 check_jffs
	local USB2JFFS=$(check_usb2jffs_used_status)
	if [ "${USB2JFFS}" == "1" ]; then
		echo_date "✅已挂载USB2JFFS，插件可正常运行！"
	else
		echo_date "⚠️未挂载USB2JFFS，插件可能无法正常运行！"
	fi
	echo_date "==================== 系统检测结束 ===================="

	# 2. stop first
	stop_process

	# 3. gen default config
	genDefaultConfig

	# 4. gen version info everytime
	/koolshare/bin/onehub --version > ${OnehubBaseDir}/.version
	local BIN_VER=$(cat ${OnehubBaseDir}/.version )
	if [ -n "${BIN_VER}" ]; then
		dbus set onehub_binver=${BIN_VER}
	fi

	# 5. start process
	start_process

	# 6. open port
	if [ "${onehub_open_port}" == "1" ]; then
		close_port >/dev/null 2>&1
		open_port
	fi
}

stop_process() {
	local ONEHUB_PID=$(pidof onehub)
	if [ -n "${ONEHUB_PID}" ]; then
		echo_date "⛔关闭 OneHub 进程..."
		if [ -f "/koolshare/perp/onehub/rc.main" ]; then
			perpctl d onehub >/dev/null 2>&1
		fi
		rm -rf /koolshare/perp/onehub
		killall onehub >/dev/null 2>&1
		kill -9 "${ONEHUB_PID}" >/dev/null 2>&1
	fi
}

stop_plugin() {
	# 1 stop onehub
	stop_process

	# 2. remove log
	rm -rf ${ONEHUB_RUN_LOG_DIR}one-hub.log

	# 3. close port
	close_port
}

open_port() {
	local CM=$(lsmod | grep xt_comment)
	local OS=$(uname -r)
	if [ -z "${CM}" -a -f "/lib/modules/${OS}/kernel/net/netfilter/xt_comment.ko" ]; then
		echo_date "ℹ️加载xt_comment.ko内核模块！"
		insmod /lib/modules/${OS}/kernel/net/netfilter/xt_comment.ko
	fi

	if [ $(number_test ${onehub_port}) != "0" ]; then
		dbus set onehub_port="3000"
	fi

	# 开启IPV4防火墙端口
	local MATCH=$(iptables -t filter -S INPUT | grep "onehub_rule")
	if [ -z "${MATCH}" ]; then
		echo_date "🧱添加防火墙入站规则，打开 onehub 端口： ${onehub_port}"
		iptables -I INPUT -p tcp --dport ${onehub_port} -j ACCEPT -m comment --comment "onehub_rule" >/dev/null 2>&1
	fi
	# 开启IPV6防火墙端口
	local v6tables=$(which ip6tables);
	local MATCH6=$(ip6tables -t filter -S INPUT | grep "onehub_rule")
	if [ -z "${MATCH6}" ] && [ -n "${v6tables}" ]; then
		ip6tables -I INPUT -p tcp --dport ${onehub_port} -j ACCEPT -m comment --comment "onehub_rule" >/dev/null 2>&1
	fi
}

close_port() {
	local IPTS=$(iptables -t filter -S | grep -w "onehub_rule" | sed 's/-A/iptables -t filter -D/g')
	if [ -n "${IPTS}" ]; then
		echo_date "🧱关闭本插件在防火墙上打开的所有端口!"
		iptables -t filter -S | grep -w "onehub_rule" | sed 's/-A/iptables -t filter -D/g' >/tmp/onehub_clean.sh
		chmod +x /tmp/onehub_clean.sh
		sh /tmp/onehub_clean.sh >/dev/null 2>&1
		rm /tmp/onehub_clean.sh
	fi
	local v6tables=$(which ip6tables);
	local IPTS6=$(ip6tables -t filter -S | grep -w "onehub_rule" | sed 's/-A/ip6tables -t filter -D/g')
	if [ -n "${IPTS6}" ] && [ -n "${v6tables}" ]; then
		ip6tables -t filter -S | grep -w "onehub_rule" | sed 's/-A/ip6tables -t filter -D/g' >/tmp/onehub_clean.sh
		chmod +x /tmp/onehub_clean.sh
		sh /tmp/onehub_clean.sh >/dev/null 2>&1
		rm /tmp/onehub_clean.sh
	fi
}


check_status() {
	local ONEHUB_PID=$(pidof onehub)
	if [ "${onehub_enable}" == "1" ]; then
		if [ -n "${ONEHUB_PID}" ]; then
			if [ "${onehub_watchdog}" == "1" ]; then
				local onehub_time=$(perpls | grep onehub | grep -Eo "uptime.+-s\ " | awk -F" |:|/" '{print $3}')
				if [ -n "${onehub_time}" ]; then
					http_response "OneHub 进程运行正常！（PID：${ONEHUB_PID} , 守护运行时间：${onehub_time}）"
				else
					http_response "OneHub 进程运行正常！（PID：${ONEHUB_PID}）"
				fi
			else
				http_response "OneHub 进程运行正常！（PID：${ONEHUB_PID}）"
			fi
		else
			http_response "OneHub 进程未运行！"
		fi
	else
		http_response "OneHub 插件未启用"
	fi
}

case $1 in
	start)
		if [ "${onehub_enable}" == "1" ]; then
			sleep 20 #延迟启动等待虚拟内存挂载
			true >${LOG_FILE}
			start | tee -a ${LOG_FILE}
			echo XU6J03M16 >>${LOG_FILE}
			logger "[软件中心-开机自启]: OneHub 自启动成功！"
		else
			logger "[软件中心-开机自启]: OneHub 未开启，不自动启动！"
		fi
	;;
	boot_up)
		if [ "${onehub_enable}" == "1" ]; then
			true >${LOG_FILE}
			start | tee -a ${LOG_FILE}
			echo XU6J03M16 >>${LOG_FILE}
		fi
	;;
	start_nat)
		if [ "${onehub_enable}" == "1" ]; then
			if [ "${onehub_open_port}" == "1" ]; then
				logger "[软件中心-NAT重启]: 打开 OneHub 防火墙端口！"
				sleep 10
				close_port
				sleep 2
				open_port
			else
				logger "[软件中心-NAT重启]: OneHub 未开启公网访问，不打开湍口！"
			fi
		fi
	;;
	backup)
		start_backup
	;;
	stop)
		stop_plugin
	;;
	esac

	case $2 in
	web_submit)
		set_lock
		true >${LOG_FILE}
		http_response "$1"
		# 调试
		# echo_date "$BASH $ARGS" | tee -a ${LOG_FILE}
		# echo_date onehub_enable=${onehub_enable} | tee -a ${LOG_FILE}
		if [ "${onehub_enable}" == "1" ]; then
			echo_date "▶️开启 OneHub ！" | tee -a ${LOG_FILE}
			start | tee -a ${LOG_FILE}
		elif [ "${onehub_enable}" == "2" ]; then
			echo_date "🔁重启 OneHub ！" | tee -a ${LOG_FILE}
			dbus set onehub_enable=1
			start | tee -a ${LOG_FILE}
		elif [ "${onehub_enable}" == "3" ]; then
			dbus set onehub_enable=1
			random_password | tee -a ${LOG_FILE}
		else
			echo_date "ℹ️停止 OneHub ！" | tee -a ${LOG_FILE}
			stop_plugin | tee -a ${LOG_FILE}
		fi
		echo XU6J03M16 | tee -a ${LOG_FILE}
		unset_lock
	;;
	status)
		check_status
	;;
	esac
