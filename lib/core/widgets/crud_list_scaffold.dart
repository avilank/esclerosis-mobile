import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'crud_list_header.dart';
import 'empty_view.dart';
import 'error_view.dart';
import 'initials_avatar.dart';
import 'loading_view.dart';
import 'search_field.dart';

/// Scaffold generico para las pantallas de listado/CRUD de administracion
/// (Sedes, Areas, Tratamientos, Categorias, Indicadores): header curvo +
/// buscador flotante + contador + lista de tarjetas. Ver manual de usuario
/// ESCLEROSIS - BI, figuras 5, 18, 21, 24, 27, 28, 31.
class CrudListScaffold<T> extends StatefulWidget {
  const CrudListScaffold({
    super.key,
    required this.title,
    required this.searchHint,
    required this.async,
    required this.filter,
    required this.itemBuilder,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.countLabel,
    this.onAdd,
    this.onRefresh,
    this.onBack,
  });

  final String title;
  final String searchHint;
  final AsyncValue<List<T>> async;
  final bool Function(T item, String query) filter;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final String emptyMessage;
  final IconData emptyIcon;
  final String Function(int count) countLabel;
  final VoidCallback? onAdd;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onBack;

  @override
  State<CrudListScaffold<T>> createState() => _CrudListScaffoldState<T>();
}

class _CrudListScaffoldState<T> extends State<CrudListScaffold<T>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final onBack = widget.onBack ??
        (Navigator.of(context).canPop() ? () => Navigator.of(context).pop() : null);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: widget.onRefresh ?? () async {},
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: CrudListHeader(title: widget.title, onAdd: widget.onAdd, onBack: onBack),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s5,
                  AppSpacing.s4,
                  AppSpacing.s5,
                  AppSpacing.s3,
                ),
                child: SearchField(
                  hintText: widget.searchHint,
                  onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
                ),
              ),
            ),
            widget.async.when(
              loading: () => const SliverFillRemaining(child: LoadingView()),
              error: (error, _) => SliverFillRemaining(
                child: ErrorView(message: error.toString()),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return SliverFillRemaining(
                    child: EmptyView(message: widget.emptyMessage, icon: widget.emptyIcon),
                  );
                }
                final filtered = _query.isEmpty
                    ? items
                    : items.where((item) => widget.filter(item, _query)).toList();
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5),
                  sliver: SliverList.separated(
                    itemCount: filtered.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s2),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.s2),
                          child: Text(
                            widget.countLabel(filtered.length),
                            textAlign: TextAlign.right,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.muted),
                          ),
                        );
                      }
                      return Container(
                        padding: const EdgeInsets.all(AppSpacing.s3),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(color: Color(0x0A0F172A), blurRadius: 8, offset: Offset(0, 2)),
                          ],
                        ),
                        child: widget.itemBuilder(context, filtered[index - 1]),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Fila estandar de una tarjeta de listado: avatar de iniciales + titulo +
/// subtitulo (opcional, con icono) + acciones (editar/eliminar/chevron).
class CrudListRow extends StatelessWidget {
  const CrudListRow({
    super.key,
    required this.avatarText,
    required this.title,
    this.subtitle,
    this.subtitleIcon,
    this.actions = const [],
  });

  final String avatarText;
  final String title;
  final String? subtitle;
  final IconData? subtitleIcon;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InitialsAvatar(text: avatarText),
        const SizedBox(width: AppSpacing.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              if (subtitle != null && subtitle!.isNotEmpty)
                Row(
                  children: [
                    if (subtitleIcon != null)
                      Icon(subtitleIcon, size: 14, color: AppColors.muted),
                    if (subtitleIcon != null) const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        ...actions,
      ],
    );
  }
}

/// Botones editar / eliminar apilados como en las tarjetas de esclerosis-movil.
class CrudVerticalActions extends StatelessWidget {
  const CrudVerticalActions({
    super.key,
    required this.onEdit,
    required this.onDelete,
  });

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.muted),
          onPressed: onEdit,
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.muted),
          onPressed: onDelete,
        ),
      ],
    );
  }
}
