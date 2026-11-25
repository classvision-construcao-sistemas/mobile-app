import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

class AppPageTitle extends StatelessWidget {
  const AppPageTitle(this.title, {super.key, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -.7,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 5),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
      ?trailing,
    ],
  );
}

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding, this.onTap});

  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: AppColors.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    ),
  );
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.outlined = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          );

    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(52)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    return outlined
        ? OutlinedButton(
            onPressed: loading ? null : onPressed,
            style: style,
            child: child,
          )
        : FilledButton(
            onPressed: loading ? null : onPressed,
            style: style,
            child: child,
          );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.suffixIcon,
    this.inputFormatters,
    this.enabled = true,
    this.helperText,
    this.onFieldSubmitted,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final IconData? icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;
  final String? helperText;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    obscureText: obscureText,
    validator: validator,
    onChanged: onChanged,
    inputFormatters: inputFormatters,
    enabled: enabled,
    onFieldSubmitted: onFieldSubmitted,
    textInputAction: onFieldSubmitted == null
        ? TextInputAction.next
        : TextInputAction.done,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helperText,
      helperMaxLines: 3,
      prefixIcon: icon == null ? null : Icon(icon, size: 20),
      suffixIcon: suffixIcon,
    ),
  );
}

/// Mensagem de erro em destaque (ex.: resposta da API).
class AppErrorBanner extends StatelessWidget {
  const AppErrorBanner(this.message, {super.key, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
    decoration: BoxDecoration(
      color: AppColors.error.withValues(alpha: .07),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.error.withValues(alpha: .25)),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline_rounded, color: AppColors.error),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: AppColors.error,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('Tentar de novo')),
      ],
    ),
  );
}

/// Bloco "rótulo + valor" usado nas telas de perfil e detalhes.
class AppInfoTile extends StatelessWidget {
  const AppInfoTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    child: Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 14),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (onTap != null)
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
          ),
      ],
    ),
  );
}

/// Etiqueta pequena de status (ativo, inativo, perfil...).
class AppStatusChip extends StatelessWidget {
  const AppStatusChip({
    super.key,
    required this.label,
    this.color = AppColors.primary,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
    ),
  );
}

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: destructive
              ? FilledButton.styleFrom(backgroundColor: AppColors.error)
              : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

void showAppMessage(
  BuildContext context,
  String message, {
  bool error = false,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : null,
      ),
    );
}

/// Campo de busca padrão das listas (lupa + texto de exemplo).
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    required this.hint,
    this.controller,
    this.onChanged,
  });

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onChanged: onChanged,
    textInputAction: TextInputAction.search,
    decoration: InputDecoration(
      prefixIcon: const Icon(Icons.search_rounded, size: 20),
      hintText: hint,
    ),
  );
}

/// Filtro de lista no mesmo estilo dos campos (ex.: "Todos os status").
class AppFilterDropdown<T> extends StatelessWidget {
  const AppFilterDropdown({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.width = 250,
  });

  final T value;

  /// Pares valor → rótulo, na ordem em que aparecem.
  final List<(T, String)> options;
  final ValueChanged<T?> onChanged;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: DropdownButtonFormField<T>(
      key: ValueKey(value),
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.filter_list_rounded, size: 20),
      ),
      items: [
        for (final (option, label) in options)
          DropdownMenuItem<T>(
            value: option,
            child: Text(label, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged,
    ),
  );
}
