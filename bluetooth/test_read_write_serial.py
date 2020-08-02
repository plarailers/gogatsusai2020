#https://qiita.com/umi_mori/items/757834e0ef75f38cea19
#から
import serial

print("===== Start Program =====\n")

# Set Parameter
deviceName = '/dev/tty.Bluetooth-Incoming-Port'    # search by `ls -l /dev/tty.*`
baudrateNum = 9600
timeoutNum = 3
print("===== Set Parameter Complete =====\n")

# # Read Serial
readSer = serial.Serial(deviceName, baudrateNum, timeout=timeoutNum)
c = readSer.read()
string = readSer.read(10)
line = readSer.readline()
print("Read Serial:")
print(c)
print(string)
print(line)
readSer.close()
print("===== Read Serial Complete =====\n")

# Write Serial
serialCommand = "test"
writeSer = serial.Serial(deviceName, baudrateNum, timeout=timeoutNum)
writeSer.write(serialCommand.encode())
writeSer.close()
print("===== Write Serial Complete =====\n")

print("===== End Program =====\n")