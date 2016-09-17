#!/usr/bin/python

import os
import subprocess
import re
import sys
from subprocess import CalledProcessError, Popen, PIPE

import traceback

#-------helpers---------------

def starts_uint( s ):
    matches = re.findall('^\d+', s)
    if matches:
        return (int(matches[0]), len(matches[0]))
    else:
        return (0, 0)

def starts_int( s ):
    matches = re.findall('^-?\d+', s)
    if matches:
        return (int(matches[0]), len(matches[0]))
    else:
        return (0, 0)

def unsigned_reinterpret(x):
    if x < 0:
        return x + 2**64
    else:
        return x

def first_or_empty( s ):
    sp = s.split()
    if sp == [] : 
        return ''
    else:
        return sp[0]

#-----------------------------

def compile( fname, text ):
    f = open( fname + '.asm', 'w')
    f.write( text )
    f.close()

    if subprocess.call( ['nasm', '-f', 'elf64', fname + '.asm', '-o', fname+'.o'] ) == 0 and subprocess.call( ['ld', '-o' , fname, fname+'.o'] ) == 0:
             # print ' ', fname, ': compiled'
             return True
    else: 
        print ' ', fname, ': failed to compile'
        return False


def launch( fname, seed = '' ):
    output = ''
    try:
        p = Popen(['./'+fname], shell=None, stdin=PIPE, stdout=PIPE)
        (output, err) = p.communicate(input=seed)
        return (output, p.returncode)
    except CalledProcessError as exc:
        return (exc.output, exc.returncode)
    else:
        return (output, 0)



def test_asm( text, name = 'dummy',  seed = '' ):
    if compile( name, text ):
        r = launch( name, seed )
        #os.remove( name )
        #os.remove( name + '.o' )
        #os.remove( name + '.asm' )
        return r 
    return None 

class Test:
    name = ''
    string = lambda x: x
    checker = lambda input, output, code : False

    def __init__(self, name, stringctor, checker):
        self.checker = checker
        self.string = stringctor
        self.name = name
    def perform(self, arg):
        res = test_asm( self.string(arg), self.name, arg if not isinstance(arg, tuple) else arg[0] + '=' + arg[1])
        if res is None:
            return False
        (output, code) = res
        #print '"', repr(arg),'" ->', repr(output),'" ->',  code
        return (self.checker( arg, output, code ), arg, res)

tests=[ Test('string_length',
             lambda v : """section .data
        str: db '""" + v + """', 0
        section .text
        %include "lib.inc"
        global _start
        _start:
        mov rdi, str
        call string_length
        mov rdi, rax
        mov rax, 60
        syscall""",
        lambda i, o, r: r == len(i)
         ),

        Test('print_string',
             lambda v : """section .data
        str: db '""" + v + """', 0
        section .text
        %include "lib.inc"
        global _start 
        _start:
        mov rdi, str
        call print_string

        mov rax, 60
        xor rdi, rdi
        syscall""", 
        lambda i,o,r: i == o),

        Test('string_copy',
            lambda v: """section .data
        arg1: db '""" + v + """', 0
        arg2: times """ + str(len(v) + 1) +  """ db  66
        section .text
        %include "lib.inc"
        global _start 
        _start:
        mov rdi, arg1
        mov rsi, arg2
        call string_copy
        mov rdi, arg2 
        call print_string
        mov rax, 60
        xor rdi, rdi
        syscall""", 
        lambda i,o,r: i == o),

        Test('print_char',
            lambda v:""" section .text
        %include "lib.inc"
        global _start 
        _start:
        mov rdi, '""" + v + """'
        call print_char
        mov rax, 60
        xor rdi, rdi
        syscall""", 
        lambda i,o,r: i == o),

        Test('print_uint',
            lambda v: """section .text
        %include "lib.inc"
        global _start 
        _start:
        mov rdi, """ + v + """
        call print_uint
        mov rax, 60
        xor rdi, rdi
        syscall""", 
        lambda i, o, r: o == str(unsigned_reinterpret(int(i)))),
        
        Test('print_int',
            lambda v: """section .text
        %include "lib.inc"
        global _start 
        _start:
        mov rdi, """ + v + """
        call print_int
        mov rax, 60
        xor rdi, rdi
        syscall""", 
        lambda i, o, r: o == i),

        Test('read_char',
             lambda v:"""section .text
        %include "lib.inc"
        global _start 
        _start:
        call read_char
        mov rdi, rax
        mov rax, 60
        syscall""", 
        lambda i, o, r: (i == "" and r == 0 ) or ord( i[0] ) == r ),

        Test('read_word',
             lambda v:"""section .text
        %include "lib.inc"
        global _start 
        _start:
        call read_word
        mov rdi, rax
        call print_string

        mov rax, 60
        xor rdi, rdi
        syscall""", 
        lambda i, o, r: first_or_empty(i) == o),

        Test('read_word_length',
             lambda v:"""section .text
        %include "lib.inc"
        global _start 
        _start:
        call read_word

        mov rax, 60
        mov rdi, rdx
        syscall""", 
        lambda i, o, r: len(first_or_empty(i)) == r),

        Test('parse_uint',
             lambda v: """section .data
        input: db '""" + v  + """', 0
        section .text
        %include "lib.inc"
        global _start 
        _start:
        mov rdi, input
        call parse_uint
        push rdx
        mov rdi, rax
        call print_uint
        mov rax, 60
        pop rdi
        syscall""", 
        lambda i,o,r:  starts_uint(i)[0] == int(o) and r == starts_uint( i )[1]),
        
        Test('parse_int',
             lambda v: """section .data
        input: db '""" + v + """', 0
        section .text
        %include "lib.inc"
        global _start 
        _start:
        mov rdi, input
        call parse_int
        push rdx
        mov rdi, rax
        call print_int
        pop rdi
        mov rax, 60
        syscall""", 
        lambda i,o,r: (starts_int( i )[1] == 0 and int(o) == 0) or (starts_int(i)[0] == int(o) and r == starts_int( i )[1] )),

        Test('string_equals',
             lambda v: """section .data
             str1: db '""" + (v if not isinstance(v, tuple) else v[0]) + """',0
             str2: db '""" + (v if not isinstance(v, tuple) else v[1]) + """',0
        section .text
        %include "lib.inc"
        global _start
        _start:
        mov rdi, str1
        mov rsi, str2
        call string_equals
        mov rdi, rax
        mov rax, 60
        syscall""",
        lambda i,o,r: r == 1 if not isinstance(i, tuple) else (1 if i[0] == i[1] else 0) == r),

        Test('string_copy',
            lambda v: """section .data
        arg1: db '""" + v + """', 0
        arg2: times """ + str(len(v) + 1) +  """ db  66
        section .text
        %include "lib.inc"
        global _start 
        _start:
        mov rdi, arg1
        mov rsi, arg2
        call string_copy
        mov rdi, arg2 
        call print_string
        mov rax, 60
        xor rdi, rdi
        syscall""", 
        lambda i,o,r: i == o) 
]


