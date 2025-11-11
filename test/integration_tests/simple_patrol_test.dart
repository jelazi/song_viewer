import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

/// Simple Patrol test without BLoC dependencies
/// Demonstrates basic Patrol framework usage
void main() {
  patrolTest(
    'Simple test - Counter app',
    ($) async {
      // Create basic Counter app
      await $.pumpWidgetAndSettle(
        const MaterialApp(
          home: SimpleCounterWidget(),
        ),
      );

      // Verify counter starts at 0
      expect($('0'), findsOneWidget);
      expect($('1'), findsNothing);

      // Find "+" button and tap it
      await $(Icons.add).tap();
      await $.pumpAndSettle();

      // Verify counter increased to 1
      expect($('0'), findsNothing);
      expect($('1'), findsOneWidget);

      // Tap 2 more times
      await $(Icons.add).tap();
      await $.pumpAndSettle();
      await $(Icons.add).tap();
      await $.pumpAndSettle();

      // Verify counter is 3
      expect($('3'), findsOneWidget);
    },
  );

  patrolTest(
    'TextField interaction test',
    ($) async {
      await $.pumpWidgetAndSettle(
        const MaterialApp(
          home: SimpleTextFieldWidget(),
        ),
      );

      // Find TextField and enter text
      final textField = $(TextField);
      expect(textField, findsOneWidget);

      await textField.enterText('Hello Patrol!');
      await $.pumpAndSettle();

      // Verify text is displayed
      expect($('Hello Patrol!'), findsOneWidget);

      // Tap clear button
      await $('Clear').tap();
      await $.pumpAndSettle();

      // TextField should be empty
      expect($('Hello Patrol!'), findsNothing);
    },
  );

  patrolTest(
    'ListView scrolling test',
    ($) async {
      await $.pumpWidgetAndSettle(
        const MaterialApp(
          home: SimpleListWidget(),
        ),
      );

      // Verify first item is visible
      expect($('Item 0'), findsOneWidget);

      // Last item is not visible (off screen)
      expect($('Item 99'), findsNothing);

      // Scroll down to last item
      await $(ListTile).at(99).scrollTo();

      // Now it should be visible
      expect($('Item 99'), findsOneWidget);

      // And first item is no longer visible
      expect($('Item 0'), findsNothing);
    },
  );

  patrolTest(
    'Page navigation test',
    ($) async {
      await $.pumpWidgetAndSettle(
        const MaterialApp(
          home: FirstPage(),
        ),
      );

      // We're on first page
      expect($('First Page'), findsOneWidget);
      expect($('Second Page'), findsNothing);

      // Tap button to go to second page
      await $('Go to Second Page').tap();
      await $.pumpAndSettle();

      // Now we're on second page
      expect($('First Page'), findsNothing);
      expect($('Second Page'), findsOneWidget);

      // Go back
      await $.native.pressBack();
      await $.pumpAndSettle();

      // We're back on first page
      expect($('First Page'), findsOneWidget);
      expect($('Second Page'), findsNothing);
    },
  );
}

/// Simple Counter widget for demonstration
class SimpleCounterWidget extends StatefulWidget {
  const SimpleCounterWidget({super.key});

  @override
  State<SimpleCounterWidget> createState() => _SimpleCounterWidgetState();
}

class _SimpleCounterWidgetState extends State<SimpleCounterWidget> {
  int counter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Counter Test')),
      body: Center(
        child: Text(
          '$counter',
          style: const TextStyle(fontSize: 48),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => counter++),
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Simple TextField widget
class SimpleTextFieldWidget extends StatefulWidget {
  const SimpleTextFieldWidget({super.key});

  @override
  State<SimpleTextFieldWidget> createState() => _SimpleTextFieldWidgetState();
}

class _SimpleTextFieldWidgetState extends State<SimpleTextFieldWidget> {
  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TextField Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Enter text'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => controller.clear(),
              child: const Text('Clear'),
            ),
            const SizedBox(height: 16),
            Text(controller.text),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

/// Simple ListView widget
class SimpleListWidget extends StatelessWidget {
  const SimpleListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('List Test')),
      body: ListView.builder(
        itemCount: 100,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('Item $index'),
          );
        },
      ),
    );
  }
}

/// First page for navigation test
class FirstPage extends StatelessWidget {
  const FirstPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('First Page')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SecondPage()),
            );
          },
          child: const Text('Go to Second Page'),
        ),
      ),
    );
  }
}

/// Second page for navigation test
class SecondPage extends StatelessWidget {
  const SecondPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Second Page')),
      body: const Center(
        child: Text('Second Page'),
      ),
    );
  }
}
