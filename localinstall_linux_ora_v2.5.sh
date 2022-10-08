#!/bin/bash
# 2019-05-15 version 1 
# 2019-05-20 version 1.2 
#       add: db basic optimize function
# 2019-06-05 version 1.3 
#       add: yum clean all 
#            /etc/yum.repo.d/bak command change
#            input val of INSTALL_DIR change
#            change memlock to totalmem's 50%
#2019-06-10 version 1.4
#            change suit for rhel6
#2019-08-30 version 1.5
#            add netca function 
#2019-10-18 version 1.6
#            add hostname check & modify
#2020-02-23 version 2.0
#             suit for multi-version OS&DB by zhh
#2020-03-03 version 2.1
#             change parameters settting methods
#2020-03-03 version 2.2
#             add some parameters and sqlnet.ora opti
#2020-03-10 version 2.3
#             opti db-deinstall and fix some bug
#2020-03-11 version 2.4
#             delete some i686 rpm in needed list and change memerytarget from 60% to 50%
#2020-03-12 version 2.5
#             consummate deinstall_db_soft function 
#             fixed some bugs : gid change from 1000 to 1100
#2020-03-13 version 2.6
#             flag parameter add judgment conditions
#2020-04-27 version 2.7
#             add function create_user of osmproxy 
#2020-07-19 version 2.8
#             add suit for huge memory
#2020-07-23 version 2.9
#             fix ora_18c dbca rsp 
#             add suit for  cdb or no-cdb
#2020-07-23 version 2.10
#             add gather_hugepages_set_script function 
#2020-08-12 version 2.10.1 
#             fix  19c dbca  automaticMemoryManagement bug
#2020-09-01 version 2.11.1
#             add suit for ftp yum repo
#             add 19c db-parameter-opti
#             fix use sqlplus -v get ORA_SOFT_RELEASE of 19c
#2020-09-11 version 2.11.2
#             add step log infos by gaoxiaodong 
#2020-09-14 version 2.12
#             add db archvie setting 
#2020-12-07 add MC_INSTALL_TAG marked 

# --------------------STEP00_01~N1~[clear_server_env][clear_install_log]--------------------
# --------------------STEP00_02~N1~[clear_server_env][clear_oracle_config]--------------------
# --------------------STEP00_03~N1~[clear_server_env][clear_mediums_download_logs]--------------------
# --------------------STEP01_01~N1~[check_server_env][check_ssh_connect]--------------------
# --------------------STEP01_02~N1~[check_server_env][check_dir_empty]--------------------
# --------------------STEP01_03~N1~[check_server_env][check_mem]--------------------
# --------------------STEP01_04~N1~[check_server_env][check_tools]--------------------
# --------------------STEP01_05~N1~[check_server_env][related_dirs_ok]--------------------
# --------------------STEP01_06~N1~[check_server_env][data_sid_dir_ok]--------------------
# --------------------STEP02_01~N1~[prepare_medium_script][prepare_medium_script_ok]--------------------
# --------------------STEP09_01~N1~[osmproxy_user][create_osmproxy_user]--------------------

export LANG=en_US.UTF-8
unset MAILCHECK


while getopts "a:c:C:d:f:G:h:H:i:I:n:o:O:p:P:s:S:D:r:" option;
do
    case "$option" in
        a)
            ARCHIVE_DIR=$OPTARG
            echo "option:a, value $OPTARG"
            echo "ARCHIVE_DIR IS: $ARCHIVE_DIR"
            ;; 
        c)
            CHARACTER=$OPTARG
            echo "option:c, value $OPTARG"
            echo "CHARACTER IS: $CHARACTER"
            ;;
        C)
            DBCA_ONLY=$OPTARG
            echo "option:C, value $OPTARG"
            echo "DBCA_ONLY IS: $DBCA_ONLY" 
            ;;
        d)
            INSTALL_DIR=${OPTARG%*/}
            echo "option:d, value $OPTARG"
            echo "INSTALL_DIR IS: $INSTALL_DIR"
            ;;
        D)  
            DEINSTALL_FLAG=$OPTARG
            echo "option:D,value $OPTARG"
            echo "DEINSTALL_FLAG IS: $DEINSTALL_FLAG"
            echo "Default install is not use the option!!!!Just for Deinstall db&service&soft!!!!"
            ;;

        G)
            my_debug_flg=$OPTARG
            echo "option:G, value $OPTARG"
            echo "my_debug_flg IS: $my_debug_flg"
            ;;  
        h)
            #echo "option:h, value $OPTARG"            
            echo "Usage: args [-a] [-c] [-C] [-d] [-D] [-G] [-help] [-H] [-i] [-n] [-o] [-p] [-s] [-S] [-r]"
            echo "Use root to run the script."
            echo "-a means: archvie dir set, must be configured for set db in archvie mode."
            echo "-c means: character set, must be configured for dbca"
            echo "-C means: soft already installed,Just create a db and optimization,Need set -C and -s together"
            echo "-d means: db soft installed directory , must be configured for install"
            echo "-D means: delete db and deinstall db softs,default values [N]"
            echo "-G means: debug flag, Using keyword [McDeBuG] for Oracle install or deinstall Debug"
            echo "-help means: to get helpinfo"
            echo "-H means: set hostname ,default value is the host original Value.  localhost.localdomain/localhost/'-' is Illegal value"
            echo "-i means: ip address, must be configured for soft_install/netca/dbca"
            echo "-n means: create listener with install soft,default value [N]"
            echo "-o means: os iso upload dir, or use cdrom default value [/dev/cdrom],if already set the ftp yum repo to use,set to [F] or [f]"
            echo "-O means: database archive dir,if need set db archive mode ,use the parameter,like -O /ora/archive "
            echo "-p means: listener port, default value [1521]" 
            echo "-P means: ContainerDatabase set Y or N,default value [N],the parameter is  valid db verion above 11g."
            echo "-s means: sid ,must be configured for dbca;if sid not set, the db will not create "
            echo "-r means: ORA_SOFT_RELEASE ,must be configured for rdbms ;if ORA_SOFT_RELEASE not set, the ORACLE_HOME  create  failed."
            echo ""
            echo "--For Oracle install and dbca"
            echo "Case 1: install soft,create listener,create db,db optimization"
            echo "       Eg: sh 1.sh -c zhs16gbk -d /app/ -H testdb -i 192.168.239.62 [-o /app] -n Y [-p 1531] -s ora19c "
            echo "Case 2: create listener,create db,db optimization and need run use root account"
            echo "       Eg: sh 1.sh -c zhs16gbk -d /app/ -C Y -i 192.168.239.62 -s ora18c -n Y [-p 1531] "  
            echo "Case 3: create db,db optimization and need run use root account"
            echo "       Eg: sh 1.sh -c zhs16gbk -d /app/ -C Y -s ora18c "  
            echo "Case 4: Install soft and create listener and need run use root account"
            echo "       Eg: sh 1.sh -d /oracle -o /oracle -H testdb -i 10.211.55.18 -n Y [-p 1531]  "  
            echo "Case 5: Install soft only and need run use root account"
            echo "       Eg: sh 1.sh -d /oracle -o /oracle -H testdb -i 10.211.55.18 "              
            echo "Case 6: Install soft and create listener and need run use root account"
            echo "       Eg: sh 1.sh -d /oracle  -i 10.211.55.18 -n Y [-p 1541]"                      
            echo ""
            echo "--For Oracle single instance Deinstall"
            echo "Case :"
            echo "      Eg: sh 1.sh -d /app/  -D Y"
            echo ""
            echo ""
            exit 1
            ;;
        H)
            HOST_NAME=$OPTARG
            echo "option:H, value $OPTARG"
            echo "HOST_NAME IS: $HOST_NAME"
            ;;            
        i)
            IP=$OPTARG
            echo "option:i, value $OPTARG"
            echo "IP IS: $IP"
            ;;              
        n)
            NETCA_FLAG=$OPTARG
            echo "option:n, value $OPTARG"
            echo "NETCA_FLAG IS: $NETCA_FLAG"
            ;;   
        o)
            OS_DIR=$OPTARG
            echo "option:o, value $OPTARG"
            echo "OS_DIR IS: $OS_DIR"
            ;;
        O)
            ORA_DATA_DIR=$OPTARG
            echo "option:O, value $OPTARG"
            echo "ORA_DATA_DIR IS: $ORA_DATA_DIR"
			;;
        p)
            PORT=$OPTARG
            echo "option:p, value $OPTARG"
            echo "PORT IS: $PORT"
            ;;
        P)
            PDB_MODE=$OPTARG
            echo "option:p, value $OPTARG"
            echo "PDB_MODE IS: $PDB_MODE"
            ;;            
        s)
            SID=$OPTARG
            echo "option:s, value $OPTARG"
            echo "SID IS: $SID"
            ;;         
        r)
            ORA_SOFT_RELEASE=$OPTARG
            echo "option:r, value $OPTARG"
            echo "ORA_SOFT_RELEASE IS: $ORA_SOFT_RELEASE"
            ;;
        \?)
            echo "Warnning: Please must specify -h option and must specify Any option value"
            exit 1
            ;;
    esac
