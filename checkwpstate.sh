#!/bin/bash
#
# WAP Gateway Check Write statistics script 
#
# CBOSS Copyright 2005-2009
# Script should be started by WAP user("wap" by default), e.g. user which is responsible for processing WAP GW modules
#
# input parameters:
# $1 - WAPINSTBASE value
# $2 - time delay between 2 calls script

# Define variables
WAPUSER=`/bin/id | sed 's/uid=[0-9]*(\([^ )]*\)) gid=.*/\1/'`
#PROXYID=${1:-"1"}
WAPINSTBASE=${1:-"$HOME/wgateway"}
TIME_DELAY=${2:-"60"}
SRVID=`/usr/bin/hostname`

PROXYCONFIGIDS=`pushd $WAPINSTBASE/config >/dev/null; ls wapproxy*.cnf | cut -d "." -f 1 | cut -c 9- | sort -n; popd >/dev/null`

    
#PROXYPIDS=`ps -u $WAPUSER | grep "wapproxy" | awk '{ print $1 }'`


# for all WAP GW PID-�� wap gw
for PROXYID in $PROXYCONFIGIDS
do

#generate statistics filename
FILENAME=$WAPINSTBASE/wpstat/wpstat_${SRVID}_${PROXYID}_`date '+%Y%m%d'`.log
WP_NAMES="`$WAPINSTBASE/bin/wpcontrol -n$PROXYID -l`"
WP_OUTPUT="`$WAPINSTBASE/bin/wpcontrol -p -n$PROXYID`"
RESULT_LINE="`date '+%Y-%m-%d %H:%M:%S'` "$SRVID" "$PROXYID 

CHECKPROXY=`ps -u $WAPUSER -o args | grep "wapproxyd -r$PROXYID " | grep -v pwatch | grep -v grep`
    if [ -n "$CHECKPROXY" ];
    then
#        if [ "-r$PROXYID" = $CHECKPROXY ];

#        then

