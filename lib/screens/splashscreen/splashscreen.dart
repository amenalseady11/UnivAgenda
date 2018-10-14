import 'dart:async';

import 'package:flutter/material.dart';
import 'package:myagenda/keys/assets.dart';
import 'package:myagenda/keys/route_key.dart';
import 'package:myagenda/keys/string_key.dart';
import 'package:myagenda/keys/url.dart';
import 'package:myagenda/screens/appbar_screen.dart';
import 'package:myagenda/screens/base_state.dart';
import 'package:myagenda/utils/http/http_request.dart';
import 'package:myagenda/widgets/ui/raised_button_colored.dart';

class SplashScreen extends StatefulWidget {
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends BaseState<SplashScreen> {
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 100)).then((_) {
      _initPreferences();
    });
  }

  void _initPreferences() async {
    _setError(false);
    _startTimeout();

    final startTime = DateTime.now();

    // Load preferences from disk
    await prefs.initFromDisk();

    // Update resources if they are empty or older than 6 hours
    int oldRes = DateTime.now().difference(prefs.resourcesDate).inHours.abs();

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

    analyticsProvider.analytics.setUserId(prefs.installUID);
    prefs.forceSetState();

    final routeDest = (!prefs.isIntroDone)
        ? RouteKey.INTRO
        : (prefs.isUserLogged) ? RouteKey.HOME : RouteKey.LOGIN;

    // Wait minimum 1.5 secondes
    final diffMs = 1500 - DateTime.now().difference(startTime).inMilliseconds;
    final waitTime = diffMs < 0 ? 0 : diffMs;

    await Future.delayed(Duration(milliseconds: waitTime));
    _goToNext(routeDest);
  }

  void _startTimeout() async {
    // Start timout of 20sec. If widget still mounted, set error
    // If not mounted anymore, do nothing
    await Future.delayed(Duration(seconds: 20));
    _setError();
  }

  void _setError([bool isError = true]) {
    if (mounted)
      setState(() {
        _isError = isError;
      });
  }

  void _goToNext(String route) {
    if (mounted) Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
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
