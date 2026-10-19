AP2 — Aplicativo de Check-in de Evento em Flutter
1. Objetivo

Implemente um aplicativo Flutter completo para a AP2 — App de Check-in de Evento, utilizando o projeto Flutter já aberto no Android Studio.

O aplicativo deve permitir gerar ingressos com QR Code, ler os QR Codes dos participantes usando a câmera do dispositivo, validar os ingressos e controlar a lista de presença.

Siga os requisitos funcionais, as regras de negócio e a estrutura visual descritos neste documento. As imagens de referência fornecidas pelo usuário devem ser utilizadas como orientação para a organização das telas.

Importante: não entregue apenas exemplos de código ou explicações. Analise o projeto existente e implemente as funcionalidades diretamente nos arquivos apropriados.

2. Tecnologias obrigatórias
Flutter.
Dart.
Material Design.
qr_flutter: ^4.1.0
mobile_scanner: ^5.0.0

Utilize as versões especificadas acima, salvo se houver uma incompatibilidade comprovada com a versão do Flutter do projeto. Caso exista incompatibilidade, explique o problema antes de propor uma alteração.

Não substitua esses pacotes por bibliotecas equivalentes sem necessidade.

3. Requisitos funcionais
R1 — Página principal

Crie uma página principal utilizando StatefulWidget.

A tela deve conter:

AppBar com o título Semana da Computação 2026.
Tema visual próprio, preferencialmente com tons de verde ou verde-petróleo.
Formulário para os dados do participante.
Botão para gerar o ingresso.
Card do ingresso gerado.
Botão para iniciar a leitura de QR Codes.
Área para apresentar o resultado do check-in.
Lista de presença com contador de participantes.

Organize os componentes em uma única página principal, permitindo rolagem vertical quando necessário.

R2 — Formulário e geração do ingresso

Crie dois campos de texto:

Nome do participante.
E-mail do participante.

Utilize TextEditingController para controlar os campos e libere os controllers com dispose().

O botão Gerar ingresso deve permanecer desabilitado enquanto o nome estiver vazio ou contiver apenas espaços.

Utilize trim() para remover espaços desnecessários do nome.

Exemplo de comportamento esperado:

FilledButton(
  onPressed: _nomeController.text.trim().isEmpty
      ? null
      : _gerarIngresso,
  child: const Text('Gerar ingresso'),
)


Atualize a interface durante a digitação com setState().

Ao pressionar o botão:

Leia e normalize o nome e o e-mail.
Gere o conteúdo do QR Code no formato obrigatório.
Exiba um Card de ingresso.
Mostre o nome e o e-mail informados.
Exiba o QR Code correspondente.
Inclua uma área superior no Card destinada à imagem do evento.

O Card só deve aparecer depois que o ingresso for gerado.

Se o e-mail estiver vazio, não invente um endereço. Como o requisito obrigatório para habilitar o botão é o nome, mantenha esse comportamento e permita gerar o ingresso com o e-mail vazio.

R3 — Formato obrigatório do QR Code

Todos os ingressos devem utilizar exatamente o seguinte formato:

CHECKIN|nome|e-mail


Exemplo:

CHECKIN|Ana Souza|ana@email.com


Para gerar o conteúdo:

final conteudo =
    'CHECKIN|${_nomeController.text.trim()}|${_emailController.text.trim()}';


Utilize o pacote qr_flutter para renderizar o QR Code na tela.

Exemplo:

QrImageView(
  data: conteudo,
  version: QrVersions.auto,
  size: 180,
)


Utilize a API compatível com qr_flutter: ^4.1.0.

Regra fundamental: não altere o prefixo CHECKIN, não substitua o separador | e não utilize URLs como conteúdo dos ingressos.

O QR Code precisa ser legível por outros celulares que executem o aplicativo.

R4 — Leitura do QR Code

Implemente a leitura usando mobile_scanner: ^5.0.0.

Na página principal, o botão Ler ingresso deve abrir a interface da câmera, substituindo temporariamente a página principal.

Utilize uma estrutura condicional com if, conforme o conceito de navegação condicional apresentado na Aula 10.

Por exemplo, controle a exibição da tela com uma variável booleana:

bool _lendoQrCode = false;


A estrutura geral deve seguir esta ideia:

body: _lendoQrCode
    ? _construirTelaScanner()
    : _construirTelaPrincipal(),


Adapte o código à estrutura real do projeto.

A tela de leitura deve conter:

