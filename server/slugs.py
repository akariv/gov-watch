def slugify(str1):
    str2 = ""
    if str1 == "":
        return ""
    for ch in str1:
        co = ord(ch)
        if co >= 0x5d0 and co < 0x600:
            co = co - 0x550
        if co < 256:
            str2 += "%02X" % co
    return str2

def unslugify(str1):
    str2 = u""
    if str1 == "":
        return u""
    str1 = str1.decode('hex')
    for ch in str1:
        co = ord(ch)
        if co >= 128:
            co += 0x550
        str2 = str2 + unichr(co)
    return str2
