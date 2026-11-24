# QMYSQL driver plugin (built against MariaDB Connector/C).
#
# Qt 6.8 does not ship qsqlmysql.dll in binary packages, and the terminal
# panel cannot talk to the remote MySQL DB without it. Sources are the
# unmodified qtbase v6.8.1 plugin files, built standalone.
#
# CI usage:
#   qmake mysql.pro "INCLUDEPATH+=C:/mariadb/include" "LIBS+=-LC:/mariadb/lib -llibmariadb"
#   nmake release
#
# Result: release/qsqlmysql.dll  -> dist/sqldrivers/qsqlmysql.dll
#         (libmariadb.dll goes next to IPS4MCO.exe)

TARGET   = qsqlmysql
TEMPLATE = lib
CONFIG  += plugin
QT       = core sql sql-private
DEFINES += QT_PLUGIN

HEADERS = qsql_mysql_p.h
SOURCES = qsql_mysql.cpp main.cpp
