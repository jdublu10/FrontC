(* cabs -- abstract syntax for FrontC *)

let version = "Cabs 4.0 Hugues Cassé et al."
exception BadModifier
exception BadType

(**
 * Thrown when an unconsistent C abstract syntax is found.
*)
exception UnconsistentDef


(** Size of int *)
type size =
    NO_SIZE  (** No size modifier *)
  | SHORT   (** "short" modifier *)
  | LONG   (** "long" modifier *)
  | LONG_LONG  (** GNU "long long" modifier *)
  [@@deriving show, compare, equal, sexp_of, hash]

(** Signess of int and bitfields *)
and sign =
    NO_SIGN  (** No sign modifier *)
  | SIGNED  (** "signed" modifier *)
  | UNSIGNED  (** "unsigned" modifier *)
  [@@deriving show, compare, equal, sexp_of, hash]

(** Storage of names *)
and storage =
    NO_STORAGE (** No storage modifier *)
  | AUTO   (** "auto" modifier *)
  | STATIC  (** "static" modifier *)
  | EXTERN  (** "extern" modifier *)
  | REGISTER  (** "register" modifier *)
  [@@deriving show, compare, equal, sexp_of, hash]


(** Base type *)
and base_type =
  | NO_TYPE    (** Old K&R declaration without type *)
  | VOID     (** "void" type *)
  | BOOL     (** C99 boolean (_Bool) type  *)
  | CHAR of sign   (** "char" type with sign modifier *)
  | INT of size * sign (** "int" type with size and sign modifiers *)
  | BITFIELD of sign * expression
  (** Bitfield with sign modifier and size expression *)
  | FLOAT of bool    (** "float" type with long (true) modifier *)
  | DOUBLE of bool   (** "double" type with long (true) modifier *)
  | COMPLEX_FLOAT    (** float complex *)
  | COMPLEX_DOUBLE   (** double complex *)
  | COMPLEX_LONG_DOUBLE         (** long double complex *)
  | PTR of base_type   (** Pointer "*" to the given type *)
  | RESTRICT_PTR of base_type (** REstricted pointer "*" to the given type. *)
  | ARRAY of base_type * expression
  (** Array of the given type with the given expression size (may be NOTHING) *)
  | STRUCT of string * name_group list
  (** "struct" of the given name (may be empty) with given fields (may also be empty) *)
  | UNION of string * name_group list
  (** "union" of the given name (may be empty) with given fields (may also be empty) *)
  | PROTO of proto  (** Prototype of a function *)
  | OLD_PROTO of old_proto (** Old-style K&R prototype *)
  | NAMED_TYPE of string  (** Named type coming from typedef *)
  | ENUM of string * enum_item list
  (** "union" of the given name (may be empty) with given values (may also be empty) *)
  | CONST of base_type
  (** "const" modifier *)
  | VOLATILE of base_type
  (** "volatile" modifier *)
  | GNU_TYPE of gnu_attrs * base_type
  (** a type annotated with GNU attributes *)
  | BUILTIN_TYPE of string
  (** a machine-specific or complier-specific builtin type  *)
  | TYPE_LINE of string * int * base_type
  (** Not a type, just to record the file/line of an identifier. *)
  [@@deriving show, compare, equal, sexp_of, hash]

(** A name in a declaration with identifier, full type, GNU attributes and
 * initialization expression. *)
and name = string * base_type * gnu_attrs * expression
  [@@deriving show, compare, equal, sexp_of, hash]

(** A name group, that is, a simple type following by many name
 * declaration as [int v, *p, t\[256\];]. *)
and name_group = base_type * storage * name list
  [@@deriving show, compare, equal, sexp_of, hash]

(** A single name, as above, but with only one declaration. *)
and single_name = base_type * storage * name
  [@@deriving show, compare, equal, sexp_of, hash]

(** Definition of an enumerated value. *)
and enum_item = string * expression
  [@@deriving show, compare, equal, sexp_of, hash]

