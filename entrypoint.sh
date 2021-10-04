#!/bin/bash
if [ "$RUN_AS_DATE" = "_" ]; then
/initialize.sh & /opt/mssql/bin/sqlservr
else

echo Starting SQL Server over dateoffset

/initialize.sh & LD_PRELOAD=/usr/lib/dateoffset/dateoffset.so \
tz_offset=$(date '+%::z') \
tz_signal=${tz_offset:0:1} \
tz_offset=${tz_offset:1} \
tz_offset_seconds=$tz_signal$(echo $tz_offset | awk -F: '{ print ($1 * 3600) + ($2 * 60) + $3 }') \
DATE_OFFSET=$(($(date -d "$RUN_AS_DATE" '+%s') + ($(date '+%s') % (24*60*60)) + $tz_offset_seconds)) \
/opt/mssql/bin/sqlservr

fi
