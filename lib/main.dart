
import 'package:flutter/material.dart';

// Função principal que inicia o aplicativo.
void main() {
  runApp(const MyApp());
}

// Classe responsável por configurar o aplicativo.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Remove a faixa de debug do canto da tela.
      debugShowCheckedModeBanner: false,

      // Define o nome do aplicativo.
      title: 'Fotografar sala',

      // Configura o tema visual do aplicativo.
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
      ),

      // Define a tela inicial do aplicativo.
      home: const CameraPage(),
    );
  }
}

// Classe que constrói a tela de fotografar a sala.
class CameraPage extends StatelessWidget {
  const CameraPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Define a cor de fundo da tela.
      backgroundColor: const Color(0xFFE5E5E5),

      // Evita que o conteúdo fique atrás das áreas do sistema.
      body: SafeArea(
        child: Column(
          children: [
            // Identificação da etapa atual da interface.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
              alignment: Alignment.centerLeft,
              child: const Text(
                '05 • Câmera',
                style: TextStyle(
                  fontSize: 17,
                  color: Color(0xFF888888),
                ),
              ),
            ),

            // Ocupa o espaço restante disponível na tela.
            Expanded(
              child: Center(
                // Container que representa o corpo do celular.
                child: Container(
                  width: 380,
                  margin: const EdgeInsets.symmetric(horizontal: 12),

                  // Define o espaçamento interno do painel.
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),

                  // Define a aparência do painel principal.
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1015),
                    borderRadius: BorderRadius.circular(30),
                  ),

                  child: Column(
                    children: [
                      // Título principal da tela.
                      const Text(
                        'Fotografar sala',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      // Espaçamento entre o título e a instrução.
                      const SizedBox(height: 14),

                      // Orientação para o usuário antes da fotografia.
                      const Text(
                        'Enquadre todos os alunos e mantenha o celular firme.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF9BA3B2),
                          fontSize: 11,
                        ),
                      ),

                      // Espaçamento antes da área da câmera.
                      const SizedBox(height: 16),

                      // Área visual que representa a câmera.
                      Expanded(
                        child: Container(
                          width: double.infinity,

                          // Define o espaço interno da área da câmera.
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 30,
                          ),

                          // Define o fundo e os cantos arredondados.
                          decoration: BoxDecoration(
                            color: const Color(0xFF20252F),
                            borderRadius: BorderRadius.circular(24),
                          ),

                          child: Column(
                            // Centraliza verticalmente os indicadores.
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Primeira fileira com quatro indicadores.
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: const [
                                  FaceIndicator(),
                                  FaceIndicator(),
                                  FaceIndicator(),
                                  FaceIndicator(),
                                ],
                              ),

                              // Espaçamento entre as duas fileiras.
                              const SizedBox(height: 48),

                              // Segunda fileira com três indicadores.
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: const [
                                  FaceIndicator(),
                                  FaceIndicator(
                                    // Destaca o rosto com borda laranja.
                                    highlighted: true,
                                  ),
                                  FaceIndicator(),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Espaçamento antes da mensagem de status.
                      const SizedBox(height: 15),

                      // Painel que apresenta o resumo do enquadramento.
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 15,
                        ),

                        // Define o fundo e os cantos do painel de status.
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1E28),
                          borderRadius: BorderRadius.circular(15),
                        ),

                        // Mensagem estática usada como exemplo visual.
                        child: const Text(
                          '7 rostos detectados • 1 precisa melhorar o enquadramento',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),

                      // Espaçamento antes do botão de captura.
                      const SizedBox(height: 16),

                      // Botão visual que representa o disparador da câmera.
                      // Ainda não possui uma ação de captura.
                      Container(
                        width: 74,
                        height: 74,

                        // Formata o botão como um círculo branco.
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,

                          // Adiciona a borda externa acinzentada.
                          border: Border.all(
                            color: const Color(0xFF788294),
                            width: 5,
                          ),
                        ),

                        // Cria o círculo menor no centro do botão.
                        child: Center(
                          child: Container(
                            width: 25,
                            height: 25,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFF3F3F3),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget reutilizável que representa um rosto na tela.
class FaceIndicator extends StatelessWidget {
  // Informa se o indicador deve receber destaque visual.
  final bool highlighted;

  // Por padrão, o indicador não fica destacado.
  const FaceIndicator({
    super.key,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Define a largura e a altura do indicador.
      width: 49,
      height: 57,

      // Define o fundo, os cantos e a cor da borda.
      decoration: BoxDecoration(
        color: const Color(0xFF171B23),
        borderRadius: BorderRadius.circular(9),

        // A borda muda de cor conforme o valor de highlighted.
        border: Border.all(
          color: highlighted
              ? const Color(0xFFFF9800) // Laranja: indicador destacado.
              : const Color(0xFF008D4D), // Verde: indicador normal.
          width: 2,
        ),
      ),

      // Centraliza o círculo que representa o rosto.
      child: Center(
        child: Container(
          width: 34,
          height: 34,

          // Cria o círculo cinza-azulado.
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFBFC7D4),
          ),
        ),
      ),
    );
  }
}
