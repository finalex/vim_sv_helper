if version < 700
   finish
endif

"==================================================
"           Menu
"==================================================
"amenu &MyFunction.-MyFunction-                          :
"amenu &MyFunction.&VerilogFormat                        :call s:VerilogFormat()<CR>
"amenu &MyFunction.&RegisterDescription                  :call s:RegisterDescription()<CR>

"==================================================
"           Map
"==================================================
"map ,i <ESC>bi.<ESC>ea()<ESC>

"==================================================
"           Command
"==================================================
command! -nargs=0 -bar RemoveSpacesEndofLine            call s:Remove_Spaces_EndofLine()
command! -nargs=0 -bar GG                               call s:VerilogGetSignal()
command! -nargs=1 -bar BA                               call s:BlockAnnotation("module", "endmodule", <q-args>, '\/\/')
command! -nargs=0 -bar VTP                              call s:VerilogTestPort()
"command! -nargs=0 -bar VerilogFormat                   call b:VerilogFormat()

command! -nargs=* SetCopyRange                          call s:SetCopyRange(<f-args>)
command! -nargs=* SendSubContent                        call s:SendSubContent(<f-args>)
command! -nargs=0 -bar VerilogLineFormat                call s:VerilogLineFormat(line("."))
command! -nargs=0 -bar RegisterDescription              call s:RegisterDescription()
command! -nargs=0 -bar VerilogDefineFormat              call s:VerilogDefineFormat(line("."))
command! -nargs=0 -bar VerilogInstFormat                call s:VerilogInstFormat(line("."))

command! AddHeader           :call AddHeader()
command! AddIComment         :call AddInlineTag(" = Commment: ")
command! AddIECO             :call AddInlineTag(" = ECO: ")
"==================================================
"           variable
"==================================================
if exists("b:vlog_company") == 0
   let b:vlog_company = "HXT"
endif

if exists("b:MAX_LENGTH_WIDTH") == 0
    let b:MAX_LENGTH_WIDTH = 25
endif

if exists("b:MAX_LENGTH_NAME") == 0
    let b:MAX_LENGTH_NAME = 25
endif

if exists("b:KEYWORD_TO_MATCH") == 0
    let b:KEYWORD_TO_MATCH = '^\s*\(\<input\>\|\<output\>\|\<inout\>\|\<logic\>\|\<reg\>\|\<bit\>\|\<wire\>\|\<int\>\|\<string\>\|\<byte\>\|\<real\>\|\<integer\>\)'
endif

"==================================================
"           function
"==================================================

"Add File Header
function! AddHeader()
  let cnt = 0
  call append(cnt,   "//=======================================================================")
  let cnt = cnt + 1
  call append(cnt,   "// Copyright ".b:vlog_company)
  let cnt = cnt + 1
  call append(cnt,   "// All rights reserved.")
  let cnt = cnt + 1
  call append(cnt,   "// ")
  let cnt = cnt + 1
  call append(cnt,   "// Filename           :".expand("%:t"))
  let cnt = cnt + 1
  call append(cnt,   "// Author             :".$USER)
  let cnt = cnt + 1
  call append(cnt,   "// Updated On         :".strftime("%Y-%m-%d"))
  let cnt = cnt + 1
  call append(cnt,   "//-----------------------------------------------------------------------")
  let cnt = cnt + 1
  call append(cnt,   "// Description        :")
  let cnt = cnt + 1
  call append(cnt,   "// ")
  let cnt = cnt + 1
  call append(cnt,   "//-----------------------------------------------------------------------")
  let cnt = cnt + 1
  call append(cnt,   "// Reset & Clock      :")
  let cnt = cnt + 1
  call append(cnt,   "// ")
  let cnt = cnt + 1
  call append(cnt,   "//-----------------------------------------------------------------------")
  let cnt = cnt + 1
  call append(cnt,   "// Release history")
  let cnt = cnt + 1
  call append(cnt,   "// Version    Author    Date        Description")
  let cnt = cnt + 1
  call append(cnt,   "// ")
  let cnt = cnt + 1
  call append(cnt,   "//=======================================================================")
endfunction

function! AddInlineTag(extra)
    call setline(".",getline(".")."    //Note: ".$USER." @".strftime("%Y-%m-%d").a:extra)
