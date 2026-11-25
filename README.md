# caixa-ferramentas 🔥

Caixa de ferramentas de TI para PowerShell — ativação de Office, correção de rede, reparo de sistema e mais.

## Como usar

Abra o PowerShell e digite:

```powershell
cf
```

O alias `cf` (e `caixa`) é instalado automaticamente no seu perfil na primeira execução.

## Opções do menu

| # | Opção | Script |
|---|-------|--------|
| 1 | 🔐 Ativação Office (MAS) | `ativa-office.ps1` |
| 2 | 🌐 Correção de Rede | `net-ultra.ps1` |
| 3 | 🪟 Instalar Aplicativos do Pacote Office | `OfficeSetup.ps1` |
| 4 | 🛠️ Reparar Corrupção do Sistema (DISM+SFC) | `sfc-dism.ps1` |
| 5 | 🪟 Pular Login Microsoft (Conta Local - OOBE) | `pular-login.ps1` |
| 6 | 💾 Recuperar Arquivos de Pendrive | `recuperar-pendrive.ps1` |
| 0 | ❌ Sair | — |

## 🪟 Pular Login Microsoft (Conta Local - OOBE)

Pula a exigência de login com conta Microsoft na configuração inicial do Windows 11, criando apenas um usuário local.

### Uso automático (pelo menu)

Na opção **[5]** da caixa de ferramentas, o comando é executado automaticamente e as instruções são exibidas na tela.

### Método manual (durante a instalação)

Funciona diretamente na tela de conexão de rede ou de login de e-mail durante a instalação:

1. **Abra o terminal.** Pressione **Shift + F10** (em alguns notebooks: **Shift + Fn + F10**).
2. **Execute o comando.** Na janela preta, digite:

   ```
   start ms-cxh:localonly
   ```

3. **Crie o usuário local.** Uma janela clássica será exibida para digitar apenas um nome de usuário e uma senha opcional, concluindo o acesso sem precisar de e-mail.

> 💡 Esse atalho funciona mesmo nas compilações recentes em que o antigo comando `oobe\bypassnro` foi bloqueado pela Microsoft. O comando `ms-cxh:localonly` só funciona na configuração inicial (OOBE) do Windows 11.

## 💾 Recuperar Arquivos de Pendrive

Recupera arquivos corrompidos por leitura bruta da mídia, **sem gravar nada no pendrive**.

### O que recupera

- `DOCX`, `XLSX`, `PPTX` e `ZIP` íntegros (EOCD + diretório central).
- `PDF`, `PNG`, `JPG/JPEG` e `MP4` por assinatura e marcadores de fim.
- ZIPs órfãos reconstruídos quando todos os trechos passam no CRC32.

### Uso

Na opção **[6]** da caixa de ferramentas, escolha a unidade removível detectada e confirme. Por padrão lê os primeiros **320 MB** e salva em `.\recuperados`, com `indice.csv` e `relatorio.txt`.

Se o Windows negar o acesso ao dispositivo bruto, o script avisa para executar como **Administrador**. Isso não é necessário quando o acesso é permitido sem elevação.

> ⚠️ Não recupera dados sobrescritos, apagados com segurança, criptografados ou danificados fisicamente. Nomes originais podem não existir mais; quando presentes, são usados `autor`, `título` e `data` dos metadados internos.
