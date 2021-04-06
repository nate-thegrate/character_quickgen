import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'main.dart';

var dndTheme = ThemeData(primarySwatch: Colors.green);
var autoArrange = true;

List<int> stats = []; // generated stat values
List<int> bonuses = []; // bonus that can be changed by user
List<List<int>> arrays = [
  [18, 17, 8, 8, 7, 7],
  [18, 15, 14, 7, 7, 7],
  [18, 14, 13, 11, 7, 7],
  [18, 11, 11, 11, 11, 11],
  [17, 16, 10, 10, 9, 9],
  [17, 14, 12, 10, 10, 10],
  [16, 16, 16, 7, 7, 7],
  [16, 15, 14, 10, 8, 8],
  [16, 14, 13, 12, 10, 9],
  [16, 12, 12, 12, 12, 12],
  [15, 14, 14, 14, 9, 9],
  [15, 15, 15, 10, 10, 10],
  [15, 14, 12, 12, 12, 12],
  [14, 14, 14, 14, 14, 9]
];

void generate(index) {
  switch (index) {
    case 0: // 4d6 Drop Lowest
      {
        stats = <int>[];
        for (var i = 0; i < 6; i++) {
          var dice = <int>[];
          for (var j = 0; j < 4; j++) {
            dice.add(d6());
          }
          dice.sort();
          dice.removeAt(0); // drop lowest
          stats.add(dice.reduce((a, b) => a + b)); // append each stat to list
        }
      }
      break;
    case 1: // Standard Array
      {
        stats = [15, 14, 13, 12, 10, 8];
        stats.shuffle();
      }
      break;
    case 2: // Random Array
      {
        stats = arrays[rng.nextInt(arrays.length)].toList();
        stats.shuffle();
      }
      break;
  }

  bonuses = [0, 0, 0, 0, 0, 0];

  if (autoArrange) {
    stats.sort();
    List<int> betterStats = []; // randomly select 3 stats to prioritize
    if (rng.nextInt(13) == 0) {
      betterStats = [0, 1, 2]; // Barbarian
    } else {
      int strDex = (rng.nextDouble() + .75).toInt();
      final int con = 2;
      double x = rng.nextDouble();
      int intWisCha = (x < 2 / 9)
          ? 3
          : (x < 2 / 3)
              ? 4
              : 5;
      betterStats = [strDex, con, intWisCha];
      List<int> betterValues = [stats[3], stats[4], stats[5]];
      // highest 3 stats
      stats = [stats[0], stats[1], stats[2]];
      // reduce stats to the lowest 3
      stats.shuffle();
      betterValues.shuffle();
      for (final stat in betterStats) {
        // loop through indices of prioritized stats
        stats.insert(stat, betterValues.removeAt(0));
      }
    }
    var highestEvenScore = stats.reduce((a, b) {
      if (a % 2 != 0 || (b > a && b % 2 == 0)) {
        return b;
      }
      return a;
    });
    var highestOddScore = stats.reduce((a, b) {
      if (a % 2 == 0 || (b > a && b % 2 != 0)) {
        return b;
      }
      return a;
    });
    bonuses[stats.indexOf(highestEvenScore)] = 2;
    bonuses[stats.indexOf(highestOddScore)] = 1;
  }
}

class DnDHome extends StatefulWidget {
  @override
  _DnDHomeState createState() => _DnDHomeState();
}

class _DnDHomeState extends State<DnDHome> {
  @override
  Widget build(BuildContext context) {
    Widget generateChoices() {
      final List choices = [
        '4d6 Drop Lowest',
        'Standard Array',
        'Random Array'
      ];
      return Flexible(
        child: ListView.separated(
          padding: const EdgeInsets.all(8),
          itemCount: choices.length,
          itemBuilder: (BuildContext context, int index) {
            return ListTile(
                title: Text(choices[index]),
                trailing: Icon(Icons.keyboard_arrow_right_rounded),
                onTap: () {
                  generate(index);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => StatScreen()),
                  );
                });
          },
          separatorBuilder: (BuildContext context, int index) =>
              const Divider(),
        ),
      );
    }

    final bottomButtons = Column(children: [
      ListTile(
          title: Text('Edit Random Arrays'),
          trailing: Container(
              margin: EdgeInsets.only(right: 15), child: Icon(Icons.edit)),
          onTap: () {
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => EditArrays()));
          }),
      Tooltip(
        message: 'Allocate stats into a viable configuration',
        child: SwitchListTile(
          title: Text('Auto-arrange stats?'),
          value: autoArrange,
          onChanged: (value) => setState(() => autoArrange = value),
        ),
      ),
    ]);

    return Theme(
      data: dndTheme,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Make a Random 5e Character'),
        ),
        drawer: appDrawer(context),
        body: Column(
          children: [
            generateChoices(),
            bottomButtons,
          ],
        ),
      ),
    );
  }
}

class EditArrays extends StatefulWidget {
  @override
  _EditArraysState createState() => _EditArraysState();
}