endfunction

"remove the useless spaces in the end of a line
function! s:Remove_Spaces_EndofLine()
    echo "Remove spaces in the end of lines..."
    execute ":%s/\ *$//g"
endfunction

"Get all verilog signal
function! s:VerilogGetSignal()
    let InputSignal      = []
    let OutputSignal     = []
    let InternalSignal   = []
    for l:line in getline(1,line("$"))
        if l:line =~ '^\s*\<input\>'
            let l:line = substitute(l:line, '^\s*\<input\>\s*\(\[.*:.*\]\)*\s*', "", "")
            let l:line = substitute(l:line, ';.*$', "", "")
            call add(InputSignal, l:line)
        elseif l:line =~ '^\s*\<output\>'
            let l:line = substitute(l:line, '^\s*\<output\>\s*\(\[.*:.*\]\)*\s*', "", "")
            let l:line = substitute(l:line, ';.*$', "", "")
            call add(OutputSignal, l:line)
        elseif l:line =~ '^\s*\<wire\>'
            let l:line = substitute(l:line, '^\s*\<wire\>\s*\(\[.*:.*\]\)*\s*', "", "")
            let l:line = substitute(l:line, ';.*$', "", "")
            call add(InternalSignal, l:line)
        elseif l:line =~ '^\s*\<reg\>'
            let l:line = substitute(l:line, '^\s*\<reg\>\s*\(\[.*:.*\]\)*\s*', "", "")
            let l:line = substitute(l:line, ';.*$', "", "")
            call add(InternalSignal, l:line)
        endif
    endfor
    "delete the input signal from the internal signal list
    for l:InternalFilter in InputSignal
        call filter(InternalSignal,'v:val !~ l:InternalFilter')
    endfor
    "delete the output signal from the internal signal list
    for l:InternalFilter in OutputSignal
        call filter(InternalSignal,'v:val !~ l:InternalFilter')
    endfor
endfunction 

function! s:BlockAnnotation(BlockHead, BlockTail, Keyword, Nota)
    let l:bStart = "disable"
    let l:bKeyFind = "disable"
    let l:linenum = 1
    "echo a:BlockHead
    "echo a:BlockTail
    "echo a:Keyword
    "echo a:Nota
    for l:line in getline(1, line("$"))
        "find the block head
        if l:line =~ '^\s*\<'.a:BlockHead.'\>'
            let l:bStart = "enable"
            let l:bHeadline = l:linenum
        endif

        "find the key word with head
        if l:bStart == "enable" && l:line =~ '\<'.a:Keyword.'\>'
            let l:bKeyFind = "enable"
        endif

        "find the block tail with head
        if l:bStart == "enable" && l:line =~ '^\s*\<'.a:BlockTail.'\>'
            let l:bStart = "disable"
            let l:bTailline = l:linenum
            "process if key
            if l:bKeyFind == "enable"
                let l:bKeyFind = "disable"
                execute ':'.l:bHeadline.','.l:bTailline.'s/^/'.a:Nota.'/g'
                echo l:bHeadline
                echo l:bTailline
            endif
        endif
        let l:linenum = l:linenum + 1
    endfor
endfunction

"Margin Calculation
function! s:CalMargin(max_len, cur_len)
   let l:margin = ""
   if a:max_len <= a:cur_len
       return l:margin
   endif
   for i in range(1, a:max_len-a:cur_len+1, 1)
      let l:margin = l:margin." "
   endfor
   return l:margin
endfunction

"Copy specified block
function! s:SetCopyRange(StartLine, EndLine)
    let b:CopiedRange = []
    for l:line in getline(a:StartLine, a:EndLine)
        call add(b:CopiedRange, l:line)
    endfor
endfunction

"Find Pat and change it to Sub in Specified Block
function! s:SendSubContent(Pat, Sub)
    let l:index = 0
    let l:curr = line(".")
    while l:index < len(b:CopiedRange)
        let l:line = b:CopiedRange[l:index]
        let l:line = substitute(l:line, a:Pat, a:Sub, 'g')
        call append(l:curr, l:line)
        let l:index = l:index + 1
        let l:curr = l:curr + 1
    endwhile
