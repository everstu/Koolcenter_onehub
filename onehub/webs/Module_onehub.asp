<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="X-UA-Compatible" content="IE=Edge" />
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta http-equiv="Pragma" content="no-cache" />
<meta http-equiv="Expires" content="-1" />
<link rel="shortcut icon" href="/res/icon-onehub.png" />
<link rel="icon" href="/res/icon-onehub.png" />
<title>软件中心 - OneHub</title>
<link rel="stylesheet" type="text/css" href="index_style.css">
<link rel="stylesheet" type="text/css" href="form_style.css">
<link rel="stylesheet" type="text/css" href="usp_style.css">
<link rel="stylesheet" type="text/css" href="css/element.css">
<link rel="stylesheet" type="text/css" href="/device-map/device-map.css">
<link rel="stylesheet" type="text/css" href="/js/table/table.css">
<link rel="stylesheet" type="text/css" href="/res/layer/theme/default/layer.css">
<link rel="stylesheet" type="text/css" href="/res/softcenter.css">
<script type="text/javascript" src="/js/jquery.js"></script>
<script language="JavaScript" type="text/javascript" src="/res/layer/layer.js"></script>
<script type="text/javascript" src="/state.js"></script>
<script type="text/javascript" src="/popup.js"></script>
<script type="text/javascript" src="/help.js"></script>
<script type="text/javascript" src="/general.js"></script>
<script type="text/javascript" language="JavaScript" src="/js/table/table.js"></script>
<script type="text/javascript" src="/res/softcenter.js"></script>
<script type="text/javascript" src="/help.js"></script>
<script type="text/javascript" src="/switcherplugin/jquery.iphone-switch.js"></script>
<script type="text/javascript" src="/validator.js"></script>
<style>
a:focus {
	outline: none;
}
.SimpleNote {
	padding:5px 5px;
}
i {
    color: #FC0;
    font-style: normal;
}
.loadingBarBlock{
	width:740px;
}
.popup_bar_bg_ks{
	position:fixed;
	margin: auto;
	top: 0;
	left: 0;
	width:100%;
	height:100%;
	z-index:99;
	/*background-color: #444F53;*/
	filter:alpha(opacity=90);  /*IE5、IE5.5、IE6、IE7*/
	background-repeat: repeat;
	visibility:hidden;
	overflow:hidden;
	/*background: url(/images/New_ui/login_bg.png);*/
	background:rgba(68, 79, 83, 0.85) none repeat scroll 0 0 !important;
	background-position: 0 0;
	background-size: cover;
	opacity: .94;
}

.FormTitle em {
    color: #00ffe4;
    font-style: normal;
    /*font-weight:bold;*/
}
.FormTable th {
	width: 30%;
}
.formfonttitle {
	font-family: Roboto-Light, "Microsoft JhengHei";
	font-size: 18px;
	margin-left: 5px;
}
.FormTitle, .FormTable, .FormTable th, .FormTable td, .FormTable thead td, .FormTable_table, .FormTable_table th, .FormTable_table td, .FormTable_table thead td {
	font-size: 14px;
	font-family: Roboto-Light, "Microsoft JhengHei";
}
</style>
<script type="text/javascript">
var dbus = {};
var refresh_flag
var db_onehub = {}
var count_down;
var _responseLen;
var STATUS_FLAG;
var noChange = 0;
var params_check = ['onehub_watchdog', 'onehub_open_port'];
var params_input = ['onehub_port', 'onehub_user_token_secret', 'onehub_session_secret', 'onehub_sql_dsn', 'onehub_redis_dsn', 'onehub_global_api_rate_limit', 'onehub_global_web_rate_limit', 'onehub_channel_test_frequency'];

String.prototype.myReplace = function(f, e){
	var reg = new RegExp(f, "g");
	return this.replace(reg, e);
}

function init() {
	show_menu(menu_hook);
	set_skin();
	register_event();
	get_dbus_data();
	check_status();
}
function set_skin(){
	var SKN = '<% nvram_get("sc_skin"); %>';
	if(SKN){
		$("#app").attr("skin", '<% nvram_get("sc_skin"); %>');
	}
}

function get_dbus_data(){
	$.ajax({
		type: "GET",
		url: "/_api/onehub_",
		dataType: "json",
		async: false,
		success: function(data) {
			dbus = data.result[0];
			conf2obj();
			show_hide_element();
			pannel_access();
		}
	});
}