done


function alert() {
	echo -e "$1"
	exit -1
}

test -z "$ARCHIVE_DIR" && ARCHIVE_DIR=N
test -z "$ORA_DATA_DIR" && alert "DATA DIR is NULL."
test -d $ORA_DATA_DIR || alert "DATA DIR IS NOT EXIST!!CHECK!!"
test -z "$SID" && SID=N
test -z "$DBCA_ONLY" && DBCA_ONLY=N
test -z "$DEINSTALL_FLAG" && DEINSTALL_FLAG=N
test -z "$PORT" && PORT=1521
test -z "$OS_DIR" && OS_DIR=/dev/cdrom
test -z "$HOST_NAME" && HOST_NAME=`hostname`
test -z "$NETCA_FLAG" && NETCA_FLAG=N
test -z "$PDB_MODE" && PDB_MODE=N
test -z "$ORA_SOFT_RELEASE" && ORA_SOFT_RELEASE=`ls ${INSTALL_DIR}/*zip|awk -F "_" '{print $2}'|sort -n|tail -1`

cd  $INSTALL_DIR
#relevance parameters
LOG_DIR=/tmp
BAK_DIR=/tmp/mcbak_`date +%Y-%m-%d_%H%M`
ROLLBAK_SCRIPT=/tmp/mc_os_rollbak.sh
#ORA_SOFT_RELEASE=`ls ${INSTALL_DIR}/*zip|awk -F "_" '{print $2}'|sort -n|tail -1`
ORA_BASE=${INSTALL_DIR}/app/oracle
ORA_HOME=${ORA_BASE}/product/${ORA_SOFT_RELEASE}/dbhome_1
ORA_INV=${INSTALL_DIR}/app/oraInventory 
OS_VERSION=`cat /etc/redhat-release|tr -cd 0-9.|awk -F "." '{print $1}'` 
ORA_USER=oracle
ORA_USERPWD=oracle
SYSPWD=oracle
totalMem=`free -m | grep Mem: |sed 's/^Mem:\s*//'| awk '{print $1}'`
#memLock=`echo "$totalMem*0.8*1024" |bc|awk '{printf "%.f", $0}'`
mkdir -p $BAK_DIR


function precheck() {
	test -d ${INSTALL_DIR}&& cd ${INSTALL_DIR} || alert "ERROR: INSTALL_DIR is not exist."
    echo "--------------------STEP03_01~N1~[precheck][cd_dir]--------------------"
	vs=`ls *zip|awk -F "_" '{print $2}'|sort -n|tail -1`
	if [[ "$vs" = "112040" || "$vs" = "121020" || "$vs" = "12201" || "$vs" = "180000" || "$vs" = "193000" ]]; then
		echo dbsoft media version is $vs
        echo "--------------------STEP03_02~N1~[precheck][check_media_version]--------------------"
	else
		alert "***********************Error: dbsoft media version check failed***********************"
	fi
}

function gather_hugepages_set_script() {
#add @20200808 
#ref MOS Doc ID 401749.1
    cat > ${PRO_DIR}/hugepages_settings.sh <<"EOF"
#!/bin/bash
#
# hugepages_settings.sh
#
# Linux bash script to compute values for the
# recommended HugePages/HugeTLB configuration
# on Oracle Linux
#
# Note: This script does calculation for all shared memory
# segments available when the script is run, no matter it
# is an Oracle RDBMS shared memory segment or not.
#
# This script is provided by Doc ID 401749.1 from My Oracle Support
# http://support.oracle.com

# Welcome text
echo "
This script is provided by Doc ID 401749.1 from My Oracle Support
(http://support.oracle.com) where it is intended to compute values for
the recommended HugePages/HugeTLB configuration for the current shared
memory segments on Oracle Linux. Before proceeding with the execution please note following:
 * For ASM instance, it needs to configure ASMM instead of AMM.
 * The 'pga_aggregate_target' is outside the SGA and
   you should accommodate this while calculating the overall size.
 * In case you changes the DB SGA size,
   as the new SGA will not fit in the previous HugePages configuration,
   it had better disable the whole HugePages,
   start the DB with new SGA size and run the script again.
And make sure that:
 * Oracle Database instance(s) are up and running
 * Oracle Database 11g Automatic Memory Management (AMM) is not setup
   (See Doc ID 749851.1)
 * The shared memory segments can be listed by command:
     # ipcs -m


Press Enter to proceed..."

read

# Check for the kernel version
KERN=`uname -r | awk -F. '{ printf("%d.%d\n",$1,$2); }'`

# Find out the HugePage size
HPG_SZ=`grep Hugepagesize /proc/meminfo | awk '{print $2}'`
if [ -z "$HPG_SZ" ];then
    echo "The hugepages may not be supported in the system where the script is being executed."
    exit 1
fi

# Initialize the counter
NUM_PG=0

# Cumulative number of pages required to handle the running shared memory segments
for SEG_BYTES in `ipcs -m | cut -c44-300 | awk '{print $1}' | grep "[0-9][0-9]*"`
do
    MIN_PG=`echo "$SEG_BYTES/($HPG_SZ*1024)" | bc -q`
    if [ $MIN_PG -gt 0 ]; then
        NUM_PG=`echo "$NUM_PG+$MIN_PG+1" | bc -q`
    fi
done

RES_BYTES=`echo "$NUM_PG * $HPG_SZ * 1024" | bc -q`

# An SGA less than 100MB does not make sense
# Bail out if that is the case
if [ $RES_BYTES -lt 100000000 ]; then
    echo "***********"
    echo "** ERROR **"
    echo "***********"
    echo "Sorry! There are not enough total of shared memory segments allocated for
HugePages configuration. HugePages can only be used for shared memory segments
that you can list by command:

    # ipcs -m

of a size that can match an Oracle Database SGA. Please make sure that:
 * Oracle Database instance is up and running
 * Oracle Database 11g Automatic Memory Management (AMM) is not configured"
    exit 1
fi

# Finish with results
case $KERN in
    '2.4') HUGETLB_POOL=`echo "$NUM_PG*$HPG_SZ/1024" | bc -q`;
           echo "Recommended setting: vm.hugetlb_pool = $HUGETLB_POOL" ;;
    '2.6') echo "Recommended setting: vm.nr_hugepages = $NUM_PG" ;;
    '3.8') echo "Recommended setting: vm.nr_hugepages = $NUM_PG" ;;
    '3.10') echo "Recommended setting: vm.nr_hugepages = $NUM_PG" ;;
    '4.1') echo "Recommended setting: vm.nr_hugepages = $NUM_PG" ;;
    '4.14') echo "Recommended setting: vm.nr_hugepages = $NUM_PG" ;;
    *) echo "Kernel version $KERN is not supported by this script (yet). Exiting." ;;