endfunction

"Register Description
function! s:RegisterDescription()
    let l:curr = line(".")
    call append(l:curr     ,"//==================================================")
    call append(l:curr+1   ,"//Register : ")
    call append(l:curr+2   ,"//           ")
    call append(l:curr+3   ,"//bit7     : ")
    call append(l:curr+4   ,"//bit6     : ")
    call append(l:curr+5   ,"//bit5     : ")
    call append(l:curr+6   ,"//bit4     : ")
    call append(l:curr+7   ,"//bit3     : ")
    call append(l:curr+8   ,"//bit2     : ")
    call append(l:curr+9   ,"//bit1     : ")
    call append(l:curr+10  ,"//bit0     : ")
    call append(l:curr+11  ,"//           ")
    call append(l:curr+12  ,"//==================================================")
endfunction

"Format the signal definition line
function! s:VerilogDefineFormat(linenum)
    let l:line = getline( a:linenum )
    "remove head & tail space
    let l:line = substitute(l:line, '^\s*', "", "")
    let l:line = substitute(l:line, '\s*$', "", "")
    "get comment
    let l:comment = matchstr(l:line, '\/\/.*$')
    "remove comment from line
    let l:line = substitute(l:line, '\/\/.*$', "", "")
    "remove head & tail space
    let l:line = substitute(l:line, '^\s*', "", "")
    let l:line = substitute(l:line, '\s*;\s*$', "", "")
    
    if l:line !~ ','
        if l:line =~ b:KEYWORD_TO_MATCH
            "keyword
            let l:keyword           = matchstr(l:line, b:KEYWORD_TO_MATCH)
            let l:margin_keyword    = s:CalMargin(10, len(l:keyword) )
            "remove keyword from line
            let l:line = substitute(l:line, b:KEYWORD_TO_MATCH, "", "")
            "remove head & tail space
            let l:line = substitute(l:line, '^\s*', "", "")
            let l:line = substitute(l:line, '\s*$', "", "")
            "signal width
            let l:signal_width      = matchstr(l:line, '^\[.*\]\s')
            let l:margin_width      = s:CalMargin(25, len(l:signal_width) )
            "remove signal width from line
            let l:line = substitute(l:line, '^\[.*\]\s', "", "")
            "remove head & tail space
            let l:line = substitute(l:line, '^\s*', "", "")
            let l:line = substitute(l:line, '\s*$', "", "")
            "signal name
            let l:signal_name       = l:line
            let l:margin_name       = s:CalMargin(25, len(l:signal_name) )

            call setline( a:linenum, l:keyword.l:margin_keyword.l:signal_width.l:margin_width.l:signal_name.l:margin_name."; ".l:comment )
        endif
    endif

"    ---> this is old version
"    let l:indicator = 0
"    if l:line !~ ','
"        if l:line =~ '^\s*\<input\>'
"            let l:indicator = 1
"            let l:keyword = "input"
"            "5 space
"            let l:margin_keyword = "     "
"        endif
"        if l:line =~ '^\s*\<output\>'
"            let l:indicator = 1
"            let l:keyword = "output"
"            "4 space
"            let l:margin_keyword = "    "
"        endif
"        if l:line =~ '^\s*\<reg\>'
"            let l:indicator = 1
"            let l:keyword = "reg"
"            "7 space
"            let l:margin_keyword = "       "
"        endif
"        if l:line =~ '^\s*\<wire\>'
"            let l:indicator = 1
"            let l:keyword = "wire"
"            "6 space
"            let l:margin_keyword = "      "
"        endif
"        if l:line =~ '^\s*\<integer\>'
"            let l:indicator = 1
"            let l:keyword = "integer"
"            "3 space
"            let l:margin_keyword = "   "
"        endif
"    endif
"
"    if l:indicator == 1
"        "signal width
"        let l:signal_width      = matchstr(l:line, '\[.*\]')
"        let l:margin_width      = s:CalMargin(b:MAX_LENGTH_WIDTH, len(l:signal_width) )
"        "signal name
"        let l:signal_name       = substitute(l:line, l:keyword, "", "")
"        let l:signal_name       = substitute(l:signal_name, '\[.*\]', "", "")
"        let l:signal_name       = substitute(l:signal_name, '\/\/.*$', "", "")
"        let l:signal_name       = substitute(l:signal_name, ';', "", "")
"        let l:signal_name       = substitute(l:signal_name, '\s*', "", "g")
"        let l:margin_name       = s:CalMargin(b:MAX_LENGTH_NAME, len(l:signal_name) )
"        "comment
"        let l:comment           = matchstr(l:line, '\/\/.*$')
"
"        "echo l:keyword
"        "echo l:signal_name
"        "echo l:signal_width
"        "echo l:comment
"
"        call setline( a:linenum, l:keyword.l:margin_keyword.l:signal_width.l:margin_width.l:signal_name.l:margin_name."; ".l:comment )
"    endif
endfunction

