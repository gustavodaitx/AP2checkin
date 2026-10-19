import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ap2_checkin/main.dart';
import 'package:ap2_checkin/tela_principal.dart';

void main() {
  testWidgets('Cenário A e B: Validação do botão e geração do ingresso',
      (WidgetTester tester) async {
    await tester.pumpWidget(const AppCheckinEvento());
    await tester.pumpAndSettle();

    // Cenário B: Inicialmente o botão Gerar ingresso está desabilitado
    final botaoGerarFinder = find.widgetWithText(FilledButton, 'Gerar ingresso');
    expect(botaoGerarFinder, findsOneWidget);

    FilledButton botaoGerar = tester.widget<FilledButton>(botaoGerarFinder);
    expect(botaoGerar.onPressed, isNull,
        reason: 'Botão deve estar desabilitado quando o nome está vazio');

    // Digita apenas espaços em branco no campo Nome
    final campoNomeFinder = find.widgetWithText(TextField, 'Nome do participante');
    await tester.enterText(campoNomeFinder, '     ');
    await tester.pumpAndSettle();

    botaoGerar = tester.widget<FilledButton>(botaoGerarFinder);
    expect(botaoGerar.onPressed, isNull,
        reason: 'Botão deve continuar desabilitado com nome contendo apenas espaços');

    // Cenário A: Preenche com dados válidos (Ana Souza / ana@email.com)
    await tester.enterText(campoNomeFinder, 'Ana Souza');
    final campoEmailFinder = find.widgetWithText(TextField, 'E-mail');
    await tester.enterText(campoEmailFinder, 'ana@email.com');
    await tester.pumpAndSettle();

    botaoGerar = tester.widget<FilledButton>(botaoGerarFinder);
    expect(botaoGerar.onPressed, isNotNull,
        reason: 'Botão deve ficar habilitado quando o nome for preenchido');

    // Clica no botão Gerar ingresso
    await tester.tap(botaoGerarFinder);
    await tester.pumpAndSettle();

    // Card do ingresso deve aparecer
    expect(find.byType(Card), findsOneWidget);
    expect(find.text('SEMANA DA COMPUTAÇÃO 2026'), findsWidgets);
    expect(find.text('Ingresso Oficial do Participante'), findsOneWidget);
    // Aparece no TextField e no Card
    expect(find.text('Ana Souza'), findsNWidgets(2));
    expect(find.text('ana@email.com'), findsNWidgets(2));

    // Valida o conteúdo exato do QR Code
    final state = tester.state(find.byType(TelaPrincipal)) as dynamic;
    expect(state.ingressoConteudoTeste, equals('CHECKIN|Ana Souza|ana@email.com'));
  });

  testWidgets('Cenários C, D, E e H: Validação de regras de check-in e presença',
      (WidgetTester tester) async {
    await tester.pumpWidget(const AppCheckinEvento());
    await tester.pumpAndSettle();

    final state = tester.state(find.byType(TelaPrincipal)) as dynamic;

    // Estado inicial da lista de presença
    expect(find.text('Presentes (0)'), findsOneWidget);
    expect(find.text('Nenhum participante confirmado ainda.'), findsOneWidget);

    // Cenário C: Primeiro check-in de Ana Souza
    state.processarCodigoTeste('CHECKIN|Ana Souza|ana@email.com');
    await tester.pumpAndSettle();

    expect(find.text('✔ Check-in confirmado'), findsOneWidget);
    expect(find.text('Presentes (1)'), findsOneWidget);
    expect(state.presentesTeste, contains('Ana Souza'));

    // Cenário D: Check-in duplicado de Ana Souza
    state.processarCodigoTeste('CHECKIN|Ana Souza|ana@email.com');
    await tester.pumpAndSettle();

    expect(find.text('⚠ Já fez check-in'), findsOneWidget);
    expect(find.text('Presentes (1)'), findsOneWidget);
    expect(state.presentesTeste.length, equals(1));

    // Cenário D: Check-in duplicado ignorando maiúsculas/minúsculas ("ana souza")
    state.processarCodigoTeste('CHECKIN|ana souza|outro@email.com');
    await tester.pumpAndSettle();

    expect(find.text('⚠ Já fez check-in'), findsOneWidget);
    expect(find.text('Presentes (1)'), findsOneWidget);

    // Cenário E: QR Code inválido - URL
    state.processarCodigoTeste('https://example.com');
    await tester.pumpAndSettle();

    expect(find.text('✖ QR inválido'), findsOneWidget);
    expect(find.text('Presentes (1)'), findsOneWidget);

    // Cenário E: QR Code inválido - Texto aleatório
    state.processarCodigoTeste('TEXTO ALEATORIO');
    await tester.pumpAndSettle();

    expect(find.text('✖ QR inválido'), findsOneWidget);
    expect(find.text('Presentes (1)'), findsOneWidget);

    // Cenário E: QR Code inválido - Menos partes
    state.processarCodigoTeste('CHECKIN|Ana Souza');
    await tester.pumpAndSettle();

    expect(find.text('✖ QR inválido'), findsOneWidget);
    expect(find.text('Presentes (1)'), findsOneWidget);

    // Cenário E: QR Code inválido - Nome vazio
    state.processarCodigoTeste('CHECKIN||ana@email.com');
    await tester.pumpAndSettle();

    expect(find.text('✖ QR inválido'), findsOneWidget);
    expect(find.text('Presentes (1)'), findsOneWidget);

    // Cenário H: QR Code inválido - Separadores extras
    state.processarCodigoTeste('CHECKIN|Ana Souza|ana@email.com|EXTRA');
    await tester.pumpAndSettle();

    expect(find.text('✖ QR inválido'), findsOneWidget);
    expect(find.text('Presentes (1)'), findsOneWidget);

    // Check-in com e-mail vazio permitido (conforme R2 e R7)
    state.processarCodigoTeste('CHECKIN|Carlos Lima|');
    await tester.pumpAndSettle();

    expect(find.text('✔ Check-in confirmado'), findsOneWidget);
    expect(find.text('Presentes (2)'), findsOneWidget);
    expect(state.presentesTeste, contains('Carlos Lima'));
  });

  testWidgets('Cenário F: Cancelar scanner e preservar estado da tela principal',
      (WidgetTester tester) async {
    await tester.pumpWidget(const AppCheckinEvento());
    await tester.pumpAndSettle();

    final state = tester.state(find.byType(TelaPrincipal)) as dynamic;

    // Adiciona um participante prévio
    state.processarCodigoTeste('CHECKIN|Ana Souza|ana@email.com');
    await tester.pumpAndSettle();
    expect(find.text('Presentes (1)'), findsOneWidget);

    // Clica no botão "Ler ingresso" para abrir a tela de scanner
    final botaoLerFinder = find.widgetWithText(OutlinedButton, 'Ler ingresso');
    await tester.tap(botaoLerFinder);
    await tester.pumpAndSettle();

    // Verifica que a interface do scanner é exibida
    expect(find.text('Aponte para o QR do ingresso'), findsOneWidget);
    final botaoCancelarFinder = find.widgetWithText(FilledButton, 'Cancelar');
    expect(botaoCancelarFinder, findsOneWidget);

    // Pressiona o botão "Cancelar"
    await tester.tap(botaoCancelarFinder);
    await tester.pumpAndSettle();

    // Verifica que a tela principal retornou com a lista intacta
    expect(find.text('Aponte para o QR do ingresso'), findsNothing);
    expect(find.text('Presentes (1)'), findsOneWidget);
    expect(state.presentesTeste.length, equals(1));
    expect(state.presentesTeste, contains('Ana Souza'));
  });
}
