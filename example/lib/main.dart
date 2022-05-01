import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bluetooth_print/bluetooth_print.dart';
import 'package:bluetooth_print/bluetooth_print_model.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  BluetoothPrint bluetoothPrint = BluetoothPrint.instance;

  bool _connected = false;
  BluetoothDevice _device;
  String tips = 'no device connect';
  List<BlePrintItems> l = [
    BlePrintItems(
      itemName: 'Dosa and idli and all other stuff',
      qty: '5003457',
      price: '23545.6074',
      total: '456457.36545',
    ),
    BlePrintItems(
      itemName: 'Butter chicken',
      qty: '7',
      price: '12.2',
      total: '77545',
    ),
    BlePrintItems(
      itemName: 'Dosa nad idli',
      qty: '75',
      price: '754',
      total: '87876',
    ),
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) => initBluetooth());
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initBluetooth() async {
    bluetoothPrint.startScan(timeout: Duration(seconds: 4));

    bool isConnected = await bluetoothPrint.isConnected;

    bluetoothPrint.state.listen((state) {
      print('cur device status: $state');

      switch (state) {
        case BluetoothPrint.CONNECTED:
          setState(() {
            _connected = true;
            tips = 'connect success';
          });
          break;
        case BluetoothPrint.DISCONNECTED:
          setState(() {
            _connected = false;
            tips = 'disconnect success';
          });
          break;
        default:
          break;
      }
    });

    if (!mounted) return;

    if (isConnected) {
      setState(() {
        _connected = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('BluetoothPrint example app'),
        ),
        body: RefreshIndicator(
          onRefresh: () =>
              bluetoothPrint.startScan(timeout: Duration(seconds: 4)),
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                      child: Text(tips),
                    ),
                  ],
                ),
                Divider(),
                StreamBuilder<List<BluetoothDevice>>(
                  stream: bluetoothPrint.scanResults,
                  initialData: [],
                  builder: (c, snapshot) => Column(
                    children: snapshot.data
                        .map((d) => ListTile(
                              title: Text(d.name ?? ''),
                              subtitle: Text(d.address),
                              onTap: () async {
                                setState(() {
                                  _device = d;
                                });
                              },
                              trailing: _device != null &&
                                      _device.address == d.address
                                  ? Icon(
                                      Icons.check,
                                      color: Colors.green,
                                    )
                                  : null,
                            ))
                        .toList(),
                  ),
                ),
                Divider(),
                Container(
                  padding: EdgeInsets.fromLTRB(20, 5, 20, 10),
                  child: Column(
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          OutlinedButton(
                            child: Text('connect'),
                            onPressed: _connected
                                ? null
                                : () async {
                                    if (_device != null &&
                                        _device.address != null) {
                                      await bluetoothPrint.connect(_device);
                                    } else {
                                      setState(() {
                                        tips = 'please select device';
                                      });
                                      print('please select device');
                                    }
                                  },
                          ),
                          SizedBox(width: 10.0),
                          OutlinedButton(
                            child: Text('disconnect'),
                            onPressed: _connected
                                ? () async {
                                    await bluetoothPrint.disconnect();
                                  }
                                : null,
                          ),
                        ],
                      ),
                      OutlinedButton(
                        child: Text('print receipt(esc)'),
                        onPressed: _connected
                            ? () async {
                                Map<String, dynamic> config = Map();
                                List<LineText> list = [];
                                list.add(
                                  LineText(
                                    type: LineText.TYPE_TEXT,
                                    content: 'Order id: 1BCd1e',
                                    align: LineText.ALIGN_CENTER,
                                    linefeed: 1,
                                  ),
                                );
                                list.add(
                                  LineText(
                                      type: LineText.TYPE_TEXT,
                                      content: 'Dt: 30/04/2022 3:51PM IST',
                                      align: LineText.ALIGN_CENTER,
                                      linefeed: 1),
                                );
                                list.add(
                                  LineText(
                                    type: LineText.TYPE_TEXT,
                                    content: '--------------------------------',
                                    align: LineText.ALIGN_LEFT,
                                    linefeed: 2,
                                  ),
                                );
                                // l = 12
                                list.add(
                                  LineText(
                                    type: LineText.TYPE_TEXT,
                                    content: 'Items       ',
                                  ),
                                );
                                // l = 6
                                list.add(
                                  LineText(
                                    type: LineText.TYPE_TEXT,
                                    content: 'Qty   ',
                                  ),
                                );
                                // l = 7
                                list.add(
                                  LineText(
                                    type: LineText.TYPE_TEXT,
                                    content: 'Price  ',
                                  ),
                                );
                                // l = 7
                                list.add(
                                  LineText(
                                    type: LineText.TYPE_TEXT,
                                    content: 'Total  ',
                                    linefeed: 1,
                                  ),
                                );
                                list.add(
                                  LineText(
                                    type: LineText.TYPE_TEXT,
                                    content: '--------------------------------',
                                    align: LineText.ALIGN_LEFT,
                                    linefeed: 2,
                                  ),
                                );
                                for (var i in l) {
                                  addPrintItemToList(i, list);
                                  list.add(
                                    LineText(
                                      type: LineText.TYPE_TEXT,
                                      content:
                                          '--------------------------------',
                                      align: LineText.ALIGN_CENTER,
                                      linefeed: 1,
                                    ),
                                  );
                                }
                                bluetoothPrint.printReceipt(config, list);

                                // list.add(LineText(type: LineText.TYPE_TEXT, content: 'A Title', weight: 1, align: LineText.ALIGN_CENTER,linefeed: 1));
                                // list.add(LineText(type: LineText.TYPE_TEXT, content: 'this is conent left', weight: 0, align: LineText.ALIGN_LEFT,linefeed: 1));
                                // list.add(LineText(type: LineText.TYPE_TEXT, content: 'this is conent right', align: LineText.ALIGN_RIGHT,linefeed: 1));
                                // list.add(LineText(linefeed: 1));

                                // ByteData data = await rootBundle.load("assets/images/bluetooth_print.png");
                              }
                            : null,
                      ),
                      OutlinedButton(
                        child: Text('print label(tsc)'),
                        onPressed: _connected
                            ? () async {
                                Map<String, dynamic> config = Map();
                                config['width'] = 40; // 标签宽度，单位mm
                                config['height'] = 70; // 标签高度，单位mm
                                config['gap'] = 2; // 标签间隔，单位mm

                                // x、y坐标位置，单位dpi，1mm=8dpi
                                List<LineText> list = [];
                                list.add(LineText(
                                    type: LineText.TYPE_TEXT,
                                    x: 10,
                                    y: 10,
                                    content: 'A Title'));
                                list.add(LineText(
                                    type: LineText.TYPE_TEXT,
                                    x: 10,
                                    y: 40,
                                    content: 'this is content'));
                                list.add(LineText(
                                    type: LineText.TYPE_QRCODE,
                                    x: 10,
                                    y: 70,
                                    content: 'qrcode i\n'));
                                list.add(LineText(
                                    type: LineText.TYPE_BARCODE,
                                    x: 10,
                                    y: 190,
                                    content: 'qrcode i\n'));

                                List<LineText> list1 = [];
                                ByteData data = await rootBundle
                                    .load("assets/images/guide3.png");
                                List<int> imageBytes = data.buffer.asUint8List(
                                    data.offsetInBytes, data.lengthInBytes);
                                String base64Image = base64Encode(imageBytes);
                                list1.add(LineText(
                                  type: LineText.TYPE_IMAGE,
                                  x: 10,
                                  y: 10,
                                  content: base64Image,
                                ));

                                await bluetoothPrint.printLabel(config, list);
                                await bluetoothPrint.printLabel(config, list1);
                              }
                            : null,
                      ),
                      OutlinedButton(
                        child: Text('print selftest'),
                        onPressed: _connected
                            ? () async {
                                await bluetoothPrint.printTest();
                              }
                            : null,
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
        floatingActionButton: StreamBuilder<bool>(
          stream: bluetoothPrint.isScanning,
          initialData: false,
          builder: (c, snapshot) {
            if (snapshot.data) {
              return FloatingActionButton(
                child: Icon(Icons.stop),
                onPressed: () => bluetoothPrint.stopScan(),
                backgroundColor: Colors.red,
              );
            } else {
              return FloatingActionButton(
                  child: Icon(Icons.search),
                  onPressed: () =>
                      bluetoothPrint.startScan(timeout: Duration(seconds: 4)));
            }
          },
        ),
      ),
    );
  }
}

