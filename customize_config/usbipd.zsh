#!/bin/zsh

# 列出所有串口设备
echo "Listing all serial devices..."
usbipd.exe list

# 提示用户输入设备ID
echo "Please enter the ID of the device you want to bind to WSL:"
read device_id

# 绑定设备
echo "Binding device ID $device_id to WSL..."
usbipd.exe bind -b $device_id
usbipd.exe attach --wsl -b $device_id

# 检查绑定是否成功
if [ $? -eq 0 ]; then
    echo "Device ID $device_id successfully bound to WSL."
else
    echo "Failed to bind device ID $device_id to WSL."
fi