esac

# End
EOF

    chmod +x ${PRO_DIR}/hugepages_settings.sh
    echo "after completed dbca,run the  ${PRO_DIR}/hugepages_settings.sh to setup HugePages!!"
    echo "NOTE: the size maybe related /etc/security/limits.conf and /etc/sysctl.conf "
    echo "--------------------STEP08_02~N1~[db_opti][hugepage_scr_gather]--------------------"
}

function basic_os_config() {
    if [ -e $ROLLBAK_SCRIPT ]; then
        mv $ROLLBAK_SCRIPT ${ROLLBAK_SCRIPT}_`date +%Y-%m-%d_%H%M`
        touch $ROLLBAK_SCRIPT
    fi
    if [ $totalMem -le 2000 ]; then 
       alert "***********************ERROR:The physical memory is ${totalMem}M,oracle requires at least 2G" || echo "Your physical memory is ${totalMem} (in MB)"
    fi
    #needed="bc binutils compat-libcap1 compat-libstdc++ compat-libstdc++-33  dstat elfutils-libelf elfutils-libelf-devel expect fontconfig-devel gcc gcc-c++ glibc glibc-common glibc-devel glibc-devel.i686 glibc-headers glibc.i686 ksh libX11 libX11.i686 libXau libXau.i686 libXext libXext.i686 libXi libXi.i686 libXrender libXrender-devel libXtst libXtst.i686 libaio libaio-devel libaio-devel.i686 libaio.i686 libgcc libgcc.i686 librdmacm-devel libstdc++ libstdc++-devel libstdc++-devel.i686 libstdc++.i686 libxcb  make net-tools nfs-utils smartmontools sysstat tree unixODBC unixODBC-devel unzip zlib-devel "
    needed="bc binutils compat-libcap1 compat-libstdc++ compat-libstdc++-33 elfutils-libelf elfutils-libelf-devel fontconfig-devel gcc gcc-c++ glibc glibc-common glibc-devel glibc-headers  glibc.i686 ksh libaio libaio-devel libgcc librdmacm-devel libstdc++ libstdc++-devel libX11 libXau libxcb libXi libXrender libXrender-devel libXtst make net-tools smartmontools sysstat unzip dstat tree expect xclock psmisc"
    missing=$(rpm -q $needed| grep "not installed")
 
    if [ ! -z "$missing" ]; then
        if [ ${OS_DIR} != "F" ] && [ ${OS_DIR} != "f" ] ; then
            test ${OS_DIR} = /dev/cdrom && mount -o loop ${OS_DIR} /mnt || mount -o loop ${OS_DIR}/*.iso /mnt           
                test $? != 0 && alert "***********************Error: mounting the os media***********************"
                test -d /etc/yum.repos.d/bak || mkdir /etc/yum.repos.d/bak && mv -f /etc/yum.repos.d/*.repo /etc/yum.repos.d/bak
              cat >/etc/yum.repos.d/dvd.repo<<EOF
[dvd]
name=dvd
baseurl=file:///mnt/
gpgcheck=0
enabled=1
EOF
            if [ -e /etc/yum.conf ]; then
                cp /etc/yum.conf $BAK_DIR/
                echo "cp -f $BAK_DIR/yum.conf  /etc/yum.conf" >>$ROLLBAK_SCRIPT
            fi
              sed -i 's/^gpgcheck=1/gpgcheck=0/' /etc/yum.conf 
          fi
            yum clean all
          yum install $needed -y
        test $? != 0 && umount /mnt && alert "***********************Error: yum installed error!***********************"

        if  [ ${OS_DIR} != "F" ] && [ ${OS_DIR} != "f" ]; then
            umount /mnt
        fi
    fi 
    echo "--------------------STEP04_01~N1~[os_config][install_rpm]--------------------"

	groupadd -g 1100 oinstall 
	groupadd -g 1101 dba 
	useradd -u 1100 -g oinstall -G dba $ORA_USER
	chown  $ORA_USER:oinstall $INSTALL_DIR
	echo $ORA_USERPWD |passwd $ORA_USER --stdin
    echo "--------------------STEP04_02~N1~[os_config][user_group_basic_config]--------------------"
	sed -i '10,$d' /home/$ORA_USER/.bash_profile
	cat >>/home/$ORA_USER/.bash_profile<<EOF
export LANG=en_US.UTF-8
export ORACLE_BASE=$ORA_BASE
export ORACLE_HOME=$ORA_HOME
export PATH=\$ORACLE_HOME/bin:\$PATH
EOF
    echo "--------------------STEP04_03~N1~[os_config][.bash_profile_config]--------------------"


    pg_size=`getconf PAGESIZE`  
    mem_total=`grep  MemTotal /proc/meminfo|awk '{print $2}'` #KB 
    shmmax_tmp=`echo ${mem_total}*1024*0.9|bc|awk '{printf "%.f", $0}'`
    shmall_tmp=`echo ${shmmax_tmp}/${pg_size}|bc|awk '{printf "%.f", $0}'`
    shmmax_mem=`cat /proc/sys/kernel/shmmax`
    shmall_mem=`cat /proc/sys/kernel/shmall`
    if [ "$shmmax_mem" -ge "$shmmax_tmp" ]; then
        shmmax=$shmmax_mem
    else
        shmmax=$shmmax_tmp
    fi
    if [ "$shmall_mem" -ge "$shmall_tmp" ]; then
        shmall=$shmall_mem
    else
        shmall=$shmall_tmp
    fi
    if [ -e /etc/sysctl.conf ]; then
        cp /etc/sysctl.conf $BAK_DIR/
        echo "cp -f $BAK_DIR/sysctl.conf  /etc/sysctl.conf" >>$ROLLBAK_SCRIPT
    fi 
    cat >>/etc/sysctl.conf <<EOF
fs.aio-max-nr = 3145728 #MC_INSTALL_TAG
fs.file-max = 6815744  #MC_INSTALL_TAG
kernel.shmall = $shmall #MC_INSTALL_TAG
kernel.shmmax = $shmmax #MC_INSTALL_TAG
kernel.shmmni = 4096 #MC_INSTALL_TAG
kernel.sem = 250 32000 100 128 #MC_INSTALL_TAG
net.ipv4.ip_local_port_range = 9000 65500  #MC_INSTALL_TAG
net.core.rmem_default = 262144  #MC_INSTALL_TAG
net.core.rmem_max = 4194304 #MC_INSTALL_TAG
net.core.wmem_default = 262144 #MC_INSTALL_TAG
net.core.wmem_max = 1048576 #MC_INSTALL_TAG
EOF
    /sbin/sysctl -p
        
    
    if [ -e /etc/security/limits.conf ]; then
       cp  /etc/security/limits.conf $BAK_DIR/
       echo "cp -f $BAK_DIR/limits.conf  /etc/security/limits.conf">>$ROLLBAK_SCRIPT
    fi 
    memLock=`echo "$totalMem*0.6*1024" |bc|awk '{printf "%.f", $0}'`
	cat >> /etc/security/limits.conf <<EOF
$ORA_USER soft nproc 2047  #MC_INSTALL_TAG
$ORA_USER hard nproc 16384 #MC_INSTALL_TAG
$ORA_USER soft nofile 1024 #MC_INSTALL_TAG
$ORA_USER hard nofile 65536 #MC_INSTALL_TAG
$ORA_USER soft stack 10240 #MC_INSTALL_TAG
$ORA_USER soft stack 32768 #MC_INSTALL_TAG
$ORA_USER soft memlock $memLock #MC_INSTALL_TAG
$ORA_USER hard memlock $memLock #MC_INSTALL_TAG
EOF

 	MaxMemlock=`su - $ORA_USER -c "ulimit -a"| grep 'max locked memory'| awk '{print $NF}'`
	test "$MaxMemlock" != "$memLock" && alert "***********************ERROR:User $ORA_USER created or configed with error***********************"
    echo "--------------------STEP04_04~N1~[os_config][mem_config]--------------------"


    cp /etc/pam.d/login $BAK_DIR/ 
    echo "cp -f $BAK_DIR/login  /etc/pam.d/login" >>$ROLLBAK_SCRIPT
    echo "session    required     pam_limits.so      #MC_INSTALL_TAG" >>/etc/pam.d/login

    cp /etc/profile $BAK_DIR
    echo "cp -f $BAK_DIR/profile  /etc/profile" >>$ROLLBAK_SCRIPT
    cat >>/etc/profile <<EOF
if [ \$USER = "oracle" ] ; then             #MC_INSTALL_TAG
    if [ \$SHELL = "/bin/ksh" ]; then            #MC_INSTALL_TAG
        ulimit -p 16384            #MC_INSTALL_TAG
        ulimit -n 65536            #MC_INSTALL_TAG
		ulimit -s unlimited            #MC_INSTALL_TAG
    else            #MC_INSTALL_TAG
        ulimit -u 16384 -n 65536            #MC_INSTALL_TAG
		ulimit -s unlimited            #MC_INSTALL_TAG
    fi            #MC_INSTALL_TAG
    umask 022            #MC_INSTALL_TAG
fi            #MC_INSTALL_TAG
EOF
    echo "--------------------STEP04_05~N1~[os_config][user_login_config]--------------------"

    if [ -e /etc/selinux/config ]; then
       cp  /etc/selinux/config $BAK_DIR/
       echo "cp -f $BAK_DIR/config /etc/selinux/config">>$ROLLBAK_SCRIPT
    fi     
    sed -i 's/^SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
    setenforce 0
    echo "--------------------STEP04_06~N1~[os_config][selinux_off]--------------------"

    echo "-----------------------INFO: basic_os_config is complete -----------------------"
}

function linux6_os_config() {
	chkconfig NetworkManager off
    service NetworkManager stop

	service iptables stop
    chkconfig iptables off
    echo "--------------------STEP04_07~N1~[os_config][iptables/network_manager/avahi-daemon(linux7):off]--------------------"

	HOST_NAME_CUR=`hostname`
	#Judge input host_name valid
	if [ "$HOST_NAME" = "localhost" ] || [ "$HOST_NAME" = "localhost.localdomain" ] || [[ "$HOST_NAME" =~ "_" ]]; then 
		alert "***********************Error: Hostname is illegal.***********************"
	fi
	#change hostname 
    if [ "$HOST_NAME_CUR" = "$HOST_NAME" ]; then
        cp /etc/hosts $BAK_DIR
        echo "cp -f $BAK_DIR/hosts /etc/hosts">>$ROLLBAK_SCRIPT
    	echo "$IP $HOST_NAME  #MC_INSTALL_TAG" >>/etc/hosts
	else
        cp /etc/hosts $BAK_DIR
        echo "cp -f $BAK_DIR/hosts /etc/hosts">>$ROLLBAK_SCRIPT    
        cp /etc/sysconfig/network $BAK_DIR
        echo "cp -f $BAK_DIR/network /etc/sysconfig/network" >>$ROLLBAK_SCRIPT
	    hostname $HOST_NAME
		#sed -i 's/'$HOSTNAME'/'$HOST_NAME'/' /etc/sysconfig/network
		sed -i '/HOSTNAME/d' /etc/sysconfig/network  #del the HOSTNAME line
        echo "HOSTNAME=$HOST_NAME" >>/etc/sysconfig/network #add new hostname into files
	    echo "$IP $HOST_NAME            #MC_INSTALL_TAG" >>/etc/hosts
    fi
    echo "--------------------STEP04_08~N1~[os_config][hostname_config]--------------------"
    echo "-----------------------INFO: linux6_os_config is complete -----------------------"
}

function linux7_os_config() {
    systemctl stop NetworkManager
	systemctl disable NetworkManager
	systemctl stop firewalld
	systemctl disable firewalld
	systemctl disable avahi-daemon
    echo "--------------------STEP04_07~N1~[os_config][iptables/network_manager/avahi-daemon(linux7):off]--------------------"

	HOST_NAME_CUR=`hostname`
	#Judge input host_name valid
	if [ "$HOST_NAME" = "localhost" ] || [ "$HOST_NAME" = "localhost.localdomain" ] || [[ "$HOST_NAME" =~ "_" ]]; then 
		alert "***********************Error: Hostname is illegal.***********************"
	fi
    if [ "$HOST_NAME_CUR" = "$HOST_NAME" ]; then
    	echo "$IP $HOST_NAME            #MC_INSTALL_TAG" >>/etc/hosts
        echo "cp -f $BAK_DIR/hosts /etc/hosts">>$ROLLBAK_SCRIPT
	else
       cp /etc/hosts $BAK_DIR
       echo "cp -f $BAK_DIR/hosts /etc/hosts">>$ROLLBAK_SCRIPT    
	   hostnamectl set-hostname $HOST_NAME
	   #echo `hostname` 
	   echo "$IP $HOST_NAME            #MC_INSTALL_TAG" >>/etc/hosts
    fi
    echo "--------------------STEP04_08~N1~[os_config][hostname_config]--------------------"
    echo "-----------------------INFO: linux7_os_config is complete -----------------------"
}
 
function ora_rdbms_install() {
	mkdir -p $ORA_HOME
	mkdir -p $ORA_INV
	chown -R ${ORA_USER}:oinstall $ORA_BASE $ORA_INV
	chmod 755 $ORA_BASE
	chmod 770 $ORA_INV
    echo "--------------------STEP04_01~N1~[soft_install][soft_install_dir_config]--------------------"

    chown $ORA_USER:oinstall  ${INSTALL_DIR}/*.zip
    cd  $INSTALL_DIR
    case "$ORA_SOFT_RELEASE" in
        112040)
	        cat > db_install.rsp <<EOF
oracle.install.responseFileVersion=/oracle/install/rspfmt_dbinstall_response_schema_v11_2_0
oracle.install.option=INSTALL_DB_SWONLY
ORACLE_HOSTNAME=$HOST_NAME
UNIX_GROUP_NAME=oinstall
INVENTORY_LOCATION=$ORA_INV
SELECTED_LANGUAGES=en
ORACLE_HOME=$ORA_HOME
ORACLE_BASE=$ORA_BASE
oracle.install.db.InstallEdition=EE
oracle.install.db.EEOptionsSelection=false
oracle.install.db.optionalComponents=oracle.rdbms.partitioning:11.2.0.4.0,oracle.oraolap:11.2.0.4.0,oracle.rdbms.dm:11.2.0.4.0,oracle.rdbms.dv:11.2.0.4.0,oracle.rdbms.lbac:11.2.0.4.0,oracle.rdbms.rat:11.2.0.4.0
oracle.install.db.DBA_GROUP=dba
oracle.install.db.OPER_GROUP=dba
DECLINE_SECURITY_UPDATES=true
oracle.installer.autoupdates.option=SKIP_UPDATES
EOF
            ;;
        12102[0])
            cat > db_install.rsp <<EOF
oracle.install.responseFileVersion=/oracle/install/rspfmt_dbinstall_response_schema_v12.1.0
oracle.install.option=INSTALL_DB_SWONLY
UNIX_GROUP_NAME=oinstall
INVENTORY_LOCATION=$ORA_INV
ORACLE_HOME=$ORA_HOME
ORACLE_BASE=$ORA_BASE
oracle.install.db.InstallEdition=EE
oracle.install.db.DBA_GROUP=dba
oracle.install.db.OPER_GROUP=dba
oracle.install.db.BACKUPDBA_GROUP=dba
oracle.install.db.DGDBA_GROUP=dba
oracle.install.db.KMDBA_GROUP=dba
DECLINE_SECURITY_UPDATES=true
oracle.installer.autoupdates.option=SKIP_UPDATES
#oracle.install.db.rootconfig.executeRootScript=false	
EOF
            ;;
        12201)  
        	cat > db_install.rsp <<EOF
oracle.install.responseFileVersion=/oracle/install/rspfmt_dbinstall_response_schema_v12c
oracle.install.option=INSTALL_DB_SWONLY
UNIX_GROUP_NAME=oinstall
INVENTORY_LOCATION=$ORA_INV
ORACLE_HOME=$ORA_HOME
ORACLE_BASE=$ORA_BASE
oracle.install.db.InstallEdition=EE
oracle.install.db.OSDBA_GROUP=dba
oracle.install.db.OSOPER_GROUP=dba
oracle.install.db.OSBACKUPDBA_GROUP=dba
oracle.install.db.OSDGDBA_GROUP=dba
oracle.install.db.OSKMDBA_GROUP=dba
oracle.install.db.OSRACDBA_GROUP=dba
#oracle.install.db.rootconfig.executeRootScript=false	
EOF
            ;;
        180000)
	        cat > db_install.rsp <<EOF
oracle.install.responseFileVersion=/oracle/install/rspfmt_dbinstall_response_schema_v18.0.0
oracle.install.option=INSTALL_DB_SWONLY
UNIX_GROUP_NAME=oinstall
INVENTORY_LOCATION=$ORA_INV
ORACLE_HOME=$ORA_HOME
ORACLE_BASE=$ORA_BASE
oracle.install.db.InstallEdition=EE
oracle.install.db.OSDBA_GROUP=dba
oracle.install.db.OSOPER_GROUP=dba
oracle.install.db.OSBACKUPDBA_GROUP=dba
oracle.install.db.OSDGDBA_GROUP=dba
oracle.install.db.OSKMDBA_GROUP=dba
oracle.install.db.OSRACDBA_GROUP=dba
#oracle.install.db.rootconfig.executeRootScript=false	
EOF
            ;; 
        193000)
	        cat > db_install.rsp <<EOF
oracle.install.responseFileVersion=/oracle/install/rspfmt_dbinstall_response_schema_v19.0.0
oracle.install.option=INSTALL_DB_SWONLY
UNIX_GROUP_NAME=oinstall
INVENTORY_LOCATION=$ORA_INV
ORACLE_HOME=$ORA_HOME
ORACLE_BASE=$ORA_BASE
oracle.install.db.InstallEdition=EE
oracle.install.db.OSDBA_GROUP=dba
oracle.install.db.OSOPER_GROUP=dba
oracle.install.db.OSBACKUPDBA_GROUP=dba
oracle.install.db.OSDGDBA_GROUP=dba
oracle.install.db.OSKMDBA_GROUP=dba
oracle.install.db.OSRACDBA_GROUP=dba
oracle.install.db.rootconfig.executeRootScript=false	
EOF
            ;;
        \?)
            echo "***********************ERROR: U upload the db soft is not correct***********************"
            exit 1
            ;;
    esac
   	chown $ORA_USER *.rsp
	chmod 600 *.rsp
    echo "--------------------STEP04_02~N1~[soft_install][create_soft_response_file]--------------------"

    if [ "$ORA_SOFT_RELEASE" == "112040" ] || [ "$ORA_SOFT_RELEASE" == "12102" ]  || [ "$ORA_SOFT_RELEASE" == "121020" ]  || [ "$ORA_SOFT_RELEASE" == "12201" ]  ; then
        su - $ORA_USER -c "cd $INSTALL_DIR;unzip  -o ${INSTALL_DIR}//\*.zip;./database/runInstaller -waitforcompletion -silent -ignorePrereq -responseFile $INSTALL_DIR/db_install.rsp" >${LOG_DIR}/rdbms.log
    else
        su - $ORA_USER -c "cd ${INSTALL_DIR};unzip   -o -d ${ORA_HOME} ${INSTALL_DIR}/*.zip;${ORA_HOME}/runInstaller -silent -ignorePrereq  -waitForCompletion -responseFile ${INSTALL_DIR}/db_install.rsp" >${LOG_DIR}/rdbms.log
    fi 
    grep "Success" ${LOG_DIR}/rdbms.log  || alert "DB rdbms install Failed!"
 
    su - $ORA_USER -c "sqlplus -v"
    test $? != 0 && cp $INSTALL_DIR/99-sysctl.conf /etc/sysctl.d/ && cp $INSTALL_DIR/limits.conf /etc/security/ && alert "***********************ERROR:RDBMS soft install failed***********************" 
    echo "--------------------STEP04_03~N1~[soft_install][create_soft_response_file]--------------------"
}

function netca() {
    test -z "$ORA_SOFT_RELEASE" && ORA_SOFT_RELEASE=`su - ${ORA_USER} -c "sqlplus -v |grep -v "^$"|tail -n 1|tr -cd 0-9"` 
    su - $ORA_USER -c " cat >>$ORA_HOME/network/admin/listener.ora <<EOF
LISTENER =  
  (DESCRIPTION_LIST =  
    (DESCRIPTION =  
      (ADDRESS = (PROTOCOL = TCP)(HOST = $IP)(PORT = $PORT))
    )  
  )  
EOF
"
    echo "--------------------STEP06_01~N1~[listener][create_listener_file]--------------------"

	if [ "$ORA_SOFT_RELEASE" == "112040" ]; then
    su - $ORA_USER -c " cat >>$ORA_HOME/network/admin/sqlnet.ora <<EOF
SQLNET.ALLOWED_LOGON_VERSION=8
EOF
"	
	else
	su - $ORA_USER -c " cat >>$ORA_HOME/network/admin/sqlnet.ora <<EOF
SQLNET.ALLOWED_LOGON_VERSION_CLIENT=8
SQLNET.ALLOWED_LOGON_VERSION_SERVER=8
EOF
"	
	fi
    echo "--------------------STEP06_02~N1~[listener][opti_connect_config]--------------------"

    su - $ORA_USER -c "$ORA_HOME/bin/lsnrctl start listener"
    echo "--------------------STEP06_03~N1~[listener][start_listener]--------------------"
}

function ora_dbca() {
    cd $INSTALL_DIR
    test -z "$ORA_SOFT_RELEASE" && ORA_SOFT_RELEASE=`su - ${ORA_USER} -c "sqlplus -v |grep -v "^$"|tail -n 1|tr -cd 0-9"` 
    totalMem=`free -m | grep Mem: |sed 's/^Mem:\s*//'| awk '{print $1}'`
	[ $totalMem -lt 2000 ] && alert "***********************ERROR:The physical memory is ${tootalMem}M,oracle requires at least 2G" || echo "Your physical memory is ${tootalMem} (in MB)"
:<<!
	declare -i oracleMem=$tootalMem*40/100
    shmsize=`df -k /dev/shm|grep tmpfs|awk '{print $2}'`
	if [ $shmsize -lt 2000000 ]; then
	    mount -o remount,size=2G /dev/shm/
    fi
!

        cat >>/home/$ORA_USER/.bash_profile<<EOF
export ORACLE_SID=$SID
EOF

    case "$ORA_SOFT_RELEASE" in
        112040)
            cat > dbca.rsp <<EOF
