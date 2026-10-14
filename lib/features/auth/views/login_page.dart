import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_ui.dart';
import '../viewmodels/login_view_model.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController(text: 'coordenacao@escola.edu.br');
  final _password = TextEditingController(text: '12345678');

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => LoginViewModel(),
    child: Consumer<LoginViewModel>(
      builder: (context, viewModel, _) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'CV',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 29,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'ClassVision',
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.7,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Acesso da coordenação',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 34),
                      AppTextField(
                        label: 'E-mail institucional',
                        controller: _email,
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) =>
                            value != null && value.contains('@')
                            ? null
                            : 'Informe um e-mail válido',
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        label: 'Senha',
                        controller: _password,
                        icon: Icons.lock_outline_rounded,
                        obscureText: viewModel.obscurePassword,
                        suffixIcon: IconButton(
                          onPressed: viewModel.togglePassword,
                          icon: Icon(
                            viewModel.obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                        validator: (value) => (value?.length ?? 0) >= 6
                            ? null
                            : 'A senha deve ter ao menos 6 caracteres',
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => showAppMessage(
                            context,
                            'Um link de recuperação foi enviado para o e-mail mockado.',
                          ),
                          child: const Text('Esqueceu a senha?'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      PrimaryButton(
                        label: 'Entrar',
                        loading: viewModel.loading,
                        onPressed: () async {
                          if (!(_formKey.currentState?.validate() ?? false)) {
                            return;
                          }
                          await viewModel.signIn();
                          if (!context.mounted) {
                            return;
                          }
                          Navigator.pushReplacementNamed(
                            context,
                            AppRoutes.home,
                          );
                        },
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Ainda não tem uma conta?',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 9),
                      PrimaryButton(
                        label: 'Criar conta',
                        outlined: true,
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.userRegistration,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
