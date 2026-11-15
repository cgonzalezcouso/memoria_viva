import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/providers/auth_providers.dart';
import '../../shared/utils/time_picker_utils.dart';
import '../../shared/widgets/info_banner.dart';

class ManageCareScreen extends ConsumerWidget {
  const ManageCareScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCaregiver = ref.watch(isCaregiverProvider);

    if (!isCaregiver) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gestionar rutinas')),
        body: const Padding(
          padding: EdgeInsets.all(20),
          child: InfoBanner(
            message: 'Solo los cuidadores pueden personalizar rutinas y medicación.',
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Personalizar cuidados'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Rutina diaria', icon: Icon(Icons.checklist_rtl)),
              Tab(text: 'Medicación', icon: Icon(Icons.medication_outlined)),
              Tab(text: 'Familia', icon: Icon(Icons.family_restroom_outlined)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ManageRoutinesTab(),
            _ManageMedicationsTab(),
            _ManageFamilyMemoriesTab(),
          ],
        ),
      ),
    );
  }
}

class _ManageRoutinesTab extends ConsumerStatefulWidget {
  const _ManageRoutinesTab();

  @override
  ConsumerState<_ManageRoutinesTab> createState() => _ManageRoutinesTabState();
}

class _ManageRoutinesTabState extends ConsumerState<_ManageRoutinesTab> {
  final _titleController = TextEditingController();
  String _scheduledTime = '09:00';

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _addTask() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final patientId = ref.read(activePatientIdProvider);
    await ref.read(routineServiceProvider).addTask(
          patientId: patientId,
          title: title,
          scheduledTime: _scheduledTime,
        );

