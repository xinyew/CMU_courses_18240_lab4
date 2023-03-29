def main():
    with open('01.vm','r') as f:
        blocks = []
        i = 0
        while i < len(f.read):
            i, fs_error = wait1(f, i)
            block = getBlock(f, i)
            i += 13
            if f[i] != 0:
                fe_error = 1
            else:
                fe_error = 0


def wait1(f, i):
    j = i
    while f[j] != 1:
        j += 1
    return j + 1, j - i > 10

def getBlock(f, i):
    return f[i: i+13]


def secded(bytess):
    bytess = bytess[::-1]
    syn = 0
    syn += (calc1(bytess, [8,9,10,11,12])) << 3
    syn += (calc1(bytess, [4,5,6,7,12])) << 2
    syn += (calc1(bytess, [2,3,6,7,10,11])) << 1
    syn += (calc1(bytess, [1,5,9,3,7,11]))

    glo = calc1(bytess, range(13))

    is1bitErr = glo != 0 and syn != 0
    is2bitErr = glo == 0 and syn != 0

    corrected = bytess
    if is1bitErr:
        if bytess[syn] == '0':
            corrected = bytess[0:syn] + '1' + bytess[sync+1:13]

    return syn, is1bitErr, is2bitErr, corrected


def calc1(bytess, i):
    s = 0
    for ii in i:
        if bytess[ii] == '1':
            s += 1
    return int(s % 2 != 0)

print(secded('0110001011001'))