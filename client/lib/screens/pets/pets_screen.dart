import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                // Sheet handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppTheme.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  isEdit ? 'Editar Pet' : 'Novo Pet',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: nameCtrl,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Nome do pet',
                    prefixIcon: Icon(Icons.pets, size: 18),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Informe o nome' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: breedCtrl,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Raça',
                    prefixIcon: Icon(Icons.info_outline, size: 18),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Informe a raça' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: size,
                  dropdownColor: AppTheme.surface2,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(labelText: 'Porte'),
                  items: ['PEQUENO', 'MEDIO', 'GRANDE']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setS(() => size = v ?? size),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notesCtrl,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Observações (opcional)',
                    hintText: 'Ex: alérgico a...',
                    prefixIcon: Icon(Icons.notes, size: 18),
                  ),
                ),
                const SizedBox(height: 22),
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

  String _sizeLabel(String size) {
    switch (size) {
      case 'PEQUENO': return 'Pequeno';
      case 'MEDIO':   return 'Médio';
      case 'GRANDE':  return 'Grande';
      default:        return size;
    }
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
            tooltip: 'Adicionar pet',
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
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withAlpha(18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.pets,
                        size: 36, color: AppTheme.accent),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum pet cadastrado.',
                    style: GoogleFonts.bricolageGrotesque(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Adicione seu primeiro pet abaixo.',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _showPetSheet(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Adicionar pet'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(180, 48),
                    ),
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
                    color: AppTheme.statusCancelado.withAlpha(35),
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
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withAlpha(18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.pets,
                          size: 24,
                          color: AppTheme.accent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              style: GoogleFonts.bricolageGrotesque(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Text(
                                  p.breed,
                                  style: const TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surface3,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _sizeLabel(p.size),
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      color: AppTheme.textMuted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (p.notes != null && p.notes!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                p.notes!,
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
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