A mesma AppBar com o nome do evento.
Visualização da câmera ocupando praticamente toda a tela.
Fundo escuro.
Moldura visual indicando a área de leitura.
Texto orientando o usuário a apontar para o QR Code.
Botão Cancelar na parte inferior.

O botão Cancelar deve retornar à página principal sem registrar presença e sem apresentar um resultado de leitura.

R5 — Permissões da câmera

Configure as permissões necessárias para Android e iOS.

Android

Verifique o arquivo:

android/app/src/main/AndroidManifest.xml

Inclua a permissão de câmera antes da declaração da tag <application>:

<uses-permission android:name="android.permission.CAMERA" />

iOS

Verifique o arquivo:

ios/Runner/Info.plist

Inclua a descrição de uso da câmera:

<key>NSCameraUsageDescription</key>
<string>A câmera será utilizada para ler os QR Codes dos ingressos do evento.</string>


Preserve as demais configurações existentes nesses arquivos.

O aplicativo deve solicitar as permissões necessárias quando o scanner for utilizado e tratar a situação em que a permissão for negada, apresentando uma mensagem compreensível ao usuário.

Não prometa funcionamento da câmera sem verificar as permissões e a configuração da plataforma.

R6 — Leitura única e prevenção de leituras repetidas

Cada abertura do scanner deve processar apenas um QR Code.

Configure o MobileScanner para ignorar novas leituras depois que a primeira leitura válida ou inválida tiver sido capturada.

Utilize uma variável de controle, como:

bool _processandoQr = false;


No callback onDetect:

Verifique se já existe uma leitura em processamento.
Ignore o evento caso já tenha ocorrido uma leitura.
Marque a leitura como processada.
Extraia o conteúdo do QR Code.
Feche o scanner e retorne à página principal.
Exiba o resultado da validação.

Evite processar o mesmo QR Code várias vezes devido à repetição dos eventos da câmera.

Consulte a API do mobile_scanner: ^5.0.0 e implemente o callback de acordo com a versão instalada.

Garanta que a atualização da tela e a navegação ocorram de forma segura, verificando mounted quando necessário.

R7 — Validação do ingresso

O aplicativo deve apresentar exatamente três tipos de resultado.

Resultado 1 — Check-in confirmado

Condição:

O conteúdo possui três partes separadas por |.
A primeira parte é exatamente CHECKIN.
O nome do participante ainda não está na lista de presença.

Comportamento:

Adicionar o participante à lista de presença.
Exibir uma mensagem de sucesso em verde.
Mostrar o nome do participante.
Atualizar o contador da lista.

Mensagem:

✔ Check-in confirmado

Resultado 2 — Já fez check-in

Condição:

O QR Code é válido.
O nome do participante já consta na lista de presença.

Comportamento:

Não adicionar o participante novamente.
Não incrementar o contador.
Exibir uma mensagem de alerta em amarelo ou laranja.

Mensagem:

⚠ Já fez check-in

Resultado 3 — QR inválido

Condição:

O conteúdo não possui exatamente três partes separadas por |; ou
A primeira parte não é exatamente CHECKIN.

Comportamento:

Não adicionar ninguém à lista.
Não incrementar o contador.
Exibir uma mensagem de erro em vermelho.

Mensagem:

✖ QR inválido

Links, textos aleatórios, QR Codes de sites e quaisquer conteúdos que não sigam o formato obrigatório devem ser rejeitados.

Utilize a seguinte regra básica de validação:

final partes = codigo.split('|');

final ingressoValido =
    partes.length == 3 && partes[0] == 'CHECKIN';


Complete a validação para impedir que o nome seja vazio ou contenha apenas espaços.

O e-mail pode estar vazio, conforme a regra de geração do ingresso. Não exija que o conteúdo seja um endereço de e-mail válido se isso não for solicitado pelo enunciado.

Importante: valide a estrutura antes de acessar partes[1] ou partes[2], evitando erros de índice.

R8 — Lista de presença

Na página principal, exiba a seção Presentes (N), em que N representa a quantidade de participantes confirmados.

A lista deve apresentar:

Um contador atualizado automaticamente.
Um Text para cada nome.
Um ícone de confirmação ao lado de cada participante, se desejado.

Utilize uma lista de nomes mantida no estado do StatefulWidget.

Exemplo de estrutura:

Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text('Presentes (${_presentes.length})'),
    ..._presentes.map(
      (nome) => Text(nome),
    ),
  ],
)


Adapte essa estrutura para incluir espaçamento e ícones sem deixar de utilizar Column e Text, conforme solicitado na atividade.

Não permita nomes duplicados na lista.

