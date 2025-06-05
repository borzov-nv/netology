#!/bin/bash

PREFIX="$1"
INTERFACE="$2"
SUBNET="$3"
HOST="$4"

trap 'echo "Ping exit (Ctrl-C)"; exit 1' 2

# Функция для  отображения ошибки и выхода
error_exit() {
    echo "Error: $1"
    exit 1
}

# Функция для проверки октета
check_octet() {
    local octet_name="$1"
    local octet_value="$2"

    if ! [[ "$octet_value" =~ ^[0-9]+$ ]] || [ "$octet_value" -lt 0 ] || [ "$octet_value" -gt 255 ]; then
        error_exit "Invalid $octet_name format"
    fi
}

# Функция для сканирования сети
scan_network() {
    echo "[*] IP : $PREFIX.$SUBNET.$HOST"
    arping -c 3 -i "$INTERFACE" "$PREFIX.$SUBNET.$HOST" 2> /dev/null
}

# Проверка на рут
if [ "$(id -nu)" != "root" ]; then
    error_exit "Must be root to run $0"
fi

# Проверка обязательных аргументов
if [ -z "$PREFIX" ]; then
    error_exit "\$PREFIX must be passed as first positional argument"
fi
if [ -z "$INTERFACE" ]; then
    error_exit "\$INTERFACE must be passed as second positional argument"
fi

# Проверка формата префикса
if ! [[ "$PREFIX" =~ ^(25[0-5]|2[0-4][0-9]|[01]?[0-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|[01]?[0-9]?[0-9])$ ]]; then
    error_exit "Invalid PREFIX format"
fi

# Если не указана подсеть, сканировать всю сеть
if [ -z "$SUBNET" ]; then
    for SUBNET in {0..255}; do
        for HOST in {0..255}; do
            scan_network
        done
    done
else
    # Проверка формата подсети
    check_octet "SUBNET" "$SUBNET"
    # Если хост не указан, сканировать все хосты в указанной подсети
    if [ -z "$HOST" ]; then
        for HOST in {0..255}; do
            scan_network
        done
    # Если хост указан, сканировать указанный хост
    else
        # Проверка формата хоста
        check_octet "HOST" "$HOST"
        scan_network
    fi
fi
