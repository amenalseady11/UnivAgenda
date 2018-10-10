import 'dart:async';

import 'package:flutter/material.dart';
import 'package:myagenda/keys/assets.dart';
import 'package:myagenda/keys/route_key.dart';
import 'package:myagenda/keys/string_key.dart';
import 'package:myagenda/keys/url.dart';
import 'package:myagenda/screens/appbar_screen.dart';
import 'package:myagenda/utils/analytics.dart';
import 'package:myagenda/utils/http/http_request.dart';
import 'package:myagenda/utils/preferences.dart';
import 'package:myagenda/utils/translations.dart';
import 'package:myagenda/widgets/ui/raised_button_colored.dart';

class SplashScreen extends StatefulWidget {
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  bool _isPrefsLoaded = false;
  bool _isError = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isPrefsLoaded) {
      _initPreferences();
      _startTimeout();
    }
  }

  void _initPreferences() async {
    _isPrefsLoaded = true;
    setState(() {
      _isError = false;
    });
    _startTimeout();

    final startTime = DateTime.now();

    final prefs = PreferencesProvider.of(context);

    // Load preferences from disk
    await prefs.initFromDisk();

    // Update resources if they are empty or older than 6 hours
    int oldRes = DateTime.now().difference(prefs.resourcesDate).inHours.abs();

    // If user haven't choose custom ics file
    if (prefs.urlIcs == null) {
      // If university list is empty or cache is older than 6 hours
      if (prefs.listUniversity.length == 0 || oldRes >= 6) {
        // Request lastest university list
        final responseUniv = await HttpRequest.get(Url.listUniversity);
        // If request failed and there is no list University
        if (!responseUniv.isSuccess && prefs.listUniversity.length == 0) {
          _setError();
          return;
        }
        // Update university list
        prefs.setListUniversityFromJSONString(responseUniv.httpResponse.body);
        prefs.setResourcesDate(startTime);
      }

      // If list university still empty, set error
      if (prefs.listUniversity.length == 0) {
        _setError();
        return;
      }
    }

    // If user was connected but university or ics url are null, disconnect him
    if (prefs.urlIcs == null && prefs.university == null && prefs.isUserLogged)
      prefs.setUserLogged(false);

    // If university is null, take the first of list
    if (prefs.urlIcs == null && prefs.university == null)
      prefs.setUniversity(prefs.listUniversity[0].name);

    // If user is connected and have an university but no resources
    // Or same as top but with cache older than 6 hours
    if (prefs.isUserLogged &&
        prefs.urlIcs == null &&
        prefs.university != null &&
        (prefs.resources.length == 0 || oldRes >= 6)) {
      final responseRes = await HttpRequest.get(
        Url.resourcesUrl(prefs.university.resourcesFile),
      );

      if (!responseRes.isSuccess && prefs.resources.length == 0) {
        _setError();
        return;
      }

      // Update resources with new data get
      final resourcesGet = responseRes.httpResponse.body;
      prefs.setResources(resourcesGet);
      prefs.setResourcesDate(startTime);
    }

    prefs.forceSetStat();

    AnalyticsProvider.of(context).analytics.setUserId(prefs.installUID);

    final routeDest = (!prefs.isIntroDone)
        ? RouteKey.INTRO
        : (prefs.isUserLogged) ? RouteKey.HOME : RouteKey.LOGIN;

    // Wait minimum 1.5 secondes
    final diffMs = DateTime.now().difference(startTime).inMilliseconds;
    final waitTime = diffMs < 1500 ? 1500 - diffMs : 0;

    Future.delayed(Duration(milliseconds: waitTime)).then((_) {
      _goToNext(routeDest);
    });
  }

  void _startTimeout() async {
    // Start timout of 30sec. If widget still mounted, set error
    // If not mounted anymore, do nothing
    await Future.delayed(Duration(seconds: 30));
    if (mounted) {
      setState(() {
        _isError = true;
      });
    }
  }

  void _setError() {
    if (mounted)
      setState(() {
        _isPrefsLoaded = false;
        _isError = true;
      });
  }

  void _goToNext(String route) {
    if (mounted) Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    final translations = Translations.of(context);

    return AppbarPage(
      body: Container(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Expanded(
              flex: 6,
              child: Center(
                child: Image.asset(Asset.LOGO, width: 192.0),
              ),
            ),
            Expanded(
              flex: 4,
              child: Center(
                child: _isError
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            translations.get(StringKey.NETWORK_ERROR),
                            style: Theme.of(context).textTheme.subhead,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24.0),
                          RaisedButtonColored(
                            text: translations.get(StringKey.RETRY),
                            onPressed: _initPreferences,
                          )
                        ],
                      )
                    : const CircularProgressIndicator(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
