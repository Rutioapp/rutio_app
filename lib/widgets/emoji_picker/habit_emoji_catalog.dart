class EmojiOption {
  const EmojiOption({
    required this.emoji,
    required this.label,
    required this.keywords,
    required this.category,
  });

  final String emoji;
  final String label;
  final List<String> keywords;
  final String category;
}

abstract final class HabitEmojiCategories {
  static const String recent = 'recent';
  static const String frequent = 'frequent';
  static const String bodyHealth = 'body_health';
  static const String mindFocus = 'mind_focus';
  static const String sleepRest = 'sleep_rest';
  static const String foodDrink = 'food_drink';
  static const String workStudy = 'work_study';
  static const String homeOrder = 'home_order';
  static const String social = 'social';
  static const String sport = 'sport';
  static const String creativity = 'creativity';
  static const String nature = 'nature';
  static const String others = 'others';
}

const List<String> kHabitEmojiCategoryOrder = <String>[
  HabitEmojiCategories.recent,
  HabitEmojiCategories.frequent,
  HabitEmojiCategories.bodyHealth,
  HabitEmojiCategories.mindFocus,
  HabitEmojiCategories.sleepRest,
  HabitEmojiCategories.foodDrink,
  HabitEmojiCategories.workStudy,
  HabitEmojiCategories.homeOrder,
  HabitEmojiCategories.social,
  HabitEmojiCategories.sport,
  HabitEmojiCategories.creativity,
  HabitEmojiCategories.nature,
  HabitEmojiCategories.others,
];

