(* Forward.ec *)

(* Forwarding Functionality *)

prover quorum=2 ["Alt-Ergo" "Z3"].

require import AllCore List ListPO.
require import UCCoreDiffieHellman.

(* theory parameters *)

(* port index of adversary that functionality communicates with *)

op adv_pi : int.

axiom fwd_pi_uniq : uniq [adv_pi; 0].

(* end theory parameters *)

(* request sent to port index 1 of forwarding functionality: pt1 is
   asking to forward u to pt2 *)

op fw_req (func : addr, pt1 pt2 : port, u : univ) : msg =
     (Dir, (func, 1), pt1, UnivPair (UnivPort pt2, u)).

op dec_fw_req (m : msg) : (addr * port * port * univ) option =
     let (mod, pt1, pt2, v) = m
     in (mod = Adv \/ pt1.`2 <> 1 \/ ! is_univ_pair v) ?
        None :
        let (v1, v2) = oget (dec_univ_pair v)
        in (! is_univ_port v1) ?
           None :
           Some (pt1.`1, pt2, oget (dec_univ_port v1), v2).

lemma enc_dec_fw_req (func : addr, pt1 pt2 : port, u : univ) :
  dec_fw_req (fw_req func pt1 pt2 u) = Some (func, pt1, pt2, u).
proof. done. qed.

lemma dec_enc_fw_req (m : msg, func : addr, pt1 pt2 : port, u : univ) :
  dec_fw_req m = Some (func, pt1, pt2, u) =>
  fw_req func pt1 pt2 u = m.
