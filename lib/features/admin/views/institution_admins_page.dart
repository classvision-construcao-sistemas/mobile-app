import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/admin_cards.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/admin_repository.dart';
import '../domain/admin_models.dart';
import 'widgets/admin_data_status.dart';
import 'widgets/admin_page_header.dart';

class InstitutionAdminsPage extends StatefulWidget {
  const InstitutionAdminsPage({super.key, required this.onManageUsers});

  final VoidCallback onManageUsers;

  @override
  State<InstitutionAdminsPage> createState() => _InstitutionAdminsPageState();
}

class _InstitutionAdminsPageState extends State<InstitutionAdminsPage> {
  String _query = '';
  AccountStatus? _status;

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final admins = [
      for (final admin in context.watch<AdminRepository>().institutionAdmins)
        if ((_status == null || admin.status == _status) &&
            (query.isEmpty ||
                admin.name.toLowerCase().contains(query) ||
                admin.email.toLowerCase().contains(query) ||
                admin.institutionName.toLowerCase().contains(query)))
          admin,
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(40, 32, 40, 40),
      children: [
        AdminPageHeader(
          title: 'Administradores institucionais',
          subtitle: 'Responsáveis pelas instituições da plataforma.',
          action: OutlinedButton.icon(
            onPressed: widget.onManageUsers,
            icon: const Icon(Icons.manage_accounts_outlined, size: 18),
            label: const Text('Gerenciar usuários'),
          ),
        ),
        const SizedBox(height: 30),
        const AdminDataStatus(),
        AdminSurface(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: AppColors.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    hintText: 'Buscar administrador ou instituição',
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              DropdownButton<AccountStatus?>(
                value: _status,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Todos os status')),
                  DropdownMenuItem(
                    value: AccountStatus.active,
                    child: Text('Ativos'),
                  ),
                  DropdownMenuItem(
                    value: AccountStatus.inactive,
                    child: Text('Inativos'),
                  ),
                ],
                onChanged: (value) => setState(() => _status = value),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        AdminSurface(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              const _AdminsHeader(),
              if (admins.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(28),
                  child: Text(
                    adminEmptyText(context, 'Nenhum administrador encontrado.'),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              for (final admin in admins) _AdminRow(admin: admin),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdminsHeader extends StatelessWidget {
  const _AdminsHeader();

  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 54,
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(flex: 3, child: _Header('ADMINISTRADOR')),
          Expanded(flex: 3, child: _Header('INSTITUIÇÃO')),
          Expanded(flex: 2, child: _Header('CADASTRO')),
          Expanded(child: _Header('STATUS')),
        ],
      ),
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: AppColors.textSecondary,
      fontSize: 11,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _AdminRow extends StatelessWidget {
  const _AdminRow({required this.admin});

  final InstitutionAdminAccount admin;

  @override
  Widget build(BuildContext context) => Container(
    height: 90,
    padding: const EdgeInsets.symmetric(horizontal: 24),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: AppColors.divider)),
    ),
    child: Row(
      children: [
        Expanded(
          flex: 3,
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primarySoft,
                foregroundColor: AppColors.primary,
                child: Text(
                  admin.name.split(' ').map((part) => part[0]).take(2).join(),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      admin.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      admin.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(flex: 3, child: Text(admin.institutionName)),
        Expanded(flex: 2, child: Text(admin.lastAccessLabel)),
        Expanded(
          child: admin.status == AccountStatus.active
              ? const StatusBadge(
                  label: 'Ativo',
                  foreground: Color(0xFF15803D),
                  background: Color(0xFFDCFCE7),
                )
              : const StatusBadge(
                  label: 'Inativo',
                  foreground: Color(0xFFB42318),
                  background: Color(0xFFFEE4E2),
                ),
        ),
      ],
    ),
  );
}
