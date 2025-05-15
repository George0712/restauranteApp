import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/bx.dart';
import 'package:iconify_flutter/icons/ion.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:iconify_flutter/icons/ri.dart';
import 'package:restaurante_app/presentation/widgets/option_button_card.dart';

class HomeMeseroScreen extends ConsumerStatefulWidget {
  const HomeMeseroScreen({super.key});

  @override
  ConsumerState<HomeMeseroScreen> createState() => _HomeMeseroScreenState();
}

class _HomeMeseroScreenState extends ConsumerState<HomeMeseroScreen> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final theme = Theme.of(context);

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent, // importante
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 60,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          leading: Padding(
            padding: const EdgeInsets.all(10),
            child: GestureDetector(
              onTap: () {
                context.push('/admin/settings');
              },
              child: CircleAvatar(
                backgroundColor: Colors.grey[300],
                child: Center(
                  child: Icon(
                    Icons.person,
                    size: 35,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ),
          ),
          title: Text(
            '',
            style: TextStyle(color: theme.primaryColor),
          ),
        ),
        body: Stack(children: [
          Positioned.fill(
            child: Opacity(
              opacity: 1,
              child: Image.asset(
                'lib/core/assets/bg-mesero.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            color: Colors.white.withAlpha(
                40), 
          ),
          Align(
            alignment: Alignment.center,
            child: SingleChildScrollView(
              padding: isTablet
                  ? const EdgeInsets.symmetric(vertical: 40, horizontal: 80)
                  : const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: isTablet ? 4 : 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      OptionButtonCard(
                        icon: const Iconify(Ri.restaurant_2_fill, size: 60),
                        text: 'Mesas',
                        onTap: () {},
                      ),
                      OptionButtonCard(
                        icon: const Iconify(Ion.fast_food, size: 60),
                        text: 'Para llevar',
                        onTap: () {},
                      ),
                      OptionButtonCard(
                        icon: const Iconify(Mdi.delivery_dining, size: 60),
                        text: 'Domicilios',
                        onTap: () {},
                      ),
                      OptionButtonCard(
                        icon: const Iconify(Bx.bxs_receipt, size: 60),
                        text: 'Historial',
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
