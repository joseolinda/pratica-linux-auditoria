# Prática de laboratório — Auditoria de TI e comandos Linux

## Sua missão

Examine arquivos de evidência sintéticos de um serviço de tribunal usando comandos Linux. Identifique o que os registros mostram, avalie controles de acesso, gestão de mudanças, monitoramento e alertas de IDS, e registre suas conclusões em um papel de trabalho.

Todos os dados são fictícios. O arquivo `ids-alertas.csv` simula alertas; ele não vem de um IDS real. Não use esta atividade para analisar dados de produção nem para concluir que houve um incidente real.

Ao concluir, você deverá conseguir:

- navegar por diretórios e consultar tipo, proprietário, grupo e permissões de arquivos;
- filtrar e resumir registros com `grep`, `cut`, `sort`, `uniq`, `awk` e `wc`;
- salvar saídas e erros com redirecionamentos e `tee`;
- relacionar evidências a critérios e controles de auditoria;
- documentar achados e limitações sem afirmar mais do que as evidências permitem.

## 1. Confira os pré-requisitos

Você precisa de:

- Docker Engine ou Docker Desktop em execução;
- Docker Compose v2, disponível pelo comando `docker compose`;
- Bash ou Zsh no Linux/macOS; no Windows, use WSL ou Git Bash com Docker Desktop;
- acesso à internet durante a primeira construção da imagem.

O contêiner usa um usuário sem privilégios de root, um sistema de arquivos somente leitura e uma rede interna. Nenhuma porta é publicada no computador. O servidor HTTP de demonstração fica acessível apenas de dentro do contêiner.

> **Se o daemon Docker for compartilhado:** ter acesso ao daemon ou ao socket `docker.sock` pode equivaler a ter privilégios administrativos na máquina. Projetos Docker separados organizam contêineres e volumes, mas não isolam alunos que podem acessar o mesmo daemon. Use uma VM ou daemon isolado por pessoa quando for necessário isolamento entre usuários. Nunca exponha a API do Docker à internet.

## 2. Abra o terminal do computador

No terminal do computador (fora do contêiner), entre na pasta `pratica-linux` que recebeu e confira as versões:

```bash
docker --version
docker compose version
```

Se os comandos não forem encontrados, inicie ou instale o Docker Desktop/Engine antes de continuar.

Se esta pasta compartilhar um daemon Docker com outras instâncias, escolha um identificador exclusivo para seu projeto. O nome evita colisões de contêiner, rede e volume; ele não substitui o isolamento do daemon:

```bash
export LAB_PROJECT=auditoria-aluno01
```

Use um identificador diferente de `auditoria-aluno01` se outra pessoa já estiver usando esse nome. Mantenha essa variável definida nos terminais do computador em que executar os comandos seguintes. Em um computador usado somente por você, pode pular esse passo.

## 3. Inicie o laboratório

Ainda no terminal do computador e dentro da pasta `pratica-linux`, execute:

```bash
./lab.sh up
./lab.sh status
```

O primeiro comando constrói a imagem Debian e inicia o contêiner. Na primeira execução, o Docker baixa a imagem-base e os pacotes necessários; isso exige internet. O segundo comando mostra se o serviço está em execução e saudável.

Abra o terminal Linux do laboratório:

```bash
./lab.sh shell
```

Os comandos das próximas atividades devem ser executados **dentro do contêiner**, a menos que o roteiro diga “terminal do computador”. Para sair do contêiner e voltar ao terminal do computador, execute `exit`.

### Comandos de administração

Execute estes comandos no terminal do computador, dentro da pasta `pratica-linux`:

| Comando | O que faz |
| --- | --- |
| `./lab.sh up` | Constrói a imagem, cria o contêiner e inicia o serviço |
| `./lab.sh shell` | Abre um Bash dentro do contêiner |
| `./lab.sh status` | Mostra o estado do serviço |
| `./lab.sh logs` | Acompanha os registros HTTP; use em outro terminal enquanto trabalha |
| `./lab.sh collect` | Copia o relatório do volume Docker para `entrega/relatorio.md` na pasta do computador |
| `./lab.sh down` | Para e remove o contêiner e a rede; preserva o volume com sua entrega |

O diretório `~/entrega` dentro do contêiner é um volume persistente. Seu relatório permanece nele mesmo que você pare o laboratório ou reconstrua a imagem. `./lab.sh down` preserva esse volume. Não use `docker compose down -v`, pois a opção `-v` remove volumes.