"Instance Format
function! s:VerilogInstFormat(linenum)
    let l:RefMaxLength = 25
    let l:InsMaxLength = 40
    let l:line = getline( a:linenum )
    "remove head & tail space
    let l:line = substitute(l:line, '^\s*', "", "")
    let l:line = substitute(l:line, '\s*$', "", "")
    "get comment
    let l:comment = matchstr(l:line, '\/\/.*$')
    "remove comment from line
    let l:line = substitute(l:line, '\/\/.*$', "", "")
    
    if l:line =~ '^\s*\.' && l:line =~ '(' && l:line =~ ')'
        let l:line = substitute(l:line, '^\.\s*', "", "")
        "echo l:line
        let l:ref_name          = substitute(l:line, '\s*(.*$', "", "")
        let l:ref_name          = substitute(l:ref_name, ',', "", "")
        let l:ref_width         = s:CalMargin(l:RefMaxLength, len(l:ref_name))
        let l:ins_name          = substitute(l:line, '^.*(\s*', "", "")
        let l:ins_name          = substitute(l:ins_name, '\s*).*$', "", "")
        let l:ins_width         = s:CalMargin(l:InsMaxLength, len(l:ins_name))
        "echo l:ref_name
        "echo l:ins_name
        "echo l:comment
        let l:iscomma = "   "
        if l:line =~ ')\s*,'
            let l:iscomma = ",  "
        endif

        call setline( a:linenum, "    .".l:ref_name.l:ref_width."( ".l:ins_name.l:ins_width." )".l:iscomma.l:comment )
    end
endfunction

"Format single line
function! s:VerilogLineFormat(linenum)
    call s:VerilogDefineFormat(a:linenum)
    call s:VerilogInstFormat(a:linenum)
endfunction

"Format whole file
function! s:VerilogFormat()
    let l:linenum = 1
    while l:linenum <= line("$")
        call s:VerilogLineFormat(l:linenum)
        let l:linenum = l:linenum + 1
    endwhile
endfunction

"Set verilog test assign
function! s:VerilogTestPort()
    let l:linenum = 1
    while l:linenum <= line("$")
        let l:line = getline(l:linenum)
        if l:line =~ '^\s*\(\<input\>\|\<output\>\|\<inout\>\|\<reg\>\|\<wire\>\).*vtp'
            "remove keyword from line
            let l:line = substitute(l:line, b:KEYWORD_TO_MATCH, "", "")
            "remove head & tail space
            let l:line = substitute(l:line, '^\s*', "", "")
            let l:line = substitute(l:line, '\s*$', "", "")
            "signal width
            let l:signal_width      = matchstr(l:line, '^\[.*\]\s')
            if l:signal_width != ""
                let l:signal_width = substitute(l:signal_width, '\[', "", "")
                let l:signal_width = substitute(l:signal_width, ':.*\]', "", "")
                let l:signal_width = l:signal_width + 1
            else
                let l:signal_width = 1
            endif
            "remove signal width from line
            let l:line = substitute(l:line, '^\[.*\]\s', "", "")
            "remove head & tail space
            let l:line = substitute(l:line, '^\s*', "", "")
            let l:line = substitute(l:line, '\s*$', "", "")
            let l:line = substitute(l:line, '\s*[,;].*$', "", "")
            "signal name
            echo l:signal_width
            echo l:signal_name
        endif
        let l:linenum = l:linenum + 1
    endwhile
endfunction