#  try to find out instanse mane 
       WPPID=`ps -u wap -o pid,args | grep "wapproxyd -r$PROXYID" | grep -v pwatch | grep -v grep | awk '{print $1}'`
       NAMES_COUNT=`echo "${WP_NAMES}" | grep -c "<"`

       if [ "$NAMES_COUNT" -eq 1 ];
       then
       INSTANSE_NAME=`echo "${WP_NAMES}" | grep "<" | cut -d "<" -f 2 | cut -d ">" -f 1`
       COMM_STAT=`$WAPINSTBASE/bin/wpcontrol -sc -n$PROXYID -i $INSTANSE_NAME`
       HTTP_REQ_CUR=`echo "$COMM_STAT" | grep "Total number of HTTP server requests" | cut -d "=" -f 2`

         STAT_FILE=$WAPINSTBASE/wpstat/ID_${PROXYID}_${INSTANSE_NAME}.stat

         # if file exit
         if [ -s $STAT_FILE ]
         then
         HTTP_REQ_OLD=`cat $STAT_FILE`
         fi
         # if value have been readed and it less than curent value
         if [[ -n "$HTTP_REQ_OLD" && $HTTP_REQ_OLD -lt $HTTP_REQ_CUR ]];
          then
          REAL_TPS=`expr $HTTP_REQ_CUR - $HTTP_REQ_OLD`
          REAL_TPS_1=`expr $REAL_TPS \/ $TIME_DELAY`
          REAL_TPS_2=`expr $REAL_TPS \% $TIME_DELAY`
          REAL_TPS=${REAL_TPS_1}.${REAL_TPS_2}

          else 
          #  if value more that current, so WAP GW has been restarted. ����饥 ���祭�� ��襬 � 䠩�, � ॠ��� TPS ����塞
          REAL_TPS=0.0
         fi

         # write current value to file
         echo $HTTP_REQ_CUR  > ${STAT_FILE}

       elif [ "$NAMES_COUNT" -eq 2 ]
       then
        INSTANSE_NAME_CO=`echo "${WP_NAMES}" | grep "<" | head -n 1 | cut -d "<" -f 2 | cut -d ">" -f 1`
        INSTANSE_NAME_CL=`echo "${WP_NAMES}" | grep "<" | tail -1 | cut -d "<" -f 2 | cut -d ">" -f 1`
        COMM_STAT_CO=`$WAPINSTBASE/bin/wpcontrol -sc -n$PROXYID -i $INSTANSE_NAME_CO`
        WAP_CO_REQ_CUR=`echo "$COMM_STAT_CO" | grep "Total number of WAP requests" | awk '{print $7}'`
        COMM_STAT_CL=`$WAPINSTBASE/bin/wpcontrol -sc -n$PROXYID -i $INSTANSE_NAME_CL`
        WAP_CL_REQ_CUR=`echo "$COMM_STAT_CL" | grep "Total number of WAP requests" | awk '{print $7}'`
       # name names

         STAT_FILE_CO=$WAPINSTBASE/wpstat/ID_${PROXYID}_${INSTANSE_NAME_CO}.stat
         STAT_FILE_CL=$WAPINSTBASE/wpstat/ID_${PROXYID}_${INSTANSE_NAME_CL}.stat 

        if [[ -s $STAT_FILE_CO && -s $STAT_FILE_CL ]]
        then 
        WAP_CO_REQ_OLD=`cat $STAT_FILE_CO`
        WAP_CL_REQ_OLD=`cat $STAT_FILE_CL`
        else
        echo $STAT_FILE_CO and $STAT_FILE_CL files don\'t exist.
        fi

        if [[ -n "$WAP_CO_REQ_OLD" &&  $WAP_CO_REQ_OLD -lt $WAP_CO_REQ_CUR ]]
        then 
        WAP_CO_REQ=`expr $WAP_CO_REQ_CUR - $WAP_CO_REQ_OLD`
        else 
        WAP_CO_REQ=0
        fi

        if [[ -n "$WAP_CL_REQ_OLD" &&  $WAP_CL_REQ_OLD -lt $WAP_CL_REQ_CUR ]]
        then 
        WAP_CL_REQ=`expr $WAP_CL_REQ_CUR - $WAP_CL_REQ_OLD`
        else 
        WAP_CL_REQ=0
        fi

        REAL_TPS=`expr $WAP_CL_REQ + $WAP_CO_REQ`
        REAL_TPS_1=`expr $REAL_TPS \/ $TIME_DELAY`
        REAL_TPS_2=`expr $REAL_TPS \% $TIME_DELAY`
        REAL_TPS=${REAL_TPS_1}.${REAL_TPS_2}

        echo $WAP_CO_REQ_CUR > ${STAT_FILE_CO}
        echo $WAP_CL_REQ_CUR > ${STAT_FILE_CL}


       fi

             PRSTAT_OUT=`prstat -p $WPPID 1 1 | grep "wapproxyd" | awk '{ print $1" "$9" "$3" "$4}'`
             PROXY_START=`echo "${WP_OUTPUT}" | grep "Proxy server start-up time" | cut -d " " -f 9,10`
       ACTIVE_PROXY_CONN=`echo "${WP_OUTPUT}" | grep "Active proxy" | cut -d "=" -f 2`
       ACTIVE_PROXY_CONN=${ACTIVE_PROXY_CONN//" "/""} 
       WEB_REQUESTS_COUNT=`echo "${WP_OUTPUT}" | grep "Pending proxy server web-requests" | cut -d "=" -f 2`
       WEB_REQUESTS_COUNT=${WEB_REQUESTS_COUNT//" "/""} 

            # some actions here ...
       RESULT_LINE="${RESULT_LINE} ${PRSTAT_OUT} ${PROXY_START} ${ACTIVE_PROXY_CONN} ${WEB_REQUESTS_COUNT} ${REAL_TPS}"


#            echo $RESULT_LINE >> ${FILENAME}
#            exit 0
#        fi
    else

     FILENAME=$WAPINSTBASE/wpstat/wpstopstat_${SRVID}_${PROXYID}_`date '+%Y%m%d'`.log

    fi

echo $RESULT_LINE >> ${FILENAME}
done
exit 1