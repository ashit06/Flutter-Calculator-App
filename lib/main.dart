import 'package:flutter/material.dart';

void main() {
  runApp(CalculatorApp());
}

class CalculatorApp extends StatefulWidget {
  @override
  _CalculatorAppState createState() => _CalculatorAppState();
}

class _CalculatorAppState extends State<CalculatorApp> {
  bool _isDarkMode = false;

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  final ThemeData _lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.blueGrey,
    colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blueGrey)
        .copyWith(secondary: Colors.orangeAccent),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueGrey[300],
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );

  final ThemeData _darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.blueGrey,
    colorScheme: ColorScheme.dark(
      primary: Colors.blueGrey,
      secondary: Colors.orangeAccent,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueGrey[700],
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: CalculatorScreen(
        isDarkMode: _isDarkMode,
        onThemeToggle: _toggleTheme,
      ),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  CalculatorScreen({required this.isDarkMode, required this.onThemeToggle});

  @override
  _CalculatorScreenState createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _expression = "";
  List<String> _savedHistory = [];
  final ScrollController _scrollController = ScrollController();
  double _memory = 0.0; // Memory variable

  /// Handles all button presses.
  /// Note: The stack-based calculation logic is preserved in _evaluateExpression.
  void _onPressed(String value) {
    setState(() {
      if (value == "C") {
        // Clear entire expression
        _expression = "";
      } else if (value == "⌫") {
        // Remove last character (backspace)
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
        }
      } else if (value == "=") {
        // Evaluate expression using the existing stack-based logic
        try {
          _expression = _evaluateExpression(_expression);
        } catch (e) {
          _expression = "Invalid Expression";
        }
      } else if (value == "MC") {
        // Memory Clear
        _memory = 0.0;
      } else if (value == "MR") {
        // Memory Recall: replace current expression with memory value
        _expression = _memory.toString();
      } else if (value == "M+") {
        // Memory Add: evaluate current expression and add it to memory
        try {
          double currentVal = double.parse(_evaluateExpression(_expression));
          _memory += currentVal;
        } catch (e) {
          _expression = "Error";
        }
      } else if (value == "M-") {
        // Memory Subtract: evaluate current expression and subtract it from memory
        try {
          double currentVal = double.parse(_evaluateExpression(_expression));
          _memory -= currentVal;
        } catch (e) {
          _expression = "Error";
        }
      } else {
        // Append numbers/operators to the expression
        _expression += value;
      }
    });
  }

  /// Uses the existing stack-based evaluation functions.
  String _evaluateExpression(String expression) {
    try {
      double result = _evaluate(expression);
      return result.toString();
    } catch (e) {
      return "Error";
    }
  }

  double _evaluate(String expression) {
    List<String> tokens = _tokenize(expression);
    List<String> postfix = _infixToPostfix(tokens);
    return _evaluatePostfix(postfix);
  }

  List<String> _tokenize(String expression) {
    RegExp regExp = RegExp(r'(\d+\.?\d*|[+\-*/])');
    Iterable<RegExpMatch> matches = regExp.allMatches(expression);
    return matches.map((m) => m.group(0)!).toList();
  }

  List<String> _infixToPostfix(List<String> tokens) {
    List<String> output = [];
    List<String> operators = [];
    for (String token in tokens) {
      if (double.tryParse(token) != null) {
        output.add(token);
      } else {
        while (operators.isNotEmpty &&
            _precedence(operators.last) >= _precedence(token)) {
          output.add(operators.removeLast());
        }
        operators.add(token);
      }
    }
    while (operators.isNotEmpty) {
      output.add(operators.removeLast());
    }
    return output;
  }

  int _precedence(String operator) {
    if (operator == '+' || operator == '-') return 1;
    if (operator == '*' || operator == '/') return 2;
    return 0;
  }

  double _evaluatePostfix(List<String> tokens) {
    List<double> stack = [];
    for (String token in tokens) {
      if (double.tryParse(token) != null) {
        stack.add(double.parse(token));
      } else {
        double b = stack.removeLast();
        double a = stack.removeLast();
        switch (token) {
          case '+':
            stack.add(a + b);
            break;
          case '-':
            stack.add(a - b);
            break;
          case '*':
            stack.add(a * b);
            break;
          case '/':
            if (b == 0) throw Exception('Division by zero');
            stack.add(a / b);
            break;
        }
      }
    }
    return stack.first;
  }

  /// Saves the current expression to the history.
  void _saveExpression() {
    if (_expression.isNotEmpty) {
      setState(() {
        _savedHistory.add(_expression);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
  }

  /// Tapping on a history item sets it as the current expression.
  void _onHistoryTap(String expr) {
    setState(() {
      _expression = expr;
    });
  }

  /// Builds an individual calculator button.
  Widget _buildButton(String text) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
          onPressed: () => _onPressed(text),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.all(20),
            backgroundColor:
                widget.isDarkMode ? Colors.blueGrey[800] : Colors.blueGrey[300],
            foregroundColor: Colors.white,
          ),
          child: Text(text, style: TextStyle(fontSize: 24)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Updated keypad layout:
    // - First row: Memory functions (MC, MR, M+, M-)
    // - Next three rows: Numbers and operators
    // - Last row: Clear (C), Backspace (⌫), Evaluate (=), and Addition (+)
    List<List<String>> keypad = [
      ["MC", "MR", "M+", "M-"],
      ["7", "8", "9", "/"],
      ["4", "5", "6", "*"],
      ["1", "2", "3", "-"],
      ["C", "⌫", "=", "+"],
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text("Calculator"),
        actions: [
          IconButton(
            onPressed: widget.onThemeToggle,
            icon: AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: widget.isDarkMode
                  ? Icon(Icons.nightlight_round, key: ValueKey('moon'))
                  : Icon(Icons.wb_sunny, key: ValueKey('sun')),
            ),
          ),
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveExpression,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blueGrey),
              child: Text("Calculator Menu",
                  style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              title: Text("Home"),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: Text("Settings"),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // History display area (tap any item to edit/reuse it)
          Container(
            height: 120,
            color:
                widget.isDarkMode ? Colors.grey[900] : Colors.blueGrey[50],
            child: _savedHistory.isEmpty
                ? Center(
                    child: Text("No saved outputs",
                        style: TextStyle(fontSize: 16)))
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _savedHistory.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(
                          _savedHistory[index],
                          style: TextStyle(
                            fontSize: 18,
                            color: widget.isDarkMode
                                ? Colors.orangeAccent
                                : Colors.blueGrey[800],
                          ),
                        ),
                        onTap: () => _onHistoryTap(_savedHistory[index]),
                      );
                    },
                  ),
          ),
          Expanded(
            child: Column(
              children: [
                // Expression display area
                Expanded(
                  child: Container(
                    alignment: Alignment.bottomRight,
                    padding: EdgeInsets.all(16),
                    child: Text(
                      _expression,
                      style:
                          TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                // Keypad rows
                Column(
                  children: keypad.map((row) {
                    return Row(
                      children: row.map((text) => _buildButton(text)).toList(),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
