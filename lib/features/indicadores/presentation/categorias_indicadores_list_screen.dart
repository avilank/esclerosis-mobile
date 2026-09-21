import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/crud_list_scaffold.dart';
import '../../auth/application/auth_providers.dart';
import '../application/indicadores_providers.dart';
import '../domain/categoria_indicador.dart';
import 'categoria_form_sheet.dart';

/// CRUD de categorías de indicadores clínicos. Ver manual de usuario
/// ESCLEROSIS - BI, figuras 1, 3, 28, 29, 30.
class CategoriasIndicadoresListScreen extends ConsumerWidget {
  const CategoriasIndicadoresListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriasAsync = ref.watch(categoriasIndicadoresListProvider);
    final api = ref.read(categoriasIndicadoresApiProvider);
    // El backend restringe la escritura de este catalogo al rol admin.
    final esAdmin = ref.watch(esAdminProvider);

    Future<void> crear() async {
      final data = await showCategoriaFormSheet(context);
      if (data == null) return;
      if (!context.mounted) return;
      await AppToast.run(
        context,
        action: () async {
          await api.create(data);
          ref.invalidate(categoriasIndicadoresListProvider);
        },
        success: 'Categoría creada',
      );
    }

    return CrudListScaffold<CategoriaIndicador>(
      title: 'Categorías de indicadores',
      searchHint: 'Buscar categoría por nombre',
      async: categoriasAsync,
      onAdd: esAdmin ? crear : null,
      onBack: () => Navigator.of(context).pop(),
      onRefresh: () => ref.refresh(categoriasIndicadoresListProvider.future),
      filter: (c, query) => c.descripcion.toLowerCase().contains(query),
      emptyMessage: 'No hay categorías registradas.',
      emptyIcon: Icons.category_outlined,
      countLabel: (count) =>
          '$count categoría${count == 1 ? '' : 's'} encontrada${count == 1 ? '' : 's'}',
      itemBuilder: (context, categoria) => CrudListRow(
        avatarText: categoria.descripcion,
        title: categoria.descripcion,
        subtitle: 'Categoría clínica',
        subtitleIcon: Icons.folder_outlined,
        actions: !esAdmin || categoria.bloqueado
            ? const []
            : [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () async {
              final data = await showCategoriaFormSheet(context, categoria: categoria);
              if (data == null) return;
              if (!context.mounted) return;
              await AppToast.run(
                context,
                action: () async {
                  await api.update(categoria.idTipoIndicador, data);
                  ref.invalidate(categoriasIndicadoresListProvider);
                },
                success: 'Categoría actualizada',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.danger),
            onPressed: () async {
              final confirmed = await showConfirmDialog(
                context,
                title: 'Eliminar categoría',
                message: '¿Eliminar "${categoria.descripcion}"?',
              );
              if (!confirmed) return;
              if (!context.mounted) return;
              await AppToast.run(
                context,
                action: () async {
                  await api.remove(categoria.idTipoIndicador);
                  ref.invalidate(categoriasIndicadoresListProvider);
                },
                success: 'Categoría eliminada',
              );
            },
          ),
        ],
      ),
    );
  }
}