[GENERAL]
RESPONSEFILE_VERSION=11.2.0
OPERATION_TYPE=createDatabase
[CREATEDATABASE]
GDBNAME= $SID
SID=$SID
TEMPLATENAME=General_Purpose.dbc
SYSPASSWORD=$SYSPWD
SYSTEMPASSWORD=$SYSPWD
HOSTUSERNAME=$HOST_NAME
DATAFILEDESTINATION=$ORA_DATA_DIR
STORAGETYPE=FS
CHARACTERSET=$CHARACTER
NATIONALCHARACTERSET=AL16UTF16
SAMPLESCHEMA=FALSE
MEMORYPERCENTAGE=40
AUTOMATICMEMORYMANAGEMENT=FALSE
DATABASETYPE=OLTP
SYSDBAUSERNAME=sys
SYSDBAPASSWORD=$SYSPWD
ENABLESECURITYCONFIGURATION=false
EMCONFIGURATION=NONE
EOF
            ;;
        12102[0]) 
			if [ $PDB_MODE = 'N' ] || [ $PDB_MODE = 'n' ]; then
                cat > dbca.rsp <<EOF
[GENERAL]
RESPONSEFILE_VERSION="12.1.0"
OPERATION_TYPE="createDatabase"
[CREATEDATABASE]
gdbName="$SID"
sid="$SID"
templateName="$ORA_HOME/assistants/dbca/templates/General_Purpose.dbc"
createAsContainerDatabase=FALSE
sysPassword="$SYSPWD"
systemPassword="$SYSPWD"
datafileDestination=$ORA_DATA_DIR
redoLogFileSize=200
storageType=FS
characterSet="$CHARACTER"
nationalCharacterSet="AL16UTF16"
sampleSchema=false
memoryPercentage=40
automaticMemoryManagement=FALSE
databaseType="OLTP"
emConfiguration="NONE"
EOF
            else 
                cat > dbca.rsp <<EOF
