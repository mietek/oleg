fun Thud () = raise RequireFailure

fun vooIndCasesDemon (tag as [iType,"cases"]) =
   (let val elim = Supply [iType,"elim"]
        val elimType = type_of_constr elim
        val (elimPref,elimTail) =
            parselim ([],Prop)
                     {A="b",EQN="eqn",H="i",ITER="die",P="q",Y="z",
                      PHI="Psi",SUBGOAL="case",PRED="pre"}
                     elimType
        val Psid = tid (#1 (parseApp elimTail))
        val (elimReducedPref,targId) = vooctxtrec
            {hitBot = fn C => (C,b42),
             hitDom = voocontinue,
             hitVoo = fn (id as (s,i),(dc,dt)) => fn b => fn _ => fn rect =>
                     (case s
                        of "Psi" => if id=Psid then (cons b)**iota else iota
                         | "case" =>
                           if (tid (#1 (parseApp dt)))=Psid
                           then let val (_,dc') =
                                        filter (fn b => (#1 (bid b))="die") dc
                                in  (cons (noo ((Pi,Vis),"") ("case",i)
                                               (dc',dt)))**iota
                                end
                           else iota
                         | _ => (cons b)**(const (bid b))) (rect ())} elimPref
        val theGoal = (elimReducedPref,elimTail)
 (*     val theGoal = (let val Tg = Supply ["Target"]
                           val zb = hd elimReducedPref
                           val tgb = noo ((Pi,Vis),"targ") ("tg",1)
                                     ([],MkApp ((Tg,[ref_typ zb,Ref zb]),
                                               [NoShow,ShowNorm]))
                       in (tgb::elimReducedPref,elimTail)
                       end handle _ => theGoal)  *)
        val trueProp = ([],?"{P|Prop}P->P")
        val trueProof = ([],?"[P|Prop][p:P]p")
        fun solvePhi i S = on S     (* dispose of spare Phis for mut ind *)
            [vooattack ("Phi",i) ("hole",1),
             vooIntroTac ("hole",1),
             ("hole",1) \ trueProp, (* should be pretty easy to prove *)
             vookcatta ("Phi",i)]
        fun solveSubg i S =
            let val S' = on S [vooattack ("subgoal",i) ("trick",1),
                               vooIntroTac ("trick",1)]
                val ob = SOME (fetch S' ("case",i)) (* may not be there *)
                         handle missing_voodoo => NONE
            in  case ob
                  of NONE => on S' [("trick",1) \ trueProof,
                                    vookcatta ("subgoal",i)]
                   | SOME b =>
                let val binfo = case ref_kind b
                                  of Voo (_,(C,_)) => C
                                   | _ => Thud ()
                    val (aa,vv) = ArgsAndVis
                                  (fn t => case tid t
                                             of ("pre",i) => vid S' ("pred",i)
                                              | _ => Thud ())
                                  binfo
                in  on S' [("trick",1) \ ([],MkApp ((Ref b,aa),vv)),
                           vooetastate,
                           vookcatta ("subgoal",i)]
                end
            end
        val CASES = on theGoal
            [vooGoal [("type",1),("cases",1),("reds",1)] ("goal",1),
             Elim MinimalStrat elim [("goal",1),targId,("reds",1)],
             vooSubSequence "Phi" solvePhi,
             vooSubSequence "subgoal" solveSubg]
    in  vooQED [("type",1),("cases",1),("reds",1)] tag CASES
    end
    handle _ => Thud ())
  | vooIndCasesDemon _ = Thud ()

(*
val _ = vooDemons:=[vooDemon,vooEqJDemon,vooDepSubstDemon,vooLinTriRespDemon,
                    vooSpecialKDemon]
*)val _ = addVooDemon vooIndCasesDemon
(**)

fun vooIndNoConfStmtDemon (tag as [iType,"no","confusion","statement"]) =
   (let val (cases,casesType) = Require [iType,"cases"]
        val (casesPref,casesTail) = parselim ([],Prop) usualElimNames casesType
        val (pPref,xPref,targ) = vooctxtrec
            {hitBot = fn _ => ([],[],0), hitDom = voocontinue,
             hitVoo = fn ((s,_),_) => fn b => fn _ => fn rect =>
                      let val rr as (ff,vv,i) = rect ()
                          val j=i+1
                      in  case s
                            of "p" => if vv=[] then ((anon b)::ff,[],0)
                                      else (ff,(newid ("x",j) (anon b))::vv,j)
                             | "y" => (ff,(newid ("x",j) (anon b))::vv,j)
                             | _ => rr
                      end} casesPref
        val (yPref,_) = copyCtxt (vNam "y") xPref
        val LT = linearTriangular yPref
        val _ = case LT
                  of ([],_) => ()
                   | ([_],[]) => ()
                   | _ => Thud ()
        val Ts = (op @) LT
        val (xs,vs) = ArgsAndVis iota xPref
        val (ys,vs) = ArgsAndVis iota yPref
        val exyPref = buildLinTriEqs "exy" 1 LT xs ys
        val theGoal = (exyPref@yPref@xPref@pPref,?"Type")
        val xtarg = vid theGoal ("x",targ)
        val XNAMES = {A="a",EQN="eqn",H="h",ITER="surprise",P="p",PHI="Phi",
                      PRED="xp",SUBGOAL="xcase",Y="y"}
        val YNAMES = {A="a",EQN="eqn",H="h",ITER="surprise",P="p",PHI="Phi",
                      PRED="yp",SUBGOAL="ycase",Y="y"}
        val daft = ([],?"{Any:Type}Any")
        fun solvexycase xi yj S =
            if xi=yj (* on the diagonal? *)
            then let val pis = case ref_kind (fetch S ("ycase",yj))
                                 of Voo (_,(dc,_)) => dc
                                  | _ => Thud ()
                     val (eqns,others) = filter (isItA "exy") pis
                     val PhiTy = $!(eqns,?"Type")
                     val S' = on S [vooattack ("ycase",yj) ("hole",1),
                                    vooIntroTac ("hole",1)]
                     val (xpPref,others) = filter (isItA "xp") others
                     val (ypPref,others) = filter (isItA "yp") others
                     val (xps,pvs) = ArgsAndVis iota xpPref
                     val (yps,pvs) = ArgsAndVis iota ypPref
                     val PLT = linearTriangular ypPref
                     val As = (op @) PLT
                     val Avs = map (const NoShow) As
                     val (lin,tri) = (length**length) PLT
                     fun ltr r = Req ["lin",string_of_num lin,
                                      "tri",string_of_num tri,
                                      "resp",string_of_num r]
                     val ePref = buildLinTriEqs "e" 1 PLT xps yps
                     val (es,evs) = ArgsAndVis iota ePref
                     val (eqs,_) = ArgsAndVis iota eqns
                     val fs = map (fn t =>
                                   case type_of_constr t
                                     of App ((_,[_,_,r]),_) =>
                                        $!(vooetastate (ypPref,r))
                                      | _ => Thud ()) eqs
                     val phiArgs =
                         if (length As)=0
                         then
                         let val eqr = ?"%Eq refl%"
                         in  map (fn f => App ((eqr,[type_of_constr f,f]),
                                                    [NoShow,ShowNorm])) fs
                         end else
                         let val ltAxyes = splice iota [As,xps,yps,es] []
                             val NSs = map (const NoShow) As
                             val SNs = map (const ShowNorm) As
                             val ltvis = splice iota [NSs,NSs,NSs,SNs] []
                             fun nastEqs i (hT::tT) (hf::tf) aa vv =
                                 let val aa = aa@[hT,hf]
                                     val vv = vv@[NoShow,ShowNorm]
                                 in  (MkApp ((ltr i,aa),vv))::
                                     (nastEqs (i+1) tT tf aa vv)
                                 end
                               | nastEqs _ _ _ _ _ = []
                         in   nastEqs 1 Ts fs ltAxyes ltvis
                         end
                     val phiVis = map (const ShowNorm) phiArgs
                     val PhiB = noo ((Pi,Vis),"") ("Phi",1) ([],PhiTy)
                     val HypB = noo ((Pi,Vis),"") ("Hyp",1)
                                (ePref,MkApp ((Ref PhiB,phiArgs),phiVis))
                     val conc = MkApp ((Ref PhiB,eqs),phiVis)
                 in  on S' [(("hole",1) \ ([HypB,PhiB],conc)),
                            vookcatta ("ycase",yj)]
                 end
            else on S [vooattack ("ycase",yj) ("hole",1),
                       vooIntroTac ("hole",1),
                       ("hole",1)\daft,
                       vookcatta ("ycase",yj)]
        fun solvexcase i S =
            let val ytarg = pick S ("xcase",i) ("y",targ)
            in  on S [Clobber MaximalStrat YNAMES cases
                              (("xcase",i),ytarg,SOME ("reds",1)),
                      vooSubSequence "ycase" (solvexycase i)]
            end
        val INCS = on theGoal
                   [vooGoal [("type",1),("incs",1),("reds",1)] ("goal",1),
                    Clobber MaximalStrat XNAMES cases
                            (("goal",1),xtarg,SOME ("reds",1)),
                    vooSubSequence "xcase" solvexcase]
    in  vooQED [("type",1),("incs",1),("reds",1)] tag INCS
    end
    handle _ => Thud ())
   | vooIndNoConfStmtDemon _ = Thud ()

val _ = addVooDemon vooIndNoConfStmtDemon

fun vooNoConfDemon (tag as [iType,"no","confusion"]) =
   (let val (stmt,stmtType) = Require [iType,"no","confusion","statement"]
        val (stmtPref,_) = introall iota "z" 1 (start stmtType)
        val (lastE,lastY) =
            case ref_kind (hd stmtPref)
              of Voo ((_,d),(_,App ((_,[_,_,r]),_))) => (d,#2 (tid r))
               | _ => Thud ()
        val dep = lastE-lastY
        val params = lastE-3*dep
        val (paramPref,rest) = intromangvool anon ["p"] 1 params 
                               (start stmtType)
        val (xPref,rest) =     intromangvool anon ["x"] 1 dep ([],rest)
        val (yPref,rest) =     intromangvool anon ["y"] 1 dep ([],rest)
        val (exyPref,_) =      intromangvool anon ["exy"] 1 dep ([],rest)
        val (aa,vv) = ArgsAndVis iota (exyPref@yPref@xPref@paramPref)
        val thePref = splice iota [exyPref,yPref,xPref] paramPref
        val theGoal = (thePref,MkApp ((stmt,aa),vv))

        val Eq_J = ?"%Eq J%"
        val eqr = ?"%Eq refl%"
        val cases = Req [iType,"cases"]
        fun hitEq i = Elim MaximalStrat Eq_J
                           [("subgoal",1),("exy",i),("reds",1)]
        fun solve i S = 
            let val S' = on S
                         [voodom ("subgoal",i),
                          introvool ["Phi","Hyp"] 1 1,
                          voodom ("Hyp",1),
                          introall iota "e" 1]
                val (aa,vv) = ArgsAndVis
                    (fn c => (case type_of_constr c
                                of App ((_,[t,_,x]),_) =>
                                   App ((eqr,[t,x]),[NoShow,ShowNorm])
                                 | _ => Thud() )) (#1 S')
            in  on S'
                [domvoo ("Hyp",1),
                 domvoo ("subgoal",i),
                 vooattack ("subgoal",i) ("spot",1),
                 vooIntroTac ("spot",1),vps,
                 fn S => vooRefineTac ("spot",1) ""
                         (MkApp ((vid S ("Hyp",1),aa),vv)) S,
                 vookcatta ("subgoal",i)]
            end

        val IDNC = on theGoal
                   [vooGoal [("type",1),("idnc",1),("reds",1)] ("subgoal",1),
                    vooForLoopTac hitEq 1 dep,
                    Elim MaximalStrat cases
                         [("subgoal",1),("x",dep),("reds",1)],
                    vooSubSequence "subgoal" solve]
    in  vooQED [("type",1),("idnc",1),("reds",1)] tag IDNC
    end
    handle _ => Thud ())
  | vooNoConfDemon _ = Thud ()

val _ = addVooDemon vooNoConfDemon

(*

fun vooAuxDemon (tag as [iType,"aux"]) =
   (let val (elim,elimTy) = Require [iType,"elim"]
        val (ELIMC,ELIMT) = parselim ([],Prop) usualElimNames elimTy
        val {P,PHI,SUBGOAL,Y,PRED,ITER,A,H,EQN} = usualElimNames
        val UNIT = ?"%unit%"
        fun cross X Y = if sameTerm Y UNIT then X
                        else Bind ((Sig,Vis),"p",X,Y)

        val (LDAS,_) = copyCtxt ldify ELIMC

        fun subgBlat C =
            let val (C',_) = copyCtxt ldify C
                val (C',T') = vooctxtrec
                    {hitBot = fn _ => fn ty => ([],ty),
                     hitDom = voocontinue,
                     hitVoo = fn ((s,i),(c,t)) => fn b => fn _ => fn rect =>
                              fn ty =>
                              let val (bv,nam,_,_) = ref_bd b
                                  val (C',T') = rect ()
                                  (if s=ITER
                                   then let val (aa,vv) = ArgsAndVis iota c
                                            val t' = Bind ((Sig,Vis),"aux",
                                                     MkApp ((Ref b,aa),vv),t)
                                        in  cross ($!(c,t')) ty
                                        end
                                   else ty)
                                  val b = if s=ITER
                                          then let val t' = ?"Type"
                                                   val ct' = $!(c,t')
                                                   val ctt = type_of_constr ct'
                                               in  (b<:(bv,nam,ct',ctt))
                                                   <!(Voo ((s,i),(c,t')))
                                               end
                                          else b
                              in  (b::C',T')
                              end} C' UNIT
            in  $!(C',T')
            end

        val (aa,vv) = vooctxtrec
                     {hitBot = const iota, hitDom = voocontinue,
                      hitVoo = fn ((s,i),(C,T)) => fn b => fn _ => fn rect =>
                               (rect ()) o 
                               ((cons 
                                 (if s=PHI
                                  then $!(#1 (copyCtxt ldify C),?"Type")
                                  else if s=SUBGOAL
                                  then subgBlat C
                                  else Ref b))
                                **
                                (cons (prVis (ref_vis b))))} LDAS ([],[])

        val backEnd = App ((elim,aa),vv)

        val (_,myLdas) = filter (fn b => (#1 (bid b))=SUBGOAL) LDAS

        val theProof = vooetastate (myLdas,backEnd)
        val theThm = ([],dnf (type_of_constr ($!theProof)))
    in  vooQED [("type",1),("iaux",1)] tag
               ([noo ((Let,Def),"type") ("type",1) theThm,
                 noo ((Let,Def),"iaux") ("iaux",1) theProof],Prop)
    end
    handle _ => Thud ())
  | vooAuxDemon _ = Thud ()

val _ = addVooDemon vooAuxDemon

*)

fun vooAuxDemon (tag as [iType,"aux"]) =
   (let val (elim,elimTy) = Require [iType,"elim"]
        val (ELIMC,ELIMT) = parselim ([],Prop) usualElimNames elimTy
        val {P,PHI,SUBGOAL,Y,PRED,ITER,A,H,EQN} = usualElimNames
        val (mutPlan,goalBits) = vooctxtrec
            {hitBot = const ([],[]), hitDom = voocontinue,
             hitVoo = fn ((s,i),(C,T)) => fn _ => fn _ => fn rect =>
                     (if s=PHI
                      then let val tnam = ref_nam (unRef (#1 (parseApp
                                          (ref_typ (hd C)))))
                               val (el,elTy) = Require [tnam,"elim"]
                               val (elC,elT) = parselim ([],Prop)
                                               usualElimNames elTy
                               val (_,goC) = voofilter (isItA SUBGOAL) elC
                               val (vgc,_) =
                                   vooGoal [("type",i),("aux",i),("reds",i)]
                                            ("goal",i) (goC,?"Type")
                               val useful = case vgc
                                              of (a::b::c::d::_) => [a,b,c,d]
                                               | _ => failwith "human error"
                           in  (cons (tnam,el,
                                 (("goal",i),Ref (hd goC),SOME ("reds",i))))**
                               (cons useful)
                           end
                      else iota) (rect ())} ELIMC
        val bigGoal = (splice iota goalBits [],Prop)
        val (_,CLOBBED) = foldr
            (fn (_,rule,stuff) => fn (bits,S) =>
             let val (b',S') = holyClobber MinimalStrat usualElimNames false
                               rule stuff S
             in  (b'::bits,S')
             end) ([],bigGoal) mutPlan
        val (tyPhiLet,otherstuff) = voofilter (fn b => (isItA "type" b)
                                               orelse ((isItA PHI b)
                                                andalso ((ref_vis b)=Def)))
                                    (#1 CLOBBED)
        val (PhiLets,_) = voofilter (isItA PHI) tyPhiLet
        val _ = map (fn b => (ref_frz b) := Froz) PhiLets
        val FLAT = on (otherstuff@tyPhiLet,Prop)
                      [vooAssumption]
        val _ = map (fn b => (ref_frz b) := UnFroz) PhiLets
        val FOLDS = map (fn b => vooFoldRew (Ref b) (bCT b))
                    (#1 (voofilter (isItA "aux") (#1 FLAT)))
        fun foldem D = foldr (fn rew => fn D => rew>>>D) D FOLDS
        val FOLDED = vooctxtrec
                    {hitBot = const FLAT, hitDom = voocontinue,
                     hitVoo = fn (id as (s,i),D) => fn b => fn t => fn rect =>
                              if s="reds"
                              then ((b<!(Voo (id,foldem D)));(rect ()))
                              else FLAT} (#1 FLAT)
        fun PhiLetMang b aa vv =
            let val (C,T) = bCT b
                val tnam = ref_nam (unRef (#1 (parseApp
                                          (ref_typ (hd C)))))
                val (f,aa,vv,_,_) = vooctxtrec
                    {hitBot = const (Bot,[],[],aa,vv), hitDom = voocontinue,
                     hitVoo = fn ((s,i),(dc,dt)) => fn b => fn _ => fn rect =>
                              let val (f,aa,vv,oaa,ovv) = rect ()
                                  val (oah,oat) = case oaa of [] => Thud ()
                                                            | (h::t) => (h,t)
                                  val (ovh,ovt) = case ovv of [] => Thud ()
                                                            | (h::t) => (h,t)
                              in  if s=PHI
                                  then let val snam = ref_nam (unRef (#1
                                                      (parseApp
                                                      (ref_typ (hd dc)))))
                                           val f = if snam=tnam then oah
                                                   else f
                                       in  (f,aa,vv,oat,ovt)
                                       end 
                                  else (f,aa@[oah],vv@[ovh],oat,ovt)
                              end} C
                val _ = case f of Bot => Thud () | _ => ()
            in  MkApp ((f,aa),vv)
            end
        val UNIT = ?"%unit%"
        fun cross X Y = if sameTerm Y UNIT then X
                        else Bind ((Sig,Vis),"p",X,Y)
        fun hitSubg subg S =
            let val S = on S
                       [vooattack subg ("czernik",1),
                        vooIntroTac ("czernik",1)]
                val theType = vooctxtrec
                   {hitBot = fn _ => iota,
                    hitDom = fn _ => fn _ => fn _ => fn _ => iota,
                    hitVoo = fn ((s,i),(c,t)) => fn b => fn _ => fn rect =>
                             fn ty => rect ()
                             (if s=ITER
                              then let val (iaa,ivv) = ArgsAndVis iota c
                                       val (f,aa,vv) = parseApp t
                                       val phi = PhiLetMang (unRef f) aa vv
                                       val t' = Bind ((Sig,Vis),"aux",
                                                MkApp ((Ref b,iaa),ivv),phi)
                                   in  cross ($!(c,t')) ty
                                   end
                              else ty)} (#1 S) UNIT
            in  on S
               [vooSolve true ("czernik",1) ([],theType), (* mystery loop *)
                domvoo subg,        (* something to do with univ checking *)
                fn S => vooSolve true subg (S ?! subg) S]
            end
        val SUBGSDONE = foldr (fn b => fn S => hitSubg (bid b) S) FOLDED
                              (#1 (voofilter (isItA SUBGOAL) (#1 FOLDED)))
        val PHISIN = foldr (fn b => fn S => voosubdef (bid b) S) SUBGSDONE
                     PhiLets
        val QEDinfo = map (fn (s,_,((_,i),_,_)) =>
                           ([("type",i),("aux",i),("reds",i)],[s,"aux"]))
                          mutPlan
        val _ = vooQEDlist QEDinfo PHISIN
    in  Require tag
    end
    handle _ => Thud ())
  | vooAuxDemon _ = Thud ()

val _ = addVooDemon vooAuxDemon

(*
fun vooGenDemon (tag as [iType,"gen"]) =
   (let val (elim,elimTy) = Require [iType,"elim"]
        val (ELIMC,ELIMT) = parselim ([],Prop) usualElimNames elimTy
        val {P,PHI,SUBGOAL,Y,PRED,ITER,A,H,EQN} = usualElimNames
        val VOID = ?"%unit void%"
        val (aux,auxTy) = Require [iType,"aux"]
        val ((phiPref,midBits),targ) = vooctxtrec
            {hitBot = fn _ => raise missing_voodoo, hitDom = voocontinue,
             hitVoo = fn ((s,_),_) => fn b => fn t => fn rect =>
                      if s=PHI then ((b::t,[]),Bot)
                      else if s=P orelse s=Y
                      then ((iota**(cons b))**(const (Ref b))) (rect ())
                      else rect ()} ELIMC
        val (Aaa,Avv) = ArgsAndVis iota phiPref
        val (bodies,auxes,vises) = vooctxtrec
            {hitBot = fn _ => ([],[],[]), hitDom = voocontinue,
             hitVoo = fn ((s,i),(C,T)) => fn b => fn _ => fn rect =>
                      if s=PHI then
                      let val (bb,xx,vv) = rect ()
                          val (C',_) = copyCtxt iota C
                          val (Caa,Cvv) = ArgsAndVis iota C'
                          val A = Req [ref_nam (unRef (voohead
                                       (ref_typ (hd C')))),"aux"]
                          val x = App ((A,Aaa),Avv)
                          val xb = noo ((Pi,Vis),"aux") ("aux",1)
                                   ([],MkApp ((x,Caa),Cvv))
                          val tb = App ((Ref b,Caa),Cvv)
                          val b' = noo ((Pi,Vis),"bod") ("body",i)
                                       (xb::C',tb)
                      in  (b'::bb,xx@[x],vv@[prVis (ref_vis b)])
                      end else
                      let val (bb,xx,vv) = rect ()
                      in  (bb,xx@[Ref b],vv@[prVis (ref_vis b)])
                      end} phiPref
        val (_,Taa,Tvv) = parseApp ELIMT
        val T' = App ((aux,Aaa@Taa),Avv@Tvv)
        val theGoal = (midBits@bodies@phiPref,T')
        fun flesh ((s,i),b) =
            let val (C,T) = introall whnf s i (bCT b)
                val (s,i) = case C
                              of [] => (s,i)
                               | (h::_) => (iota**succ) (bid h)
                val (id,C') = vooctxtrec
                    {hitBot = fn _ => ((s,i),[]), hitDom = voocontinue,
                     hitVoo = fn _ => fn b' => fn _ => fn rect =>
                     if (ref_bind b')=Sig
                     then let val (id,C') = rect ()
                              val (id,b') = flesh (id,b')
                          in  (id,b'::C')
                          end
                     else (iota**(cons b')) (rect ())} C
            in  (id,b<!(Voo (bid b,(C',T))))
            end
        fun fleshEm (C,_) = vooctxtrec
           {hitBot = fn _ => [], hitDom = voocontinue,
            hitVoo = fn ((s,_),_) => fn b => fn _ => fn rect =>
                    (if s="subgoal"
                     then (cons (#2 (flesh (("x",1),b))))
                     else iota) (rect ())} C
        val IGEN = on theGoal
                  [vooGoal [("type",1),("igen",1)] ("goal",1),
                   vooattack ("goal",1) ("zob",1),
                   vooGenIntro false
                              (fn b => fn _ => (#1 (bid b))="body")
                              (fn b => fn f => f andalso (#1 (bid b))<>"body")
                              ("zob",1),
                   vooRefineTac ("zob",1) "subgoal" (App ((elim,auxes),vises)),
                   vooshove (noo ((Let,Def),"hint") ("hint",1) ([],VOID)),
                   fn S => prologSubHoles 5 (fleshEm S) S,
                   voosubdef ("hint",1),
                   vookcatta ("goal",1)]
    in  vooQED [("type",1),("igen",1)] tag IGEN
    end
    handle _ => Thud ())
  | vooGenDemon _ = Thud ()

val _ = addVooDemon vooGenDemon
*)

fun vooGenDemon (tag as [iType,"gen"]) =
   (let val (elim,elimTy) = Require [iType,"elim"]
        val (ELIMC,ELIMT) = parselim ([],Prop) usualElimNames elimTy
        val {P,PHI,SUBGOAL,Y,PRED,ITER,A,H,EQN} = usualElimNames
        val VOID = ?"%unit void%"
        val phiPref = vooctxtrec
            {hitBot = fn _ => const [], hitDom = voocontinue,
             hitVoo = fn ((s,_),_) => fn b => fn t => fn rect => fn flag =>
                      if s=PHI orelse flag then b::(rect () true) 
                      else rect () false} ELIMC false
        val (phAA,phVV) = ArgsAndVis iota phiPref
        fun mkZap C = #1 (vooctxtrec
           {hitBot = const (([],[]),phAA), hitDom = voocontinue,
            hitVoo = fn _ => fn b => fn _ => fn rect =>
                     case rect ()
                       of ((z,c),[]) => ((z,b::c),[])
                        | ((z,c),h::t) => (((b,h)::z,c),t)} C)
        val mutAlist = vooctxtrec
            {hitBot = const [], hitDom = voocontinue,
             hitVoo = fn ((s,i),(C,_)) => fn _ => fn _ => fn rect =>
                     (if s=PHI
                      then let val tnam = ref_nam (unRef (#1 (parseApp
                                          (ref_typ (hd C)))))
                               val (el,elTy) = Require [tnam,"elim"]
                               val (elC,elT) = parselim ([],Prop)
                                               usualElimNames elTy
                               val (_,noSGs) = voofilter (isItA SUBGOAL) elC
                               val (zap,indC) = mkZap noSGs
                               val (indC,elT) = zap%>>>(indC,elT)
                               val (iAA,iVV) = ArgsAndVis iota indC
                               val Aux = Req [tnam,"aux"]
                               val auxT = MkApp ((Aux,phAA@iAA),phVV@iVV)
                               val aux = noo ((Pi,Vis),"aux_"^tnam) ("aux",i)
                                             ([],auxT)
                               val bod = noo ((Pi,Vis),"body_"^tnam) ("body",i)
                                             (aux::indC,elT)
                           in  cons (tnam,(i,el,indC,auxT,bod))
                           end
                      else iota) (rect ())} phiPref
        val BODIES = map ((#5) o (#2)) mutAlist
        val (BODIES,_) = vooCopy (BODIES,Prop)
        val backend = BODIES@phiPref
        val (goalBits,clobBits) = foldr
            (fn (_,(i,el,indC,auxT,_)) =>
             let val goal as (C,T) = vooCopy (indC@backend,auxT)
                 val targ = Ref (hd C)
                 val bits = case (vooGoal [("type",i),("gen",i),("reds",i)]
                                          ("goal",i) goal)
                              of (a::b::c::d::_,_) => [a,b,c,d]
                               | _ => failwith "pear-shaped"
                 val clob = (el,(("goal",i),targ,SOME ("reds",i)))
             in (cons bits)**(cons clob)
             end) ([],[]) mutAlist
        val GOAL = (splice iota goalBits [],Prop)
        val (_,CLOBBED) = foldr
            (fn (rule,stuff) => fn (bits,S) =>
             let val (b',S') = holyClobber MinimalStrat usualElimNames false
                               rule stuff S
             in  (b'::bits,S')
             end) ([],GOAL) clobBits
        val (tyPhiLet,otherstuff) = voofilter (fn b => (isItA "type" b)
                                               orelse ((isItA PHI b)
                                                andalso ((ref_vis b)=Def)))
                                    (#1 CLOBBED)
        val (PhiLets,_) = voofilter (isItA PHI) tyPhiLet
        val _ = map (fn b => (ref_frz b) := Froz) PhiLets
        val FLAT = on (otherstuff@tyPhiLet,Prop)
                      [vooAssumption]
        val _ = map (fn b => (ref_frz b) := UnFroz) PhiLets
        val FOLDS = map (fn b => vooFoldRew (Ref b) (bCT b))
                    (#1 (voofilter (isItA "gen") (#1 FLAT)))
        fun foldem D = foldr (fn rew => fn D => rew>>>D) D FOLDS
        val FOLDED = vooctxtrec
                    {hitBot = const FLAT, hitDom = voocontinue,
                     hitVoo = fn (id as (s,i),D) => fn b => fn t => fn rect =>
                              if s="reds"
                              then ((b<!(Voo (id,foldem D)));(rect ()))
                              else FLAT} (#1 FLAT)
        val PHISIN = foldr (fn b => fn S => voosubdef (bid b) S) FOLDED
                     PhiLets
        fun flesh ((s,i),b) =
            let val (C,T) = introall whnf s i (bCT b)
                val (s,i) = case C
                              of [] => (s,i)
                               | (h::_) => (iota**succ) (bid h)
                val (id,C') = vooctxtrec
                    {hitBot = fn _ => ((s,i),[]), hitDom = voocontinue,
                     hitVoo = fn _ => fn b' => fn _ => fn rect =>
                     if (ref_bind b')=Sig
                     then let val (id,C') = rect ()
                              val (id,b') = flesh (id,b')
                          in  (id,b'::C')
                          end
                     else (iota**(cons b')) (rect ())} C
            in  (id,b<!(Voo (bid b,(C',T))))
            end
        fun fleshEm (C,_) = vooctxtrec
           {hitBot = fn _ => [], hitDom = voocontinue,
            hitVoo = fn ((s,_),_) => fn b => fn _ => fn rect =>
                    (if s="subgoal"
                     then (cons (#2 (flesh (("x",1),b))))
                     else iota) (rect ())} C
        val subgC = fleshEm PHISIN
        val SOLVED = on PHISIN
                    [vooshove (noo ((Let,Def),"hint") ("hint",1) ([],VOID)),
                     prologSubHoles 5 subgC,
                     voosubdef ("hint",1)]
        val QEDinfo = map (fn (s,(i,_,_,_,_)) =>
                           ([("type",i),("gen",i),("reds",i)],[s,"gen"]))
                          mutAlist
        val _ = vooQEDlist QEDinfo SOLVED
    in  Require tag
    end
    handle _ => Thud ())
  | vooGenDemon _ = Thud ()

val _ = addVooDemon vooGenDemon

fun vooPlanDemon (tag as [iType,"plan"]) =
   (let val (_,casesTy) = Require [iType,"cases"]
        val (CASESC,CASEST) = parselim ([],Prop) usualElimNames casesTy
        val {P,PHI,SUBGOAL,Y,PRED,ITER,A,H,EQN} = usualElimNames
        val (phiPref,midBits) = vooctxtrec
            {hitBot = fn _ => ([],[]), hitDom = voocontinue,
             hitVoo = fn ((s,_),_) => fn b => fn t => fn rect =>
                      let val (pp,mb) = rect ()
                      in  if s=PHI then ((ldify b)::mb,[])
                          else if s=P orelse s=Y
                          then (pp,(ldify b)::mb)
                          else (pp,mb)
                      end} CASESC
        val Auxb = noo ((Lda,Vis),"Aux") ("Aux",1) (vooCopy (bCT (hd phiPref)))
        val (phi,aa,vv) = parseApp CASEST
        val (GC,(zap,_)) = copyCtxt pify midBits
        val Aapp = MkApp ((Ref Auxb,aa),vv)
        val genb = noo ((Lda,Vis),"gen") ("gen",1) (GC,zap%>>Aapp)
        val (PC1,(zap,_)) = copyCtxt pify midBits
        val auxb = noo ((Pi,Vis),"aux") ("aux",1) ([],zap%>>Aapp)
        val projb = noo ((Lda,Vis),"proj") ("proj",1)
                        (auxb::PC1,zap%>>CASEST)
        val trick = App ((Ref projb,aa@[App ((Ref genb,aa),vv)]),
                                    vv@[ShowNorm])
        val theProof = (midBits@(genb::projb::Auxb::phiPref),trick)
    in  vooQED [("type",1),("iplan",1)] tag
               ([noo ((Let,Def),"type") ("type",1)
                     ([],type_of_constr ($!theProof)),
                 noo ((Let,Def),"plan") ("iplan",1) theProof],Prop)
    end
    handle _ => Thud ())
  | vooPlanDemon _ = Thud ()

val _ = addVooDemon vooPlanDemon

fun vooEduardoDemon (tag as [iType,"eduardo"]) =
   (let val (_,casesTy) = Require [iType,"cases"]
        val (CASESC,CASEST) = parselim ([],Prop) usualElimNames casesTy
        val {P,PHI,SUBGOAL,Y,PRED,ITER,A,H,EQN} = usualElimNames
        val subgsGone = vooctxtrec
           {hitBot = const [], hitDom = voocontinue,
            hitVoo = fn ((s,_),_) => fn b => fn _ => fn rect =>
                    (if s=SUBGOAL then iota else cons b) (rect ())} CASESC
        val someHoles = map pihole subgsGone
        val (gen,genTy) = Require [iType,"gen"]
        val (genC,_) = introall iota "g" 1 ([],genTy)
        val FRAME = (someHoles@genC,CASEST)
        val GOAL = vooAssumption FRAME
        val (aa,vv) = ArgsAndVis iota genC
        val hint = noo ((Let,Def),"hint") ("hint",1) ([],MkApp ((gen,aa),vv))
        val IED = on (vooGoal [("type",1),("ied",1)] ("goal",1) GOAL)
                 [vooattack ("goal",1) ("zob",1),
                  vooIntroTac ("zob",1),
                  vooshove hint,
                  prologTopHole 3,
                  voosubdef ("hint",1),
                  vookcatta ("goal",1)]
    in  vooQED [("type",1),("ied",1)] tag IED
    end
    handle _ => Thud ())
  | vooEduardoDemon _ = Thud ()

val _ = addVooDemon vooEduardoDemon
