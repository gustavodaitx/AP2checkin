import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Tipo de resultado para a exibição visual após a leitura do QR Code
enum TipoResultadoCheckin {
  sucesso,
  duplicado,
  invalido,
}

class TelaPrincipal extends StatefulWidget {
  const TelaPrincipal({super.key});

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  // Controllers dos campos de texto (Requisito R2)
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // Estados de navegação e controle de scanner (Requisitos R4 e R6)
  bool _lendoQrCode = false;
  bool _processandoQr = false;
  MobileScannerController? _scannerController;

  // Estados do ingresso gerado (Requisitos R2 e R3)
  bool _ingressoGerado = false;
  String _ingressoNome = '';
  String _ingressoEmail = '';
  String _ingressoConteudo = '';

  // Lista de presença mantida em memória (Requisitos R7 e R8)
  final List<String> _presentes = [];

  // Resultado da última leitura (Requisito R7)
  TipoResultadoCheckin? _ultimoResultadoTipo;
  String? _ultimoResultadoMensagem;
  String? _ultimoParticipanteNome;

  // Paleta de cores do tema do evento (Verde-petróleo / Material 3)
  static const Color _corPrimaria = Color(0xFF00695C); // Teal escuro
  static const Color _corSecundaria = Color(0xFF00897B);
  static const Color _corFundo = Color(0xFFF7FAF9);
  static const Color _corSucesso = Color(0xFF2E7D32); // Verde
  static const Color _corAlerta = Color(0xFFE65100); // Laranja/Amarelo
  static const Color _corErro = Color(0xFFC62828); // Vermelho

  @override
  void initState() {
    super.initState();
    // Atualiza a interface quando o nome é alterado para habilitar/desabilitar o botão
    _nomeController.addListener(_aoMudarTexto);
  }

  void _aoMudarTexto() {
    setState(() {});
  }

  @override
  void dispose() {
    _nomeController.removeListener(_aoMudarTexto);
    _nomeController.dispose();
    _emailController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  /// Gera o ingresso com QR Code (Requisitos R2 e R3)
  void _gerarIngresso() {
    final nome = _nomeController.text.trim();
    if (nome.isEmpty) return;

    final email = _emailController.text.trim();
    // Formato obrigatório: CHECKIN|nome|e-mail
    final conteudo = 'CHECKIN|$nome|$email';

    setState(() {
      _ingressoNome = nome;
      _ingressoEmail = email;
      _ingressoConteudo = conteudo;
      _ingressoGerado = true;
    });

    // Oculta o teclado
    FocusScope.of(context).unfocus();
  }

  /// Inicia a leitura do QR Code abrindo a interface da câmera (Requisito R4)
  void _abrirScanner() {
    setState(() {
      _processandoQr = false;
      _lendoQrCode = true;
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
      );
    });
  }

  /// Cancela a leitura da câmera e retorna à tela principal sem registrar presença (Requisito R4)
  void _cancelarScanner() {
    _scannerController?.dispose();
    _scannerController = null;
    setState(() {
      _lendoQrCode = false;
      _processandoQr = false;
    });
  }

  /// Callback do mobile_scanner para detecção única de QR Code (Requisito R6)
  void _aoDetectar(BarcodeCapture capture) {
    // Previne leituras repetidas enquanto processa
    if (_processandoQr) return;
    if (capture.barcodes.isEmpty) return;

    final String? codigo = capture.barcodes.first.rawValue;
    if (codigo == null || codigo.isEmpty) return;

    _processandoQr = true;

    // Encerra a câmera e fecha a visualização do scanner
    _scannerController?.stop();
    _scannerController?.dispose();
    _scannerController = null;

    if (!mounted) return;

    setState(() {
      _lendoQrCode = false;
    });

    _processarQrCode(codigo);
  }

