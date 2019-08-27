import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:wasabee/network/urlmanager.dart';
import 'package:wasabee/pages/loginpage/login.dart';
import 'package:wasabee/pages/mappage/utilities.dart';
import 'package:wasabee/network/cookies.dart';
import 'package:wasabee/network/responses/meResponse.dart';
import 'package:wasabee/network/responses/operationFullResponse.dart';
import 'package:wasabee/pages/settingspage/constants.dart';
import 'package:wasabee/storage/localstorage.dart';

import '../main.dart';

class OperationUtils {
  static Map<String, Portal> getPortalMap(List<Portal> portalList) {
    Map<String, Portal> portalMap = Map<String, Portal>();
    for (var portal in portalList) portalMap[portal.id] = portal;
    return portalMap;
  }

  static Color getLinkColor(Op operation) {
    String hexString = "";
    switch (operation.color) {
      case "groupa":
        hexString = 'ff6600';
        break;
      case "groupb":
        hexString = 'ff9900';
        break;
      case "groupc":
        hexString = 'BB9900';
        break;
      case "groupd":
        hexString = 'bb22cc';
        break;
      case "groupe":
        hexString = '33cccc';
        break;
      case "groupf":
        hexString = 'ff55ff';
        break;
    }
    return HexColor(hexString);
  }

  static Color getPortalLevelColor(double portalLevel) {
    String hexString = '#FECE5A';
    if (portalLevel >= 1 && portalLevel < 2) {
      hexString = 'FECE5A';
    } else if (portalLevel >= 2 && portalLevel < 3) {
      hexString = 'FFA630';
    } else if (portalLevel >= 3 && portalLevel < 4) {
      hexString = 'FF7315';
    } else if (portalLevel >= 4 && portalLevel < 5) {
      hexString = 'E40000';
    } else if (portalLevel >= 5 && portalLevel < 6) {
      hexString = 'FD2992';
    } else if (portalLevel >= 6 && portalLevel < 7) {
      hexString = 'EB26CD';
    } else if (portalLevel >= 7 && portalLevel < 8) {
      hexString = 'C124E0';
    } else if (portalLevel >= 8) {
      hexString = '9627F4';
    }
    return HexColor(hexString);
  }

  static Portal getPortalFromID(String id, Operation operation) {
    for (var portal in operation.opportals) {
      if (portal.id == id) return portal;
    }
    return null;
  }

  static List<Link> getLinksForPortalId(String id, Operation operation) {
    var linkList = List<Link>();
    if (operation.links != null)
      for (var link in operation.links) {
        if (link.fromPortalId == id || link.toPortalId == id) {
          linkList.add(link);
        }
      }
    return linkList;
  }

  static AlertDialog getParsingOperationFailedDialog(
      BuildContext context, String operationName) {
    return AlertDialog(
      title: Text('Parsing Op Failed!'),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Text(
                'Either parsing the operation$operationName failed or your auth token expired.  You must login again to continue.  If you\'ve seen this message within 5 minutes, check the operation you\'re trying to load.'),
          ],
        ),
      ),
      actions: <Widget>[
        FlatButton(
          child: Text('Ok'),
          onPressed: () {
            Navigator.of(context).pop();
            LocalStorageUtils.storeSelectedOpId(null).then((any) {
              CookieUtils.clearAllCookiesAndGotoLogin(context);
            });
          },
        ),
      ],
    );
  }

  static AlertDialog checkForAlertsMarkersLinks(
      Operation operation, BuildContext context) {
    if (operation.markers.length == 0 &&
        operation.anchors.length == 0 &&
        operation.links.length == 0) {
      return AlertDialog(
        title: Text('No Links/Alerts Found'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text(
                  'No Links or Alerts were found for this operation.  You should add some!'),
            ],
          ),
        ),
        actions: <Widget>[
          FlatButton(
            child: Text('Ok'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    } else
      return null;
  }

  static AlertDialog getNoOperationDialog(BuildContext context) {
    return AlertDialog(
      title: Text('No Operations Found'),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Text('No operations were found for your user on the server.'),
          ],
        ),
      ),
      actions: <Widget>[
        FlatButton(
          child: Text('More Info'),
          onPressed: () {
            Navigator.of(context).pop();
            CookieUtils.clearAllCookiesAndGotoLogin(context);
            UrlManager.openWasabeeWebsite();
          },
        ),
        FlatButton(
          child: Text('Ok'),
          onPressed: () {
            Navigator.of(context).pop();
            CookieUtils.clearAllCookiesAndGotoLogin(context);
          },
        ),
      ],
    );
  }

  static AlertDialog getRefreshOpListDialog(BuildContext context) {
    return AlertDialog(
      title: Text('Refresh Op List?'),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Text('Are you sure you want to refresh your operation list?'),
          ],
        ),
      ),
      actions: <Widget>[
        FlatButton(
          child: Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        FlatButton(
          child: Text('Ok'),
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.pushNamedAndRemoveUntil(
                context, WasabeeConstants.LOGIN_ROUTE_NAME, (r) => false);
          },
        ),
      ],
    );
  }
}
