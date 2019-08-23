#!/bin/sh
#添加lib的环境变量
export LD_LIBRARY_PATH=/lib
#sysctl 
ulimit -s 256


#从/mnt/jffs2/hwontlog.bin读取log到内存中
Reloadlog

# Get kernel version, for user to load difference KOs.
ker_ver=$(cat /proc/version | cut -c15-20)
echo "Get kernel version:$ker_ver"

[ -f /mnt/jffs2/stop ] && exit

HW_LANMAC_TEMP="/var/hw_lanmac_temp"

HW_BOARD_LANMAC="00:00:00:00:00:02"

echo -n "Rootfs time stamp:"
cat /etc/timestamp

echo -n "SVN label(ont):"
cat /etc/wap/ont_svn_info.txt

#echo 100 > /proc/sys/vm/pagecache_ratio
#echo 3 > /proc/sys/vm/drop_caches
echo 64 > /proc/sys/kernel/msgmni
echo 2048 > /proc/sys/net/ipv4/route/max_size

#避免eth0发RS
[ -f /proc/sys/net/ipv6/conf/default/forwarding ] && echo 1 > /proc/sys/net/ipv6/conf/default/forwarding

# Close/Open(0/8) the printk for debug
echo 8 > /proc/sys/kernel/printk

[ -f /mnt/jffs2/Equip.sh ] && /bin/Equip.sh && exit

# calc used start
#CalcUsedMem "system" "ont"
# calc used end

cd /

echo "User init start......"

var_xpon_mode=`cat /mnt/jffs2/hw_boardinfo | grep "0x00000001" | cut -c38-38`

# load hisi modules
if [ -f /mnt/jffs2/TranStar/hi_sysctl.ko ]; then
	  cd /mnt/jffs2/TranStar/
          echo "Loading the Temp SD5115V100 modules: "
else
	  cd /lib/modules/hisi_sdk
	  echo "Loading the SD5115V100 modules: "
fi
		
    insmod hi_sysctl.ko	
    insmod hi_pie.ko tx_chk=0
    insmod hi_gpio_5115.ko
    insmod hi_gpio.ko
    insmod hi_i2c.ko
    insmod hi_timer.ko	
    insmod hi_spi.ko
if [ -e /mnt/jffs2/PhyPatch ]; then
    echo "phy patch path is /mnt/jffs2/PhyPatch/ "
    insmod hi_bridge_5115.ko pPhyPatchPath="/mnt/jffs2/PhyPatch/"
    insmod hi_bridge.ko  pPhyPatchPath="/mnt/jffs2/PhyPatch/"
else
    insmod hi_bridge_5115.ko
    insmod hi_bridge.ko
fi 
    insmod hi_gpon.ko
    insmod hi_epon.ko
    insmod hi_oam.ko
    insmod hi_adp_cnt.ko

cd /

# calc used start
#CalcUsedMem "sdk" "ont"
# calc used end

# set lanmac 
getlanmac $HW_LANMAC_TEMP
if [ 0  -eq  $? ]; then
    read HW_BOARD_LANMAC < $HW_LANMAC_TEMP
    echo "ifconfig eth0 hw ether $HW_BOARD_LANMAC"
    ifconfig eth0 hw ether $HW_BOARD_LANMAC
fi

# delete temp lanmac file
if [ -f $HW_LANMAC_TEMP ]; then
    rm -f $HW_LANMAC_TEMP
fi

# activate ethernet drivers
ifconfig eth0 192.168.100.1 up
ifconfig eth0 mtu 1500

# calc used start
#CalcUsedMem "system" "config"
# calc used end

mkdir /var/tmp

echo "Loading the EchoLife WAP modules: LDSP"

# hw_module_common.ko hw_module_hlp.ko are needed by all of ko
insmod /lib/modules/wap/hw_module_common.ko
insmod /lib/modules/wap/hw_module_i2c.ko
insmod /lib/modules/wap/hw_module_gpio.ko
insmod /lib/modules/wap/hw_soc_sd5115_basic.ko
insmod /lib/modules/wap/hw_module_lsw_l2.ko
insmod /lib/modules/wap/hw_module_dev.ko

# calc used start
#CalcUsedMem "ldsp" "basic"
# calc used end

#判断/mnt/jffs2/customize_xml.tar.gz文件是否存在，存在解压
if [ -e /mnt/jffs2/customize_xml.tar.gz ]
then
    #解析customize_relation.cfg
    tar -xzf /mnt/jffs2/customize_xml.tar.gz -C /mnt/jffs2/ customize_xml/customize_relation.cfg  
fi

#dm产品侧ko,需在hw_module_dev.ko加载后加载
insmod /lib/modules/wap/hw_dm_pdt.ko
insmod /lib/modules/wap/hw_module_feature.ko
. /usr/bin/init_topo_info.sh
echo "pots_num="$pots_num
echo "ssid_num="$ssid_num
echo " usb_num="$usb_num
echo "hw_route="$hw_route
echo "   l3_ex="$l3_ex
echo "    ipv6="$ipv6
rm /var/topo.sh

# calc used start
#CalcUsedMem "ssmp" "feature"
# calc used end

insmod /lib/modules/wap/hw_module_optic.ko
insmod /lib/modules/wap/hw_module_key.ko
insmod /lib/modules/wap/hw_module_led.ko
insmod /lib/modules/wap/hw_module_rf.ko

# calc used start
#CalcUsedMem "ldsp" "extern"
# calc used end

