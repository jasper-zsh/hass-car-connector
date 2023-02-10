import 'package:flutter/material.dart';
import 'package:hass_car_connector/background.dart';
import 'package:hass_car_connector/service_locator.dart';
import 'package:hass_car_connector/ui/form/mqtt_remote.dart';
import 'package:hass_car_connector/ui/remote_config_form.dart';
import 'package:hass_car_connector/ui/remote_config_list.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator();
  await initializeService();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HASS Car',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int currentTab = 0;
  var _controller = PageController(initialPage: 0);

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: 2,
        itemBuilder: (context, index) {
          switch (index) {
            case 0:
              return RemoteConfigListPage();
              break;
            case 1:
              return Center(
                child: Text('TODO'),
              );
              break;
          }
        },
        onPageChanged: (page) {
          setState(() {
            currentTab = page;
          });
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentTab,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_remote),
            label: 'Remotes'
          ),
          BottomNavigationBarItem(icon: Icon(Icons.sensors), label: 'Sensors')
        ],
        onTap: (index) {
          setState(() {
            _controller.animateToPage(index, duration: Duration(microseconds: 300), curve: Curves.easeIn);
          });
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          switch (currentTab) {
            case 0:
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return RemoteConfigForm();
              }));
          }
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
