(* :Title: 	NCSimplifyRational *)

(* :Author: 	mauricio. *)

(* :Context: 	NCSimplifyRational` *)

(* :Summary:
*)

(* :Alias:
*)

(* :Warnings: 
*)

(* :History:
*)

BeginPackage[ "NCSimplifyRational`",
              "NCSubstitute`",
              "NCCollect`",
              "NCPolynomial`",
              "NCUtil`",
              "NonCommutativeMultiply`" ];

Clear[NCNormalizeInverse, 
      NCSimplifyRational, 
      NCSimplifyRationalSinglePass];

Get["NCSimplifyRational.usage"];

Begin["`Private`"]

  Clear[ninv];
  NCNormalizeInverse[expr__] :=
    (((expr //. inv[x_] -> ninv[0, x]) 
            //. (ninv[a_, b__?CommutativeQ + c_] -> 
                       ninv[1, c/(a+Times[b])]/(a+Times[b])))
            //. ninv[a_, x_] -> inv[a + x])

  Clear[NCSimplifyRationalRules];
  Clear[a,b,c,d,e,K];
  SetCommutative[K];
  SetNonCommutative[a,b,c,d,e];

  NCSimplifyRationalRules = 
  {
      
      (*---------------------------RULE 1---------------------------*) 
      (* rule 1 is as follows:                                      *) 
      (*    inv[a] inv[1 + K a b] -> inv[a] - K b inv[1 + K a b]    *) 
      (*    inv[a] inv[1 + K a] -> inv[a] - K inv[1 + K a]          *)
      (*------------------------------------------------------------*)
      {
          d___ ** inv[a__] ** inv[1 + K_. a__ ** b__] ** e___ :> 
              d ** inv[a] ** e - K d ** b ** inv[1 + K a ** b] ** e,
          d___ ** inv[a_] ** inv[1 + K_. a_] ** e___ :> 
              d ** inv[a] ** e - K d ** inv[1 + K a] ** e
      },

      (*-----------------------RULE 2-------------------------------*) 
      (* rule 2 is as follows:                                      *) 
      (*    inv[1 + K a b] inv[b] -> inv[b] - K inv[1 + K a b] a    *) 
      (*                   -> inv[b] - K a inv[1 + K a b] (rule #6) *) 
      (*    inv[1 + K a] inv[a] -> inv[a] - K inv[1 + K a ]         *) 
      (*------------------------------------------------------------*)
      {
          d___ ** inv[1 + K_. a__ ** b__] ** inv[b__] ** e___ :> 
              d ** inv[b] ** e - K d ** a ** inv[1 + K a ** b] ** e,
          d___ ** inv[1 + K_. a_] ** inv[a_] ** e___ :> 
              d ** inv[a] ** e - K d ** inv[1 + K a] ** e
      },

      (*---------------------------RULE 3'------------------------*) 
      (* inv[1 + K a b] a b -> [1 - inv[1 + c + K a b] (1 + c)]/K *)
      (* inv[1 + K a] a -> [1 - inv[1 + c + K a] (1 + c)]/K       *)
      (*----------------------------------------------------------*)
      {
          d___ ** inv[1 + K_. a__ ** b__] ** a__ ** b__ ** e___ :> 
              (1/K) d ** e - (1/K) d ** inv[1 + K a ** b] ** e,
          d___ ** inv[1 + K_. a_] ** a_ ** e___ :> 
              (1/K) d ** e - (1/K) d ** inv[1 + K a] ** e
      },

      (*---------------------------RULE 4 ------------------------*) 
      (* a b inv[1 + K a b] -> [1 - inv[1 + K a b]]/K             *)
      (* a inv[1 + K a] -> [1 - inv[1 + K a]]/K                   *)
      (*----------------------------------------------------------*)
      {
          d___ ** a__ ** b__ ** inv[1 + K_. a__ ** b__] ** e___ :> 
              (1/K) d ** e - (1/K) d ** inv[1 + K a ** b] ** e,
          d___ ** a_ ** inv[1 + K_. a_] ** e___ :> 
              (1/K) d ** e - (1/K) d ** inv[1 + K a] ** e
      },

      (*---------------------------------RULE 5---------------------*) 
      (* rule 5 is as follows:                                      *) 
      (*     inv[1 + K a b] inv[a] -> inv[a] inv[1 + K b a]         *)
      (*     inv[1 + K a] inv[a] -> inv[a] inv[1 + K a]             *)
      (*------------------------------------------------------------*)
      (*
         ?? THIS RULE IS INCORRECT ?? 
            THE CORRECT ONE IS RULE 2!
      *)
      (*
      {
          d___ ** inv[1 + K_. a__ ** b__] ** inv[a__] ** e___ :> 
              d ** inv[a] ** inv[1 + K b ** a] ** e,
          d___ ** inv[1 + K_. a_] ** inv[a_] ** e___ :> 
              d ** inv[a] ** inv[1 + K a] ** e
      },
      *)
      
      (*---------------------------------RULE 6---------------------*) 
      (* rule 6 is as follows:                                      *)
      (*      inv[1 + K a b] a  =  a inv[1 + K b a]                 *) 
      (*------------------------------------------------------------*)
      {
          d___ ** inv[1 + K_. a__ ** b__] ** a__ ** e___ :> 
              d ** a ** inv[1 + K b ** a] ** e
      }
      
  };

  AdditionalRules = {
          d___ ** inv[1 + c_. + K_. a__ ** b__] ** a__ ** b__ ** e___ :> 
              (1/K) d ** e - (1/K) d ** inv[1 + c + K a ** b] ** (1 + c) ** e,
          d___ ** inv[1 + c_. + K_. a_] ** a_ ** e___ :> 
              (1/K) d ** e - (1/K) d ** inv[1 + c + K a] ** (1 + c) ** e
  };

  
  (* NCSimplifyRational *)
  NCSimplifyRationalSinglePass[exp_] := Module[
      {expr = exp},
      
      (* Normalize inverses *)
      expr = NCNormalizeInverse[expr];

      (* Apply rules *)
      Scan[(expr = NCReplaceRepeated[expr, #])&,
           NCSimplifyRationalRules];

      Return[expr];
  ];


  Clear[NCSimplifyRationalAuxRules];
  NCSimplifyRationalAuxRules[terms_, rat_] :=
    { rat ** Last[terms] -> 1 - rat ** (Plus @@ Drop[terms]),
      Last[terms] ** rat -> 1 - (Plus @@ Drop[terms]) ** rat };

  NCSimplifyRational[expr_] := Module[
    {poly, rvars, rules, simpRules, tmp, invs},

    (* Convert from rational to polynomial *)
    {poly,rvars,rules} = NCRationalToNCPolynomial[expr];
    
    Print["poly = ", poly];
    Print["rvars = ", rvars];
    Print["rules = ", rules];
      
    (* Create Rules *)
    simpRules = Map[NCSimplifyRationalAuxRules[NCPSort[NCToNCPolynomial[#[[2,1]]]], 
                                               #[[1]]]&, rules];

    Print["simpRules = ", simpRules];

    tmp = NCPolynomialToNC[poly];

    Print["tmp0 = ", tmp];
      
    tmp = ExpandAll[ExpandNonCommutativeMultiply[
              Scan[(tmp = NCReplace[tmp, #])&, simpRules]
    ]];

    Print["tmp1 = ", tmp];
       
    (* Apply rules *)
      
    tmp = FixedPoint[
      ExpandAll[
        ExpandNonCommutativeMultiply[
          NCSimplifyRationalSinglePass[#]]]&, expr];
      
    Return[tmp];
      
  ];
        
End[];

EndPackage[];
