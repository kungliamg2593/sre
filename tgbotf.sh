TAG_NAME=$(echo "${Tags}" | awk -F'/' '{print $NF}')
curl -X POST "https://api.telegram.org/bot7194383189:AAEpSgHrOvALwf5BdM5er-a3resHrc8zqGc/sendMessage" -d "chat_id=-4211449241&text=${env}站${TAG_NAME}分支#${BUILD_ID}：FAILURE"