# AMP_KO
insmod /lib/modules/wap/hw_amp.ko
#
# calc used start
#CalcUsedMem "amp" "ko"
# calc used end

# BBSP_l2_basic
echo "Loading BBSP L2 modules: "
insmod /lib/modules/wap/commondata.ko
insmod /lib/modules/wap/sfwd.ko
insmod /lib/modules/wap/l2ffwd.ko
insmod /lib/modules/wap/hw_bbsp_lswadp.ko
insmod /lib/modules/wap/hw_ptp.ko
insmod /lib/modules/wap/l2base.ko
insmod /lib/modules/wap/acl.ko
insmod /lib/modules/wap/cpu.ko
insmod /lib/modules/wap/l2m_adpt.ko
insmod /lib/modules/wap/qos_adpt.ko

# BBSP_l2_basic end

# calc used start
#CalcUsedMem "bbsp" "basic"
# calc used end

echo "xpon_mode:${var_xpon_mode}"
if [ ${var_xpon_mode} == "1" ]; then
    insmod /lib/modules/wap/hw_module_ploam.ko
    insmod /lib/modules/wap/hw_module_gmac.ko		
elif [ ${var_xpon_mode} == "2" ]; then
    insmod /lib/modules/wap/hw_module_emac.ko
    insmod /lib/modules/wap/hw_module_mpcp.ko	
else
    insmod /lib/modules/wap/hw_module_ploam.ko
    insmod /lib/modules/wap/hw_module_gmac.ko
    insmod /lib/modules/wap/hw_module_emac.ko
    insmod /lib/modules/wap/hw_module_mpcp.ko		
fi	

# BBSP_l2_extended
#echo "Loading BBSP L2_extended modules: "
insmod /lib/modules/wap/l2ext.ko
insmod /lib/modules/wap/ethoam_adpt.ko
insmod /lib/modules/wap/video_diag_adpt.ko
# BBSP_l2_extended end
# calc used start
#CalcUsedMem "ldsp" "extern"
# calc used end

echo =======memory used: system:$asystem ssmp:$assmp amp:$aamp bbsp:$abbsp ldsp:$aldsp sdk:$asdk======
echo =======memory used: system:$asystem ssmp:$assmp amp:$aamp bbsp:$abbsp ldsp:$aldsp sdk:$asdk====== >>/var/memory_used

#add by zhaochao for ldsp_user
iLoop=0
echo -n "Start ldsp_user..."
if [ -e /bin/hw_ldsp_cfg ]
then
  hw_ldsp_cfg &
  while [ $iLoop -lt 5 ] && [ ! -e /var/hw_ldsp_tmp.txt ] 
  do
    echo $iLoop
    iLoop=$(( $iLoop + 1 ))
    sleep 1
  done
  
  if [ -e /var/hw_ldsp_tmp.txt ]
  then 
      rm -rf /var/hw_ldsp_tmp.txt
  fi
fi

if [ -e /bin/hw_ldsp_xpon_adpt ]
then
    hw_ldsp_xpon_adpt &
fi
#end by zhaochao for ldsp_user

iLoop=0
if [ -e /bin/hw_ldsp_cfg ]
then
  while [ $iLoop -lt 10 ] && [ ! -e /var/epon_up_mode.txt ] && [ ! -e /var/gpon_up_mode.txt ] 
  do
    echo $iLoop
    iLoop=$(( $iLoop + 1 ))
    sleep 1
  done
fi

if [ -e /bin/ethoam ]
then
    var_proc_name="ssmp bbsp igmp amp ethoam"
else
    var_proc_name="ssmp bbsp igmp amp"
fi

if [ -e /var/gpon_up_mode.txt ]
then
    var_proc_name=$var_proc_name" omci"
fi

if [ -e /var/epon_up_mode.txt ]
then
    var_proc_name=$var_proc_name" oam"
fi

echo $var_proc_name

start $var_proc_name&

#echo -n "Start SSMP..."
ssmp &

#echo -n "Start BBSP..."
bbsp &

#echo -n "Start AMP..."
amp &

if [ -e /var/gpon_up_mode.txt ]
then
    #echo -n "Start OMCI..."
    omci &
fi 

if [ -e /var/epon_up_mode.txt ]
then
    #echo -n "Start OAM..."
    oam &
fi

#echo -n "Start IGMP..."
igmp &

#echo -n "Start ethoam..."
if [ -e /bin/ethoam ]
then
    ethoam &
fi

#echo -n "Launch dropbear ssh server"
/bin/start_dropbear.sh &

#echo -n "Activate CATV output"
/bin/start_CATV.sh &

#echo -n "Launch user custom scripts"
if [ -e /mnt/jffs2/startup.sh ]
then
    /mnt/jffs2/startup.sh &
fi

#echo -n "Start ProcMonitor..."
while true; do 
    sleep 1
    # 如果ssmploadconfig文件存在，表示消息服务启动成功，可以启动PM进程了
    if [ -f /var/ssmploadconfig ]; then
    	echo "Start ProcMonitor without vspa ..."
        procmonitor ssmp amp & break
    fi
done &


# After system up, drop the page cache.
while true; do sleep 30 ; echo 3 > /proc/sys/vm/drop_caches ; echo "Dropped the page cache."; break; done &


while true; do sleep 40 ; mu& break; done &

while true; do
    sleep 2
    if [ -f /var/ssmploaddata ] ; then
        web & break; 
    fi
done &



