# xref a number of python files (only functions)

import re, sys
from collections import defaultdict

DEF_RE = re.compile(r"\s*def\s+(\w+)\s*\(")
CALL_RE = re.compile(r"\b(\w+)\(")

repo = defaultdict(lambda:defaultdict(dict))

def get_defs(name):
    for i, line in enumerate(open(name)):
        m = DEF_RE.match(line)
        if m:
            repo[name][m.group(1)] = []

def get_calls(name):
    for i, line in enumerate(open(name)):
        if not DEF_RE.match(line):
            for m in CALL_RE.finditer(line):
                fun = m.group(1)
                for n, ns in repo.items():
                    if fun in ns:
                        ns[fun].append((name, i))

if __name__ == '__main__':
    internal = True
    compress = True
    
    for name in sys.argv[1:]:
        get_defs(name)
        
    for name in sys.argv[1:]:
        get_calls(name)
    
    for name, names in repo.items():
        print name
        print "-" * len(name)
        for name1, refs in sorted(names.items()):
            if internal or not all(n == name for n, i in refs):
                print "  %s" % name1
                if compress:
                    refs1 = []
                    for nn, i in sorted(refs):
                        if refs1 and refs1[-1][0] == nn:
                            refs1[-1][1].append(i)
                        else:
                            refs1.append((nn, [i]))
                    for nn, ii in refs1:
                        print "    %s %s" % (nn, ", ".join(str(i) for i in ii))
                else:
                    for ref in sorted(refs):
                        print "    %s:%i" % ref
        print