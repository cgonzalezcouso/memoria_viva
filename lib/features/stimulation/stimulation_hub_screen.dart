import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import '../../core/models/cognitive_activity_type.dart';
import '../../core/router/app_router.dart';
import '../../shared/widgets/accessible_card.dart';
import '../../shared/widgets/section_header.dart';
import 'widgets/difficulty_selector_card.dart';

class StimulationHubScreen extends StatelessWidget {
  const StimulationHubScreen({super.key});

  static const _generalExercises = CognitiveActivityType.general;
  static const _thematicExercises = CognitiveActivityType.thematic;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estimulación cognitiva'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SectionHeader(
            title: 'Entrena tu mente',
            description:
                'Trece actividades para memoria, atención, lenguaje, '
                'secuencias, cálculo, emociones y temas cotidianos.',
          ),
          const SizedBox(height: 20),
          const DifficultySelectorCard(),
          const SizedBox(height: 24),
          Text(
            'Ejercicios generales',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          ..._generalExercises.map(
            (type) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: AccessibleCard(
                icon: CognitiveActivityType.icon(type),
                title: CognitiveActivityType.label(type),
                subtitle: CognitiveActivityType.subtitle(type),
                onTap: () => context.push(CognitiveActivityType.routeFor(type)!),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ejercicios temáticos',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          ..._thematicExercises.map(
            (type) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: AccessibleCard(
                icon: CognitiveActivityType.icon(type),
                title: CognitiveActivityType.label(type),
                subtitle: CognitiveActivityType.subtitle(type),
                color: const Color(0xFF2E7D5A),
                onTap: () => context.push(CognitiveActivityType.routeFor(type)!),
              ),
            ),
          ),
          AccessibleCard(
            icon: Icons.insights_outlined,
            title: 'Informe semanal',
            subtitle: 'Consulta, exporta en PDF o envía por correo.',
            color: const Color(0xFF4A5568),
            onTap: () => context.push(AppRoutes.weeklyReport),
          ),
        ],
      ),
    );
  }
}
