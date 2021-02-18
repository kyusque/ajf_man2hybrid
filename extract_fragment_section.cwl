#!/usr/bin/env cwltool
class: CommandLineTool
cwlVersion: v1.0
baseCommand: awk
arguments:
    - >
        BEGIN { OFS = ","; for_nf = for_fragment = for_atom2frag = for_bondinfo = 1; i_frag = 1;  fraginfo = "$(inputs.fraginfo_name)"}
        for_nf && /NF=/ { gsub("NF=","", $0); nf = int($0); nf_overflow_wrap = int(nf / 10) + 1; for_nf = 0 } 
        for_nf { next }
        for_fragment && /&FRAGMENT/ { _for_n_atom = _for_charge = _for_n_bond = nf_overflow_wrap; for_fragment = 0; next } 
        for_fragment { next }
        _for_n_atom { for (i = 1; i <= NF; i++) n_atom[++i_n_atom] = $i; _for_n_atom--; next } 
        _for_charge { for (i = 1; i <= NF; i++) charge[++i_charge] = $i; _for_charge--; next }
        _for_n_bond { for (i = 1; i <= NF; i++) n_bond[++i_n_bond] = $i; _for_n_bond--; next }
        !header_fraginfo { print "frag_id","n_atom", "charge", "n_bond" > fraginfo;  header_fraginfo = 1}
        !print_fraginfo { for (i = 1; i <= i_n_atom; i++) print i, n_atom[i], charge[i], n_bond[i] > fraginfo; print_fraginfo = 1 }
        !header_atom2frag { print "atom_id", "frag_id"; header_atom2frag = 1 }
        for_atom2frag && i_frag >  nf { for_atom2frag =  0 }
        for_atom2frag && n_atom_tmp == n_atom[i_frag] { i_frag++; n_atom_tmp = 0 }
        for_atom2frag { for (i = 1; i <= NF; i++) { print $i, i_frag; n_atom_tmp++}; next }
        !header_bondinfo { print "bda", "baa", "type" >  "$(inputs.bondinfo_name)"; header_bondinfo = 1}
        for_bondinfo && /\\// { for_bondinfo = 0; exit }
        for_bondinfo { print $1,$2,$3 > "$(inputs.bondinfo_name)"; next }
        END { 
        if (for_nf + for_fragment + _for_n_atom + _for_charge + _for_n_bond + for_bondinfo) 
        { print "[error]", for_nf, for_fragment, _for_n_atom, _for_charge, _for_n_bond, for_bondinfo > "/dev/stderr"; exit 1} 
        }
stdout: $(inputs.atom2frag_name)
inputs:
    ajffile:
        type: File
        inputBinding:
            position: 1
        streamable: true
    atom2frag_name:
        type: string
        default: atom2frag.txt
    fraginfo_name:
        type: string
        default: fraginfo.txt
    bondinfo_name:
        type: string
        default: bondinfo.txt
outputs:
    atom2frag:
        type: stdout
    fraginfo:
        type: File
        outputBinding:
            glob: $(inputs.fraginfo_name)
    bondinfo:
        type: File
        outputBinding:
            glob: $(inputs.bondinfo_name)

