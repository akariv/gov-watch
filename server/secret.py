#encoding: utf8
import sys
import md5

secret = file('secret').read()
chars='abcdefghijklmnopqrstuvwxyz0123456789_+ABCDEFGHIJKLMNOPQRSTUVWXYZ'
print(len(chars))
def calc_secret(what):
    return ''.join([ chars[(ord(x) & 0x3f)] for x in  md5.md5(secret+what.encode('utf8')).digest() ])

print calc_secret('gov')
print calc_secret(u'מושיקו')

if __name__ == "__main__":
    user = sys.argv[1].decode('utf8')
    print "%r"% user
    print calc_secret(user)

