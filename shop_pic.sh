#!/bin/bash
source shop_pic_conf.sh


echo "Taking pic . . . "
raspistill -n -t 1 \
    -w ${WIDTH} -h ${HEIGHT} -q ${JPEG_QUALITY} \
    -o ${OUT_FILE}
echo "Sending pic . . . "
scp -i ${PRIVATE_KEY_FILE} \
    ${OUT_FILE} \
    ${SERVER_USERNAME}@${SERVER_HOST}:${SERVER_UPLOAD_PATH}
