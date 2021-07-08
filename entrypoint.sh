#!/bin/bash
if [ "$RUN_AS_DATE" = "_" ]; then
/initialize.sh & /opt/mssql/bin/sqlservr
else

echo Starting SQL Server over dateoffset

/initialize.sh & LD_PRELOAD=/usr/lib/dateoffset/dateoffset.so \
DATE_OFFSET=$(($(date -d "$RUN_AS_DATE" '+%s') + ($(date '+%s') % (24*60*60)))) \
/opt/mssql/bin/sqlservr

fi
