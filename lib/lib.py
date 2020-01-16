import sys, os, re, string, pathlib, inspect

if __name__ == "__main__":
    sys.exit(1)
    
parent_module = None
for s in inspect.stack()[1:]:
    m = inspect.getmodule(s[0])
    if m and m.__name__ == "__main__":
        parent_module = m
        break

if parent_module != None and parent_module.__name__ == "__main__":
    if len(sys.argv) < 2:
        print('Error: output filename should be specified.', file=sys.stderr)
        sys.exit(1)

    SCRIPT_NAME = parent_module.__file__   # ./python/script.py
    SCRIPT_BASE = os.path.splitext(SCRIPT_NAME)[0]     # ./python/script
    SCRIPT_DIR = os.path.dirname(SCRIPT_NAME)
    OUTPUT = sys.argv[1]        # ./python/script_image.png
    BASENAME = os.path.splitext(OUTPUT)[0]  # ./python/script_image
    FILENAME = os.path.basename(BASENAME)   # script_image
    FACTOR = ""
    if os.path.abspath(BASENAME).startswith(os.path.abspath(SCRIPT_BASE) + "_"):
        FACTOR = os.path.abspath(BASENAME)[len(os.path.abspath(SCRIPT_BASE)) + 1:]  # image
    SUFFIX = os.path.splitext(OUTPUT)[1][1:]    # png
    
    def __compare_path(p1, p2):
        if "%" in p2:
            p2s = p2.split("%")
            if len(p2s) != 2:
                print('Error: character "%" cannot used more than once.', file=sys.stderr)
                sys.exit(1)
            if p1.startswith(p2s[0]) and p1.endswith(p2s[1]):
                return True, p1[len(p2s[0]):-len(p2s[1])]
            else:
                return False, ""
        else:
            return p1 == p2, ""
    
    def __get_imported_modules(file):
        ret = []
        includeRe = re.compile("^[ \t]*import[ \t]*")
        moduleAsRe = re.compile("^([A-Za-z0-9_]+)[ \t]+as[ \t]+[A-Za-z0-9_]+$")
        moduleRe = re.compile("^[A-Za-z0-9_]+$")
        
        with open(file) as inf:
            for x in inf.readlines():
                m = includeRe.search(x)
                if m != None:
                    for arg in x[m.regs[0][1]:-1].split(","):
                        arg = arg.strip()
                        m = moduleRe.search(arg)
                        if m != None:
                            ret.append(arg)
                        else:
                            m = moduleAsRe.search(arg)
                            if m != None:
                                ret.append(m.group(1))
        return ret
                                
    def __get_imported(file):
        ret = []
        for m in __get_imported_modules(file):
            if os.path.exists(SCRIPT_DIR + "/" + m + ".py"):
                ret.append(m + ".py")
        return ret
                                
    def depends(out, a):
        compared, PERCENT_STR = __compare_path(os.path.abspath(BASENAME), os.path.abspath(SCRIPT_DIR + "/" + os.path.splitext(out)[0]))
        if SUFFIX == "d" and compared:
            a += __get_imported(SCRIPT_NAME)
            rel_out = BASENAME + os.path.splitext(out)[1]
            id_out = os.path.splitext(rel_out)[0].replace("/", "_DS_")
            with open(OUTPUT, mode='w') as fd:
                for f in a:
                    if f.startswith("."):
                        f = os.path.basename(SCRIPT_BASE) + f
                    f.replace("%", PERCENT_STR)
                    rel_f = SCRIPT_DIR + "/" + f
                    id_f = os.path.splitext(rel_f)[0].replace("/", "_DS_")
                    f_dep = os.path.splitext(f)[0] + ".d"
                    fd.write("ifeq (,$(filter %s,$(MAKEFILE_LIST)))\n-include %s\nendif\n" % (f_dep, f_dep))
                    fd.write("DEPS_%s:=$(DEPS_%s) %s $(DEPS_%s)\n" % (id_out, id_out, rel_f, id_f))
                    fd.write("REFS_%s:=$(REFS_%s) %s\n" % (id_f, id_f, rel_out))
                    fd.write("%s:\t$(DEPS_%s)\n" % (rel_out, id_out))
            sys.exit(0)
    