inputs= {'string_length' 
        : [ 'asdkbasdka', 'qwe qweqe qe', '', '\t\t'],
         'print_string'  
         : ['ashdb asdhabs dahb', ' ', '', 'q'],
         'string_copy'   
         : ['ashdb asdhabs dahb', ' ', ''],
         'print_char'    
         : "a c",
         'print_uint'    
         : ['-1', '12345234121', '0', '12312312', '123123', '65535'],
         'print_int'     
         : ['-1', '-12345234121', '0', '123412312', '123123', '-34567', '-34567890987654'],
         'read_char'            
         : ['-1', '-1234asdasd5234121', '', '   ', '\t   ', 'hey ya ye ya', 'hello world', 'asdbaskdbaksvbaskvhbashvbasdasdads wewe'],
         'read_word'            
         : ['-1', '-1234asdasd5234121', '', '   ', '\t   ', 'hey ya ye ya', 'hello world', 'asdbaskdbaksvbaskvhbashvbasdasdads wewe', 'a'*254, '123\t123'],
         'read_word_length'     
         : ['-1', '-1234asdasd5234121', '', '   ', '\t   ', 'hey ya ye ya', 'hello world', 'asdbaskdbaksvbaskvhbashvbasdasdads wewe' '12\t123'],
         'parse_uint'           
         : ["0", "1234567890987654321hehehey", "1", "as" ],
         'parse_int'                
         : ["0", "1234567890987654321hehehey", "-1dasda", "-eedea", "-123123123", "1" ],
         'string_equals'            
         : [('ashdb asdhabs dahb', 'ashdb asdhabs dahb'), (' ', ' ') , ('', ''), ("asd", "asd"), ('123', '321'),
            ('ashdb asdhabs dahb', 'ashdbasdhabs dahb'), (' ', 'dfg') , ('', 'j'), ("asd", "asd"), ('123', '121'),
            ('a'*255, 'a'*255), ('a'*255, 'a'*254 + 'b') ]
}
              

if __name__ == "__main__":
    force = True if len(sys.argv) > 1 else False
    found_error = False
    test_count = 0
    success = 0
    for t in tests:
        for arg in inputs[t.name]:
            if not found_error or force:
                test_count += 1
                try:
                    res = t.perform(arg)
                    if res[0]: 
                        success += 1
                        print '  [  ok  ]',
                    else:
                        print '* [ fail ]',
                        found_error = True
                except:
                    traceback.print_exc()
                    print '* [ fail ] Exception in', 
                    found_error = True
                print ' testing', t.name,'on '+ repr(arg) +'','->',  res[2]
    if found_error:
        print 'Not all tests have been passed'
    else:
        print "Good work, all tests are passed"
    if force:
        print "( ", success, "/", test_count, ")"
