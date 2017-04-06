(* :Title: 	NCReplace *)

(* :Author: 	mauricio *)

(* :Context: 	NCReplace` *)

(* :Summary:
		NCReplace is a package containing several functions that 
		are useful in making replacements in noncommutative expressions.
*)

(* :Warnings: 
*)

(* :History: 
*)

BeginPackage[ "NCReplace`", 
              "NCDot`",
              "NonCommutativeMultiply`"];

Clear[NCReplace, NCReplaceAll, 
      NCReplaceRepeated, NCReplaceList,
      NCMakeRuleSymmetric, NCMakeRuleSelfAdjoint,
      NCMatrixReplaceAll, NCMatrixReplaceRepeated];

Begin["`Private`"]

  Clear[FlatNCMultiply];
  SetAttributes[FlatNCMultiply, {Flat, OneIdentity}];

  Clear[NCReplaceFlatRules];
  NCReplaceFlatRules = {
      NonCommutativeMultiply -> FlatNCMultiply
  };

  Clear[NCReplaceReverseFlatRules];
  NCReplaceReverseFlatRules = {
      FlatNCMultiply -> NonCommutativeMultiply
  };

  NCReplace[expr_, rule_] := 
    ((Replace @@ 
        ({expr, rule} 
           /. NCReplaceFlatRules))
        /. NCReplaceReverseFlatRules);

  NCReplace[expr_, rule_, levelspec_] := 
    ((Replace @@ 
        Append[({expr, rule} 
                  /. NCReplaceFlatRules),
               levelspec])
        /. NCReplaceReverseFlatRules);
        
  NCReplaceAll[expr_, rule_] := 
    ((ReplaceAll @@ 
        ({expr, rule} 
           /. NCReplaceFlatRules))
        /. NCReplaceReverseFlatRules);

  NCReplaceRepeated[expr_, rule_] := 
    ((ReplaceRepeated @@ 
        ({expr, rule} 
           /. NCReplaceFlatRules))
        /. NCReplaceReverseFlatRules);

  NCReplaceList[expr_, rule_] := 
    ((ReplaceList @@ 
        ({expr, rule} 
           /. NCReplaceFlatRules))
        /. NCReplaceReverseFlatRules);

  NCReplaceList[expr_, rule_, n_] := 
    ((ReplaceList @@ 
        Append[({expr, rule} 
                  /. NCReplaceFlatRules),
                n])
        /. NCReplaceReverseFlatRules);
        
  (* NCMakeRuleSymmetric *)
  (* Adapted from http://mathematica.stackexchange.com/questions/31238/how-to-combine-elements-of-two-matrices *)
  
  NCMakeRuleSymmetric[rule_Rule] := NCMakeRuleSymmetric[{rule}];
  NCMakeRuleSymmetric[rule_RuleDelayed] := NCMakeRuleSymmetric[{rule}];
  NCMakeRuleSymmetric[rules_List] := 
    Function[Null, ##, Listable][rules, 
       Function[Null, Map[tp, ##], Listable][rules]];
        
  (* NCMakeRuleSelfAdjoint *)
  
  NCMakeRuleSelfAdjoint[rule_Rule] := NCMakeRuleSelfAdjoint[{rule}];
  NCMakeRuleSelfAdjoint[rule_RuleDelayed] := NCMakeRuleSelfAdjoint[{rule}];
  NCMakeRuleSelfAdjoint[rules_List] := 
    Function[Null, ##, Listable][rules, 
       Function[Null, Map[aj, ##], Listable][rules]];

  (* NCMatrixReplaceAll *)
  
  Clear[FlatNCPlus];
  SetAttributes[FlatNCPlus, {Orderless, OneIdentity}];
  FlatNCPlus[x_,y_] := (Plus @@ {x,y} /; 
     And[Not[MatchQ[x, _. (_NonCommutativeMultiply|_FlatNCMultiply|_inv)]],
         Not[MatchQ[y, _. (_NonCommutativeMultiply|_FlatNCMultiply|_inv)]]]);

  Clear[FlatMatrix];
     
  Clear[NCMatrixReplaceReverseFlatPlusRules];
  NCMatrixReplaceReverseFlatPlusRules = {
      FlatNCPlus[x_?MatrixQ,y_?MatrixQ] :> 
        Plus @@ {x,y},
      inv -> NCInverse
  };
      
  Clear[NCMatrixReplaceFlatRules];
  NCMatrixReplaceFlatRules = {
      NonCommutativeMultiply -> FlatNCMultiply,
      Plus -> FlatNCPlus,
      x_?MatrixQ :> FlatMatrix[x]
  };

  Clear[NCMatrixReplaceReverseFlatRules];
  NCMatrixReplaceReverseFlatRules = {
      FlatNCMultiply -> NonCommutativeMultiply,
      FlatMatrix -> ArrayFlatten
  };

  (*
  NCMatrixReplaceAll[expr_, rule_] := Module[
    {tmp},

    tmp = ({expr, rule} 
             /. NCMatrixReplaceFlatRules);

    Print["tmp0 = ", tmp];
      
    tmp = (ReplaceAll @@ 
            ({expr, rule} 
             /. NCMatrixReplaceFlatRules))
               /. NCMatrixReplaceReverseFlatRules;

    Print["tmp1 = ", tmp];
      
    tmp = NCMatrixExpand[tmp];
      
    Print["tmp2 = ", tmp];
      
    Return[tmp /. FlatNCPlus -> Plus];
  ];
  *)

  NCMatrixReplaceAll[expr_, rule_] := NCMatrixExpand[
      (ReplaceAll @@ 
            ({expr, rule} 
             /. NCMatrixReplaceFlatRules))
               /. NCMatrixReplaceReverseFlatRules] /. FlatNCPlus -> Plus;

  NCMatrixReplaceRepeated[expr_, rule_] := NCMatrixExpand[
      (ReplaceRepeated @@ 
            ({expr, rule} 
             /. NCMatrixReplaceFlatRules))
               /. NCMatrixReplaceReverseFlatRules] /. FlatNCPlus -> Plus;
  
End[];

EndPackage[];
