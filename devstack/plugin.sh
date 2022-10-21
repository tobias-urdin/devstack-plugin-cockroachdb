#!/bin/bash

# Copyright 2022 Binero
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

# Save trace setting
XTRACE=$(set +o | grep xtrace)
set +o xtrace

register_database cockroachdb

function _download_cockroachdb {
    if [ ! -f ${FILES}/cockroachdb_${COCKROACHDB_VERSION}.tgz ]; then
        wget ${COCKROACHDB_URL} -O ${FILES}/cockroachdb_${COCKROACHDB_VERSION}.tgz
    fi
}

function _install_cockroachdb {
    if [ ! -d ${FILES}/${COCKROACHDB_FILE} ]; then
        tar -xvzf ${FILES}/cockroachdb_${COCKROACHDB_VERSION}.tgz -C ${FILES}
    fi

    if [ ! -d ${COCKROACHDB_DEST}/cockroachdb ]; then
        mkdir -p ${COCKROACHDB_DEST}
        mv ${FILES}/${COCKROACHDB_FILE} ${COCKROACHDB_DEST}/cockroachdb
    fi

    if [ ! -f /etc/systemd/system/cockroachdb.service ]; then
    cat <<EOF | sudo tee /etc/systemd/system/cockroachdb.service >/dev/null
[Unit]
Description=CockroachDB

[Service]
ExecStart=${COCKROACHDB_DEST}/cockroachdb/cockroach start-single-node --insecure
User=$(whoami)
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
        sudo systemctl daemon-reload
    fi
}

function get_database_type_cockroachdb {
    echo cockroachdb
}

function cleanup_database_cockroachdb {
    stop_service cockroachdb
    rm ${FILES}/${COCKROACHDB_FILE}.tgz
    rm -rf ${COCKROACHDB_DEST}/cockroachdb
    sudo rm -f /etc/systemd/system/cockroachdb.service
    sudo systemctl daemon-reload
}

function recreate_database_cockroachdb {
    local db=$1
    ${COCKROACHDB_DEST}/cockroachdb/cockroach sql --insecure -e "DROP DATABASE IF EXISTS ${db};"
    ${COCKROACHDB_DEST}/cockroachdb/cockroach sql --insecure -e "CREATE DATABASE ${db};"
}

function configure_database_cockroachdb {
    echo_summary "Configuring and starting CockroachDB"
    start_service cockroachdb
}

function install_database_cockroachdb {
    echo_summary "Installing CockroachDB"
    _download_cockroachdb
    _install_cockroachdb
}

function install_database_python_cockroachdb {
    pip_install_gr psycopg2
    pip_install_gr sqlalchemy-cockroachdb
    ADDITIONAL_VENV_PACKAGES+=",psycopg2,sqlalchemy-cockroachdb"
}

function database_connection_url_cockroachdb {
    local db=$1
    echo "cockroachdb+psycopg2://root@127.0.0.1:26257/${db}?sslmode=disable"
}

# Restore xtrace
$XTRACE