4. Regras de negócio

Implemente as seguintes regras:

O nome é obrigatório para gerar um ingresso.
O e-mail pode ficar vazio.
O QR Code deve seguir o formato CHECKIN|nome|e-mail.
A validação deve verificar a estrutura do conteúdo antes de acessar suas partes.
Um QR Code inválido nunca pode gerar presença.
Um participante já presente não pode ser adicionado novamente.
O mesmo QR Code deve produzir o resultado de check-in duplicado após a primeira confirmação.
O scanner deve encerrar a leitura depois de detectar um único código.
Cancelar a leitura não pode adicionar participantes.
Os dados da lista devem permanecer durante a utilização do aplicativo, mesmo após abrir e fechar o scanner.

Para esta atividade, a lista de presença pode ficar em memória. Não implemente banco de dados, autenticação ou serviços externos sem necessidade.

Observação sobre a identificação dos participantes

O formato exigido pela atividade utiliza o nome para verificar duplicidade.

Utilize o nome normalizado, removendo espaços nas extremidades, para comparar participantes. A comparação deve ignorar diferenças entre letras maiúsculas e minúsculas, para evitar que Ana Souza e ana souza sejam contabilizados como pessoas diferentes.

Preserve a grafia original do nome para exibição na interface.

Não utilize o e-mail como requisito de identificação, pois a atividade define a comparação pela lista de nomes.

5. Interface visual

Utilize as imagens de referência fornecidas como orientação para as duas telas.

Tela principal

A disposição dos componentes deve seguir esta ordem:

AppBar com o título Semana da Computação 2026.
Campo Nome do participante.
Campo E-mail.
Botão Gerar ingresso.
Card do ingresso, inicialmente oculto.
Área superior do Card com imagem ou espaço visual para a imagem do evento.
Nome e e-mail do participante.
QR Code.
Divisor visual.
Título Check-in.
Botão Ler ingresso.
Área de resultado da leitura.
Título Presentes (N).
Lista de participantes confirmados.

Características visuais sugeridas:

Fundo claro.
AppBar verde-petróleo.
Botões arredondados.
Campos de texto com bordas discretas.
Card com cantos arredondados.
QR Code preto e branco com bom contraste.
Resultado de sucesso em verde.
Resultado de duplicidade em amarelo ou laranja.
Resultado inválido em vermelho.
Lista de presença com ícones de confirmação.

Mantenha os textos legíveis e o espaçamento adequado.

Utilize SingleChildScrollView ou uma estrutura equivalente para evitar overflow em telas menores.

Tela do scanner

A disposição deve seguir esta ordem:

AppBar com o nome do evento.
Fundo escuro ocupando a área disponível.
Visualização da câmera.
Moldura de enquadramento do QR Code.
Texto Aponte para o QR do ingresso.
Botão Cancelar na parte inferior.

Utilize MobileScanner para a câmera real. Não substitua a câmera por uma imagem estática ou por um campo de texto.

6. Organização do código

Antes de modificar os arquivos, inspecione a estrutura do projeto Flutter existente.

Implemente a solução de forma simples, clara e compatível com o nível de uma atividade acadêmica introdutória.

A organização sugerida é:

lib/main.dart: inicialização do aplicativo, tema e estrutura principal, se for conveniente manter tudo em um arquivo.
lib/tela_principal.dart: formulário, geração do ingresso, validação e lista de presença, se a separação facilitar a leitura.
lib/tela_scanner.dart: interface da câmera, se for conveniente separar a tela de leitura.

A separação em arquivos é opcional. A prioridade é produzir um aplicativo funcional, fácil de apresentar e explicar.

Use nomes de variáveis e métodos em português, de forma consistente.

Sugestões:

_nomeController
_emailController
_lendoQrCode
_processandoQr
_presentes
_ingressoGerado
_gerarIngresso()
_processarQrCode()
_construirTelaPrincipal()
_construirTelaScanner()

Gerencie corretamente o ciclo de vida dos controllers e do scanner.

Evite dependências desnecessárias e código excessivamente complexo.

7. Dependências

Confira o pubspec.yaml existente e adicione as dependências obrigatórias:

dependencies:
  flutter:
    sdk: flutter
  qr_flutter: ^4.1.0
  mobile_scanner: ^5.0.0


Preserve as outras dependências já existentes.

Depois, execute ou oriente a execução de:

flutter pub get


Não substitua todo o arquivo pubspec.yaml por um exemplo mínimo, pois isso pode remover configurações do projeto.

8. Testes e cenários obrigatórios