## 4. Atividades dentro do contêiner

### Atividade 1 — Identidade, navegação e metadados

Execute:

```bash
whoami
id
pwd
ls -lah
cd /opt/lab/evidencias
pwd
ls -lah
file inventario.csv auth.log app.conf
stat inventario.csv
```

O que cada comando informa:

- `whoami` mostra o nome do usuário atual.
- `id` mostra o identificador do usuário e os grupos aos quais ele pertence.
- `pwd` imprime o diretório atual.
- `ls -lah` lista arquivos, incluindo os ocultos (`-a`), em formato detalhado (`-l`) e com tamanhos legíveis (`-h`).
- `cd` muda o diretório atual.
- `file` identifica o tipo de conteúdo do arquivo; não informa se os dados estão corretos nem se são confiáveis.
- `stat` mostra metadados, como tamanho, proprietário, grupo, permissões e horários.

**Registre e responda:**

1. Qual usuário executa os comandos? Quais grupos aparecem em `id`?
2. Qual era seu diretório inicial? Qual é o diretório das evidências?
3. O que `file` revela sobre `inventario.csv`, `auth.log` e `app.conf`?
4. Em que `file` e `stat` diferem?

Os arquivos-fonte estão em `/opt/lab/evidencias`. Esse diretório é somente leitura. Use caminhos absolutos nos registros de auditoria para indicar exatamente de onde veio cada evidência.

### Atividade 2 — Inventário e cobertura de monitoramento

Execute:

```bash
find /opt/lab/evidencias -maxdepth 1 -type f -print | sort
cat /opt/lab/evidencias/inventario.csv
cut -d, -f1,2,3,4,6 /opt/lab/evidencias/inventario.csv
```

- `find` procura itens no diretório indicado. `-maxdepth 1` limita a busca ao próprio diretório, `-type f` seleciona arquivos regulares e `-print` exibe seus caminhos.
- `sort` ordena as linhas; aqui facilita a leitura da lista produzida por `find`.
- `cat` exibe o conteúdo completo do arquivo.
- Em `cut`, `-d,` define a vírgula como delimitador e `-f1,2,3,4,6` seleciona os campos 1, 2, 3, 4 e 6.

O inventário contém identificador do ativo, serviço, ambiente, criticidade, responsável e indicação de sensor IDS.

**Tarefa de auditoria:** compare a criticidade dos serviços com a coluna `ids_sensor`. Identifique um ativo para o qual você pediria evidência adicional sobre cobertura de monitoramento. Anote qual evidência pediria, por exemplo, diagrama de arquitetura, configuração do sensor, regra de monitoramento ou relatório de cobertura.

A ausência de sensor indicada na amostra é uma condição a investigar. Ela não demonstra, sozinha, que ocorreu um incidente nem que não há controles compensatórios.

### Atividade 3 — Permissões e menor privilégio

Execute:

```bash
id
stat -c '%A %a %U:%G %n' /opt/lab/evidencias/app.conf
stat -c '%A %a %U:%G %n' /opt/lab/evidencias/config-compartilhado.conf
stat -c '%A %a %U:%G %n' /opt/lab/evidencias/restrito-demo.txt
namei -l /opt/lab/evidencias/restrito-demo.txt
find /opt/lab/evidencias -type f -perm /022 -printf '%M %u:%g %p\n'
cat /opt/lab/evidencias/restrito-demo.txt
```

Em `stat -c`, os marcadores mostram:

- `%A`: permissões em formato simbólico, como `-rw-r-----`;
- `%a`: permissões em formato octal, como `640`;
- `%U:%G`: proprietário e grupo;
- `%n`: nome do arquivo.

`namei -l` apresenta as permissões de cada diretório no caminho até o arquivo. `find -perm /022` seleciona arquivos com permissão de escrita para grupo (`020`) ou outros usuários (`002`).

O último `cat` deve exibir `Permission denied`. Esse resultado é esperado: `restrito-demo.txt` pertence a root e tem modo `0600`, portanto o usuário do laboratório não pode lê-lo. Não tente contornar a restrição. O arquivo `config-compartilhado.conf` concede escrita ao grupo. Avalie se essa permissão atende ao princípio do menor privilégio e que informação você precisaria para confirmar o risco.

