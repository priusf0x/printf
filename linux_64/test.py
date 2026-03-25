import random
import string

specifiers = ["%b", "%c", "%d", "%o", "%x", "%s"]
args = []
constchar = []

maxim = 1000000

for i in range(maxim):
    print(i/ maxim)
    text = [random.choice(string.ascii_lowercase + string.digits) for i in range(10)]
    constchar.extend(text) 
    if (random.randint(0,1) == 1):
        spec = random.choice(specifiers)
        constchar.append(spec) 
        if (spec == "%s"):
            args.extend([',','"',])
            args.extend([random.choice(string.ascii_lowercase + string.digits) for i in range(10)])
            args.append('"')
        else:
            args.append(',')
            args.append(str(random.randint(-1000000, 1000000)))

final =  '"' + "".join(constchar) + '"' + "".join(args)

with open("test.h", "w") as f:
    print("my_pr1ntf(" + final + ");", file=f)

        
    
