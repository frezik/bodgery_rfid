#!/bin/bash
source shop_pic_conf.sh

PREV_OPEN_STATUS=0

while true; do
    IS_OPEN=`curl -k https://${SERVER}/shop_open`
    echo "Shop open status: ${IS_OPEN}"
    
    if [ "${IS_OPEN}" -eq 1 ]
    then
        echo "Taking pic . . . "
        raspistill -n -t 1 \
            -w ${WIDTH} -h ${HEIGHT} -q ${JPEG_QUALITY} \
            -o ${OUT_FILE}
        echo "Sending pic . . . "
        scp -i ${PRIVATE_KEY_FILE} \
            ${OUT_FILE} \
            ${SERVER_USERNAME}@${SERVER_HOST}:${SERVER_UPLOAD_PATH}
    else
        if [ "${PREV_OPEN_STATUS}" -eq 1 ]
        then
            echo "Sending default pic . . ."
            scp -i ${PRIVATE_KEY_FILE} \
                ${DEFAULT_PIC} \
                ${SERVER_USERNAME}@${SERVER_HOST}:${SERVER_UPLOAD_PATH}
        else
            echo "Doing nothing . . ."
        fi
    fi

    PREV_OPEN_STATUS=${IS_OPEN}
    sleep ${SLEEP_TIME}
done
