import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:wasabee/classutils/dialog.dart';
import 'package:wasabee/classutils/team.dart';
import 'package:wasabee/network/cookies.dart';
import 'package:wasabee/network/networkcalls.dart';
import 'package:wasabee/network/responses/meResponse.dart';
import 'package:wasabee/network/responses/teamResponse.dart';
import 'package:wasabee/network/urlmanager.dart';
import 'package:wasabee/pages/teamspage/teamdialogvm.dart';
import 'package:wasabee/pages/teamspage/teamfiltermanager.dart';
import 'package:wasabee/pages/teamspage/teamlistvm.dart';
import 'package:wasabee/pages/teamspage/teamsortdialog.dart';
import 'package:wasabee/storage/localstorage.dart';

class TeamPage extends StatefulWidget {
  TeamPage(
      {Key key,
      this.teamSortDropDownValue,
      this.teamFilterDropDownValue,
      this.googleId})
      : super(key: key);
  final TeamSortType teamSortDropDownValue;
  final TeamFilterType teamFilterDropDownValue;
  final String googleId;

  @override
  TeamPageState createState() =>
      TeamPageState(teamSortDropDownValue, teamFilterDropDownValue, googleId);
}

class TeamPageState extends State<TeamPage> {
  TextStyle style = TextStyle(fontFamily: 'Montserrat', fontSize: 20.0);
  TeamSortType teamSortDropDownValue;
  TeamFilterType teamFilterDropDownValue;
  List<TeamListViewModel> vmList;
  List<TeamListViewModel> totalVmList;
  List<Team> teamList;
  List<Team> ownedTeamList;
  String googleId;
  bool isLoading = true;
  bool someThingChanged = false;
  TeamPageState(TeamSortType teamSortDropDownValue,
      TeamFilterType teamFilterDropDownValue, String googleId) {
    this.teamSortDropDownValue = teamSortDropDownValue;
    this.teamFilterDropDownValue = teamFilterDropDownValue;
    this.googleId = googleId;
  }

  @override
  void initState() {
    getTeams();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var title = "Teams";
    return WillPopScope(
        onWillPop: () async {
          Navigator.pop(context, someThingChanged);
          debugPrint("Will pop");
          return false;
        },
        child: getBody(title));
  }

  Widget getBody(String title) {
    return isLoading == true
        ? Scaffold(
            appBar: AppBar(
              title: Text(title),
            ),
            body: Container(
                color: Colors.white,
                child: Center(
                  child: CircularProgressIndicator(),
                )))
        : getLoadedBody(title);
  }

