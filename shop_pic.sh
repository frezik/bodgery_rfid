#!/bin/bash
source shop_pic_conf.sh

while true; do
    IS_OPEN=`curl http://${SERVER}/shop_open`
    
    if [ ${IS_OPEN} == 0 ]; do 
        echo "Sending pic . . . "
        raspistill -n -t 1 \
            -w ${WIDTH} -h ${HEIGHT} -q ${JPEG_QUALITY} \
            -o ${OUT_FILE}
        scp -i ${PRIVATE_KEY_FILE} \
            ${OUT_FILE} \
            ${SERVER_USERNAME}@${SERVER_HOST}:${SERVER_UPLOAD_PATH}
    done

    sleep ${SLEEP_TIME}
done