function pannel_access(){
    let protocol,hostname,webUiHref,port;
	if(dbus["onehub_enable"] == "1"){
		port = dbus["onehub_port"];
		protocol = window.location.protocol;
		hostname = document.domain;
		if (hostname.indexOf('.kooldns.cn') != -1 || hostname.indexOf('.ddnsto.com') != -1 || hostname.indexOf('.tocmcc.cn') != -1) {
			if(hostname.indexOf('.kooldns.cn') != -1){
				hostname = hostname.replace('.kooldns.cn','-onehub.kooldns.cn');
			}else if(hostname.indexOf('.ddnsto.com') != -1){
				hostname = hostname.replace('.ddnsto.com','-onehub.ddnsto.com');
			}else{
				hostname = hostname.replace('.tocmcc.cn','-onehub.tocmcc.cn');
			}

			webUiHref = window.location.protocol + "//" + hostname;
		}else{
			webUiHref = protocol + "//" + window.location.hostname;
            if(port){
                webUiHref += ":" + port;
            }
		}

		E("fileb").href = webUiHref;
		E("fileb").innerHTML = "访问 OneHub 面板";
	}
}

function conf2obj(){
	for (var i = 0; i < params_check.length; i++) {
		if(dbus[params_check[i]]){
			E(params_check[i]).checked = dbus[params_check[i]] != "0";
		}
	}
	for (var i = 0; i < params_input.length; i++) {
		if (dbus[params_input[i]]) {
			$("#" + params_input[i]).val(dbus[params_input[i]]);
		}
	}
	if (dbus["onehub_version"]){
		E("onehub_version").innerHTML = " - " + dbus["onehub_version"];
	}

	if (dbus["onehub_binver"]){
		E("onehub_binver").innerHTML = "程序版本：<em>" + dbus["onehub_binver"] + "</em>";
	}else{
		E("onehub_binver").innerHTML = "程序版本：<em>null</em>";
	}
}

function show_hide_element(){
	if(dbus["onehub_enable"] == "1"){
		E("onehub_status_tr").style.display = "";
		E("onehub_version_tr").style.display = "";
		E("onehub_info_tr").style.display = "";
		E("onehub_pannel_tr").style.display = "";
		E("onehub_apply_btn_1").style.display = "none";
		E("onehub_apply_btn_2").style.display = "";
		E("onehub_apply_btn_3").style.display = "";
	}else{
		E("onehub_status_tr").style.display = "";
		E("onehub_version_tr").style.display = "none";
		E("onehub_info_tr").style.display = "none";
		E("onehub_pannel_tr").style.display = "none";
		E("onehub_apply_btn_1").style.display = "";
		E("onehub_apply_btn_2").style.display = "none";
		E("onehub_apply_btn_3").style.display = "none";
	}
}

function menu_hook(title, tab) {
	tabtitle[tabtitle.length - 1] = new Array("", "OneHub");
	tablink[tablink.length - 1] = new Array("", "Module_onehub.asp");
}

function register_event(){
	$(".popup_bar_bg_ks").click(
		function() {
			count_down = -1;
		});
	$(window).resize(function(){
		var page_h = window.innerHeight || document.documentElement.clientHeight || document.body.clientHeight;
		var page_w = window.innerWidth || document.documentElement.clientWidth || document.body.clientWidth;
		if($('.popup_bar_bg_ks').css("visibility") == "visible"){
			document.scrollingElement.scrollTop = 0;
			var log_h = E("loadingBarBlock").clientHeight;
			var log_w = E("loadingBarBlock").clientWidth;
			var log_h_offset = (page_h - log_h) / 2;
			var log_w_offset = (page_w - log_w) / 2 + 90;
			$('#loadingBarBlock').offset({top: log_h_offset, left: log_w_offset});
		}
	});
}

function check_status(){
	var id = parseInt(Math.random() * 100000000);
	var postData = {"id": id, "method": "onehub_config.sh", "params":['status'], "fields": ""};
	$.ajax({
		type: "POST",
		url: "/_api/",
		async: true,
		data: JSON.stringify(postData),
		success: function (response) {
			E("onehub_run_status").innerHTML = response.result;
			setTimeout("check_status();", 10000);
		},
		error: function(){
			E("onehub_run_status").innerHTML = "获取运行状态失败";
			setTimeout("check_status();", 5000);
		}
	});
}

