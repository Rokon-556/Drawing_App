import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_painter/flutter_painter.dart';
import 'package:image_picker/image_picker.dart';

import 'dart:ui' as ui;

import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/services.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Drawing App",
      theme: ThemeData(
          primaryColor: Colors.brown,
          colorScheme:
              ColorScheme.fromSwatch().copyWith(secondary: Colors.redAccent)),
      home: const FlutterPainterExample(),
    );
  }
}

class FlutterPainterExample extends StatefulWidget {
  const FlutterPainterExample({Key? key}) : super(key: key);

  @override
  _FlutterPainterExampleState createState() => _FlutterPainterExampleState();
}

class _FlutterPainterExampleState extends State<FlutterPainterExample> {
  static const Color red = Color(0xFFFF0000);
  FocusNode textFocusNode = FocusNode();
  late PainterController controller;
  ui.Image? backgroundImage;
  Paint shapePaint = Paint()
    ..strokeWidth = 5
    ..color = Colors.red
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  File? image;
  final ImagePicker _picker = ImagePicker();
  getImageFromGallery() async {
    XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
    );

    if (pickedFile != null) {
      image = File(pickedFile.path);
      initBackground();
    }
  }

  @override
  void initState() {
    super.initState();
    screenController();
  }

  void screenController() {
    controller = PainterController(
        settings: PainterSettings(
            text: TextSettings(
              focusNode: textFocusNode,
              textStyle: const TextStyle(
                  fontWeight: FontWeight.bold, color: red, fontSize: 18),
            ),
            freeStyle: const FreeStyleSettings(
              color: red,
              strokeWidth: 5,
            ),
            shape: ShapeSettings(
              paint: shapePaint,
            ),
            scale: const ScaleSettings(
              enabled: true,
              minScale: 1,
              maxScale: 5,
            )));

    textFocusNode.addListener(onFocus);
  }

  void initBackground() async {
    // Extension getter (.image) to get [ui.Image] from [ImageProvider]
    final image =
        await const NetworkImage('https://picsum.photos/1920/1080/').image;

    setState(() {
      backgroundImage = image;
      controller.background = image.backgroundDrawable;
    });
  }

  Future<ui.Image> getUiImage(String imageAssetPath) async {
    final ByteData assetImageByteData = await rootBundle.load(imageAssetPath);
    final codec = await ui.instantiateImageCodec(
      assetImageByteData.buffer.asUint8List(),
      // targetHeight: height,
      // targetWidth: width,
    );
    final image = (await codec.getNextFrame());
    return image.image;
  }

  /// Updates UI when the focus changes
  void onFocus() {
    setState(() {});
  }

  Widget buildDefault(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size(double.infinity, kToolbarHeight),
        // Listen to the controller and update the UI when it updates.
        child: ValueListenableBuilder<PainterControllerValue>(
            valueListenable: controller,
            child: const Text("Flutter Painter Example"),
            builder: (context, _, child) {
              return AppBar(
                title: child,
                backgroundColor: Theme.of(context).primaryColor,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.image),
                    onPressed: () {
                      initBackground();
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      PhosphorIcons.arrowClockwise,
                    ),
                    onPressed: controller.canRedo ? redo : null,
                  ),
                  // Undo action
                  IconButton(
                    icon: const Icon(
                      PhosphorIcons.arrowCounterClockwise,
                    ),
                    onPressed: controller.canUndo ? undo : null,
                  ),
                ],
              );
            }),
      ),
      // Generate image
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          screenController();
          setState(() {});
        },
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Center(
              child: Container(
                height: 500,
                width: MediaQuery.of(context).size.width,
                child: FlutterPainter(
                  controller: controller,
                ),
              ),
            ),
          ),
          // Enforces constraints

          Positioned(
            bottom: 0,
            right: 0,
            left: 0,
            child: ValueListenableBuilder(
              valueListenable: controller,
              builder: (context, _, __) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Container(
                      constraints: const BoxConstraints(
                        maxWidth: 400,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: const BoxDecoration(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                        color: Colors.white54,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (controller.freeStyleMode !=
                              FreeStyleMode.none) ...[
                            const Divider(),
                            const Text("Free Style Settings"),
                            // Control free style stroke width
                            Row(
                              children: [
                                const Expanded(
                                    flex: 1, child: Text("Stroke Width")),
                                Expanded(
                                  flex: 3,
                                  child: Slider.adaptive(
                                      min: 2,
                                      max: 25,
                                      value: controller.freeStyleStrokeWidth,
                                      onChanged: setFreeStyleStrokeWidth),
                                ),
                              ],
                            ),
                            if (controller.freeStyleMode == FreeStyleMode.draw)
                              Row(
                                children: [
                                  const Expanded(flex: 1, child: Text("Color")),
                                  // Control free style color hue
                                  Expanded(
                                    flex: 3,
                                    child: Slider.adaptive(
                                        min: 0,
                                        max: 359.99,
                                        value: HSVColor.fromColor(
                                                controller.freeStyleColor)
                                            .hue,
                                        activeColor: controller.freeStyleColor,
                                        onChanged: setFreeStyleColor),
                                  ),
                                ],
                              ),
                          ],
                          if (textFocusNode.hasFocus) ...[
                            const Divider(),
                            const Text("Text settings"),
                            // Control text font size
                            Row(
                              children: [
                                const Expanded(
                                    flex: 1, child: Text("Font Size")),
                                Expanded(
                                  flex: 3,
                                  child: Slider.adaptive(
                                      min: 8,
                                      max: 96,
                                      value:
                                          controller.textStyle.fontSize ?? 14,
                                      onChanged: setTextFontSize),
                                ),
                              ],
                            ),

                            // Control text color hue
                            Row(
                              children: [
                                const Expanded(flex: 1, child: Text("Color")),
                                Expanded(
                                  flex: 3,
                                  child: Slider.adaptive(
                                      min: 0,
                                      max: 359.99,
                                      value: HSVColor.fromColor(
                                              controller.textStyle.color ?? red)
                                          .hue,
                                      activeColor: controller.textStyle.color,
                                      onChanged: setTextColor),
                                ),
                              ],
                            ),
                          ],
                          if (controller.shapeFactory != null) ...[
                            const Divider(),
                            const Text("Shape Settings"),

                            // Control text color hue
                            Row(
                              children: [
                                const Expanded(
                                    flex: 1, child: Text("Stroke Width")),
                                Expanded(
                                  flex: 3,
                                  child: Slider.adaptive(
                                      min: 2,
                                      max: 25,
                                      value:
                                          controller.shapePaint?.strokeWidth ??
                                              shapePaint.strokeWidth,
                                      onChanged: (value) =>
                                          setShapeFactoryPaint(
                                              (controller.shapePaint ??
                                                      shapePaint)
                                                  .copyWith(
                                            strokeWidth: value,
                                          ))),
                                ),
                              ],
                            ),

                            // Control shape color hue
                            Row(
                              children: [
                                const Expanded(flex: 1, child: Text("Color")),
                                Expanded(
                                  flex: 3,
                                  child: Slider.adaptive(
                                      min: 0,
                                      max: 359.99,
                                      value: HSVColor.fromColor(
                                              (controller.shapePaint ??
                                                      shapePaint)
                                                  .color)
                                          .hue,
                                      activeColor:
                                          (controller.shapePaint ?? shapePaint)
                                              .color,
                                      onChanged: (hue) => setShapeFactoryPaint(
                                              (controller.shapePaint ??
                                                      shapePaint)
                                                  .copyWith(
                                            color:
                                                HSVColor.fromAHSV(1, hue, 1, 1)
                                                    .toColor(),
                                          ))),
                                ),
                              ],
                            ),

                            Row(
                              children: [
                                const Expanded(
                                    flex: 1, child: Text("Fill shape")),
                                Expanded(
                                  flex: 3,
                                  child: Center(
                                    child: Switch(
                                        value: (controller.shapePaint ??
                                                    shapePaint)
                                                .style ==
                                            PaintingStyle.fill,
                                        onChanged: (value) =>
                                            setShapeFactoryPaint(
                                                (controller.shapePaint ??
                                                        shapePaint)
                                                    .copyWith(
                                              style: value
                                                  ? PaintingStyle.fill
                                                  : PaintingStyle.stroke,
                                            ))),
                                  ),
                                ),
                              ],
                            ),
                          ]
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: ValueListenableBuilder(
        valueListenable: controller,
        builder: (context, _, __) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Free-style eraser
            IconButton(
              icon: Icon(
                PhosphorIcons.eraser,
                color: controller.freeStyleMode == FreeStyleMode.erase
                    ? Theme.of(context).colorScheme.secondary
                    : null,
              ),
              onPressed: toggleFreeStyleErase,
            ),
            // Free-style drawing
            IconButton(
              icon: Icon(
                PhosphorIcons.scribbleLoop,
                color: controller.freeStyleMode == FreeStyleMode.draw
                    ? Theme.of(context).colorScheme.secondary
                    : null,
              ),
              onPressed: toggleFreeStyleDraw,
            ),
            // Add text
            IconButton(
              icon: Icon(
                PhosphorIcons.textT,
                color: textFocusNode.hasFocus
                    ? Theme.of(context).colorScheme.secondary
                    : null,
              ),
              onPressed: addText,
            ),
            // Add shapes
            if (controller.shapeFactory == null)
              PopupMenuButton<ShapeFactory?>(
                tooltip: "Add shape",
                itemBuilder: (context) => <ShapeFactory, String>{
                  LineFactory(): "Line",
                  ArrowFactory(): "Arrow",
                  DoubleArrowFactory(): "Double Arrow",
                  RectangleFactory(): "Rectangle",
                  OvalFactory(): "Oval",
                }
                    .entries
                    .map((e) => PopupMenuItem(
                        value: e.key,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Icon(
                              getShapeIcon(e.key),
                              color: Colors.black,
                            ),
                            Text(" ${e.value}")
                          ],
                        )))
                    .toList(),
                onSelected: selectShape,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    getShapeIcon(controller.shapeFactory),
                    color: controller.shapeFactory != null
                        ? Theme.of(context).colorScheme.secondary
                        : null,
                  ),
                ),
              )
            else
              IconButton(
                icon: Icon(
                  getShapeIcon(controller.shapeFactory),
                  color: Theme.of(context).colorScheme.secondary,
                ),
                onPressed: () => selectShape(null),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return buildDefault(context);
  }

  static IconData getShapeIcon(ShapeFactory? shapeFactory) {
    if (shapeFactory is LineFactory) return PhosphorIcons.lineSegment;
    if (shapeFactory is ArrowFactory) return PhosphorIcons.arrowUpRight;
    if (shapeFactory is DoubleArrowFactory) {
      return PhosphorIcons.arrowsHorizontal;
    }
    if (shapeFactory is RectangleFactory) return PhosphorIcons.rectangle;
    if (shapeFactory is OvalFactory) return PhosphorIcons.circle;
    return PhosphorIcons.polygon;
  }

  void undo() {
    controller.undo();
  }

  void redo() {
    controller.redo();
  }

  void toggleFreeStyleDraw() {
    controller.freeStyleMode = controller.freeStyleMode != FreeStyleMode.draw
        ? FreeStyleMode.draw
        : FreeStyleMode.none;
  }

  void toggleFreeStyleErase() {
    controller.freeStyleMode = controller.freeStyleMode != FreeStyleMode.erase
        ? FreeStyleMode.erase
        : FreeStyleMode.none;
  }

  void addText() {
    if (controller.freeStyleMode != FreeStyleMode.none) {
      controller.freeStyleMode = FreeStyleMode.none;
    }
    controller.addText();
  }

  void setFreeStyleStrokeWidth(double value) {
    controller.freeStyleStrokeWidth = value;
  }

  void setFreeStyleColor(double hue) {
    controller.freeStyleColor = HSVColor.fromAHSV(1, hue, 1, 1).toColor();
  }

  void setTextFontSize(double size) {
    // Set state is just to update the current UI, the [FlutterPainter] UI updates without it
    setState(() {
      controller.textSettings = controller.textSettings.copyWith(
          textStyle:
              controller.textSettings.textStyle.copyWith(fontSize: size));
    });
  }

  void setShapeFactoryPaint(Paint paint) {
    // Set state is just to update the current UI, the [FlutterPainter] UI updates without it
    setState(() {
      controller.shapePaint = paint;
    });
  }

  void setTextColor(double hue) {
    controller.textStyle = controller.textStyle
        .copyWith(color: HSVColor.fromAHSV(1, hue, 1, 1).toColor());
  }

  void selectShape(ShapeFactory? factory) {
    controller.shapeFactory = factory;
  }

  void removeSelectedDrawable() {
    final selectedDrawable = controller.selectedObjectDrawable;
    if (selectedDrawable != null) controller.removeDrawable(selectedDrawable);
  }

  void flipSelectedImageDrawable() {
    final imageDrawable = controller.selectedObjectDrawable;
    if (imageDrawable is! ImageDrawable) return;

    controller.replaceDrawable(
        imageDrawable, imageDrawable.copyWith(flipped: !imageDrawable.flipped));
  }
}
