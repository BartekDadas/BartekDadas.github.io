import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: DocWidget(),
    );
  }
}


class DocWidget extends StatelessWidget {
  const DocWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Dock(
            items: const [
              Icons.person,
              Icons.message,
              Icons.call,
              Icons.camera,
              Icons.photo,
            ],
            builder: (e) {
              return Container(
                constraints: const BoxConstraints(minWidth: 48),
                height: 48,
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.primaries[e.hashCode % Colors.primaries.length],
                ),
                child: Center(child: Icon(e, color: Colors.white)),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Dock of the reorderable [items].
class Dock<T extends Object> extends StatefulWidget {
  const Dock({
    super.key,
    this.items = const [],
    required this.builder,
  });


  final List<T> items;

  
  final Widget Function(T) builder;

  @override
  State<Dock<T>> createState() => _DockState<T>();
}

class _DockState<T extends Object> extends State<Dock<T>>
    with TickerProviderStateMixin {

  late List<T> _items = widget.items.toList();


  int? _draggedIndex;

  
  Offset? _dragOffset;

  
  int? _targetIndex;

  late Animation<double> _scaleAnimation;

  late AnimationController _scaleController;

  late AnimationController _scaleBackController;

  late Animation<double> _scaleBackAnimation;

  @override
  void initState() {
    _scaleController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 200));
    _scaleAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
    _scaleBackController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 200));
    _scaleBackAnimation = Tween<double>(
      begin: 0.0,
      end: 50.0,
    ).animate(
      CurvedAnimation(parent: _scaleBackController, curve: Curves.easeOut),
    );
    super.initState();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _scaleBackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.black12,
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              double scale = 1.0;
              if (_draggedIndex != null &&
                  _targetIndex == index &&
                  _draggedIndex != index) {
                scale = 1.2; 
              }

              return Row(
                children: [
                  if (_targetIndex == index && _targetIndex != _items.length - 1)
                    AnimatedContainer(
                        duration: Duration(milliseconds: 500),
                        width: _scaleBackAnimation.value,
                        height: 30,
                        margin: EdgeInsets.symmetric(horizontal: 4)),
                  MouseRegion(
                    onEnter: (_) {
                      if (_draggedIndex != null) {
                        setState(() => _targetIndex = index);
                      }
                    },
                    child: Draggable<T>(
                      data: item,
                      feedback: Material(
                        color: Colors.transparent,
                        child: widget.builder(item),
                      ),
                      childWhenDragging: AnimatedContainer(
                        duration: Duration(milliseconds: 900),
                        width: _scaleAnimation.value,
                        height: 30,
                  ),
                      onDragStarted: () {
                        setState(() {
                          _draggedIndex = index;
                          _targetIndex = index;
                        });
                        _scaleController.forward();
                      },
                      onDragUpdate: (details) {
                        setState(() => _dragOffset = details.localPosition);
                        final RenderBox? box =
                            context.findRenderObject() as RenderBox?;
                        if (box != null) {
                          final Offset localPosition =
                              box.globalToLocal(details.globalPosition);
                          final double itemWidth =
                              box.size.width / _items.length;
                          int closestIndex =
                              (localPosition.dx / itemWidth).floor();
                          closestIndex =
                              closestIndex.clamp(0, _items.length - 1);

                          if (_targetIndex != closestIndex) {
                            setState(() => _targetIndex = closestIndex);
                            _scaleBackController.forward();
                          }
                        }
                      },
                      onDragEnd: (details) {
                        if (_draggedIndex != null &&
                            _targetIndex != null &&
                            _draggedIndex != _targetIndex) {
                          setState(() {
                            final item = _items.removeAt(_draggedIndex!);
                            _items.insert(_targetIndex!, item);
                          });
                        }
                        setState(() {
                          _draggedIndex = null;
                          _dragOffset = null;
                          _targetIndex = null;
                        });
                        _scaleController.reset();
                        _scaleBackController.reset();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.easeOutQuart,
                        transform: Matrix4.identity()..scale(scale),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: widget.builder(item),
                        ),
                      ),
                    ),
                  ),
                  if (_targetIndex == index && _targetIndex == _items.length - 1)
                    AnimatedContainer(
                        duration: Duration(milliseconds: 800),
                        width: _scaleAnimation.value,
                        height: 30,
                        margin: EdgeInsets.symmetric(horizontal: 4)),
                ],
              );
            }).toList(),
          ),
        ),
        if (_dragOffset != null && _draggedIndex != null)
          Positioned(
            left: _dragOffset!.dx - 25, // Adjust based on item size
            top: _dragOffset!.dy - 25,
            child: Opacity(
              opacity: 0.7,
              child: widget.builder(_items[_draggedIndex!]),
            ),
          ),
      ],
    );
  }
}