[GENERAL]
RESPONSEFILE_VERSION="12.1.0"
OPERATION_TYPE="createDatabase"
[CREATEDATABASE]
gdbName="$SID"
sid="$SID"
templateName="$ORA_HOME/assistants/dbca/templates/General_Purpose.dbc"
createAsContainerDatabase=TRUE
sysPassword="$SYSPWD"
systemPassword="$SYSPWD"
datafileDestination=$ORA_DATA_DIR
redoLogFileSize=200
storageType=FS
characterSet="$CHARACTER"
nationalCharacterSet="AL16UTF16"
sampleSchema=false
memoryPercentage=40
automaticMemoryManagement=FALSE
databaseType="OLTP"
emConfiguration="NONE"
EOF
		    fi
            ;;
        12201)
			if [ $PDB_MODE = 'N' ] || [ $PDB_MODE = 'n' ]; then
        	    cat > dbca.rsp <<EOF
responseFileVersion=/oracle/assistants/rspfmt_dbca_response_schema_v12.2.0
gdbName=$SID
sid=$SID
templateName=General_Purpose.dbc
createAsContainerDatabase=false
sysPassword=$SYSPWD
systemPassword=$SYSPWD
datafileDestination=$ORA_DATA_DIR
redoLogFileSize=200
storageType=FS
characterSet=$CHARACTER
nationalCharacterSet=AL16UTF16
sampleSchema=false
memoryPercentage=40
automaticMemoryManagement=FALSE
databaseType=OLTP
emConfiguration=NONE
EOF
            else
        	    cat > dbca.rsp <<EOF
