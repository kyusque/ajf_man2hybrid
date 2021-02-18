#!/usr/bin/env cwltool
class: CommandLineTool
cwlVersion: v1.0
baseCommand: awk
arguments: 
    - >
        function in_array (x, a) { for (i in a) if (a[i] == x) return 1; return 0 }
        function print_ofw (sa,  i) { for (i = 1; i <= length(sa); i++) { printf "%8i", sa[i]; if(i == length(sa) || !(i % 10)) printf ORS }}
        BEGIN { FS = ","}
        !init { split("$(inputs.target_frag_id)", target_frag_id, ","); init = 1 }
        / FNR == 1 / { next }
        !read_fraginfo && FILENAME != ARGV[1] { read_fraginfo = 1 }
        !read_fraginfo && in_array($1, target_frag_id) { sep = " "; n_atom[++i_frag] = $2; charge[i_frag] = $3; n_bond[i_frag] = $4 }
        !read_fraginfo { next; print length(n_atom) }
        !write_n_atom { print_ofw(n_atom); write_n_atom = 1 }
        !write_charge { print_ofw(charge); write_charge = 1 }
        !write_n_bond { print_ofw(n_bond); write_n_bond = 1 }
        !read_atom2frag && FILENAME != ARGV[2] { read_atom2frag = 1 }
        !read_atom2frag && !in_array($2, target_frag_id) { next }
        !read_atom2frag { atom2frag[$1] = $2 }
        !read_atom2frag { if (frag2atom[$2]) frag2atom[$2] = frag2atom[$2] "," $1; else frag2atom[$2] = $1; next }
        !write_atoms {for (i = 1; i <= length(target_frag_id); i++) { split(frag2atom[target_frag_id[i]], atoms, ","); print_ofw(atoms)} write_atoms = 1}
        !write_bonds && (in_array(atom2frag[$1], target_frag_id) || in_array(atom2frag[$2], target_frag_id)) { if (!$3) $3 = 3; printf "%8i%8i%8i" ORS, $1, $2, $3 }
stdout: fragment.txt
inputs:
    fraginfofile:
        type: File
        inputBinding:
            position: 1
        streamable: true
    atom2fragfile:
        type: File
        inputBinding:
            position: 2
    bondinfofile:
        type: File
        inputBinding:
            position: 3
    target_frag_id:
        type: string
outputs:
    fragment:
        type: stdout