  /// Valida o ingresso de acordo com as regras de negócio R7
  void _processarQrCode(String codigo) {
    final partes = codigo.split('|');

    // Validação estrutural: exatamente 3 partes, prefixo CHECKIN e nome não vazio
    final bool ingressoValido = partes.length == 3 &&
        partes[0] == 'CHECKIN' &&
        partes[1].trim().isNotEmpty;

    if (!ingressoValido) {
      // Resultado 3 — QR inválido
      setState(() {
        _ultimoResultadoTipo = TipoResultadoCheckin.invalido;
        _ultimoResultadoMensagem = '✖ QR inválido';
        _ultimoParticipanteNome = null;
      });
      return;
    }

    final nome = partes[1].trim();

    // Verificação de duplicidade: case-insensitive e sem espaços extras nas extremidades
    final bool jaPresente = _presentes.any(
      (p) => p.trim().toLowerCase() == nome.toLowerCase(),
    );

    if (jaPresente) {
      // Resultado 2 — Já fez check-in
      setState(() {
        _ultimoResultadoTipo = TipoResultadoCheckin.duplicado;
        _ultimoResultadoMensagem = '⚠ Já fez check-in';
        _ultimoParticipanteNome = nome;
      });
    } else {
      // Resultado 1 — Check-in confirmado
      setState(() {
        _presentes.add(nome); // Preserva a grafia original para exibição
        _ultimoResultadoTipo = TipoResultadoCheckin.sucesso;
        _ultimoResultadoMensagem = '✔ Check-in confirmado';
        _ultimoParticipanteNome = nome;
      });
    }
  }

  // Métodos e getters para automação de testes dos cenários obrigatórios (Seção 8)
  @visibleForTesting
  void processarCodigoTeste(String codigo) => _processarQrCode(codigo);

  @visibleForTesting
  List<String> get presentesTeste => _presentes;

  @visibleForTesting
  String? get ultimoResultadoMensagemTeste => _ultimoResultadoMensagem;

  @visibleForTesting
  TipoResultadoCheckin? get ultimoResultadoTipoTeste => _ultimoResultadoTipo;

  @visibleForTesting
  String get ingressoConteudoTeste => _ingressoConteudo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lendoQrCode ? Colors.black : _corFundo,
      appBar: AppBar(
        title: const Text(
          'Semana da Computação 2026',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: _corPrimaria,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      // Navegação condicional entre scanner e tela principal (Requisito R4)
      body: _lendoQrCode
          ? _construirTelaScanner()
          : _construirTelaPrincipal(),
    );
  }

  /// Constrói a tela principal com o formulário, card, check-in e presentes (Requisito R1 e Seção 5)
  Widget _construirTelaPrincipal() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Campo Nome do participante (Requisito R2)
          TextField(
            controller: _nomeController,
            decoration: InputDecoration(
              labelText: 'Nome do participante',
              hintText: 'Digite o nome completo',
              prefixIcon: const Icon(Icons.person_outline, color: _corPrimaria),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _corPrimaria, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Campo E-mail (Requisito R2)
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'E-mail',
              hintText: 'Digite o e-mail (opcional)',
              prefixIcon: const Icon(Icons.email_outlined, color: _corPrimaria),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _corPrimaria, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 3. Botão Gerar ingresso (Requisito R2)
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: _corPrimaria,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 1,
            ),
            onPressed: _nomeController.text.trim().isEmpty ? null : _gerarIngresso,
            icon: const Icon(Icons.qr_code_2_rounded),
            label: const Text(
              'Gerar ingresso',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24),

          // 4. Card do ingresso gerado, inicialmente oculto (Requisitos R2 e R3)
          if (_ingressoGerado) ...[
            _construirCardIngresso(),
            const SizedBox(height: 24),
          ],

          // 5. Divisor visual (Seção 5)
          const Divider(height: 32, thickness: 1.2),

          // 6. Título Check-in (Seção 5)
          Text(
            'Check-in',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _corPrimaria,
                ),
          ),
          const SizedBox(height: 12),

          // 7. Botão Ler ingresso (Requisito R4)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: _corPrimaria,
              side: const BorderSide(color: _corPrimaria, width: 1.8),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _abrirScanner,
            icon: const Icon(Icons.qr_code_scanner, size: 24),
            label: const Text(
              'Ler ingresso',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),

          // 8. Área de resultado da leitura (Requisito R7)
          _construirAreaResultado(),
          const SizedBox(height: 24),