responseFileVersion=/oracle/assistants/rspfmt_dbca_response_schema_v12.2.0
gdbName=$SID
sid=$SID
databaseConfigType=SI
templateName=General_Purpose.dbc
createAsContainerDatabase=TRUE
sysPassword=$SYSPWD  
systemPassword=$SYSPWD  
datafileDestination=$ORA_DATA_DIR 
storageType=FS
characterSet=$CHARACTER
nationalCharacterSet=AL16UTF16
sampleSchema=false
memoryPercentage=40
automaticMemoryManagement=FALSE
databaseType=OLTP
emConfiguration=NONE 
EOF
            fi
            ;;
        180000)
			if [ $PDB_MODE = 'N' ] || [ $PDB_MODE = 'n' ]; then
	            cat > dbca.rsp <<EOF
responseFileVersion=/oracle/assistants/rspfmt_dbca_response_schema_v18.0.0
gdbName=$SID
sid=$SID
templateName=General_Purpose.dbc
databaseConfigType=SI
createAsContainerDatabase=false
sysPassword=$SYSPWD
systemPassword=$SYSPWD
datafileDestination=$ORA_DATA_DIR
storageType=FS
characterSet=$CHARACTER
nationalCharacterSet=AL16UTF16
sampleSchema=false
memoryPercentage=40
emConfiguration=NONE
databaseType=MULTIPURPOSE
automaticMemoryManagement=false
totalMemory=0
EOF
            else 
	            cat > dbca.rsp <<EOF
responseFileVersion=/oracle/assistants/rspfmt_dbca_response_schema_v18.0.0
gdbName=$SID
sid=$SID
templateName=General_Purpose.dbc
databaseConfigType=SI
createAsContainerDatabase=TRUE
sysPassword=$SYSPWD
systemPassword=$SYSPWD
datafileDestination=$ORA_DATA_DIR
storageType=FS
characterSet=$CHARACTER
nationalCharacterSet=AL16UTF16
sampleSchema=false
memoryPercentage=40
emConfiguration=NONE
databaseType=MULTIPURPOSE
automaticMemoryManagement=false
totalMemory=0
EOF
            fi
            ;; 
        193000)
            if [ $PDB_MODE = 'N' ] || [ $PDB_MODE = 'n' ]; then 
	        cat > dbca.rsp <<EOF
