function! s:ansible_vault(subcmd) abort
  if !executable('ansible-vault')
    echoerr 'ansible-vault: not found in your PATH'
    return
  endif
  if a:subcmd == 'encrypt'
    setlocal ft=ansible-vault
  elseif a:subcmd == 'decrypt'
    setlocal ft=yaml
  else
    echoerr 'Only "encrypt" or "decrypt" will be accepted for subcommand'
    return
  endif
  let password_file = expand(get(g:, 'ansible_vault_password_file', '~/.vault_password'))
  if !filereadable(password_file)
    echoerr printf('%s: no such password file for ansible-vault', password_file)
    return
  endif
  let cmd = printf('ansible-vault %s --vault-password-file=%s', a:subcmd, password_file)
  call setqflist([])
  let tmpfile = ''
  if stridx(cmd, '%s') > -1
    let tmpfile = tempname()
    let cmd = substitute(cmd, '%s', tr(tmpfile, '\', '/'), 'g')
    let lines = system(cmd, iconv(join(getline(1, '$'), "\n"), &encoding, 'utf-8'))
    if v:shell_error != 0
      call delete(tmpfile)
      echoerr substitute(lines, '[\r\n]', ' ', 'g')
      return
    endif
    let lines = join(readfile(tmpfile), "\n")
    call delete(tmpfile)
  else
    let lines = system(cmd, iconv(join(getline(1, '$'), "\n"), &encoding, 'utf-8'))
    if v:shell_error != 0
      echoerr substitute(lines, '[\r\n]', ' ', 'g')
      return
    endif
  endif
  let pos = getcurpos()
  silent! %d _
  call setline(1, split(lines, "\n"))
  call setpos('.', pos)
endfunction

nnoremap <silent> <Plug>(ansible_vault) :<C-u>call <SID>ansible_vault()<CR>

command! -nargs=0 AnsibleVaultEncrypt call <SID>ansible_vault('encrypt')
command! -nargs=0 AnsibleVaultDecrypt call <SID>ansible_vault('decrypt')

au BufNewFile,BufRead *.yml,*.yaml call s:detect_ansible_vault()

function! s:detect_ansible_vault()
  let n = 1
  while n < 10 && n < line('$')
    if getline(n) =~ 'ANSIBLE_VAULT'
      set filetype=ansible-vault
      " if confirm('Decrypt with ansible-vault?', "yes\nNo", 2) == 1
      "   AnsibleVaultDecrypt
      " endif
    endif
    let n = n + 1
  endwhile
endfunction
