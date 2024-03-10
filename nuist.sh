#!/bin/bash

USER_PASSWORD_POOL=(
  "username:password"
  "username:password"
  # Add more username:password pairs as needed
)

function demo() {
  tar=10.255.255.46
  code=$(curl -I --connect-timeout 5 $tar -w %{http_code} | tail -n1)

  if [ "$code" = 200 ]; then
    for n in $@; do
     # 如果是wan接口，跳过
      if [ "$n" = "wan" ]; then
        continue
      fi
      login_attempt=0
      while [ $login_attempt -lt 10 ]; do
      # 获取用户名密码池中的下一个元素
      user_pass=${USER_PASSWORD_POOL[$index]}
      index=$((index + 1))

      # 解析用户名和密码
      username=$(echo $user_pass | cut -d':' -f1)
      password=$(echo $user_pass | cut -d':' -f2)
      channel=2

      HOST=$(ifconfig $n | grep "inet addr" | awk '{ print $2}' | awk -F: '{print $2}')
      echo $HOST
      # 使用获取的用户名和密码进行登录
      response=$(curl -s -w "%{http_code}" 'http://10.255.255.46/api/v1/login' -H 'Accept: application/json, text/plain, */*' -H 'Accept-Language: zh-CN,zh;q=0.9,zh-US;q=0.8' -H 'Access-Control-Allow-Origin: *' -H 'Connection: keep-alive' -H 'Content-Type: application/json;charset=UTF-8' -H 'DNT: 1' -H 'Origin: http://10.255.255.46' -H 'Referer: http://10.255.255.46/?LanmanUserURL=$USERURL' -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36' --data-raw '{"username":"'$username'","password":"'$password'","ifautologin":"1","channel":"'$channel'","pagesign":"secondauth","usripadd":"'${HOST}'"}')
      
      if echo "$response" | grep -q '"code": 200'; then
        break  # 登录成功，退出循环
      else
        echo "Login failed for $username:$password on $n. Retrying..."
        login_attempt=$((login_attempt + 1))
      fi
      sleep 2
      done
    done
  else
    echo "failed"
    sleep 5
    ifdown wan
    for i in $(seq 1 $(ifconfig | grep -o "macvwan[0-9]*" | wc -l)); do
      ifdown vwan$i
    done
    sleep 2
    ifup wan
    for a in $(seq 1 $(ifconfig | grep -o "macvwan[0-9]*" | wc -l)); do
      ifup vwan$a
    done
    sleep 10

    demo wan $(ifconfig | grep -o "macvlan[0-9]*")
  fi
}

# 初始索引为0
index=0

# 初始调用
demo wan $(ifconfig | grep -o "macvlan[0-9]*")
