(*********************************************************************

The Elim tactic of November 2001

**********************************************************************)

val Tgb = ref VooBase
val Ton = ref Prop

val TonV = [NoShow,ShowNorm]

fun doTargets (Bind ((Pi,v),nam,dom,ran)) tgVTs i (bofb::C,T) =
   ((case parseApp dom
       of (Ref b,[ftgT,ftgt],_) =>
          if sameRef b (!Tgb) (* is it a formal target ? *)
          then case tgVTs
                 of [] => failwith "I want more targets!"
                  | ((atgt,atgT)::tgVTs) => (* got an actual target *)
                   (case wrapUnify atgt ftgt (wrapUnify atgT ftgT (SOME []))
                      of NONE => failwith "Not a legitimate target!"
                       | SOME s =>
                         let val (C,T) = s $>>> (C,T)
                             val nam = case v of Hid => "hid" | _ => "vis"
                             val nlb = noo ((Let,Def),"nam") ("tg",i)
                                           ([],MkApp ((!Ton,[atgT,atgt]),TonV))
                             val rty = whnf (subst1closed (Ref nlb) ran)
                         in  doTargets rty tgVTs (i+1) (bofb::nlb::C,T)
                         end)
          else raise Match
        | _ => raise Match)
    handle Match => (* just an ordinary premise *)
    let val nhb = noo (HoleBV,"") ("vh",i) ([],dom)
        val nam = case v of Hid => "hid" | _ => "vis"
        val nlb = noo ((Let,Def),nam) ("vl",i) ([],Ref nhb)
        val rty = whnf (subst1closed (Ref nlb) ran)
    in  doTargets rty tgVTs (i+1) (bofb::nlb::nhb::C,T)
    end)
  | doTargets (Bind ((Pi,_),_,_,_)) _ _ ([],_) = bug "doTargets"
  | doTargets rty ((atgt,atgT)::tgVTs) i (C,T) = vooctxtrec {
      hitBot = fn _ => failwith "Not a legitimate target!",
      hitDom = fn _ => fn _ => fn _ => fn _ =>
                       failwith "Not a legitimate target!",
      hitVoo = fn _ => fn b => fn _ => fn rect =>
               if holy b (* does the spare actual target fit here *)
               then case wrapUnify atgt (Ref b)
                         (wrapUnify atgT (ref_typ b) (SOME []))
                      of NONE => rect ()
                       | SOME s =>
                         let val S = s $>>> (C,T)
                         in  doTargets (whnf rty) tgVTs i S
                         end
               else rect ()
    } C
  | doTargets rty [] i S = S

fun makeEmbryo rv (bofb::C,T) =
    let val (splat,aa,vv) = Cfoldl
              (fn sav as (splat,aa,vv) => fn b =>
               if (ref_bind b) = Let
               then let val id = bid b
                        val a = ref_val b
                        val v = if (ref_nam b)="hid" then NoShow else ShowNorm
                    in (splat o (id\([],a)),a::aa,v::vv)
                    end
               else sav) (iota,[],[]) C
        val neb = noo ((Let,Def),"emb") ("emb",1)
                      ([],MkApp ((rv,aa),vv))
    in  splat (bofb::neb::C,T)
    end
  | makeEmbryo _ ([],_) = bug "makeEmbryo"

fun novTarget (rv,rt) g tgVTs S =
    let val S = on S [
                  vooattack g ("bof",1),
                  vooIntroTac ("bof",1),
                  doTargets (whnf rt) tgVTs 1,
               (*  makeEmbryo rv, *)
                  domvoo g
                ]
    in  S
    end

(*****************************
fun splitMotive n i (S,p) (g,_) =
    let fun Fholes 0 D = []
          | Fholes n D =
            let val hs = Fholes (n-1) D
                val nom = if n=p then "Phi" else "F"
                val hb = noo (HoleBV,"F") (nom,i+n-1) (vooCopy D)
            in  hb::hs
            end
        val ((bofb,C),T) = hdtlid (voodom g S)
        val phib = case parseApp (ref_typ (hd C))
                     of (Ref b,_,_) => b
                      | _ => failwith "I see no motive!"
        val _ = if (holy phib) andalso
                   (Cfoldr (fn b => fn p => p orelse
                                              sameRef phib b) false C)
                then ()
                else failwith "I see no motive!"
        val phid = bid phib
        val S = on (C,T) [
                  voodom phid,
                  introall iota "i" 1,
                  domvoo phid
                ]
        val (IC,IT) = (bCT phib)
        val (LIC,(zap,paz)) = copyCtxt ldify IC
        val (aa,vv) = ArgsAndVis iota LIC
        val hs = Fholes n (IC,IT)
        val happs = map (fn hb => MkApp ((Ref hb,aa),vv)) hs
        val sigs = map (fn T => noo ((Sig,Vis),"") ("F",0) ([],T)) (tl happs)
        val SigT = $!(sigs,hd happs)
        val ((emb,C),T) = hdtlid ((phid \ (LIC@hs,SigT)) S)
        fun proj 1 1 t = t
          | proj 1 n t = Proj (Fst,t)
          | proj p n t = if p>1 then proj (p-1) (n-1) (Proj (Snd,t))
                         else bug "splitMotive-dimwit"
        val neb = noo ((Let,Def),"emb") ("emb",2) ([],proj p n (Ref emb))
        val S = on (bofb::neb::emb::C,T) [
                  voosubdef ("emb",1),
                  domvoo g
                ]
    in  (S,p+1)
    end
*****************************)