class BlePrintItems {
  final String itemName;
  final String qty;
  final String price;
  final String total;
  BlePrintItems({
    @required this.itemName,
    @required this.qty,
    @required this.price,
    @required this.total,
  });
}

class BlePrintConfig {
  static const ITEM_WIDTH = 12;
  static const QTY_WIDTH = 6;
  static const PRICE_WIDTH = 7;
  static const TOTAL_WIDTH = 7;
}

void addPrintItemToList(BlePrintItems item, List<LineText> list) {
  var startIndexed = [0, 0, 0, 0];
  while (true) {
    if (startIndexed[0] == item.itemName.length &&
        startIndexed[1] == item.qty.length &&
        startIndexed[2] == item.price.length &&
        startIndexed[3] == item.total.length) break;
    final int endIndex1 = min<int>(
        startIndexed[0] + BlePrintConfig.ITEM_WIDTH - 1, item.itemName.length);
    final itemName = item.itemName.substring(startIndexed[0], endIndex1);
    startIndexed[0] = endIndex1;
    list.add(
      LineText(
        content: itemName +
            ' ' +
            ' ' * (BlePrintConfig.ITEM_WIDTH - itemName.length - 1),
        type: LineText.TYPE_TEXT,
      ),
    );
    final endIndex2 =
        min(startIndexed[1] + BlePrintConfig.QTY_WIDTH - 1, item.qty.length);
    final qty = item.qty.substring(startIndexed[1], endIndex2);
    startIndexed[1] = endIndex2;
    list.add(
      LineText(
        content: qty + ' ' + ' ' * (BlePrintConfig.QTY_WIDTH - qty.length - 1),
        type: LineText.TYPE_TEXT,
      ),
    );
    // print(qty + ' ' + ' ' * (BlePrintConfig.QTY_WIDTH - qty.length-1));

    final endIndex3 = min(
        startIndexed[2] + BlePrintConfig.PRICE_WIDTH - 1, item.price.length);
    final price = item.price.substring(startIndexed[2], endIndex3);
    startIndexed[2] = endIndex3;
    list.add(
      LineText(
        content:
            price + ' ' + ' ' * (BlePrintConfig.PRICE_WIDTH - price.length - 1),
        type: LineText.TYPE_TEXT,
      ),
    );
    final endIndex4 = min(
        startIndexed[3] + BlePrintConfig.TOTAL_WIDTH - 1, item.total.length);
    final total = item.total.substring(startIndexed[3], endIndex4);
    startIndexed[3] = endIndex4;
    list.add(
      LineText(
        content:
            total + ' ' + ' ' * (BlePrintConfig.TOTAL_WIDTH - total.length - 1),
        type: LineText.TYPE_TEXT,
      ),
    );
  }
}