responseFileVersion=/oracle/assistants/rspfmt_dbca_response_schema_v19.0.0
gdbName=$SID
sid=$SID
templateName=General_Purpose.dbc
createAsContainerDatabase=FALSE
sysPassword=$SYSPWD
systemPassword=$SYSPWD
datafileDestination=$ORA_DATA_DIR
storageType=FS
characterSet=$CHARACTER
nationalCharacterSet=AL16UTF16
sampleSchema=false
memoryPercentage=40
automaticMemoryManagement=false
databaseType=OLTP
emConfiguration=NONE
EOF
            else 
	        cat > dbca.rsp <<EOF
responseFileVersion=/oracle/assistants/rspfmt_dbca_response_schema_v19.0.0
gdbName=$SID
sid=$SID
templateName=General_Purpose.dbc
createAsContainerDatabase=TRUE
sysPassword=$SYSPWD
systemPassword=$SYSPWD
datafileDestination=$ORA_DATA_DIR
storageType=FS
characterSet=$CHARACTER
nationalCharacterSet=AL16UTF16
sampleSchema=false
memoryPercentage=40
automaticMemoryManagement=false
databaseType=OLTP
emConfiguration=NONE
EOF
            fi
            ;;
        \?)
            echo "***********************ERROR: U upload the db soft is not correct***********************"
            exit 1
            ;;
    esac
    echo "--------------------STEP07_01~N1~[dbca][create_dbca_response_file]--------------------"
    
    #modify data_dir arch_dir owner and privs
    chown -R $ORA_USER:oinstall $ORA_DATA_DIR $ARCHIVE_DIR
    chmod -R 755 $ORA_DATA_DIR $ARCHIVE_DIR

    if [ $ORA_SOFT_RELEASE -eq '112040' ];then
        su - $ORA_USER -c "dbca -silent -responseFile ${INSTALL_DIR}/dbca.rsp  -redoLogFileSize 500" >${LOG_DIR}/dbca.log
        grep 'System Identifier(SID)' ${ORA_BASE}/cfgtoollogs/dbca/${SID}/${SID}*.log  || alert "dbca is failed.Please check."
    else
	      su - $ORA_USER -c "dbca -silent -responseFile ${INSTALL_DIR}/dbca.rsp -createDatabase -redoLogFileSize 500" >${LOG_DIR}/dbca.log
        #grep 'System Identifier(SID)' ${LOG_DIR}/dbca.log || alert "dbca is failed.Please check."
        grep 'System Identifier(SID)' ${ORA_BASE}/cfgtoollogs/dbca/${SID}/${SID}*.log  || alert "dbca is failed.Please check."
    fi
    echo "--------------------STEP07_02~N1~[dbca][create_db]--------------------"

	cat > db_check.sh<<EOF
export ORACLE_SID=${SID}
sqlplus -s / as sysdba <<eof
set newpage none
set head off
select open_mode from v\\\$database;
eof
EOF
	res=`su - $ORA_USER -c "sh ${INSTALL_DIR}/db_check.sh"`
	#rm -f dbca.rsp
	test "$res" != "READ WRITE" && cp $INSTALL_DIR/99-sysctl.conf /etc/sysctl.d/ && cp $INSTALL_DIR/limits.conf /etc/security/ && alert "***********************ERROR:DB $SID create failed***********************" 
    echo "--------------------STEP07_03~N1~[dbca][check_db_status]--------------------"
}


function db_opti() { 
    test -z "$ORA_SOFT_RELEASE" && ORA_SOFT_RELEASE=`su - ${ORA_USER} -c "sqlplus -v |grep -v "^$"|tail -n 1|tr -cd 0-9"` 

    case "$ORA_SOFT_RELEASE" in
        112040) 
            cat >>${INSTALL_DIR}/db_opti.sh<<EOF
export ORACLE_SID=$SID
sqlplus -s / as sysdba <<eof
alter system register;
col  db_log_dest  new_value db_log_dest_val noprint 
select SUBSTR(MEMBER,0,INSTR(MEMBER,'/',-1)-1) db_log_dest from v\\\$logfile where GROUP#=1;
ALTER DATABASE ADD LOGFILE GROUP 11 '&&db_log_dest_val/redo11.log' SIZE 500M;
ALTER DATABASE ADD LOGFILE GROUP 12  '&&db_log_dest_val/redo12.log' SIZE 500M;
alter system set db_files =2000 scope=spfile sid='*';
alter profile default limit  PASSWORD_LIFE_TIME unlimited;
alter profile default limit  FAILED_LOGIN_ATTEMPTS unlimited;
ALTER SYSTEM SET event='28401 TRACE NAME CONTEXT FOREVER, LEVEL 1' SCOPE=SPFILE SID='*';
alter system set audit_trail=none scope=spfile sid='*';
ALTER SYSTEM SET "_resource_manager_always_on"=FALSE SCOPE=SPFILE SID='*';
alter system set "_resource_manager_always_off"=true scope=spfile SID='*';
execute dbms_scheduler.set_attribute('SATURDAY_WINDOW','RESOURCE_PLAN',''); 
execute dbms_scheduler.set_attribute('SUNDAY_WINDOW','RESOURCE_PLAN','');
execute dbms_scheduler.set_attribute('MONDAY_WINDOW','RESOURCE_PLAN',''); 
execute dbms_scheduler.set_attribute('TUESDAY_WINDOW','RESOURCE_PLAN','');
execute dbms_scheduler.set_attribute('WEDNESDAY_WINDOW','RESOURCE_PLAN',''); 
execute dbms_scheduler.set_attribute('THURSDAY_WINDOW','RESOURCE_PLAN','');
execute dbms_scheduler.set_attribute('FRIDAY_WINDOW','RESOURCE_PLAN','');
ALTER SYSTEM SET deferred_segment_creation=FALSE SCOPE=SPFILE SID='*';
ALTER SYSTEM SET parallel_force_local=TRUE SCOPE=BOTH;
alter system set "_external_scn_rejection_threshold_hours"=1 scope=spfile sid='*';
alter system set "_external_scn_logging_threshold_seconds"=600 scope=spfile sid='*';
alter system set SEC_CASE_SENSITIVE_LOGON=false sid='*';
exit
eof
EOF

            ;; 
        193000)
            cat >> ${INSTALL_DIR}/db_opti.sh<<EOF
