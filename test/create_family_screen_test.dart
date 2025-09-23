import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardiao_familiar/create_family_screen.dart';

void main() {
  testWidgets('Teste CreateFamilyScreen - validação e clique no botão', (WidgetTester tester) async {
    // Cria a tela, passando um userId fictício
    await tester.pumpWidget(
      const MaterialApp(
        home: CreateFamilyScreen(userId: '123'),
      ),
    );

    // Verifica se o campo de texto está na tela
    expect(find.byType(TextField), findsOneWidget);

    // Verifica se o botão existe e está habilitado
    final criarButton = find.widgetWithText(ElevatedButton, 'CRIAR FAMÍLIA E ACESSAR');
    expect(criarButton, findsOneWidget);
    expect(tester.widget<ElevatedButton>(criarButton).enabled, isTrue);

    // Clica no botão sem preencher o nome (deve mostrar SnackBar)
    await tester.tap(criarButton);
    await tester.pump(); // Rebuild

    // Verifica se SnackBar aparece com a mensagem correta
    expect(find.text('Por favor, digite um nome para a família.'), findsOneWidget);

    // Preenche o campo de texto
    await tester.enterText(find.byType(TextField), 'Família Teste');
    await tester.pump();

    // Clica no botão novamente
    await tester.tap(criarButton);

    // Como o botão inicia requisição async, você pode fazer await no pump para dar tempo
    await tester.pump();

    // Aqui você poderia mockar a requisição HTTP para testar a navegação, 
    // mas isso já é mais avançado.

    // Só para garantir que a tela ainda está presente após o clique
    expect(find.byType(CreateFamilyScreen), findsOneWidget);
  });
}