const List<EmojiOption> kHabitEmojiOptions = <EmojiOption>[
  EmojiOption(
    emoji: '📚',
    label: 'Lectura',
    keywords: <String>[
      'leer',
      'lectura',
      'libro',
      'libros',
      'read',
      'reading',
      'book',
      'study',
    ],
    category: HabitEmojiCategories.frequent,
  ),
  EmojiOption(
    emoji: '💧',
    label: 'Agua',
    keywords: <String>['agua', 'hidratar', 'hidratacion', 'water', 'drink'],
    category: HabitEmojiCategories.frequent,
  ),
  EmojiOption(
    emoji: '🏃',
    label: 'Correr',
    keywords: <String>['correr', 'running', 'run', 'cardio', 'trotar'],
    category: HabitEmojiCategories.sport,
  ),
  EmojiOption(
    emoji: '🧘',
    label: 'Meditacion',
    keywords: <String>['meditar', 'meditacion', 'calma', 'mindful', 'meditate'],
    category: HabitEmojiCategories.mindFocus,
  ),
  EmojiOption(
    emoji: '😴',
    label: 'Dormir',
    keywords: <String>['dormir', 'sueno', 'sleep', 'sleeping', 'descanso', 'rest'],
    category: HabitEmojiCategories.sleepRest,
  ),
  EmojiOption(
    emoji: '📖',
    label: 'Estudiar',
    keywords: <String>['estudiar', 'study', 'learning', 'aprender', 'repasar'],
    category: HabitEmojiCategories.workStudy,
  ),
  EmojiOption(
    emoji: '💪',
    label: 'Entrenar',
    keywords: <String>['entrenar', 'gym', 'workout', 'fitness', 'fuerza'],
    category: HabitEmojiCategories.bodyHealth,
  ),
  EmojiOption(
    emoji: '✍️',
    label: 'Escribir',
    keywords: <String>['escribir', 'writing', 'write', 'journal', 'texto'],
    category: HabitEmojiCategories.creativity,
  ),
  EmojiOption(
    emoji: '📓',
    label: 'Diario',
    keywords: <String>['diario', 'journal', 'journaling', 'reflexion', 'notas'],
    category: HabitEmojiCategories.creativity,
  ),
  EmojiOption(
    emoji: '☕',
    label: 'Cafe',
    keywords: <String>['cafe', 'coffee', 'desayuno', 'morning'],
    category: HabitEmojiCategories.foodDrink,
  ),
  EmojiOption(
    emoji: '🍎',
    label: 'Comida sana',
    keywords: <String>['comida', 'food', 'meal', 'healthy', 'fruta', 'eat'],
    category: HabitEmojiCategories.foodDrink,
  ),
  EmojiOption(
    emoji: '🚶',
    label: 'Caminar',
    keywords: <String>['caminar', 'walk', 'walking', 'pasos', 'step'],
    category: HabitEmojiCategories.sport,
  ),
  EmojiOption(
    emoji: '🧹',
    label: 'Limpiar',
    keywords: <String>['limpiar', 'clean', 'cleaning', 'orden', 'ordenar'],
    category: HabitEmojiCategories.homeOrder,
  ),
  EmojiOption(
    emoji: '💼',
    label: 'Trabajo',
    keywords: <String>['trabajo', 'work', 'office', 'job', 'focus'],
    category: HabitEmojiCategories.workStudy,
  ),
  EmojiOption(
    emoji: '🎵',
    label: 'Musica',
    keywords: <String>['musica', 'music', 'song', 'practice', 'instrumento'],
    category: HabitEmojiCategories.creativity,
  ),
  EmojiOption(
    emoji: '🫶',
    label: 'Social',
    keywords: <String>['social', 'amistad', 'friends', 'friend', 'people'],
    category: HabitEmojiCategories.social,
  ),
  EmojiOption(
    emoji: '🩺',
    label: 'Salud',
    keywords: <String>['salud', 'health', 'doctor', 'wellness', 'bienestar'],
    category: HabitEmojiCategories.bodyHealth,
  ),
  EmojiOption(
    emoji: '🚰',
    label: 'Botella',
    keywords: <String>['agua', 'botella', 'water bottle', 'hidratar', 'beber'],
    category: HabitEmojiCategories.foodDrink,
  ),
  EmojiOption(
    emoji: '🛏️',
    label: 'Descanso',
    keywords: <String>['descanso', 'rest', 'bed', 'siesta', 'dormir'],
    category: HabitEmojiCategories.sleepRest,
  ),
  EmojiOption(
    emoji: '🧠',
    label: 'Foco',
    keywords: <String>['mente', 'foco', 'focus', 'brain', 'pensar', 'deep work'],
    category: HabitEmojiCategories.mindFocus,
  ),
  EmojiOption(
    emoji: '🫁',
    label: 'Respirar',
    keywords: <String>['respirar', 'breath', 'breathing', 'calma', 'relax'],
    category: HabitEmojiCategories.bodyHealth,
  ),
  EmojiOption(
    emoji: '🥗',
    label: 'Ensalada',
    keywords: <String>['ensalada', 'salad', 'comida', 'healthy', 'vegetales'],
    category: HabitEmojiCategories.foodDrink,
  ),
  EmojiOption(
    emoji: '🥤',
    label: 'Bebida',
    keywords: <String>['bebida', 'drink', 'smoothie', 'batido', 'tomar'],
    category: HabitEmojiCategories.foodDrink,
  ),
  EmojiOption(
    emoji: '🧺',
    label: 'Lavar',
    keywords: <String>['lavar', 'laundry', 'ropa', 'wash', 'house'],
    category: HabitEmojiCategories.homeOrder,
  ),
  EmojiOption(
    emoji: '🗂️',
    label: 'Organizar',
    keywords: <String>['organizar', 'organize', 'tidy', 'orden', 'workspace'],
    category: HabitEmojiCategories.homeOrder,
  ),
  EmojiOption(
    emoji: '📞',
    label: 'Llamar',
    keywords: <String>['llamar', 'call', 'telefono', 'family', 'social'],
    category: HabitEmojiCategories.social,
  ),
  EmojiOption(
    emoji: '💬',
    label: 'Hablar',
    keywords: <String>['hablar', 'chat', 'talk', 'social', 'mensaje'],
    category: HabitEmojiCategories.social,
  ),
  EmojiOption(
    emoji: '🏋️',
    label: 'Gimnasio',
    keywords: <String>['gimnasio', 'gym', 'pesas', 'entrenar', 'workout'],
    category: HabitEmojiCategories.sport,
  ),
  EmojiOption(
    emoji: '🚴',
    label: 'Bicicleta',
    keywords: <String>['bici', 'bicicleta', 'bike', 'cycling', 'cardio'],
    category: HabitEmojiCategories.sport,
  ),
  EmojiOption(
    emoji: '🎨',
    label: 'Arte',
    keywords: <String>['arte', 'art', 'draw', 'dibujar', 'creative'],
    category: HabitEmojiCategories.creativity,
  ),
  EmojiOption(
    emoji: '📷',
    label: 'Foto',
    keywords: <String>['foto', 'camera', 'photography', 'creative'],
    category: HabitEmojiCategories.creativity,
  ),
  EmojiOption(
    emoji: '🌿',
    label: 'Naturaleza',
    keywords: <String>['naturaleza', 'nature', 'garden', 'plantas', 'green'],
    category: HabitEmojiCategories.nature,
  ),
  EmojiOption(
    emoji: '☀️',
    label: 'Sol',
    keywords: <String>['sol', 'sun', 'morning', 'outside', 'naturaleza'],
    category: HabitEmojiCategories.nature,
  ),
  EmojiOption(
    emoji: '💰',
    label: 'Ahorrar',
    keywords: <String>['ahorrar', 'save', 'money', 'finanzas', 'budget'],
    category: HabitEmojiCategories.others,
  ),
  EmojiOption(
    emoji: '🪥',
    label: 'Cepillarse',
    keywords: <String>['dientes', 'cepillar', 'brush', 'higiene', 'teeth'],
    category: HabitEmojiCategories.bodyHealth,
  ),
  EmojiOption(
    emoji: '🙏',
    label: 'Gratitud',
    keywords: <String>['gratitud', 'grateful', 'pray', 'agradecer', 'thanks'],
    category: HabitEmojiCategories.mindFocus,
  ),
];
