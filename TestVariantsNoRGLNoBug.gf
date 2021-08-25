concrete TestVariantsNoRGLNoBug of TestVariants = {

  lin
    PredVP np vp = {s = np.s ++ vp.s} ;
    cat_Subj = {s = "the cat"} ;

    doesnt_sit_Pred = {s = sit_V.s ! PNegTopVariants.p} ;
    {- -- Both of these work too! I am unable to introduce the bug here.
    doesnt_sit_Pred = {s = sit_V.s ! PNegInlineVariants.p} ;
    doesnt_sit_Pred = {s = sit_V.s ! CNeg (True|False)} ; --}

  param
    Bool = True | False ;
    CPolarity = CPos | CNeg Bool ;

  oper
    Pol : Type = {s : Str ; p : CPolarity} ;
    PNegInlineVariants : Pol = {s = [] ; p = CNeg (True|False)} ;
    PNegTopVariants    : Pol = {s = [] ; p = CNeg True } |
                        {s = [] ; p = CNeg False} ;

    V : Type = {s : CPolarity => Str} ;
    sit_V : V = {
      s = table {
        CPos => "sits" ;
        CNeg True => "doesn't sit" ;
        CNeg False => "does not sit"
      }
    } ;

}