(** Prototype of a function with return type, function declaration and
 * variable argument "..." boolean. *)
and proto = base_type * single_name list * bool
  [@@deriving show, compare, equal, sexp_of, hash]

(** Old-C K&R function prototype with root type, list of arguments and
 * variable argument "..." boolean. *)
and old_proto = base_type * string list * bool
  [@@deriving show, compare, equal, sexp_of, hash]


(** Definitions found in a C file. *)
and definition =
  | FUNDEF of single_name * body
  (** Definition of a function. *)
  | OLDFUNDEF of single_name * name_group list * body
  (** Definition of an old-C K&R style function. *)
  | DECDEF of name_group
  (** Declaration of function or definition of a variable. *)
  | TYPEDEF of name_group * gnu_attrs
  (** Definition of a typedef. *)
  | ONLYTYPEDEF of name_group
  (** Definition of lonely "struct", "union" or "enum". *)
  [@@deriving show, compare, equal, sexp_of, hash]

(** A C files is composed of C definitions *)
and file = definition list
  [@@deriving show, compare, equal, sexp_of, hash]


(** The body of a function is composed as a list of variable declaration
 * and of a statement. *)
and body = definition list * statement
  [@@deriving show, compare, equal, sexp_of, hash]


(** Statement changes the flow of control. *)
and statement =
    NOP
  (** No operation. Useful for empty else-part in condition. *)
  | COMPUTATION of expression
  (** A simple expression, usually an assignment. *)
  | BLOCK of body
  (** A block between braces *)
  | SEQUENCE of statement * statement
  (** Two statement separated by ";" *)
  | IF of expression * statement * statement
  (** "if" statement with or without else-part. *)
  | WHILE of expression * statement
  (** "while" statement. *)
  | DOWHILE of expression * statement
  (** "do ... while" statement *)
  | FOR of expression * expression * expression * statement
  (** "for" statement. *)
  | BREAK
  (** "break" statement. *)
  | CONTINUE
  (** "continue" statement. *)
  | RETURN of expression
  (** "return" statement with an expression or with NOTHING. *)
  | SWITCH of expression * statement
  (** "switch" statement. Cases are put in the sub-statement as labels. *)
  | CASE of expression * statement
  (** "case" statement as a label. *)
  | DEFAULT of statement
  (** "default" statement as a label. *)
  | LABEL of string * statement
  (** "label" statement whose sub-statement follows colon ":". *)
  | GOTO of string
  (** "goto" statement. *)
  | ASM of string
  (** Classical "asm" support. *)
  | GNU_ASM of string * gnu_asm_arg list * gnu_asm_arg list * string list
  (** GNU "asm" support. *)
  | STAT_LINE of statement * string * int
  (** Information the filename and the line number of the contained statement. *)
  [@@deriving show, compare, equal, sexp_of, hash]

and gnu_asm_arg =  string * string * expression
  [@@deriving show, compare, equal, sexp_of, hash]

(* Binary operators identifiers. *)
and binary_operator =
    ADD    (** "+" operator. *)
  | SUB    (** "-" operator. *)
  | MUL    (** "*" operator. *)
  | DIV    (** "/" operator. *)
  | MOD    (** "%" operator. *)
  | AND    (** "&&" operator. *)
  | OR    (** "||" operator. *)
  | BAND    (** "&" operator. *)
  | BOR    (** "|" operator. *)
  | XOR    (** "^" operator. *)
  | SHL    (** "<<" operator. *)
  | SHR    (** ">>" operator. *)
  | EQ    (** "==" operator. *)
  | NE    (** "!=" operator. *)
  | LT    (** "<" operator. *)
  | GT    (** ">" operator. *)
  | LE    (** "<=" operator. *)
  | GE    (** ">=" operator. *)
  | ASSIGN   (** "=" operator. *)
  | ADD_ASSIGN  (** "+=" operator. *)
  | SUB_ASSIGN  (** "-=" operator. *)
  | MUL_ASSIGN  (** "*=" operator. *)
  | DIV_ASSIGN  (** "/=" operator. *)
  | MOD_ASSIGN  (** "%=" operator. *)
  | BAND_ASSIGN  (** "&=" operator. *)
  | BOR_ASSIGN  (** "|=" operator. *)
  | XOR_ASSIGN  (** "^=" operator. *)
  | SHL_ASSIGN  (** "<<=" operator. *)
  | SHR_ASSIGN  (** ">>=" operator. *)
  [@@deriving show, compare, equal, sexp_of, hash]