function save(flag){
	var db_onehub = {};
	if(flag){
		console.log(flag)
		db_onehub["onehub_enable"] = flag;
	}else{
		db_onehub["onehub_enable"] = "0";
	}
	for (var i = 0; i < params_check.length; i++) {
			db_onehub[params_check[i]] = E(params_check[i]).checked ? '1' : '0';
	}
	for (var i = 0; i < params_input.length; i++) {
		if (E(params_input[i])) {
			db_onehub[params_input[i]] = E(params_input[i]).value;
		}
	}
	var id = parseInt(Math.random() * 100000000);
	var postData = {"id": id, "method": "onehub_config.sh", "params": ["web_submit"], "fields": db_onehub};
	$.ajax({
		type: "POST",
		url: "/_api/",
		data: JSON.stringify(postData),
		dataType: "json",
		success: function(response) {
			if(response.result == id){
				get_log();
			}
		}
	});
}

function get_log(flag){
	E("ok_button").style.visibility = "hidden";
	showALLoadingBar();
	$.ajax({
		url: '/_temp/onehub_log.txt',
		type: 'GET',
		cache:false,
		dataType: 'text',
		success: function(response) {
			var retArea = E("log_content");
			if (response.search("XU6J03M16") != -1) {
				retArea.value = response.myReplace("XU6J03M16", " ");
				E("ok_button").style.visibility = "visible";
				retArea.scrollTop = retArea.scrollHeight;
				if(flag == 1){
					count_down = -1;
					refresh_flag = 0;
				}else{
					count_down = 6;
					refresh_flag = 1;
				}
				count_down_close();
				return false;
			}
			setTimeout("get_log(" + flag + ");", 500);
			retArea.value = response.myReplace("XU6J03M16", " ");
			retArea.scrollTop = retArea.scrollHeight;
		},
		error: function(xhr) {
			E("loading_block_title").innerHTML = "暂无日志信息 ...";
			E("log_content").value = "日志文件为空，请关闭本窗口！";
			E("ok_button").style.visibility = "visible";
			return false;
		}
	});
}

function showALLoadingBar(){
	document.scrollingElement.scrollTop = 0;
	E("loading_block_title").innerHTML = "&nbsp;&nbsp;OneHub日志信息";
	E("LoadingBar").style.visibility = "visible";
	var page_h = window.innerHeight || document.documentElement.clientHeight || document.body.clientHeight;
	var page_w = window.innerWidth || document.documentElement.clientWidth || document.body.clientWidth;
	var log_h = E("loadingBarBlock").clientHeight;
	var log_w = E("loadingBarBlock").clientWidth;
	var log_h_offset = (page_h - log_h) / 2;
	var log_w_offset = (page_w - log_w) / 2 + 90;
	$('#loadingBarBlock').offset({top: log_h_offset, left: log_w_offset});
}

function hideALLoadingBar(){
	E("LoadingBar").style.visibility = "hidden";
	E("ok_button").style.visibility = "hidden";
	if (refresh_flag == "1"){
		refreshpage();
	}
}
function count_down_close() {
	if (count_down == "0") {
		hideALLoadingBar();
	}
	if (count_down < 0) {
		E("ok_button1").value = "手动关闭"
		return false;
	}
	E("ok_button1").value = "自动关闭（" + count_down + "）"
		--count_down;
	setTimeout("count_down_close();", 1000);
}

function close() {
	if (confirm('确定马上关闭吗.?')) {
		showLoading(2);
		refreshpage(2);
		var id = parseInt(Math.random() * 100000000);
		var postData = { "id": id, "method": "onehub_config.sh", "params": ["stop"], "fields": "" };
		$.ajax({
			url: "/_api/",
			cache: false,
			type: "POST",
			dataType: "json",
			data: JSON.stringify(postData)
		});
	}
}

