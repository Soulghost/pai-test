destPath="/Applications/.mnnenv/pyenv"

# 同时内置python3.7.7和python2.7.18两套环境
# 3.7用于正常代码执行，2.7用于编译py文件给端侧调试用
urlPath_3="http://mnnworkstation.oss-cn-hangzhou.aliyuncs.com/Versions-e1f72307eb545542a7da614c3e51889e.zip"
urlMd5_3="e1f72307eb545542a7da614c3e51889e"
fileName_3="Versions-e1f72307eb545542a7da614c3e51889e.zip"

# state 状态码
WB_PY_RESOURCE_DOWNLOAD=1
WB_PY_INSTALL_CHECK=2
WB_PY_INSTALL_DOWNLOAD=3
WB_PY_INSTALL_UNZIP=4
WB_PY_INSTALL_COPY=5
WB_PY_INSTALL_CREATE_VENV=6
WB_PY_INSTALL_REQUIREMENTS=7
WB_PY_INSTALL_INNER_REQUIREMENTS=8
WB_PY_INSTALL_LCOAL_WHL=9
WB_PY_INSTALL_FINISHED=10

# code 错误码
RET_SUCCESS=0
# zip包下载失败
PY_INSTALL_DOWNLOAD_FAIL=1301
# zip包文件md5 check失败
PY_INSTALL_MD5_CHECK_FAIL=1302
# 解压失败
PY_INSTALL_UNZIP_FAIL=1303
# 文件copy到指定路径失败
PY_INSTALL_COPY_FAIL=1304
# 虚拟环境创建失败
PY_INSTALL_VENV_CREATE_FAIL=1305
# 虚拟环境激活失败
PY_INSTALL_VENV_ACTIVATE_FAIL=1306
# 依赖包安装失败
PY_INSTALL_REQUIREMENTS_INSTALL_FAIL=1307
# 本地whl包安装失败
PY_INSTALL_WHL_INSTALL_FAIL=1308
# 安装异常
PY_INSTALL_EXCEPTION=1309
# 安装内部依赖requirements失败
PY_INSTALL_INNER_REQUIREMENTS_ERROR=1311


code=$RET_SUCCESS
msg=""
state=$WB_PY_INSTALL_CHECK

reportMsg(){
    percent=`echo "scale = 2; $state / $WB_PY_INSTALL_FINISHED * 100" | bc`
    echo "[MNNWB]{\"code\":$code,\"state\":$state,\"totalPercent\":$percent,\"msg\":\"$msg\"}[/MNNWB]"
    # 防止进程退出过快，导致日志未及时被监听解析
    sleep 0.01s
}

reportMsg

# check dir
stepPath="$destPath/$fileName_3.step"
if [ ! -f "$stepPath" ]; then
    rm -rf $destPath/Versions/3.7
else
    # 校验是否完成
    step=`cat $stepPath`
    if [ $step != $WB_PY_INSTALL_FINISHED ] && [ $step != $WB_PY_INSTALL_CREATE_VENV ]; then
        # 没有安装成功
        rm -rf $destPath/Versions/3.7
    fi
fi

if [ ! -d "$destPath" ]; then
    mkdir -p $destPath
fi

if [ ! -d "$destPath/Versions" ]; then
    rm -rf $destPath
fi

downloadAndUnzip() {
    rm -rf $destPath/Versions/3.7
    mkdir -p $destPath/Versions/3.7
    # download
    curl $urlPath_3 -o $destPath/$fileName_3
    if [ $? -ne 0 ]; then
        echo "download $urlPath_3 fail"
        code=$PY_INSTALL_DOWNLOAD_FAIL
        msg="download $urlPath_2 fail"
        state=$WB_PY_INSTALL_DOWNLOAD
        reportMsg
        exit 1
    else
        echo "download $urlPath_3 success"
    fi

    # 下载成功
    code=$RET_SUCCESS
    msg="download $urlPath_2 success"
    state=$WB_PY_INSTALL_DOWNLOAD
    reportMsg

    # checkmd5
    md5Result=`md5sum $destPath/$fileName_3 | awk '{print $1}'`
    if [ $md5Result != $urlMd5_3 ]; then
        echo "$urlPath_3 md5 is not $urlMd5_3"
        exit 1
    else
        echo "file md5 check success"
    fi

    # unzip
    mkdir -p $destPath/tmp
    unzip -q -o $destPath/$fileName_3 -d $destPath/tmp
    if [ $? -ne 0 ]; then
        echo "unzip fail"
        rm -rf $destPath/$fileName_3
        rm -rf $destPath/tmp

        code=$PY_INSTALL_UNZIP_FAIL
        msg="unzip fail"
        state=$WB_PY_INSTALL_DOWNLOAD
        reportMsg
        exit 1
    fi
    
    echo "unzip success"

    # 解压成功
    code=$RET_SUCCESS
    msg="unzip success"
    state=$WB_PY_INSTALL_UNZIP
    reportMsg

    cp -r $destPath/tmp/Versions/3.7 $destPath/Versions
    if [ $? -ne 0 ]; then
        echo "copy fail"
        rm -rf $destPath/tmp/

        code=$PY_INSTALL_COPY_FAIL
        msg="copy fail"
        state=$WB_PY_INSTALL_UNZIP
        reportMsg
        exit 1
    else
        echo "copy success"
        rm -rf $destPath/tmp/
    fi

    # copy成功
    code=$RET_SUCCESS
    msg="copy success"
    state=$WB_PY_INSTALL_COPY
    reportMsg
}