  Widget getLoadedBody(String title) {
    return Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        body: Column(children: <Widget>[
          Container(
              margin:
                  EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0, bottom: .0),
              child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    VerticalDivider(),
                    Expanded(
                        child: DropdownButton<TeamFilterType>(
                      isExpanded: true,
                      value: teamFilterDropDownValue,
                      underline: Divider(
                        color: Colors.white,
                      ),
                      onChanged: (TeamFilterType newValue) {
                        LocalStorageUtils.setTeamFilter(newValue).then((any) {
                          setTeamFilterDropdownValue(newValue);
                        });
                      },
                      items: TeamFilterManager.getFilters()
                          .map<DropdownMenuItem<TeamFilterType>>((value) {
                        return DropdownMenuItem<TeamFilterType>(
                          value: value,
                          child: Text(
                              TeamFilterManager.getDisplayStringFromEnum(
                                  value, totalVmList, googleId)),
                        );
                      }).toList(),
                    )),
                    Row(
                      children: <Widget>[
                        Container(
                          width: 5.0,
                          height: 30.0,
                          color: Colors.green,
                        )
                      ],
                    ),
                    IconButton(
                      color: Colors.white,
                      icon: Icon(
                        Icons.sort,
                        color: Colors.black,
                      ),
                      onPressed: () {
                        showDialog(
                            barrierDismissible: false,
                            context: context,
                            builder: (_) => TeamSortDialog(
                                selectedValue: teamSortDropDownValue,
                                baseState: this));
                      },
                    ),
                  ])),
          Divider(
            color: Colors.black,
            height: 4,
          ),
          Expanded(
              child: ListView.builder(
                  itemCount: vmList.length,
                  itemBuilder: (BuildContext context, int index) {
                    TeamListViewModel vm = vmList[index];
                    return getListItem(vm, index);
                  }))
        ]));
  }

  Widget getListItem(TeamListViewModel vm, int index) {
    var teamRowWidgets = <Widget>[
      Container(
          padding: EdgeInsets.all(8),
          child: CircleAvatar(
            radius: 8,
            backgroundColor: vm.isEnabled ? Colors.green : Colors.red,
          )),
      Container(
          padding: EdgeInsets.only(top: 8, left: 8, bottom: 8),
          child: Text(
            '${vm.titleString}',
            style: TextStyle(fontSize: 15),
          )),
      Expanded(
          child: Container(
              padding: EdgeInsets.only(left: 8),
              child: Divider(
                color: Colors.green,
              ))),
    ];
    if (vm.isOwned)
      teamRowWidgets.add(Container(
          padding: EdgeInsets.only(left: 8), child: Icon(Icons.verified_user)));
    return Container(
        color: DialogUtils.getListBgColor(index),
        child: Material(
            color: Colors.transparent,
            child: InkWell(
                onTap: () {
                  tappedTeam(vm);
                },
                child: Column(children: <Widget>[
                  Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: teamRowWidgets),
                ]))));
  }

  tappedTeam(TeamListViewModel vm) {
    if (vm.isEnabled) {
      setState(() {
        isLoading = true;
      });
      getIndividualTeam(vm);
    } else
      showTeamDetailsAlert(vm, null);
  }

  getIndividualTeam(TeamListViewModel vm) {
    var url = UrlManager.getTeamUrl(vm.teamId);
    try {
      NetworkCalls.doNetworkCall(url, Map<String, String>(), finishedGetTeam,
          true, NetWorkCallType.GET, vm);
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print(e);
    }
  }

  finishedGetTeam(String response, dynamic vm) async {
    try {
      print('name => ${vm.teamName}');
      var teamResponse = TeamResponse.fromJson(json.decode(response));
      showTeamDetailsAlert(vm, teamResponse);
    } catch (e) {
      await CookieUtils.clearAllCookies();
      print("Exception In getTeams -> $e");
    }
    setState(() {
      isLoading = false;
    });
  }

  showTeamDetailsAlert(TeamListViewModel vm, TeamResponse teamResponse) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return TeamUtils.getTeamInfoAlert(
            context, TeamDialogViewModel.fromObjects(vm, teamResponse), this);
      },
    );
  }

  getTeams() {
    var url = UrlManager.FULL_ME_URL;
    try {
      NetworkCalls.doNetworkCall(url, Map<String, String>(), finishedGetTeams,
          true, NetWorkCallType.GET, null);
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print(e);
    }
  }

  toggleTeam(String teamId, Map<String, String> data) {
    try {
      setState(() {
        isLoading = true;
      });
      String url = UrlManager.getModTeamUrl(teamId);
      url = "${UrlManager.addDataToUrl(url, data)}";
      NetworkCalls.doNetworkCall(url, data, finishedToggleTeam,
          true, NetWorkCallType.GET, null);
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print(e);
    }
  }

  finishedToggleTeam(String response, dynamic object) {
    someThingChanged = true;
    getTeams();
  }

  void finishedGetTeams(String response, dynamic object) async {
    try {
      var meResponse = MeResponse.fromJson(json.decode(response));
      var googleId = meResponse.googleID;
      if (googleId != null) await LocalStorageUtils.storeGoogleId(googleId);
      teamList = meResponse.teams;
      ownedTeamList = meResponse.ownedTeams;
      totalVmList = TeamListViewModel.fromTeamData(
          teamList, ownedTeamList, teamSortDropDownValue, TeamFilterType.All);
      setState(() {
        updateTeamList();
        isLoading = false;
      });
    } catch (e) {
      await CookieUtils.clearAllCookies();
      setState(() {
        isLoading = false;
      });
      print("Exception In getTeams -> $e");
    }
  }

  updateTeamList() {
    vmList = TeamListViewModel.fromTeamData(teamList, ownedTeamList,
        teamSortDropDownValue, teamFilterDropDownValue);
  }

  setTeamFilterDropdownValue(TeamFilterType value) {
    setState(() {
      teamFilterDropDownValue = value;
      updateTeamList();
    });
  }

  setTeamSortDropdownValue(TeamSortType value) {
    setState(() {
      teamSortDropDownValue = value;
      updateTeamList();
    });
  }
}
