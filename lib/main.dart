import 'package:flutter/material.dart';

void main() {
  runApp(CalculatorApp());
}

class CalculatorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Updated theme using colorScheme for accent color
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.deepPurple)
            .copyWith(secondary: Colors.amber),
        buttonTheme: ButtonThemeData(
          buttonColor: Colors.deepPurple, // default button color
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      home: CalculatorScreen(),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  @override
  _CalculatorScreenState createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _expression = "";
  List<String> _savedHistory = []; // Holds saved outputs
  final ScrollController _scrollController = ScrollController();

  // Called when any button is pressed
  void _onPressed(String value) {
    setState(() {
      if (value == "C") {
        _expression = "";
      } else if (value == "=") {
        try {
          _expression = _evaluateExpression(_expression);
        } catch (e) {
          _expression = "Invalid Expression";
        }
      } else {
        _expression += value;
      }
    });
  }

  // Evaluates the expression string and returns the result as a string.
  String _evaluateExpression(String expression) {
    try {
      double result = _evaluate(expression);
      return result.toString();
    } catch (e) {
      print('Error evaluating expression: $e');
      return "Error";
    }
  }

  // Evaluates a simple arithmetic expression using the shunting-yard algorithm
  double _evaluate(String expression) {
    List<String> tokens = _tokenize(expression);
    List<String> postfix = _infixToPostfix(tokens);
    return _evaluatePostfix(postfix);
  }

  // Tokenizes the input expression into numbers and operators
  List<String> _tokenize(String expression) {
    // This regex matches numbers (with optional decimals) and operators
    RegExp regExp = RegExp(r'(\d+\.?\d*|[+\-*/])');
    Iterable<RegExpMatch> matches = regExp.allMatches(expression);
    return matches.map((m) => m.group(0)!).toList();
  }

  // Returns the precedence of an operator
  int _precedence(String operator) {
    if (operator == '+' || operator == '-') return 1;
    if (operator == '*' || operator == '/') return 2;
    return 0;
  }

  // Converts an infix expression (as tokens) to postfix notation
  List<String> _infixToPostfix(List<String> tokens) {
    List<String> output = [];
    List<String> operators = [];

    for (String token in tokens) {
      if (double.tryParse(token) != null) {
        output.add(token);
      } else if (token == '+' || token == '-' || token == '*' || token == '/') {
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

  // Evaluates a postfix (Reverse Polish Notation) expression
  double _evaluatePostfix(List<String> tokens) {
    List<double> stack = [];

    for (String token in tokens) {
      double? number = double.tryParse(token);
      if (number != null) {
        stack.add(number);
      } else {
        if (stack.length < 2) throw Exception('Invalid Expression');
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
          default:
            throw Exception('Unknown operator');
        }
      }
    }

    if (stack.length != 1) throw Exception('Invalid Expression');
    return stack.first;
  }

  // Creates a calculator button with the given text
  Widget _buildButton(String text) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
          onPressed: () => _onPressed(text),
          style: ElevatedButton.styleFrom(
            elevation: 5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: EdgeInsets.all(20),
          ),
          child: Text(text, style: TextStyle(fontSize: 24)),
        ),
      ),
    );
  }

  // Save the current expression to history and scroll to bottom
  void _saveExpression() {
    if (_expression.isNotEmpty) {
      setState(() {
        _savedHistory.add(_expression);
      });
      // Scroll to the bottom after the frame is rendered.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Basic Calculator"),
        actions: <Widget>[
          // Save button icon
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
              decoration: BoxDecoration(color: Colors.deepPurple),
              child: Text(
                "Calculator Menu",
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
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
        children: <Widget>[
          // History area: a fixed height container with a scrollable ListView
          Container(
            height: 150,
            color: Colors.deepPurple[50],
            child: _savedHistory.isEmpty
                ? Center(child: Text("No saved outputs", style: TextStyle(fontSize: 16)))
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _savedHistory.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(
                          _savedHistory[index],
                          style: TextStyle(fontSize: 18),
                        ),
                      );
                    },
                  ),
          ),
          // Calculator area: current expression display and button grid
          Expanded(
            child: Column(
              children: <Widget>[
                // Display for current expression/result
                Expanded(
                  child: Container(
                    alignment: Alignment.bottomRight,
                    padding: EdgeInsets.all(16),
                    child: Text(
                      _expression,
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                    ),
                  ),
                ),
                // Button grid for the calculator
                Column(
                  children: [
                    Row(
                      children: ["7", "8", "9", "/"]
                          .map((text) => _buildButton(text))
                          .toList(),
                    ),
                    Row(
                      children: ["4", "5", "6", "*"]
                          .map((text) => _buildButton(text))
                          .toList(),
                    ),
                    Row(
                      children: ["1", "2", "3", "-"]
                          .map((text) => _buildButton(text))
                          .toList(),
                    ),
                    Row(
                      children: ["C", "0", "=", "+"]
                          .map((text) => _buildButton(text))
                          .toList(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
