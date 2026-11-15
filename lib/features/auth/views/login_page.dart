import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../data/repositories/auth_repository.dart';
import '../viewmodels/login_view_model.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit(LoginViewModel viewModel) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final success = await viewModel.signIn(
      email: _email.text,
      password: _password.text,
    );
    if (!success || !mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
  }

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (context) => LoginViewModel(context.read<AuthRepository>()),
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
                        onChanged: (_) => viewModel.clearError(),
                        validator: (value) =>
                            value != null && value.trim().contains('@')
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
                        onChanged: (_) => viewModel.clearError(),
                        onFieldSubmitted: (_) => _submit(viewModel),
                        validator: (value) => (value?.isEmpty ?? true)
                            ? 'Informe a sua senha'
                            : null,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => showAppMessage(
                            context,
                            'Peça ao administrador da sua instituição para '
                            'redefinir a sua senha.',
                          ),
                          child: const Text('Esqueceu a senha?'),
                        ),
                      ),
                      if (viewModel.error != null) ...[
                        AppErrorBanner(viewModel.error!),
                        const SizedBox(height: 14),
                      ] else
                        const SizedBox(height: 8),
                      PrimaryButton(
                        label: 'Entrar',
                        loading: viewModel.loading,
                        onPressed: () => _submit(viewModel),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Ainda não tem acesso? As contas são criadas pelo '
                        'administrador da sua instituição.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
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
