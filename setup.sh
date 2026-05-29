#!/bin/bash

set -euo pipefail

declare -A PRODUCTS=(
    [ak620]="0x0002"
    [ak500s]="0x0004"
)

INSTALL_DIR="/opt/deepcool-ak-series-digital"
SERVICE_DIR="/etc/systemd/system"
SCRIPT_NAME="deepcool-ak-series-digital.py"

usage() {
    echo "usage: ./setup.sh <model> <sensor> [-dt | --disable-temp] [-du | --disable-utils]"
    echo -e "\tmodel:\t\t\tone of: ${!PRODUCTS[*]}"
    echo -e "\tsensor:\t\t\tpsutil temperature sensor name, for example coretemp"
    echo -e "\t-dt, --disable-temp:\tdisable sensor temperature display"
    echo -e "\t-du, --disable-utils:\tdisable CPU utilization display"
}

if [[ $# -lt 2 ]]; then
    echo "Please provide valid product and hardware sensor names."
    usage
    exit 1
fi

PRODUCT="$1"
SENSOR="$2"
SHOW_TEMP="True"
SHOW_UTIL="True"
shift 2

if [[ -z "${PRODUCTS[$PRODUCT]+x}" ]]; then
    echo "Unsupported model: $PRODUCT"
    usage
    exit 1
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        -dt|--disable-temp)
            SHOW_TEMP="False"
            ;;
        -du|--disable-utils)
            SHOW_UTIL="False"
            ;;
        *)
            echo "Invalid optional argument: $1"
            usage
            exit 1
            ;;
    esac
    shift
done

if [[ ! -f "requirements.txt" || ! -f "$SCRIPT_NAME" ]]; then
    echo "Run setup.sh from the project directory."
    exit 1
fi

sudo install -d "$INSTALL_DIR"
sudo install -m 0644 "$SCRIPT_NAME" "$INSTALL_DIR/$SCRIPT_NAME"
sudo install -m 0644 requirements.txt "$INSTALL_DIR/requirements.txt"

sudo sed -i \
    -e "s/^PRODUCT_ID = .*/PRODUCT_ID = ${PRODUCTS[$PRODUCT]}/" \
    -e "s/^SENSOR = .*/SENSOR = \"$SENSOR\"/" \
    -e "s/^SHOW_TEMP = .*/SHOW_TEMP = $SHOW_TEMP/" \
    -e "s/^SHOW_UTIL = .*/SHOW_UTIL = $SHOW_UTIL/" \
    "$INSTALL_DIR/$SCRIPT_NAME"

sudo python3 -m venv "$INSTALL_DIR/venv"
sudo "$INSTALL_DIR/venv/bin/python" -m pip install --upgrade pip
sudo "$INSTALL_DIR/venv/bin/python" -m pip install -r "$INSTALL_DIR/requirements.txt"

sudo install -m 0644 deepcool-ak-series-digital.service "$SERVICE_DIR/deepcool-ak-series-digital.service"
sudo install -m 0644 deepcool-ak-series-digital-restart.service "$SERVICE_DIR/deepcool-ak-series-digital-restart.service"

sudo systemctl daemon-reload
sudo systemctl enable deepcool-ak-series-digital.service
sudo systemctl enable deepcool-ak-series-digital-restart.service
sudo systemctl restart deepcool-ak-series-digital.service