Agora copie um registro para sua área de trabalho e altere **somente a cópia**:

```bash
cp -p /opt/lab/evidencias/auth.log ~/entrega/auth-copia.log
chmod 640 ~/entrega/auth-copia.log
stat -c '%A %a %U:%G %n' ~/entrega/auth-copia.log
umask_atual="$(umask)"
umask 0027
touch ~/entrega/arquivo-criado.txt
stat -c '%A %a %U:%G %n' ~/entrega/arquivo-criado.txt
umask "$umask_atual"
```

- `cp -p` copia o arquivo e preserva seus metadados quando possível.
- `chmod 640` define leitura e escrita para o proprietário, leitura para o grupo e nenhum acesso para outros.
- `umask` define quais permissões são removidas dos arquivos criados pelo processo. Com `0027`, arquivos novos normalmente ficam com modo `640`.
- `umask_atual` guarda a máscara original; o último comando restaura essa configuração.
- `touch` cria um arquivo vazio, usado aqui para observar as permissões resultantes.

**Registre:** compare as permissões antes e depois do `chmod`; explique quem consegue ler a cópia. Anote o modo observado no arquivo criado com `umask 0027`. Não altere arquivos em `/opt/lab/evidencias`.

### Atividade 4 — Leitura, busca e contagem de registros

Execute:

```bash
wc -l /opt/lab/evidencias/auth.log
head -n 3 /opt/lab/evidencias/auth.log
tail -n 3 /opt/lab/evidencias/auth.log
grep -c 'result=FAIL' /opt/lab/evidencias/auth.log
grep 'result=FAIL' /opt/lab/evidencias/auth.log
grep -n 'contract-temp' /opt/lab/evidencias/auth.log
```

- `wc -l` conta as linhas do arquivo.
- `head -n 3` exibe as três primeiras linhas; `tail -n 3` exibe as três últimas.
- `grep -c` conta as linhas que correspondem ao padrão.
- `grep` sem `-c` exibe as linhas correspondentes; `-n` acrescenta o número da linha.
- Aspas simples preservam o padrão passado ao `grep` sem expansão do shell.

**Tarefa de auditoria:** conte as falhas de autenticação. Identifique a conta que acumula falhas e verifique se há um sucesso posterior para essa mesma conta. Registre horário, usuário, resultado e origem conforme aparecem nos dados.

As falhas e o sucesso posterior são indícios que devem ser correlacionados com outras fontes, como registros de identidade, atividade autorizada e logs do serviço. Um resultado de `grep` não prova comprometimento.

### Atividade 5 — Campos, filtros e pipelines

As amostras CSV deste laboratório usam campos simples, sem vírgulas dentro de aspas. `cut -d,` e `awk -F,` são adequados para essa amostra, mas não fazem parsing completo de CSV com campos entre aspas ou vírgulas escapadas.

Execute:

```bash
cut -d, -f2 /opt/lab/evidencias/ids-alertas.csv | tail -n +2
awk -F, 'NR > 1 && $4 == "HIGH" {print $2}' /opt/lab/evidencias/ids-alertas.csv
awk -F, 'NR > 1 && $6 == "OPEN" {print $1, $2, $3, $4}' /opt/lab/evidencias/ids-alertas.csv
awk -F, 'NR > 1 && $4 == "NONE" {print}' /opt/lab/evidencias/mudancas.csv
```

Em `awk`, `-F,` define a vírgula como separador, `NR` é o número do registro, e `$1`, `$2` etc. representam os campos. `NR > 1` ignora o cabeçalho. As condições selecionam alertas de alta severidade (`$4 == "HIGH"`), alertas abertos (`$6 == "OPEN"`) e mudanças sem aprovador registrado (`$4 == "NONE"`).

Agora conte os alertas de alta severidade por IP de origem:

```bash
awk -F, 'NR > 1 && $4 == "HIGH" {print $2}' /opt/lab/evidencias/ids-alertas.csv \
  | sort \
  | uniq -c \
  | sort -nr
```

O símbolo `|` encaminha a saída de um comando para a entrada do próximo:

1. `awk` seleciona os IPs dos alertas de alta severidade.
2. `sort` coloca IPs iguais em linhas adjacentes.
3. `uniq -c` conta cada grupo de linhas iguais.
4. `sort -nr` ordena a contagem numericamente, da maior para a menor.

`uniq -c` conta apenas repetições adjacentes; por isso, o primeiro `sort` é necessário.