fun splitMotive rv n i (S,1) (g,_) =
    let val (C,T) = makeEmbryo rv (voodom g S)
        val phib = case parseApp (ref_typ (hd (tl C)))
                     of (Ref b,_,_) => b
                      | _ => failwith "I see no motive!"
        val _ = if (holy phib) andalso
                   (Cfoldr (fn b => fn p => p orelse
                                              sameRef phib b) false C)
                then ()
                else failwith "I see no motive!"
        val phid = bid phib
        val (C,T) = on (C,T) [
                      voodom phid,
                      introall iota "i" 1,
                      domvoo phid
                    ]
        val (IC,IT) = (bCT phib)
        val Phib = noo (HoleBV,"Phi") ("Phi",1) (vooCopy (IC,IT))
        val Fb   = noo (HoleBV,"F") ("F",1) (vooCopy (IC,IT))
        val (LIC,(zap,paz)) = copyCtxt ldify IC
        val (aa,vv) = ArgsAndVis iota LIC
        val SigT = Bind ((Sig,Vis),"phi",MkApp ((Ref Phib,aa),vv),
                                         MkApp ((Ref Fb,aa),vv))
        val (phiHoles,_) = Cfilter ((isBFam phib) o ref_typ) (tl (tl C))
        val S = (phid \ (LIC@[Fb,Phib],SigT)) (C,T)
        val sols = map (fn b =>
                       let val id as (_,j) = bid b
                           val (HC,HT) = introtestall
                                         (fn Bind ((Pi,_),_,_,_) => true
                                           | _ => false)
                                         iota "x" 1 ([],ref_typ b)
                           val (ha,hv) = ArgsAndVis iota HC
                           val (_,aa,vv) = case HT
                                  of Bind ((Sig,_),_,_,r) => parseApp r
                                   | _ => bug "splitMotive"
                           val (HPC,(pzap,ppaz)) = copyCtxt iota HC
                           val hpb = noo (HoleBV,"phi") ("phi",j)
                                       (HPC,pzap %>> MkApp ((Ref Phib,aa),vv))
                           val (HFC,(fzap,fpaz)) = copyCtxt iota HC
                           val hfb = noo (HoleBV,"f") ("f",j)
                                       (HPC,fzap %>> MkApp ((Ref Fb,aa),vv))
                           val sol = $!(map ldify HC,
                                        MkTuple (HT,[MkApp ((Ref hpb,ha),hv),
                                                     MkApp ((Ref hfb,ha),hv)]))
                       in (id \ ([hfb,hpb],sol))
                       end
                      ) phiHoles
        val S = on S sols
        val S = domvoo g S
    in (S,2)
    end
  | splitMotive rv n i (S,p) (g,_) = (S,p+1)

(***************************************
fun novOneElim (S,i) (rvt as (rv,_),gtargs) =
    let val S = foldl (fn S => fn (g,tgVTs) => novTarget rvt g tgVTs S)
                      S gtargs
        val n = length gtargs
        val (S,_) = foldl (splitMotive rv n i) (S,1) gtargs
    in (S,i+n)
    end
****************************************)


fun novOneElim (S,i) (rvt as (rv,_),gtargs) =
    let val (S,i) = foldl (fn (S,i) => fn (g,tgVTs) =>
                    let val tgVs = map fst tgVTs
                        val S = octElim g rv tgVs S
                        val (sgs,_) = filter (hasName "subgoal") (fst S)
                        val S = vooRename [(("subgoal",0),("sg",i))] S
                    in (S,i+(length sgs))
                    end) (S,i) gtargs
    in (S,i)
    end

val mergeMotives = iota

fun novElim plan after S =
    let val _ = Tgb := unRef (Supply ["Target"])
        val _ = Ton := Supply ["Target","on"]
        val (S,i) = foldl novOneElim (S,1) plan
        val S = mergeMotives S
        val S = after S
    in  S
    end

val unifyAfter = ref (iota : (binding list * cnstr) -> (binding list * cnstr))

val elimBox = ref ([] : (cnstr_c * ((int * (cnstr_c list)) list)) list)

fun legoNovElim (elims : 
                 (cnstr_c * ((int * (cnstr_c list)) list)) list) =
    let val _ = elimBox := elims (* for debugging purposes *)
        val LEGOC = fst (start Prop)
        fun findGoalAndTargets (i,tgs_c) =
            let val (gn,gT) = Synt.goaln i
                val (GC,GT) = introall iota "h" 1 ([],gT)
                val TGC = GC@LEGOC
                val tgVTs = map (fEvalCxt TGC) tgs_c
                val si = string_of_num gn
                val ngb = noo (HoleBV,"g"^si) ("g",gn) (GC,GT)
                val nlb = noo ((Let,Def),"lego"^si) ("lego",gn) ([],Ref ngb)
            in (gn,(ngb,nlb),tgVTs)
            end
        val Elims = map (fEval ** (map findGoalAndTargets)) elims
        val (s,C) = foldr (fn (_,ls) => fn sC =>
                      foldr
                      (fn (gn,(ngb,nlb),_) => fn (s,C) =>
                       ((gn,Ref nlb)::s,nlb::ngb::C))
                      sC ls)
                    ([],[]) Elims
        val S = (vootopsort**iota) (s $>>> (C,Prop))
        val plan = map (iota**
                        map (fn (gn,_,tgVTs) => (("g",gn),tgVTs)))
                   Elims
        val S = novElim plan (!unifyAfter) S
        val _ = vooprintstate S
    in  claimHolesSolveGoals [] (map (fn (i,_,_) => i)) S
    end

(*
val _ = ConorTools.NovElim := legoNovElim
val _ = Tgb := unRef (Supply ["Target"])
val _ = Ton := Supply ["Target","on"]
*)