export ORACLE_SID=$SID
sqlplus -s / as sysdba <<eof
alter system register;
col  db_log_dest  new_value db_log_dest_val noprint 
select SUBSTR(MEMBER,0,INSTR(MEMBER,'/',-1)-1) db_log_dest from v\\\$logfile where GROUP#=1;
ALTER DATABASE ADD LOGFILE GROUP 11 '&&db_log_dest_val/redo11.log' SIZE 500M;
ALTER DATABASE ADD LOGFILE GROUP 12  '&&db_log_dest_val/redo12.log' SIZE 500M;
alter profile default limit  PASSWORD_LIFE_TIME unlimited;
alter profile default limit  FAILED_LOGIN_ATTEMPTS unlimited;
alter system set db_files =2000 scope=spfile sid='*';
alter system set audit_trail=none  scope=spfile sid='*';
alter system set archive_lag_target=1200 scope=spfile sid='*';
alter system set deferred_segment_creation=FALSE scope=spfile sid='*';
alter system set enable_ddl_logging=TRUE scope=spfile sid='*';
alter system set optimizer_adaptive_plans=FALSE scope=spfile sid='*';
alter system set parallel_force_local=TRUE  scope=spfile sid='*';
alter system set undo_retention=3600 scope=spfile sid='*';
alter system set "_clusterwide_global_transactions"=FALSE scope=spfile sid='*';
alter system set "_datafile_write_errors_crash_instance"=FALSE scope=spfile sid='*';
alter system set "_lm_drm_disable" = 7 scope=spfile sid='*';
alter system set "_optimizer_adaptive_cursor_sharing"=FALSE scope=spfile sid='*';
alter system set "_optimizer_ads_use_result_cache"=FALSE scope=spfile sid='*';
alter system set "_optimizer_aggr_groupby_elim"=FALSE scope=spfile sid='*';
alter system set "_optimizer_dsdir_usage_control"=0 scope=spfile sid='*';
alter system set "_optimizer_extended_cursor_sharing"=none scope=spfile sid='*';
alter system set "_optimizer_extended_cursor_sharing_rel"=none scope=spfile sid='*';
alter system set "_px_use_large_pool"=TRUE scope=spfile sid='*';
alter system set "_report_capture_cycle_time"=0 scope=spfile sid='*';
alter system set "_serial_direct_read"=never scope=spfile sid='*';
alter system set "_sql_plan_directive_mgmt_control"=0 scope=spfile sid='*'; 
alter system set "_use_adaptive_log_file_sync"=FALSE scope=spfile sid='*';
alter system set "_use_single_log_writer"=TRUE scope=spfile sid='*';
alter system set "_disable_file_resize_logging"=TRUE scope=spfile sid='*';
shutdown immediate
startup 
eof
EOF
            ;;
        \?)  
            echo  "***********************Warnning: DB parameters not optimization!***********************"
            exit 1
            ;;
    esac
    test -f ${INSTALL_DIR}/db_opti.sh && chown  $ORA_USER:oinstall  ${INSTALL_DIR}/db_opti.sh
    test -f ${INSTALL_DIR}/db_opti.sh && su - $ORA_USER -c "sh ${INSTALL_DIR}/db_opti.sh"
    echo "--------------------STEP08_01~N1~[db_opti][opti_db_config]--------------------"
}

function db_arch() {
    ###set db ARCHIVE mode @20200916 
    if [ -d $ARCHIVE_DIR ]; then
        su - ${ORA_USER} -c "export ORACLE_SID=$SID
sqlplus -s / as sysdba <<eof
alter system set log_archive_dest_1='location=${ARCHIVE_DIR}' scope=both;
shutdown immediate
startup mount
alter database archivelog;
alter database open;
eof
"
        db_status_check=`su - ${ORA_USER} -c "export ORACLE_SID=$SID
sqlplus -S / as sysdba<<'eof'
set newpage none
set head off
select open_mode||','||log_mode  from v\\$database;
eof
"
`

        OIFS=$IFS; IFS=","; set -- $db_status_check; OPEN_STAT=$1;ARCH_STAT=$2 IFS=$OIFS
        test "$ARCH_STAT" = 'ARCHIVELOG' && test  "$OPEN_STAT"  && echo "db arch set is ok" || alert "***********************ERROR: db status or db arch mode is error***********************"
    elif [ $ARCHIVE_DIR != 'N' ]; then
        alert "***********************ERROR: User set the ARCHIVE directory is not exist***********************"
    else 
        echo "***********************Warnning: User not set db in archive mode!***********************"    
    fi 
}
 
function deinstall_db_soft(){ 
    DEINSTALL_DIR=/tmp/deinstall_`date +%Y-%m-%d_%H%M`
    su - $ORA_USER -c "sh ${ORA_HOME}/deinstall/deinstall  -silent -checkonly -tmpdir ${DEINSTALL_DIR}"
    rsp=`find ${DEINSTALL_DIR} -name deinstall*rsp`
    echo "deinstall parameter file: "$rsp
    su - $ORA_USER -c "cd ${DEINSTALL_DIR};sh ${ORA_HOME}/deinstall/deinstall -silent -paramfile ${rsp} " >>${DEINSTALL_DIR}/deinstall_run.log
    grep Run ${DEINSTALL_DIR}/deinstall_run.log |awk -F"'" '{print $2}' >>${DEINSTALL_DIR}/run.sh 
    sh ${DEINSTALL_DIR}/run.sh
    rm -rf $INSTALL_DIR/*rsp
    rm -rf $INSTALL_DIR/*sh 
    rm -rf $INSTALL_DIR/database 
    rm -rf $INSTALL_DIR/app
    rm -rf /etc/oratab
    rm -rf /etc/oraInst.loc
    rm -rf /tmp/CVU*
    rm -rf /var/tmp/.oracle 
    userdel -r oracle 
    groupdel oinstall 
    groupdel dba
    sh $ROLLBAK_SCRIPT

}
function main() {
	DEBUG_FLG='McDeBuG'
	my_debug_flg=`echo $*| awk '{print $NF}'`
    if [[ "$my_debug_flg" = "$DEBUG_FLG" ]]; then
        export PS4='+{$LINENO:${FUNCNAME[0]}} '
        set -x
        echo args=$@
    fi
    case $DEINSTALL_FLAG in
        [nN])
            if [ ${DBCA_ONLY} == 'N' ] || [ ${DBCA_ONLY} == 'n' ]; then
                echo "-----------------------INFO1:db soft media check begin-----------------------";date
                precheck
                echo "-----------------------INFO1:OS config begin-----------------------";date
                basic_os_config
                if [ "$OS_VERSION" -eq 6 ]; then
                    linux6_os_config 
                else
                    linux7_os_config
                fi
                echo "-----------------------INFO1:RDBMS install begin-----------------------";date
                ora_rdbms_install
                echo "-----------------------INFO1:ROOT scripts begin-----------------------";date
                $ORA_INV/orainstRoot.sh
                $ORA_HOME/root.sh
                echo "--------------------STEP04_04~N1~[soft_install][soft_root_execute]--------------------"
                if [ ${SID} != 'N' ]; then
                    echo "-----------------------INFO1:netca begin-----------------------";date
                    netca
                    echo "-----------------------INFO1:netca end-----------------------";date
                    echo "-----------------------INFO1:dbca begin-----------------------";date
                    ora_dbca
                    echo "-----------------------INFO1:dbca end-----------------------";date
                    echo "-----------------------INFO1:db basic optimize begin-----------------------";date
                    db_opti
                    db_arch
                    gather_hugepages_set_script
                    echo "-----------------------INFO1:db basic optimize end-----------------------";date
                fi
            else
                if [ ${SID} != 'N' ]; then
                    if [ $NETCA_FLAG != 'N' ] && [ $NETCA_FLAG != 'n' ]; then
                        echo "-----------------------INFO2:netca begin-----------------------";date
                        netca
                        echo "-----------------------INFO2:netca end-----------------------";date
                    fi
                    echo "-----------------------INFO2:dbca begin-----------------------";date
                    ora_dbca
                    echo "-----------------------INFO2:dbca end-----------------------";date
                    echo "-----------------------INFO2:db basic optimize begin-----------------------";date
                    db_opti
                    db_arch
                    gather_hugepages_set_script 
                    echo "-----------------------INFO2:db basic optimize end-----------------------";date
                else
                    echo "-----------------------ERROR:Need set -C and -s together-----------------------"
                fi
            fi 
            ;;
        [yY])
            echo "-----------------------INFO3:deinstall begin----------------------";date
            deinstall_db_soft
            echo "-----------------------INFO3:deinstall end----------------------";date            
            ;;            
    esac
}
main $@ 2>&1