proof.
case m => mod pt1' pt2' u'.
rewrite /dec_fw_req /fw_req /=.
case (mod = Adv \/ pt1'.`2 <> 1 \/ ! is_univ_pair u') => //.
rewrite !negb_or /= not_adv.
move => [#] => -> H1.
rewrite /is_univ_pair.
case u' => //.
case => x1 x2 /=.
rewrite oget_some /=.
rewrite /is_univ_port.
case x1 => // p /=.
rewrite oget_some /#.
qed.

op is_fw_req (m : msg) : bool =
     dec_fw_req m <> None.

lemma is_fw_req (func : addr, pt1 pt2 : port, u : univ) :
  is_fw_req (fw_req func pt1 pt2 u).
proof. done. qed.

lemma dest_good_fw_req (m : msg) :
  is_fw_req m =>
  (oget (dec_fw_req m)).`1 = m.`2.`1 /\ m.`2.`2 = 1.
proof.
case m => mod pt1 pt2 u.
rewrite /is_fw_req /dec_fw_req /=.
case (mod = Adv \/ pt1.`2 <> 1 \/ ! is_univ_pair u) => //.
rewrite !negb_or /=.
move => [#] _ _.
rewrite /is_univ_pair /dec_univ_pair; case u => // x /=.
rewrite oget_some; case x => /= x1 x2.
case (is_univ_port x1) => //=.
qed.

(* response sent from port index 1 of forwarding functionality to pt2,
   completing the forwarding of u that was requested by pt1 *)

op fw_rsp (func : addr, pt1 pt2 : port, u : univ) : msg =
     (Dir, pt2, (func, 1), UnivPair (UnivPort pt1, u)).

op dec_fw_rsp (m : msg) : (addr * port * port * univ) option =
     let (mod, pt1, pt2, v) = m
     in (mod = Adv \/ pt2.`2 <> 1 \/ ! is_univ_pair v) ?
        None :
        let (v1, v2) = oget (dec_univ_pair v)
        in (! is_univ_port v1) ?
           None :
           Some (pt2.`1, oget (dec_univ_port v1), pt1, v2).

lemma enc_dec_fw_rsp (func : addr, pt1 pt2 : port, u : univ) :
  dec_fw_rsp (fw_rsp func pt1 pt2 u) = Some (func, pt1, pt2, u).
proof. done. qed.

lemma dec_enc_fw_rsp (m : msg, func : addr, pt1 pt2 : port, u : univ) :
  dec_fw_rsp m = Some (func, pt1, pt2, u) =>
  fw_rsp func pt1 pt2 u = m.
proof.
case m => mod pt1' pt2' u'.
rewrite /dec_fw_rsp /fw_rsp /=.
case (mod = Adv \/ pt2'.`2 <> 1 \/ ! is_univ_pair u') => //.
rewrite !negb_or /= not_adv.
move => [#] -> H1 /=.
rewrite /is_univ_pair.
case u' => //.
case => x1 x2 /=.
rewrite oget_some /=.
rewrite /is_univ_port.
case x1 => // p /=.
rewrite oget_some /#.
qed.

op is_fw_rsp (m : msg) : bool =
     dec_fw_rsp m <> None.

lemma is_fw_rsp (func : addr, pt1 pt2 : port, u : univ) :
  is_fw_rsp (fw_rsp func pt1 pt2 u).
proof. done. qed.

lemma dest_good_fw_rsp (m : msg) :
  is_fw_rsp m => (oget (dec_fw_rsp m)).`3 = m.`2.
proof.
case m => mod pt1 pt2 u.
rewrite /is_fw_rsp /dec_fw_rsp /=.
case (mod = Adv \/ pt2.`2 <> 1 \/ ! is_univ_pair u) => //.
rewrite !negb_or /=.
move => [#] _ _.
rewrite /is_univ_pair /dec_univ_pair; case u => // x /=.
rewrite oget_some; case x => /= x1 x2.
case (is_univ_port x1) => //.
qed.

(* message from forwarding functionality to adversary, letting it
   observe that the functionality is proposing to forward u to
   pt2 on behalf of pt1 *)

op fw_obs (func adv : addr, pt1 pt2 : port, u : univ) : msg =
     (Adv, (adv, adv_pi), (func, 1),
      univ_triple (UnivPort pt1) (UnivPort pt2) u).

op dec_fw_obs (m : msg) : (addr * addr * port * port * univ) option =
     let (mod, pt1, pt2, v) = m
     in (mod = Dir \/ pt1.`2 <> adv_pi \/ pt2.`2 <> 1 \/
         ! is_univ_triple v) ?
        None :
        let (v1, v2, v3) = oget (dec_univ_triple v)
        in (! is_univ_port v1 \/ ! is_univ_port v2) ?
           None :
           Some (pt2.`1, pt1.`1,
                 oget (dec_univ_port v1),
                 oget (dec_univ_port v2),
                 v3).

lemma enc_dec_fw_obs (func adv : addr, pt1 pt2 : port, u : univ) :
  dec_fw_obs (fw_obs func adv pt1 pt2 u) = Some (func, adv, pt1, pt2, u).
proof.
by rewrite /fw_obs /dec_fw_obs /=
   (is_univ_triple (UnivPort pt2) (UnivPort pt2) u) /=
    enc_dec_univ_triple.
qed.

lemma dec_enc_fw_obs (m : msg, func adv : addr, pt1 pt2 : port, u : univ) :
  dec_fw_obs m = Some (func, adv, pt1, pt2, u) =>
  fw_obs func adv pt1 pt2 u = m.
proof.
case m => mod pt1' pt2' u'.
rewrite /dec_fw_obs /fw_obs /=.
case (mod = Dir \/ pt1'.`2 <> adv_pi \/ pt2'.`2 <> 1 \/
      ! is_univ_triple u') => //.
rewrite !negb_or not_dir /=.
move => [#] => -> H1 H2.
rewrite /is_univ_triple.
case u'; first 7 smt().
case => x1 x2.
rewrite /dec_univ_triple /= oget_some /=.
case x2 => //.
case => x2 x3 /=.
rewrite oget_some /= oget_some /=.
case (! is_univ_port x1 \/ ! is_univ_port x2) => //=.
rewrite negb_or /=.
move => [#] => H3 H4 [#] <- <- <- <- <-.
rewrite /univ_triple.
split; first smt().
move => _; split; first smt().
move => _.
congr; congr.
move : H3; by case x1.
congr; congr.
move : H4; by case x2.
qed.

op is_fw_obs (m : msg) : bool =
     dec_fw_obs m <> None.

lemma is_fw_obs (func adv : addr, pt1 pt2 : port, u : univ) :
  is_fw_obs (fw_obs func adv pt1 pt2 u).
proof.
by rewrite /is_fw_obs enc_dec_fw_obs.
qed.

(* message from adversary telling forwarding functionality it may
   proceed with forwarding *)

op fw_ok (func adv : addr) : msg =
     (Adv, (func, 1), (adv, adv_pi), UnivUnit).

op dec_fw_ok (m : msg) : (addr * addr) option =
     let (mod, pt1, pt2, v) = m
     in (mod = Dir \/ pt1.`2 <> 1 \/ pt2.`2 <> adv_pi \/
         v <> UnivUnit) ?
        None :
        Some (pt1.`1, pt2.`1).

lemma dec_enc_fw_ok (m : msg, func adv) :
  dec_fw_ok m = Some (func, adv) =>
  fw_ok func adv = m.
proof.
case m => mod pt1' pt2' u'.
rewrite /dec_fw_ok /fw_ok /=.
case (mod = Dir \/ pt1'.`2 <> 1 \/ pt2'.`2 <> adv_pi \/ u' <> UnivUnit) => //.
rewrite !negb_or not_dir /#.
qed.

op is_fw_ok (m : msg) : bool =
     dec_fw_ok m <> None.

lemma is_fw_ok (func adv : addr) :
  is_fw_ok (fw_ok func adv).
proof. done. qed.

lemma dest_good_fw_ok (m : msg) :
  is_fw_ok m => (oget (dec_fw_ok m)).`1 = m.`2.`1 /\
  m.`2.`2 = 1.
proof.
case m => mod pt1 pt2 u.
rewrite /is_fw_ok /dec_fw_ok /=.
case
  (mod = Dir \/ pt1.`2 <> 1 \/ pt2.`2 <> adv_pi \/
   u <> UnivUnit) => //.
by rewrite !negb_or /=.
qed.

type fw_state = [
    FwStateInit
  | FwStateWait  of (port * port * univ)
  | FwStateFinal of (port * port * univ)
].

op dec_fw_state_wait (st : fw_state) : (port * port * univ) option =
     with st = FwStateInit    => None
     with st = FwStateWait t  => Some t
     with st = FwStateFinal _ => None.

lemma enc_dec_fw_state_wait (t : port * port * univ) :
  dec_fw_state_wait (FwStateWait t) = Some t.
proof. done. qed.

op is_fw_state_wait (st : fw_state) : bool =
  dec_fw_state_wait st <> None.

lemma is_fw_state_wait (t : port * port * univ) :
  is_fw_state_wait (FwStateWait t).
proof. done. qed.

op dec_fw_state_final (st : fw_state) : (port * port * univ) option =
     with st = FwStateInit    => None
     with st = FwStateWait _  => None
     with st = FwStateFinal x => Some x.

lemma enc_dec_fw_final (t : port * port * univ) :
  dec_fw_state_final (FwStateFinal t) = Some t.
proof. done. qed.

op is_fw_state_final (st : fw_state) : bool =
  dec_fw_state_final st <> None.

lemma is_fw_state_final (t : port * port * univ) :
  is_fw_state_final (FwStateFinal t).
proof. done. qed.

module Forw : FUNC = {
  var self, adv : addr
  var st : fw_state

  proc init(self_ adv_ : addr) : unit = {
    self <- self_; adv <- adv_; st <- FwStateInit;
  }

  proc invoke(m : msg) : msg option = {
    var pt1, pt2 : port; var u : univ;
    var addr1, addr2 : addr;
    var r : msg option <- None;
    if (st = FwStateInit) {
      if (is_fw_req m) {
        (addr1, pt1, pt2, u) <- oget (dec_fw_req m);
        if (self = addr1 /\ ! self <= pt1.`1 /\ ! self <= pt2.`1) {
          r <- Some (fw_obs self adv pt1 pt2 u);
          st <- FwStateWait (pt1, pt2, u);
        }
      }
    }
    elif (is_fw_state_wait st) {
      (pt1, pt2, u) <- oget (dec_fw_state_wait st);
      if (is_fw_ok m) {
        (addr1, addr2) <- oget (dec_fw_ok m);
        if (addr1 = self) {
          r <- Some (fw_rsp self pt1 pt2 u);
          st <- FwStateFinal (pt1, pt2, u);
        }
      }
    }
    return r;
  }
}.

(* termination metric and proof *)

op term_metric_max : int = 2.

op term_metric (st : fw_state) : int =
     with st = FwStateInit    => 2
     with st = FwStateWait _  => 1
     with st = FwStateFinal _ => 0.

lemma ge0_term_metric (st : fw_state) : 0 <= term_metric st.
proof. by case st. qed.

lemma term_metric_is_fw_state_wait (st : fw_state) :
  is_fw_state_wait st => term_metric st = 1.
proof. by case st. qed.

lemma init :
  equiv
  [Forw.init ~ Forw.init :
   ={self_, adv_} ==> ={res, glob Forw}].
proof.
proc; auto.
qed.

lemma term_init :
  equiv
  [Forw.init ~ Forw.init :
   ={self_, adv_} ==>
   ={res, glob Forw} /\
   term_metric Forw.st{1} = term_metric_max].
proof.
proc; auto.
qed.

lemma term_invoke (n : int) :
  equiv
  [Forw.invoke ~ Forw.invoke :
   ={m, glob Forw} /\
   term_metric Forw.st{1} = n ==>
   ={res, Forw.st} /\
   (res{1} = None \/ term_metric Forw.st{1} = n - 1)].
proof.
proc; sp 1 1.
if => //.
if => //.
sp 1 1.
if; first by move => |> &1 &2 <-.
auto => |> &1 &2 <- //.
auto.
if => //.
sp 1 1.
if => //.
sp 1 1.
if.
move => &1 &2 [#] oget_dec_1 oget_dec_2 _ _ _ _ ->>.
rewrite -oget_dec_1 /= in oget_dec_2.
by elim oget_dec_2 => -> _.
auto => |> &1 &2.
smt(term_metric_is_fw_state_wait).
auto.
qed.
