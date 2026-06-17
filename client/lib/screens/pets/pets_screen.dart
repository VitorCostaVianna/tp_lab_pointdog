import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/pet.dart';
import '../../providers/pets_notifier.dart';

class PetsScreen extends StatefulWidget {
  const PetsScreen({super.key});
  @override
  State<PetsScreen> createState() => _PetsScreenState();
}

class _PetsScreenState extends State<PetsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PetsNotifier>().loadAll();
    });
  }

  void _showPetSheet({Pet? pet}) {
    final nameCtrl = TextEditingController(text: pet?.name ?? '');
    final breedCtrl = TextEditingController(text: pet?.breed ?? '');
    String size = pet?.size ?? 'PEQUENO';
    final notesCtrl = TextEditingController(text: pet?.notes ?? '');
    final form = GlobalKey<FormState>();
    final isEdit = pet != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: StatefulBuilder(
          builder: (ctx, setS) => Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'Editar Pet' : 'Novo Pet',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'NOME DO PET'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Informe o nome' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: breedCtrl,
                  decoration: const InputDecoration(labelText: 'RAÇA'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Informe a raça' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: size,
                  dropdownColor: AppTheme.surface2,
                  decoration: const InputDecoration(labelText: 'PORTE'),
                  items: ['PEQUENO', 'MEDIO', 'GRANDE']
                      .map((s) =>
                          DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setS(() => size = v ?? size),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'OBSERVAÇÕES (OPCIONAL)',
                    hintText: 'Ex: alérgico a...',
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (!form.currentState!.validate()) return;
                    final notifier = context.read<PetsNotifier>();
                    final bool ok;
                    if (isEdit) {
                      ok = await notifier.updatePet(
                        id: pet.id,
                        name: nameCtrl.text.trim(),
                        breed: breedCtrl.text.trim(),
                        size: size,
                        notes: notesCtrl.text.trim(),
                      );
                    } else {
                      ok = await notifier.addPet(
                        name: nameCtrl.text.trim(),
                        breed: breedCtrl.text.trim(),
                        size: size,
                        notes: notesCtrl.text.trim(),
                      );
                    }
                    if (ok && ctx.mounted) Navigator.pop(ctx);
                  },
                  child: Text(isEdit ? 'Salvar alterações' : 'Adicionar pet'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Pets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.accent),
            onPressed: () => _showPetSheet(),
          ),
        ],
      ),
      body: Consumer<PetsNotifier>(
        builder: (_, notifier, __) {
          if (notifier.loading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.accent),
            );
          }
          if (notifier.pets.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🐶', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  const Text(
                    'Nenhum pet cadastrado.',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _showPetSheet(),
                    child: const Text('+ Adicionar pet'),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifier.pets.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final p = notifier.pets[i];
              return Dismissible(
                key: Key(p.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.statusCancelado.withAlpha(40),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.delete_outline,
                      color: AppTheme.statusCancelado),
                ),
                confirmDismiss: (_) async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppTheme.surface2,
                      title: const Text('Remover pet'),
                      content: Text('Deseja remover ${p.name}?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancelar',
                              style: TextStyle(color: AppTheme.textMuted)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Remover',
                              style:
                                  TextStyle(color: AppTheme.statusCancelado)),
                        ),
                      ],
                    ),
                  );
                  return confirm ?? false;
                },
                onDismissed: (_) => notifier.removePet(p.id),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surface2,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withAlpha(40),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Text('🐕', style: TextStyle(fontSize: 22)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '${p.breed} · ${p.size}',
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 11,
                              ),
                            ),
                            if (p.notes != null && p.notes!.isNotEmpty)
                              Text(
                                p.notes!,
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            size: 18, color: AppTheme.textMuted),
                        onPressed: () => _showPetSheet(pet: p),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
