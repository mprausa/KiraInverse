BeginPackage["KiraInverse`"];
        
Options[KiraInverse] = {Threads->1};

KiraInverse[mat_List,OptionsPattern[]] := Module[{dim,dir,strm,err,res,threads},
    threads = OptionValue[Threads];

    dim = Dimensions[mat];
    If [Length[dim] != 2 || dim[[1]] != dim[[2]], Return[$Failed]];
    dim = First[dim];

    dir = CreateDirectory[]; 

    strm = OpenWrite[dir<>"/system"];

    Do[
        WriteString[strm,"KiraINT["<>ToString[r]<>"]*(-1)\n"];
        Do[
            If [mat[[r,c]] === 0, Continue[]];

            WriteString[strm,"KiraINT["<>ToString[c+dim]<>"]*("<>StringReplace[ToString[mat[[r,c]],InputForm]," "->""]<>")\n"];
        ,{c,1,dim}];
        WriteString[strm,"\n"];
    ,{r,1,dim}];
    
    Close[strm];

    WriteString[dir<>"/masters","KiraINT["<>ToString[#]<>"]\n"] &/@Range[dim];
    WriteString[dir<>"/list","- ["<>ToString[#+dim]<>"]\n"] &/@Range[dim];

    strm = OpenWrite[dir<>"/jobs.yaml"];

    WriteString[strm,"jobs:\n"];
    WriteString[strm,"  - reduce_user_defined_system:\n"];
    WriteString[strm,"      input_system: system\n"];
    WriteString[strm,"      select_integrals:\n"];
    WriteString[strm,"        select_mandatory_list:\n"];
    WriteString[strm,"          - [KiraINT,list]\n"];
    WriteString[strm,"      preferred_masters: masters\n"];
    WriteString[strm,"      run_symmetries: true\n"];
    WriteString[strm,"      run_initiate: true\n"];
    WriteString[strm,"      run_triangular: true\n"];
    WriteString[strm,"      run_back_substitution: true\n"];
    WriteString[strm,"  - kira2math:\n"];
    WriteString[strm,"      target:\n"];
    WriteString[strm,"        - [KiraINT,list]\n"];

    Close[strm];
    
    SetDirectory[dir];
    err = Run["kira"<>If[threads>1," --parallel="<>ToString[threads],""]<>" jobs.yaml"];
    ResetDirectory[];

    If [err != 0, 
        DeleteDirectory[dir,DeleteContents->True];
        Return[$Failed]];

    res = Get[dir<>"/results/KiraINT/kira_list.m"];
    DeleteDirectory[dir,DeleteContents->True];

    res = (KiraINT/@Range[dim+1,2*dim])/.res;
    
    If [Union[Cases[res,KiraINT[n_]->n,Infinity]] =!= Range[dim], Return[$Failed]];

    res = Coefficient[#,KiraINT/@Range[dim]] &/@res;

    Return[res];
];

EndPackage[];