function get_run_log(){
	if(STATUS_FLAG == 0) return;
	$.ajax({
		url: '/_temp/onehub_run_log/one-hub.log',
		type: 'GET',
		dataType: 'html',
		async: true,
		cache: false,
		success: function(response) {
			var retArea = E("log_content_onehub");
			if (_responseLen == response.length) {
				noChange++;
			} else {
				noChange = 0;
			}
			if (noChange > 10) {
				return false;
			} else {
				setTimeout("get_run_log();", 1500);
			}
			retArea.value = response;

			if(E("onehub_stop_log").checked == false){
				retArea.scrollTop = retArea.scrollHeight;
			}
			_responseLen = response.length;
		},
		error: function(xhr) {
			E("log_pannel_title").innerHTML = "暂无日志信息 ...";
			E("log_content_onehub").value = "日志文件为空，请关闭本窗口！";
			setTimeout("get_run_log();", 5000);
		}
	});
}
function show_log_pannel(){
	document.scrollingElement.scrollTop = 0;
	E("log_pannel_div").style.visibility = "visible";
	var page_h = window.innerHeight || document.documentElement.clientHeight || document.body.clientHeight;
	var page_w = window.innerWidth || document.documentElement.clientWidth || document.body.clientWidth;
	var log_h = E("log_pannel_table").clientHeight;
	var log_w = E("log_pannel_table").clientWidth;
	var log_h_offset = (page_h - log_h) / 2;
	var log_w_offset = (page_w - log_w) / 2;
	$('#log_pannel_table').offset({top: log_h_offset, left: log_w_offset});
	STATUS_FLAG = 1;
	get_run_log();
}
function hide_log_pannel(){
	E("log_pannel_div").style.visibility = "hidden";
	STATUS_FLAG = 0;
}
function open_onehub_hint(itemNum) {
	statusmenu = "";
	width = "350px";
	switch (itemNum){
	    case 'run_status':
            statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;1. 此处显示onehub二进制程序在路由器后台的简要运行情况，详细运行日志可以点击<b>onehub运行日志</b>查看。<br/><br/>"
            statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;2. 当开启了实时进程守护后，可以看到onehub二进制运行时长，即守护运行时间。<br/><br/>"
            statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;3. 当出现<b>获取运行状态失败</b>时，可能是路由器后台登陆超时或者httpd进程崩溃导致，如果是后者，请等待路由器httpd进程恢复，或者自行使用ssh命令：server restart_httpd重启httpd。<br/><br/>"
            _caption = "运行状态";
            break;
	    case 'version':
            statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;1. 此处显示onehub二进制程序的版本号。<br/><br/>"
            statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;2. onehub二进制程序下载自onehub的github项目release页面的onehub-linux-arm64版本。<br/><br/>"
            statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;3.目前只支持hnd机型中的armv8机型，比如cpu型号为BCM4906、BCM4908、BCM4912等armv8机型。<br/><br/>"
            _caption = "运行状态";
            break;
	    case 'info':
            statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;点击【onehub运行日志】可以实时查看onehub程序的运行情况。<br/><br/>"
            statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;此日志是onehub二进制运行日志，可以查看启动二进制启动情况、二进制报错、API请求记录等日志。<br/><br/>"
            _caption = "信息获取";
            break;
	    case 'panel':
            statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;点击【访问 OneHub 面板】可以访问OneHub控制面板。<br/><br/>"
            statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;OneHub控制面板可以配置渠道、运营设置等。<br/><br/>"
            statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;用户管理、API令牌、渠道添加、请求日志都可以在此查看。<br/><br/>"
            _caption = "控制面板";
            break;
	    case 'watchdog':
            width = '550px';
            statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;采用perp对onehub进程进行实时进程守护，这比一些定时检查脚本更有效率，当然如果onehub程序在你的路由器上运行良好，完全可以不使用进程守护。<br/><br/>"
            statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;由于onehub对路由器资源占用较多，所以强烈建议为路由器配置1G及以上的虚拟内存，以保证onehub的稳定运行！<br/><br/>"
            _caption = "实时进程守护";
            break;
	    case 'open_port':
            statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;开启公网访问后，onehub将打开防火墙端口，这样就能从WAN外部访问路由器内的onehub面板及服务。<br/><br/>"
            statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;关闭公网访问后，onehub将关闭防火墙端口，这样onehub面板及服务仅能从局域网内部访问。<br/><br/>"
            _caption = "开启公网访问";
            break;
	    case 'port':
            width = '500px';
            statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;onehub服务默认端口为3000，你可以自行更改为其它端口。<br/><br/>"
            statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;onehub默认提供HTTP服务，如需HTTPS服务请使用Lucky插件或Nginx服务反向代理。<br/><br/>"
            _caption = "服务监听端口";
            break;
	    case 'user_token_secret':
            statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;<b>请求确定你了解此项设置，并认真阅读文档后设置!</b><br/><br/>"
            statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;设置用户令牌签名密钥，必填，大于 32 位以上。<br/><br/>"
            statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;设置后请勿修改，否则会导致用户令牌失效。<br/><br/>"
            _caption = "用户令牌签名密钥";
            break;
	    case 'session_secret':
            statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;<b>请求确定你了解此项设置，并认真阅读文档后设置!</b><br/><br/>"
            statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;设置之后将使用固定的会话密钥，这样系统重新启动后已登录用户的 cookie 将依旧有效。<br/><br/>"
            _caption = "用户会话密钥";
            break;
	    case 'sql_dsn':
            width = '600px';
            statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;<b>请求确定你了解此项设置，并认真阅读文档后设置!</b><br/><br/>"
            statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;<b>默认使用SQLite，存储位置：/koolshare/configs/onehub/</b><br/><br/>"
            statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;设置之后将使用指定数据库而非 SQLite，请使用 MySQL 或 PostgreSQL。<br/><br/>"
            statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;例子：<br/>"
            statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;MySQL：SQL_DSN=root:123456@tcp(localhost:3306)/oneapi<br/>"
            statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;PostgreSQL：SQL_DSN=postgres://postgres:123456@localhost:5432/oneapi<br/><br/>"
            statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;注意需要提前建立数据库 oneapi，无需手动建表，程序将自动建表。<br/><br/>"
            statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;如果使用云数据库：如果云服务器需要验证身份，需要在连接参数中添加 ?tls=skip-verify。<br/><br/>"
            _caption = "数据库DSN";
            break;
	    case 'redis_dsn':
            statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;<b>请求确定你了解此项设置，并认真阅读文档后设置!</b><br/><br/>"
            statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;设置之后将使用 Redis 作为缓存使用。<br/><br/>"
            statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;例子：<br/>"
            statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;REDIS_CONN_STRING=redis://default:redispw@localhost:49153<br/>"
            statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;如果数据库访问延迟很低，没有必要启用 Redis，启用后反而会出现数据滞后的问题。<br/><br/>"
            _caption = "Redis缓存DSN";
            break;
	    case 'global_api_rate_limit':
            statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;<b>请求确定你了解此项设置，并认真阅读文档后设置!</b><br/><br/>"
            statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;全局 API 速率限制（除中继请求外），单 ip 三分钟内的最大请求数，默认为 180。<br/><br/>"
            _caption = "全局API速率限制";
            break;
	    case 'global_web_rate_limit':
            statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;<b>请求确定你了解此项设置，并认真阅读文档后设置!</b><br/><br/>"
            statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;全局 Web 速率限制，单 ip 三分钟内的最大请求数，默认为 60。<br/><br/>"
            _caption = "全局WEB速率限制";
            break;
	    case 'channel_test_frequency':
            statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;设置之后将定期检查渠道，单位为分钟，未设置则不进行检查。<br/><br/>"
            _caption = "渠道定时检查";
            break;
        default:
            statusmenu += "<b>帮助待更新，请等待作者后续更新。</b>"
            _caption = "待更新帮助";

	}

	return overlib(statusmenu, OFFSETX, 10, OFFSETY, 10, RIGHT, STICKY, WIDTH, 'width', CAPTION, _caption, CLOSETITLE, '');
}

