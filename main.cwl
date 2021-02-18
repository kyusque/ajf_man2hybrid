#!/usr/bin/env cwltool
class: Workflow
cwlVersion: v1.0
inputs:
    ajffile:
        type: File
    target_frag_id:
        type: string
outputs:
    outfile:
        type: File
        outputSource: rewrite_ajf/ajf_new
steps:
    extract_fragment_section:
        run: extract_fragment_section.cwl
        in:
            ajffile: ajffile
        out:
            - atom2frag
            - fraginfo
            - bondinfo
    dump_fragment_section:
        run: dump_fragment_section.cwl
        in:
            fraginfofile: extract_fragment_section/fraginfo
            atom2fragfile: extract_fragment_section/atom2frag
            bondinfofile:  extract_fragment_section/bondinfo
            target_frag_id: target_frag_id
        out:
            - fragment
    rewrite_ajf:
        run:
            class: CommandLineTool
            cwlVersion: v1.0
            baseCommand: awk
            arguments:
                - >
                    ARGV[1] == FILENAME { frag[++i] = $0; next }
                    ARGV[2] == FILENAME && /&FRAGMENT/,/\// { fragment = 1; next}
                    fragment && !header { print "&FRAGMENT"; header = 1}
                    fragment && !write_frag {for (i = 1; i <= length(frag); i++) print frag[i]; write_frag = 1 }
                    fragment && !footer { print "/"; footer = 1}
                    { print }
                    END { exit !header + !write_frag + !footer }
            stdout: $(inputs.ajf_new_name)
            inputs:
                ajffile:
                    type: File
                    inputBinding:
                        position: 2
                    streamable: true
                fragment:
                    type: File
                    inputBinding:
                        position: 1
                    streamable: true
                ajf_new_name:
                    type: string
                    default: ajf_new.txt
            outputs:
                ajf_new:
                    type: stdout
        in:
            ajffile: ajffile
            fragment: dump_fragment_section/fragment
        out:
            - ajf_new