Confira se os seguintes cenários funcionam.

Cenário A — Gerar ingresso

Dados:

Nome: Ana Souza
E-mail: ana@email.com

Resultado esperado:

O botão fica habilitado.
O Card aparece.
O nome e o e-mail são exibidos.
O QR Code contém exatamente:
CHECKIN|Ana Souza|ana@email.com

Cenário B — Nome vazio

Dados:

Nome vazio ou contendo apenas espaços.

Resultado esperado:

O botão Gerar ingresso fica desabilitado.
Cenário C — Primeiro check-in

Leia o QR Code da Ana Souza, sem que ela esteja na lista.

Resultado esperado:

Mensagem ✔ Check-in confirmado.
Ana Souza aparece na lista.
O contador aumenta em um.
Cenário D — Check-in duplicado

Leia novamente o QR Code da Ana Souza.

Resultado esperado:

Mensagem ⚠ Já fez check-in.
Ana Souza permanece na lista apenas uma vez.
O contador não aumenta.
Cenário E — QR Code inválido

Leia um QR Code contendo:

https://example.com


Resultado esperado:

Mensagem ✖ QR inválido.
Nenhum participante é adicionado.

Repita com os seguintes conteúdos:

TEXTO ALEATORIO

CHECKIN|Ana Souza

CHECKIN||ana@email.com


Todos devem ser rejeitados.

Cenário F — Cancelar scanner

Abra o scanner e pressione Cancelar.

Resultado esperado:

A tela principal reaparece.
Nenhum participante é adicionado.
A lista de presença permanece intacta.
Cenário G — Ler ingresso de um colega

Gere um ingresso no aplicativo e leia o QR Code usando outro dispositivo com o aplicativo instalado.

Resultado esperado:

O QR Code é reconhecido.
O conteúdo é validado.
O resultado aparece na tela principal.

A validação é local ao dispositivo. Não implemente sincronização entre celulares ou alegue que a presença é compartilhada entre dispositivos, pois isso exigiria persistência ou comunicação adicional.

Cenário H — QR Code com separadores extras

Leia um código como:

CHECKIN|Ana Souza|ana@email.com|EXTRA


Resultado esperado:

Mensagem ✖ QR inválido, pois existem mais de três partes.
9. Testes em dispositivo

Sempre que possível, execute:

flutter analyze


Corrija os erros e os avisos relevantes introduzidos pela implementação.

Teste a câmera em um celular físico.

No emulador Android, caso a câmera virtual esteja disponível, configure a câmera traseira para utilizar Webcam0:

Device Manager → Edit → Camera → Back → Webcam0

O simulador de iOS pode não disponibilizar uma câmera utilizável para este teste.

Se não for possível executar o aplicativo ou testar a câmera no ambiente atual, informe claramente essa limitação. Não declare que os testes passaram sem executá-los.

10. Critérios de conclusão

Considere a atividade concluída somente quando:

A página principal utiliza StatefulWidget.
A AppBar apresenta o nome do evento.
Existem os dois campos de texto.
O botão de geração fica desabilitado com o nome vazio.
O Card aparece após gerar o ingresso.
O Card apresenta nome, e-mail e QR Code.
O conteúdo segue o formato obrigatório.
O scanner utiliza mobile_scanner.
A câmera tem as permissões necessárias.
O scanner lê apenas um QR Code por abertura.
Existe um botão Cancelar.
Os três resultados são exibidos corretamente.
A lista de presença utiliza contador, Column e Text.
Não existem participantes duplicados.
Os QR Codes inválidos não geram presença.
O projeto compila e não apresenta erros relevantes de análise.
11. Instruções finais para a implementação

Execute as seguintes etapas:

Inspecione os arquivos existentes e identifique a versão do Flutter e a estrutura do projeto.
Planeje as alterações mínimas necessárias.
Implemente a tela principal, o formulário e o Card do ingresso.
Implemente a geração do QR Code com qr_flutter.
Implemente a tela do scanner com mobile_scanner.
Configure as permissões de câmera para Android e iOS.
Implemente a validação dos três resultados.
Implemente a lista de presença e a prevenção de duplicidades.
Execute flutter pub get e flutter analyze, quando disponíveis.
Corrija os problemas encontrados e revise o fluxo completo.

Ao terminar, apresente um resumo dos arquivos criados ou modificados, explique como executar o aplicativo e informe quais verificações foram realmente realizadas.

Não entregue apenas instruções para o usuário implementar manualmente. Faça as alterações diretamente no projeto sempre que as ferramentas disponíveis permitirem.