function mOver(obj, hint){
	$(obj).css({
		"color": "#00ffe4",
		"text-decoration": "underline"
	});
	open_onehub_hint(hint);
}
function mOut(obj){
	$(obj).css({
		"color": "#fff",
		"text-decoration": ""
	});
	E("overDiv").style.visibility = "hidden";
}
function popAd(){
    const adHtml = `
    <ul style="
        font-family: 'Microsoft Yahei', sans-serif;
        color: yellow;
        font-size: 16px;
        line-height: 1.6;
        background:black;
      ">
        <br><br>
        <li>
            <a href="https://ppinfra.com/user/register?invited_by=7IIT1H" target="_blank" rel="noopener noreferrer">
                <em>
                    <u>
                        派欧云 - 点击接受邀请注册送￥55
                    </u>
                </em>
            </a>&nbsp;&nbsp;邀请码&nbsp;7IIT1H&nbsp;
        </li>
        <br>
        <li>
            <a href="https://cloud.siliconflow.cn/i/jOOhe7rC" target="_blank" rel="noopener noreferrer">
                <em>
                    <u>
                        硅基流动 - 点击接受邀请注册送￥14
                    </u>
                </em>
            </a>&nbsp;&nbsp;邀请码&nbsp;jOOhe7rC&nbsp;
        </li>
        <br><br>
    </ul>
    `;
    layer.open({
        type: 1,
        title: false,
        closeBtn: 1,
        area: ['500px'],
        shadeClose: true,
        content: adHtml
    });
    return false;
}
</script>
</head>
<body id="app" skin="ASUSWRT" onload="init();">
	<div id="TopBanner"></div>
	<div id="Loading" class="popup_bg"></div>
	<div id="LoadingBar" class="popup_bar_bg_ks" style="z-index: 200;" >
		<table cellpadding="5" cellspacing="0" id="loadingBarBlock" class="loadingBarBlock" align="center">
			<tr>
				<td height="100">
					<div id="loading_block_title" style="margin:10px auto;margin-left:10px;width:85%; font-size:12pt;"></div>
					<div id="loading_block_spilt" style="margin:10px 0 10px 5px;" class="loading_block_spilt">
						<li><font color="#ffcc00">请等待日志显示完毕，并出现自动关闭按钮！</font></li>
						<li><font color="#ffcc00">在此期间请不要刷新本页面，不然可能导致问题！</font></li>
					</div>
					<div style="margin-left:15px;margin-right:15px;margin-top:10px;outline: 1px solid #3c3c3c;overflow:hidden">
						<textarea cols="50" rows="25" wrap="off" readonly="readonly" id="log_content" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false" style="border:1px solid #000;width:99%; font-family:'Lucida Console'; font-size:11px;background:transparent;color:#FFFFFF;outline: none;padding-left:5px;padding-right:22px;overflow-x:hidden;white-space:break-spaces;"></textarea>
					</div>
					<div id="ok_button" class="apply_gen" style="background:#000;visibility:hidden;">
						<input id="ok_button1" class="button_gen" type="button" onclick="hideALLoadingBar()" value="确定">
					</div>
				</td>
			</tr>
		</table>
	</div>
	<div id="log_pannel_div" class="popup_bar_bg_ks" style="z-index: 200;" >
		<table cellpadding="5" cellspacing="0" id="log_pannel_table" class="loadingBarBlock" style="width:960px" align="center">
			<tr>
				<td height="100">
					<div style="text-align: center;font-size: 18px;color: #99FF00;padding: 10px;font-weight: bold;">onehub日志信息</div>
					<div style="margin-left:15px"><i>🗒️此处展示onehub程序的运行日志...</i></div>
					<div style="margin-left:15px;margin-right:15px;margin-top:10px;outline: 1px solid #3c3c3c;overflow:hidden">
						<textarea cols="50" rows="32" wrap="off" readonly="readonly" id="log_content_onehub" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false" style="border:1px solid #000;width:99%; font-family:'Lucida Console'; font-size:11px;background:transparent;color:#FFFFFF;outline: none;padding-left:5px;padding-right:22px;line-height:1.3;overflow-x:hidden;white-space:break-spaces;"></textarea>
					</div>
					<div id="ok_button_onehub" class="apply_gen" style="background:#000;">
						<input class="button_gen" type="button" onclick="hide_log_pannel()" value="返回主界面">
						<input style="margin-left:10px" type="checkbox" id="onehub_stop_log">
						<lable>&nbsp;暂停日志刷新</lable>
					</div>
				</td>
			</tr>
		</table>
	</div>
	<iframe name="hidden_frame" id="hidden_frame" width="0" height="0" frameborder="0"></iframe>
	<!--=============================================================================================================-->
	<table class="content" align="center" cellpadding="0" cellspacing="0">
		<tr>
			<td width="17">&nbsp;</td>
			<td valign="top" width="202">
				<div id="mainMenu"></div>
				<div id="subMenu"></div>
			</td>
			<td valign="top">
				<div id="tabMenu" class="submenuBlock"></div>
				<table width="98%" border="0" align="left" cellpadding="0" cellspacing="0">
					<tr>
						<td align="left" valign="top">
							<table width="760px" border="0" cellpadding="5" cellspacing="0" bordercolor="#6b8fa3" class="FormTitle" id="FormTitle">
								<tr>
									<td bgcolor="#4D595D" colspan="3" valign="top">
										<div>&nbsp;</div>
										<div class="formfonttitle">OneHub <lable id="onehub_version"></lable></div>
										<div style="float: right; width: 15px; height: 25px; margin-top: -20px">
											<img id="return_btn" alt="" onclick="reload_Soft_Center();" align="right" style="cursor: pointer; position: absolute; margin-left: -30px; margin-top: -25px;" title="返回软件中心" src="/images/backprev.png" onmouseover="this.src='/images/backprevclick.png'" onmouseout="this.src='/images/backprev.png'" />
										</div>
										<div style="margin: 10px 0 10px 5px;" class="splitLine"></div>
										<div class="SimpleNote">
											<a href="https://github.com/MartialBE/one-hub" target="_blank"><em><u>OneHub</u></em></a>&nbsp;是基于one-api二次开发而来的LLM API 管理 & 分发系统，支持 OpenAI、Azure、Anthropic Claude、Google Gemini、DeepSeek。
											<span><a type="button" href="https://github.com/everstu/Koolcenter_onehub/blob/master/Changelog.txt" target="_blank" class="ks_btn" style="margin-left:5px;" >更新日志</a></span>
											<span><a type="button" class="ks_btn" href="javascript:void(0);" onclick="get_log(1)" style="margin-left:5px;">插件日志</a></span><br>
										</div>
										<div id="onehub_status_pannel">
											<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
												<thead>
													<tr>
														<td colspan="2">OneHub - 状态</td>
													</tr>
												</thead>
												<tr id="onehub_status_tr" style="display: none;">
													<th><a onmouseover="mOver(this, 'run_status')" onmouseout="mOut(this)" class="hintstyle" href="javascript:void(0);">运行状态</a></th>
													<td>
														<span style="margin-left:4px" id="onehub_run_status"></span>
													</td>
												</tr>
												<tr id="onehub_version_tr" style="display: none;">
													<th><a onmouseover="mOver(this, 'version')" onmouseout="mOut(this)" class="hintstyle" href="javascript:void(0);">版本信息</a></th>
													<td>
														<span style="margin-left:4px" id="onehub_binver"></span>
													</td>
												</tr>
												<tr id="onehub_info_tr" style="display: none;">
													<th><a onmouseover="mOver(this, 'info')" onmouseout="mOut(this)" class="hintstyle" href="javascript:void(0);">信息获取</a></th>
													<td>
														<a type="button" class="ks_btn" href="javascript:void(0);" onclick="show_log_pannel()" style="margin-left:5px;">OneHub运行日志</a>
													</td>
												</tr>
												<tr id="onehub_pannel_tr" style="display: none;">
													<th><a onmouseover="mOver(this, 'panel')" onmouseout="mOut(this)" class="hintstyle" href="javascript:void(0);">控制面板</a></th>
													<td>
														<a type="button" style="vertical-align:middle;cursor:pointer;margin-left:5px;" id="fileb" class="ks_btn" href="" target="_blank">访问 OneHub 面板</a>
													</td>
												</tr>
											</table>
										</div>
										<div id="onehub_setting_pannel" style="margin-top:10px">
											<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
												<thead>
													<tr>
														<td colspan="2">OneHub - 基础设置</td>
													</tr>
												</thead>
												<!--<tr><th colspan="2"><em>基础设置</em></th></tr>-->
												<tr id="oh_watchdog">
													<th><a onmouseover="mOver(this, 'watchdog')" onmouseout="mOut(this)" class="hintstyle" href="javascript:void(0);">实时进程守护</a></th>
													<td>
														<input type="checkbox" id="onehub_watchdog" style="vertical-align:middle;">
													</td>
												</tr>
												<tr id="oh_open_port">
													<th><a onmouseover="mOver(this, 'open_port')" onmouseout="mOut(this)" class="hintstyle" href="javascript:void(0);">开启公网访问</a></th>
													<td>
														<input type="checkbox" id="onehub_open_port" onchange="show_hide_element();" style="vertical-align:middle;">
													</td>
												</tr>
												<tr id="oh_port">
													<th><a onmouseover="mOver(this, 'port')" onmouseout="mOut(this)" class="hintstyle" href="javascript:void(0);">服务监听端口</a></th>
													<td>
													<input type="text" id="onehub_port" style="width: 15%;" class="input_3_table" autocorrect="off" autocapitalize="off" style="background-color: rgb(89, 110, 116);" value="3000" placeholder="3000">
													</td>
												</tr>
												<tr id="oh_user_token_secret">
													<th><a onmouseover="mOver(this, 'user_token_secret')" onmouseout="mOut(this)" class="hintstyle" href="javascript:void(0);">API令牌密钥</a></th>
													<td>
													<input type="text" id="onehub_user_token_secret" style="width: 95%;" class="input_3_table" autocorrect="off" autocapitalize="off" style="background-color: rgb(89, 110, 116);" value="" placeholder="e10adc3949ba59abbe56e057f20f883e">
													</td>
												</tr>
												<tr id="oh_session_secret">
													<th><a onmouseover="mOver(this, 'session_secret')" onmouseout="mOut(this)" class="hintstyle" href="javascript:void(0);">用户会话密钥</a></th>
													<td>
													<input type="text" id="onehub_session_secret" style="width: 95%;" class="input_3_table" autocorrect="off" autocapitalize="off" style="background-color: rgb(89, 110, 116);" value="" placeholder="e10adc3949ba59abbe56e057f20f883e">
													</td>
												</tr>
												<tr id="oh_sql_dsn">
													<th><a onmouseover="mOver(this, 'sql_dsn')" onmouseout="mOut(this)" class="hintstyle" href="javascript:void(0);">配置数据库服务</a></th>
													<td>
													<input type="text" id="onehub_sql_dsn" style="width: 95%;" class="input_3_table" autocorrect="off" autocapitalize="off" style="background-color: rgb(89, 110, 116);" value="" placeholder="SQL_DSN=root:123456@tcp(localhost:3306)/oneapi">
													</td>
												</tr>
												<tr id="oh_redis_dsn">
													<th><a onmouseover="mOver(this, 'redis_dsn')" onmouseout="mOut(this)" class="hintstyle" href="javascript:void(0);">配置缓存服务</a></th>
													<td>
													<input type="text" id="onehub_redis_dsn" style="width: 95%;" class="input_3_table" autocorrect="off" autocapitalize="off" style="background-color: rgb(89, 110, 116);" value="" placeholder="redis://default:redispw@localhost:49153">
													</td>
												</tr>
												<tr id="oh_global_api_rate_limit">
													<th><a onmouseover="mOver(this, 'global_api_rate_limit')" onmouseout="mOut(this)" class="hintstyle" href="javascript:void(0);">配置全局API速率限制</a></th>
													<td>
													<input type="text" id="onehub_global_api_rate_limit" style="width: 95%;" class="input_3_table" autocorrect="off" autocapitalize="off" style="background-color: rgb(89, 110, 116);" value="" placeholder="180">
													</td>
												</tr>
												<tr id="oh_global_web_rate_limit">
													<th><a onmouseover="mOver(this, 'global_web_rate_limit')" onmouseout="mOut(this)" class="hintstyle" href="javascript:void(0);">配置全局WEB速率限制</a></th>
													<td>
													<input type="text" id="onehub_global_web_rate_limit" style="width: 95%;" class="input_3_table" autocorrect="off" autocapitalize="off" style="background-color: rgb(89, 110, 116);" value="" placeholder="60">
													</td>
												</tr>
												<tr id="oh_channel_test_frequency">
													<th><a onmouseover="mOver(this, 'channel_test_frequency')" onmouseout="mOut(this)" class="hintstyle" href="javascript:void(0);">配置渠道自动测试时间</a></th>
													<td>
													<input type="text" id="onehub_channel_test_frequency" style="width: 95%;" class="input_3_table" autocorrect="off" autocapitalize="off" style="background-color: rgb(89, 110, 116);" value="" placeholder="0">
													</td>
												</tr>
											</table>
										</div>
										<div id="onehub_apply" class="apply_gen">
											<input class="button_gen" style="display: none;" id="onehub_apply_btn_1" onClick="save(1)" type="button" value="开启" />
											<input class="button_gen" style="display: none;" id="onehub_apply_btn_2" onClick="save(2)" type="button" value="重启" />
											<input class="button_gen" style="display: none;" id="onehub_apply_btn_3" onClick="save(0)" type="button" value="关闭" />
										</div>
										<div style="margin: 10px 0 10px 5px;" class="splitLine"></div>
										<div style="margin:10px 0 0 5px">
                                            <li><a href="#" onclick="popAd();return false;">点击查看提供<em>免费大模型API服务</em>的云厂商</a></li>
											<li>由于OneHub需要路由器较好性能，本插件仅支持hnd平台！</li>
											<li>OneHub初始超级管理员账号：root 密码：123456，请尽快修改账号密码！丢失无法找回，请牢记修改后的密码！</li>
											<li>因未提供https服务，如需https服务请搭配lucky或nginx等服务使用！</li>
											<li>建议挂载U盘并配合usb2jffs和虚拟内存插件一起食用，口感更佳，否则可能会出现莫名的问题。</li>
											<li>如有不懂，特别是OneHub配置文件的填写，请查看OneHub官方文档<a href="https://github.com/MartialBE/one-hub/wiki" target="_blank"><em>点这里看文档</em></a></li>
											<li>插件使用有任何问题请加入<a href="https://t.me/xbchat" target="_blank"><em><u>koolcenter TG群</u></em></a>或<a href="https://t.me/meilinchajian" target="_blank"><em><u>Mc Chat TG群</u></em></a>联系 @fiswonder<br></li>
										</div>
									</td>
								</tr>
							</table>
						</td>
					</tr>
				</table>
			</td>
			<td width="10" align="center" valign="top"></td>
		</tr>
	</table>
	<div id="footer"></div>
</body>
</html>