          // 9 e 10. Título Presentes (N) e Lista de participantes confirmados (Requisito R8)
          _construirListaPresentes(),
        ],
      ),
    );
  }

  /// Constrói o Card do ingresso no formato de crachá oficial (Requisitos R2 e R3)
  Widget _construirCardIngresso() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Área superior do Card para imagem ou espaço visual do evento (R2)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_corPrimaria, _corSecundaria],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.event_available,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SEMANA DA COMPUTAÇÃO 2026',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Ingresso Oficial do Participante',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Corpo do Card: dados do participante e QR Code
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Text(
                  _ingressoNome,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (_ingressoEmail.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _ingressoEmail,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
                const SizedBox(height: 18),

                // QR Code gerado com qr_flutter: ^4.1.0 (Requisito R3)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, width: 1.2),
                  ),
                  child: QrImageView(
                    data: _ingressoConteudo,
                    version: QrVersions.auto,
                    size: 180,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Apresente este código no leitor do credenciamento',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói a área visual para o resultado do check-in (Requisito R7)
  Widget _construirAreaResultado() {
    if (_ultimoResultadoTipo == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey.shade600, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Nenhum check-in realizado nesta sessão.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Color corFundo;
    Color corBorda;
    Color corTexto;
    IconData icone;

    switch (_ultimoResultadoTipo!) {
      case TipoResultadoCheckin.sucesso:
        corFundo = const Color(0xFFE8F5E9); // Verde claro
        corBorda = _corSucesso;
        corTexto = _corSucesso;
        icone = Icons.check_circle_outline;
        break;
      case TipoResultadoCheckin.duplicado:
        corFundo = const Color(0xFFFFF3E0); // Laranja claro
        corBorda = _corAlerta;
        corTexto = _corAlerta;
        icone = Icons.warning_amber_rounded;
        break;
      case TipoResultadoCheckin.invalido:
        corFundo = const Color(0xFFFFEBEE); // Vermelho claro
        corBorda = _corErro;
        corTexto = _corErro;
        icone = Icons.cancel_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: corFundo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: corBorda, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icone, color: corTexto, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _ultimoResultadoMensagem ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: corTexto,
                  ),
                ),
                if (_ultimoParticipanteNome != null &&
                    _ultimoParticipanteNome!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Participante: $_ultimoParticipanteNome',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói a lista de presença com contador de confirmados (Requisito R8)
  Widget _construirListaPresentes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título Presentes (N)
        Text(
          'Presentes (${_presentes.length})',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: _corPrimaria,
                fontSize: 17,
              ),
        ),
        const SizedBox(height: 10),

        if (_presentes.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Text(
              'Nenhum participante confirmado ainda.',
              style: TextStyle(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
                fontSize: 14,
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                for (int i = 0; i < _presentes.length; i++) ...[
                  if (i > 0)
                    Divider(height: 1, color: Colors.grey.shade200),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: _corSecundaria,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _presentes[i],
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  /// Constrói a tela de leitura do QR Code usando mobile_scanner (Requisitos R4, R5 e R6)
  Widget _construirTelaScanner() {
    return Stack(
      children: [
        // Fundo escuro e visualização da câmera
        Container(
          color: Colors.black,
          width: double.infinity,
          height: double.infinity,
          child: _scannerController != null
              ? MobileScanner(
                  controller: _scannerController!,
                  onDetect: _aoDetectar,
                  errorBuilder: (context, error, child) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.videocam_off_outlined,
                              color: Colors.white70,
                              size: 56,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Não foi possível acessar a câmera.\nVerifique se as permissões foram concedidas no dispositivo.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                )
              : const SizedBox.shrink(),
        ),

        // Moldura visual de enquadramento do QR Code e orientação
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Moldura de enquadramento
              Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF80CBC4),
                    width: 3.5,
                  ),
                  color: Colors.transparent,
                ),
              ),
              const SizedBox(height: 24),

              // Texto orientando o usuário (Seção 5)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Aponte para o QR do ingresso',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Botão Cancelar na parte inferior (Requisito R4)
        Positioned(
          bottom: 40,
          left: 32,
          right: 32,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: const BorderSide(color: Colors.white70, width: 1.5),
              ),
            ),
            onPressed: _cancelarScanner,
            icon: const Icon(Icons.close),
            label: const Text(
              'Cancelar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
