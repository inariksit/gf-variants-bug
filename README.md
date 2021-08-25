# gf-variants-bug

Example grammars to trigger a bug in GF compiler (see [issue 132](https://github.com/GrammaticalFramework/gf-core/issues/132)).

Tested with GF 3.11 and GF 3.10 (from December 2018), both have the bug.

## Grammars

### Abstract: [TestVariants.gf](TestVariants.gf)

```haskell
abstract TestVariants = {
  cat
    S ; Subj ; Pred ;
  fun
    PredVP : Subj -> Pred -> S ;
    cat_Subj : Subj ;
    doesnt_sit_Pred : Pred ;
}
```

### Concrete with bug: [TestVariantsBugEng.gf](TestVariantsBugEng.gf)

The category Pred is linearised to `ExtendEng.VPS`, like this.

```haskell
    Pred = ExtendEng.VPS ;
```

In addition, we have an `oper` that allows both contracted and uncontracted negation.

```haskell
  oper
    PNegInlineVariants : Pol = lin Pol {s = [] ; p = ResEng.CNeg (True|False)} ;
```

The issue comes in the linearisation of `doesnt_sit_Pred`, which is defined as follows.

```haskell
  lin
    doesnt_sit_Pred =
      let temp : Temp = mkTemp pastTense simultaneousAnt ;
          vp   : VP   = mkVP sit_V ;
       in ExtendEng.MkVPS temp PNegInlineVariants vp ;
```

However, this version of the same grammar compiles just fine. It's still using variants, but now they are not on the level of params, but rather the whole record.

```haskell
  oper
    PNegTopVariants  : Pol = lin Pol ( {s = [] ; p = R.CNeg True }
                                     | {s = [] ; p = R.CNeg False}
                                     ) ;
  lin
    doesnt_sit_Pred =
      let temp : Temp = mkTemp pastTense simultaneousAnt ;
          vp   : VP   = mkVP sit_V ;
       in ExtendEng.MkVPS temp PNegTopVariants vp ;
```

## The bug

When I try to compile the code that uses `PNegInlineVariants`, it gets stuck at `doesnt_sit_Pred`.

```
$ gf -v TestVariantsBugEng.gf
…
- parsing TestVariantsBugEng.gf
  renaming
  type checking
  optimizing  PNegInlineVariants
 doesnt_sit_Pred
 cat_Subj
 Subj
 S
 PredVP
 Pred
 PNegTopVariants

  generating PMCFG
+ Pred 1
+ PredVP 10 (10,10)
+ S 1
+ Subj 10
+ cat_Subj 1 (1,1)
+ doesnt_sit_Pred 1
```

It is stuck there in what seems to be an infinite loop. I added debug output in [getFIds](https://github.com/inariksit/gf-core/blob/aed838acacf61a924b51f76a005911ae299a3d16/src/compiler/GF/Compile/GeneratePMCFG.hs#L313-L320), and this is what it spits out:

```
+ doesnt_sit_Pred 1
-------
getFIds
Pred
1 Pred
CRec [LIdent (Id {rawId2utf8 = "s"}),LIdent (Id {rawId2utf8 = "lock_VPS"})]
-------
getFIds.variants: found a record
getFIds.variants: found a table Order
getFIds.variants: found a table Agr
getFIds.variants: found a record
getFIds.variants: recursion ended on string 0
getFIds.variants: recursion ended on string 1
getFIds.variants: found a record
…
getFIds.variants: recursion ended on string 58
getFIds.variants: recursion ended on string 59
getFIds.variants: found a record

-------
getFIds
Pred
1 Pred
CRec [LIdent (Id {rawId2utf8 = "s"}),LIdent (Id {rawId2utf8 = "lock_VPS"})]
-------
getFIds.variants: found a record
getFIds.variants: found a table Order
getFIds.variants: found a table Agr
getFIds.variants: found a record
getFIds.variants: recursion ended on string 0
getFIds.variants: recursion ended on string 1


… more of the same until I press Ctrl+C
```

So there's something that calls `getFIds` over and over again, the subfunction `getFIds.variants` ends every time. This is the stack trace from when I pressed Ctrl+C: `getFIds` is called most immediately from `GeneratePMCFG.addPMCFG.addRule`, but that doesn't mean the looping happens there–there are many other functions where I didn't put debug output.

```
*** Exception (reporting due to +RTS -xc): (base:GHC.Exception.Type.SomeException), stack trace:
  GF.Compile.GeneratePMCFG.getFIds.variants,
  called from GF.Compile.GeneratePMCFG.getFIds,
  called from GF.Compile.GeneratePMCFG.addPMCFG.addRule.(...),
  called from GF.Compile.GeneratePMCFG.addPMCFG.addRule,
  called from GF.Data.BacktrackM.return.\,
  called from GF.Data.BacktrackM.return,
  called from GF.Data.BacktrackM.>>=.\.\,
  called from GF.Data.BacktrackM.member.\.\,
  called from GF.Data.BacktrackM.member.\,
  called from GF.Data.BacktrackM.member,
  called from GF.Data.BacktrackM.>>=.\,
  called from GF.Data.BacktrackM.>>=,
  called from GF.Compile.GeneratePMCFG.goV,
  called from GF.Compile.GeneratePMCFG.goB,
  called from GF.Data.BacktrackM.foldBM,
  called from GF.Compile.GeneratePMCFG.addPMCFG.pmcfgEnv1,
  called from GF.Compile.GeneratePMCFG.addPMCFG,
  called from GF.Compile.GeneratePMCFG.mapAccumWithKeyM.mapAccumM,
  called from GF.Compile.GeneratePMCFG.mapAccumWithKeyM,
  called from GF.Compile.GeneratePMCFG.generatePMCFG,
```

## Other observations

I tried to make a more minimal version of the grammar, that doesn't use the RGL, but has the same inline variants.

This grammar is at [TestVariantsNoRGLNoBug.gf](TestVariantsNoRGLNoBug.gf), I defined the parameters as follows:

```haskell
  param
    Bool = True | False ;
    CPolarity = CPos | CNeg Bool ;

  oper
    Pol : Type = {s : Str ; p : CPolarity} ;
    PNegInlineVariants : Pol = {s = [] ; p = CNeg (True|False)} ;
    PNegTopVariants    : Pol = {s = [] ; p = CNeg True } |
                               {s = [] ; p = CNeg False} ;
```

But when I use `PNegInlineVariants` in the linearisation of `doesnt_sit_Pred`, it compiles happily.