    ref.invalidate(todayRoutineProvider);
    _titleController.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Actividad añadida')),
      );
    }
  }

  Future<void> _deleteTask(String taskId) async {
    final patientId = ref.read(activePatientIdProvider);
    await ref.read(routineServiceProvider).deleteTask(
          patientId: patientId,
          taskId: taskId,
        );
    ref.invalidate(todayRoutineProvider);
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(todayRoutineProvider);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const InfoBanner(
          message:
              'Añade actividades para el día de hoy. '
              'La persona podrá marcarlas como completadas.',
        ),
        const SizedBox(height: 20),
        Text('Nueva actividad', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Nombre de la actividad',
            prefixIcon: Icon(Icons.edit_outlined),
          ),
        ),
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Hora'),
          subtitle: Text(_scheduledTime, style: theme.textTheme.titleMedium),
          trailing: IconButton(
            icon: const Icon(Icons.schedule),
            onPressed: () async {
              final picked = await pickTime(context, initialTime: _scheduledTime);
              if (picked != null) setState(() => _scheduledTime = picked);
            },
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _addTask,
            child: const Text('Añadir actividad'),
          ),
        ),
        const SizedBox(height: 28),
        Text('Actividades de hoy', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        tasksAsync.when(
          loading: () => const CircularProgressIndicator(),
          error: (_, _) => const Text('No se pudo cargar la rutina.'),
          data: (tasks) {
            if (tasks.isEmpty) {
              return const Text('No hay actividades configuradas.');
            }

            return Column(
              children: tasks
                  .map(
                    (task) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(task.title),
                        subtitle: Text('Hora: ${task.scheduledTime}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Eliminar',
                          onPressed: () => _deleteTask(task.id),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _ManageMedicationsTab extends ConsumerStatefulWidget {
  const _ManageMedicationsTab();

  @override
  ConsumerState<_ManageMedicationsTab> createState() =>
      _ManageMedicationsTabState();
}

class _ManageMedicationsTabState extends ConsumerState<_ManageMedicationsTab> {
  final _nameController = TextEditingController();
  final _instructionsController = TextEditingController();
  String _scheduledTime = '09:00';

  @override
  void dispose() {
    _nameController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _addMedication() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final patientId = ref.read(activePatientIdProvider);
    await ref.read(medicationServiceProvider).addMedication(
          patientId: patientId,
          name: name,
          scheduledTime: _scheduledTime,
          instructions: _instructionsController.text.trim().isEmpty
              ? null
              : _instructionsController.text.trim(),
        );

    ref.invalidate(medicationsProvider);
    ref.invalidate(allMedicationsProvider);
    _nameController.clear();
    _instructionsController.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medicamento añadido')),
      );
    }
  }

  Future<void> _deleteMedication(String medicationId) async {
    final patientId = ref.read(activePatientIdProvider);
    final all = await ref.read(medicationServiceProvider).fetchAllMedications(
          patientId: patientId,
        );
    final medication = all.firstWhere((med) => med.id == medicationId);

    await ref.read(medicationServiceProvider).deleteMedication(medication);
    ref.invalidate(medicationsProvider);
    ref.invalidate(allMedicationsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final medsAsync = ref.watch(allMedicationsProvider);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const InfoBanner(
          message:
              'Configura los medicamentos y horarios. '
              'La persona recibirá recordatorios si activa las notificaciones.',
        ),
        const SizedBox(height: 20),
        Text('Nuevo medicamento', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Nombre del medicamento',
            prefixIcon: Icon(Icons.medication_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _instructionsController,
          decoration: const InputDecoration(
            labelText: 'Instrucciones (opcional)',
            prefixIcon: Icon(Icons.notes_outlined),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Hora del recordatorio'),
          subtitle: Text(_scheduledTime, style: theme.textTheme.titleMedium),
          trailing: IconButton(
            icon: const Icon(Icons.schedule),
            onPressed: () async {
              final picked = await pickTime(context, initialTime: _scheduledTime);
              if (picked != null) setState(() => _scheduledTime = picked);
            },
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _addMedication,
            child: const Text('Añadir medicamento'),
          ),
        ),
        const SizedBox(height: 28),
        Text('Medicamentos configurados', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        medsAsync.when(
          loading: () => const CircularProgressIndicator(),
          error: (_, _) => const Text('No se pudo cargar la medicación.'),
          data: (medications) {
            final active = medications.where((med) => med.active).toList();
            if (active.isEmpty) {
              return const Text('No hay medicamentos configurados.');
            }

            return Column(
              children: active
                  .map(
                    (med) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(med.name),
                        subtitle: Text(
                          'Hora: ${med.scheduledTime}'
                          '${med.instructions != null ? '\n${med.instructions}' : ''}',
                        ),
                        isThreeLine: med.instructions != null,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Eliminar',
                          onPressed: () => _deleteMedication(med.id),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _ManageFamilyMemoriesTab extends ConsumerStatefulWidget {
  const _ManageFamilyMemoriesTab();

  @override
  ConsumerState<_ManageFamilyMemoriesTab> createState() =>
      _ManageFamilyMemoriesTabState();
}

class _ManageFamilyMemoriesTabState extends ConsumerState<_ManageFamilyMemoriesTab> {
  final _nameController = TextEditingController();
  final _relationshipController = TextEditingController();
  String _emoji = '👤';

  static const _emojiOptions = ['👤', '👩', '👨', '👵', '👴', '👦', '👧', '👩‍🦳', '👨‍🦳'];

  @override
  void dispose() {
    _nameController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  Future<void> _addMemory() async {
    final name = _nameController.text.trim();
    final relationship = _relationshipController.text.trim();
    if (name.isEmpty || relationship.isEmpty) return;

    final patientId = ref.read(activePatientIdProvider);
    await ref.read(familyMemoryServiceProvider).addMemory(
          patientId: patientId,
          displayName: name,
          relationship: relationship,
          emoji: _emoji,
        );

    ref.invalidate(familyMemoriesProvider);
    ref.invalidate(allFamilyMemoriesProvider);
    _nameController.clear();
    _relationshipController.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recuerdo familiar añadido')),
      );
    }
  }

  Future<void> _deleteMemory(String memoryId) async {
    final patientId = ref.read(activePatientIdProvider);
    final all = await ref.read(familyMemoryServiceProvider).fetchAllMemories(
          patientId: patientId,
        );
    final memory = all.firstWhere((m) => m.id == memoryId);

    await ref.read(familyMemoryServiceProvider).deleteMemory(memory);
    ref.invalidate(familyMemoriesProvider);
    ref.invalidate(allFamilyMemoriesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final memoriesAsync = ref.watch(allFamilyMemoriesProvider);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const InfoBanner(
          message:
              'Personaliza nombres y vínculos familiares para el ejercicio '
              'de recuerdos familiares en estimulación cognitiva.',
        ),
        const SizedBox(height: 20),
        Text('Nueva persona', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _relationshipController,
          decoration: const InputDecoration(
            labelText: 'Relación (ej. hija, nieto)',
            prefixIcon: Icon(Icons.people_outline),
          ),
        ),
        const SizedBox(height: 12),
        Text('Icono', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _emojiOptions.map((emoji) {
            final selected = emoji == _emoji;
            return ChoiceChip(
              label: Text(emoji, style: const TextStyle(fontSize: 24)),
              selected: selected,
              onSelected: (_) => setState(() => _emoji = emoji),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _addMemory,
            child: const Text('Añadir persona'),
          ),
        ),
        const SizedBox(height: 28),
        Text('Personas configuradas', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        memoriesAsync.when(
          loading: () => const CircularProgressIndicator(),
          error: (_, _) => const Text('No se pudieron cargar los recuerdos.'),
          data: (memories) {
            if (memories.isEmpty) {
              return const Text('No hay personas configuradas.');
            }

            return Column(
              children: memories
                  .map(
                    (memory) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Text(memory.emoji, style: const TextStyle(fontSize: 32)),
                        title: Text(memory.displayName),
                        subtitle: Text(memory.relationship),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Eliminar',
                          onPressed: () => _deleteMemory(memory.id),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}
