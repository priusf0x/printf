import random
import string

specifiers = ["%b", "%c", "%d", "%o", "%x"]
args = []
constchar = []

for i in range(100000):
    text = [random.choice(string.ascii_lowercase + string.digits) for i in range(10)]
    constchar = constchar + text 
    if (random.randint(0,1) == 1):
        spec = random.choice(specifiers)
        constchar = constchar + [spec] 
        if (spec == "%s"):
            args = args + [',']+ [random.choice(string.ascii_lowercase + string.digits) for i in range(10)]    
        else:
            args = args + [','] + [str(random.randint(-1000000, 1000000))]

final =  '"' + "".join(constchar) + '"' + "".join(args)

with open("test.h", "w") as f:
    print("my_pr1ntf(" + final + ");", file=f)

        
    
