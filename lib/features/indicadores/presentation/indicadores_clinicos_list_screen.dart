import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/crud_list_scaffold.dart';
import '../../auth/application/auth_providers.dart';
import '../application/indicadores_providers.dart';
import '../domain/indicador_clinico.dart';
import 'indicador_form_sheet.dart';

/// CRUD de indicadores clínicos. Ver manual de usuario ESCLEROSIS - BI,
/// figuras 2, 31, 32, 33.
class IndicadoresClinicosListScreen extends ConsumerWidget {
  const IndicadoresClinicosListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final indicadoresAsync = ref.watch(indicadoresClinicosListProvider);
    final categoriasAsync = ref.watch(categoriasIndicadoresListProvider);
    final api = ref.read(indicadoresClinicosApiProvider);
    // El backend restringe la escritura de este catalogo al rol admin.
    final esAdmin = ref.watch(esAdminProvider);

    Future<void> crear() async {
      final categorias = categoriasAsync.value ?? const [];
      if (categorias.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Primero crea una categoría')));
        return;
      }
      final data = await showIndicadorFormSheet(context, categorias: categorias);
      if (data == null) return;
      try {
        await api.create(data);
        ref.invalidate(indicadoresClinicosListProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }

    return CrudListScaffold<IndicadorClinico>(
      title: 'Indicadores clínicos',
      searchHint: 'Buscar por nombre, descripción o categoría',
      async: indicadoresAsync,
      onAdd: esAdmin ? crear : null,
      onBack: () => Navigator.of(context).pop(),
      onRefresh: () => ref.refresh(indicadoresClinicosListProvider.future),
      filter: (i, query) =>
          i.nombre.toLowerCase().contains(query) ||
          i.descripcion.toLowerCase().contains(query) ||
          (i.categoriaDescripcion ?? '').toLowerCase().contains(query),
      emptyMessage: 'No hay indicadores registrados.',
      emptyIcon: Icons.show_chart,
      countLabel: (count) =>
          '$count indicador${count == 1 ? '' : 'es'} encontrado${count == 1 ? '' : 's'}',
      itemBuilder: (context, indicador) => CrudListRow(
        avatarText: indicador.nombre,
        title: indicador.nombre,
        subtitle: indicador.categoriaDescripcion ?? indicador.descripcion,
        subtitleIcon: Icons.folder_outlined,
        actions: !esAdmin || indicador.bloqueado
            ? const []
            : [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () async {
              final data = await showIndicadorFormSheet(
                context,
                categorias: categoriasAsync.value ?? const [],
                indicador: indicador,
              );
              if (data == null) return;
              try {
                await api.update(indicador.idIndicador, data);
                ref.invalidate(indicadoresClinicosListProvider);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.danger),
            onPressed: () async {
              final confirmed = await showConfirmDialog(
                context,
                title: 'Eliminar indicador',
                message: '¿Eliminar "${indicador.nombre}"?',
              );
              if (!confirmed) return;
              try {
                await api.remove(indicador.idIndicador);
                ref.invalidate(indicadoresClinicosListProvider);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