**Tarefas de auditoria:**

1. Liste os alertas de alta severidade que permanecem abertos.
2. Verifique se alertas diferentes compartilham o mesmo IP de origem.
3. Identifique as mudanças sem aprovador registrado.
4. Para cada condição, descreva o critério que deveria ser atendido e a evidência que ainda precisaria obter.
5. Antes de classificar qualquer registro como incidente, indique quais fontes adicionais consultaria e por quê.

### Atividade 6 — Redirecionamento, erros e hash

Execute:

```bash
grep 'result=FAIL' /opt/lab/evidencias/auth.log > ~/entrega/falhas.txt
wc -l ~/entrega/falhas.txt
ls /opt/lab/evidencias/arquivo-inexistente.txt > ~/entrega/saida.txt 2> ~/entrega/erros.txt
status=$?
printf 'exit=%s\n' "$status"
cat ~/entrega/saida.txt
cat ~/entrega/erros.txt
```

- `>` envia a saída padrão (stdout) para um arquivo e substitui seu conteúdo anterior.
- `2>` envia a saída de erro (stderr) para outro arquivo.
- Como o arquivo pedido ao `ls` não existe, o comando deve terminar com código diferente de zero; a mensagem de erro fica em `erros.txt`.
- `status=$?` guarda o código de saída do comando executado imediatamente antes. Por isso, não execute outro comando entre `ls` e essa atribuição.
- `cat` permite conferir separadamente os dois arquivos. `saida.txt` pode ficar vazio, pois a lista foi direcionada para lá e não houve resultado.

Agora filtre os alertas abertos, mostre-os na tela e guarde uma cópia:

```bash
awk -F, 'NR > 1 && $6 == "OPEN" {print $1, $2, $3, $4}' /opt/lab/evidencias/ids-alertas.csv \
  | tee ~/entrega/alertas-abertos.txt
sha256sum /opt/lab/evidencias/ids-alertas.csv ~/entrega/alertas-abertos.txt
```

`tee` grava a saída no arquivo e também a exibe no terminal. `sha256sum` calcula um resumo criptográfico dos bytes de cada arquivo. Se o conteúdo mudar, o hash normalmente muda; o hash, isoladamente, não comprova autoria, origem ou autenticidade. Para demonstrar integridade, registre o hash junto com a origem, o horário e o procedimento de coleta.

### Atividade 7 — Processo, porta e logs

Execute dentro do contêiner:

```bash
ps -ef
ps -ef | grep '[h]ttp.server'
ss -lnt
curl -I http://127.0.0.1:8080
```

- `ps -ef` lista processos em execução.
- `grep '[h]ttp.server'` localiza o servidor Python sem que a própria linha do `grep` apareça como resultado.
- `ss -lnt` lista sockets TCP em escuta; `-l` seleciona sockets em escuta, `-n` exibe números sem resolução de nomes e `-t` seleciona TCP.
- `curl -I` solicita apenas os cabeçalhos HTTP da página local.

Relacione o processo Python à porta `8080` e confirme que o servidor responde. A porta não é publicada no computador: o `curl` deve ser executado dentro do contêiner.

Para observar o log da requisição, abra **outro terminal do computador**, entre na mesma pasta `pratica-linux` e execute:

```bash
./lab.sh logs
```

Se estiver usando `LAB_PROJECT`, defina novamente essa variável nesse segundo terminal. Observe o registro gerado pelo `curl`. Relacione o evento ao processo e à porta, mas não conclua que o serviço está seguro apenas porque respondeu. Da mesma forma, `ss` não demonstra que todo o tráfego está sendo monitorado por um IDS.

### Atividade 8 — Acompanhar um registro em tempo real

Mantenha o primeiro shell do contêiner aberto. Abra um **segundo shell do contêiner** pelo terminal do computador:

```bash
./lab.sh shell
```

Se estiver usando `LAB_PROJECT`, mantenha o mesmo valor também nesse terminal. No primeiro shell, copie o registro e inicie o acompanhamento:

```bash
cp /opt/lab/evidencias/auth.log ~/entrega/auth-live.log
tail -n 0 -f ~/entrega/auth-live.log
```

`tail -f` continua observando o arquivo e mostra linhas acrescentadas. `-n 0` evita reexibir o conteúdo que já estava no arquivo.

