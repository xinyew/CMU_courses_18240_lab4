with open('./lab5_task1.vm', 'r') as f:
    string = f.read()
    for i in range(len(string)//16):
        print('----------' + str(i) + '--------')
        print(string[i*16:i*16+16])
