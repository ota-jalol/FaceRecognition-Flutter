library my_localization;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_translate/flutter_translate.dart';

late LocalizationDelegate _delegate;


typedef MyLocalizationBuilder =
    Widget Function(
      Iterable<LocalizationsDelegate<dynamic>> localizationsDelegates,
      LocalizationDelegate delegate,
    );

class MyLocalization {
  Future<void> initialize({
    required List<String> supportedLocales,
    String? actualLang,
  }) async {
    if (supportedLocales.isEmpty) {
      throw Exception("supportedLocales must be not empty");
    }

    _delegate = await LocalizationDelegate.create(
      fallbackLocale: supportedLocales.first,
      supportedLocales: supportedLocales,
      basePath: 'assets/i18n',
    );

    if (actualLang != null) {
      if (supportedLocales.contains(actualLang)) {
        await _delegate.changeLocale(Locale(actualLang));

        return;
      } else {
        throw Exception("actualLang does not contain on supportedLocales");
      }
    }

    var locale = Locale(Platform.localeName.split('_').first);
    if (actualLang != null) {
      locale = Locale(actualLang);
    } else if (supportedLocales.contains(locale.languageCode)) {
      locale = Locale(locale.languageCode);
    } else {
      locale = Locale(supportedLocales.first);
    }

    await _delegate.changeLocale(locale);
  }

  static LocalizedApp localizedApp(Widget app) => LocalizedApp(_delegate, app);

  static LocalizationProvider provider(
    BuildContext context, {
    required MyLocalizationBuilder materialAppBuilder,
  }) {
    WidgetsBinding.instance;

    final LocalizationDelegate localizationDelegate = LocalizedApp.of(
      context,
    ).delegate;

    return LocalizationProvider(
      state: LocalizationProvider.of(context).state,
      child: materialAppBuilder([
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        localizationDelegate,
      ], localizationDelegate),
    );
  }

  static LocalizationDelegate delegate = _delegate;
}

String tr(String key) {
  return translate(key);
}
