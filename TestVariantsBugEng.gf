concrete TestVariantsBugEng of TestVariants = open SyntaxEng, ParadigmsEng, LexiconEng, (R=ResEng), Prelude, ExtendEng in {
  lincat
    S = SyntaxEng.S ;
    Subj = SyntaxEng.NP ;
    Pred = ExtendEng.VPS ;

  lin
    PredVP np vp = PredVPS np vp ;
    cat_Subj = mkNP the_Det cat_N ;
    doesnt_sit_Pred =
      let temp : Temp = mkTemp pastTense simultaneousAnt ;
          vp : SyntaxEng.VP = mkVP sit_V ;
       in MkVPS temp PNegInlineVariants vp ;  -- freezes
--       in MkVPS temp PNegTopVariants vp ;   -- works great

  oper
    PNegInlineVariants : Pol = lin Pol {s = [] ; p = R.CNeg (True|False)} ;
    PNegTopVariants  : Pol = lin Pol ( {s = [] ; p = R.CNeg True }
                                     | {s = [] ; p = R.CNeg False}
                                     ) ;
}