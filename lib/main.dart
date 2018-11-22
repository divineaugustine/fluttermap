import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart';
import 'package:http/http.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;

void main() {
  runApp(new MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Map<String, double> _startLocation;
  Map<String, double> _currentLocation;

  StreamSubscription<Map<String, double>> _locationSubscription;

  Location _location = new Location();
  bool _permission = false;
  String error;
  String locationDetails;
  double _distanceBetweenPOints = 0.0;

  bool currentWidget = true;

  Image image1;

  @override
  void initState() {
    super.initState();

    initPlatformState();

    _locationSubscription =
        _location.onLocationChanged().listen((Map<String,double> result) 
        {
          setState(() {
            _currentLocation = result;
          });
          
        });
  }
double _degreesToRadians(degrees) 
    {
        return degrees *3.14 / 180;
    }
double _distanceInKmBetweenEarthCoordinates(lat1, lon1, lat2, lon2) 
    {
        const int earthRadiusKm = 6371;

        var dLat    = _degreesToRadians(lat2-lat1);
        var dLon    = _degreesToRadians(lon2-lon1);

        lat1        = _degreesToRadians(lat1);
        lat2        = _degreesToRadians(lat2);

        var a       = sin(dLat/2) * sin(dLat/2) +
                      sin(dLon/2) * sin(dLon/2) * cos(lat1) * cos(lat2); 
        var c       = 2 * atan2(sqrt(a), sqrt(1-a)); 
        return earthRadiusKm * c;
    }

  // Platform messages are asynchronous, so we initialize in an async method.
  initPlatformState() async {
    Map<String, double> location;
    // Platform messages may fail, so we use a try/catch PlatformException.

    try {
      _permission = await _location.hasPermission();
      location = await _location.getLocation();


      error = null;
    } on PlatformException catch (e) {
      if (e.code == 'PERMISSION_DENIED') {
        error = 'Permission denied';
      } else if (e.code == 'PERMISSION_DENIED_NEVER_ASK') {
        error = 'Permission denied - please ask the user to enable it from the app settings';
      }

      location = null;
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    //if (!mounted) return;

    setState(() {
        if( null != _startLocation && null != location)
        {
          double lat1  =  _startLocation['latitude'].toDouble();
          double long1 =  _startLocation['longitude'].toDouble();

          double lat2  =  location['latitude'].toDouble();
          double long2 =  location['longitude'].toDouble();

          _distanceBetweenPOints = _distanceInKmBetweenEarthCoordinates(lat1,long1, lat2,long2);
        }
        _startLocation = location;
    });
    var details = await _getAddressOfCurrentCoOrdinates(_currentLocation);
    setState(() {
        locationDetails = details;
    });

  }
Future<String> _getAddressOfCurrentCoOrdinates(Map<String, double> _location) async
    {
        // https://nominatim.openstreetmap.org/reverse?format=json&lat=52.5487429714954&lon=-1.81602098644987&addressdetails=1
        // check if it is withing the radius of previous location
        // check if it is within the radius of any of the previous locations
        // If a new location, get the location details using api

        String respData = "";
        void onSuccess(data) async
        {
            respData = data;
        }

        void onError(msg)
        {
            print(msg);
        }

        String server = 'https://nominatim.openstreetmap.org';
        String api = '/reverse?format=json&lat=';
        api+= _location['latitude'].toString();
        api+= '&lon=';
        api+= _location['longitude'].toString();
        api+= '&addressdetails=1';

        await makeGenericGetRequest( server,api, onSuccess, onError );
        return respData;
    }
    void getError(HttpClientResponse response, errorCallBack) async {
  var msg = "Request Failed";
  try{
    String reply = await response.transform(utf8.decoder).join();
    if( reply != null && reply.isNotEmpty){
      var errorData = json.decode(reply);
      if( errorData["error_description"] != null ){
        msg = errorData["error_description"];
      }else if( errorData["Message"]!= null){
        msg = errorData["Message"];
      }
    }

  }catch(ex){}
  errorCallBack(msg);
}
    Future makeGenericGetRequest( host, api, /*data,*/ onSucessCallBack, onErrorCallBack)async {
      try {
        var url = host + api;
        HttpClient httpClient = new HttpClient();
        HttpClientRequest request = await httpClient.postUrl(Uri.parse(url));
        request.headers.set('content-type', 'application/json');
        // request.add(utf8.encode(json.encode(data)));
        HttpClientResponse response = await request.close();
        if (response.statusCode != 200) {
          getError(response, onErrorCallBack);
        } else {
          String reply = await response.transform(utf8.decoder).join();
          onSucessCallBack(reply);
        }
        httpClient.close();
      }catch(ex){
        onErrorCallBack( "Request failed");
      }
    }

  void queryLocation() async
  {
    initPlatformState();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets;


    if (_currentLocation == null) 
    {
      widgets = new List();
    } 
    else
     {
      widgets = [
        /*new Image.network(
            "https://maps.googleapis.com/maps/api/staticmap?center=${_currentLocation["latitude"]},${_currentLocation["longitude"]}&zoom=18&size=640x400&key=YOUR_API_KEY")
            */
            new Image.network("https://www.google.co.in/search?q=hump+road&safe=off&rlz=1C1GCEU_en-GBGB819GB819&tbm=isch&source=iu&ictx=1&fir=yveBtwjMSd4LUM%253A%252CgiPay9xXljQTiM%252C_&usg=AI4_-kTaJ5BIPnAYe7ZQitncdfmOnlck4g&sa=X&ved=2ahUKEwjU8rPN7eXeAhXLRo8KHdBbBzgQ9QEwAnoECAIQBA#")
      ];
    }

    widgets.add(new Center(
        child: new Text(_startLocation != null
            ? 'Start location: $_startLocation\n'
            : 'Error: $error\n')));

    widgets.add(new Center(
        child: new Text(_currentLocation != null
            ? 'Continuous location: $_currentLocation\n'
            : 'Error: $error\n')));

    widgets.add(new Center(
      child: new Text(_permission 
            ? 'Has permission : Yes' 
            : "Has permission : No")));


    widgets.add(new Center(
      child: new Text('Ditance in KM : '+ _distanceBetweenPOints.toString())));

    widgets.add(new Center(
      child: new Text( '$locationDetails')));

    widgets.add(new Center(
      child: new RaisedButton(
                    onPressed: queryLocation,
                    textColor: Colors.white,
                    color: Colors.red,
                    padding: const EdgeInsets.all(8.0),
                    child: new Text(
                      "Query",
                    ),
                  )));

    return new MaterialApp(
        home: new Scaffold(
            appBar: new AppBar(
              title: new Text('Location plugin example app'),
            ),
            body: new Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: widgets,
            )));
  }
}


/*import 'package:flutter/material.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or press Run > Flutter Hot Reload in IntelliJ). Notice that the
        // counter didn't reset back to zero; the application is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return new Scaffold(
      appBar: new AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: new Text(widget.title),
      ),
      body: new Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: new Column(
          // Column is also layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug paint" (press "p" in the console where you ran
          // "flutter run", or select "Toggle Debug Paint" from the Flutter tool
          // window in IntelliJ) to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            new Text(
              'You have pushed the button this many times:',
            ),
            new Text(
              '$_counter',
              style: Theme.of(context).textTheme.display1,
            ),
          ],
        ),
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: new Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
*/