No segundo shell, acrescente uma linha sintética à cópia:

```bash
printf '%s\n' 'timestamp=2026-11-19T13:00:00Z user=lab-demo result=FAIL source=192.0.2.99' \
  >> ~/entrega/auth-live.log
```

A linha deve aparecer no primeiro shell. Interrompa o acompanhamento com `Ctrl+C`. `>>` acrescenta a linha sem apagar o conteúdo existente. Você alterou uma cópia em `~/entrega`, não a evidência-fonte em `/opt/lab/evidencias`.

### Atividade 9 — Redigir o papel de trabalho

O arquivo `~/entrega/relatorio.md` já está no volume persistente. Abra-o dentro do contêiner:

```bash
nano ~/entrega/relatorio.md
```

No `nano`, edite o texto, salve com `Ctrl+O`, confirme com `Enter` e saia com `Ctrl+X`. Preencha:

- **Objetivo, escopo e critério:** o que foi examinado, em qual período e contra qual regra ou controle?
- **Procedimentos e evidências:** quais comandos executou, quais arquivos consultou e quais resultados guardou?
- **Amostra e limitações:** quais registros analisou e o que os dados não permitem concluir?
- **Achado:** descreva critério, condição observada, causa (se comprovada) e efeito ou risco.
- **Recomendação:** que ação reduziria o risco e qual evidência deveria ser apresentada para validar a correção?
- **Conclusão:** o que os resultados sustentam, sem extrapolar além das evidências?

Diferencie observação de conclusão. Por exemplo, um alerta aberto é uma observação; para afirmar incidente, você precisaria corroborar a atividade com fontes confiáveis e contexto. Declare no relatório que os arquivos deste laboratório são sintéticos.

Saia do shell do contêiner e copie o relatório para o computador:

```bash
exit
./lab.sh collect
```

O relatório ficará em `entrega/relatorio.md`, na pasta `pratica-linux`. Esse arquivo local não é incluído no Git. Entregue-o conforme as instruções da disciplina.

## 5. Confira suas hipóteses

Use esta seção depois de executar as atividades e escrever suas respostas. Ela indica pontos que devem aparecer na análise, não conclusões prontas:

- **Inventário:** `relatorios` aparece como ativo de média criticidade sem sensor indicado. Confirme se há sensor fora do inventário, monitoramento centralizado ou controle compensatório.
- **Contas:** `acessos.csv` inclui contas administrativas com titular compartilhado ou revisão `NEVER`. Verifique necessidade, titularidade, aprovação, último uso e revisão periódica.
- **Mudanças:** `mudancas.csv` tem registros com `approved_by` igual a `NONE`. Consulte chamados, processo de aprovação, trilha de implantação e eventual justificativa emergencial.
- **Autenticação e IDS:** falhas de `contract-temp` e alertas de `198.51.100.27` se relacionam na amostra, e há sucesso posterior. Correlacione com identidade, horário, autorização e logs do serviço antes de concluir.
- **Configuração:** `app.conf` indica `DEBUG=true` e `APP_ENV=production`. Valide que o arquivo representa a configuração efetiva; ele é ilustrativo e não configura o servidor HTTP do laboratório.
- **Permissões:** `config-compartilhado.conf` concede escrita ao grupo. Identifique quem pertence ao grupo, se a escrita é necessária e como as alterações são controladas. O sistema de arquivos somente leitura do contêiner não substitui o controle de acesso de um sistema real.
- **Arquivo restrito:** a leitura negada de `restrito-demo.txt` é o comportamento esperado para o usuário do laboratório. A negativa, por si só, não é uma falha.

## 6. Encerrar o laboratório e preservar a entrega

No terminal do computador, confirme o estado e pare o laboratório:

```bash
./lab.sh status
./lab.sh down
```

O contêiner e a rede do projeto serão removidos; o volume com `relatorio.md` permanecerá. Para continuar em outro momento, execute `./lab.sh up` e depois `./lab.sh shell`. Para copiar novamente o relatório ao computador, use `./lab.sh collect`.

## Consulta rápida

Dentro do contêiner, consulte os manuais:

```bash
man ls
man chmod
man find
man grep
man awk
man bash
```

No manual, digite `/termo` para buscar, pressione `n` para ir ao próximo resultado e `q` para sair. Este contêiner Debian não inicia `systemd`; portanto, `systemctl` e `journalctl` não fazem parte desta prática.
