import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:univagenda/keys/string_key.dart';
import 'package:univagenda/models/resource.dart';
import 'package:univagenda/screens/appbar_screen.dart';
import 'package:univagenda/screens/base_state.dart';
import 'package:univagenda/screens/find_schedules/find_schedules_result.dart';
import 'package:univagenda/utils/analytics.dart';
import 'package:univagenda/utils/custom_route.dart';
import 'package:univagenda/utils/functions.dart';
import 'package:univagenda/utils/translations.dart';
import 'package:univagenda/widgets/ui/treeview/node.dart';
import 'package:univagenda/widgets/ui/treeview/treeview.dart';
import 'package:outline_material_icons/outline_material_icons.dart';

class FindSchedulesFilter extends StatefulWidget {
  final List<String> groupKeySearch;
  final DateTime startTime;
  final DateTime endTime;

  const FindSchedulesFilter({
    Key key,
    this.groupKeySearch,
    this.startTime,
    this.endTime,
  }) : super(key: key);

  FindSchedulesFilterState createState() => FindSchedulesFilterState();
}

class FindSchedulesFilterState extends BaseState<FindSchedulesFilter> {
  String _search;
  String _treeTitle;
  Map<String, dynamic> _treeValues = {};
  HashSet<Node> _selectedResources = HashSet();

  @override
  void initState() {
    super.initState();
    AnalyticsProvider.setScreen(widget);
  }

  void didChangeDependencies() {
    super.didChangeDependencies();
    final selectFirst = widget.groupKeySearch[0];
    final selectSecond = widget.groupKeySearch[1];

    _treeTitle = selectSecond;
    _treeValues = prefs.resources[selectFirst][selectSecond];
  }

  void _onSubmit() {
    Navigator.of(context).push(
      CustomRoute(
        builder: (context) => FindSchedulesResults(
          searchResources: _selectedResources.map((node) {
            return Resource(node.key, node.value);
          }).toList(),
          startTime: widget.startTime,
          endTime: widget.endTime,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  Widget _buildAppbarSub() {
    final color = getColorDependOfBackground(theme.primaryColor);

    return TextField(
      keyboardType: TextInputType.text,
      style: TextStyle(color: color),
      cursorColor: color,
      decoration: InputDecoration(
          hintStyle: TextStyle(color: color),
          hintText: i18n.text(StrKey.SEARCH),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 16.0)),
      onChanged: (search) => setState(() => _search = search),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppbarPage(
      title: i18n.text(StrKey.FINDSCHEDULES_FILTER_SELECTION),
      actions: [
        IconButton(icon: const Icon(OMIcons.search), onPressed: _onSubmit),
      ],
      body: Container(
        child: Column(
          children: [
            AppbarSubTitle(
              child: _buildAppbarSub(),
              padding: EdgeInsets.zero,
            ),
            Expanded(
              child: TreeView(
                treeTitle: _treeTitle,
                dataSource: _treeValues,
                search: _search,
                onCheckedChanged: (listNode) {
                  _selectedResources = listNode;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
