# 定义函数以截取代码片段
get_code_snippet() {
    user_id=$1
    awk -v user_id="$user_id" '
    $0 ~ "# User " user_id " code" {flag=1; next}
    flag && $0 ~ /^$/ {flag=0}
    flag {print}
    ' "code.txt"
}

# 读取JSON文件并遍历用户
jq -c '.Users[]' test.json | while read -r user; do
    echo "Processing user: $user"  # 输出正在处理的用户信息
    user_id=$(echo "$user" | jq -r '.UserId' 2>/dev/null)
    if [ -z "$user_id" ]; then
        echo "Failed to extract User ID from: $user"
        continue
    fi
    echo "User ID: $user_id"  # 输出提取的用户ID
    new_code=$(get_code_snippet "$user_id")
    # 将字符串中的转义字符转换为实际换行符
    new_code=$(echo "$new_code")
    echo "New Code: $new_code"  # 输出截取到的代码片段
    
    # 更新JSON文件中的AbsFileDir字段
    jq --arg user_id "$user_id" --arg new_code "$new_code" '
    (.Users[] | select(.UserId == $user_id) | .AbsFileDir) |= $new_code
    ' test.json > tmp.$$.json && mv tmp.$$.json test.json
done

# 输出更新后的JSON文件内容
cat test.json