class _EditArraysState extends State<EditArrays> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    var arrayText = '';
    for (final array in arrays) {
      for (var i = 0; i < array.length; i++) {
        arrayText += '${array[i]}${(i < array.length - 1) ? ' ' : ''}';
      }
      arrayText += '\n';
    }
    _controller.text = arrayText;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  var editIcon = Icon(Icons.edit);

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;

    final saveIcon = IconButton(
        icon: Icon(Icons.check_rounded),
        onPressed: () {
          var txt = _controller.text;
          var tempArrays = txt.split('\n');
          arrays = [];
          for (var array in tempArrays) {
            var stats = array.split(' ');
            var intStats = <int>[];
            for (var stat in stats) {
              try {
                intStats.add(int.parse(stat));
              } catch (e) {}
            }
            if (intStats.length == 6) {
              arrays.add(intStats);
            }
          }
          Navigator.pop(context);
        });

    final description = Text(
      'Combines the fun randomness of rolling for stats with the fairness of arrays!\n\n',
      style: TextStyle(fontSize: 16),
    );

    final textBox = Container(
        width: 250 + screenWidth / 5,
        child: TextField(
          decoration: InputDecoration(
              contentPadding:
                  EdgeInsets.symmetric(vertical: 20, horizontal: 15),
              border: OutlineInputBorder()),
          keyboardType: TextInputType.multiline,
          maxLines: null,
          controller: _controller,
        ));

    return Theme(
      data: dndTheme,
      child: Scaffold(
        appBar: AppBar(title: Text('Random Arrays'), actions: [
          Container(margin: EdgeInsets.only(right: 10), child: saveIcon)
        ]),
        body: SingleChildScrollView(
          child: Container(
            margin: EdgeInsets.all(30),
            alignment: Alignment.topCenter,
            child: Column(
              children: [
                description,
                textBox,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StatScreen extends StatefulWidget {
  @override
  _StatScreenState createState() => _StatScreenState();
}

class _StatScreenState extends State<StatScreen> {
  @override
  Widget build(BuildContext context) {
    statColumns(width) => [
          DataColumn(label: Text('Stat')),
          DataColumn(label: Text(' ')),
          DataColumn(
              label: Container(
                  padding: EdgeInsets.only(left: 20), child: Text('Bonus'))),
          DataColumn(
              label: Container(
            padding: EdgeInsets.only(left: width),
            child: Text('Final'),
          ))
        ];

    statRows(width) {
      List<DataRow> rows = [];
      final statNames = <String>['Str', 'Dex', 'Con', 'Int', 'Wis', 'Cha'];
      for (var i = 0; i < 6; i++) {
        rows.add(DataRow(cells: [
          DataCell(Text(
            statNames[i],
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          )),
          DataCell(Text(stats[i].toString())),
          DataCell(ArrowIncrement(
            value: bonuses[i],
            update: (bonus) => setState(() => bonuses[i] = bonus),
          )),
          DataCell(Row(children: [
            Container(width: width),
            Container(
              width: 25,
              alignment: Alignment.center,
              child: Text((stats[i] + bonuses[i]).toString()),
            ),
            Container(
                width: 50,
                alignment: Alignment.center,
                child: Text(
                  () {
                    var mod = ((stats[i] + bonuses[i]) / 2 - 5).floor();
                    if (mod > 0) {
                      return '+$mod';
                    } else {
                      return mod.toString();
                    }
                  }(),
                  style: TextStyle(fontSize: 20),
                )),
          ])),
        ]));
      }
      return rows;
    }

    var screenWidth = MediaQuery.of(context).size.width;
    var tableWidth = screenWidth;
    return Theme(
      data: dndTheme,
      child: Scaffold(
        appBar: AppBar(title: Text('Stats')),
        body: ConstrainedBox(
          constraints: BoxConstraints.expand(),
          child: Container(
            margin: EdgeInsets.symmetric(
              horizontal: (() {
                if (screenWidth < 600) {
                  return 0.0;
                } else {
                  var margin = (screenWidth - 600) / 3;
                  tableWidth = screenWidth - margin * 2;
                  return margin;
                }
              })(),
              vertical: 15,
            ),
            child: DataTable(
              headingRowHeight: 50,
              headingTextStyle: TextStyle(
                fontSize: 18,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
              columnSpacing: 20,
              dataRowHeight: 75,
              columns: statColumns(tableWidth - 294),
              rows: statRows(tableWidth - 310),
            ),
          ),
        ),
      ),
    );
  }
}

class ArrowIncrement extends StatelessWidget {
  final ValueChanged<int> update;
  final int value;

  ArrowIncrement({required this.value, required this.update});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          splashRadius: 20,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          tooltip: 'decrease bonus by 1',
          onPressed: () => update(value - 1),
        ),
      ),
      Container(width: 90, child: Center(child: Text(value.toString()))),
      Align(
        alignment: Alignment.centerRight,
        child: IconButton(
          splashRadius: 20,
          icon: const Icon(Icons.keyboard_arrow_up_rounded),
          tooltip: 'increase bonus by 1',
          onPressed: () => update(value + 1),
        ),
      ),
    ]);
  }
}
