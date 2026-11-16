import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/commerce/presentation/bloc/commerce_bloc.dart';

class ECommerceApp extends StatelessWidget {
  const ECommerceApp({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => CommerceBloc(),
    child: MaterialApp(
      title: 'NOVA Store',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.home,
      onGenerateRoute: AppRouter.onGenerateRoute,
      locale: const Locale('en'),
      supportedLocales: const [Locale('en'), Locale('ar')],
    ),
  );
}