# check python3
if [ ! -f "$destPath/$fileName_3" ] || [ ! -f "$destPath/Versions/3.7/bin/python3.7" ]; then
    downloadAndUnzip
else
    # 进度条显示要求
    code=$RET_SUCCESS
    msg="skip download"
    state=$WB_PY_INSTALL_DOWNLOAD
    reportMsg

    msg="skip unzip"
    state=$WB_PY_INSTALL_UNZIP
    reportMsg

    msg="skip copy"
    state=$WB_PY_INSTALL_COPY
    reportMsg
fi

py="/Applications/.mnnenv/pyenv/Versions/3.7/bin/python3.7"

$py -m virtualenv "/Users/hcy/Library/Application Support/MNNWorkbenchData/model/FastClassifier/venv"

if [ $? -ne 0 ]; then
    echo "virtualenv create venv fail"
    code=$PY_INSTALL_VENV_CREATE_FAIL
    msg="virtualenv create venv fail"
    state=$WB_PY_INSTALL_CREATE_VENV
    reportMsg
    exit 2
else
    echo "virtualenv create venv success"
    code=$RET_SUCCESS
    msg="virtualenv create venv success"
    state=$WB_PY_INSTALL_CREATE_VENV
    reportMsg
fi

cd "/Users/hcy/Library/Application Support/MNNWorkbenchData/model/FastClassifier"

source "/Users/hcy/Library/Application Support/MNNWorkbenchData/model/FastClassifier/venv/bin/activate"

if [ $? -ne 0 ]; then
    echo "activate venv fail"
    code=$PY_INSTALL_VENV_ACTIVATE_FAIL
    msg="activate venv fail"
    state=$WB_PY_INSTALL_CREATE_VENV
    reportMsg
    exit 1
else
    echo "activate venv success"
    code=$RET_SUCCESS
    msg="activate venv success"
    state=$WB_PY_INSTALL_CREATE_VENV
    reportMsg
fi

echo $WB_PY_INSTALL_FINISHED > $stepPath

if [ -f "/Users/hcy/projects/MNNWorkStation/extensions/models/Image/Image Classifier/FastClassifier/requirements.txt" ]; then
    pip install -i https://mirrors.aliyun.com/pypi/simple/ -r "/Users/hcy/projects/MNNWorkStation/extensions/models/Image/Image Classifier/FastClassifier/requirements.txt" --cache-dir "/Users/hcy/Library/Application Support/MNNWorkbenchData/model/FastClassifier/../../Caches/"

    if [ $? -ne 0 ]; then
        echo "install requirements fail, from aliyun"

        pip install -r "/Users/hcy/projects/MNNWorkStation/extensions/models/Image/Image Classifier/FastClassifier/requirements.txt"  --cache-dir "/Users/hcy/Library/Application Support/MNNWorkbenchData/model/FastClassifier/../../Caches/"

        if [ $? -ne 0 ]; then
            echo "install requirements fail, from pypi"
            code=$PY_INSTALL_REQUIREMENTS_INSTALL_FAIL
            msg="install requirements fail, from pypi"
            state=$WB_PY_INSTALL_REQUIREMENTS
            reportMsg
            exit 1
        else
            echo "install requirements success, from pypi"
        fi
    else
        echo "install requirements success, from aliyun"
    fi
else
    echo "no requirements file found, will skip"
fi

if [ -f "/Users/hcy/projects/MNNWorkStation/extensions/models/Image/Image Classifier/FastClassifier/requirements_inner.txt" ]; then
    pip install -i https://pypi.antfin-inc.com/simple/ -r "/Users/hcy/projects/MNNWorkStation/extensions/models/Image/Image Classifier/FastClassifier/requirements_inner.txt" --timeout 2 --retries 2 --cache-dir "/Users/hcy/Library/Application Support/MNNWorkbenchData/model/FastClassifier/../../Caches/"

    if [ $? -ne 0 ]; then
        echo "install inner requirements fail, please check your network, and connect to alibaba intranet"
        code=$PY_INSTALL_INNER_REQUIREMENTS_ERROR
        msg="install inner requirements fail, please check your network, and connect to alibaba intranet"
        state=$WB_PY_INSTALL_REQUIREMENTS
        reportMsg
        exit 1
    else
        echo "install inner requirements success"
    fi
else
    echo "no inner requirements file found, will skip"
fi

code=$RET_SUCCESS
msg="install requirements success"
state=$WB_PY_INSTALL_REQUIREMENTS
reportMsg

if [ -d "/Users/hcy/projects/MNNWorkStation/extensions/models/Image/Image Classifier/FastClassifier" ]; then
    cd "/Users/hcy/projects/MNNWorkStation/extensions/models/Image/Image Classifier/FastClassifier"
    find ./ -name \*.whl | xargs pip install

    if [ $? -ne 0 ]; then
        echo "whl install fail"
        code=$PY_INSTALL_WHL_INSTALL_FAIL
        msg="whl install fail"
        state=$WB_PY_INSTALL_LCOAL_WHL
        reportMsg
        exit 1
    else
        echo "whl install success"
    fi
else
    echo "no whl found, will skip"
fi

code=$RET_SUCCESS
msg="install local whl success"
state=$WB_PY_INSTALL_LCOAL_WHL
reportMsg

echo $WB_PY_INSTALL_FINISHED > $stepPath

msg="install success"
state=$WB_PY_INSTALL_FINISHED
reportMsg