import 'package:flutter/material.dart';

abstract final class CognitiveActivityType {
  static const memoria = 'memoria';
  static const atencion = 'atencion';
  static const orientacion = 'orientacion';
  static const categorias = 'categorias';
  static const secuencias = 'secuencias';
  static const calculo = 'calculo';
  static const emociones = 'emociones';
  static const intruso = 'intruso';
  static const recuerdo = 'recuerdo';
  static const musica = 'musica';
  static const familia = 'familia';
  static const naturaleza = 'naturaleza';
  static const cocina = 'cocina';
  static const refranes = 'refranes';

  static const general = [memoria, atencion, orientacion, categorias, secuencias, calculo, emociones, intruso, recuerdo, refranes];
  static const thematic = [musica, familia, naturaleza, cocina];
  static const all = [...general, ...thematic];

  static String label(String type) {
    return switch (type) {
      memoria => 'Juego de memoria',
      atencion => 'Ejercicio de atención',
      orientacion => 'Orientación temporal',
      categorias => 'Asociación de categorías',
      secuencias => 'Orden de secuencias',
      calculo => 'Cálculo sencillo',
      emociones => 'Reconocimiento de emociones',
      intruso => 'Encuentra el intruso',
      recuerdo => 'Memoria inmediata',
      musica => 'Música e instrumentos',
      familia => 'Recuerdos familiares',
      naturaleza => 'Naturaleza y estaciones',
      cocina => 'Cocina y alimentación',
      refranes => 'Completar refranes',
      _ => 'Actividad cognitiva',
    };
  }

  static String subtitle(String type) {
    return switch (type) {
      memoria => 'Encuentra parejas de cartas iguales.',
      atencion => 'Cuenta los elementos del color indicado.',
      orientacion => 'Practica día, mes, año, estación y fecha.',
      categorias => 'Relaciona palabras con su categoría.',
      secuencias => 'Ordena pasos de actividades cotidianas.',
      calculo => 'Sumas, restas, multiplicaciones, divisiones y combinadas.',
      emociones => 'Identifica emociones básicas en caras.',
      intruso => 'Encuentra la palabra que no encaja.',
      recuerdo => 'Recuerda objetos mostrados unos segundos.',
      musica => 'Reconoce instrumentos musicales.',
      familia => 'Recuerda nombres y vínculos familiares.',
      naturaleza => 'Estaciones, clima y elementos naturales.',
      cocina => 'Asocia alimentos con momentos del día.',
      refranes => 'Completa dichos populares de toda la vida.',
      _ => 'Actividad de estimulación cognitiva.',
    };
  }

  static IconData icon(String type) {
    return switch (type) {
      memoria => Icons.grid_view_rounded,
      atencion => Icons.visibility_outlined,
      orientacion => Icons.today_outlined,
      categorias => Icons.category_outlined,
      secuencias => Icons.format_list_numbered,
      calculo => Icons.calculate_outlined,
      emociones => Icons.sentiment_satisfied_alt_outlined,
      intruso => Icons.highlight_off_outlined,
      recuerdo => Icons.psychology_alt_outlined,
      musica => Icons.music_note_outlined,
      familia => Icons.family_restroom_outlined,
      naturaleza => Icons.park_outlined,
      cocina => Icons.restaurant_outlined,
      refranes => Icons.chat_bubble_outline_rounded,
      _ => Icons.psychology_outlined,
    };
  }

  static String? routeFor(String type) {
    return switch (type) {
      memoria => '/estimulacion/memoria',
      atencion => '/estimulacion/atencion',
      orientacion => '/estimulacion/orientacion',
      categorias => '/estimulacion/categorias',
      secuencias => '/estimulacion/secuencias',
      calculo => '/estimulacion/calculo',
      emociones => '/estimulacion/emociones',
      intruso => '/estimulacion/intruso',
      recuerdo => '/estimulacion/recuerdo',
      musica => '/estimulacion/musica',
      familia => '/estimulacion/familia',
      naturaleza => '/estimulacion/naturaleza',
      cocina => '/estimulacion/cocina',
      refranes => '/estimulacion/refranes',
      _ => null,
    };
  }
}
