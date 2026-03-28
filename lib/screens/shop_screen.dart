import 'package:flutter/material.dart';
import 'package:rutio/widgets/app_header/app_header.dart';
import 'package:rutio/widgets/app_view_drawer.dart';
import 'package:rutio/screens/home/home_screen.dart';
import 'package:rutio/screens/habit_weekly_screen.dart';
import 'package:rutio/screens/habit_archived_screen.dart';
import 'package:rutio/screens/diary/diary_screen.dart';
import 'package:rutio/screens/profile/profile_screen.dart';
import 'package:rutio/screens/habit_stats_overview_screen.dart';
import 'package:rutio/screens/habit_monthly_screen.dart';

void _navReplace(BuildContext context, Widget screen) {
  final st = Scaffold.maybeOf(context);
  if (st != null && st.isDrawerOpen) {
    Navigator.of(context).pop(); // close drawer
  }
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (_) => screen),
  );
}

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final List<String> _categories = [
    'Ropa',
    'Zapatos',
    'Accesorios',
    'Mascotas',
    'Consumibles',
    'Ofertas',
    'Marcos de perfil',
    'Badges de nombre',
    'Fondos de avatar',
    'Animaciones',
  ];

  int _selectedIndex = 0;
  int _coins = 120;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppViewDrawer(
        selected: 'shop',
        onGoDaily: () => _navReplace(context, const HomeScreen()),
        onGoWeekly: () => _navReplace(context, const HabitWeeklyScreen()),
        onGoMonthly: () => _navReplace(context, const HabitMonthlyScreen()),
        onGoTodo: () => Navigator.pushNamed(context, '/todo'),
        onGoDiary: () => _navReplace(context, const DiaryScreen()),
        onGoArchived: () => _navReplace(context, const ArchivedHabitsScreen()),
        onGoStats: () => _navReplace(context, const HabitStatsOverviewHost()),
        onGoProfile: () => _navReplace(context, const ProfileScreen()),
      ),
      backgroundColor: const Color(0xFFD9CCF3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD9CCF3),
        elevation: 0,
        leadingWidth: AppDrawerAppBarLeading.leadingWidth,
        leading: Builder(
          builder: (ctx) => AppDrawerAppBarLeading(
            onTap: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: const Text('Tienda'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _CoinsPill(coins: _coins),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          _CategorySelector(
            categories: _categories,
            selectedIndex: _selectedIndex,
            onSelect: (i) => setState(() => _selectedIndex = i),
          ),
          const SizedBox(height: 14),
          _SearchBar(),
          const SizedBox(height: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                itemCount: 12,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.78,
                ),
                itemBuilder: (context, index) {
                  return _ProductCard(
                    name: 'Producto $index',
                    price: 25,
                    onBuy: () => _confirmBuy(context, 'Producto $index', 25),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmBuy(BuildContext context, String name, int price) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar compra'),
        content: Text(
          '¿Estás seguro que quieres comprar "$name" por $price monedas?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              // Cierra el popup de confirmación
              Navigator.pop(context);

              if (_coins >= price) {
                setState(() => _coins -= price);
              } else {
                _showInsufficientCoinsDialog(context, price);
              }
            },
            child: const Text('Sí'),
          ),
        ],
      ),
    );
  }

  void _showInsufficientCoinsDialog(BuildContext context, int price) {
    final missing = price - _coins;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Monedas insuficientes'),
        content: Text(
          'No tienes suficientes monedas para esta compra.\n'
          'Te faltan $missing monedas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }
}

/* ===================== COMPONENTES ===================== */

class _CoinsPill extends StatelessWidget {
  final int coins;
  const _CoinsPill({required this.coins});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.monetization_on, size: 18),
          const SizedBox(width: 4),
          Text(
            '$coins',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _CategorySelector extends StatelessWidget {
  final List<String> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _CategorySelector({
    required this.categories,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(categories.length, (index) {
              final selected = index == selectedIndex;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: GestureDetector(
                  onTap: () => onSelect(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF8E7CC3)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      categories[index],
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.grey[800],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Buscar...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final String name;
  final int price;
  final VoidCallback onBuy;

  const _ProductCard({
    required this.name,
    required this.price,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          // 🖼️ IMAGEN PRENDA
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              alignment: Alignment.center,
            ),
          ),

          // 🔽 NOMBRE + PRECIO
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.monetization_on, size: 14),
                        const SizedBox(width: 3),
                        Text(
                          '$price',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    height: 24,
                    child: ElevatedButton(
                      onPressed: onBuy,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8E7CC3),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        textStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Comprar'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