(** Unary operators identifiers. *)
and unary_operator =
    MINUS  (** "-" operator. *)
  | PLUS  (** "+" operator. *)
  | NOT  (** "!" operator. *)
  | BNOT  (** "~" operator. *)
  | MEMOF  (** "*" operator. *)
  | ADDROF (** "&" operator. *)
  | PREINCR (** "++" pre-incrementation. *)
  | PREDECR (** "--" pre-decrementation. *)
  | POSINCR (** "++" post-incrementation. *)
  | POSDECR (** "--" post-decrementation. *)
  [@@deriving show, compare, equal, sexp_of, hash]

(** Expressions. *)
and expression =
    NOTHING
  (** Null-expression. Useful for return with no value or table
      declaration without size. *)
  | UNARY of unary_operator * expression
  (** Unary operator use. *)
  | BINARY of binary_operator * expression * expression
  (** Binary operator use. *)
  | QUESTION of expression * expression * expression
  (** "condition ? then-expression : else-expression" operator. *)
  | CAST of base_type * expression
  (** "(type)expresson" type casting. *)
  | CALL of expression * expression list
  (** Function call. *)
  | COMMA of expression list
  (** Sequence of expression separated with ",". *)
  | CONSTANT of constant
  (** Constant value. *)
  | VARIABLE of string
  (** Access to an identifier. *)
  | EXPR_SIZEOF of expression
  (** "sizeof" with expression. *)
  | TYPE_SIZEOF of base_type
  (** "sizeof" with type. *)
  | INDEX of expression * expression
  (** Access to an array item; *)
  | MEMBEROF of expression * string
  (** Indirection through ".". *)
  | MEMBEROFPTR of expression * string
  (** Pointer indirection through "->". *)
  | GNU_BODY of body
  (** GNU braces inside an expression. *)
  | DESIGNATED of string * expression
  (** Designated initialization, in compound constants only. *)
  | EXPR_LINE of expression * string * int
  (** Record the file and line of the expression. *)
  [@@deriving show, compare, equal, sexp_of, hash]

(** Constant values. *)
and constant =
  | CONST_INT of string
  (** Integer constant. *)
  | CONST_FLOAT of string
  (** Float constant. *)
  | CONST_CHAR of string
  (** Character constant with escapes resolved. *)
  | CONST_STRING of string
  (** String constant with escapes resolved. *)
  | CONST_COMPOUND of expression list
  (** Compound values between braces. Only valid for variable
      initialization. *)
  [@@deriving show, compare, equal, sexp_of, hash]

(** GNU special attribute list.*)
and gnu_attrs = gnu_attr list
  [@@deriving show, compare, equal, sexp_of, hash]

(** GNU special attribute. *)
and gnu_attr =
    GNU_NONE
  (** No attribute "()". *)
  | GNU_CALL of string * gnu_attr list
  (** Function call. *)
  | GNU_ID of string
  (** Single identifier. *)
  | GNU_CST of constant
  (** Constant value. *)
  | GNU_EXTENSION
  (** Support of __extension__ keyword *)
  | GNU_INLINE
  (** Support of __inline keyword *)
  | GNU_TYPE_ARG of base_type * storage
  [@@deriving show, compare, equal, sexp_of, hash]
