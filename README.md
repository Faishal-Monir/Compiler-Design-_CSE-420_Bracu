# CSE 420 - Compiler Design [ Spring-2026 ]

![Course](https://img.shields.io/badge/Course-CSE%20420-blue)
![Topic](https://img.shields.io/badge/Topic-Compiler%20Design-0aa6a6)
![Language](https://img.shields.io/badge/Language-C%2FC%2B%2B-00599C?logo=cplusplus&logoColor=white)
![Flex](https://img.shields.io/badge/Tool-Flex%2FLex-orange)
![Yacc](https://img.shields.io/badge/Tool-Yacc%2FBison-purple)
![Shell](https://img.shields.io/badge/Scripts-Bash-4EAA25?logo=gnubash&logoColor=white)

A complete CSE 420 Compiler Design lab repository completed in **Spring 2026**. This repository covers the practical construction of a small C-like compiler using **Flex/Lex**, **Yacc/Bison**, and **C/C++**, progressing from lexical analysis and syntax analysis to scoped symbol-table management, semantic analysis, AST construction, and intermediate three-address code generation.

---

## Table of contents

- [Course information](#course-information)
- [Folder structure](#folder-structure)
- [Lab work summary](#lab-work-summary)
- [Installation guide](#installation-guide)
- [Project group members](#project-group-members)

---

## Course information

**Course:** CSE420 - Compiler Design  
**Semester completed:** Spring 2026  
**Pre-requisites:** CSE321, CSE331, CSE340  

### Course description

CSE420 introduces the theory and practice of compiler and interpreter design. The course emphasizes practical solutions using compiler-writing tools such as **Yacc/Bison** in UNIX-like environments and the **C/C++** programming language.

Covered topics include lexical scanners, context-free languages, pushdown automata, recursive descent parsing, bottom-up parsing, attributed grammars, symbol-table design, run-time memory allocation, machine language, code generation, and code optimization.

---

## Folder structure

```text
CSE-420 LABS/
  Software_Installation_Instructions_updated.pdf

  CSE420LAB1/
    22101235_22101870.l
    22101235_22101870.y
    symbol_info.h
    input.txt
    script.sh

  CSE420LAB2/
    22101235_22101870.l
    22101235_22101870.y
    symbol_info.h
    scope_table.h
    symbol_table.h
    input.c
    script.sh

  CSE420LAB3/
    22101235_22101870.l
    22101235_22101870.y
    symbol_info.h
    scope_table.h
    symbol_table.h
    input.c
    script.sh
    generate_lab3_pdf.py

  CSE420LAB4/
    22101235_22101870.l
    22101235_22101870.y
    ast.h
    three_addr_code.h
    symbol_info.h
    scope_table.h
    symbol_table.h
    input.c
    script.sh
    code.txt
```

---

## Lab work summary

### Lab 1 - Lexical analyzer and syntax analyzer

**Main files:**

```text
CSE420LAB1/
  22101235_22101870.l
  22101235_22101870.y
  symbol_info.h
  input.txt
  script.sh
```

Lab 1 implements the first stage of the compiler front-end. The Lex/Flex file defines regular expressions for whitespace, newlines, identifiers, integer constants, floating-point constants, keywords, operators, brackets, parentheses, braces, commas, semicolons, and other C-like language tokens.

The Yacc/Bison file defines grammar productions for a simplified C-like language. It supports program units, variable declarations, function definitions, parameter lists, compound statements, statements, expressions, logical expressions, relational expressions, arithmetic expressions, unary expressions, factors, function arguments, and array access syntax.

**What was done:**

- Tokenized C-like source code using Lex/Flex.
- Built parser grammar using Yacc/Bison.
- Logged recognized tokens and grammar reductions.
- Parsed variable declarations, functions, control statements, expressions, function calls, and arrays.
- Used a simple `symbol_info` class to pass token and grammar-rule information between scanner and parser.

---

### Lab 2 - Symbol table generation

**Main files:**

```text
CSE420LAB2/
  22101235_22101870.l
  22101235_22101870.y
  symbol_info.h
  scope_table.h
  symbol_table.h
  input.c
  script.sh
```

Lab 2 extends the parser by integrating a scoped symbol table. The implementation introduces separate classes for symbol information, scope tables, and the full symbol-table manager.

`symbol_info.h` stores metadata for identifiers, including whether a symbol is a variable, array, or function. It also stores data types, array sizes, return types, and function parameter details.

`scope_table.h` implements individual scope tables using hashing and collision handling. `symbol_table.h` manages nested scopes, insertion, deletion, lookup, current-scope printing, and all-scope printing.

**What was done:**

- Added a scoped symbol-table architecture.
- Inserted variables, arrays, and functions into the correct scope.
- Managed function parameters and compound-statement scopes.
- Printed symbol-table contents after parsing.
- Detected duplicate declarations in the current scope during insertion.
- Preserved grammar-production logging from Lab 1.

---

### Lab 3 - Semantic analysis

**Main files:**

```text
CSE420LAB3/
  22101235_22101870.l
  22101235_22101870.y
  symbol_info.h
  scope_table.h
  symbol_table.h
  input.c
  script.sh
  generate_lab3_pdf.py
```

Lab 3 adds semantic checking on top of parsing and symbol-table generation. The Yacc/Bison file performs type propagation, scope lookup, function validation, parameter checking, and semantic error reporting.

The implementation uses helper logic for detecting integer, float, void, and error types. It also merges numeric expression types where needed and prevents cascading errors by propagating an internal `error` type.

**What was done:**

- Checked multiple declarations of variables and functions.
- Checked duplicate parameter names in function definitions.
- Detected undeclared variables and undeclared functions.
- Differentiated scalar variables, arrays, and functions.
- Checked invalid array access and non-integer array indices.
- Detected use of arrays as normal variables and normal variables as arrays.
- Validated function-call argument count and argument types.
- Detected return-type mismatches.
- Checked assignment compatibility, including float-to-int warning cases.
- Detected invalid operations on `void` type.
- Checked modulus operator constraints and division/modulus by zero.
- Wrote semantic errors to `22101235_22101870_error.txt`.
- Logged total line count and total error count.

---

### Lab 4 - AST and intermediate code generation

**Main files:**

```text
CSE420LAB4/
  22101235_22101870.l
  22101235_22101870.y
  ast.h
  three_addr_code.h
  symbol_info.h
  scope_table.h
  symbol_table.h
  input.c
  script.sh
```

Lab 4 implements a two-pass compiler workflow. The first pass parses the source program, performs symbol-table and semantic checks, and builds an Abstract Syntax Tree. The second pass walks the AST and generates three-address code.

`ast.h` defines AST node classes such as `ProgramNode`, `FuncDeclNode`, `BlockNode`, `DeclNode`, `ExprStmtNode`, `IfNode`, `WhileNode`, `ForNode`, `ReturnNode`, `AssignNode`, `BinaryOpNode`, `UnaryOpNode`, `VarNode`, `ConstNode`, `FuncCallNode`, and `ArgumentsNode`.

`three_addr_code.h` defines a `ThreeAddrCodeGenerator` class that traverses the AST and emits temporary-variable based intermediate code with labels for control flow.

**What was done:**

- Built an AST while reducing parser grammar rules.
- Attached AST nodes to `symbol_info` objects during parsing.
- Generated intermediate three-address code only when parsing and semantic analysis completed without errors.
- Supported TAC generation for declarations, assignments, arithmetic expressions, relational expressions, function calls, returns, loops, and conditional statements.
- Used temporary variables such as `t0`, `t1`, `t2` for expression evaluation.
- Used labels such as `L0`, `L1`, `L2` for branching and loop control.
- Generated `param` and `call` instructions for function calls.
- Wrote final intermediate code to `code.txt`.

Example three-address code pattern generated by Lab 4:

```text
t0 = a
t1 = b
t2 = t0 + t1
return t2
```

Control-flow code is generated using labels and conditional jumps:

```text
L0:
t1 = i
t2 = 10
t3 = t1 < t2
if t3 goto L1
goto L2
```

---

## Installation guide

Before running the labs, install the required compiler tools and environment.

### Installation tutorial

A video installation tutorial is available here:

```text
https://www.youtube.com/watch?v=fH6OvP6oeBE
```

### Installation PDF

The repository also includes an installation PDF in the root folder:

```text
Software_Installation_Instructions_updated.pdf
```

Refer to this PDF for the updated software installation instructions.

---

## Project group members

- [Umma Salma Mim](https://github.com/ummasalmamim)
- [Faishal Monir](https://github.com/Faishal-Monir)