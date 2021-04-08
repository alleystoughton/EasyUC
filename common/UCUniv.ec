(* Univ.ec *)

(* Universe of Values Plus EPDPs *)

(* TODO
prover [""].  (* no use of SMT provers *)
*)

prover ["Z3" "Alt-Ergo"].  (* TODO - remove! *)

require import AllCore List StdOrder IntDiv BitEncoding UCEncoding.
import IntOrder BS2Int.

(* auxiliary definitions and lemmas *)

(* integer logarithms for use below (EasyCrypt now provides these via
   log on reals, but we prefer to work directly with ints) *)

lemma exists_int_log (b n : int) :
  2 <= b => 1 <= n =>
  exists (k : int), 0 <= k /\ b ^ k <= n < b ^ (k + 1).
proof.
move => ge2_b ge1_n.
have gt1_b : 1 < b by rewrite ltzE.
have gt0_b : 0 < b by rewrite (ltr_trans 1).
have ge0_b : 0 <= b by rewrite ltrW.
have H :
  forall n,
  0 <= n => 1 <= n =>
  exists (k : int), 0 <= k /\ b ^ k <= n < b ^ (k + 1).
  apply sintind => i ge0_i IH /= ge1_i.
  case (i < b) => [lt_i_b | ge_b_i].
  exists 0; by rewrite /= expr0 ge1_i /= expr1.
  rewrite -lerNgt in ge_b_i.
  have [ge1_i_div_b i_div_b_lt_i] : 1 <= i %/ b < i.
    split => [| _].
    by rewrite lez_divRL 1:gt0_b.
    by rewrite ltz_divLR 1:gt0_b -divr1 mulzA 1:ltr_pmul2l ltzE.
  have /= [k [#] ge0_k b_exp_k_le_i_div_b i_div_b_lt_b_tim_b_exp_k]
       := IH (i %/ b) _ _.
    split; [by rewrite (lez_trans 1) | trivial].
    trivial.
  rewrite exprS // in i_div_b_lt_b_tim_b_exp_k.
  exists (k + 1).
  split; first by rewrite ler_paddl.
  rewrite exprS // mulzC exprS 1:ler_paddr // exprS //.
  split => [| _].
  rewrite (lez_trans ((i %/ b) * b)).
  by rewrite ler_wpmul2r 1:(lez_trans 2).
  by rewrite leq_trunc_div 1:(lez_trans 1).
  rewrite ltz_divLR // in i_div_b_lt_b_tim_b_exp_k.
  by rewrite mulzC.
by rewrite H (lez_trans 1).
qed.

lemma int_log_uniq (b n k1 k2 : int) :
  2 <= b =>
  0 <= k1 => b ^ k1 <= n => n < b ^ (k1 + 1) =>
  0 <= k2 => b ^ k2 <= n => n < b ^ (k2 + 1) =>
  k1 = k2.
proof.
move => ge2_b ge0_k1 b2k1_le_n n_lt_b2k1p1 ge0_k2 b2k2_le_n n_lt_b2k2p1.
have ge1_b : 1 <= b.
  by rewrite (lez_trans 2).
case (k1 = k2) => [// | /ltr_total [lt_k1_k2 | lt_k2_k1]].
rewrite ltzE in lt_k1_k2.
have b2k1p1_le_b2k2 : b ^ (k1 + 1) <= b ^ k2.
  by rewrite ler_weexpn2l // lt_k1_k2 /= addr_ge0.
have // : n < n.
  by rewrite (ltr_le_trans (b ^ (k1 + 1))) // (lez_trans (b ^ k2)).
rewrite ltzE in lt_k2_k1.
have b2k2p1_le_b2k1 : b ^ (k2 + 1) <= b ^ k1.
  by rewrite ler_weexpn2l // lt_k2_k1 /= addr_ge0.
have // : n < n.
  by rewrite (ltr_le_trans (b ^ (k2 + 1))) // (lez_trans (b ^ k1)).
qed.

op int_log (b n : int) : int = (* integer logarithm *)
  choiceb
  (fun (k : int) => 0 <= k /\ b ^ k <= n < b ^ (k + 1))
  0.

lemma int_logP (b n : int) :
  2 <= b => 1 <= n =>
  0 <= int_log b n /\ b ^ (int_log b n) <= n < b ^ (int_log b n + 1).
proof.
move => ge2_b ge1_n.
have // := choicebP (fun k => 0 <= k /\ b ^ k <= n < b ^ (k + 1)) 0 _.
  by rewrite /= exists_int_log.
qed.

lemma ge0_int_log (b n : int) :
  2 <= b => 1 <= n => 0 <= int_log b n.
proof.
move => ge2_b ge1_n.
have := int_logP b n _ _ => //.
qed.

lemma int_logPuniq (b n l : int) :
  2 <= b =>
  0 <= l => b ^ l <= n < b ^ (l + 1) =>
  l = int_log b n.
proof.
move => ge2_b ge0_n [b2l_le_n n_lt_b2lp1].
have ge1_n : 1 <= n.
  by rewrite (lez_trans (b ^ l)) // exprn_ege1 // (lez_trans 2).
have := int_logP b n _ _ => // [#] ge0_il b2il_le_n n_lt_b2ilp1.
by apply (int_log_uniq b n).
qed.

(* int2bs, for 1 <= n, with minimum number of bits: *)

op int2bs_min (n : int) : bool list = int2bs (int_log 2 n + 1) n.

lemma div_self (n : int) :
  n <> 0 => n %/ n = 1.
proof.
move => ne0_n.
by rewrite divzz /b2i ne0_n.
qed.

(* most significant (which is last) element of int2bs_min n
   is true: *)

lemma int2bs_min_last (n : int) :
  1 <= n => last false (int2bs_min n).
proof.
move => ge1_n.
rewrite /int2bs_min.
have [#] := int_logP 2 n _ _ => //.
pose N := int_log 2 n.
move => ge0_N two2N_le_n n_lt_two2Np1.
have sizeNp1_eq : size (int2bs (N + 1) n) = N + 1.
  by rewrite size_int2bs ler_maxr 1:ler_paddr.
have sizeN_eq: size (int2bs N n) = N.
  by rewrite size_int2bs ler_maxr /N 1:ge0_N.
rewrite -nth_last sizeNp1_eq /= 1:int2bsS // nth_rcons sizeN_eq /=.
have -> // : n %/ 2 ^ N = 1.
have ge1_ndivtwo2N : 1 <= n %/ 2 ^ N.
  have -> : 1 = 2 ^ N %/ 2 ^ N.
    by rewrite div_self // gtr_eqF 1:expr_gt0.
  by rewrite leq_div2r // expr_ge0.
have ndivtwo2N_le_1 : n %/ 2 ^ N <= 1.
  rewrite -ltzS /=.
  rewrite exprS // in n_lt_two2Np1.
  by rewrite ltz_divLR 1:expr_gt0.
by rewrite eqr_le.
qed.

(* universe *)

type univ = bool list.  (* universe values are lists of bits *)

(* unit encoding: *)

op enc_unit (x : unit) : univ = [].

op dec_unit (u : univ) : unit option =
  if u = [] then Some () else None.

op nosmt epdp_unit_univ : (unit, univ) epdp =
  {|enc = enc_unit; dec = dec_unit|}.

lemma valid_epdp_unit_univ : valid_epdp epdp_unit_univ.
apply epdp_intro => [x | u x].
by rewrite /epdp_unit_univ /= /enc_unit /dec_unit.
rewrite /epdp_unit_univ /= /enc_unit /dec_unit.
by case u.
qed.

hint simplify [eqtrue] valid_epdp_unit_univ.
hint rewrite epdp : valid_epdp_unit_univ.

(* bool encoding: *)

op enc_bool (b : bool) : univ = [b].

op dec_bool (u : univ) : bool option =
  if size u = 1 then Some (head true u) else None.

op nosmt epdp_bool_univ : (bool, univ) epdp =
  {|enc = enc_bool; dec = dec_bool|}.

lemma valid_epdp_bool_univ : valid_epdp epdp_bool_univ.
apply epdp_intro => [x | u x].
by rewrite /epdp_bool_univ /= /enc_bool /dec_bool.
rewrite /epdp_bool_univ /= /enc_bool /dec_bool.
case u => [// | y ys /=].
case (1 + size ys = 1) => [size_eq /= -> /=| //].
have /= /size_eq0 -> // : (1 + size ys) - 1 = 1 - 1.
  by rewrite size_eq.
qed.

hint simplify [eqtrue] valid_epdp_bool_univ.
hint rewrite epdp : valid_epdp_bool_univ.

(* int encoding: *)

op enc_int (n : int) : univ =
  if n = 0
  then []
  else if 0 < n
       then true  :: int2bs_min n
       else false :: int2bs_min (-n).

op dec_int (u : univ) : int option =
  match u with
  | []      => Some 0
  | b :: bs =>
      if b
      then if bs = [] \/ ! (last false bs)
           then None
           else Some (bs2int bs)
      else if bs = [] \/ ! (last false bs)
           then None
           else Some (-(bs2int bs))
  end.

op nosmt epdp_int_univ : (int, univ) epdp =
  {|enc = enc_int; dec = dec_int|}.

lemma valid_epdp_int_univ : valid_epdp epdp_int_univ.
apply epdp_intro => [x | u x].
rewrite /epdp_int_univ /= /enc_int /dec_int /=.
case (x = 0) => [-> // | ne0_x].
case (0 < x) => [gt0_x | not_ge0_x].
pose bs := int2bs_min x.
have [#] ge0_il two2il_le_x x_lt_two2ilp1 := int_logP 2 x _ _ => //.
  by rewrite -add0z -ltzE.
have bs_ne_nil : bs <> [] by rewrite int2bs_ne_nil 1:ler_paddl.
rewrite bs_ne_nil /=.



rewrite int2bsK 1:ler_paddr //.
split => [| //].
by rewrite ltzW.
have ge0_negx : 0 < -x.
  rewrite -lerNgt -oppz_ge0 in not_ge0_x.
  by rewrite ltr_def not_ge0_x /= oppr_eq0.
have [#] ge0_il two2il_le_negx negx_lt_two2ilp1 := int_logP 2 (-x) _ _ => //.
  by rewrite -add0z -ltzE.
pose bs := int2bs (int_log 2 (-x) + 1) (-x).
have -> /= : bs <> [] by rewrite int2bs_ne_nil 1:ler_paddl.
rewrite int2bsK 1:ler_paddr //.
split => [| //].
by rewrite ltzW.
rewrite /epdp_int_univ /= /enc_int /dec_int.
case u => [/= <- // | z zs /=].
case z => _.
case (zs = []) => [// | zs_ne_nil /= <-].
have bs2int_zs_ne0 : bs2int zs <> 0.
  admit.
rewrite bs2int_zs_ne0 /=.
case (0 < bs2int zs) => [gt0_bs2int_zs | not_ge0_bs2int_zs].
congr.
have -> : int_log 2 (bs2int zs) + 1 = size zs.

search int2bs size.
search int2bs.

int_log 2 (bs2int zs) + 1 = size zs
int_log 2 (bs2int [10]) + 1 = size [10]



by rewrite bs2intK.
admit.
case (zs = []) => [// | zs_ne_nil /= <-].
have bs2int_zs_ne0 : - bs2int zs <> 0.
  admit.
rewrite bs2int_zs_ne0 /=.
case (0 < - bs2int zs) => [gt0_bs2int_zs | not_ge0_bs2int_zs].
admit.
congr.
have -> : int_log 2 (bs2int zs) + 1 = size zs.
  admit.
by rewrite bs2intK.
qed.

hint simplify [eqtrue] valid_epdp_int_univ.
hint rewrite epdp : valid_epdp_int_univ.

op epdp_univ_pair_univ : (univ * univ, univ) epdp.  (* univ * univ *)

axiom valid_epdp_univ_pair_univ : valid_epdp epdp_univ_pair_univ.

hint simplify [eqtrue] valid_epdp_univ_pair_univ.
hint rewrite epdp : valid_epdp_univ_pair_univ.

op epdp_univ_list_univ : (univ list, univ) epdp.  (* univ list *)

axiom valid_epdp_univ_list_univ : valid_epdp epdp_univ_list_univ.

hint simplify [eqtrue] valid_epdp_univ_list_univ.
hint rewrite epdp : valid_epdp_univ_list_univ.

(* now we can build on these axiomatized encoding/partial decoding
   operators *)

(* triple univ encoding: *)

op nosmt enc_univ_triple (t : univ * univ * univ) : univ =
  epdp_univ_pair_univ.`enc (t.`1, (epdp_univ_pair_univ.`enc (t.`2, t.`3))).

op nosmt dec_univ_triple (u : univ) : (univ * univ * univ) option =
  match epdp_univ_pair_univ.`dec u with
  | None   => None
  | Some p =>
      match epdp_univ_pair_univ.`dec p.`2 with
        None   => None
      | Some q => Some (p.`1, q.`1, q.`2)
      end
  end.

op nosmt epdp_univ_triple_univ : (univ * univ * univ, univ) epdp =
  {|enc = enc_univ_triple; dec = dec_univ_triple|}.

lemma valid_epdp_univ_triple_univ : valid_epdp epdp_univ_triple_univ.
apply epdp_intro => [x | u x].
rewrite /epdp_univ_triple_univ /= /enc_univ_triple /dec_univ_triple.
rewrite !epdp /= !epdp /=.
by case x.
rewrite /epdp_univ_triple_univ /= /enc_univ_triple /dec_univ_triple =>
  match_dec_u_eq_some.
have val_u :
  epdp_univ_pair_univ.`dec u =
  Some (x.`1, epdp_univ_pair_univ.`enc (x.`2, x.`3)).
  move : match_dec_u_eq_some.
  case (epdp_univ_pair_univ.`dec u) => // [[]] x1 q /=.
  move => match_dec_q_eq_some.
  have val_y2 :
    epdp_univ_pair_univ.`dec q = Some (x.`2, x.`3).
    move : match_dec_q_eq_some.
    case (epdp_univ_pair_univ.`dec q) => // [[]] x2 x3 /= <- //.
  move : match_dec_q_eq_some.
  rewrite val_y2 /= => <- /=.
  rewrite (epdp_dec_enc _ _ q) 1:valid_epdp_univ_pair_univ //.
by rewrite (epdp_dec_enc _ _ u) 1:valid_epdp_univ_pair_univ.
qed.

hint simplify [eqtrue] valid_epdp_univ_triple_univ.
hint rewrite epdp : valid_epdp_univ_triple_univ.

(* quadruple univ encoding: *)

op nosmt enc_univ_quadruple (t : univ * univ * univ * univ) : univ =
  epdp_univ_pair_univ.`enc
  (t.`1, (epdp_univ_triple_univ.`enc (t.`2, t.`3, t.`4))).

op nosmt dec_univ_quadruple (u : univ) : (univ * univ * univ * univ) option =
  match epdp_univ_pair_univ.`dec u with
  | None   => None
  | Some p =>
      match epdp_univ_triple_univ.`dec p.`2 with
        None   => None
      | Some q => Some (p.`1, q.`1, q.`2, q.`3)
      end
  end.

op nosmt epdp_univ_quadruple_univ : (univ * univ * univ * univ, univ) epdp =
  {|enc = enc_univ_quadruple; dec = dec_univ_quadruple|}.

lemma valid_epdp_univ_quadruple_univ : valid_epdp epdp_univ_quadruple_univ.
apply epdp_intro => [x | u x].
rewrite /epdp_univ_quadruple_univ /= /enc_univ_quadruple /dec_univ_quadruple /=.
rewrite !epdp /= !epdp /=.
by case x.
rewrite /epdp_univ_quadruple_univ /= /enc_univ_quadruple /dec_univ_quadruple =>
  match_dec_u_eq_some.
have val_u :
  epdp_univ_pair_univ.`dec u =
  Some (x.`1, epdp_univ_triple_univ.`enc (x.`2, x.`3, x.`4)).
  move : match_dec_u_eq_some.
  case (epdp_univ_pair_univ.`dec u) => // [[]] x1 q /=.
  move => match_dec_q_eq_some.
  have val_y2 :
    epdp_univ_triple_univ.`dec q = Some (x.`2, x.`3, x.`4).
    move : match_dec_q_eq_some.
    case (epdp_univ_triple_univ.`dec q) => // [[]] x2 x3 x4 /= <- //.
  move : match_dec_q_eq_some.
  rewrite val_y2 /= => <- /=.
  rewrite (epdp_dec_enc _ _ q) 1:valid_epdp_univ_triple_univ //.
by rewrite (epdp_dec_enc _ _ u) 1:valid_epdp_univ_pair_univ.
qed.

hint simplify [eqtrue] valid_epdp_univ_quadruple_univ.
hint rewrite epdp : valid_epdp_univ_quadruple_univ.

(* quintuple univ encoding: *)

op nosmt enc_univ_quintuple (t : univ * univ * univ * univ * univ) : univ =
  epdp_univ_pair_univ.`enc
  (t.`1, (epdp_univ_quadruple_univ.`enc (t.`2, t.`3, t.`4, t.`5))).

op nosmt dec_univ_quintuple (u : univ) :
    (univ * univ * univ * univ * univ) option =
  match epdp_univ_pair_univ.`dec u with
  | None   => None
  | Some p =>
      match epdp_univ_quadruple_univ.`dec p.`2 with
        None   => None
      | Some q => Some (p.`1, q.`1, q.`2, q.`3, q.`4)
      end
  end.

op nosmt epdp_univ_quintuple_univ :
    (univ * univ * univ * univ * univ, univ) epdp =
  {|enc = enc_univ_quintuple; dec = dec_univ_quintuple|}.

lemma valid_epdp_univ_quintuple_univ : valid_epdp epdp_univ_quintuple_univ.
apply epdp_intro => [x | u x].
rewrite /epdp_univ_quintuple_univ /= /enc_univ_quintuple
        /dec_univ_quintuple /=.
rewrite !epdp /= !epdp /=.
by case x.
rewrite /epdp_univ_quintuple_univ /= /enc_univ_quintuple
        /dec_univ_quintuple => match_dec_u_eq_some.
have val_u :
  epdp_univ_pair_univ.`dec u =
  Some (x.`1, epdp_univ_quadruple_univ.`enc (x.`2, x.`3, x.`4, x.`5)).
  move : match_dec_u_eq_some.
  case (epdp_univ_pair_univ.`dec u) => // [[]] x1 q /=.
  move => match_dec_q_eq_some.
  have val_y2 :
    epdp_univ_quadruple_univ.`dec q = Some (x.`2, x.`3, x.`4, x.`5).
    move : match_dec_q_eq_some.
    case (epdp_univ_quadruple_univ.`dec q) => // [[]] x2 x3 x4 x5 /= <- //.
  move : match_dec_q_eq_some.
  rewrite val_y2 /= => <- /=.
  rewrite (epdp_dec_enc _ _ q) 1:valid_epdp_univ_quadruple_univ //.
by rewrite (epdp_dec_enc _ _ u) 1:valid_epdp_univ_pair_univ.
qed.

hint simplify [eqtrue] valid_epdp_univ_quintuple_univ.
hint rewrite epdp : valid_epdp_univ_quintuple_univ.

(* encoding of 'a * 'b *)

op nosmt enc_pair_univ
     (epdp1 : ('a, univ) epdp, epdp2 : ('b, univ) epdp, p : 'a * 'b) : univ =
  epdp_univ_pair_univ.`enc (epdp1.`enc p.`1, epdp2.`enc p.`2).
  
op nosmt dec_pair_univ
     (epdp1 : ('a, univ) epdp, epdp2 : ('b, univ) epdp, u : univ)
       : ('a * 'b) option =
  match epdp_univ_pair_univ.`dec u with
  | None   => None
  | Some p =>
      match epdp1.`dec p.`1 with
      | None    => None
      | Some x1 =>
          match epdp2.`dec p.`2 with
          | None    => None
          | Some x2 => Some (x1, x2)
          end
      end
  end.

op nosmt epdp_pair_univ (epdp1 : ('a, univ) epdp, epdp2 : ('b, univ) epdp)
     : ('a * 'b, univ) epdp =
  {|enc = enc_pair_univ epdp1 epdp2; dec = dec_pair_univ epdp1 epdp2|}.

lemma valid_epdp_pair_univ (epdp1 : ('a, univ) epdp, epdp2 : ('b, univ) epdp) :
  valid_epdp epdp1 => valid_epdp epdp2 =>
  valid_epdp (epdp_pair_univ epdp1 epdp2).
proof.  
move => valid1 valid2.
apply epdp_intro => [x | y x].
rewrite /epdp_pair_univ /= /dec_pair_univ /enc_pair_univ.
rewrite !epdp /= !epdp // /=.
by case x.  
rewrite /epdp_pair_univ /= /dec_pair_univ /enc_pair_univ => match_dec_y_eq_some.
have val_y :
  epdp_univ_pair_univ.`dec y = Some (epdp1.`enc x.`1, epdp2.`enc x.`2).
  move : match_dec_y_eq_some.
  case (epdp_univ_pair_univ.`dec y) => // [[]] x1 x2 /=.
  move => match_dec_x1_eq_some.
  have val_x1 : epdp1.`dec x1 = Some x.`1.
    move : match_dec_x1_eq_some.
    case (epdp1.`dec x1) => // x1' /=.
    case (epdp2.`dec x2) => // _ /=.
  rewrite (epdp_dec_enc _ _ x1) //=.
  move : match_dec_x1_eq_some.
  rewrite val_x1 /= => match_dec_x2_eq_some.
  have val_x2 : epdp2.`dec x2 = Some x.`2.
    move : match_dec_x2_eq_some.
    case (epdp2.`dec x2) => // x2' /= <- //.
  rewrite (epdp_dec_enc _ _ x2) //.
by rewrite (epdp_dec_enc _ _ y) 1:valid_epdp_univ_pair_univ.
qed.

hint rewrite epdp_sub : valid_epdp_pair_univ.

(* encoding of 'a * 'b * 'c *)

op nosmt enc_triple_univ
     (epdp1 : ('a, univ) epdp, epdp2 : ('b, univ) epdp, epdp3 : ('c, univ) epdp,
      p : 'a * 'b * 'c) : univ =
  epdp_univ_triple_univ.`enc
  (epdp1.`enc p.`1, epdp2.`enc p.`2, epdp3.`enc p.`3).
  
op nosmt dec_triple_univ
     (epdp1 : ('a, univ) epdp, epdp2 : ('b, univ) epdp,
      epdp3 : ('c, univ) epdp, u : univ) : ('a * 'b * 'c) option =
  match epdp_univ_triple_univ.`dec u with
  | None   => None
  | Some p =>
      match epdp1.`dec p.`1 with
      | None    => None
      | Some x1 =>
          match epdp2.`dec p.`2 with
          | None    => None
          | Some x2 =>
              match epdp3.`dec p.`3 with
              | None    => None
              | Some x3 => Some (x1, x2, x3)
              end
          end
      end
  end.

op nosmt epdp_triple_univ
     (epdp1 : ('a, univ) epdp, epdp2 : ('b, univ) epdp, epdp3 : ('c, univ) epdp)
       : ('a * 'b * 'c, univ) epdp =
  {|enc = enc_triple_univ epdp1 epdp2 epdp3;
    dec = dec_triple_univ epdp1 epdp2 epdp3|}.

lemma valid_epdp_triple_univ
      (epdp1 : ('a, univ) epdp, epdp2 : ('b, univ) epdp,
       epdp3 : ('c, univ) epdp) :
  valid_epdp epdp1 => valid_epdp epdp2 => valid_epdp epdp3 =>
  valid_epdp (epdp_triple_univ epdp1 epdp2 epdp3).
proof.  
move => valid1 valid2 valid3.
apply epdp_intro => [x | y x].
rewrite /epdp_triple_univ /= /dec_triple_univ /enc_triple_univ.
rewrite !epdp /= !epdp //=.
by case x.  
rewrite /epdp_triple_univ /= /dec_triple_univ /enc_triple_univ =>
  match_dec_y_eq_some.
have val_y :
  epdp_univ_triple_univ.`dec y =
  Some (epdp1.`enc x.`1, epdp2.`enc x.`2, epdp3.`enc x.`3).
  move : match_dec_y_eq_some.
  case (epdp_univ_triple_univ.`dec y) => // [[]] x1 x2 x3 /=.
  move => match_dec_x1_eq_some.
  have val_x1 : epdp1.`dec x1 = Some x.`1.
    move : match_dec_x1_eq_some.
    case (epdp1.`dec x1) => // x1' /=.
    case (epdp2.`dec x2) => // x0 /=.
    case (epdp3.`dec x3) => // _ /=.
  rewrite (epdp_dec_enc _ _ x1) 1:valid1 //=.
  move : match_dec_x1_eq_some.
  rewrite val_x1 /= => match_dec_x2_eq_some.
  have val_x2 : epdp2.`dec x2 = Some x.`2.
    move : match_dec_x2_eq_some.
    case (epdp2.`dec x2) => // x2' /=.
    by case (epdp3.`dec x3) => // x0 /= <-.
  rewrite (epdp_dec_enc _ _ x2) 1:valid2 //=.
  move : match_dec_x2_eq_some.
  rewrite val_x2 /= => match_dec_x3_eq_some.
  have val_x3 : epdp3.`dec x3 = Some x.`3.
    move : match_dec_x3_eq_some.
    by case (epdp3.`dec x3) => // x3' /= <-.
  rewrite (epdp_dec_enc _ _ x3) //.
by rewrite (epdp_dec_enc _ _ y) 1:valid_epdp_univ_triple_univ.
qed.

hint rewrite epdp_sub : valid_epdp_triple_univ.

(* encoding of 'a * 'b * 'c * 'd *)

op nosmt enc_quadruple_univ
     (epdp1 : ('a, univ) epdp, epdp2 : ('b, univ) epdp,
      epdp3 : ('c, univ) epdp, epdp4 : ('d, univ) epdp,
      p : 'a * 'b * 'c * 'd) : univ =
  epdp_univ_quadruple_univ.`enc
  (epdp1.`enc p.`1, epdp2.`enc p.`2, epdp3.`enc p.`3, epdp4.`enc p.`4).
  
op nosmt dec_quadruple_univ
     (epdp1 : ('a, univ) epdp, epdp2 : ('b, univ) epdp,
      epdp3 : ('c, univ) epdp, epdp4 : ('d, univ) epdp,
      u : univ) : ('a * 'b * 'c * 'd) option =
  match epdp_univ_quadruple_univ.`dec u with
  | None   => None
  | Some p =>
      match epdp1.`dec p.`1 with
      | None    => None
      | Some x1 =>
          match epdp2.`dec p.`2 with
          | None    => None
          | Some x2 =>
              match epdp3.`dec p.`3 with
              | None    => None
              | Some x3 =>
                  match epdp4.`dec p.`4 with
                  | None    => None
                  | Some x4 => Some (x1, x2, x3, x4)
                  end
              end
          end
      end
  end.

op nosmt epdp_quadruple_univ
     (epdp1 : ('a, univ) epdp, epdp2 : ('b, univ) epdp,
      epdp3 : ('c, univ) epdp, epdp4 : ('d, univ) epdp)
       : ('a * 'b * 'c * 'd, univ) epdp =
  {|enc = enc_quadruple_univ epdp1 epdp2 epdp3 epdp4;
    dec = dec_quadruple_univ epdp1 epdp2 epdp3 epdp4|}.

lemma valid_epdp_quadruple_univ
      (epdp1 : ('a, univ) epdp, epdp2 : ('b, univ) epdp,
       epdp3 : ('c, univ) epdp, epdp4 : ('d, univ) epdp) :
  valid_epdp epdp1 => valid_epdp epdp2 => valid_epdp epdp3 =>
  valid_epdp epdp4 =>
  valid_epdp (epdp_quadruple_univ epdp1 epdp2 epdp3 epdp4).
proof.  
move => valid1 valid2 valid3 valid4.
apply epdp_intro => [x | y x].
rewrite /epdp_quadruple_univ /= /dec_quadruple_univ /enc_quadruple_univ.
rewrite !epdp /= !epdp //=.
by case x.  
rewrite /epdp_quadruple_univ /= /dec_quadruple_univ /enc_quadruple_univ =>
  match_dec_y_eq_some.
have val_y :
  epdp_univ_quadruple_univ.`dec y =
  Some (epdp1.`enc x.`1, epdp2.`enc x.`2, epdp3.`enc x.`3, epdp4.`enc x.`4).
  move : match_dec_y_eq_some.
  case (epdp_univ_quadruple_univ.`dec y) => // [[]] x1 x2 x3 x4 /=.
  move => match_dec_x1_eq_some.
  have val_x1 : epdp1.`dec x1 = Some x.`1.
    move : match_dec_x1_eq_some.
    case (epdp1.`dec x1) => // x1' /= match_dec_x2_eq_some.
    have val_x2 : epdp2.`dec x2 = Some x.`2.
      move : match_dec_x2_eq_some.
      case (epdp2.`dec x2) => // x2' /=.
      case (epdp3.`dec x3) => // x0 /=.
      case (epdp4.`dec x4) => // _ /=.
    move : match_dec_x2_eq_some.
    rewrite val_x2 /=.
    case (epdp3.`dec x3) => // x0 /=.
    by case (epdp4.`dec x4) => // x5 /= <-.
  move : match_dec_x1_eq_some.
  rewrite val_x1 => /= match_dec_x2_eq_some.
  rewrite (epdp_dec_enc _ _ x1) //=.
  have val_x2 : epdp2.`dec x2 = Some x.`2. 
    move : match_dec_x2_eq_some.
    case (epdp2.`dec x2) => // x2' /=.
    case (epdp3.`dec x3) => // x0 /=.
    by case (epdp4.`dec x4) => // x5 /= <-.
  rewrite (epdp_dec_enc _ _ x2) //=.
  move : match_dec_x2_eq_some.
  rewrite val_x2 /= => match_dec_x3_eq_some.
  have val_x3 : epdp3.`dec x3 = Some x.`3.
    move : match_dec_x3_eq_some.
    case (epdp3.`dec x3) => // x3' /=.
    by case (epdp4.`dec x4) => // x0 /= <-.
  rewrite (epdp_dec_enc _ _ x3) //=.
  move : match_dec_x3_eq_some.
  rewrite val_x3 /= => match_dec_x4_eq_some.
  have val_x4 : epdp4.`dec x4 = Some x.`4.
    move : match_dec_x4_eq_some.
    by case (epdp4.`dec x4) => // x4' /= <-.
  by rewrite (epdp_dec_enc _ _ x4).
by rewrite (epdp_dec_enc _ _ y) 1:valid_epdp_univ_quadruple_univ.
qed.

hint rewrite epdp_sub : valid_epdp_quadruple_univ.

(* encoding of 'a * 'b * 'c * 'd * 'e *)

op nosmt enc_quintuple_univ
     (epdp1 : ('a, univ) epdp, epdp2 : ('b, univ) epdp,
      epdp3 : ('c, univ) epdp, epdp4 : ('d, univ) epdp,
      epdp5 : ('e, univ) epdp,
      p : 'a * 'b * 'c * 'd * 'e) : univ =
  epdp_univ_quintuple_univ.`enc
  (epdp1.`enc p.`1, epdp2.`enc p.`2, epdp3.`enc p.`3,
   epdp4.`enc p.`4, epdp5.`enc p.`5).
  
op nosmt dec_quintuple_univ
     (epdp1 : ('a, univ) epdp, epdp2 : ('b, univ) epdp,
      epdp3 : ('c, univ) epdp, epdp4 : ('d, univ) epdp,
      epdp5 : ('e, univ) epdp,
      u : univ) : ('a * 'b * 'c * 'd * 'e) option =
  match epdp_univ_quintuple_univ.`dec u with
  | None   => None
  | Some p =>
      match epdp1.`dec p.`1 with
      | None    => None
      | Some x1 =>
          match epdp2.`dec p.`2 with
          | None    => None
          | Some x2 =>
              match epdp3.`dec p.`3 with
              | None    => None
              | Some x3 =>
                  match epdp4.`dec p.`4 with
                  | None    => None
                  | Some x4 =>
                      match epdp5.`dec p.`5 with
                      | None    => None
                      | Some x5 => Some (x1, x2, x3, x4, x5)
                      end
                  end
              end
          end
      end
  end.

op nosmt epdp_quintuple_univ
     (epdp1 : ('a, univ) epdp, epdp2 : ('b, univ) epdp,
      epdp3 : ('c, univ) epdp, epdp4 : ('d, univ) epdp,
      epdp5 : ('e, univ) epdp)
       : ('a * 'b * 'c * 'd * 'e, univ) epdp =
  {|enc = enc_quintuple_univ epdp1 epdp2 epdp3 epdp4 epdp5;
    dec = dec_quintuple_univ epdp1 epdp2 epdp3 epdp4 epdp5|}.

lemma valid_epdp_quintuple_univ
      (epdp1 : ('a, univ) epdp, epdp2 : ('b, univ) epdp,
       epdp3 : ('c, univ) epdp, epdp4 : ('d, univ) epdp,
       epdp5 : ('e, univ) epdp) :
  valid_epdp epdp1 => valid_epdp epdp2 => valid_epdp epdp3 =>
  valid_epdp epdp4 => valid_epdp epdp5 =>
  valid_epdp (epdp_quintuple_univ epdp1 epdp2 epdp3 epdp4 epdp5).
proof.  
move => valid1 valid2 valid3 valid4 valid5.
apply epdp_intro => [x | y x].
rewrite /epdp_quintuple_univ /= /dec_quintuple_univ /enc_quintuple_univ.
rewrite !epdp /= !epdp //=.
by case x.  
rewrite /epdp_quintuple_univ /= /dec_quintuple_univ /enc_quintuple_univ =>
  match_dec_y_eq_some.
have val_y :
  epdp_univ_quintuple_univ.`dec y =
  Some (epdp1.`enc x.`1, epdp2.`enc x.`2, epdp3.`enc x.`3,
        epdp4.`enc x.`4, epdp5.`enc x.`5).
  move : match_dec_y_eq_some.
  case (epdp_univ_quintuple_univ.`dec y) => // [[]] x1 x2 x3 x4 x5 /=.
  move => match_dec_x1_eq_some.
  have val_x1 : epdp1.`dec x1 = Some x.`1.
    move : match_dec_x1_eq_some.
    case (epdp1.`dec x1) => // x1' /= match_dec_x2_eq_some.
    have val_x2 : epdp2.`dec x2 = Some x.`2.
      move : match_dec_x2_eq_some.
      case (epdp2.`dec x2) => // x2' /=.
      case (epdp3.`dec x3) => // x0 /=.
      case (epdp4.`dec x4) => // x6 /=.
      case (epdp5.`dec x5) => // _ /=.
    move : match_dec_x2_eq_some.
    rewrite val_x2 /=.
    case (epdp3.`dec x3) => // x0 /=.
    case (epdp4.`dec x4) => // x6 /=.
    by case (epdp5.`dec x5) => // x7 /= <-.
  move : match_dec_x1_eq_some.
  rewrite val_x1 => /= match_dec_x2_eq_some.
  rewrite (epdp_dec_enc _ _ x1) //=.
  have val_x2 : epdp2.`dec x2 = Some x.`2. 
    move : match_dec_x2_eq_some.
    case (epdp2.`dec x2) => // x2' /=.
    case (epdp3.`dec x3) => // x0 /=.
    case (epdp4.`dec x4) => // x6 /=.
    by case (epdp5.`dec x5) => // x7 /= <-.
  rewrite (epdp_dec_enc _ _ x2) //=.
  move : match_dec_x2_eq_some.
  rewrite val_x2 /= => match_dec_x3_eq_some.
  have val_x3 : epdp3.`dec x3 = Some x.`3.
    move : match_dec_x3_eq_some.
    case (epdp3.`dec x3) => // x3' /=.
    case (epdp4.`dec x4) => // x0 /=.
    by case (epdp5.`dec x5) => // x6 /= <-.
  rewrite (epdp_dec_enc _ _ x3) //=.
  move : match_dec_x3_eq_some.
  rewrite val_x3 /= => match_dec_x4_eq_some.
  have val_x4 : epdp4.`dec x4 = Some x.`4.
    move : match_dec_x4_eq_some.
    case (epdp4.`dec x4) => // x4' /=.
    by case (epdp5.`dec x5) => // x0 /= <-.
  rewrite (epdp_dec_enc _ _ x4) //=.
  move : match_dec_x4_eq_some.
  rewrite val_x4 /= => match_dec_x5_eq_some.
  have val_x5 : epdp5.`dec x5 = Some x.`5.
    move : match_dec_x5_eq_some.
    by case (epdp5.`dec x5) => // x5' /= <-.
  by rewrite (epdp_dec_enc _ _ x5).
by rewrite (epdp_dec_enc _ _ y) 1:valid_epdp_univ_quintuple_univ.
qed.

hint rewrite epdp_sub : valid_epdp_quintuple_univ.

(* encoding of 'a list *)

op nosmt enc_list_univ (epdp : ('a, univ) epdp, xs : 'a list) : univ =
  epdp_univ_list_univ.`enc (map epdp.`enc xs).

op nosmt dec_list_univ
     (epdp : ('a, univ) epdp, u : univ) : 'a list option =
  match epdp_univ_list_univ.`dec u with
    None    => None
  | Some vs =>
      let ys = map epdp.`dec vs
      in if all is_some ys
         then Some (map oget ys)
         else None
  end.

op nosmt epdp_list_univ (epdp : ('a, univ) epdp) : ('a list, univ) epdp =
  {|enc = enc_list_univ epdp; dec = dec_list_univ epdp|}.

lemma valid_epdp_list_univ (epdp : ('a, univ) epdp) :
  valid_epdp epdp => valid_epdp (epdp_list_univ epdp).
proof.  
move => valid.
apply epdp_intro => [xs | y xs].
rewrite /epdp_list_univ /enc_list_univ /dec_list_univ /=.
rewrite !epdp /=.
have -> : map epdp.`dec (map epdp.`enc xs) = map Some xs.
  elim xs => [// | y ys /=].
  rewrite !epdp //.
have -> /= : all is_some (map Some xs) = true.
  elim xs => [// | y ys //].
elim xs => [// | y ys //].
rewrite /epdp_list_univ /enc_list_univ /dec_list_univ /= =>
  match_dec_y_eq_some.
have val_u : epdp_univ_list_univ.`dec y = Some (map epdp.`enc xs).
  move : match_dec_y_eq_some.
  case (epdp_univ_list_univ.`dec y) => // zs /=.
  case (all is_some (map epdp.`dec zs)) => // => all_is_some /= <-.
  move : all_is_some.
  elim zs => [// | w ws IH /= [#] is_some_dec_w all_is_some_dec_ws].
  split.
  rewrite (epdp_dec_enc _ _ w) // -(some_oget (epdp.`dec w)) //.
  move : is_some_dec_w; by case (epdp.`dec w).
  by apply IH.
by rewrite (epdp_dec_enc _ _ y) 1:valid_epdp_univ_list_univ.
qed.

hint rewrite epdp_sub : valid_epdp_list_univ.
