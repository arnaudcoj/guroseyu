def bytecount(filename):
    try:
        fin = open(filename, 'rb')
        text = fin.read()
        fin.close()
    except IOError:
        print("File %s not found" % filename)
        raise SystemExit
    # all characters
    number_of_characters = len(text)
    # assumes lines end with 
    return number_of_characters

if __name__ == '__main__':
    import sys

    # there is a commandline
    if len(sys.argv) > 1:
        # sys.argv[0] is the program filename, slice it off
        for filename in sys.argv[1:]:
            bc = bytecount(filename)
            print("def NB_PB8_BLOCKS equ ((%u) + 7) / 8\n" % bc)
    else:
        print("usage pb8_size.py textfile1 [textfile2 ...]")