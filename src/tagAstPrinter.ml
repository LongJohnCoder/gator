(* Tag AST pretty printer *)

open CoreAst
open Util
open TagAst

let string_of_lst (f : 'a -> string) (l: 'a list) : string =
    List.fold_left (fun a b -> f b) "\n" l

let string_of_tag_typ (t: tag_typ) : string =
    match t with
    | TopTyp n -> "vec"^(string_of_int n)
    | BotTyp n -> "vec"^(string_of_int n)^"lit"
    | VarTyp s -> s
    | TAbsTyp s -> "`"^s

let rec string_of_typ (t: typ) : string = 
    match t with
    | AutoTyp -> "auto"
    | UnitTyp -> "void"
    | BoolTyp -> "bool"
    | IntTyp -> "int"
    | FloatTyp -> "float"
    | TagTyp s -> string_of_tag_typ s
    | TransTyp (s1, s2) -> (string_of_tag_typ s1) ^ "->" ^ (string_of_tag_typ s2)
    | SamplerTyp i -> "sampler" ^ (string_of_int i) ^ "D"
    | AbsTyp s -> "`" ^ s
    | GenTyp -> "genTyp"
    | GenMatTyp -> "mat"
    | GenVecTyp -> "vec"

let rec string_of_exp (e:exp) : string =
    let string_of_arr (a: exp list) : string = 
        "["^(String.concat ", " (List.map string_of_exp a))^"]"
    in
    match e with
    | Val v -> string_of_value v
    | Var v -> v
    | Arr a -> string_of_arr a
    | Unop (op, x) -> (string_of_unop op (string_of_exp x))
    | Binop (op, l, r) -> 
        let ls = (string_of_exp l) in
        let rs = (string_of_exp r) in
        (match op with
        | _ -> (string_of_binop op ls rs))
    | _ -> failwith "string_of_exp Unimplemented"

let rec string_of_params (p: (id * typ * typ option) list) : string =
    match p with
    | [] -> ""
    | (i1, t1, None)::t -> (string_of_typ t1) ^ " " ^ i1 ^ ", " ^ (string_of_params t)
    | (i1, t1, Some s)::t -> (string_of_typ t1) ^ " " ^ i1 ^ ", " ^ (string_of_params t)

let rec string_of_parameterization (pm : parametrization) : string = 
    match pm with 
    | [] -> ""
    | (t, None)::tl -> (string_of_typ t) ^ ", " ^ (string_of_parameterization tl)
    | (t, Some t')::tl -> (string_of_typ t) ^ ":" ^ (string_of_typ t') ^", "^(string_of_parameterization tl)

let string_of_fn_type ((p, r, pm): fn_type) : string = 
    (string_of_typ r) ^ " <" ^ (string_of_parameterization pm) ^ ">" ^ "(" ^ (string_of_params p) ^ ")"

let string_of_fn_decl (d: fn_decl) : string = 
    match d with
    | (id, (p, r, pm)) -> (string_of_typ r) ^ " " ^ id ^ " <" ^ (string_of_parameterization pm) ^ ">" ^ " (" ^ (string_of_params p) ^ ")"

let rec string_of_comm (c: comm) : string =
    match c with
    | Skip -> "skip;"
    | Print e -> "print " ^ (string_of_exp e) ^ ";"
    | Inc x -> x ^ "++"
    | Dec x -> x ^ "--"
    | Decl (t, None, s, e) -> (string_of_typ t)^" " ^ s ^ " = " ^ (string_of_exp e) ^ ";"
    | Decl (t, _, s, e) -> failwith "unsupported"
    | Assign (b, x) -> b ^ " = " ^ (string_of_exp x) ^ ";"
    | AssignOp (x, op, e) -> x ^ " " ^  binop_string op ^ "= " ^ (string_of_exp e)
    | If ((b, c1), elif_list, c2) -> 
        let block_string c = "{\n " ^ (string_of_comm_list c) ^ "}" in
        let rec string_of_elif lst = (match lst with 
        | [] -> "" 
        | (b, c)::t -> "elif (" ^ (string_of_exp b) ^ ")" ^ block_string c ^ (string_of_elif t))
        in
        "if (" ^ (string_of_exp b) ^ ") {\n" ^ (string_of_comm_list c1) ^ "} " 
        ^ string_of_elif elif_list ^ (match c2 with | None -> "" | Some c2 -> "else {\n" ^ (string_of_comm_list c2) ^ "}")
    | For (d, b, u, cl) -> "for (" ^ string_of_comm d ^ string_of_exp b ^ "; " ^ string_of_comm u ^ ") {\n" ^ string_of_comm_list cl ^ "}"
    | Return None -> "return;"
    | Return Some e -> "return" ^ (string_of_exp e) ^ ";"
    | FnCall (id, e, _) -> id ^ "(" ^ (String.concat "," (List.map string_of_exp e)) ^ "^" (* TODO *)
    

and 
string_of_comm_list (cl : comm list) : string = 
    string_of_lst string_of_comm cl

let rec string_of_tags (t : tag_decl list) : string =
    match t with 
    | [] -> ""
    | (s, a)::t -> "tag " ^ s ^ " is "^(string_of_typ a) ^ ";\n" ^ (string_of_tags t)

let string_of_fn (f : fn) : string = 
    match f with
    | (d, c1) -> string_of_fn_decl d ^ "{" ^ (string_of_comm_list c1) ^"}"

let rec string_of_fn_lst (fl : fn list) : string = 
    string_of_lst string_of_fn fl

let string_of_declare (f: fn) : string = 
    "declare " ^ string_of_fn f

let string_of_declare_lst (fl : fn list) : string = 
    string_of_lst string_of_declare fl

let string_of_prog (e : prog) : string =
    match e with
    | Prog (d, t, f) -> (string_of_tags t) ^ (string_of_fn_lst f) 
