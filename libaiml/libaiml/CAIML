File Format
===========

[ Intro ]
  CAIML is intended to be used as a caching feature: you parse all your .aiml
files once, then save the status of the graphmaster to a file. If you later
need to use the same aiml files, you can just use the saved CAIML file (which
is much faster).
  The CAIML file is NOT intended to be saved by the library in one platform
and then read back in another. This is because the types used to store the
data in the CAIML have sizes determined by the current architecture/compiler.
  This file format optimizes the constructions of the graphmaster.
  The templates are stored in a special binary format (when constructing the grapmhaster)
and then executed at runtime. Thus, the binary content of the templates isn't
described here (but should be taken merely as a chunk of binary data).
  The description of the file format is something like binary EBNF.
  Also, when this syntax is used:
    <n : number>
  it means that that field has the name "n", and it is of type "number" (this
  allows referring to the field's value.
  
[ Structure ]

  Basic types:
    <number>  : size_t (defined generally as unsigned long on most platforms)
    <byte>    : char (one byte, 8 bits in most 32bit platforms)
    <zero>    : a <number> with value 0
  
    A string is saved as a number (size), indicating the length of the string, and
    'size' bytes conforming the string itself:
    <string> ::= <size : number> <byte>{size}
    
    A similar one is the "node" field, but with restricted characters: [A-Z0-9]
    
    NOTE: both "string" and "node" never contain a '\0' (null terminator)
  
  Elements:
    <header> ::= "CAIML" <version : number>
    
    <data> ::= <teamplates_num : number> <same_childs : number> <zero> <child-list>
               
    <child-list> ::= <node> <#same_childs : number> <#diff_childs : number>
      <same-childs-list : child-list>{#same_childs} <diff-child-list : child-list>{#diff_childs}
                     
    <file> ::= <header> <data>
  
  
[ Semantic ]
  The EBNF structure can't describe fully the structure of a CAIML file, but
it helps to get an idea.

  A graphmaster can be thought as a rosetree (rosetree := nil | node and list
of rosetree) that has 3 possible types of nodes ("pattern", "that" and "topic"
nodes). Now, whenver a node is of type "pattern", its inmediate childs can be: nil,
all of type "pattern", some of type "pattern" and some of type "that", or all
of type "that". Same things happens if the parent is of type "that" and childs
of type "that" and "topic". In the case of a "topic" node, the childs can only
be nil or of type "topic". In the leafs of this whole rosetree, there are
templates (just a <string> in each one).

  This means that it is possible to write linearly this tree by walking the tree
in Depth-First order. And considering that a node of type A has a list of
childrens of the same type (same-childs-list) and a list of the next type
(diff-child-list).

  An example might clear things up:
  
                                  _____A_____
                                 /           \
                              __B__         __C__
                             /     \       /     \
                            D       E     F       G
                            |       |     |       |
                            H       I     J       K
                                    |
                                    L
                                    
  Node types:
    A, B, C, E -> type "pattern"
    D, F, G, I -> type "that"
    H, J, K, L -> type "topic"
        
    If I write binary <number>s as text and the "same_childs" and
  "diff_childs" pair as [ <same_childs>, <diff_childs> ], the resulting CAIML would look
  something like (header would be "CAIML0"):
    1A[2,0]B[0,1]D[0,1]H[0,0]<string>E[0,1]I[0,1]L[0,0]<string>C[0,2]F[0,1]J[0,0]<string>
    G[0,1]K[0,0]<string>
    
    Note that the nodes and the <string> have their length embedded.
